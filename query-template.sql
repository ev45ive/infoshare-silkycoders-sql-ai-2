-- ============================================================================
-- ANALYTICAL QUERY TEMPLATE - Sales Analysis by Segment
-- ============================================================================
-- Use this template to generate similar SQL queries by replacing:
--   [METRIC_LABEL] - what you're measuring (e.g., Sales, Quantity, Cost)
--   [SEGMENT_LABEL] - how you're grouping (e.g., Category, Store, Customer)
--   [FactTable] - your transactional data source
--   [DimensionTable] - lookup table for readable labels
--   [SEGMENT_KEY] - the foreign key that links them
--   [METRIC_COLUMN] - the column being summed
-- ============================================================================

-- Example 1: SALES BY PRODUCT CATEGORY (Current Query)
-- ============================================================================
-- Need category labels and revenue totals to analyze sales performance by product type
SELECT 
    dp.[CategoryName],
    SUM(fs.[GrossAmount]) AS [TotalSalesValue],
    SUM(fs.[Quantity]) AS [TotalQuantitySold]
-- Join with product dimension because FactSales only stores ProductKey, not category names
FROM [RetailDW].[dbo].[FactSales] fs
JOIN [RetailDW].[dbo].[DimProduct] dp
    ON fs.[ProductKey] = dp.[ProductKey]
-- Aggregate by category to compare performance across product lines
GROUP BY dp.[CategoryName]
-- Show highest revenue categories first for quick identification of top performers
ORDER BY [TotalSalesValue] DESC;

-- ============================================================================
-- Example 2: SALES BY STORE (Template for Geographic Analysis)
-- ============================================================================
-- To use this: uncomment and execute
/*
SELECT 
    ds.[StoreName],
    SUM(fs.[GrossAmount]) AS [TotalSalesValue],
    SUM(fs.[Quantity]) AS [TotalQuantitySold],
    COUNT(DISTINCT fs.[SalesKey]) AS [TransactionCount]
FROM [RetailDW].[dbo].[FactSales] fs
JOIN [RetailDW].[dbo].[DimStore] ds
    ON fs.[StoreKey] = ds.[StoreKey]
GROUP BY ds.[StoreName]
ORDER BY [TotalSalesValue] DESC;
*/

-- ============================================================================
-- Example 3: RETURNS BY PRODUCT (Template for Quality Analysis)
-- ============================================================================
-- To use this: uncomment and execute
/*
SELECT 
    dp.[CategoryName],
    SUM(fr.[ReturnQuantity]) AS [TotalReturns],
    SUM(fr.[ReturnAmount]) AS [TotalReturnValue]
FROM [RetailDW].[dbo].[FactReturns] fr
JOIN [RetailDW].[dbo].[DimProduct] dp
    ON fr.[ProductKey] = dp.[ProductKey]
GROUP BY dp.[CategoryName]
ORDER BY [TotalReturns] DESC;
*/

-- ============================================================================
-- QUICK REFERENCE: Key Tables & Columns
-- ============================================================================
-- Fact Tables:
--   - FactSales: [SalesKey], [ProductKey], [StoreKey], [Quantity], [GrossAmount]
--   - FactReturns: [ReturnKey], [ProductKey], [ReturnQuantity], [ReturnAmount]
--   - FactInventorySnapshot: [InventorySnapshotKey], [ProductKey], [StoreKey], [Quantity]
--
-- Dimension Tables & Key Label Columns:
--   - DimProduct: [ProductKey], [CategoryName], [ProductName]
--   - DimStore: [StoreKey], [StoreName]
--   - DimCustomer: [CustomerKey], [CustomerName]
--
-- Adapt these examples by:
--   1. Change the SELECT columns (pick different metrics)
--   2. Change the FROM table (pick different fact source)
--   3. Change the JOIN table (pick different dimension)
--   4. Change the GROUP BY (different segmentation)
--   5. Update comments to explain the business purpose
-- ============================================================================
