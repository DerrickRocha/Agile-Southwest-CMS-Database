#!/usr/bin/env bash
set -e

echo "Creating database..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"

DB_HOST="localhost"
DB_USER="sa"
DB_PASSWORD="YourStrong!Passw0rd"
DB_NAME="AppDb"

# Create database if not exists
/opt/mssql-tools/bin/sqlcmd \
  -b \
  -S "$DB_HOST" \
  -U "$DB_USER" \
  -P "$DB_PASSWORD" \
  -Q "IF DB_ID('$DB_NAME') IS NULL CREATE DATABASE [$DB_NAME];"

echo "Applying migrations..."

for file in "$MIGRATIONS_DIR"/*.sql; do
  echo "Running $(basename "$file")"
  /opt/mssql-tools/bin/sqlcmd \
    -b \
    -S "$DB_HOST" \
    -U "$DB_USER" \
    -P "$DB_PASSWORD" \
    -d "$DB_NAME" \
    -i "$file"
done

echo "✅ Migrations applied successfully"

