#!/usr/bin/env bash
set -e

############################################
# PRODUCTION DATABASE MIGRATION SCRIPT
# ------------------------------------------
# ⚠️ WARNING:
# - This script runs against REAL databases
# - Requires explicit confirmation
# - NEVER used in CI
############################################

if [[ -z "$DB_SERVER" || -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "❌ Missing required environment variables."
  echo "Required:"
  echo "  DB_SERVER"
  echo "  DB_NAME"
  echo "  DB_USER"
  echo "  DB_PASSWORD"
  exit 1
fi

echo "=========================================="
echo "🚨 PRODUCTION DATABASE MIGRATION"
echo "=========================================="
echo "Server:   $DB_SERVER"
echo "Database: $DB_NAME"
echo "User:     $DB_USER"
echo "=========================================="
echo

read -p "Type APPLY to continue: " CONFIRM

if [[ "$CONFIRM" != "APPLY" ]]; then
  echo "❌ Migration cancelled."
  exit 1
fi

echo
echo "🔍 Checking applied migrations..."

APPLIED=$(sqlcmd \
  -S "$DB_SERVER" \
  -U "$DB_USER" \
  -P "$DB_PASSWORD" \
  -d "$DB_NAME" \
  -h -1 -Q "SELECT MigrationId FROM app.SchemaMigrations")

for file in migrations/*.sql; do
  MIGRATION_ID=$(basename "$file" .sql)

  if echo "$APPLIED" | grep -q "$MIGRATION_ID"; then
    echo "⏭️  Skipping $MIGRATION_ID (already applied)"
    continue
  fi

  echo "▶ Applying $MIGRATION_ID"

  sqlcmd \
    -S "$DB_SERVER" \
    -U "$DB_USER" \
    -P "$DB_PASSWORD" \
    -d "$DB_NAME" \
    -i "$file"

  echo "✔ Applied $MIGRATION_ID"
done

echo
echo "✅ Production migrations completed successfully."
