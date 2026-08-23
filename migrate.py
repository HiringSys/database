"""Executor das migrações PostgreSQL do HiringSys."""
from __future__ import annotations

import argparse
import hashlib
import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from psycopg import sql

ROOT = Path(__file__).resolve().parent

# A ordem dos diretórios representa as dependências entre as migrações.
# Dentro de cada diretório, use prefixos 01_, 02_, ... para definir a ordem.
MIGRATION_DIRECTORIES = (
    "create",
    "dataload",
    "functions",
    "procedures",
    "triggers",
    "views",
    "indexes",
)


def migration_files() -> tuple[Path, ...]:
    migrations: list[Path] = []
    for directory in MIGRATION_DIRECTORIES:
        migrations.extend(sorted((ROOT / directory).glob("*.sql")))
    return tuple(migrations)

def env_bool(name: str) -> bool:
    return os.getenv(name, "false").strip().lower() in {"1", "true", "yes", "sim"}

def connection_kwargs(database: str | None = None) -> dict[str, object]:
    required = ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD")
    missing = [key for key in required if not os.getenv(key)]
    if missing:
        raise ValueError(f"Variáveis ausentes no .env: {', '.join(missing)}")
    return {"host": os.environ["DB_HOST"], "port": int(os.environ["DB_PORT"]),
            "dbname": database or os.environ["DB_NAME"], "user": os.environ["DB_USER"],
            "password": os.environ["DB_PASSWORD"],
            "sslmode": os.getenv("DB_SSLMODE", "require"),
            "connect_timeout": int(os.getenv("DB_CONNECT_TIMEOUT", "10"))}

def create_database_if_requested() -> None:
    if not env_bool("DB_CREATE_IF_MISSING"):
        return
    target = os.environ["DB_NAME"]
    try:
        psycopg.connect(**connection_kwargs(target)).close()
        return
    except psycopg.OperationalError:
        pass
    admin = os.getenv("DB_ADMIN_DATABASE", "postgres")
    with psycopg.connect(**connection_kwargs(admin), autocommit=True) as conn:
        exists = conn.execute("SELECT 1 FROM pg_database WHERE datname = %s", (target,)).fetchone()
        if not exists:
            conn.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(target)))
            print(f"Banco {target!r} criado.")


def reset_database() -> None:
    """Remove todas as tabelas do schema public e os objetos dependentes."""
    create_database_if_requested()
    with psycopg.connect(**connection_kwargs()) as conn:
        tables = conn.execute(
            """
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = 'public'
            ORDER BY tablename
            """
        ).fetchall()
        with conn.transaction():
            for (table,) in tables:
                conn.execute(
                    sql.SQL("DROP TABLE {} CASCADE").format(
                        sql.Identifier("public", table)
                    )
                )
        print(f"Reset concluído: {len(tables)} tabela(s) removida(s).")


def migrate(dry_run: bool = False) -> None:
    create_database_if_requested()
    with psycopg.connect(**connection_kwargs()) as conn:
        conn.execute("""CREATE TABLE IF NOT EXISTS schema_migrations (
            filename TEXT PRIMARY KEY, checksum CHAR(64) NOT NULL,
            applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)""")
        conn.commit()
        applied = dict(conn.execute("SELECT filename, checksum FROM schema_migrations").fetchall())
        conn.commit()
        for path in migration_files():
            name = path.relative_to(ROOT).as_posix()
            contents = path.read_text(encoding="utf-8-sig")
            checksum = hashlib.sha256(contents.encode()).hexdigest()
            if name in applied:
                if applied[name] != checksum:
                    raise RuntimeError(f"Migração já aplicada foi alterada: {name}")
                print(f"[ok]       {name}")
                continue
            if dry_run:
                print(f"[pendente] {name}")
                continue
            print(f"[aplicando] {name}")
            with conn.transaction():
                conn.execute(contents)
                conn.execute("INSERT INTO schema_migrations (filename, checksum) VALUES (%s, %s)",
                             (name, checksum))
        print("Migrações verificadas." if dry_run else "Banco atualizado com sucesso.")

def main() -> int:
    parser = argparse.ArgumentParser(description="Aplica migrações do HiringSys")
    parser.add_argument("--dry-run", action="store_true", help="lista pendências sem executar SQL")
    parser.add_argument(
        "--reset",
        action="store_true",
        help="remove todas as tabelas do schema public antes de migrar",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="confirma a exclusão destrutiva solicitada por --reset",
    )
    args = parser.parse_args()
    load_dotenv(ROOT / ".env")
    try:
        if args.reset and args.dry_run:
            raise ValueError("--reset e --dry-run não podem ser usados juntos")
        if args.reset and not args.yes:
            raise ValueError("use --reset --yes para confirmar a exclusão de todas as tabelas")
        if args.reset:
            reset_database()
        migrate(args.dry_run)
    except (OSError, ValueError, RuntimeError, psycopg.Error) as exc:
        print(f"Erro: {exc}", file=sys.stderr)
        return 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
