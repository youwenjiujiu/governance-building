#!/usr/bin/env bash
set -euo pipefail

DATABASE_URL="${1:?Usage: $0 <database-url>}"

# Extract host and port from the DATABASE_URL for pg_isready
# Expects format: postgres://user:pass@host:port/dbname
HOST=$(echo "$DATABASE_URL" | sed -E 's|.*@([^:]+):([0-9]+)/.*|\1|')
PORT=$(echo "$DATABASE_URL" | sed -E 's|.*@([^:]+):([0-9]+)/.*|\2|')

echo "Waiting for PostgreSQL at ${HOST}:${PORT} to be ready..."
until pg_isready -h "$HOST" -p "$PORT" -q; do
    echo "  PostgreSQL not ready yet, retrying in 1s..."
    sleep 1
done
echo "PostgreSQL is ready."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATIONS_DIR="${SCRIPT_DIR}/../migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Error: migrations directory not found at ${MIGRATIONS_DIR}"
    exit 1
fi

for migration in "$MIGRATIONS_DIR"/*.sql; do
    [ -f "$migration" ] || continue
    echo "Running migration: $(basename "$migration")"
    psql "$DATABASE_URL" -f "$migration"
done

echo "All migrations applied successfully."
