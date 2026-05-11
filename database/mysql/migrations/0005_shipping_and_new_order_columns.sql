START TRANSACTION;

ALTER TABLE orders MODIFY fulfillment_status ENUM('fulfilled', 'unfulfilled', 'partial');
ALTER TABLE orders MODIFY currency ENUM('USD', 'CAD', 'EUR', 'GBP', 'AUD', 'NZD');
ALTER TABLE orders MODIFY payment_processor ENUM('stripe', 'aeropay');
ALTER TABLE orders MODIFY order_type ENUM('standard', 'subscription');

CREATE TABLE IF NOT EXISTS shipping_methods (
                                                id INT PRIMARY KEY AUTO_INCREMENT,
                                                tenant_id INT NOT NULL,
                                                name VARCHAR(255) NOT NULL,
                                                description TEXT,
                                                display_order INT NOT NULL DEFAULT 0,
                                                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                                                pricing_strategy ENUM('Flat', 'Weight', 'Price', 'Carrier', 'Free') NOT NULL,
                                                carrier_name VARCHAR(100) NULL,
                                                carrier_service_code VARCHAR(100) NULL,
                                                estimated_min_days INT NOT NULL DEFAULT 1,
                                                estimated_max_days INT NOT NULL DEFAULT 7,
                                                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                deleted_at DATETIME NULL,
                                                INDEX idx_tenant_id (tenant_id),
                                                INDEX idx_is_active (is_active),
                                                INDEX idx_deleted_at (deleted_at),
                                                FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS shipping_rate_rules (
                                                   id INT PRIMARY KEY AUTO_INCREMENT,
                                                   shipping_method_id INT NOT NULL,
                                                   condition_type ENUM('Subtotal', 'Weight', 'Quantity', 'Distance') NOT NULL,
                                                   min_value DECIMAL(15,2) NULL,
                                                   max_value DECIMAL(15,2) NULL,
                                                   base_price_cents DECIMAL(15,2) NOT NULL DEFAULT 0,
                                                   price_per_unit_cents DECIMAL(15,2) NULL,
                                                   free_shipping_threshold_cents DECIMAL(15,2) NULL,
                                                   priority INT NOT NULL DEFAULT 0,
                                                   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                   INDEX idx_shipping_method_id (shipping_method_id),
                                                   INDEX idx_condition_type (condition_type),
                                                   INDEX idx_priority (priority),
                                                   FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS shipping_zones (
                                              id INT PRIMARY KEY AUTO_INCREMENT,
                                              tenant_id INT NOT NULL,
                                              name VARCHAR(255) NOT NULL,
                                              is_active BOOLEAN NOT NULL DEFAULT TRUE,
                                              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                              updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                              deleted_at DATETIME NULL,
                                              INDEX idx_tenant_id (tenant_id),
                                              INDEX idx_is_active (is_active),
                                              INDEX idx_deleted_at (deleted_at),
                                              FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS shipping_zone_methods (
                                                     shipping_zone_id INT NOT NULL,
                                                     shipping_method_id INT NOT NULL,
                                                     created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                     PRIMARY KEY (shipping_zone_id, shipping_method_id),
                                                     FOREIGN KEY (shipping_zone_id) REFERENCES shipping_zones(id) ON DELETE CASCADE,
                                                     FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS shipping_zone_locations (
                                                       id INT PRIMARY KEY AUTO_INCREMENT,
                                                       shipping_zone_id INT NOT NULL,
                                                       type ENUM('Country', 'StateProvince', 'PostalCode', 'Continent', 'Radius') NOT NULL,
                                                       code VARCHAR(100) NOT NULL,
                                                       name VARCHAR(255) NULL,
                                                       latitude DECIMAL(10,8) NULL,
                                                       longitude DECIMAL(11,8) NULL,
                                                       radius_km INT NULL,
                                                       created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                       updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                       INDEX idx_shipping_zone_id (shipping_zone_id),
                                                       INDEX idx_type (type),
                                                       INDEX idx_code (code),
                                                       UNIQUE KEY uk_zone_location (shipping_zone_id, type, code),
                                                       FOREIGN KEY (shipping_zone_id) REFERENCES shipping_zones(id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS shipping_restrictions (
                                                     id INT PRIMARY KEY AUTO_INCREMENT,
                                                     shipping_method_id INT NOT NULL,
                                                     type ENUM('ExcludeLocation', 'MaxWeightGrams', 'MaxQuantity', 'ExcludeProductCategory', 'MinOrderValue', 'MaxOrderValue') NOT NULL,
                                                     value TEXT NOT NULL,
                                                     message TEXT NULL,
                                                     created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                     updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                     INDEX idx_shipping_method_id (shipping_method_id),
                                                     INDEX idx_type (type),
                                                     FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;




INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0005_shipping_and_new_order_columns',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add shipping and new order columns'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0005_shipping_and_new_order_columns');
COMMIT;
