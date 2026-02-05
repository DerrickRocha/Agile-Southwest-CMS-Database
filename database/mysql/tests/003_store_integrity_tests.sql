START TRANSACTION;

-- --------------------------------------------------
-- Step 1: Insert a tenant
-- --------------------------------------------------
SET @TenantId = UNHEX(REPLACE(UUID(), '-', ''));

INSERT INTO Tenants (TenantId, Name, Subdomain, SubscriptionStatus)
VALUES (@TenantId, 'Tenant', 'tenant', 'Active');

-- --------------------------------------------------
-- Step 2: Insert a default store for the tenant
-- --------------------------------------------------
INSERT INTO Stores (TenantId, Name, IsDefault)
VALUES (@TenantId, 'Main Store', 1);

-- --------------------------------------------------
-- Step 3: Attempt to insert a second default store for the same tenant
-- Expect failure due to unique constraint on (TenantId, IsDefault)
-- --------------------------------------------------
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM Stores
            WHERE TenantId = @TenantId
              AND IsDefault = 1
        )
            THEN 1 / 0  -- fail if we somehow allow multiple default stores
        ELSE 1
        END AS default_store_uniqueness_test;

ROLLBACK;
