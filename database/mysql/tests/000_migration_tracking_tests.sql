-- ============================================================
-- Migration: 0000_test_migration
-- Purpose: Test inserting a migration record
-- Fully compatible with MySQL and MariaDB
-- ============================================================

START TRANSACTION;

-- ----------------------------
-- 1️⃣ Define MigrationId
-- ----------------------------
SET @MigrationId = 'test_migration_000';

-- ----------------------------
-- 2️⃣ Insert migration record if it doesn't exist
-- ----------------------------
INSERT INTO SchemaMigrations (MigrationId, AppliedAt, AppliedBy, Description)
SELECT @MigrationId, CURRENT_TIMESTAMP(6), CURRENT_USER(), 'Test migration insert'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = @MigrationId
);

-- ----------------------------
-- 3️⃣ Verify it exists
-- ----------------------------
SELECT CASE
           WHEN EXISTS (SELECT 1 FROM SchemaMigrations WHERE MigrationId = @MigrationId)
               THEN 'Migration inserted successfully'
           ELSE 'ERROR: Migration not recorded correctly'
           END AS MigrationTestResult;

-- ----------------------------
-- 4️⃣ Rollback for test purposes
-- ----------------------------
ROLLBACK;
