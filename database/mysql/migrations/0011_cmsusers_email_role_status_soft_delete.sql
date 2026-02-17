/* ============================================================
   0011_cmsusers_email_role_status_soft_delete
   Adds Email, Status, DeletedAt; converts CmsUsers.Role to INT
   ============================================================ */

START TRANSACTION;

-- ------------------------------------------------------------
-- 1) Add Email (guarded)
--   Note: adding NOT NULL directly can fail if CmsUsers already has rows.
--   So: add NULLable -> backfill -> enforce NOT NULL.
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND COLUMN_NAME = 'Email'
        ),
        'SELECT 1;',
        'ALTER TABLE CmsUsers
         ADD COLUMN Email VARCHAR(255) NULL AFTER CognitoUserId;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill Email for existing rows that might not have it yet
-- Uses a non-routable placeholder domain to avoid accidental delivery.
UPDATE CmsUsers
SET Email = CONCAT(CognitoUserId, '@example.invalid')
WHERE Email IS NULL OR Email = '';

-- Enforce NOT NULL (guarded)
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND COLUMN_NAME = 'Email'
              AND IS_NULLABLE = 'YES'
        ),
        'ALTER TABLE CmsUsers MODIFY COLUMN Email VARCHAR(255) NOT NULL AFTER CognitoUserId;',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 2) Convert Role from VARCHAR -> INT (guarded)
--    Safe approach:
--      - add RoleInt if needed
--      - backfill using enum mapping
--      - replace old column
-- ------------------------------------------------------------
SET @needs_convert := (
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND COLUMN_NAME = 'Role'
              AND DATA_TYPE <> 'int'
        )
        THEN 1 ELSE 0
    END
);

SET @has_temp := (
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND COLUMN_NAME = 'RoleInt'
        )
        THEN 1 ELSE 0
    END
);

SET @sql := (
    SELECT IF(
        @needs_convert = 1 AND @has_temp = 0,
        'ALTER TABLE CmsUsers ADD COLUMN RoleInt INT NOT NULL DEFAULT 0 AFTER Role;',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill temp column (only when conversion is needed)
-- Enum mapping (case-insensitive):
--   Owner=0, Admin=1, Editor=2, Member=3
SET @sql := (
    SELECT IF(
        @needs_convert = 1,
        "UPDATE CmsUsers
         SET RoleInt =
             CASE
                 -- already numeric? keep it
                 WHEN Role REGEXP '^[0-9]+$'
                     THEN CAST(Role AS UNSIGNED)

                 -- string roles (case-insensitive)
                 WHEN LOWER(Role) IN ('owner')
                     THEN 0
                 WHEN LOWER(Role) IN ('admin','administrator')
                     THEN 1
                 WHEN LOWER(Role) IN ('editor')
                     THEN 2
                 WHEN LOWER(Role) IN ('member','user')
                     THEN 3

                 -- unknown values fall back to Owner(0)
                 ELSE 0
             END;",
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Swap columns
SET @sql := (
    SELECT IF(
        @needs_convert = 1,
        'ALTER TABLE CmsUsers DROP COLUMN Role;',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := (
    SELECT IF(
        @needs_convert = 1,
        'ALTER TABLE CmsUsers CHANGE COLUMN RoleInt Role INT NOT NULL;',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 3) Add User Status (guarded)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND COLUMN_NAME = 'Status'
        ),
        'SELECT 1;',
        'ALTER TABLE CmsUsers
         ADD COLUMN Status INT NOT NULL DEFAULT 0 AFTER Role;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 4) Add DeletedAt (soft delete) (guarded)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'CmsUsers'
              AND COLUMN_NAME = 'DeletedAt'
        ),
        'SELECT 1;',
        'ALTER TABLE CmsUsers
         ADD COLUMN DeletedAt DATETIME(6) NULL AFTER UpdatedAt;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 5) Record migration (idempotent)
-- ------------------------------------------------------------
INSERT INTO SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
SELECT
    '0011_cmsusers_email_role_status_soft_delete',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Add CmsUsers.Email/Status/DeletedAt; convert CmsUsers.Role to INT'
WHERE NOT EXISTS (
    SELECT 1
    FROM SchemaMigrations
    WHERE MigrationId = '0011_cmsusers_email_role_status_soft_delete'
);

COMMIT;
