START TRANSACTION;

ALTER TABLE order_items ADD COLUMN weight_grams INT NULL;
ALTER TABLE shipping_restrictions MODIFY COLUMN type ENUM('ExcludeLocation', 'MaxWeightGrams', 'MaxQuantity', 'MinOrderValue', 'MaxOrderValue');
ALTER TABLE shipping_rate_rules MODIFY COLUMN condition_type ENUM('Subtotal', 'Weight', 'Quantity', 'Distance', 'Price') NOT NULL;
ALTER TABLE customers ADD COLUMN tenant_id INT NULL;
ALTER TABLE customers ADD CONSTRAINT customer_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
ALTER TABLE customers ADD INDEX idx_tenant_id (tenant_id);
ALTER TABLE orders
    DROP FOREIGN KEY orders_customer_fk; -- Drop if exists

ALTER TABLE orders
    ADD CONSTRAINT orders_customer_fk
        FOREIGN KEY (customer_id, tenant_id)
            REFERENCES customers(id, tenant_id)
            ON DELETE SET NULL;

ALTER TABLE orders
    ADD COLUMN shipping_method_id INT NULL,
    ADD CONSTRAINT orders_shipping_method_fk
        FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(id) ON DELETE SET NULL;

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
                                                             latitude DECIMAL(10,8) NOT NULL,  -- Store coordinates directly
                                                             longitude DECIMAL(11,8) NOT NULL, -- Store coordinates directly
                                                             is_active BOOLEAN NOT NULL DEFAULT TRUE,
                                                             created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                             updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                             INDEX idx_tenant_id (tenant_id),
                                                             INDEX idx_is_primary (is_primary),
                                                             INDEX idx_is_active (is_active),
                                                             FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX idx_customers_tenant_user ON customers(tenant_id, user_id);
CREATE INDEX idx_order_items_weight ON order_items(weight_grams);
CREATE INDEX idx_orders_shipping_method ON orders(shipping_method_id, status);


INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0006_add_weight_grams_and_remove_exclude_product_category',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add weight_grams to order_items and remove exclude_product_category from shipping_restrictions.type.'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0006_add_weight_grams_and_remove_exclude_product_category');
COMMIT;