SET XACT_ABORT ON;
BEGIN TRAN;

IF NOT EXISTS (SELECT 1
               FROM sys.schemas
               WHERE name = 'app')
    BEGIN
        CREATE SCHEMA app;
    END

IF OBJECT_ID('app.SchemaMigrations', 'U') IS NULL
    BEGIN
        CREATE TABLE app.SchemaMigrations
        (
            MigrationId NVARCHAR(150) PRIMARY KEY,
            AppliedAt   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
            AppliedBy   NVARCHAR(128) NOT NULL,
            Description NVARCHAR(500)
        );
    END

COMMIT;

