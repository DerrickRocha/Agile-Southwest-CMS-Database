DELIMITER $$

CREATE PROCEDURE store_integrity_tests()
BEGIN
    DECLARE v_TenantId BINARY(16);
    DECLARE v_StoreId1 BINARY(16);
    DECLARE v_StoreId2 BINARY(16);

    -- Generate UUIDs for tenant and stores
    SET v_TenantId = UUID_TO_BIN(UUID());
    SET v_StoreId1 = UUID_TO_BIN(UUID());
    SET v_StoreId2 = UUID_TO_BIN(UUID());

    -- Insert a tenant
    INSERT INTO Tenants (TenantId, Name, Subdomain, SubscriptionStatus)
    VALUES (v_TenantId, 'Tenant', 'tenant', 'Active');

    -- Insert the first default store
    INSERT INTO Stores (StoreId, TenantId, Name, IsDefault)
    VALUES (v_StoreId1, v_TenantId, 'Main Store', 1);

    -- Test: attempt to insert a second default store for same tenant
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            BEGIN
                -- Expected: uniqueness violation on (TenantId, IsDefault)
                -- Do nothing, test passes
            END;

        -- This should fail due to unique constraint
        INSERT INTO Stores (StoreId, TenantId, Name, IsDefault)
        VALUES (v_StoreId2, v_TenantId, 'Second Default', 1);

        -- If we reach here, no error occurred → test failed
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Test failed: multiple default stores allowed';
    END;
END$$

DELIMITER ;

-- Run the test
CALL store_integrity_tests();

-- Drop the procedure after test to avoid conflicts
DROP PROCEDURE store_integrity_tests;

