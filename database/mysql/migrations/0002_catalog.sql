-- ----------------------------------------
-- 0002_catalog.sql
-- Products catalog
-- ----------------------------------------
START TRANSACTION;

CREATE TABLE IF NOT EXISTS images
(
    id                INT           NOT NULL PRIMARY KEY AUTO_INCREMENT,
    tenant_id         INT           NOT NULL,
    url               VARCHAR(2048) NOT NULL,
    original_filename VARCHAR(255),
    file_size         BIGINT,
    content_type      VARCHAR(100),
    created_at        DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at        DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at        DATETIME(6)   NULL,
    row_version       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT image_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    INDEX idx_tenant (tenant_id),
    INDEX idx_deleted (deleted_at),
    INDEX idx_tenant_deleted (tenant_id, deleted_at)

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS products
(
    id                           INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id                    INT          NOT NULL,
    tax_category_id              INT          NULL,
    name                         VARCHAR(255) NOT NULL,
    description                  TEXT,
    base_price_cents             INT          NOT NULL,
    is_active                    BOOLEAN      NOT NULL DEFAULT TRUE,
    is_enhanced_payment_required BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at                   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at                   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at                   DATETIME(6)  NULL,
    row_version                  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT product_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT products_tax_category_fk FOREIGN KEY (tax_category_id) REFERENCES tax_categories (id),
    UNIQUE KEY uk_tenant_product (tenant_id, id),
    INDEX product_tenant_idx (tenant_id),
    INDEX product_tenant_active_idx (tenant_id, is_active),
    INDEX product_tenant_name_idx (tenant_id, name),
    INDEX idx_tenant_active_price (tenant_id, is_active, base_price_cents),
    INDEX idx_tenant_created (tenant_id, created_at DESC)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_options
(
    id          INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id   INT          NOT NULL,
    product_id  INT          NOT NULL,
    name        VARCHAR(255) NOT NULL,
    is_required BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at  DATETIME(6)  NULL,
    row_version TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT product_option_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT product_option_product_fk FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
    UNIQUE KEY uk_tenant_option (tenant_id, id),
    INDEX product_option_product_idx (product_id, tenant_id),
    INDEX product_option_tenant_idx (tenant_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_option_choices
(
    id                     INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id              INT          NOT NULL,
    option_id              INT          NOT NULL,
    name                   VARCHAR(255) NOT NULL,
    price_delta_cents      INT          NOT NULL,
    sale_price_delta_cents INT,
    is_active              BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at             DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at             DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at             DATETIME(6)  NULL,
    row_version            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT product_option_choice_option_fk FOREIGN KEY (option_id) REFERENCES product_options (id) ON DELETE CASCADE,
    CONSTRAINT product_option_choices_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT chk_price_delta_range
        CHECK (price_delta_cents >= -1000000 AND price_delta_cents <= 1000000),
    INDEX product_option_choice_option_idx (option_id, tenant_id),
    INDEX product_option_choice_tenant_idx (tenant_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_images
(
    id          INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id   INT         NOT NULL,
    product_id  INT         NOT NULL,
    image_id    INT         NOT NULL,
    is_primary  BOOLEAN     NOT NULL DEFAULT FALSE,
    position    INT         NOT NULL DEFAULT 0,
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at  DATETIME(6) NULL,
    row_version TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_product_image (product_id, image_id),
    UNIQUE KEY uk_position_per_product (tenant_id, product_id, position),
    CONSTRAINT FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES images (id) ON DELETE CASCADE,
    CONSTRAINT chk_position_non_negative CHECK (position >= 0),
    INDEX image_product_idx (product_id, tenant_id),
    INDEX image_primary_idx (product_id, is_primary),
    INDEX idx_deleted (deleted_at),
    INDEX idx_product_images_image(image_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

INSERT INTO schema_migrations (migration_id,
                               applied_by,
                               description)
SELECT '0002_catalog',
       CURRENT_USER(),
       'Product catalog'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0002_catalog');

COMMIT;