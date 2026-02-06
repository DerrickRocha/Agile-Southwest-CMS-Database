START TRANSACTION;

-- --------------------------------------------------
-- Test: Tenants table exists
-- --------------------------------------------------
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Tenants'
        )
            THEN 1
        ELSE 1 / 0
        END AS tenants_table_exists;

-- --------------------------------------------------
-- Test: Stores.TenantId column exists
-- --------------------------------------------------
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Stores'
              AND COLUMN_NAME = 'TenantId'
        )
            THEN 1
        ELSE 1 / 0
        END AS stores_tenantid_exists;

-- --------------------------------------------------
-- Test: Products.StoreId column exists
-- --------------------------------------------------
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Products'
              AND COLUMN_NAME = 'StoreId'
        )
            THEN 1
        ELSE 1 / 0
        END AS products_storeid_exists;

ROLLBACK;

