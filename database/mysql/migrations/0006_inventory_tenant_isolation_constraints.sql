START TRANSACTION;

-- ========================================
-- 1. Fix PRODUCTS table
-- ========================================

-- Drop foreign keys that reference products
ALTER TABLE inventory DROP FOREIGN KEY IF EXISTS inventory_product_id_fk;

-- Remove AUTO_INCREMENT temporarily
ALTER TABLE products MODIFY id INT NOT NULL;

-- Drop existing primary key and add composite PK
ALTER TABLE products DROP PRIMARY KEY;
ALTER TABLE products ADD PRIMARY KEY (id, tenant_id);

-- Restore AUTO_INCREMENT (id is first column in PK now)
ALTER TABLE products MODIFY id INT NOT NULL AUTO_INCREMENT;

-- Add indexes for products
ALTER TABLE products
    ADD INDEX IF NOT EXISTS products_tenant_id_idx (tenant_id),
    ADD INDEX IF NOT EXISTS products_tenant_active_idx (tenant_id, is_active),
    ADD INDEX IF NOT EXISTS products_tenant_created_idx (tenant_id, created_at);

-- Add unique constraint for product name per tenant
ALTER TABLE products
    ADD UNIQUE INDEX IF NOT EXISTS products_tenant_name_uk (tenant_id, name, deleted_at);

-- ========================================
-- 2. Fix STORES table
-- ========================================

-- Drop foreign keys that reference stores
ALTER TABLE inventory DROP FOREIGN KEY IF EXISTS inventory_store_id_fk;

-- Remove AUTO_INCREMENT temporarily
ALTER TABLE stores MODIFY id INT NOT NULL;

-- Drop existing primary key and add composite PK
ALTER TABLE stores DROP PRIMARY KEY;
ALTER TABLE stores ADD PRIMARY KEY (id, tenant_id);

-- Restore AUTO_INCREMENT
ALTER TABLE stores MODIFY id INT NOT NULL AUTO_INCREMENT;

-- Add indexes for stores
ALTER TABLE stores
    ADD INDEX IF NOT EXISTS stores_tenant_id_idx (tenant_id),
    ADD INDEX IF NOT EXISTS stores_tenant_subdomain_idx (tenant_id, sub_domain),
    ADD INDEX IF NOT EXISTS stores_tenant_online_idx (tenant_id, is_online);

-- Add unique constraint for subdomain per tenant
ALTER TABLE stores
    ADD UNIQUE INDEX IF NOT EXISTS stores_tenant_subdomain_uk (tenant_id, sub_domain, deleted_at);

-- ========================================
-- 3. Handle INVENTORY table
-- ========================================

-- Ensure tenant_id is NOT NULL
ALTER TABLE inventory MODIFY tenant_id INT NOT NULL;

-- Drop existing constraints
ALTER TABLE inventory
DROP FOREIGN KEY IF EXISTS inventory_tenant_id_fk,
    DROP FOREIGN KEY IF EXISTS inventory_product_id_fk,
    DROP FOREIGN KEY IF EXISTS inventory_store_id_fk;

-- Drop existing indexes
ALTER TABLE inventory
DROP INDEX IF EXISTS inventory_store_product_uk,
DROP INDEX IF EXISTS inventory_tenant_id_idx,
DROP INDEX IF EXISTS inventory_tenant_store_idx,
DROP INDEX IF EXISTS inventory_tenant_product_idx;

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
    ADD UNIQUE INDEX inventory_tenant_store_product_uk (tenant_id, store_id, product_id, deleted_at);

-- Add tenant-scoped indexes
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
-- 4. Migration Record
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