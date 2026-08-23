-- Evolução compatível: preserva tabelas e dados das migrações anteriores.

ALTER TABLE grupo_funcionario
    ADD COLUMN IF NOT EXISTS score_proximidade NUMERIC(5, 2);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'grupo_funcionario'::regclass
          AND conname = 'ck_grupo_funcionario_score_proximidade'
    ) THEN
        ALTER TABLE grupo_funcionario
            ADD CONSTRAINT ck_grupo_funcionario_score_proximidade
            CHECK (
                score_proximidade IS NULL
                OR score_proximidade BETWEEN 0 AND 100
            );
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS arquivo_funcionario (
    id BIGSERIAL,
    funcionario_id BIGINT,
    nome_arquivo VARCHAR(255),
    categoria VARCHAR(50),
    mime_type VARCHAR(150),
    extensao VARCHAR(20),
    tamanho_bytes BIGINT,
    bucket VARCHAR(100),
    storage_path VARCHAR(500),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE arquivo_funcionario
    ALTER COLUMN funcionario_id SET NOT NULL,
    ALTER COLUMN nome_arquivo SET NOT NULL,
    ALTER COLUMN categoria SET NOT NULL,
    ALTER COLUMN bucket SET NOT NULL,
    ALTER COLUMN storage_path SET NOT NULL,
    ALTER COLUMN criado_em SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'arquivo_funcionario'::regclass AND contype = 'p'
    ) THEN
        ALTER TABLE arquivo_funcionario
            ADD CONSTRAINT pk_arquivo_funcionario PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'arquivo_funcionario'::regclass
          AND conname = 'fk_arquivo_funcionario_funcionario'
    ) THEN
        ALTER TABLE arquivo_funcionario
            ADD CONSTRAINT fk_arquivo_funcionario_funcionario
            FOREIGN KEY (funcionario_id) REFERENCES funcionario(id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'arquivo_funcionario'::regclass
          AND conname = 'uk_arquivo_funcionario_storage'
    ) THEN
        ALTER TABLE arquivo_funcionario
            ADD CONSTRAINT uk_arquivo_funcionario_storage
            UNIQUE (bucket, storage_path);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'arquivo_funcionario'::regclass
          AND conname = 'ck_arquivo_funcionario_tamanho'
    ) THEN
        ALTER TABLE arquivo_funcionario
            ADD CONSTRAINT ck_arquivo_funcionario_tamanho
            CHECK (tamanho_bytes IS NULL OR tamanho_bytes >= 0);
    END IF;
END
$$;

-- Relacionamentos associativos não devem sobreviver à exclusão das entidades.
ALTER TABLE grupo_funcionario
    DROP CONSTRAINT IF EXISTS fk_grupo_funcionario_grupo,
    DROP CONSTRAINT IF EXISTS fk_grupo_funcionario_funcionario,
    ADD CONSTRAINT fk_grupo_funcionario_grupo
        FOREIGN KEY (grupo_id) REFERENCES grupo(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_grupo_funcionario_funcionario
        FOREIGN KEY (funcionario_id) REFERENCES funcionario(id) ON DELETE CASCADE;

ALTER TABLE cargo_funcionario
    DROP CONSTRAINT IF EXISTS fk_cargo_funcionario_cargo,
    DROP CONSTRAINT IF EXISTS fk_cargo_funcionario_funcionario,
    ADD CONSTRAINT fk_cargo_funcionario_cargo
        FOREIGN KEY (cargo_id) REFERENCES cargo(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_cargo_funcionario_funcionario
        FOREIGN KEY (funcionario_id) REFERENCES funcionario(id) ON DELETE CASCADE;

ALTER TABLE rede_funcionario
    DROP CONSTRAINT IF EXISTS fk_rede_funcionario_rede,
    DROP CONSTRAINT IF EXISTS fk_rede_funcionario_funcionario,
    ADD CONSTRAINT fk_rede_funcionario_rede
        FOREIGN KEY (rede_id) REFERENCES rede(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_rede_funcionario_funcionario
        FOREIGN KEY (funcionario_id) REFERENCES funcionario(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_arquivo_funcionario_funcionario_id
    ON arquivo_funcionario (funcionario_id);
