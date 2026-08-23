-- Copia os vínculos da versão anterior, quando cargo_id ainda existe.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'funcionario'
          AND column_name = 'cargo_id'
    ) THEN
        INSERT INTO cargo_funcionario (cargo_id, funcionario_id)
        SELECT cargo_id, id
        FROM funcionario
        WHERE cargo_id IS NOT NULL
        ON CONFLICT (cargo_id, funcionario_id) DO NOTHING;
    END IF;
END
$$;

-- Distribui um cargo somente para funcionários que ainda não possuem vínculo.
WITH funcionarios_ordenados AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS posicao
    FROM funcionario
    WHERE NOT EXISTS (
        SELECT 1
        FROM cargo_funcionario
        WHERE cargo_funcionario.funcionario_id = funcionario.id
    )
),
cargos_ordenados AS (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS posicao,
        COUNT(*) OVER () AS total
    FROM cargo
)
INSERT INTO cargo_funcionario (cargo_id, funcionario_id)
SELECT cargo.id, funcionario.id
FROM funcionarios_ordenados AS funcionario
JOIN cargos_ordenados AS cargo
    ON cargo.posicao = ((funcionario.posicao - 1) % cargo.total) + 1
ON CONFLICT (cargo_id, funcionario_id) DO NOTHING;
