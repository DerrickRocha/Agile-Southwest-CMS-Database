START TRANSACTION;

ALTER TABLE tax_categories ADD COLUMN tenant_id INT NOT NULL;
ALTER TABLE tax_categories ADD CONSTRAINT tax_category_tenant_fk FOREIGN KEY(tenant_id) REFERENCES tenants(id);
ALTER TABLE tax_categories ADD COLUMN deleted_at DATETIME NULL;

CREATE INDEX idx_tax_categories_tenant_id ON tax_categories(tenant_id);

INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0008_add_tax_category_relationships',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add tenants to tax categories'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0008_add_tax_category_relationships');

COMMIT;