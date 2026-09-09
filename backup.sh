#!/usr/bin/env bash
#
# Creates a timestamped, compressed pg_dump of the local database running
# in Docker Compose (custom format, so it can be restored with pg_restore
# and supports parallel restore / selective table restore).
#
# Usage:
#   ./scripts/backup.sh
#
# Output:
#   backups/hotelbooking_YYYYmmdd_HHMMSS.dump
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$REPO_ROOT/backups"

CONTAINER_NAME="${DB_CONTAINER_NAME:-hotelbooking-db}"
DB_NAME="${POSTGRES_DB:-hotelbooking}"
DB_USER="${POSTGRES_USER:-app_admin}"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"

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

mkdir -p "$BACKUP_DIR"

echo "==> Backing up database '$DB_NAME' to $BACKUP_FILE ..."
if ! docker exec -i "$CONTAINER_NAME" pg_dump \
    --username "$DB_USER" \
    --dbname "$DB_NAME" \
    --format=custom \
    --no-owner \
    --no-privileges \
    > "$BACKUP_FILE"; then
    echo "ERROR: pg_dump failed. Removing incomplete backup file." >&2
    rm -f "$BACKUP_FILE"
    exit 1
fi

if [ ! -s "$BACKUP_FILE" ]; then
    echo "ERROR: backup file is empty, something went wrong." >&2
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo "==> Backup complete: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
echo "==> Verify contents anytime with: docker exec -i $CONTAINER_NAME pg_restore --list < $BACKUP_FILE"
