-- ----------------------------------------
-- 0004_inventory.sql
-- Inventory & stock
-- ----------------------------------------

START TRANSACTION;

CREATE TABLE IF NOT EXISTS Inventory (
                                         InventoryId      BINARY(16) PRIMARY KEY,
    TenantId         BINARY(16) NOT NULL,
    ProductId        BINARY(16) NOT NULL,
    QuantityOnHand   INT NOT NULL,
    QuantityReserved INT NOT NULL DEFAULT 0,
    UpdatedAt        DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_inventory_tenant
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    ON DELETE CASCADE,
    CONSTRAINT fk_inventory_product
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
    ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO SchemaMigrations
SELECT '0004_inventory', CURRENT_TIMESTAMP(6), CURRENT_USER(), 'Inventory & stock'
    WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0004_inventory'
);

COMMIT;
