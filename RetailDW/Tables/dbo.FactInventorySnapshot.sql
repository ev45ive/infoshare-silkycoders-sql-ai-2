/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: End-of-day stock level per product and store.

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE TABLE [dbo].[FactInventorySnapshot]
(
    [InventorySnapshotKey] BIGINT          NOT NULL,
    [SnapshotDate]         DATE            NOT NULL,
    [ProductKey]           INT             NOT NULL,
    [StoreKey]             INT             NOT NULL,
    [StockQuantity]        DECIMAL (18, 4) NOT NULL,
    [SourceSystem]         NVARCHAR (20)   NOT NULL,
    [LoadId]               INT             NOT NULL,
    CONSTRAINT [PK_FactInventorySnapshot] PRIMARY KEY CLUSTERED ([InventorySnapshotKey] ASC),
    CONSTRAINT [UQ_FactInventorySnapshot_Grain] UNIQUE NONCLUSTERED ([SnapshotDate] ASC, [ProductKey] ASC, [StoreKey] ASC),
    CONSTRAINT [FK_FactInventorySnapshot_DimProduct] FOREIGN KEY ([ProductKey]) REFERENCES [dbo].[DimProduct] ([ProductKey]),
    CONSTRAINT [FK_FactInventorySnapshot_DimStore] FOREIGN KEY ([StoreKey]) REFERENCES [dbo].[DimStore] ([StoreKey]),
    CONSTRAINT [FK_FactInventorySnapshot_LoadLog] FOREIGN KEY ([LoadId]) REFERENCES [dbo].[LoadLog] ([LoadId])
);
GO

CREATE NONCLUSTERED INDEX [IX_FactInventorySnapshot_SnapshotDate]
    ON [dbo].[FactInventorySnapshot] ([SnapshotDate] ASC)
    INCLUDE ([ProductKey], [StoreKey], [StockQuantity]);
