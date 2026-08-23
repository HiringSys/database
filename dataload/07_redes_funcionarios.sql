INSERT INTO rede_funcionario (rede_id, funcionario_id)
SELECT rede.id, funcionario.id
FROM (
    VALUES
        ('https://www.linkedin.com/in/lucas-ferreira', 'lucas.ferreira@email.com'),
        ('https://github.com/lucas-ferreira', 'lucas.ferreira@email.com'),
        ('https://www.linkedin.com/in/mariana-souza', 'mariana.souza@email.com'),
        ('https://mariana-souza.dev', 'mariana.souza@email.com'),
        ('https://github.com/gabriel-santos', 'gabriel.santos@email.com'),
        ('https://www.linkedin.com/in/beatriz-oliveira', 'beatriz.oliveira@email.com'),
        ('https://beatriz-oliveira.dev', 'beatriz.oliveira@email.com'),
        ('https://www.linkedin.com/in/rafael-lima', 'rafael.lima@email.com'),
        ('https://github.com/julia-costa', 'julia.costa@email.com'),
        ('https://www.linkedin.com/in/matheus-almeida', 'matheus.almeida@email.com')
) AS vinculo(url, email)
JOIN rede ON rede.url = vinculo.url
JOIN funcionario ON funcionario.email = vinculo.email
ON CONFLICT (rede_id, funcionario_id) DO NOTHING;
