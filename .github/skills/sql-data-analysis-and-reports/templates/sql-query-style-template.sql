-- ============================================================================
-- ANALYSIS QUERY: [SHORT TITLE] — Phase [N] of <ticket-id> analysis
-- ============================================================================
-- Business question this phase answers: [one line]
-- Source: docs/analysis/<ticket-id>-plan.md, Phase [N]
-- ============================================================================

-- [Why this data is needed for the business question, not what the SELECT does]
SELECT
    dp.[CategoryName],
    SUM(fs.[GrossAmount]) AS [TotalSalesValue]
-- Join with product dimension because the fact table only stores the key, not the label
FROM [dbo].[FactSales] fs
JOIN [dbo].[DimProduct] dp
    ON fs.[ProductKey] = dp.[ProductKey]
-- Filter reflects the confirmed scope from the plan (adjust to actual scope)
WHERE fs.[SalesDate] >= '2026-01-01'
GROUP BY dp.[CategoryName]
ORDER BY [TotalSalesValue] DESC;

-- ============================================================================
-- SAMPLING (only if source table exceeds ~100,000 rows)
-- ============================================================================
-- Validate logic cheaply before running against the full table
/*
SELECT TOP 1000
    dp.[CategoryName],
    fs.[GrossAmount]
FROM [dbo].[FactSales] fs
JOIN [dbo].[DimProduct] dp
    ON fs.[ProductKey] = dp.[ProductKey]
ORDER BY fs.[SalesKey];
*/

-- ============================================================================
-- VERIFICATION (run after the main query to sanity-check results)
-- ============================================================================
-- Row count should match plan's expectation; flag if 0 or unexpectedly high
/*
SELECT COUNT(*) AS [RowCount] FROM [dbo].[FactSales];
*/
