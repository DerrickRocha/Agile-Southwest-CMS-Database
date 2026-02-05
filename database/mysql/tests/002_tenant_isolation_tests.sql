START TRANSACTION;

-- Generate IDs
SET @TenantA = UUID_TO_BIN(UUID(), 1);
SET @TenantB = UUID_TO_BIN(UUID(), 1);
SET @StoreA  = UUID_TO_BIN(UUID(), 1);

-- Create tenants
INSERT INTO Tenants (TenantId, Name, Subdomain, SubscriptionStatus)
VALUES
    (@TenantA, 'Tenant A', 'tenant-a-test', 'Active'),
    (@TenantB, 'Tenant B', 'tenant-b-test', 'Active');

-- Create store for Tenant A
INSERT INTO Stores (StoreId, TenantId, Name, IsDefault)
VALUES (@StoreA, @TenantA, 'Store A', 1);

-- This insert MUST fail if tenant isolation is enforced
INSERT INTO Products (
    ProductId,
    TenantId,
    StoreId,
    Name,
    Price
)
VALUES (
           UUID_TO_BIN(UUID(), 1),
           @TenantB,  -- ❌ Wrong tenant
           @StoreA,   -- ❌ Store belongs to TenantA
           'Invalid Product',
           10.00
       );

-- If we get here, isolation is broken → force failure
SELECT
    1 / 0 AS tenant_isolation_violation_allowed;

ROLLBACK;
