-- ----------------------------------------
-- 0006_audit_logs.sql
-- Audit logging
-- ----------------------------------------

START TRANSACTION;

CREATE TABLE IF NOT EXISTS AuditLogs (
                                         AuditLogId BINARY(16) PRIMARY KEY,
    TenantId   BINARY(16) NOT NULL,
    ActorUserId VARCHAR(100),
    ActorRole   VARCHAR(50),
    Action      VARCHAR(200),
    EntityName  VARCHAR(100),
    EntityId    BINARY(16),
    IpAddress   VARCHAR(50),
    CreatedAt   DATETIME(6)
    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_auditlogs_tenant
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO SchemaMigrations
SELECT '0006_audit_logs', CURRENT_TIMESTAMP(6), CURRENT_USER(), 'Audit logging'
    WHERE NOT EXISTS (
    SELECT 1 FROM SchemaMigrations WHERE MigrationId = '0006_audit_logs'
);

COMMIT;
