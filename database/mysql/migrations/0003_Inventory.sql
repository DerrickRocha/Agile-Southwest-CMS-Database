START TRANSACTION;

CREATE TABLE IF NOT EXISTS stores (
    id INT NOT NULL AUTO_INCREMENT,
    tenant_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    sub_domain VARCHAR(255) NOT NULL,
    is_online BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    PRIMARY KEY (id, tenant_id),
    UNIQUE KEY stores_tenant_subdomain_uk (tenant_id, sub_domain, deleted_at),
    CONSTRAINT stores_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    INDEX stores_tenant_id_idx (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS inventory (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    CONSTRAINT inventory_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    CONSTRAINT inventory_store_tenant_id_fk FOREIGN KEY (store_id, tenant_id) REFERENCES stores(id, tenant_id) ON DELETE RESTRICT,
    CONSTRAINT inventory_product_tenant_id_fk FOREIGN KEY (product_id, tenant_id) REFERENCES products(id, tenant_id) ON DELETE RESTRICT,
    CONSTRAINT inventory_quantity_check CHECK (quantity >= 0),
    
    UNIQUE KEY inventory_tenant_store_product_uk (tenant_id, store_id, product_id, deleted_at),

    INDEX inventory_tenant_id_idx (tenant_id),
    INDEX inventory_tenant_store_idx (tenant_id, store_id),
    INDEX inventory_tenant_product_idx (tenant_id, product_id),
    INDEX inventory_tenant_quantity_idx (tenant_id, quantity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0003_Inventory',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add Stores, Inventory and InventoryItem tables'
    WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0003_Inventory');

COMMIT;