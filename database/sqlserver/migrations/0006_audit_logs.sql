IF EXISTS (SELECT 1 FROM app.SchemaMigrations WHERE MigrationId = '0006_audit_logs')
    THROW 50000, 'Migration already applied', 1;

BEGIN TRAN;

CREATE TABLE app.AuditLogs (
    AuditLogId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ActorUserId NVARCHAR(100),
    ActorRole NVARCHAR(50),
    Action NVARCHAR(200),
    EntityName NVARCHAR(100),
    EntityId UNIQUEIDENTIFIER,
    IpAddress NVARCHAR(50),
    CreatedAt DATETIME2 DEFAULT SYSDATETIME()
);

INSERT INTO app.SchemaMigrations VALUES
('0006_audit_logs', SYSDATETIME(), SUSER_SNAME(), 'Audit logging');

COMMIT;