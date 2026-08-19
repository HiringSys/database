ALTER TABLE cargo
    ADD CONSTRAINT fk_cargo_departamento
        FOREIGN KEY (departamento_id) REFERENCES departamento(id),
    ADD CONSTRAINT uk_cargo_nome_departamento UNIQUE (nome, departamento_id);

ALTER TABLE funcionario
    ADD CONSTRAINT fk_funcionario_cargo FOREIGN KEY (cargo_id) REFERENCES cargo(id),
    ADD CONSTRAINT ck_funcionario_salario CHECK (salario IS NULL OR salario >= 0),
    ADD CONSTRAINT ck_funcionario_status CHECK (
        status IN ('EM_ANALISE', 'APROVADO', 'REPROVADO', 'CONTRATADO'));
