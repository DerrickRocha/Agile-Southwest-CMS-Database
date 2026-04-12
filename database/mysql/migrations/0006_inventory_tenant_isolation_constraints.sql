START TRANSACTION;

-- ========================================
-- 1. Drop ALL foreign keys that reference products.id
-- ========================================

ALTER TABLE inventory DROP FOREIGN KEY inventory_product_id_fk;
ALTER TABLE product_options DROP FOREIGN KEY product_option_product_fk;
ALTER TABLE product_images DROP FOREIGN KEY image_product_fk;
-- Note: product_option_choices doesn't directly reference products, so no need

-- ========================================
-- 2. Fix PRODUCTS table
-- ========================================

-- Remove AUTO_INCREMENT temporarily
ALTER TABLE products MODIFY id INT NOT NULL;

-- Drop existing primary key and add composite PK
ALTER TABLE products DROP PRIMARY KEY;
ALTER TABLE products ADD PRIMARY KEY (id, tenant_id);

-- Restore AUTO_INCREMENT (id is first column in PK now)
ALTER TABLE products MODIFY id INT NOT NULL AUTO_INCREMENT;

-- Add indexes for products
ALTER TABLE products
    ADD INDEX products_tenant_id_idx (tenant_id),
    ADD INDEX products_tenant_active_idx (tenant_id, is_active),
    ADD INDEX products_tenant_created_idx (tenant_id, created_at);

-- Add unique constraint for product name per tenant
ALTER TABLE products
    ADD UNIQUE INDEX products_tenant_name_uk (tenant_id, name, deleted_at);

-- ========================================
-- 3. Update child tables to include tenant_id (for consistency)
-- ========================================

-- Add tenant_id to product_options
ALTER TABLE product_options
    ADD COLUMN tenant_id INT NOT NULL AFTER product_id,
    MODIFY product_id INT NOT NULL;

-- Add tenant_id to product_option_choices (inherits from product_options)
ALTER TABLE product_option_choices
    ADD COLUMN IF NOT EXISTS tenant_id INT NOT NULL AFTER option_id;

-- Add tenant_id to product_images
ALTER TABLE product_images
    ADD COLUMN IF NOT EXISTS tenant_id INT NOT NULL AFTER product_id,
DROP FOREIGN KEY IF EXISTS image_product_fk,
    MODIFY product_id INT NOT NULL;

-- ========================================
-- 4. Rebuild foreign keys with tenant_id
-- ========================================

-- Product options foreign key
ALTER TABLE product_options
    ADD CONSTRAINT product_option_product_fk
        FOREIGN KEY (product_id, tenant_id)
            REFERENCES products(id, tenant_id)
            ON DELETE CASCADE;

-- Product images foreign key
ALTER TABLE product_images
    ADD CONSTRAINT image_product_fk
        FOREIGN KEY (product_id, tenant_id)
            REFERENCES products(id, tenant_id)
            ON DELETE CASCADE;

-- Product option choices foreign key (still references product_options.id)
ALTER TABLE product_option_choices
DROP FOREIGN KEY IF EXISTS product_option_choice_option_fk,
    ADD CONSTRAINT product_option_choice_option_fk 
    FOREIGN KEY (option_id, tenant_id) 
    REFERENCES product_options(id, tenant_id) 
    ON DELETE CASCADE;

-- ========================================
-- 5. Add indexes to child tables for tenant isolation
-- ========================================

ALTER TABLE product_options
    ADD INDEX IF NOT EXISTS product_options_tenant_idx (tenant_id),
    ADD INDEX IF NOT EXISTS product_options_product_tenant_idx (product_id, tenant_id);

ALTER TABLE product_option_choices
    ADD INDEX IF NOT EXISTS product_option_choices_tenant_idx (tenant_id),
    ADD INDEX IF NOT EXISTS product_option_choices_option_tenant_idx (option_id, tenant_id);

ALTER TABLE product_images
    ADD INDEX IF NOT EXISTS product_images_tenant_idx (tenant_id),
    ADD INDEX IF NOT EXISTS product_images_product_tenant_idx (product_id, tenant_id);

-- ========================================
-- 6. Now handle STORES table (similar pattern)
-- ========================================

-- Check if any tables reference stores.id
-- (Add similar DROP FOREIGN KEY statements for any tables referencing stores)

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
-- 7. Handle INVENTORY table
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
-- 8. Migration Record
-- ========================================

INSERT INTO schema_migrations (migration_id, applied_at, applied_by, description)
SELECT '0006_inventory_tenant_isolation_constraints',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add tenant isolation constraints and indexes to products, stores, inventory, and related tables'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE migration_id = '0006_inventory_tenant_isolation_constraints'
);

COMMIT;