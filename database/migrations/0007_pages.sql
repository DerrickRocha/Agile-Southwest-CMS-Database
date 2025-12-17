/* ============================================================
   Migration: 0007_pages
   Description: CMS-managed pages (home, about, contact, etc.)
   ============================================================ */

IF EXISTS (
    SELECT 1 FROM app.SchemaMigrations
    WHERE MigrationId = '0007_pages'
)
    THROW 50000, 'Migration 0007_pages already applied', 1;

SET XACT_ABORT ON;
BEGIN TRAN;

CREATE TABLE app.Pages (
    PageId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_Pages PRIMARY KEY
        DEFAULT NEWID(),

    TenantId UNIQUEIDENTIFIER NOT NULL,

    Slug NVARCHAR(100) NOT NULL,      -- home, about, contact, products
    Title NVARCHAR(200) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,

    IsPublished BIT NOT NULL DEFAULT 1,

    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Pages_Tenant
        FOREIGN KEY (TenantId)
        REFERENCES app.Tenants(TenantId),

    CONSTRAINT UQ_Pages_Tenant_Slug
        UNIQUE (TenantId, Slug)
);

-- Performance index for storefront page resolution
CREATE INDEX IX_Pages_Tenant_Slug
    ON app.Pages (TenantId, Slug);

INSERT INTO app.SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
VALUES (
    '0007_pages',
    SYSDATETIME(),
    SUSER_SNAME(),
    'CMS pages for tenant storefronts'
);

COMMIT;
