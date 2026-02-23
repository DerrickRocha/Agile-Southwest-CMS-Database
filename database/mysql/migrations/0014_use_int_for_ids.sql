/* ============================================================
   0014_binary16_to_int_autoinc_empty
   MySQL: Convert BINARY(16) PK/FK columns to INT AUTO_INCREMENT.
   Assumption: tables are empty (enforced by checks).
   ============================================================ */

START TRANSACTION;

SET @migration_id := '0014_use_int_for_ids';

-- ... existing code ...

SET FOREIGN_KEY_CHECKS = 0;

-- ... existing code ...

-- Replace the old dynamic GROUP_CONCAT FK-drop blocks with this procedure-based approach
DROP PROCEDURE IF EXISTS DropAllForeignKeys;
DELIMITER $$

CREATE PROCEDURE DropAllForeignKeys(IN in_table_name VARCHAR(64))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE fk_name VARCHAR(64);

    DECLARE cur CURSOR FOR
        SELECT CONSTRAINT_NAME
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = in_table_name
          AND CONSTRAINT_TYPE = 'FOREIGN KEY';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO fk_name;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        SET @stmt = CONCAT('ALTER TABLE `', in_table_name, '` DROP FOREIGN KEY `', fk_name, '`');
        PREPARE s FROM @stmt;
        EXECUTE s;
        DEALLOCATE PREPARE s;
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;

-- Drop all FKs on tables that participate (add/remove as needed)
CALL DropAllForeignKeys('UserTenants');
CALL DropAllForeignKeys('Invoices');
CALL DropAllForeignKeys('Subscriptions');
CALL DropAllForeignKeys('Payments');
CALL DropAllForeignKeys('OrderItems');
CALL DropAllForeignKeys('Orders');
CALL DropAllForeignKeys('Inventory');
CALL DropAllForeignKeys('ProductOptions');
CALL DropAllForeignKeys('Products');
CALL DropAllForeignKeys('Customers');
CALL DropAllForeignKeys('CmsUsers');
CALL DropAllForeignKeys('Stores');
CALL DropAllForeignKeys('Pages');
CALL DropAllForeignKeys('AuditLogs');

-- optional cleanup (keeps migration re-runnable in dev resets)
DROP PROCEDURE IF EXISTS DropAllForeignKeys;

-- ... existing code ...

SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------
-- Record migration (idempotent)
-- ------------------------------------------------------------
INSERT INTO SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
SELECT
    @migration_id,
    CURRENT_TIMESTAMP(6),
    CURRENT_USER(),
    'Convert BINARY(16) PK/FK columns to INT AUTO_INCREMENT.'
WHERE NOT EXISTS (
    SELECT 1
    FROM SchemaMigrations
    WHERE MigrationId = @migration_id
);

COMMIT;

COMMIT;