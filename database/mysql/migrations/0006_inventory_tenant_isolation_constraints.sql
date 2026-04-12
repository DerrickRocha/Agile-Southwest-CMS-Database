START TRANSACTION;

-- ========================================
-- 1. Handle Products Table
-- ========================================

-- Drop foreign keys that reference products
ALTER TABLE inventory DROP FOREIGN KEY IF EXISTS inventory_product_id_fk;

-- Drop existing primary key and add composite PK
ALTER TABLE products DROP PRIMARY KEY;
ALTER TABLE products ADD PRIMARY KEY (id, tenant_id);

-- Add tenant_id to products if missing (safety check)
ALTER TABLE products MODIFY COLUMN tenant_id INT NOT NULL;

-- Add indexes for products
ALTER TABLE products
    ADD INDEX IF NOT EXISTS products_tenant_id_idx (tenant_id),
    ADD INDEX IF NOT EXISTS products_tenant_active_idx (tenant_id, is_active),
    ADD INDEX IF NOT EXISTS products_tenant_created_idx (tenant_id, created_at);

-- Add unique constraint for product name per tenant
ALTER TABLE products
    ADD UNIQUE INDEX IF NOT EXISTS products_tenant_name_uk (tenant_id, name, deleted_at);

-- ========================================
-- 2. Handle Stores Table
-- ========================================

-- Drop foreign keys that reference stores
ALTER TABLE inventory DROP FOREIGN KEY IF EXISTS inventory_store_id_fk;

-- Drop existing primary key and add composite PK
ALTER TABLE stores DROP PRIMARY KEY;
ALTER TABLE stores ADD PRIMARY KEY (id, tenant_id);

-- Ensure tenant_id is NOT NULL
ALTER TABLE stores MODIFY COLUMN tenant_id INT NOT NULL;

-- Add indexes for stores
ALTER TABLE stores
    ADD INDEX IF NOT EXISTS stores_tenant_id_idx (tenant_id),
    ADD INDEX IF NOT EXISTS stores_tenant_subdomain_idx (tenant_id, sub_domain),
    ADD INDEX IF NOT EXISTS stores_tenant_online_idx (tenant_id, is_online);

-- Add unique constraint for subdomain per tenant
ALTER TABLE stores
    ADD UNIQUE INDEX IF NOT EXISTS stores_tenant_subdomain_uk (tenant_id, sub_domain, deleted_at);

-- ========================================
-- 3. Handle Inventory Table
-- ========================================

-- Add tenant_id if missing (should already exist)
ALTER TABLE inventory MODIFY COLUMN tenant_id INT NOT NULL;

-- Drop existing constraints and indexes (clean slate)
ALTER TABLE inventory
DROP FOREIGN KEY IF EXISTS inventory_tenant_id_fk,
    DROP FOREIGN KEY IF EXISTS inventory_product_id_fk,
    DROP FOREIGN KEY IF EXISTS inventory_store_id_fk,
DROP INDEX IF EXISTS inventory_store_product_uk,
DROP INDEX IF EXISTS inventory_tenant_id_idx,
DROP INDEX IF EXISTS inventory_tenant_store_idx,
DROP INDEX IF EXISTS inventory_tenant_product_idx,
DROP INDEX IF EXISTS inventory_tenant_quantity_idx;

-- Add composite foreign keys
ALTER TABLE inventory
    ADD CONSTRAINT inventory_tenant_id_fk
        FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    ADD CONSTRAINT inventory_product_id_fk 
        FOREIGN KEY (product_id, tenant_id) REFERENCES products(id, tenant_id) ON DELETE RESTRICT,
    ADD CONSTRAINT inventory_store_id_fk 
        FOREIGN KEY (store_id, tenant_id) REFERENCES stores(id, tenant_id) ON DELETE CASCADE;

-- Add unique constraint with tenant_id
ALTER TABLE inventory
    ADD UNIQUE KEY inventory_tenant_store_product_uk (tenant_id, store_id, product_id, deleted_at);

-- Add tenant-scoped indexes (tenant_id should be first for RLS)
ALTER TABLE inventory
    ADD INDEX inventory_tenant_id_idx (tenant_id),
    ADD INDEX inventory_tenant_store_idx (tenant_id, store_id),
    ADD INDEX inventory_tenant_product_idx (tenant_id, product_id),
    ADD INDEX inventory_tenant_quantity_idx (tenant_id, quantity),
    ADD INDEX inventory_tenant_updated_idx (tenant_id, updated_at),
    ADD INDEX inventory_tenant_deleted_idx (tenant_id, deleted_at);

-- Add check constraint for quantity
ALTER TABLE inventory
    ADD CONSTRAINT inventory_quantity_check CHECK (quantity >= 0);

-- ========================================
-- 4. Additional Constraints for Data Integrity
-- ========================================

-- Ensure products.base_price_cents is non-negative
ALTER TABLE products
    ADD CONSTRAINT products_base_price_check CHECK (base_price_cents >= 0);

-- ========================================
-- 5. Migration Record
-- ========================================

INSERT INTO schema_migrations (migration_id, applied_at, applied_by, description)
SELECT '0006_inventory_tenant_isolation_constraints',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add tenant isolation constraints and indexes to products, stores, and inventory'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE migration_id = '0006_inventory_tenant_isolation_constraints'
);

COMMIT;

-- ========================================
-- 6. Verification Queries (Run after commit)
-- ========================================

-- Verify primary keys
SELECT
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
  AND table_name IN ('products', 'stores', 'inventory')
  AND constraint_type = 'PRIMARY KEY';

-- Verify foreign keys
SELECT
    constraint_name,
    table_name,
    column_name,
    referenced_table_name,
    referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = DATABASE()
  AND table_name = 'inventory'
  AND referenced_table_name IS NOT NULL;

-- Verify indexes
SELECT
    table_name,
    index_name,
    column_name,
    seq_in_index
FROM information_schema.statistics
WHERE table_schema = DATABASE()
  AND table_name IN ('products', 'stores', 'inventory')
ORDER BY table_name, index_name, seq_in_index;