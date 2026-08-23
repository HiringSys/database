-- Permite hashes de senha maiores caso o algoritmo de criptografia seja alterado.
ALTER TABLE usuario
    ALTER COLUMN senha TYPE TEXT;
