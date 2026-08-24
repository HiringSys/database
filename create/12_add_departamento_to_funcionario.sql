-- Funcionários passam a registrar explicitamente o departamento a que pertencem,
-- em complemento ao cargo já existente.
ALTER TABLE funcionario
    ADD COLUMN IF NOT EXISTS departamento VARCHAR(100);
