-- O frontend oferece estas redes nos seus tipos e componentes de icone.
-- PORTFOLIO e OUTRO permanecem validos para preservar dados legados.
ALTER TABLE rede
    DROP CONSTRAINT IF EXISTS ck_rede_tipo,
    ADD CONSTRAINT ck_rede_tipo CHECK (
        tipo IN (
            'LINKEDIN', 'GITHUB', 'INSTAGRAM', 'FACEBOOK', 'X', 'WHATSAPP',
            'GITLAB', 'BEHANCE', 'DRIBBBLE', 'TIKTOK', 'PORTFOLIO', 'OUTRO'
        )
    );
