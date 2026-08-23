INSERT INTO grupo (nome, area, estado, disponiveis, cargo)
VALUES
    ('Backend Java - Agosto', 'Tecnologia', 'EM_COLETA', 5, 'Desenvolvedor Backend'),
    ('Frontend React - Agosto', 'Tecnologia', 'EM_PROCESSO', 3, 'Desenvolvedor Frontend'),
    ('Engenharia de Dados', 'Dados', 'EM_COLETA', 4, 'Engenheiro de Dados'),
    ('Time de Produto', 'Produto', 'RASCUNHO', 2, 'Product Owner'),
    ('Recrutamento Corporativo', 'Recursos Humanos', 'EM_PROCESSO', 2, 'Recrutador'),
    ('Expansão Comercial', 'Comercial', 'EM_COLETA', 8, 'Executivo de Vendas'),
    ('Atendimento ao Cliente', 'Atendimento', 'PAUSADO', 6, 'Analista de Atendimento'),
    ('Operações - São Paulo', 'Operações', 'ENCERRADO', 0, 'Analista de Operações')
ON CONFLICT (nome) DO NOTHING;
