/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Raw landing zone for end-of-day stock level extracts. Nullable
                 by default; validation happens in [etl].[LoadInventorySnapshot].

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE TABLE [stg].[InventorySnapshot]
(
    [StagingRowId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [SnapshotDate]  DATE            NULL,
    [ProductCode]   NVARCHAR (20)   NULL,
    [StoreCode]     NVARCHAR (20)   NULL,
    [StockQuantity] DECIMAL (18, 4) NULL,
    [SourceSystem]  NVARCHAR (20)   NULL,
    [LoadedAt]      DATETIME2 (3)   NOT NULL CONSTRAINT [DF_stg_InventorySnapshot_LoadedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_stg_InventorySnapshot] PRIMARY KEY CLUSTERED ([StagingRowId] ASC)
);
