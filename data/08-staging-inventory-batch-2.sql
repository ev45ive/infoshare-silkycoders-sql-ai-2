/*
Sample inventory snapshot batch #2 for RetailDW - only 3 of 5 stores reported
(run this after data/07-staging-inventory-batch-1.sql has already been loaded).

Change log:
- 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
SET NOCOUNT ON;

DELETE FROM [stg].[InventorySnapshot];

INSERT INTO [stg].[InventorySnapshot]
    ([SnapshotDate], [ProductCode], [StoreCode], [StockQuantity], [SourceSystem])
VALUES
    ('2026-02-09', N'P-1001', N'S-WAW-01', 38.0000, N'WMS'),
    ('2026-02-09', N'P-2001', N'S-KRK-01', 55.0000, N'WMS'),
    ('2026-02-09', N'P-3001', N'S-WAW-01',  7.0000, N'WMS');

PRINT N'stg.InventorySnapshot loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
SELECT [TotalStagedRows] = COUNT(*) FROM [stg].[InventorySnapshot];
