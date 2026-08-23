# Banco de dados do HiringSys

Os scripts são aplicados por diretório (`create`, `dataload`, `functions`,
`procedures`, `triggers`, `views` e `indexes`) e, dentro de cada diretório, em
ordem alfabética. Use prefixos `01_`, `02_`, etc. para declarar dependências.
Cada arquivo roda em uma transação. A tabela `schema_migrations` registra o
arquivo e o checksum, impedindo reexecução acidental ou alteração de migrações
já aplicadas.

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

Para apagar todas as tabelas e dados do schema `public` e recriar o banco com
as migrações atuais, use o comando destrutivo:

```powershell
python migrate.py --reset --yes
```

Para evoluções futuras, crie outro SQL no diretório da etapa correspondente,
com um prefixo posterior aos arquivos dos quais ele depende. Não edite um
arquivo que já tenha sido aplicado em algum ambiente.
