-- Permite que dataloads e clientes legados, anteriores aos campos do frontend,
-- continuem inserindo grupos sem informar as novas colunas obrigatorias.
ALTER TABLE grupo
    ALTER COLUMN limite_aprovados SET DEFAULT 0,
    ALTER COLUMN email_equipe SET DEFAULT 'rh@hiringsys.local';
