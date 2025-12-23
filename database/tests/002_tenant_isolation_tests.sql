BEGIN TRANSACTION;

DECLARE @TenantA UNIQUEIDENTIFIER = NEWID();
DECLARE @TenantB UNIQUEIDENTIFIER = NEWID();

INSERT INTO app.Tenants (TenantId, Name, Subdomain, SubscriptionStatus)
VALUES
    (@TenantA, 'Tenant A', 'tenant-a', 'Active'),
    (@TenantB, 'Tenant B', 'tenant-b', 'Active');

DECLARE @StoreA UNIQUEIDENTIFIER = NEWID();

INSERT INTO app.Stores (StoreId, TenantId, Name, IsDefault)
VALUES (@StoreA, @TenantA, 'Store A', 1);

BEGIN TRY
INSERT INTO app.Products (
        TenantId, StoreId, Name, Price
    )
    VALUES (
        @TenantB, -- WRONG tenant
        @StoreA,  -- Store belongs to TenantA
        'Invalid Product',
        10.00
    );

    THROW 52001, 'Tenant isolation violation allowed', 1;
END TRY
BEGIN CATCH
    -- Expected failure
END CATCH;

ROLLBACK TRANSACTION;
