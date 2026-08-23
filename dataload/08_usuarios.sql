-- Senhas fictícias em formato de hash bcrypt para ambientes de desenvolvimento.
INSERT INTO usuario (email, senha)
VALUES
    ('admin@hiringsys.local', '$2b$12$8K1p/a0dL1LXMIgoEDFrwOeJXn8nXnK4QfN6uqLhpTlr0WuoD.nJy'),
    ('recrutador@hiringsys.local', '$2b$12$8K1p/a0dL1LXMIgoEDFrwOeJXn8nXnK4QfN6uqLhpTlr0WuoD.nJy')
ON CONFLICT (email) DO NOTHING;
