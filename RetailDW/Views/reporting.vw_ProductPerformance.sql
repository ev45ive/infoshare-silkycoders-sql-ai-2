/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Product-level revenue, cost and margin, net of returns.

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE VIEW [reporting].[vw_ProductPerformance]
AS
WITH [Sales] AS
(
    SELECT  fi.[ProductKey],
            SUM(fi.[LineTotal])                 AS [Revenue],
            SUM(fi.[Quantity] * p.[UnitCost])    AS [Cost]
    FROM    [dbo].[FactSalesItem] AS fi
    JOIN    [dbo].[DimProduct]    AS p ON p.[ProductKey] = fi.[ProductKey]
    GROUP BY fi.[ProductKey]
),
[Returns] AS
(
    SELECT  [ProductKey],
            SUM([ReturnAmount]) AS [ReturnAmount]
    FROM    [dbo].[FactReturns]
    GROUP BY [ProductKey]
)
SELECT  p.[ProductKey],
        p.[ProductName],
        p.[CategoryName],
        s.[Revenue],
        s.[Cost],
        ISNULL(r.[ReturnAmount], 0)                                       AS [ReturnAmount],
        s.[Revenue] - s.[Cost] - ISNULL(r.[ReturnAmount], 0)              AS [Margin]
FROM    [Sales]        AS s
JOIN    [dbo].[DimProduct] AS p ON p.[ProductKey] = s.[ProductKey]
LEFT JOIN [Returns]    AS r ON r.[ProductKey] = s.[ProductKey];
