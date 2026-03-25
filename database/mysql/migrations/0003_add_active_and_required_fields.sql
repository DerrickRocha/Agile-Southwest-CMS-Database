START TRANSACTION;

ALTER TABLE product_options ADD COLUMN is_required BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE product_option_choices ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;


INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0003_add_active_and_required_fields',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add active and required fields to product_options and product_option_choices'
    WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0003_add_active_and_required_fields');

COMMIT;