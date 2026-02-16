/* ============================================================
   0010_tenant_plan_tier_status_soft_delete
   Adds PlanTier, Status, DeletedAt; converts SubscriptionStatus to INT
   ============================================================ */

START TRANSACTION;

-- ------------------------------------------------------------
-- 1) Add PlanTier (guarded)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Tenants'
              AND COLUMN_NAME = 'PlanTier'
        ),
        'SELECT 1;',
        'ALTER TABLE Tenants
         ADD COLUMN PlanTier INT NOT NULL DEFAULT 0 AFTER CustomDomain;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 2) Convert SubscriptionStatus from VARCHAR -> INT (guarded)
--    Safe approach:
--      - add SubscriptionStatusInt if needed
--      - backfill (numeric strings cast; otherwise 0)
--      - replace old column
-- ------------------------------------------------------------
SET @needs_convert := (
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Tenants'
              AND COLUMN_NAME = 'SubscriptionStatus'
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
              AND TABLE_NAME = 'Tenants'
              AND COLUMN_NAME = 'SubscriptionStatusInt'
        )
        THEN 1 ELSE 0
    END
);

SET @sql := (
    SELECT IF(
        @needs_convert = 1 AND @has_temp = 0,
        'ALTER TABLE Tenants ADD COLUMN SubscriptionStatusInt INT NOT NULL DEFAULT 0 AFTER SubscriptionStatus;',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill temp column (only when conversion is needed)
SET @sql := (
    SELECT IF(
        @needs_convert = 1,
        "UPDATE Tenants
         SET SubscriptionStatusInt =
             CASE
                 WHEN SubscriptionStatus REGEXP '^[0-9]+$' THEN CAST(SubscriptionStatus AS UNSIGNED)
                 ELSE 0
             END;",
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Replace the original column with the INT version
SET @sql := (
    SELECT IF(
        @needs_convert = 1,
        'ALTER TABLE Tenants DROP COLUMN SubscriptionStatus;',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := (
    SELECT IF(
        @needs_convert = 1,
        'ALTER TABLE Tenants CHANGE COLUMN SubscriptionStatusInt SubscriptionStatus INT NOT NULL;',
        'SELECT 1;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 3) Add Tenant Status (guarded)
-- ------------------------------------------------------------
SET @sql := (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'Tenants'
              AND COLUMN_NAME = 'Status'
        ),
        'SELECT 1;',
        'ALTER TABLE Tenants
         ADD COLUMN Status INT NOT NULL DEFAULT 0 AFTER SubscriptionStatus;'
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
              AND TABLE_NAME = 'Tenants'
              AND COLUMN_NAME = 'DeletedAt'
        ),
        'SELECT 1;',
        'ALTER TABLE Tenants
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
    '0010_tenant_plan_tier_status_soft_delete',
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Add PlanTier/Status/DeletedAt; convert Tenants.SubscriptionStatus to INT'
WHERE NOT EXISTS (
    SELECT 1
    FROM SchemaMigrations
    WHERE MigrationId = '0010_tenant_plan_tier_status_soft_delete'
);

COMMIT;
