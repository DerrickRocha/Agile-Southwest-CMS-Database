-- ----------------------------
-- 1️⃣ Create SchemaMigrations table if it doesn't exist
-- ----------------------------

START TRANSACTION;

CREATE TABLE IF NOT EXISTS schema_migrations (
                                                migration_id VARCHAR(150) PRIMARY KEY,
                                                applied_at   DATETIME(6) NOT NULL,
                                                applied_by   VARCHAR(128) NOT NULL,
                                                description VARCHAR(500)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO schema_migrations (
    migration_id,
    applied_at,
    applied_by,
    description
)
SELECT
    '0000_bootstrap',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Schema migrations table'
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations WHERE migration_id = '0000_bootstrap'
);

COMMIT;
