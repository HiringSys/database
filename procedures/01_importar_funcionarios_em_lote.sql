CREATE OR REPLACE PROCEDURE importar_funcionarios_em_lote(
    p_grupo_id BIGINT,
    p_funcionarios JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item JSONB;
    v_funcionario_id BIGINT;
    v_cargo_id BIGINT;
    v_cargo_nome TEXT;
    v_nome TEXT;
    v_email TEXT;
    v_status TEXT;
    v_experiencia TEXT;
    v_salario NUMERIC(12, 2);
    v_anos_experiencia INTEGER;
    v_limite_aprovados INTEGER;
    v_total_aprovados INTEGER;
    v_ordem_aprovacao INTEGER;
    v_vinculo_existe BOOLEAN;
BEGIN
    -- Serializa importacoes concorrentes para o mesmo grupo e protege o limite.
    SELECT limite_aprovados
    INTO v_limite_aprovados
    FROM grupo
    WHERE id = p_grupo_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Grupo nao encontrado: %', p_grupo_id;
    END IF;

    IF p_funcionarios IS NULL
       OR COALESCE(jsonb_typeof(p_funcionarios), 'null') <> 'array' THEN
        RAISE EXCEPTION 'O JSON deve ser um array nao vazio de funcionarios';
    END IF;

    IF jsonb_array_length(p_funcionarios) = 0 THEN
        RAISE EXCEPTION 'O JSON deve ser um array nao vazio de funcionarios';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM jsonb_array_elements(p_funcionarios) AS item
        WHERE NULLIF(LOWER(BTRIM(item->>'email')), '') IS NOT NULL
        GROUP BY LOWER(BTRIM(item->>'email'))
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'O JSON possui e-mails duplicados';
    END IF;

    FOR v_item IN
        SELECT value FROM jsonb_array_elements(p_funcionarios)
    LOOP
        IF jsonb_typeof(v_item) <> 'object' THEN
            RAISE EXCEPTION 'Cada funcionario deve ser um objeto JSON';
        END IF;

        v_nome := NULLIF(BTRIM(v_item->>'nome'), '');
        v_email := NULLIF(LOWER(BTRIM(v_item->>'email')), '');
        v_status := COALESCE(NULLIF(UPPER(BTRIM(v_item->>'status')), ''), 'EM_ANALISE');
        v_experiencia := COALESCE(
            NULLIF(UPPER(BTRIM(v_item->>'experiencia')), ''),
            'SEM_EXPERIENCIA'
        );
        v_salario := NULLIF(BTRIM(v_item->>'salario'), '')::NUMERIC(12, 2);
        v_anos_experiencia := COALESCE(
            NULLIF(BTRIM(v_item->>'anosExperiencia'), '')::INTEGER,
            CASE v_experiencia
                WHEN 'SENIOR' THEN 5
                WHEN 'PLENO' THEN 3
                WHEN 'JUNIOR' THEN 1
                ELSE 0
            END
        );

        IF v_nome IS NULL OR v_email IS NULL THEN
            RAISE EXCEPTION 'Nome e e-mail sao obrigatorios em todos os funcionarios';
        END IF;

        IF v_salario IS NULL OR v_salario < 0 THEN
            RAISE EXCEPTION 'Salario invalido para o funcionario %', v_email;
        END IF;

        IF v_anos_experiencia < 0 THEN
            RAISE EXCEPTION 'Anos de experiencia invalidos para o funcionario %', v_email;
        END IF;

        IF v_status NOT IN ('EM_ANALISE', 'APROVADO', 'REPROVADO', 'CONTRATADO') THEN
            RAISE EXCEPTION 'Status invalido para o funcionario %: %', v_email, v_status;
        END IF;

        IF v_experiencia NOT IN (
            'SEM_EXPERIENCIA', 'ESTAGIARIO', 'JUNIOR', 'PLENO', 'SENIOR'
        ) THEN
            RAISE EXCEPTION 'Experiencia invalida para o funcionario %: %', v_email, v_experiencia;
        END IF;

        IF COALESCE(jsonb_typeof(v_item->'cargos'), 'null') <> 'array' THEN
            RAISE EXCEPTION 'Informe ao menos um cargo para o funcionario %', v_email;
        END IF;

        IF jsonb_array_length(v_item->'cargos') = 0
           OR NOT EXISTS (
               SELECT 1
               FROM jsonb_array_elements_text(v_item->'cargos') AS cargo(cargo_nome)
               WHERE BTRIM(cargo_nome) <> ''
           ) THEN
            RAISE EXCEPTION 'Informe ao menos um cargo para o funcionario %', v_email;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM jsonb_array_elements(v_item->'cargos') AS cargo
            WHERE jsonb_typeof(cargo) <> 'string'
               OR LENGTH(BTRIM(cargo #>> '{}')) > 100
        ) THEN
            RAISE EXCEPTION 'Os cargos do funcionario % devem ser textos de ate 100 caracteres', v_email;
        END IF;

        -- O e-mail identifica o cadastro global. Se ja existir, apenas novos
        -- cargos e o vinculo com o grupo sao criados.
        SELECT id
        INTO v_funcionario_id
        FROM funcionario
        WHERE LOWER(email) = v_email
        ORDER BY id
        LIMIT 1;

        IF v_funcionario_id IS NULL THEN
            INSERT INTO funcionario (
                nome,
                email,
                telefone,
                salario,
                cidade,
                status,
                experiencia,
                anos_experiencia
            )
            VALUES (
                v_nome,
                v_email,
                NULLIF(BTRIM(v_item->>'telefone'), ''),
                v_salario,
                NULLIF(BTRIM(v_item->>'cidade'), ''),
                v_status,
                v_experiencia,
                v_anos_experiencia
            )
            RETURNING id INTO v_funcionario_id;
        END IF;

        FOR v_cargo_nome IN
            SELECT DISTINCT BTRIM(value)
            FROM jsonb_array_elements_text(v_item->'cargos')
            WHERE BTRIM(value) <> ''
        LOOP
            SELECT id
            INTO v_cargo_id
            FROM cargo
            WHERE LOWER(nome) = LOWER(v_cargo_nome)
            ORDER BY id
            LIMIT 1;

            IF v_cargo_id IS NULL THEN
                INSERT INTO cargo (nome)
                VALUES (v_cargo_nome)
                RETURNING id INTO v_cargo_id;
            END IF;

            INSERT INTO cargo_funcionario (cargo_id, funcionario_id)
            VALUES (v_cargo_id, v_funcionario_id)
            ON CONFLICT (cargo_id, funcionario_id) DO NOTHING;
        END LOOP;

        SELECT EXISTS (
            SELECT 1
            FROM grupo_funcionario
            WHERE grupo_id = p_grupo_id
              AND funcionario_id = v_funcionario_id
        )
        INTO v_vinculo_existe;

        IF NOT v_vinculo_existe THEN
            IF v_status IN ('APROVADO', 'CONTRATADO') THEN
                SELECT COUNT(*)
                INTO v_total_aprovados
                FROM grupo_funcionario
                WHERE grupo_id = p_grupo_id
                  AND status_selecao = 'APROVADO';

                IF v_total_aprovados >= v_limite_aprovados THEN
                    RAISE EXCEPTION
                        'O limite de % aprovados do grupo % seria excedido',
                        v_limite_aprovados,
                        p_grupo_id;
                END IF;

                SELECT COALESCE(MAX(ordem_aprovacao), 0) + 1
                INTO v_ordem_aprovacao
                FROM grupo_funcionario
                WHERE grupo_id = p_grupo_id;

                INSERT INTO grupo_funcionario (
                    grupo_id,
                    funcionario_id,
                    status_selecao,
                    ordem_aprovacao
                )
                VALUES (
                    p_grupo_id,
                    v_funcionario_id,
                    'APROVADO',
                    v_ordem_aprovacao
                );
            ELSE
                INSERT INTO grupo_funcionario (
                    grupo_id,
                    funcionario_id,
                    status_selecao,
                    ordem_aprovacao
                )
                VALUES (
                    p_grupo_id,
                    v_funcionario_id,
                    'REPROVADO',
                    NULL
                );
            END IF;
        END IF;
    END LOOP;
END;
$$;
