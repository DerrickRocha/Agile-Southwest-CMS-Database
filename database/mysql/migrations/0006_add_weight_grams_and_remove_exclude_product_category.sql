START TRANSACTION;

-- 1. Add weight_grams to order_items
ALTER TABLE order_items ADD COLUMN weight_grams INT NULL;

-- 2. Update ENUM types
ALTER TABLE shipping_restrictions
    MODIFY COLUMN type ENUM('ExcludeLocation', 'MaxWeightGrams', 'MaxQuantity', 'MinOrderValue', 'MaxOrderValue') NOT NULL;

ALTER TABLE shipping_rate_rules
    MODIFY COLUMN condition_type ENUM('Subtotal', 'Weight', 'Quantity', 'Distance', 'Price') NOT NULL;

-- 3. Add tenant_id to customers (temporarily nullable)
ALTER TABLE customers ADD COLUMN tenant_id INT NULL;

-- 5. Make tenant_id NOT NULL after populating
ALTER TABLE customers MODIFY COLUMN tenant_id INT NOT NULL;

-- 6. Drop the existing primary key (if needed) and add composite primary key
-- First, check if there are any foreign keys referencing customers.id
-- You already dropped orders_customer_fk, so this should be fine
ALTER TABLE customers DROP PRIMARY KEY;
ALTER TABLE customers ADD PRIMARY KEY (id, tenant_id);

-- 7. Add foreign key and indexes for customers
ALTER TABLE customers ADD CONSTRAINT customer_tenant_fk
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

ALTER TABLE customers ADD INDEX idx_tenant_id (tenant_id);

-- 8. Add row_version to customers if not exists
ALTER TABLE customers ADD COLUMN IF NOT EXISTS row_version TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- 9. Drop existing foreign key from orders (if it exists)
ALTER TABLE orders DROP FOREIGN KEY IF EXISTS orders_customer_fk;


-- 11. Recreate the foreign key with composite reference
ALTER TABLE orders
    ADD CONSTRAINT orders_customer_fk
        FOREIGN KEY (customer_id, tenant_id)
            REFERENCES customers(id, tenant_id)
            ON DELETE SET NULL;

-- 12. Add shipping_method_id to orders
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS shipping_method_id INT NULL,
    ADD CONSTRAINT orders_shipping_method_fk
    FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(id) ON DELETE SET NULL;

-- 13. Create warehouse_fulfillment_centers table (only if doesn't exist)
CREATE TABLE IF NOT EXISTS warehouse_fulfillment_centers (
                                                             id INT PRIMARY KEY AUTO_INCREMENT,
                                                             tenant_id INT NOT NULL,
                                                             name VARCHAR(255) NOT NULL,
                                                             is_primary BOOLEAN NOT NULL DEFAULT FALSE,
                                                             address_line1 VARCHAR(255) NOT NULL,
                                                             address_line2 VARCHAR(255) NULL,
                                                             city VARCHAR(100) NOT NULL,
                                                             state VARCHAR(50) NOT NULL,
                                                             postal_code VARCHAR(20) NOT NULL,
                                                             country VARCHAR(3) NOT NULL,
                                                             latitude DECIMAL(10,8) NOT NULL,
                                                             longitude DECIMAL(11,8) NOT NULL,
                                                             is_active BOOLEAN NOT NULL DEFAULT TRUE,
                                                             created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                             updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                             INDEX idx_tenant_id (tenant_id),
                                                             INDEX idx_is_primary (is_primary),
                                                             INDEX idx_is_active (is_active),
                                                             FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- 14. Add indexes
CREATE INDEX idx_customers_tenant_user ON customers(tenant_id, user_id);
CREATE INDEX idx_order_items_weight ON order_items(weight_grams);
CREATE INDEX idx_orders_shipping_method ON orders(shipping_method_id, status);

-- 15. Record migration
INSERT INTO schema_migrations (migration_id, applied_at, applied_by, description)
SELECT '0006_add_weight_grams_and_shipping_updates',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add weight_grams to order_items, update customer tenant relationship, add warehouse table'
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations
                  WHERE migration_id = '0006_add_weight_grams_and_shipping_updates');

COMMIT;