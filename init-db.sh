#!/usr/bin/env bash
# Runs once, automatically, the first time the postgres container starts
# with an empty data volume (docker-entrypoint-initdb.d convention).
# Applies migrations/*.sql in filename order, then seed/*.sql in filename order.
set -euo pipefail

echo "==> Applying migrations..."
for f in /migrations/*.sql; do
  echo "    - $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done

echo "==> Loading seed data..."
for f in /seed/*.sql; do
  echo "    - $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done

echo "==> Database initialization complete."
