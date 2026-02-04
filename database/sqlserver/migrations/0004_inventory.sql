IF EXISTS (SELECT 1 FROM app.SchemaMigrations WHERE MigrationId = '0004_inventory')
    THROW 50000, 'Migration already applied', 1;

BEGIN TRAN;

CREATE TABLE app.Inventory (
    InventoryId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    QuantityOnHand INT NOT NULL,
    QuantityReserved INT DEFAULT 0,
    UpdatedAt DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY (TenantId) REFERENCES app.Tenants(TenantId),
    FOREIGN KEY (ProductId) REFERENCES app.Products(ProductId)
);

INSERT INTO app.SchemaMigrations VALUES
('0004_inventory', SYSDATETIME(), SUSER_SNAME(), 'Inventory & stock');

COMMIT;
