-- Campos exigidos pelas telas de peneiras. Esta evolucao preserva dados existentes.

ALTER TABLE grupo
    ADD COLUMN IF NOT EXISTS limite_aprovados INTEGER,
    ADD COLUMN IF NOT EXISTS email_equipe VARCHAR(150);

UPDATE grupo
SET limite_aprovados = GREATEST(disponiveis, 0)
WHERE limite_aprovados IS NULL;

UPDATE grupo
SET email_equipe = 'rh@hiringsys.local'
WHERE email_equipe IS NULL;

ALTER TABLE grupo
    ALTER COLUMN limite_aprovados SET NOT NULL,
    ALTER COLUMN email_equipe SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'grupo'::regclass
          AND conname = 'ck_grupo_limite_aprovados'
    ) THEN
        ALTER TABLE grupo
            ADD CONSTRAINT ck_grupo_limite_aprovados
            CHECK (limite_aprovados >= 0);
    END IF;
END
$$;

ALTER TABLE funcionario
    ADD COLUMN IF NOT EXISTS anos_experiencia INTEGER;

UPDATE funcionario
SET anos_experiencia = CASE experiencia
    WHEN 'SENIOR' THEN 5
    WHEN 'PLENO' THEN 3
    WHEN 'JUNIOR' THEN 1
    ELSE 0
END
WHERE anos_experiencia IS NULL;

ALTER TABLE funcionario
    ALTER COLUMN anos_experiencia SET DEFAULT 0,
    ALTER COLUMN anos_experiencia SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'funcionario'::regclass
          AND conname = 'ck_funcionario_anos_experiencia'
    ) THEN
        ALTER TABLE funcionario
            ADD CONSTRAINT ck_funcionario_anos_experiencia
            CHECK (anos_experiencia >= 0);
    END IF;
END
$$;

-- A aprovacao pertence ao vinculo com a peneira, nao ao cadastro global.
ALTER TABLE grupo_funcionario
    ADD COLUMN IF NOT EXISTS status_selecao VARCHAR(20),
    ADD COLUMN IF NOT EXISTS ordem_aprovacao INTEGER;

UPDATE grupo_funcionario AS vinculo
SET status_selecao = CASE
    WHEN funcionario.status IN ('APROVADO', 'CONTRATADO') THEN 'APROVADO'
    ELSE 'REPROVADO'
END
FROM funcionario
WHERE funcionario.id = vinculo.funcionario_id
  AND vinculo.status_selecao IS NULL;

WITH aprovados AS (
    SELECT
        id,
        ROW_NUMBER() OVER (PARTITION BY grupo_id ORDER BY id) AS ordem
    FROM grupo_funcionario
    WHERE status_selecao = 'APROVADO'
      AND ordem_aprovacao IS NULL
)
UPDATE grupo_funcionario AS vinculo
SET ordem_aprovacao = aprovados.ordem
FROM aprovados
WHERE aprovados.id = vinculo.id;

ALTER TABLE grupo_funcionario
    ALTER COLUMN status_selecao SET DEFAULT 'REPROVADO',
    ALTER COLUMN status_selecao SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'grupo_funcionario'::regclass
          AND conname = 'ck_grupo_funcionario_status_selecao'
    ) THEN
        ALTER TABLE grupo_funcionario
            ADD CONSTRAINT ck_grupo_funcionario_status_selecao
            CHECK (status_selecao IN ('APROVADO', 'REPROVADO'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'grupo_funcionario'::regclass
          AND conname = 'ck_grupo_funcionario_ordem_aprovacao'
    ) THEN
        ALTER TABLE grupo_funcionario
            ADD CONSTRAINT ck_grupo_funcionario_ordem_aprovacao
            CHECK (
                (status_selecao = 'APROVADO' AND ordem_aprovacao > 0)
                OR (status_selecao = 'REPROVADO' AND ordem_aprovacao IS NULL)
            );
    END IF;
END
$$;

CREATE UNIQUE INDEX IF NOT EXISTS uk_grupo_funcionario_ordem_aprovacao
    ON grupo_funcionario (grupo_id, ordem_aprovacao)
    WHERE ordem_aprovacao IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_grupo_funcionario_grupo_status
    ON grupo_funcionario (grupo_id, status_selecao);
