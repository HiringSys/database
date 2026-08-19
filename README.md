# Banco de dados do HiringSys

Os scripts são aplicados na ordem declarada em `migrate.py`, cada um em uma
transação. A tabela `schema_migrations` registra arquivo e checksum, impedindo
reexecução acidental ou alteração de migrações já aplicadas.

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Preencha o `.env`. No Aiven, use `DB_SSLMODE=require` e deixe
`DB_CREATE_IF_MISSING=false`. Depois execute:

```powershell
python migrate.py --dry-run
python migrate.py
```

Para evoluções futuras, crie outro SQL e adicione-o ao fim de `MIGRATIONS`.
Não edite um arquivo que já tenha sido aplicado em algum ambiente.
