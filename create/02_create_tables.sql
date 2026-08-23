CREATE TABLE IF NOT EXISTS grupo (
    id BIGSERIAL,
    nome VARCHAR(100),
    area VARCHAR(100),
    estado VARCHAR(20),
    disponiveis INTEGER,
    cargo VARCHAR(100),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cargo (
    id BIGSERIAL,
    nome VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS funcionario (
    id BIGSERIAL,
    nome VARCHAR(150),
    email VARCHAR(150),
    telefone VARCHAR(20),
    salario NUMERIC(12, 2),
    cidade VARCHAR(100),
    status VARCHAR(30) DEFAULT 'EM_ANALISE',
    experiencia VARCHAR(30) DEFAULT 'SEM_EXPERIENCIA',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE funcionario
    ADD COLUMN IF NOT EXISTS experiencia VARCHAR(30) DEFAULT 'SEM_EXPERIENCIA';

-- Compatibilidade com a versão anterior, que guardava os vínculos diretamente.
-- As colunas antigas são preservadas para não apagar dados já existentes.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'cargo'
          AND column_name = 'departamento_id'
    ) THEN
        ALTER TABLE cargo ALTER COLUMN departamento_id DROP NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'funcionario'
          AND column_name = 'cargo_id'
    ) THEN
        ALTER TABLE funcionario ALTER COLUMN cargo_id DROP NOT NULL;
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS grupo_funcionario (
    id BIGSERIAL,
    grupo_id BIGINT,
    funcionario_id BIGINT
);

CREATE TABLE IF NOT EXISTS cargo_funcionario (
    id BIGSERIAL,
    cargo_id BIGINT,
    funcionario_id BIGINT
);

CREATE TABLE IF NOT EXISTS rede (
    id BIGSERIAL,
    url VARCHAR(255),
    tipo VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS rede_funcionario (
    id BIGSERIAL,
    rede_id BIGINT,
    funcionario_id BIGINT
);

CREATE TABLE IF NOT EXISTS usuario (
    id BIGSERIAL,
    email VARCHAR(150),
    senha VARCHAR(100)
);
