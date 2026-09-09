#!/usr/bin/env bash
#
# Restores a backup created by backup.sh into a FRESH database (dropped
# and recreated) on the running Postgres container, then runs a quick
# verification query so you can see the restore actually worked.
#
# Usage:
#   ./scripts/restore.sh                     # restores the most recent backup
#   ./scripts/restore.sh backups/foo.dump     # restores a specific backup
#
# The restore target is a separate database ("hotelbooking_restore" by
# default) rather than overwriting the live "hotelbooking" database, so
# you can compare row counts between the two and confirm nothing was lost.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$REPO_ROOT/backups"

CONTAINER_NAME="${DB_CONTAINER_NAME:-hotelbooking-db}"
DB_USER="${POSTGRES_USER:-app_admin}"
RESTORE_DB="${RESTORE_DB_NAME:-hotelbooking_restore}"

echo "==> Checking dependencies..."
if ! command -v docker &> /dev/null; then
    echo "ERROR: docker is not installed or not on PATH." >&2
    exit 1
fi

echo "==> Checking that the database container is running..."
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "ERROR: container '$CONTAINER_NAME' is not running. Start it with 'docker compose up -d'." >&2
    exit 1
fi

BACKUP_FILE="${1:-}"
if [ -z "$BACKUP_FILE" ]; then
    BACKUP_FILE="$(ls -t "$BACKUP_DIR"/*.dump 2> /dev/null | head -n1 || true)"
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: no backup file found. Run ./scripts/backup.sh first, or pass a path explicitly." >&2
    exit 1
fi

echo "==> Restoring from: $BACKUP_FILE"
echo "==> Target database: $RESTORE_DB (will be dropped and recreated)"

echo "==> Recreating a fresh target database..."
docker exec -i "$CONTAINER_NAME" psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname postgres \
    -c "DROP DATABASE IF EXISTS ${RESTORE_DB};"
docker exec -i "$CONTAINER_NAME" psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname postgres \
    -c "CREATE DATABASE ${RESTORE_DB};"

echo "==> Running pg_restore..."
if ! docker exec -i "$CONTAINER_NAME" pg_restore \
    --username "$DB_USER" \
    --dbname "$RESTORE_DB" \
    --no-owner \
    --no-privileges \
    < "$BACKUP_FILE"; then
    echo "ERROR: pg_restore failed. Check the output above for details." >&2
    exit 1
fi

echo "==> Restore finished. Verifying data..."
BOOKING_COUNT="$(docker exec -i "$CONTAINER_NAME" psql --username "$DB_USER" --dbname "$RESTORE_DB" \
    -t -A -c "SELECT COUNT(*) FROM hotel_bookings;")"
EVENT_COUNT="$(docker exec -i "$CONTAINER_NAME" psql --username "$DB_USER" --dbname "$RESTORE_DB" \
    -t -A -c "SELECT COUNT(*) FROM booking_events;")"

if [ "$BOOKING_COUNT" -lt 1 ]; then
    echo "ERROR: restored database has 0 hotel_bookings rows — restore likely failed." >&2
    exit 1
fi

echo "==> Verification: $BOOKING_COUNT rows in hotel_bookings, $EVENT_COUNT rows in booking_events."
echo "==> Restore verified successfully into database '$RESTORE_DB'."
echo "==> Compare against the live database with:"
echo "        docker exec -i $CONTAINER_NAME psql --username $DB_USER --dbname hotelbooking -c 'SELECT COUNT(*) FROM hotel_bookings;'"
