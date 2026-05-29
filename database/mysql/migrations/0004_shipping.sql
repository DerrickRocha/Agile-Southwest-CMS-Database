-- ----------------------------------------
-- 0004_shipping.sql
-- Shipping
-- ----------------------------------------

START TRANSACTION;

-- Define geographic boundaries
CREATE TABLE IF NOT EXISTS shipping_zones
(
    id             INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id      INT          NOT NULL,
    name           VARCHAR(100) NOT NULL, -- e.g., "Local Delivery", "Domestic East"
    is_local_fleet BOOLEAN               DEFAULT FALSE,
    created_at     DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at     DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at     DATETIME(6)  NULL,
    row_version    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT zone_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- Store postal codes or regions for each zone
CREATE TABLE IF NOT EXISTS zone_postal_codes
(
    id               INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id        INT         NOT NULL,
    shipping_zone_id INT         NOT NULL,
    postal_code      VARCHAR(20) NOT NULL, -- e.g., "10001" or wildcards like "100*"
    created_at       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at       DATETIME(6) NULL,
    row_version      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT zone_postal_code_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT zone_postal_code_shipping_zone_fk FOREIGN KEY (shipping_zone_id) REFERENCES shipping_zones (id) ON DELETE CASCADE,
    INDEX idx_shipping_zone (shipping_zone_id),
    INDEX idx_postal_code_lookup (tenant_id, postal_code)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='Postal codes/ZIPs assigned to shipping zones. Supports wildcards like "100*" for prefix matching.';

-- Define weight-based or flat rates per zone
CREATE TABLE IF NOT EXISTS shipping_rates
(
    id               INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id        INT            NOT NULL,
    shipping_zone_id INT            NOT NULL,
    rate_name        VARCHAR(100), -- e.g., "Heavy Tier", "Standard Flat"
    min_weight       DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    max_weight       DECIMAL(10, 2) NULL COMMENT 'NULL means no upper bound',
    price            DECIMAL(10, 2) NOT NULL,
    created_at       DATETIME(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at       DATETIME(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at       DATETIME(6)    NULL,
    row_version      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT shipping_rate_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT shipping_rate_shipping_zone_fk FOREIGN KEY (shipping_zone_id) REFERENCES shipping_zones (id) ON DELETE CASCADE,
    CONSTRAINT chk_weight_range CHECK (min_weight <= max_weight),
    CONSTRAINT chk_weight_values CHECK (
        (min_weight IS NULL OR min_weight >= 0) AND
        (max_weight IS NULL OR max_weight >= 0) AND
        (min_weight IS NULL OR max_weight IS NULL OR min_weight <= max_weight)
        ),
    INDEX idx_shipping_zone (shipping_zone_id),
    INDEX idx_rate_weight_range (tenant_id, shipping_zone_id, min_weight, max_weight)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='Shipping rate rules. Rates are evaluated in order of min_weight. First rate where order weight between min_weight and max_weight (inclusive) applies. If max_weight is NULL, applies to all weights above min_weight.';

INSERT INTO schema_migrations (migration_id,
                               applied_by,
                               description)
SELECT '0004_shipping',
       CURRENT_USER(),
       'Shipping'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0004_shipping');

COMMIT;