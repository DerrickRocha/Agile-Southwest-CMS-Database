START TRANSACTION;


CREATE TABLE IF NOT EXISTS order_status_history (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    order_id INT NOT NULL,
    changed_by_id INT NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    old_status VARCHAR(20) NOT NULL,
    new_payment_status VARCHAR(20) NOT NULL,
    old_payment_status VARCHAR(20) NOT NULL,
    new_fulfillment_status VARCHAR(20) NOT NULL,
    old_fulfillment_status VARCHAR(20) NOT NULL,
    reason VARCHAR(255) NULL,
    created_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at        DATETIME(6)  NULL,
    row_version       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT order_status_history_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    CONSTRAINT order_status_history_order_fk FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT,
    CONSTRAINT orders_status_history_changed_by_id_fk FOREIGN KEY (changed_by_id) REFERENCES cms_users(id) ON DELETE RESTRICT,
    INDEX idx_tenant (tenant_id),
    INDEX idx_order_id (order_id),
    INDEX idx_changed_by_id (changed_by_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT INTO schema_migrations (migration_id,
                               applied_by,
                               description)
SELECT '0006_order_status_history',
       CURRENT_USER(),
       'Add Orders and Purchases'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0006_order_status_history');

COMMIT;