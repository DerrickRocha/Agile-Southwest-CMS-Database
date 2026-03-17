START TRANSACTION;

CREATE TABLE IF NOT EXISTS products
(
    id          Int PRIMARY KEY AUTO_INCREMENT,
    tenant_id   Int          NOT NULL,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    base_price_cents   INT          NOT NULL,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT product_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    INDEX product_tenant_idx (tenant_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_options
(
    id         INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT          NOT NULL,
    name       VARCHAR(255) NOT NULL,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX product_option_product_idx (product_id),
    CONSTRAINT product_option_product_fk FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS product_option_choices
(
    id         INT PRIMARY KEY AUTO_INCREMENT,
    option_id  INT          NOT NULL,
    name       VARCHAR(255) NOT NULL,
    price_delta_cents INT          NOT NULL,
    sale_price_delta_cents INT,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX product_option_choice_option_idx (option_id),
    CONSTRAINT product_option_choice_option_fk FOREIGN KEY (option_id) REFERENCES product_options (id) ON DELETE CASCADE
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