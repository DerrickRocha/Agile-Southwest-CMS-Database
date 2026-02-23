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
    UNIQUE KEY uq_cms_users_email (email)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- ----------------------------------------
-- 1️⃣ Tenants
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS tenants
(
    id                  Int PRIMARY KEY AUTO_INCREMENT,
    name                VARCHAR(200) NOT NULL,
    sub_domain          VARCHAR(100) NOT NULL,
    custom_domain       VARCHAR(255),
    plan_tier           VARCHAR(50)  NOT NULL,
    subscription_status VARCHAR(50)  NOT NULL,
    status              VARCHAR(50)  NOT NULL,
    created_at          DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at          DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_tenants_subdomain (sub_domain)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;


CREATE TABLE IF NOT EXISTS user_tenants
(
    tenant_id Int NOT NULL,
    user_id   Int NOT NULL,
    PRIMARY KEY (tenant_id, user_id),
    Role      VARCHAR(50)     NOT NULL DEFAULT 'Member',
    CreatedAt DATETIME(6)     NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UpdatedAt DATETIME(6)     NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    DeletedAt DATETIME(6)     NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT user_tenant_user_fk FOREIGN KEY (user_id) REFERENCES cms_users (id) ON DELETE CASCADE,
    CONSTRAINT user_tenant_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- ----------------------------------------
-- 3️⃣ Customers (storefront users)
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS customers
(
    id         Int PRIMARY KEY AUTO_INCREMENT,
    user_id    Int          NOT NULL,
    email      VARCHAR(255) NOT NULL,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_customers_tenant_email (email),
    CONSTRAINT customer_user_fk FOREIGN KEY (user_id) REFERENCES cms_users (id) ON DELETE CASCADE
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
