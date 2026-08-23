-- O dataload legado nao informa o perfil e recebe RH por default.
-- Corrige explicitamente os perfis das contas de desenvolvimento.
UPDATE usuario
SET tipo = CASE email
    WHEN 'admin@hiringsys.local' THEN 'ADMIN'
    ELSE 'RH'
END
WHERE email IN ('admin@hiringsys.local', 'recrutador@hiringsys.local');
