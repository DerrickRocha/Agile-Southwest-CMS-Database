/* ============================================================
   0012_add_tenants_cmsusers_constraints
   Adds unique indexes + ensures FK CmsUsers(TenantId) -> Tenants(TenantId)
   ============================================================ */

START TRANSACTION;

-- ------------------------------------------------------------
-- 1) Unique index: Tenants(Subdomain)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Tenants'
              AND INDEX_NAME = 'UX_Tenants_Subdomain'
        ),
        'SELECT 1;',
        'CREATE UNIQUE INDEX UX_Tenants_Subdomain ON Tenants (Subdomain);'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 2) Unique index: Tenants(CustomDomain)
--    NOTE: MySQL UNIQUE allows multiple NULLs, which is usually what you want here.
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Tenants'
              AND INDEX_NAME = 'UX_Tenants_CustomDomain'
        ),
        'SELECT 1;',
        'CREATE UNIQUE INDEX UX_Tenants_CustomDomain ON Tenants (CustomDomain);'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 3) Unique index: CmsUsers(CognitoUserId)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND INDEX_NAME = 'UX_CmsUsers_CognitoUserId'
        ),
        'SELECT 1;',
        'CREATE UNIQUE INDEX UX_CmsUsers_CognitoUserId ON CmsUsers (CognitoUserId);'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 4) Unique index: CmsUsers(TenantId, Email)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND INDEX_NAME = 'UX_CmsUsers_Tenant_Email'
        ),
        'SELECT 1;',
        'CREATE UNIQUE INDEX UX_CmsUsers_Tenant_Email ON CmsUsers (TenantId, Email);'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 5) Foreign key: CmsUsers(TenantId) -> Tenants(TenantId) ON DELETE RESTRICT
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND CONSTRAINT_TYPE = 'FOREIGN KEY'
              AND CONSTRAINT_NAME = 'FK_CmsUsers_Tenants'
        ),
        'SELECT 1;',
        'ALTER TABLE CmsUsers
         ADD CONSTRAINT FK_CmsUsers_Tenants
         FOREIGN KEY (TenantId)
         REFERENCES Tenants(TenantId)
         ON DELETE RESTRICT;'
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
    '0012_add_tenants_cmsusers_constraints',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Add unique indexes for Tenants/CmsUsers + ensure CmsUsers->Tenants FK'
WHERE NOT EXISTS (
    SELECT 1
    FROM SchemaMigrations
    WHERE MigrationId = '0012_add_tenants_cmsusers_constraints'
);

COMMIT;
