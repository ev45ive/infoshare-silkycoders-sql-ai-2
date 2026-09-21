/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Product-level margin (revenue minus cost).

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE VIEW [reporting].[vw_MarginAnalysis]
AS
SELECT  p.[ProductKey],
        p.[ProductName],
        p.[CategoryName],
        SUM(fi.[LineTotal])              AS [Revenue],
        SUM(fi.[Quantity] * p.[UnitCost]) AS [Cost],
        SUM(fi.[LineTotal]) - SUM(fi.[Quantity] * p.[UnitCost]) AS [Margin]
FROM    [dbo].[FactSalesItem] AS fi
JOIN    [dbo].[DimProduct]    AS p ON p.[ProductKey] = fi.[ProductKey]
GROUP BY p.[ProductKey], p.[ProductName], p.[CategoryName];
