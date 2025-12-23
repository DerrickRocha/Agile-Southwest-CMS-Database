BEGIN TRANSACTION;

DECLARE @TenantId UNIQUEIDENTIFIER = NEWID();

INSERT INTO app.Tenants (TenantId, Name, Subdomain, SubscriptionStatus)
VALUES (@TenantId, 'Tenant', 'tenant', 'Active');

INSERT INTO app.Stores (TenantId, Name, IsDefault)
VALUES (@TenantId, 'Main Store', 1);

BEGIN TRY
INSERT INTO app.Stores (TenantId, Name, IsDefault)
    VALUES (@TenantId, 'Second Default', 1);

    THROW 53001, 'Multiple default stores allowed', 1;
END TRY
BEGIN CATCH
    -- Expected if unique index exists
END CATCH;

ROLLBACK TRANSACTION;
