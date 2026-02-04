-- ----------------------------
-- 1️⃣ Create SchemaMigrations table if it doesn't exist
-- ----------------------------
CREATE TABLE IF NOT EXISTS SchemaMigrations (
                                                MigrationId VARCHAR(150) PRIMARY KEY,
                                                AppliedAt   DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                AppliedBy   VARCHAR(128) NOT NULL,
                                                Description VARCHAR(500)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- 2️⃣ Optional: prevent duplicate migration entries
-- ----------------------------
-- This is idempotent: re-running the script won't insert duplicates
INSERT INTO SchemaMigrations (MigrationId, AppliedAt, AppliedBy, Description)
SELECT '0000_schema_migrations', CURRENT_TIMESTAMP(6), CURRENT_USER(), 'Initial SchemaMigrations table'
WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0000_schema_migrations'
);
