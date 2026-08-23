-- O perfil de autorizacao passa a fazer parte do usuario persistido.
ALTER TABLE usuario
    ADD COLUMN IF NOT EXISTS tipo VARCHAR(10);

-- Preserva usuarios existentes. Contas administrativas conhecidas recebem
-- ADMIN; as demais recebem o perfil de menor privilegio, RH.
UPDATE usuario
SET tipo = CASE
    WHEN LOWER(email) LIKE 'admin@%' THEN 'ADMIN'
    ELSE 'RH'
END
WHERE tipo IS NULL;

ALTER TABLE usuario
    ALTER COLUMN tipo SET DEFAULT 'RH',
    ALTER COLUMN tipo SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'usuario'::regclass
          AND conname = 'ck_usuario_tipo'
    ) THEN
        ALTER TABLE usuario
            ADD CONSTRAINT ck_usuario_tipo
            CHECK (tipo IN ('RH', 'ADMIN'));
    END IF;
END
$$;
