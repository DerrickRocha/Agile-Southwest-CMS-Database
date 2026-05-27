START TRANSACTION;

-- Define geographic boundaries
CREATE TABLE  IF NOT EXISTS shipping_zones
(
    id             INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id      INT NOT NULL,
    name           VARCHAR(100), -- e.g., "Local Delivery", "Domestic East"
    is_local_fleet BOOLEAN DEFAULT FALSE,
    CONSTRAINT zone_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
);

-- Store postal codes or regions for each zone
CREATE TABLE IF NOT EXISTS zone_postal_codes
(
    id          INT PRIMARY KEY,
    tenant_id   INT NOT NULL,
    shipping_zone_id     INT REFERENCES shipping_zones (id),
    postal_code VARCHAR(20), -- e.g., "10001" or wildcards like "100*"
    CONSTRAINT zone_postal_code_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT zone_postal_code_shipping_zone_fk FOREIGN KEY (shipping_zone_id) REFERENCES shipping_zones (id) ON DELETE CASCADE
);

-- Define weight-based or flat rates per zone
CREATE TABLE IF NOT EXISTS shipping_rates
(
    id         INT PRIMARY KEY,
    tenant_id  INT NOT NULL,
    shipping_zone_id    INT REFERENCES shipping_zones (id),
    rate_name  VARCHAR(100), -- e.g., "Heavy Tier", "Standard Flat"
    min_weight DECIMAL(10, 2) DEFAULT 0.00,
    max_weight DECIMAL(10, 2),
    price      DECIMAL(10, 2) NOT NULL,

    CONSTRAINT shipping_rate_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT shipping_rate_shipping_zone_fk FOREIGN KEY (shipping_zone_id) REFERENCES shipping_zones (id) ON DELETE CASCADE
);

INSERT INTO schema_migrations (
    migration_id,
    applied_at,
    applied_by,
    description
)
SELECT
    '0004_shipping',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Shipping'
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations WHERE migration_id = '0004_shipping'
);

COMMIT;