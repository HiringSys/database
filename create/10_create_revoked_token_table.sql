CREATE TABLE IF NOT EXISTS token_revogado (
    jti VARCHAR(36) PRIMARY KEY,
    expira_em TIMESTAMPTZ NOT NULL,
    revogado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_token_revogado_expira_em
    ON token_revogado (expira_em);
