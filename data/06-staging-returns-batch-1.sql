/*
Sample returns batch #1 for RetailDW.

Change log:
- 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
SET NOCOUNT ON;

DELETE FROM [stg].[Returns];

INSERT INTO [stg].[Returns]
    ([ReturnNo], [SalesOrderNo], [SalesLineNo], [ReturnDate], [ProductCode], [StoreCode],
     [Quantity], [ReturnAmount], [ReturnReason], [Status], [SourceSystem])
VALUES
    -- customer-initiated returns ---------------------------------------------
    (N'RET-2026-0001', N'SO-2026-0001', 1, '2026-01-10', N'P-1001', N'S-WAW-01', 1.0000,  84.9900, N'DAMAGED',    N'REFUNDED', N'POS'),
    (N'RET-2026-0002', N'SO-2026-0004', 1, '2026-01-20', N'P-1002', N'S-WRO-01', 1.0000,  42.0000, N'WRONG_ITEM', N'APPROVED', N'POS'),

    -- order adjustments --------------------
    (N'RET-2026-0003', N'SO-2026-0005', 1, '2026-02-15', N'P-3002', N'S-WAW-02', 1.0000, 119.0000, N'ORDER_ADJUSTMENT', N'REFUNDED', N'POS'),
    (N'RET-2026-0004', N'SO-2026-0002', 1, '2026-02-15', N'P-2001', N'S-KRK-01', 3.0000,  45.0000, N'ORDER_ADJUSTMENT', N'REFUNDED', N'POS');

PRINT N'stg.Returns loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
SELECT [TotalStagedRows] = COUNT(*) FROM [stg].[Returns];
