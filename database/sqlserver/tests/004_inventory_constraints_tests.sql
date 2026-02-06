BEGIN TRANSACTION;

DECLARE @TenantId UNIQUEIDENTIFIER = NEWID();
DECLARE @StoreId UNIQUEIDENTIFIER = NEWID();
DECLARE @ProductId UNIQUEIDENTIFIER = NEWID();

INSERT INTO app.Tenants (TenantId, Name, Subdomain, SubscriptionStatus)
VALUES (@TenantId, 'Tenant', 'tenant', 'Active');

INSERT INTO app.Stores (StoreId, TenantId, Name, IsDefault)
VALUES (@StoreId, @TenantId, 'Store', 1);

INSERT INTO app.Products (
    ProductId, TenantId, StoreId, Name, Price
)
VALUES (
           @ProductId, @TenantId, @StoreId, 'Product', 5.00
       );

INSERT INTO app.Inventory (
    TenantId, StoreId, ProductId, QuantityOnHand, QuantityReserved
)
VALUES (
           @TenantId, @StoreId, @ProductId, 10, 0
       );

ROLLBACK TRANSACTION;
