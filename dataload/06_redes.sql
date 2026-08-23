INSERT INTO rede (url, tipo)
VALUES
    ('https://www.linkedin.com/in/lucas-ferreira', 'LINKEDIN'),
    ('https://github.com/lucas-ferreira', 'GITHUB'),
    ('https://www.linkedin.com/in/mariana-souza', 'LINKEDIN'),
    ('https://mariana-souza.dev', 'PORTFOLIO'),
    ('https://github.com/gabriel-santos', 'GITHUB'),
    ('https://www.linkedin.com/in/beatriz-oliveira', 'LINKEDIN'),
    ('https://beatriz-oliveira.dev', 'PORTFOLIO'),
    ('https://www.linkedin.com/in/rafael-lima', 'LINKEDIN'),
    ('https://github.com/julia-costa', 'GITHUB'),
    ('https://www.linkedin.com/in/matheus-almeida', 'LINKEDIN')
ON CONFLICT (url) DO NOTHING;
