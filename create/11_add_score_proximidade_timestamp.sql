-- Mantem separada a data do calculo por IA das demais atualizacoes do vinculo.
-- Scores legados ficam com timestamp nulo e, portanto, serao recalculados.
ALTER TABLE grupo_funcionario
    ADD COLUMN IF NOT EXISTS score_atualizado_em TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_grupo_funcionario_score_atualizado_em
    ON grupo_funcionario (score_atualizado_em, id);
