-- ----------------------------------------
-- 0004_shipping.sql
-- Shipping
-- ----------------------------------------

START TRANSACTION;

-- Define weight-based or flat rates per zone
CREATE TABLE IF NOT EXISTS shipping_rates
(
    id               INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id        INT            NOT NULL,
    rate_name        VARCHAR(100) NOT NULL, -- e.g., "Heavy Tier", "Standard Flat, Local  Ground"
    postal_code VARCHAR(20) DEFAULT '*', -- e.g., "100*", "94025", or "*"
    min_weight_grams       DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    max_weight_grams       DECIMAL(10, 2) NULL COMMENT 'NULL means no upper bound',
    price_cents            INT NOT NULL,
    created_at       DATETIME(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at       DATETIME(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at       DATETIME(6)    NULL,
    row_version      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT shipping_rate_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT chk_weight_range CHECK (min_weight_grams <= max_weight_grams),
    CONSTRAINT chk_weight_values CHECK (
        (min_weight_grams IS NULL OR min_weight_grams >= 0) AND
        (max_weight_grams IS NULL OR max_weight_grams >= 0) AND
        (min_weight_grams IS NULL OR max_weight_grams IS NULL OR min_weight_grams <= max_weight_grams)
        )
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