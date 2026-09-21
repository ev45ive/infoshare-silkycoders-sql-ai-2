/*
Sample sub-item staging batch #1 for RetailDW.

Contents (mirrors the order lines already staged in batch #1 for stg.Sales,
each split into exactly one sub-item):

  * 8 clean rows (SubItemNo = 1 for every order line) -> loaded
  * 1 unknown ProductCode                              -> rejected

Change log:
- 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
- 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Add CustomerCode (run after data/04-staging-customers-batch-1.sql + etl.LoadCustomers)
*/
SET NOCOUNT ON;

DELETE FROM [stg].[SalesItems];

INSERT INTO [stg].[SalesItems]
    ([SalesOrderNo], [SalesLineNo], [SubItemNo], [SalesDate], [ProductCode], [StoreCode], [CustomerCode],
     [Quantity], [UnitPrice], [DiscountAmount], [SourceSystem], [LoadedAt])
VALUES
    -- clean rows -------------------------------------------------------------
    (N'SO-2026-0001', 1, 1, '2026-01-05', N'P-1001', N'S-WAW-01', N'C-0001',  2.0000,  89.9900,  5.0000, N'POS', '2026-01-06T02:00:00'),
    (N'SO-2026-0001', 2, 1, '2026-01-05', N'P-3001', N'S-WAW-01', N'C-0001',  1.0000,  24.5000,  NULL,   N'POS', '2026-01-06T02:00:00'),
    (N'SO-2026-0002', 1, 1, '2026-01-05', N'P-2001', N'S-KRK-01', N'C-0002',  3.0000,  15.0000,  0.0000, N'POS', '2026-01-06T02:00:00'),
    (N'SO-2026-0003', 1, 1, '2026-01-06', N'P-4001', N'S-GDA-01', N'C-0003', 10.0000,   6.9900,  2.5000, N'POS', '2026-01-07T02:00:00'),
    (N'SO-2026-0003', 2, 1, '2026-01-06', N'P-5001', N'S-GDA-01', N'C-0003',  4.0000,   4.5000,  NULL,   N'POS', '2026-01-07T02:00:00'),
    (N'SO-2026-0004', 1, 1, '2026-01-07', N'P-1002', N'S-WRO-01', N'C-0004',  1.0000,  42.0000,  0.0000, N'POS', '2026-01-08T02:00:00'),
    (N'SO-2026-0005', 1, 1, '2026-01-07', N'P-3002', N'S-WAW-02', N'C-0005',  1.0000, 129.0000, 10.0000, N'POS', '2026-01-08T02:00:00'),
    (N'SO-2026-0006', 1, 1, '2026-02-02', N'P-2002', N'S-KRK-01', N'C-0001',  5.0000,  18.0000,  0.0000, N'POS', '2026-02-03T02:00:00'),

    -- rejected: product code not present in DimProduct -----------------------
    (N'SO-2026-0007', 1, 1, '2026-02-02', N'P-9999', N'S-KRK-01', N'C-0002',  1.0000,  10.0000,  0.0000, N'POS', '2026-02-03T02:00:00');

PRINT N'stg.SalesItems loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
SELECT [TotalStagedRows] = COUNT(*) FROM [stg].[SalesItems];
