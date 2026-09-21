/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Current-tier customer activity, based on sub-item purchase history.

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE VIEW [reporting].[vw_CustomerActivity]
AS
WITH [LastPurchase] AS
(
    SELECT  hist.[CustomerCode],
            MAX(fi.[SalesDate]) AS [LastPurchaseDate]
    FROM    [dbo].[FactSalesItem] AS fi
    JOIN    [dbo].[DimCustomer]   AS hist ON hist.[CustomerKey] = fi.[CustomerKey]
    WHERE   fi.[CustomerKey] IS NOT NULL
    GROUP BY hist.[CustomerCode]
),
[Reference] AS
(
    SELECT MAX([SalesDate]) AS [AsOfDate] FROM [dbo].[FactSalesItem]
)
SELECT  dc.[CustomerKey],
        dc.[CustomerCode],
        dc.[Name],
        dc.[Tier],
        lp.[LastPurchaseDate],
        CASE WHEN DATEDIFF(DAY, lp.[LastPurchaseDate], r.[AsOfDate]) <= 30 THEN 1 ELSE 0 END AS [IsActive]
FROM    [dbo].[DimCustomer] AS dc
JOIN    [LastPurchase]      AS lp ON lp.[CustomerCode] = dc.[CustomerCode]
CROSS JOIN [Reference]      AS r
WHERE   dc.[IsCurrent] = 1;
