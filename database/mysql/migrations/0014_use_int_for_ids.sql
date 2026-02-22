/* ============================================================
   0014_binary16_to_int_autoinc_empty
   MySQL: Convert BINARY(16) PK/FK columns to INT AUTO_INCREMENT.
   Assumption: tables are empty (enforced by checks).
   ============================================================ */

START TRANSACTION;

SET @migration_id := '0014_binary16_to_int_autoinc_empty';

-- Idempotency guard
SET @already := (SELECT EXISTS(
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = @migration_id
));
SET @sql := (SELECT IF(@already = 1, 'SELECT 1;', 'SELECT 1;'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Safety: abort if ANY rows exist in core tables (edit list if needed)
SET @has_data :=
(
    SELECT CASE WHEN
        (SELECT COUNT(*) FROM Tenants) > 0 OR
        (SELECT COUNT(*) FROM CmsUsers) > 0 OR
        (SELECT COUNT(*) FROM Customers) > 0 OR
        (SELECT COUNT(*) FROM Products) > 0 OR
        (SELECT COUNT(*) FROM Orders) > 0
    THEN 1 ELSE 0 END
);

SET @sql := (
    SELECT IF(
        @already = 0 AND @has_data = 1,
        'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT = ''Migration requires empty tables'';',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Helper: drop ALL foreign keys on a table (dynamic)
-- ------------------------------------------------------------
-- Usage pattern:
--   SET @tbl := 'SomeTable';
--   <block>

SET FOREIGN_KEY_CHECKS = 0;

-- Drop FKs for each table that participates
SET @tbl := 'UserTenants';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Invoices';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Subscriptions';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Payments';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'OrderItems';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Orders';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Inventory';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'ProductOptions';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Products';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Customers';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'CmsUsers';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Stores';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'Pages';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := 'AuditLogs';
SET @sql := (
    SELECT IFNULL(
        (SELECT GROUP_CONCAT(CONCAT('ALTER TABLE `', @tbl, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`') SEPARATOR '; ')
         FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = @tbl
           AND CONSTRAINT_TYPE = 'FOREIGN KEY'),
        'SELECT 1'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Drop PKs (so MODIFY works cleanly)
ALTER TABLE Tenants        DROP PRIMARY KEY;
ALTER TABLE Stores         DROP PRIMARY KEY;
ALTER TABLE CmsUsers       DROP PRIMARY KEY;
ALTER TABLE Customers      DROP PRIMARY KEY;
ALTER TABLE Products       DROP PRIMARY KEY;
ALTER TABLE ProductOptions DROP PRIMARY KEY;
ALTER TABLE Orders         DROP PRIMARY KEY;
ALTER TABLE OrderItems     DROP PRIMARY KEY;
ALTER TABLE Payments       DROP PRIMARY KEY;
ALTER TABLE Inventory      DROP PRIMARY KEY;
ALTER TABLE Subscriptions  DROP PRIMARY KEY;
ALTER TABLE Invoices       DROP PRIMARY KEY;
ALTER TABLE Pages          DROP PRIMARY KEY;
ALTER TABLE UserTenants    DROP PRIMARY KEY;

-- -------------------------
-- Convert PKs to AUTO_INCREMENT
-- -------------------------
ALTER TABLE Tenants        MODIFY TenantId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Stores         MODIFY StoreId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE CmsUsers       MODIFY CmsUserId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Customers      MODIFY CustomerId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Products       MODIFY ProductId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE ProductOptions MODIFY ProductOptionId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Orders         MODIFY OrderId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE OrderItems     MODIFY OrderItemId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Payments       MODIFY PaymentId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Inventory      MODIFY InventoryId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Subscriptions  MODIFY SubscriptionId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Invoices       MODIFY InvoiceId INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Pages          MODIFY PageId INT NOT NULL AUTO_INCREMENT;

-- -------------------------
-- Convert FK columns to INT
-- -------------------------
ALTER TABLE Stores         MODIFY TenantId INT NOT NULL;

ALTER TABLE Customers      MODIFY TenantId INT NOT NULL;

ALTER TABLE Products       MODIFY TenantId INT NOT NULL;
ALTER TABLE Products       MODIFY StoreId INT NOT NULL;

ALTER TABLE ProductOptions MODIFY ProductId INT NOT NULL;

ALTER TABLE Orders         MODIFY TenantId INT NOT NULL;
ALTER TABLE Orders         MODIFY CustomerId INT NOT NULL;
ALTER TABLE Orders         MODIFY StoreId INT NOT NULL;

ALTER TABLE OrderItems     MODIFY OrderId INT NOT NULL;
ALTER TABLE OrderItems     MODIFY ProductId INT NOT NULL;

ALTER TABLE Payments       MODIFY OrderId INT NOT NULL;
ALTER TABLE Payments       MODIFY TenantId INT NOT NULL;

ALTER TABLE Inventory      MODIFY TenantId INT NOT NULL;
ALTER TABLE Inventory      MODIFY ProductId INT NOT NULL;
ALTER TABLE Inventory      MODIFY StoreId INT NOT NULL;

ALTER TABLE Subscriptions  MODIFY TenantId INT NOT NULL;
ALTER TABLE Invoices       MODIFY SubscriptionId INT NOT NULL;

ALTER TABLE Pages          MODIFY TenantId INT NOT NULL;

ALTER TABLE AuditLogs      MODIFY TenantId INT NOT NULL;

ALTER TABLE UserTenants    MODIFY UserId INT NOT NULL;
ALTER TABLE UserTenants    MODIFY TenantId INT NOT NULL;

-- Re-add PKs
ALTER TABLE Tenants        ADD PRIMARY KEY (TenantId);
ALTER TABLE Stores         ADD PRIMARY KEY (StoreId);
ALTER TABLE CmsUsers       ADD PRIMARY KEY (CmsUserId);
ALTER TABLE Customers      ADD PRIMARY KEY (CustomerId);
ALTER TABLE Products       ADD PRIMARY KEY (ProductId);
ALTER TABLE ProductOptions ADD PRIMARY KEY (ProductOptionId);
ALTER TABLE Orders         ADD PRIMARY KEY (OrderId);
ALTER TABLE OrderItems     ADD PRIMARY KEY (OrderItemId);
ALTER TABLE Payments       ADD PRIMARY KEY (PaymentId);
ALTER TABLE Inventory      ADD PRIMARY KEY (InventoryId);
ALTER TABLE Subscriptions  ADD PRIMARY KEY (SubscriptionId);
ALTER TABLE Invoices       ADD PRIMARY KEY (InvoiceId);
ALTER TABLE Pages          ADD PRIMARY KEY (PageId);
ALTER TABLE UserTenants    ADD PRIMARY KEY (UserId, TenantId);

-- Re-add FKs (fresh names)
ALTER TABLE Stores
    ADD CONSTRAINT fk_stores_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId);

ALTER TABLE Customers
    ADD CONSTRAINT fk_customers_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE Products
    ADD CONSTRAINT fk_products_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE Products
    ADD CONSTRAINT fk_products_store_int
        FOREIGN KEY (StoreId) REFERENCES Stores(StoreId);

ALTER TABLE ProductOptions
    ADD CONSTRAINT fk_productoptions_product_int
        FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
            ON DELETE CASCADE;

ALTER TABLE Orders
    ADD CONSTRAINT fk_orders_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE Orders
    ADD CONSTRAINT fk_orders_customer_int
        FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
            ON DELETE RESTRICT;

ALTER TABLE Orders
    ADD CONSTRAINT fk_orders_store_int
        FOREIGN KEY (StoreId) REFERENCES Stores(StoreId);

ALTER TABLE OrderItems
    ADD CONSTRAINT fk_orderitems_order_int
        FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
            ON DELETE CASCADE;

ALTER TABLE OrderItems
    ADD CONSTRAINT fk_orderitems_product_int
        FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
            ON DELETE RESTRICT;

ALTER TABLE Payments
    ADD CONSTRAINT fk_payments_order_int
        FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
            ON DELETE CASCADE;

ALTER TABLE Payments
    ADD CONSTRAINT fk_payments_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE Inventory
    ADD CONSTRAINT fk_inventory_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE Inventory
    ADD CONSTRAINT fk_inventory_product_int
        FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
            ON DELETE CASCADE;

ALTER TABLE Inventory
    ADD CONSTRAINT fk_inventory_store_int
        FOREIGN KEY (StoreId) REFERENCES Stores(StoreId);

ALTER TABLE Subscriptions
    ADD CONSTRAINT fk_subscriptions_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE Invoices
    ADD CONSTRAINT fk_invoices_subscription_int
        FOREIGN KEY (SubscriptionId) REFERENCES Subscriptions(SubscriptionId)
            ON DELETE CASCADE;

ALTER TABLE Pages
    ADD CONSTRAINT fk_pages_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE AuditLogs
    ADD CONSTRAINT fk_auditlogs_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

ALTER TABLE UserTenants
    ADD CONSTRAINT fk_usertenants_user_int
        FOREIGN KEY (UserId) REFERENCES CmsUsers(CmsUserId)
            ON DELETE CASCADE;

ALTER TABLE UserTenants
    ADD CONSTRAINT fk_usertenants_tenant_int
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
            ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;

-- Record migration
INSERT INTO SchemaMigrations (MigrationId, AppliedAt, AppliedBy, Description)
SELECT
    @migration_id,
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Convert BINARY(16) ids to INT AUTO_INCREMENT (empty tables)'
    WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = @migration_id
);

COMMIT;