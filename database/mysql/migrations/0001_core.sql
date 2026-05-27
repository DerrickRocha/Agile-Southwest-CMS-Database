-- ----------------------------------------
-- 0001_core.sql
-- Core tenancy & users
-- ----------------------------------------

START TRANSACTION;

-- ----------------------------------------
-- 2️CMS Users (admins/editors)
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS cms_users
(
    id              int PRIMARY KEY AUTO_INCREMENT,
    cognito_user_id VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    role            VARCHAR(50)  NOT NULL,
    status          VARCHAR(50)  NOT NULL,
    created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at      DATETIME(6)  NULL,
    UNIQUE KEY uq_cms_users_email (email)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- ----------------------------------------
-- 1️⃣ Tenants
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS tenants
(
    id            Int PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(200) NOT NULL,
    sub_domain    VARCHAR(100) NOT NULL,
    custom_domain VARCHAR(255),
    created_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at    DATETIME(6)  NULL,
    row_version   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_tenants_subdomain (sub_domain)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;


CREATE TABLE IF NOT EXISTS user_tenants
(
    tenant_id   Int         NOT NULL,
    user_id     Int         NOT NULL,
    PRIMARY KEY (tenant_id, user_id),
    Role        VARCHAR(50) NOT NULL DEFAULT 'Member',
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at  DATETIME(6) NULL,
    row_version TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT user_tenant_user_fk FOREIGN KEY (user_id) REFERENCES cms_users (id) ON DELETE CASCADE,
    CONSTRAINT user_tenant_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS tax_categories
(
    id         INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id  INT          NOT NULL,
    name       VARCHAR(255) NOT NULL,
    tax_rate   DECIMAL      NOT NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME     NULL,
    CONSTRAINT tax_category_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id),

    INDEX idx_tax_categories_tenant_id (tenant_id)
);

-- ----------------------------------------
-- 3️⃣ Customers (storefront users)
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS customers
(
    id          Int PRIMARY KEY AUTO_INCREMENT,
    tenant_id   INT          NULL,
    user_id     Int          NOT NULL,
    email       VARCHAR(255) NOT NULL,
    created_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at  DATETIME(6)  NULL,
    row_version TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_customers_tenant_email (email),
    CONSTRAINT customer_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT customer_user_fk FOREIGN KEY (user_id) REFERENCES cms_users (id) ON DELETE CASCADE,
    INDEX idx_tenant_id (tenant_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;


-- ----------------------------------------
-- 4️⃣ Record migration (idempotent)
-- ----------------------------------------
INSERT INTO schema_migrations (migration_id,
                               applied_at,
                               applied_by,
                               description)
SELECT '0001_core',
       CURRENT_TIMESTAMP(6),
       CURRENT_USER(),
       'Core tenancy & users'
WHERE NOT EXISTS (SELECT 1
                  FROM schema_migrations
                  WHERE migration_id = '0001_core');

COMMIT;
