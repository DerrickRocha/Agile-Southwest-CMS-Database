#!/usr/bin/env bash
set -e

echo "Creating database (if it doesn't exist)..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"

DB_HOST="localhost"
DB_USER="cms_migrator"
DB_PASSWORD="YourStrong!Passw0rd"
DB_NAME="agile_cms_dev"  # Change to your dev database

# Create database if it doesn't exist
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "Applying migrations..."

for file in "$MIGRATIONS_DIR"/*.sql; do
  echo "Running $(basename "$file")"
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$file"
done

echo "✅ Migrations applied successfully"
