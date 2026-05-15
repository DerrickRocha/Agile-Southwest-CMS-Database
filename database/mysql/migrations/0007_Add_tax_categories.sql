START TRANSACTION;



CREATE TABLE IF NOT EXISTS tax_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    tax_rate DECIMAL NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE products ADD COLUMN tax_category_id INT NULL;
ALTER TABLE products ADD CONSTRAINT products_tax_category_fk FOREIGN KEY (tax_category_id) REFERENCES tax_categories(id);

ALTER TABLE order_items ADD COLUMN tax_category_id INT NULL;
ALTER TABLE order_items ADD CONSTRAINT order_items_tax_category_fk FOREIGN KEY (tax_category_id) REFERENCES tax_categories(id);

INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0007_Add_tax_categories',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add tax_categories table and and taxt_category_id to products'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0007_Add_tax_categories');

COMMIT;