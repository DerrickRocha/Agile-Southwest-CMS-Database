DELIMITER $$

CREATE PROCEDURE inventory_constraints_tests()
BEGIN
    DECLARE v_TenantId BINARY(16) DEFAULT UNHEX(REPLACE(UUID(), '-', ''));
    DECLARE v_StoreId BINARY(16) DEFAULT UNHEX(REPLACE(UUID(), '-', ''));
    DECLARE v_ProductId BINARY(16) DEFAULT UNHEX(REPLACE(UUID(), '-', ''));
    DECLARE v_Subdomain VARCHAR(255) DEFAULT CONCAT('tenant-', UUID_SHORT());

    -- ------------------------------------------------------------
    -- Insert Tenant (unique subdomain per run)
    -- ------------------------------------------------------------
    INSERT INTO Tenants (TenantId, Name, Subdomain, SubscriptionStatus)
    VALUES (v_TenantId, 'Tenant', v_Subdomain, 'Active');

    -- ------------------------------------------------------------
    -- Insert Store for Tenant
    -- ------------------------------------------------------------
    INSERT INTO Stores (StoreId, TenantId, Name, IsDefault)
    VALUES (v_StoreId, v_TenantId, 'Store', 1);

    -- ------------------------------------------------------------
    -- Insert Product for Store
    -- ------------------------------------------------------------
    INSERT INTO Products (ProductId, TenantId, StoreId, Name, Price)
    VALUES (v_ProductId, v_TenantId, v_StoreId, 'Product', 5.00);

    -- ------------------------------------------------------------
    -- Insert Inventory for Product
    -- ------------------------------------------------------------
    INSERT INTO Inventory (TenantId, StoreId, ProductId, QuantityOnHand, QuantityReserved)
    VALUES (v_TenantId, v_StoreId, v_ProductId, 10, 0);

    -- ------------------------------------------------------------
    -- Rollback changes after test
    -- ------------------------------------------------------------
    ROLLBACK;
END$$

DELIMITER ;


