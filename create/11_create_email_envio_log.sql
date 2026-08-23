CREATE TABLE IF NOT EXISTS email_envio_log (
    id BIGSERIAL PRIMARY KEY,
    grupo_funcionario_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL,
    destinatario VARCHAR(150) NOT NULL,
    tentativas INTEGER NOT NULL DEFAULT 0,
    ultimo_erro VARCHAR(1000),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enviado_em TIMESTAMPTZ,
    CONSTRAINT uk_email_envio_log_vinculo_tipo
        UNIQUE (grupo_funcionario_id, tipo),
    CONSTRAINT ck_email_envio_log_tipo
        CHECK (tipo IN ('APROVACAO_CANDIDATO')),
    CONSTRAINT ck_email_envio_log_status
        CHECK (status IN ('PROCESSANDO', 'ENVIADO', 'FALHA')),
    CONSTRAINT ck_email_envio_log_tentativas
        CHECK (tentativas >= 0)
);

CREATE INDEX IF NOT EXISTS idx_email_envio_log_status_tentativas
    ON email_envio_log (status, tentativas);
