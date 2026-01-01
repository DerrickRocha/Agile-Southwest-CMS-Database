SET XACT_ABORT ON;
BEGIN TRAN;

-- 1️⃣ Create app schema FIRST
IF NOT EXISTS (SELECT 1
               FROM sys.schemas
               WHERE name = 'app')
    BEGIN
        EXEC ('CREATE SCHEMA app');
    END;

-- 2️⃣ Create SchemaMigrations table
IF NOT EXISTS (SELECT 1
               FROM sys.tables t
                        JOIN sys.schemas s ON t.schema_id = s.schema_id
               WHERE t.name = 'SchemaMigrations'
                 AND s.name = 'app')
    BEGIN
        CREATE TABLE app.SchemaMigrations
        (
            MigrationId NVARCHAR(150) PRIMARY KEY,
            AppliedAt   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
            AppliedBy   NVARCHAR(128) NOT NULL,
            Description NVARCHAR(500)
        );
    END;

COMMIT;

