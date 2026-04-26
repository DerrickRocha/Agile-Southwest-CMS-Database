START TRANSACTION;

CREATE TABLE IF NOT EXISTS images(
                                     id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
                                     tenant_id INT NOT NULL,
                                     url VARCHAR(2048) NOT NULL,
                                     original_filename VARCHAR(255),
                                     file_size BIGINT,
                                     content_type VARCHAR(100),
                                     created_at       TIMESTAMP             DEFAULT CURRENT_TIMESTAMP,
                                     updated_at       TIMESTAMP             DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                     deleted_at       TIMESTAMP    NULL,
                                     CONSTRAINT image_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
                                     INDEX idx_tenant (tenant_id),
                                     INDEX idx_deleted (deleted_at),
                                     INDEX idx_tenant_deleted (tenant_id, deleted_at)

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS products
(
    id               Int          NOT NULL AUTO_INCREMENT,
    tenant_id        Int          NOT NULL,
    name             VARCHAR(255) NOT NULL,
    description      TEXT,
    base_price_cents INT          NOT NULL,
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    is_enhanced_payment_required BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    row_version TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id, tenant_id),
    CONSTRAINT product_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    INDEX product_tenant_idx (tenant_id),
    INDEX product_tenant_active_idx (tenant_id, is_active),
    INDEX product_tenant_name_idx (tenant_id, name)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_options
(
    id          INT AUTO_INCREMENT,
    tenant_id   Int          NOT NULL,
    product_id  INT          NOT NULL,
    name        VARCHAR(255) NOT NULL,
    is_required BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    row_version TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id, tenant_id),
    CONSTRAINT product_option_tenant_product_fk FOREIGN KEY (product_id, tenant_id) REFERENCES products (id, tenant_id) ON DELETE CASCADE,
    INDEX product_option_product_idx (product_id, tenant_id),
    INDEX product_option_tenant_idx (tenant_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_option_choices
(
    id                     INT AUTO_INCREMENT,
    tenant_id              INT          NOT NULL,
    option_id              INT          NOT NULL,
    name                   VARCHAR(255) NOT NULL,
    price_delta_cents      INT          NOT NULL,
    sale_price_delta_cents INT,
    is_active              BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    row_version TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id, tenant_id),
    CONSTRAINT product_option_choice_option_fk FOREIGN KEY (option_id, tenant_id) REFERENCES product_options (id, tenant_id) ON DELETE CASCADE,
    INDEX product_option_choice_option_idx (option_id, tenant_id),
    INDEX product_option_choice_tenant_idx (tenant_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_images
(
    id         INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id  INT       NOT NULL,
    product_id INT       NOT NULL,
    image_id   INT       NOT NULL,
    is_primary BOOLEAN   NOT NULL DEFAULT FALSE,
    position INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP          DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    UNIQUE KEY uk_active_product_image (tenant_id, product_id, image_id),
    UNIQUE KEY uk_position_per_product (tenant_id, product_id, position),
    FOREIGN KEY (tenant_id, product_id) REFERENCES products (tenant_id, id),
    FOREIGN KEY (image_id) REFERENCES images (id),
    INDEX image_product_idx (product_id, tenant_id),
    INDEX image_product_tenant_idx (tenant_id),
    INDEX image_primary_idx (product_id, is_primary),
    INDEX idx_deleted (deleted_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0002_catalog',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Product catalog'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0002_catalog');

COMMIT;