/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Sub-item level revenue, for order-line detail analysis.

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE VIEW [reporting].[vw_SalesItemRevenue]
AS
SELECT  fi.[SalesOrderNo],
        fi.[SalesLineNo],
        fi.[SubItemNo],
        fi.[SalesDate],
        p.[ProductName],
        st.[Region],
        fi.[Quantity],
        fi.[LineTotal],
        [dbo].[fn_NetRevenue](fi.[LineTotal], fi.[VatRate]) AS [NetRevenue]
FROM    [dbo].[FactSalesItem] AS fi
JOIN    [dbo].[DimProduct]    AS p  ON p.[ProductKey] = fi.[ProductKey]
JOIN    [dbo].[DimStore]      AS st ON st.[StoreKey]  = fi.[StoreKey];
