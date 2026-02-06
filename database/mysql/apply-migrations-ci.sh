#!/usr/bin/env bash
set -e

echo "Creating database (if it doesn't exist)..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"

# Read from environment variables set in the GitHub workflow
DB_HOST="${DB_HOST:-mysql}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-rootpassword}"
DB_NAME="${DB_NAME:-agile_cms_dev}"

# Create database if it doesn't exist
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "Applying migrations..."

for file in "$MIGRATIONS_DIR"/*.sql; do
  echo "Running $(basename "$file")"
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$file"
done

echo "✅ Migrations applied successfully"

