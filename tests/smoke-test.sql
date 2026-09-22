/*
RetailDW smoke test
-------------------
Confidence check that the deployed database is usable: the objects exist, the
sample data is loaded, and the reporting layer runs.

Fails loudly (RAISERROR severity 16) if any assertion is broken.

Run after:  ./scripts/dw.sh reset
*/
SET NOCOUNT ON;

DECLARE @Failures INT = 0;

-- ---------------------------------------------------------------------------
PRINT N'--- 1. objects exist -------------------------------------------------';

DECLARE @Expected TABLE ([ObjectName] SYSNAME NOT NULL);

INSERT INTO @Expected ([ObjectName])
VALUES (N'src.SalesRaw'), (N'src.InventoryRaw'), (N'src.ReturnsRaw'),
       (N'stg.Sales'), (N'stg.Inventory'), (N'stg.Returns'),
       (N'dbo.DimDate'), (N'dbo.DimProduct'), (N'dbo.DimStore'),
       (N'dbo.FactSales'), (N'dbo.FactInventoryDaily'), (N'dbo.FactReturns'),
       (N'dbo.LoadLog'),
       (N'etl.LoadSales'), (N'etl.LoadInventory'), (N'etl.LoadReturns'),
       (N'reporting.vw_SalesDaily'), (N'reporting.vw_SalesWeekly'),
       (N'reporting.vw_ProductPerformance'), (N'reporting.vw_MarginAnalysis'),
       (N'reporting.vw_StoreScorecard'), (N'reporting.vw_StockAvailability');

SELECT @Failures = @Failures + COUNT(*)
FROM   @Expected AS e
WHERE  OBJECT_ID(e.[ObjectName]) IS NULL;

SELECT N'MISSING OBJECT' AS [Problem], e.[ObjectName]
FROM   @Expected AS e
WHERE  OBJECT_ID(e.[ObjectName]) IS NULL;

-- ---------------------------------------------------------------------------
PRINT N'--- 2. dimensions are seeded -----------------------------------------';

IF (SELECT COUNT(*) FROM [dbo].[DimProduct]) <> 124
BEGIN PRINT N'FAIL: expected 124 rows in dbo.DimProduct'; SET @Failures += 1; END

IF (SELECT COUNT(*) FROM [dbo].[DimStore]) <> 6
BEGIN PRINT N'FAIL: expected 6 rows in dbo.DimStore'; SET @Failures += 1; END

IF (SELECT COUNT(*) FROM [dbo].[DimDate]) < 700
BEGIN PRINT N'FAIL: dbo.DimDate covers fewer than 700 days'; SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 3. facts are loaded ----------------------------------------------';

DECLARE @Sales INT = (SELECT COUNT(*) FROM [dbo].[FactSales]),
        @Stock INT = (SELECT COUNT(*) FROM [dbo].[FactInventoryDaily]),
        @Rets  INT = (SELECT COUNT(*) FROM [dbo].[FactReturns]);

PRINT N'  dbo.FactSales           : ' + CAST(@Sales AS NVARCHAR (10));
PRINT N'  dbo.FactInventoryDaily  : ' + CAST(@Stock AS NVARCHAR (10));
PRINT N'  dbo.FactReturns         : ' + CAST(@Rets  AS NVARCHAR (10));

IF @Sales < 150000 BEGIN PRINT N'FAIL: too few rows in dbo.FactSales';          SET @Failures += 1; END
IF @Stock < 70000  BEGIN PRINT N'FAIL: too few rows in dbo.FactInventoryDaily'; SET @Failures += 1; END
IF @Rets  < 8000   BEGIN PRINT N'FAIL: too few rows in dbo.FactReturns';        SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 4. every load finished successfully -------------------------------';

IF (SELECT COUNT(*) FROM [dbo].[LoadLog] WHERE [Status] = N'SUCCEEDED') < 3
BEGIN PRINT N'FAIL: expected three successful loads in dbo.LoadLog'; SET @Failures += 1; END

IF EXISTS (SELECT 1 FROM [dbo].[LoadLog] WHERE [Status] = N'FAILED')
BEGIN PRINT N'FAIL: dbo.LoadLog contains a failed load'; SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 5. measures are internally consistent ----------------------------';

IF EXISTS (SELECT 1 FROM [dbo].[FactSales]
           WHERE [GrossAmount] <> CAST([Quantity] * [UnitPrice] - [DiscountAmount] AS DECIMAL (12, 2)))
BEGIN PRINT N'FAIL: GrossAmount does not match Quantity * UnitPrice - DiscountAmount'; SET @Failures += 1; END

IF EXISTS (SELECT 1 FROM [dbo].[FactSales] WHERE ABS([NetAmount] * 1.23 - [GrossAmount]) > 0.02)
BEGIN PRINT N'FAIL: NetAmount is not GrossAmount excluding 23% VAT'; SET @Failures += 1; END

IF EXISTS (SELECT 1 FROM [dbo].[FactSales] WHERE [Quantity] <= 0 OR [UnitPrice] <= 0)
BEGIN PRINT N'FAIL: dbo.FactSales contains a non-positive quantity or price'; SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 6. every fact row resolves to its dimensions ----------------------';

IF EXISTS (SELECT 1 FROM [dbo].[FactSales] AS f
           LEFT JOIN [dbo].[DimProduct] AS p ON p.[ProductKey] = f.[ProductKey]
           WHERE p.[ProductKey] IS NULL)
BEGIN PRINT N'FAIL: dbo.FactSales has rows without a product'; SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 7. reporting layer is queryable ----------------------------------';

BEGIN TRY
    DECLARE @Sink INT;
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_SalesDaily];
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_SalesWeekly];
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_ProductPerformance];
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_MarginAnalysis];
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_StoreScorecard];
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_StockAvailability];
END TRY
BEGIN CATCH
    PRINT N'FAIL: reporting layer raised: ' + ERROR_MESSAGE();
    SET @Failures += 1;
END CATCH

-- ---------------------------------------------------------------------------
PRINT N'======================================================================';
IF @Failures = 0
    PRINT N'SMOKE TEST PASSED';
ELSE
BEGIN
    DECLARE @Msg NVARCHAR (200) = N'SMOKE TEST FAILED: ' + CAST(@Failures AS NVARCHAR (10)) + N' assertion(s).';
    RAISERROR (@Msg, 16, 1);
END
