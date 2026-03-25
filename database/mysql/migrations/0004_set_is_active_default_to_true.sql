START TRANSACTION;

ALTER TABLE products ALTER COLUMN is_active SET DEFAULT true;

INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)

SELECT '0004_set_is_active_default_to_true',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Setting default value for is_active column to true'
    WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0004_set_is_active_default_to_true');

COMMIT;