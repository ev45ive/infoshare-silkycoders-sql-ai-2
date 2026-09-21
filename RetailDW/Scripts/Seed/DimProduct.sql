PRINT N'  seeding [dbo].[DimProduct]';

MERGE [dbo].[DimProduct] AS tgt
USING (VALUES
    (1,  N'P-1001', N'Espresso Beans 1kg',   N'Coffee',     0.2300, 40.0000, 1),
    (2,  N'P-1002', N'Filter Coffee 500g',   N'Coffee',     0.2300, 18.0000, 1),
    (3,  N'P-2001', N'Green Tea 100g',       N'Tea',        0.2300,  6.5000, 1),
    (4,  N'P-2002', N'Earl Grey 100g',       N'Tea',        0.2300,  7.5000, 1),
    (5,  N'P-3001', N'Ceramic Mug',          N'Accessories',0.2300,  9.0000, 1),
    (6,  N'P-3002', N'French Press 1L',      N'Accessories',0.2300, 55.0000, 1),
    (7,  N'P-4001', N'Oat Milk 1L',          N'Dairy',      0.0500,  3.2000, 1),
    (8,  N'P-4002', N'Whole Milk 1L',        N'Dairy',      0.0500,  2.5000, 1),
    (9,  N'P-5001', N'Chocolate Bar 90g',    N'Snacks',     0.2300,  1.8000, 1),
    (10, N'P-5002', N'Almond Cookies 200g',  N'Snacks',     0.2300,  4.0000, 0)
) AS src ([ProductKey], [ProductCode], [ProductName], [CategoryName], [VatRate], [UnitCost], [IsActive])
    ON tgt.[ProductKey] = src.[ProductKey]
WHEN MATCHED THEN UPDATE
    SET tgt.[ProductCode]  = src.[ProductCode],
        tgt.[ProductName]  = src.[ProductName],
        tgt.[CategoryName] = src.[CategoryName],
        tgt.[VatRate]      = src.[VatRate],
        tgt.[UnitCost]     = src.[UnitCost],
        tgt.[IsActive]     = src.[IsActive]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([ProductKey], [ProductCode], [ProductName], [CategoryName], [VatRate], [UnitCost], [IsActive])
    VALUES (src.[ProductKey], src.[ProductCode], src.[ProductName], src.[CategoryName], src.[VatRate], src.[UnitCost], src.[IsActive]);
