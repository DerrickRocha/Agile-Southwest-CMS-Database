BEGIN TRANSACTION;

-- Tenants
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'app' AND TABLE_NAME = 'Tenants'
)
    THROW 51001, 'Tenants table missing', 1;

-- Stores
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'app'
      AND TABLE_NAME = 'Stores'
      AND COLUMN_NAME = 'TenantId'
)
    THROW 51002, 'Stores.TenantId missing', 1;

-- Products.StoreId
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'app'
      AND TABLE_NAME = 'Products'
      AND COLUMN_NAME = 'StoreId'
)
    THROW 51003, 'Products.StoreId missing', 1;

ROLLBACK TRANSACTION;
