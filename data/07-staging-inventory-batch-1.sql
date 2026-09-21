/*
Sample inventory snapshot batch #1 for RetailDW.

Change log:
- 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
SET NOCOUNT ON;

DELETE FROM [stg].[InventorySnapshot];

INSERT INTO [stg].[InventorySnapshot]
    ([SnapshotDate], [ProductCode], [StoreCode], [StockQuantity], [SourceSystem])
VALUES
    ('2026-02-02', N'P-1001', N'S-WAW-01', 42.0000, N'WMS'),
    ('2026-02-02', N'P-1002', N'S-WRO-01', 15.0000, N'WMS'),
    ('2026-02-02', N'P-2001', N'S-KRK-01', 60.0000, N'WMS'),
    ('2026-02-02', N'P-3001', N'S-WAW-01',  8.0000, N'WMS'),
    ('2026-02-02', N'P-3002', N'S-WAW-02',  3.0000, N'WMS'),
    ('2026-02-02', N'P-4001', N'S-GDA-01',  0.0000, N'WMS'),
    ('2026-02-02', N'P-5001', N'S-GDA-01', 25.0000, N'WMS');

PRINT N'stg.InventorySnapshot loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
SELECT [TotalStagedRows] = COUNT(*) FROM [stg].[InventorySnapshot];
