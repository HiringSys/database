-- Os grupos inseridos pelo dataload legado recebem inicialmente os defaults da
-- migration 07. Usa as vagas disponiveis como limite inicial, seguindo o
-- mesmo criterio de compatibilidade aplicado pela migration 05.
UPDATE grupo
SET limite_aprovados = disponiveis
WHERE limite_aprovados = 0
  AND disponiveis > 0
  AND email_equipe = 'rh@hiringsys.local';
