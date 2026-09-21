/*
Sample staging batch #2 for RetailDW - represents a later load window than
batch #1 (run this after data/01-staging-batch-1.sql has already been staged
and loaded via etl.LoadFactSales).

Contents:

  * 5 new clean rows for 2026-03  -> loaded
  * 1 correction to an order line already loaded from batch #1
    (SO-2026-0001 / line 1: quantity revised from 2.0000 to 3.0000)
  * 1 unknown ProductCode         -> rejected

Change log:
- 2026-09-20 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
SET NOCOUNT ON;

DELETE FROM [stg].[Sales];

INSERT INTO [stg].[Sales]
    ([SalesOrderNo], [SalesLineNo], [SalesDate], [ProductCode], [StoreCode],
     [Quantity], [UnitPrice], [DiscountAmount], [SnapshotID], [SourceSystem], [LoadedAt])
VALUES
    -- clean rows -------------------------------------------------------------
    (N'SO-2026-0010', 1, '2026-03-02', N'P-1002', N'S-WAW-01',  2.0000,  32.5000,  0.0000, 4, N'POS', '2026-03-03T02:00:00'),
    (N'SO-2026-0011', 1, '2026-03-02', N'P-2002', N'S-KRK-01',  1.0000,  19.9900,  0.0000, 4, N'POS', '2026-03-03T02:00:00'),
    (N'SO-2026-0012', 1, '2026-03-03', N'P-4002', N'S-GDA-01',  6.0000,   5.4900,  1.0000, 4, N'POS', '2026-03-04T02:00:00'),
    (N'SO-2026-0013', 1, '2026-03-03', N'P-5002', N'S-WRO-01',  3.0000,  11.0000,  0.0000, 4, N'POS', '2026-03-04T02:00:00'),
    (N'SO-2026-0014', 1, '2026-03-04', N'P-3001', N'S-WAW-02',  1.0000,  24.5000,  0.0000, 4, N'POS', '2026-03-05T02:00:00'),

    -- correction to an order line loaded from batch #1 -----------------------
    (N'SO-2026-0001', 1, '2026-01-05', N'P-1001', N'S-WAW-01',  3.0000,  89.9900,  5.0000, 4, N'POS', '2026-03-05T02:00:00'),

    -- rejected: product code not present in DimProduct -----------------------
    (N'SO-2026-0015', 1, '2026-03-04', N'P-8888', N'S-KRK-01',  1.0000,  10.0000,  0.0000, 4, N'POS', '2026-03-05T02:00:00');

PRINT N'stg.Sales loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
SELECT [TotalStagedRows] = COUNT(*) FROM [stg].[Sales];
