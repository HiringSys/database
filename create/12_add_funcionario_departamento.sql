-- Mantem o schema de funcionario alinhado ao campo exposto pela API.
ALTER TABLE funcionario
    ADD COLUMN IF NOT EXISTS departamento VARCHAR(100);
