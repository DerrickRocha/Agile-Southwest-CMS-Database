IF EXISTS (SELECT 1 FROM app.SchemaMigrations WHERE MigrationId = '0005_subscriptions')
    THROW 50000, 'Migration already applied', 1;

BEGIN TRAN;

CREATE TABLE app.Subscriptions (
    SubscriptionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    StripeSubscriptionId NVARCHAR(100),
    PlanName NVARCHAR(100),
    Status NVARCHAR(50),
    CurrentPeriodEnd DATETIME2,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY (TenantId) REFERENCES app.Tenants(TenantId)
);

CREATE TABLE app.Invoices (
    InvoiceId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SubscriptionId UNIQUEIDENTIFIER NOT NULL,
    StripeInvoiceId NVARCHAR(100),
    AmountDue DECIMAL(10,2),
    Status NVARCHAR(50),
    InvoiceDate DATETIME2,
    FOREIGN KEY (SubscriptionId) REFERENCES app.Subscriptions(SubscriptionId)
);

INSERT INTO app.SchemaMigrations VALUES
('0005_subscriptions', SYSDATETIME(), SUSER_SNAME(), 'Billing & invoices');

COMMIT;