-- ----------------------------------------
-- 0001_core.sql
-- Core tenancy & users
-- ----------------------------------------

START TRANSACTION;

-- ----------------------------------------
-- 1️⃣ Tenants
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS Tenants (
                                       TenantId BINARY(16) PRIMARY KEY,
                                       Name VARCHAR(200) NOT NULL,
                                       Subdomain VARCHAR(100) NOT NULL,
                                       CustomDomain VARCHAR(255),
                                       SubscriptionStatus VARCHAR(50) NOT NULL,
                                       CreatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                       UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                       UNIQUE KEY uq_tenants_subdomain (Subdomain)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------
-- 2️⃣ CMS Users (admins/editors)
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS CmsUsers (
                                        CmsUserId BINARY(16) PRIMARY KEY,
                                        TenantId  BINARY(16) NOT NULL,
                                        CognitoUserId VARCHAR(100) NOT NULL,
                                        Role VARCHAR(50) NOT NULL,
                                        CreatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                        UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                        CONSTRAINT fk_cmsusers_tenant
                                            FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
                                                ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------
-- 3️⃣ Customers (storefront users)
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS Customers (
                                         CustomerId BINARY(16) PRIMARY KEY,
                                         TenantId   BINARY(16) NOT NULL,
                                         CognitoUserId VARCHAR(100),
                                         Email VARCHAR(255) NOT NULL,
                                         CreatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                         UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                         CONSTRAINT fk_customers_tenant
                                             FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
                                                 ON DELETE CASCADE,
                                         UNIQUE KEY uq_customers_tenant_email (TenantId, Email)
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
    '0001_core',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Core tenancy & users'
WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0001_core'
);

COMMIT;
