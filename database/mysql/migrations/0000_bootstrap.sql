-- ----------------------------
-- 1️⃣ Create SchemaMigrations table if it doesn't exist
-- ----------------------------

START TRANSACTION;

CREATE TABLE IF NOT EXISTS SchemaMigrations (
                                                MigrationId VARCHAR(150) PRIMARY KEY,
                                                AppliedAt   DATETIME(6) NOT NULL,
                                                AppliedBy   VARCHAR(128) NOT NULL,
                                                Description VARCHAR(500)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
SELECT
    '0000_bootstrap',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Schema migrations table'
WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0000_bootstrap'
);

COMMIT;
