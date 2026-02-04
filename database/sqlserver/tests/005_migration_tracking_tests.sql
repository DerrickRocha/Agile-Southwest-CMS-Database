BEGIN TRANSACTION;

DECLARE @MigrationId NVARCHAR(150) = 'test_migration_005';

-- Insert migration record
INSERT INTO app.SchemaMigrations (
    MigrationId,
    AppliedAt,
    AppliedBy,
    Description
)
VALUES (
           @MigrationId,
           SYSDATETIME(),
           SUSER_SNAME(),
           'Test migration insert'
       );

-- Verify it exists
IF NOT EXISTS (
    SELECT 1
    FROM app.SchemaMigrations
    WHERE MigrationId = @MigrationId
)
    THROW 54001, 'Migration not recorded correctly', 1;

ROLLBACK TRANSACTION;

