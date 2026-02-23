-- ----------------------------------------
-- 0003_orders.sql
-- Orders and payments
-- ----------------------------------------

START TRANSACTION;

-- ----------------------------------------
-- 1️⃣ Orders
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS Orders (
                                      OrderId     BINARY(16) PRIMARY KEY,
    TenantId    BINARY(16) NOT NULL,
    CustomerId  BINARY(16) NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    Status      VARCHAR(50) NOT NULL,
    CreatedAt   DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UpdatedAt   DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_orders_tenant
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    ON DELETE CASCADE,
    CONSTRAINT fk_orders_customer
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
    ON DELETE RESTRICT
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------
-- 2️⃣ Order Items
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS OrderItems (
                                          OrderItemId BINARY(16) PRIMARY KEY,
    OrderId     BINARY(16) NOT NULL,
    ProductId   BINARY(16) NOT NULL,
    Quantity    INT NOT NULL,
    UnitPrice   DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_orderitems_order
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
    ON DELETE CASCADE,
    CONSTRAINT fk_orderitems_product
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
    ON DELETE RESTRICT
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------
-- 3️⃣ Payments
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS Payments (
                                        PaymentId BINARY(16) PRIMARY KEY,
    OrderId   BINARY(16) NOT NULL,
    TenantId  BINARY(16) NOT NULL,
    StripePaymentIntentId VARCHAR(100),
    Amount    DECIMAL(10,2),
    Status    VARCHAR(50),
    CreatedAt DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UpdatedAt DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_payments_order
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
    ON DELETE CASCADE,
    CONSTRAINT fk_payments_tenant
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------
-- 4️⃣ Record migration (idempotent)
-- ----------------------------------------
INSERT INTO SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
SELECT
    '0003_orders',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Orders and payments'
    WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0003_orders'
);

COMMIT;
