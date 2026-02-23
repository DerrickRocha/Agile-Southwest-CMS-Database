/* ============================================================
   0013_add_user_tenants
   Adds UserTenants table and migrates existing relationships
   ============================================================ */

START TRANSACTION;

CREATE TABLE IF NOT EXISTS UserTenants
(
    UserId    BINARY(16)  NOT NULL,
    TenantId  BINARY(16)  NOT NULL,
    Role      VARCHAR(50) NOT NULL DEFAULT 'Member',
    CreatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    DeletedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    PRIMARY KEY (UserId, TenantId),

    CONSTRAINT FK_UserTenants_User
        FOREIGN KEY (UserId) REFERENCES CmsUsers (CmsUserId)
            ON DELETE CASCADE,

    CONSTRAINT FK_User_Tenants_Tenant
        FOREIGN KEY (TenantId) REFERENCES Tenants (TenantId)
            ON DELETE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- Index for fast tenant lookups
-- ------------------------------------------------------------
-- 1) Unique index: Tenants(Subdomain)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'UserTenants'
              AND INDEX_NAME = 'INDEX_IX_UserTenants_TenentId'
        ),
        'SELECT 1;',
        'CREATE UNIQUE INDEX INDEX_IX_UserTenants_TenentId ON UserTenants (TenantId);'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

         -- ------------------------------------------------------------
-- 6) Record migration (idempotent)
-- ------------------------------------------------------------
INSERT INTO SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
SELECT
    '0013_add_user_tenants',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    ' Adds UserTenants table and migrates existing relationships'
    WHERE NOT EXISTS (
    SELECT 1
    FROM SchemaMigrations
    WHERE MigrationId = '0013_add_user_tenants'
);

COMMIT;