/* ============================================================
   Migration: 0008_add_stores_and_store_scoping
   Purpose  : Introduce Stores and scope Products, Inventory,
              Orders to a Store while preserving existing data
   Author   : Your Name
   ============================================================ */
   IF EXISTS (SELECT 1 FROM app.SchemaMigrations WHERE MigrationId = '008_add_stores_and_store_scoping')
    THROW 50000, 'Migration already applied', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    /* ============================================================
       1️⃣ Create Stores table
       ============================================================ */
    IF NOT EXISTS (
        SELECT 1 FROM sys.tables 
        WHERE name = 'Stores' AND schema_id = SCHEMA_ID('app')
    )
    BEGIN
        CREATE TABLE app.Stores (
            StoreId     UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            TenantId    UNIQUEIDENTIFIER NOT NULL,
            Name        NVARCHAR(200) NOT NULL,
            IsDefault   BIT NOT NULL DEFAULT 0,
            CreatedAt   DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
            UpdatedAt   DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

            CONSTRAINT FK_Stores_Tenants
                FOREIGN KEY (TenantId)
                REFERENCES app.Tenants(TenantId)
        );
    END

    /* ============================================================
       2️⃣ Insert a default store for each tenant (idempotent)
       ============================================================ */
    INSERT INTO app.Stores (TenantId, Name, IsDefault)
    SELECT
        t.TenantId,
        'Main Store',
        1
    FROM app.Tenants t
    WHERE NOT EXISTS (
        SELECT 1
        FROM app.Stores s
        WHERE s.TenantId = t.TenantId
          AND s.IsDefault = 1
    );

    /* ============================================================
       3️⃣ Add StoreId column (nullable for now)
       ============================================================ */

    -- Products
    IF COL_LENGTH('app.Products', 'StoreId') IS NULL
        ALTER TABLE app.Products ADD StoreId UNIQUEIDENTIFIER NULL;

    -- Inventory
    IF COL_LENGTH('app.Inventory', 'StoreId') IS NULL
        ALTER TABLE app.Inventory ADD StoreId UNIQUEIDENTIFIER NULL;

    -- Orders
    IF COL_LENGTH('app.Orders', 'StoreId') IS NULL
        ALTER TABLE app.Orders ADD StoreId UNIQUEIDENTIFIER NULL;

    /* ============================================================
       4️⃣ Backfill StoreId using default store
       ============================================================ */

    -- Products
    UPDATE p
    SET StoreId = s.StoreId
    FROM app.Products p
    JOIN app.Stores s
        ON s.TenantId = p.TenantId
       AND s.IsDefault = 1
    WHERE p.StoreId IS NULL;

    -- Inventory
    UPDATE i
    SET StoreId = s.StoreId
    FROM app.Inventory i
    JOIN app.Stores s
        ON s.TenantId = i.TenantId
       AND s.IsDefault = 1
    WHERE i.StoreId IS NULL;

    -- Orders
    UPDATE o
    SET StoreId = s.StoreId
    FROM app.Orders o
    JOIN app.Stores s
        ON s.TenantId = o.TenantId
       AND s.IsDefault = 1
    WHERE o.StoreId IS NULL;

    /* ============================================================
       5️⃣ Enforce NOT NULL + Foreign Keys
       ============================================================ */

    ALTER TABLE app.Products
        ALTER COLUMN StoreId UNIQUEIDENTIFIER NOT NULL;

    ALTER TABLE app.Inventory
        ALTER COLUMN StoreId UNIQUEIDENTIFIER NOT NULL;

    ALTER TABLE app.Orders
        ALTER COLUMN StoreId UNIQUEIDENTIFIER NOT NULL;

    ALTER TABLE app.Products
        ADD CONSTRAINT FK_Products_Stores
            FOREIGN KEY (StoreId)
            REFERENCES app.Stores(StoreId);

    ALTER TABLE app.Inventory
        ADD CONSTRAINT FK_Inventory_Stores
            FOREIGN KEY (StoreId)
            REFERENCES app.Stores(StoreId);

    ALTER TABLE app.Orders
        ADD CONSTRAINT FK_Orders_Stores
            FOREIGN KEY (StoreId)
            REFERENCES app.Stores(StoreId);

    /* ============================================================
       6️⃣ Indexes for performance & tenant/store isolation
       ============================================================ */

    CREATE INDEX IX_Stores_TenantId
        ON app.Stores (TenantId);

    CREATE INDEX IX_Products_Tenant_Store
        ON app.Products (TenantId, StoreId);

    CREATE INDEX IX_Inventory_Tenant_Store
        ON app.Inventory (TenantId, StoreId);

    CREATE INDEX IX_Orders_Tenant_Store
        ON app.Orders (TenantId, StoreId);

    /* ============================================================
       7️⃣ Record migration as applied
       ============================================================ */
  

    INSERT INTO app.SchemaMigrations VALUES (
        '008_add_stores_and_store_scoping',
        SYSDATETIME(),
        SUSER_SNAME(),
        'Stores and store scoping'
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;

    THROW;
END CATCH;
