/* ============================================================
   0009_add_store_unique_index
   Adds unique constraint on Stores(TenantId, IsDefault)
   ============================================================ */

START TRANSACTION;

-- Add unique key if it doesn't exist
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Stores'
              AND CONSTRAINT_NAME = 'uq_stores_tenant_default'
        ),
        'SELECT 1;',
        'ALTER TABLE Stores
         ADD CONSTRAINT uq_stores_tenant_default UNIQUE (TenantId, IsDefault);'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Record migration
INSERT INTO SchemaMigrations
SELECT '0009_add_store_unique_index',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add unique constraint on Stores(TenantId, IsDefault)'
    WHERE NOT EXISTS (
    SELECT 1
    FROM SchemaMigrations
    WHERE MigrationId = '0009_add_store_unique_index'
);

COMMIT;
