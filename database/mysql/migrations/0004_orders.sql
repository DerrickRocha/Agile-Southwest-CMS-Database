START TRANSACTION;

CREATE TABLE IF NOT EXISTS orders
(
    id                        INT                                           NOT NULL AUTO_INCREMENT,
    tenant_id                 INT                                           NOT NULL,
    customer_id               INT                                           NULL,
    order_number              VARCHAR(50)                                   NOT NULL,
    customer_email            VARCHAR(255)                                  NOT NULL,
    customer_first_name       VARCHAR(100)                                  NOT NULL,
    customer_last_name        VARCHAR(100)                                  NOT NULL,
    customer_phone            VARCHAR(50)                                   NULL,
    -- Status tracking
    status                    ENUM (
        'pending',                                                                                          -- Order created, payment not initiated
        'awaiting_payment',                                                                                 -- Payment initiated but not confirmed (ACH)
        'payment_processing',-- Gateway processing (between auth and capture)
        'paid',                                                                                             -- Payment confirmed
        'payment_failed',                                                                                   -- Payment failed
        'payment_expired',                                                                                  -- Auth expired (ACH timeout)
        'partially_refunded',-- Partial refund issued
        'refunded',                                                                                         -- Fully refunded
        'cancelled'                                                                                         -- Order cancelled before payment
        )                                                                   NOT NULL DEFAULT 'pending',

    payment_status            ENUM (
        'unpaid',                                                                                           -- No payment attempted
        'authorized',                                                                                       -- Card authorized, not captured
        'processing',                                                                                       -- ACH payment in progress (awaiting settlement)
        'paid',                                                                                             -- Payment completed
        'failed',                                                                                           -- Payment failed
        'refunded',                                                                                         -- Fully refunded
        'partial_refunded'
        )                                                                   NOT NULL DEFAULT 'unpaid',
    fulfillment_status        VARCHAR(50)                                   NOT NULL DEFAULT 'unfulfilled', -- unfulfilled, partial, fulfilled

    -- Amounts (in cents)
    subtotal_cents            INT                                           NOT NULL,
    discount_cents            INT                                           NOT NULL DEFAULT 0,
    coupon_code               VARCHAR(100)                                  NULL,
    coupon_discount_cents     INT                                           NOT NULL DEFAULT 0,
    tax_cents                 INT                                           NOT NULL DEFAULT 0,
    shipping_cents            INT                                           NOT NULL DEFAULT 0,
    total_cents               INT                                           NOT NULL,
    refunded_amount_cents     INT                                           NOT NULL DEFAULT 0,
    payment_service_fee_cents INT                                           NOT NULL DEFAULT 0,
    -- Currency
    currency                  VARCHAR(3)                                    NOT NULL DEFAULT 'USD',

    -- Shipping address
    shipping_address_line1    VARCHAR(255)                                  NOT NULL,
    shipping_address_line2    VARCHAR(255)                                  NULL,
    shipping_city             VARCHAR(100)                                  NOT NULL,
    shipping_state            VARCHAR(100)                                  NULL,
    shipping_postal_code      VARCHAR(20)                                   NOT NULL,
    shipping_country          VARCHAR(100)                                  NOT NULL,

    -- Billing address (can be same as shipping)
    billing_address_line1     VARCHAR(255)                                  NOT NULL,
    billing_address_line2     VARCHAR(255)                                  NULL,
    billing_city              VARCHAR(100)                                  NOT NULL,
    billing_state             VARCHAR(100)                                  NULL,
    billing_postal_code       VARCHAR(20)                                   NOT NULL,
    billing_country           VARCHAR(100)                                  NOT NULL,

    -- Payment info
    payment_processor         VARCHAR(50)                                   NULL COMMENT 'stripe, aeropay, paypal, etc.',
    processor_transaction_id  VARCHAR(255)                                  NULL COMMENT 'Gateways internal transaction reference',
    processor_response_code   VARCHAR(50)                                   NULL COMMENT 'Gateway response code for debugging',
    payment_intent_id         VARCHAR(255)                                  NULL COMMENT 'Gateways unique transaction ID',
    checkout_session_id       VARCHAR(255)                                  NULL,
    payment_authorized_at     DATETIME(6)                                   NULL COMMENT 'When gateway authorized the payment',
    payment_captured_at       DATETIME(6)                                   NULL COMMENT 'When funds were captured/settled',
    paid_at                   DATETIME(6)                                   NULL COMMENT 'When payment was confirmed (authorized for cards, settled for ACH)',
    payment_expires_at        DATETIME(6)                                   NULL COMMENT 'For ACH, when the auth expires',
    payment_method_details    JSON                                          NULL COMMENT 'Processor-specific metadata (card brand, bank name, etc.)',
    payment_settled_at        DATETIME(6)                                   NULL COMMENT 'When ACH funds actually settled',
    payment_risk_score        INT                                           NULL COMMENT 'Gateways fraud score (0-100)',
    payment_metadata          JSON                                          NULL COMMENT 'Additional processor data',
    order_type                ENUM ('standard', 'subscription', 'preorder') NOT NULL DEFAULT 'standard',

    -- Audit
    ip_address                VARCHAR(45)                                   NULL,
    user_agent                TEXT                                          NULL,
    
    -- Shipping info
    shipping_method           VARCHAR(100)                                  NULL,
    tracking_number           VARCHAR(255)                                  NULL,
    tracking_url              VARCHAR(500)                                  NULL,

    -- Notes
    customer_notes            TEXT                                          NULL,
    admin_notes               TEXT                                          NULL,

    -- Timestamps
    created_at                TIMESTAMP                                              DEFAULT CURRENT_TIMESTAMP,
    updated_at                TIMESTAMP                                              DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at                TIMESTAMP                                     NULL,
    deleted_by                INT                                           NULL,
    -- Concurrency
    row_version               TIMESTAMP                                     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id, tenant_id),
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
    INDEX idx_orders_checkout_session (checkout_session_id),
    INDEX idx_orders_payment_intent (payment_intent_id),
    INDEX idx_orders_payment_processor (payment_processor),
    INDEX idx_orders_payment_status (payment_processor, payment_status),
    INDEX idx_orders_paid_at (paid_at),                                                                     -- ✅ Added
    INDEX idx_orders_stale_pending (created_at),
    INDEX idx_customer_orders (customer_id, created_at, status)
);

CREATE TABLE IF NOT EXISTS order_items
(
    id                INT          NOT NULL AUTO_INCREMENT,
    tenant_id         INT          NOT NULL,
    order_id          INT          NOT NULL,
    product_id        INT          NOT NULL,
    product_name      VARCHAR(255) NOT NULL, -- Snapshot of product name at time of order
    product_sku       VARCHAR(100) NULL,
    quantity          INT          NOT NULL,
    unit_price_cents  INT          NOT NULL, -- Price at time of order
    total_price_cents INT          NOT NULL, -- quantity * unit_price
    discount_cents    INT          NOT NULL DEFAULT 0,

    -- Product options snapshot
    option_details    JSON         NULL,     -- Store selected options as JSON

    -- Image snapshot
    image_url         VARCHAR(500) NULL,     -- Snapshot of primary image URL

    -- Timestamps
    created_at        TIMESTAMP             DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP             DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at        TIMESTAMP    NULL,

    PRIMARY KEY (id, tenant_id),
    CONSTRAINT order_items_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT order_items_order_fk FOREIGN KEY (order_id, tenant_id) REFERENCES orders (id, tenant_id) ON DELETE CASCADE,
    CONSTRAINT order_items_product_fk FOREIGN KEY (product_id, tenant_id) REFERENCES products (id, tenant_id) ON DELETE RESTRICT,

    -- Indexes
    INDEX idx_tenant (tenant_id),
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id),
    INDEX idx_deleted (deleted_at)

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- =========================
-- Order Status History Table (Audit Trail)
-- =========================
CREATE TABLE IF NOT EXISTS order_status_history
(
    id              INT                                  NOT NULL AUTO_INCREMENT,
    tenant_id       INT                                  NOT NULL,
    order_id        INT                                  NOT NULL,
    old_status      VARCHAR(50)                          NULL,
    new_status      VARCHAR(50)                          NOT NULL,
    reason          VARCHAR(255)                         NULL,
    changed_by      INT                                  NULL, -- User ID who made the change
    changed_by_type ENUM ('system', 'admin', 'customer') NOT NULL DEFAULT 'system',
    created_at      TIMESTAMP                                     DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id, tenant_id),
    CONSTRAINT order_status_history_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT order_status_history_order_fk FOREIGN KEY (order_id, tenant_id) REFERENCES orders (id, tenant_id) ON DELETE CASCADE,
    CONSTRAINT order_status_history_user_fk FOREIGN KEY (changed_by) REFERENCES cms_users (id) ON DELETE SET NULL,

    INDEX idx_tenant (tenant_id),
    INDEX idx_order_id (order_id),
    INDEX idx_created_at (created_at)

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS payment_attempts
(
    id                       INT          NOT NULL AUTO_INCREMENT,
    tenant_id                INT          NOT NULL,
    order_id                 INT          NOT NULL,
    payment_processor        VARCHAR(50)  NOT NULL,
    attempt_number           INT          NOT NULL DEFAULT 1,

    -- Request/Response tracking
    request_payload          JSON         NULL,
    response_payload         JSON         NULL,
    payment_intent_id        VARCHAR(255) NULL,
    status                   VARCHAR(50)  NOT NULL COMMENT 'initiated, pending, succeeded, failed, expired',
    error_code               VARCHAR(100) NULL,
    error_message            TEXT         NULL,

    -- Timing
    started_at               DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    completed_at             DATETIME(6)  NULL,

    -- For ACH: when we expect settlement
    expected_settlement_date DATE         NULL,

    -- Audit
    ip_address               VARCHAR(45)  NULL,
    user_agent               TEXT         NULL,

    PRIMARY KEY (id, tenant_id),
    FOREIGN KEY (tenant_id, order_id) REFERENCES orders (tenant_id, id) ON DELETE CASCADE,
    INDEX idx_payment_attempts_order (order_id),
    INDEX idx_payment_attempts_intent (payment_intent_id),
    INDEX idx_payment_attempts_status (status),
    INDEX idx_payment_attempts_processor (payment_processor)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS payment_methods
(
    id                INT          NOT NULL AUTO_INCREMENT,
    tenant_id         INT          NOT NULL,
    customer_id       INT          NOT NULL,
    payment_processor VARCHAR(50)  NOT NULL,
    processor_token   VARCHAR(255) NOT NULL COMMENT 'Gateways token for this payment method',

    -- Display info
    nickname          VARCHAR(100) NULL,
    is_default        BOOLEAN      NOT NULL DEFAULT FALSE,

    -- Method-specific details
    method_type       VARCHAR(50)  NOT NULL COMMENT 'card, bank_account, digital_wallet',
    last_four         VARCHAR(4)   NULL,
    expiry_month      INT          NULL,
    expiry_year       INT          NULL,
    card_brand        VARCHAR(50)  NULL COMMENT 'visa, mastercard, amex',
    bank_name         VARCHAR(100) NULL,
    account_type      VARCHAR(50)  NULL COMMENT 'checking, savings',

    -- Metadata
    billing_address   JSON         NULL,
    metadata          JSON         NULL,

    -- Status
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Timestamps
    created_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at        DATETIME(6)  NULL,

    PRIMARY KEY (id, tenant_id),
    CONSTRAINT payment_methods_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT payment_methods_customer_fk FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL,
    INDEX idx_payment_methods_customer (customer_id),
    INDEX idx_payment_methods_processor_token (processor_token),
    INDEX idx_payment_methods_default (customer_id, is_default),
    INDEX idx_payment_methods_deleted (deleted_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS payment_webhook_events
(
    id                INT          NOT NULL AUTO_INCREMENT,
    tenant_id         INT          NULL COMMENT 'May not know initially, can be populated after processing',
    payment_processor VARCHAR(50)  NOT NULL,
    event_id          VARCHAR(255) NOT NULL COMMENT 'Gateways unique event ID (prevents duplicates)',
    event_type        VARCHAR(100) NOT NULL,

    -- Raw and processed data
    raw_payload       JSON         NOT NULL,
    processed_payload JSON         NULL,

    -- Processing status
    status            VARCHAR(50)  NOT NULL DEFAULT 'pending' COMMENT 'pending, processed, failed',
    error_message     TEXT         NULL,
    processed_at      DATETIME(6)  NULL,

    -- Timing
    received_at       DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    PRIMARY KEY (id),
    UNIQUE KEY uk_webhook_events (payment_processor, event_id),
    INDEX idx_webhook_events_status (status),
    INDEX idx_webhook_events_processor (payment_processor)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0004_orders',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Add Orders and Purchases'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0004_orders');
COMMIT;