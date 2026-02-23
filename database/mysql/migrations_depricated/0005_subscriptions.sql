-- ----------------------------------------
-- 0005_subscriptions.sql
-- Billing & invoices
-- ----------------------------------------

START TRANSACTION;

CREATE TABLE IF NOT EXISTS Subscriptions (
                                             SubscriptionId BINARY(16) PRIMARY KEY,
    TenantId       BINARY(16) NOT NULL,
    StripeSubscriptionId VARCHAR(100),
    PlanName       VARCHAR(100),
    Status         VARCHAR(50),
    CurrentPeriodEnd DATETIME(6),
    CreatedAt      DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UpdatedAt      DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_subscriptions_tenant
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS Invoices (
                                        InvoiceId        BINARY(16) PRIMARY KEY,
    SubscriptionId  BINARY(16) NOT NULL,
    StripeInvoiceId VARCHAR(100),
    AmountDue       DECIMAL(10,2),
    Status          VARCHAR(50),
    InvoiceDate     DATETIME(6),
    CONSTRAINT fk_invoices_subscription
    FOREIGN KEY (SubscriptionId)
    REFERENCES Subscriptions(SubscriptionId)
    ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO SchemaMigrations
SELECT '0005_subscriptions', CURRENT_TIMESTAMP(6), CURRENT_USER(), 'Billing & invoices'
    WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0005_subscriptions'
);

COMMIT;
