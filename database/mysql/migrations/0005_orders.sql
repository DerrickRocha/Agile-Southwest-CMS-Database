-- ----------------------------------------
-- 0005_orders.sql
-- Orders and Purchases
-- ----------------------------------------
START TRANSACTION;

CREATE TABLE IF NOT EXISTS orders
(
    id                        INT PRIMARY KEY AUTO_INCREMENT,
    order_number              VARCHAR(255)                                    NOT NULL,
    tenant_id                 INT                                             NOT NULL,
    shipping_zone_id          INT                                             NOT NULL,
    customer_id               INT                                             NULL,
    customer_email            VARCHAR(255)                                    NOT NULL,
    -- Status tracking
    status                    ENUM (
        'pending',
        'confirmed',
        'completed',
        'cancelled'
        )                                                                     NOT NULL DEFAULT 'pending',

    payment_status            ENUM (
        'unpaid',
        'paid',
        'processing',
        'partially_paid',
        'failed',
        'payment_expired',
        'refunded',
        'partial_refunded'
        )                                                                     NOT NULL DEFAULT 'unpaid',
    fulfillment_status        ENUM ('fulfilled', 'unfulfilled', 'partial'),

    -- Amounts (in cents)
    subtotal_cents            INT                                             NOT NULL,
    discount_cents            INT                                             NOT NULL DEFAULT 0,
    coupon_code               VARCHAR(100)                                    NULL,
    coupon_discount_cents     INT                                             NOT NULL DEFAULT 0,
    tax_cents                 INT                                             NOT NULL DEFAULT 0,
    shipping_cents            INT                                             NOT NULL DEFAULT 0,
    total_cents               INT                                             NOT NULL,
    refunded_amount_cents     INT                                             NOT NULL DEFAULT 0,
    payment_service_fee_cents INT                                             NOT NULL DEFAULT 0,

    -- Shipping address
    shipping_address_line1    VARCHAR(255)                                    NOT NULL,
    shipping_address_line2    VARCHAR(255)                                    NULL,
    shipping_city             VARCHAR(100)                                    NOT NULL,
    shipping_state            VARCHAR(100)                                    NULL,
    shipping_postal_code      VARCHAR(20)                                     NOT NULL,
    shipping_country          VARCHAR(100)                                    NOT NULL,

    -- Billing address (can be same as shipping)
    billing_address_line1     VARCHAR(255)                                    NOT NULL,
    billing_address_line2     VARCHAR(255)                                    NULL,
    billing_city              VARCHAR(100)                                    NOT NULL,
    billing_state             VARCHAR(100)                                    NULL,
    billing_postal_code       VARCHAR(20)                                     NOT NULL,
    billing_country           VARCHAR(100)                                    NOT NULL,
    order_type                ENUM ('standard', 'subscription')               NOT NULL DEFAULT 'standard',

    -- Audit
    ip_address                VARCHAR(45)                                     NULL,
    user_agent                TEXT                                            NULL,

    -- Notes
    customer_notes            TEXT                                            NULL,
    admin_notes               TEXT                                            NULL,

    -- Timestamps
    created_at                DATETIME(6)                                     NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at                DATETIME(6)                                     NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at                DATETIME(6)                                     NULL,
    -- Concurrency
    row_version               TIMESTAMP                                       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT orders_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT orders_customer_fk FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL,
    CONSTRAINT chk_orders_amounts CHECK (
        subtotal_cents >= 0
            AND discount_cents >= 0
            AND tax_cents >= 0
            AND shipping_cents >= 0
            AND total_cents >= 0
        ),
    CONSTRAINT chk_orders_refund CHECK (
        refunded_amount_cents <= total_cents
        ),
    CONSTRAINT orders_shipping_zone_fk
        FOREIGN KEY (shipping_zone_id) REFERENCES shipping_zones (id) ON DELETE SET NULL,

    UNIQUE KEY uk_tenant_order (tenant_id, id),
    -- Indexes
    INDEX idx_tenant (tenant_id),
    INDEX idx_order_number (order_number),
    INDEX idx_customer_id (customer_id),
    INDEX idx_customer_email (customer_email),
    INDEX idx_status (status),
    INDEX idx_payment_status (payment_status),
    INDEX idx_created_at (created_at),
    INDEX idx_tenant_status (tenant_id, status),
    INDEX idx_tenant_created (tenant_id, created_at),
    INDEX idx_tenant_customer (tenant_id, customer_id),
    INDEX idx_deleted (deleted_at),
    INDEX idx_orders_stale_pending (created_at),
    INDEX idx_customer_orders (customer_id, created_at, status)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS order_items
(
    id                INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id         INT          NOT NULL,
    order_id          INT          NOT NULL,
    product_id        INT          NOT NULL,
    tax_category_id   INT          NULL,
    product_name      VARCHAR(255) NOT NULL,
    product_sku       VARCHAR(100) NULL,
    quantity          INT          NOT NULL,
    unit_price_cents  INT          NOT NULL, -- Price at time of order
    total_price_cents INT          NOT NULL, -- quantity * unit_price
    discount_cents    INT          NOT NULL DEFAULT 0,
    weight_grams      INT          NULL,
    -- Product options snapshot
    option_details    JSON         NULL,     -- Store selected options as JSON

    -- Image snapshot
    image_url         VARCHAR(500) NULL,     -- Snapshot of primary image URL

    -- Timestamps
    created_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at        DATETIME(6)  NULL,
    -- Concurrency
    row_version       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT order_items_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT order_items_order_fk FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT order_items_product_fk FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT,
    CONSTRAINT order_items_tax_category_fk FOREIGN KEY (tax_category_id) REFERENCES tax_categories (id),
    -- Indexes
    INDEX idx_tenant (tenant_id),
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id),
    INDEX idx_deleted (deleted_at)

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS payment_transactions
(
    id                INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id         INT          NOT NULL,
    order_id          INT          NOT NULL,
    amount_cents       INT          NOT NULL,
    transaction_type   ENUM('authorize', 'capture', 'sale', 'refund', 'void') NOT NULL DEFAULT 'authorize',
    gateway_name             ENUM('stripe', 'aeropay')  NOT NULL DEFAULT 'stripe',
    gateway_transaction_id   VARCHAR(255) NULL COMMENT 'Actual id from gateway',
    gateway_fee_cents        INT          NULL COMMENT 'Gateway fee for this transaction',
    status             ENUM('success', 'failed', 'pending')  NOT NULL DEFAULT 'pending',
    error_code         VARCHAR(100) NULL,
    raw_gateway_response JSON         NULL COMMENT 'Stores the full webhook JSON for developer debugging',
    error_message      TEXT         NULL,
    created_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at        DATETIME(6)  NULL,
    row_version       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT payment_transactions_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    CONSTRAINT payment_transactions_order_fk FOREIGN KEY (order_id) REFERENCES orders(id),
    INDEX idx_tenant (tenant_id),
    INDEX idx_order_id (order_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;


INSERT INTO schema_migrations (migration_id,
                               applied_by,
                               description)
SELECT '0005_orders',
       CURRENT_USER(),
       'Add Orders and Purchases'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0005_orders');
COMMIT;