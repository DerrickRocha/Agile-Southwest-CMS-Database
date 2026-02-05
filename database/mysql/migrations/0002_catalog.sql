-- ----------------------------------------
-- 0002_catalog.sql
-- Product catalog
-- ----------------------------------------

START TRANSACTION;

-- ----------------------------------------
-- 1️⃣ Products
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS Products (
                                        ProductId BINARY(16) PRIMARY KEY,
                                        TenantId  BINARY(16) NOT NULL,
                                        Name      VARCHAR(200) NOT NULL,
                                        Description TEXT,
                                        Price     DECIMAL(10,2) NOT NULL,
                                        IsActive  TINYINT(1) NOT NULL DEFAULT 1,
                                        CreatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                        UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                        CONSTRAINT fk_products_tenant
                                            FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
                                                ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------
-- 2️⃣ Product Options
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS ProductOptions (
                                              ProductOptionId BINARY(16) PRIMARY KEY,
                                              ProductId       BINARY(16) NOT NULL,
                                              Name            VARCHAR(100) NOT NULL,
                                              CreatedAt       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                              UpdatedAt       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                              CONSTRAINT fk_productoptions_product
                                                  FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
                                                      ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------
-- 3️⃣ Record migration (idempotent)
-- ----------------------------------------
INSERT INTO SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
SELECT
    '0002_catalog',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Product catalog'
WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0002_catalog'
);

COMMIT;
