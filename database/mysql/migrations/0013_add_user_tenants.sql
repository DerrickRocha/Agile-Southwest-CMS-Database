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
        FOREIGN KEY (TenantId) REFERENCES Tenant (TenantId)
            ON DELETE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- Index for fast tenant lookups

CREATE INDEX INDEX_IX_UserTenants_TenentId ON UserTenants (TenantId);

-- =====================================================
-- 2️⃣ Migrate Existing Relationships
-- =====================================================
INSERT INTO UserTenants (UserId, TenantId, Role, CreatedAt)
SELECT CmsUserId, TenantId, 'Member', CreatedAt
FROM CmsUsers
WHERE TenantId IS NOT NULL;



COMMIT;