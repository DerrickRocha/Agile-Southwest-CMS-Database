#!/usr/bin/env bash
set -e

SERVER="localhost"
USER="sa"
PASSWORD="YourStrong!Passw0rd"
DB="appdb"

echo "Creating database..."
/opt/mssql-tools/bin/sqlcmd -S $SERVER -U $USER -P $PASSWORD -Q "IF DB_ID('$DB') IS NULL CREATE DATABASE $DB"

echo "Applying migrations..."
for file in migrations/*.sql; do
  echo "Running $file"
  /opt/mssql-tools/bin/sqlcmd -S $SERVER -U $USER -P $PASSWORD -d $DB -i "$file"
done

echo "Migrations applied successfully."
