/* ============================================================
   0008_add_stores_and_store_scoping
   Adds StoreId scoping to Products, Inventory, Orders
   ============================================================ */

START TRANSACTION;

-- ------------------------------------------------------------
-- 1️⃣ Create Stores table if not exists
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Stores (
                                      StoreId     BINARY(16) PRIMARY KEY,
                                      TenantId    BINARY(16) NOT NULL,
                                      Name        VARCHAR(200) NOT NULL,
                                      IsDefault   TINYINT(1) NOT NULL DEFAULT 0,
                                      CreatedAt   DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                      UpdatedAt   DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
                                      CONSTRAINT fk_stores_tenant FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
                                      UNIQUE KEY uq_stores_tenant_default (TenantId, IsDefault)
);

-- ------------------------------------------------------------
-- Add StoreId column to Products
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Products'
                         AND COLUMN_NAME = 'StoreId'
                   ),
                   'SELECT 1;',
                   'ALTER TABLE Products ADD COLUMN StoreId BINARY(16) NULL;'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Add StoreId column to Inventory
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Inventory'
                         AND COLUMN_NAME = 'StoreId'
                   ),
                   'SELECT 1;',
                   'ALTER TABLE Inventory ADD COLUMN StoreId BINARY(16) NULL;'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Add StoreId column to Orders
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Orders'
                         AND COLUMN_NAME = 'StoreId'
                   ),
                   'SELECT 1;',
                   'ALTER TABLE Orders ADD COLUMN StoreId BINARY(16) NULL;'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Backfill StoreId using default store
-- ------------------------------------------------------------
UPDATE Products p
    JOIN Stores s
    ON s.TenantId = p.TenantId
        AND s.IsDefault = 1
SET p.StoreId = s.StoreId
WHERE p.StoreId IS NULL;

UPDATE Inventory i
    JOIN Stores s
    ON s.TenantId = i.TenantId
        AND s.IsDefault = 1
SET i.StoreId = s.StoreId
WHERE i.StoreId IS NULL;

UPDATE Orders o
    JOIN Stores s
    ON s.TenantId = o.TenantId
        AND s.IsDefault = 1
SET o.StoreId = s.StoreId
WHERE o.StoreId IS NULL;

-- ------------------------------------------------------------
-- Enforce NOT NULL
-- ------------------------------------------------------------
ALTER TABLE Products  MODIFY StoreId BINARY(16) NOT NULL;
ALTER TABLE Inventory MODIFY StoreId BINARY(16) NOT NULL;
ALTER TABLE Orders    MODIFY StoreId BINARY(16) NOT NULL;

-- ------------------------------------------------------------
-- Foreign keys (guarded)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Products'
                         AND CONSTRAINT_NAME = 'fk_products_store'
                   ),
                   'SELECT 1;',
                   'ALTER TABLE Products
                    ADD CONSTRAINT fk_products_store
                    FOREIGN KEY (StoreId) REFERENCES Stores(StoreId);'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Inventory'
                         AND CONSTRAINT_NAME = 'fk_inventory_store'
                   ),
                   'SELECT 1;',
                   'ALTER TABLE Inventory
                    ADD CONSTRAINT fk_inventory_store
                    FOREIGN KEY (StoreId) REFERENCES Stores(StoreId);'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Orders'
                         AND CONSTRAINT_NAME = 'fk_orders_store'
                   ),
                   'SELECT 1;',
                   'ALTER TABLE Orders
                    ADD CONSTRAINT fk_orders_store
                    FOREIGN KEY (StoreId) REFERENCES Stores(StoreId);'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Indexes (guarded)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Products'
                         AND INDEX_NAME = 'ix_products_tenant_store'
                   ),
                   'SELECT 1;',
                   'CREATE INDEX ix_products_tenant_store ON Products (TenantId, StoreId);'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Inventory'
                         AND INDEX_NAME = 'ix_inventory_tenant_store'
                   ),
                   'SELECT 1;',
                   'CREATE INDEX ix_inventory_tenant_store ON Inventory (TenantId, StoreId);'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := (
    SELECT IF(
                   EXISTS (
                       SELECT 1
                       FROM INFORMATION_SCHEMA.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'Orders'
                         AND INDEX_NAME = 'ix_orders_tenant_store'
                   ),
                   'SELECT 1;',
                   'CREATE INDEX ix_orders_tenant_store ON Orders (TenantId, StoreId);'
           )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Record migration
-- ------------------------------------------------------------
INSERT INTO SchemaMigrations
SELECT
    '0008_add_stores_and_store_scoping',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Stores and store scoping'
WHERE NOT EXISTS (
    SELECT 1
    FROM SchemaMigrations
    WHERE MigrationId = '0008_add_stores_and_store_scoping'
);

COMMIT;
