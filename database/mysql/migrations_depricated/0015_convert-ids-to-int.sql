/* ============================================================
   0015_convert-ids-to-int
   MySQL: Convert BINARY(16) PK/FK columns to INT UNSIGNED AUTO_INCREMENT.
   Assumption: tables are empty (enforced by checks).
   ============================================================ */

START TRANSACTION;

SET @migration_id := '0015_convert-ids-to-int';

-- ------------------------------------------------------------
-- 0) Hard guard: prevent re-applying (your runner already skips applied)
-- ------------------------------------------------------------
SET @already := (
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM SchemaMigrations WHERE MigrationId = @migration_id
    ) THEN 1 ELSE 0 END
);

SET @sql := (
    SELECT IF(
        @already = 1,
        'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT = ''Migration already applied'';',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 1) Safety: abort if ANY rows exist (edit list if you add more tables)
-- ------------------------------------------------------------
SET @has_data :=
(
    SELECT CASE WHEN
        (SELECT COUNT(*) FROM Tenants) > 0 OR
        (SELECT COUNT(*) FROM Stores) > 0 OR
        (SELECT COUNT(*) FROM CmsUsers) > 0 OR
        (SELECT COUNT(*) FROM Customers) > 0 OR
        (SELECT COUNT(*) FROM Products) > 0 OR
        (SELECT COUNT(*) FROM ProductOptions) > 0 OR
        (SELECT COUNT(*) FROM Orders) > 0 OR
        (SELECT COUNT(*) FROM OrderItems) > 0 OR
        (SELECT COUNT(*) FROM Payments) > 0 OR
        (SELECT COUNT(*) FROM Inventory) > 0 OR
        (SELECT COUNT(*) FROM Subscriptions) > 0 OR
        (SELECT COUNT(*) FROM Invoices) > 0 OR
        (SELECT COUNT(*) FROM Pages) > 0 OR
        (SELECT COUNT(*) FROM AuditLogs) > 0 OR
        (SELECT COUNT(*) FROM UserTenants) > 0
    THEN 1 ELSE 0 END
);

SET @sql := (
    SELECT IF(
        @has_data = 1,
        'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT = ''Migration requires empty tables'';',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 2) Drop all FKs dynamically (one statement at a time)
--    (Avoids GROUP_CONCAT multi-statement PREPARE issues)
-- ------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;

DROP PROCEDURE IF EXISTS DropAllForeignKeys;
DELIMITER $$

CREATE PROCEDURE DropAllForeignKeys(IN in_table_name VARCHAR(64))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE fk_name VARCHAR(64);

    DECLARE cur CURSOR FOR
SELECT CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = in_table_name
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

OPEN cur;

read_loop: LOOP
        FETCH cur INTO fk_name;
        IF done = 1 THEN
            LEAVE read_loop;
END IF;

        SET @stmt = CONCAT('ALTER TABLE `', in_table_name, '` DROP FOREIGN KEY `', fk_name, '`');
PREPARE s FROM @stmt;
EXECUTE s;
DEALLOCATE PREPARE s;
END LOOP;

CLOSE cur;
END$$

DELIMITER ;

CALL DropAllForeignKeys('UserTenants');
CALL DropAllForeignKeys('Invoices');
CALL DropAllForeignKeys('Subscriptions');
CALL DropAllForeignKeys('Payments');
CALL DropAllForeignKeys('OrderItems');
CALL DropAllForeignKeys('Orders');
CALL DropAllForeignKeys('Inventory');
CALL DropAllForeignKeys('ProductOptions');
CALL DropAllForeignKeys('Products');
CALL DropAllForeignKeys('Customers');
CALL DropAllForeignKeys('CmsUsers');
CALL DropAllForeignKeys('Stores');
CALL DropAllForeignKeys('Pages');
CALL DropAllForeignKeys('AuditLogs');
CALL DropAllForeignKeys('Tenants');

DROP PROCEDURE IF EXISTS DropAllForeignKeys;

-- ------------------------------------------------------------
-- 3) Convert PKs to INT UNSIGNED AUTO_INCREMENT
--    Must be a KEY at the moment AUTO_INCREMENT is defined.
-- ------------------------------------------------------------
ALTER TABLE Tenants
DROP PRIMARY KEY,
    MODIFY TenantId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (TenantId);

ALTER TABLE Stores
DROP PRIMARY KEY,
    MODIFY StoreId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (StoreId);

ALTER TABLE CmsUsers
DROP PRIMARY KEY,
    MODIFY CmsUserId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (CmsUserId);

ALTER TABLE Customers
DROP PRIMARY KEY,
    MODIFY CustomerId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (CustomerId);

ALTER TABLE Products
DROP PRIMARY KEY,
    MODIFY ProductId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (ProductId);

ALTER TABLE ProductOptions
DROP PRIMARY KEY,
    MODIFY ProductOptionId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (ProductOptionId);

ALTER TABLE Orders
DROP PRIMARY KEY,
    MODIFY OrderId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (OrderId);

ALTER TABLE OrderItems
DROP PRIMARY KEY,
    MODIFY OrderItemId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (OrderItemId);

ALTER TABLE Payments
DROP PRIMARY KEY,
    MODIFY PaymentId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (PaymentId);

ALTER TABLE Inventory
DROP PRIMARY KEY,
    MODIFY InventoryId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (InventoryId);

ALTER TABLE Subscriptions
DROP PRIMARY KEY,
    MODIFY SubscriptionId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (SubscriptionId);

ALTER TABLE Invoices
DROP PRIMARY KEY,
    MODIFY InvoiceId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (InvoiceId);

ALTER TABLE Pages
DROP PRIMARY KEY,
    MODIFY PageId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD PRIMARY KEY (PageId);

-- UserTenants has a composite PK; do NOT make any column AUTO_INCREMENT here.
ALTER TABLE UserTenants
DROP PRIMARY KEY,
    ADD PRIMARY KEY (UserId, TenantId);

-- ------------------------------------------------------------
-- 4) Convert all FK columns to INT UNSIGNED BEFORE recreating FKs
-- ------------------------------------------------------------
ALTER TABLE Stores         MODIFY TenantId INT UNSIGNED NOT NULL;

ALTER TABLE Customers      MODIFY TenantId INT UNSIGNED NOT NULL;

ALTER TABLE Products       MODIFY TenantId INT UNSIGNED NOT NULL;
ALTER TABLE Products       MODIFY StoreId  INT UNSIGNED NOT NULL;

ALTER TABLE ProductOptions MODIFY ProductId INT UNSIGNED NOT NULL;

ALTER TABLE Orders         MODIFY TenantId   INT UNSIGNED NOT NULL;
ALTER TABLE Orders         MODIFY CustomerId INT UNSIGNED NOT NULL;
ALTER TABLE Orders         MODIFY StoreId    INT UNSIGNED NOT NULL;

ALTER TABLE OrderItems     MODIFY OrderId   INT UNSIGNED NOT NULL;
ALTER TABLE OrderItems     MODIFY ProductId INT UNSIGNED NOT NULL;

ALTER TABLE Payments       MODIFY OrderId  INT UNSIGNED NOT NULL;
ALTER TABLE Payments       MODIFY TenantId INT UNSIGNED NOT NULL;

ALTER TABLE Inventory      MODIFY TenantId  INT UNSIGNED NOT NULL;
ALTER TABLE Inventory      MODIFY ProductId INT UNSIGNED NOT NULL;
ALTER TABLE Inventory      MODIFY StoreId   INT UNSIGNED NOT NULL;

ALTER TABLE Subscriptions  MODIFY TenantId INT UNSIGNED NOT NULL;
ALTER TABLE Invoices       MODIFY SubscriptionId INT UNSIGNED NOT NULL;

ALTER TABLE Pages          MODIFY TenantId INT UNSIGNED NOT NULL;

ALTER TABLE AuditLogs      MODIFY TenantId INT UNSIGNED NOT NULL;

ALTER TABLE UserTenants    MODIFY UserId   INT UNSIGNED NOT NULL;
ALTER TABLE UserTenants    MODIFY TenantId INT UNSIGNED NOT NULL;

-- ------------------------------------------------------------
-- 5) Recreate foreign keys (now types are compatible)
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 6) Record migration
-- ------------------------------------------------------------
INSERT INTO SchemaMigrations (MigrationId, AppliedAt, AppliedBy, Description)
VALUES (
           @migration_id,
           CURRENT_TIMESTAMP(6),
           CURRENT_USER(),
           'Convert BINARY(16) id columns to INT UNSIGNED AUTO_INCREMENT (empty tables)'
       );

COMMIT;