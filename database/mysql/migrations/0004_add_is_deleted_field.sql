START TRANSACTION;

ALTER TABLE products 
    ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE, 
    ADD COLUMN deleted_at DATETIME(6) NULL;

ALTER TABLE product_options
    ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN deleted_at DATETIME(6) NULL;

ALTER TABLE product_option_choices
    ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN deleted_at DATETIME(6) NULL;

INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0004_add_is_deleted_field',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add is_deleted field to products table'
    WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0004_add_is_deleted_field');
COMMIT;