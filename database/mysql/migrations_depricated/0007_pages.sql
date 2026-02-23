-- ----------------------------------------
-- 0007_pages.sql
-- CMS pages
-- ----------------------------------------

START TRANSACTION;

CREATE TABLE IF NOT EXISTS Pages (
                                     PageId BINARY(16) PRIMARY KEY,
    TenantId BINARY(16) NOT NULL,
    Slug VARCHAR(100) NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Content LONGTEXT NOT NULL,
    IsPublished TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UpdatedAt DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_pages_tenant
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    ON DELETE CASCADE,
    UNIQUE KEY uq_pages_tenant_slug (TenantId, Slug),
    KEY ix_pages_tenant_slug (TenantId, Slug)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO SchemaMigrations
SELECT '0007_pages', CURRENT_TIMESTAMP(6), CURRENT_USER(), 'CMS pages'
    WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0007_pages'
);

COMMIT;
