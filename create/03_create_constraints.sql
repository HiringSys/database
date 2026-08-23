ALTER TABLE grupo
    ALTER COLUMN nome SET NOT NULL,
    ALTER COLUMN area SET NOT NULL,
    ALTER COLUMN estado SET NOT NULL,
    ALTER COLUMN disponiveis SET NOT NULL,
    ALTER COLUMN criado_em SET NOT NULL,
    ADD CONSTRAINT pk_grupo PRIMARY KEY (id),
    ADD CONSTRAINT uk_grupo_nome UNIQUE (nome),
    ADD CONSTRAINT ck_grupo_disponiveis CHECK (disponiveis >= 0),
    ADD CONSTRAINT ck_grupo_estado CHECK (
        estado IN ('EM_COLETA', 'EM_PROCESSO', 'PAUSADO', 'ENCERRADO', 'RASCUNHO')
    );

ALTER TABLE cargo
    ALTER COLUMN nome SET NOT NULL,
    ADD CONSTRAINT uk_cargo_nome UNIQUE (nome);

ALTER TABLE funcionario
    ALTER COLUMN nome SET NOT NULL,
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN experiencia SET NOT NULL,
    ALTER COLUMN criado_em SET NOT NULL,
    ALTER COLUMN atualizado_em SET NOT NULL,
    ADD CONSTRAINT uk_funcionario_email UNIQUE (email),
    ADD CONSTRAINT ck_funcionario_experiencia CHECK (
        experiencia IN ('SEM_EXPERIENCIA', 'ESTAGIARIO', 'JUNIOR', 'PLENO', 'SENIOR')
    ),
    ADD CONSTRAINT ck_funcionario_status CHECK (
        status IN ('EM_ANALISE', 'APROVADO', 'REPROVADO', 'CONTRATADO')
    );

-- Cargo e funcionario podem vir da versão anterior do esquema.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cargo'::regclass AND contype = 'p'
    ) THEN
        ALTER TABLE cargo ADD CONSTRAINT pk_cargo PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'funcionario'::regclass AND contype = 'p'
    ) THEN
        ALTER TABLE funcionario ADD CONSTRAINT pk_funcionario PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'funcionario'::regclass
          AND conname = 'ck_funcionario_salario'
    ) THEN
        ALTER TABLE funcionario ADD CONSTRAINT ck_funcionario_salario
            CHECK (salario IS NULL OR salario >= 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'funcionario'::regclass
          AND conname = 'ck_funcionario_status'
    ) THEN
        ALTER TABLE funcionario ADD CONSTRAINT ck_funcionario_status
            CHECK (status IN ('EM_ANALISE', 'APROVADO', 'REPROVADO', 'CONTRATADO'));
    END IF;
END
$$;

ALTER TABLE grupo_funcionario
    ALTER COLUMN grupo_id SET NOT NULL,
    ALTER COLUMN funcionario_id SET NOT NULL,
    ADD CONSTRAINT pk_grupo_funcionario PRIMARY KEY (id),
    ADD CONSTRAINT fk_grupo_funcionario_grupo
        FOREIGN KEY (grupo_id) REFERENCES grupo(id),
    ADD CONSTRAINT fk_grupo_funcionario_funcionario
        FOREIGN KEY (funcionario_id) REFERENCES funcionario(id),
    ADD CONSTRAINT uk_grupo_funcionario UNIQUE (grupo_id, funcionario_id);

ALTER TABLE cargo_funcionario
    ALTER COLUMN cargo_id SET NOT NULL,
    ALTER COLUMN funcionario_id SET NOT NULL,
    ADD CONSTRAINT pk_cargo_funcionario PRIMARY KEY (id),
    ADD CONSTRAINT fk_cargo_funcionario_cargo
        FOREIGN KEY (cargo_id) REFERENCES cargo(id),
    ADD CONSTRAINT fk_cargo_funcionario_funcionario
        FOREIGN KEY (funcionario_id) REFERENCES funcionario(id),
    ADD CONSTRAINT uk_cargo_funcionario UNIQUE (cargo_id, funcionario_id);

ALTER TABLE rede
    ALTER COLUMN url SET NOT NULL,
    ALTER COLUMN tipo SET NOT NULL,
    ADD CONSTRAINT pk_rede PRIMARY KEY (id),
    ADD CONSTRAINT uk_rede_url UNIQUE (url),
    ADD CONSTRAINT ck_rede_tipo CHECK (
        tipo IN ('LINKEDIN', 'GITHUB', 'PORTFOLIO', 'OUTRO')
    );

ALTER TABLE rede_funcionario
    ALTER COLUMN rede_id SET NOT NULL,
    ALTER COLUMN funcionario_id SET NOT NULL,
    ADD CONSTRAINT pk_rede_funcionario PRIMARY KEY (id),
    ADD CONSTRAINT fk_rede_funcionario_rede
        FOREIGN KEY (rede_id) REFERENCES rede(id),
    ADD CONSTRAINT fk_rede_funcionario_funcionario
        FOREIGN KEY (funcionario_id) REFERENCES funcionario(id),
    ADD CONSTRAINT uk_rede_funcionario UNIQUE (rede_id, funcionario_id);

ALTER TABLE usuario
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN senha SET NOT NULL,
    ADD CONSTRAINT pk_usuario PRIMARY KEY (id),
    ADD CONSTRAINT uk_usuario_email UNIQUE (email);
