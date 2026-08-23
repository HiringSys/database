WITH funcionarios_ordenados AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS posicao
    FROM funcionario
),
grupos_ordenados AS (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS posicao,
        COUNT(*) OVER () AS total
    FROM grupo
)
INSERT INTO grupo_funcionario (grupo_id, funcionario_id)
SELECT grupo.id, funcionario.id
FROM funcionarios_ordenados AS funcionario
JOIN grupos_ordenados AS grupo
    ON grupo.posicao = ((funcionario.posicao - 1) % grupo.total) + 1
ON CONFLICT (grupo_id, funcionario_id) DO NOTHING;
