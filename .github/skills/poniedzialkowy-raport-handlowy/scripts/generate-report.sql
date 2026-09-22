-- ============================================================================
-- PONIEDZIAŁKOWY PRZEGLĄD HANDLOWY — AUTOMATYCZNE PODSUMOWANIE
-- Wykonanie: Co poniedziałek (lub wtorek) o 09:00
-- Logika: Raporty na dni 1-2 tygodnia (Pn-Wt) pokazują poprzedni pełny tydzień
-- ============================================================================

DECLARE @CurrentWeek  NVARCHAR(10);
DECLARE @PreviousWeek NVARCHAR(10);
DECLARE @PreviousYearWeek NVARCHAR(10);

-- ============================================================================
-- CALCULATE REPORTING WEEKS
-- ============================================================================

DECLARE @TodayDayOfWeek TINYINT;  -- ISO format: Monday=1
DECLARE @ReportWeekIsoYear SMALLINT;
DECLARE @ReportWeekIsoWeek TINYINT;

SELECT @TodayDayOfWeek = [DayOfWeek]
FROM [dbo].[DimDate]
WHERE [Date] = CAST(GETDATE() AS DATE);

-- If Monday (1) or Tuesday (2): report on previous complete week
-- Otherwise: report on current week
IF @TodayDayOfWeek IN (1, 2)
BEGIN
    SELECT @ReportWeekIsoYear = [IsoYear],
           @ReportWeekIsoWeek = [IsoWeek] - 1
    FROM [dbo].[DimDate]
    WHERE [Date] = CAST(GETDATE() AS DATE);
    
    -- Handle year boundary (week 0 -> week 52 of previous year)
    IF @ReportWeekIsoWeek = 0
    BEGIN
        SET @ReportWeekIsoYear = @ReportWeekIsoYear - 1;
        SET @ReportWeekIsoWeek = 52;
    END
END
ELSE
BEGIN
    SELECT @ReportWeekIsoYear = [IsoYear],
           @ReportWeekIsoWeek = [IsoWeek]
    FROM [dbo].[DimDate]
    WHERE [Date] = CAST(GETDATE() AS DATE);
END

SET @CurrentWeek = CONCAT(@ReportWeekIsoYear, '-W', RIGHT('0' + CAST(@ReportWeekIsoWeek AS VARCHAR(2)), 2));
SET @PreviousWeek = CONCAT(
    @ReportWeekIsoYear, '-W', 
    RIGHT('0' + CAST(CASE WHEN @ReportWeekIsoWeek = 1 THEN 52 ELSE @ReportWeekIsoWeek - 1 END AS VARCHAR(2)), 2)
);
SET @PreviousYearWeek = CONCAT(@ReportWeekIsoYear - 1, '-W', RIGHT('0' + CAST(@ReportWeekIsoWeek AS VARCHAR(2)), 2));

-- ============================================================================
-- SECTION 1: OVERALL SUMMARY
-- ============================================================================

PRINT '';
PRINT '================== PODSUMOWANIE WYKONANIA ==================';
PRINT 'Tydzień: ' + @CurrentWeek;

DECLARE @CurrentWeekStart DATE, @CurrentWeekEnd DATE;

SELECT @CurrentWeekStart = MIN([WeekStart]), @CurrentWeekEnd = MAX([WeekEnd])
FROM [reporting].[vw_SalesWeekly]
WHERE [YearWeek] = @CurrentWeek;

PRINT 'Okres: ' + FORMAT(@CurrentWeekStart, 'dd.MM.yyyy') + ' – ' + FORMAT(@CurrentWeekEnd, 'dd.MM.yyyy');
PRINT '';

SELECT 
    CONCAT('Sprzedaż netto: ', FORMAT(SUM([NetAmount]), 'N2'), ' PLN') AS [Wartość],
    CONCAT(SUM([Transactions]), ' transakcji') AS [Transakcje],
    CONCAT('Średni koszyk: ', FORMAT(SUM([NetAmount]) / NULLIF(SUM([Transactions]), 0), 'N2'), ' PLN') AS [Koszyk]
FROM [reporting].[vw_SalesWeekly]
WHERE [YearWeek] = @CurrentWeek;

-- ============================================================================
-- SECTION 2: WOW AND YOY CHANGES
-- ============================================================================

PRINT '';
PRINT '================== ZMIANA TYGODNIOWO I ROK DO ROKU ==================';

WITH sales_by_week AS (
    SELECT 
        [YearWeek],
        SUM([NetAmount]) AS [NetAmount]
    FROM [reporting].[vw_SalesWeekly]
    WHERE [YearWeek] IN (@CurrentWeek, @PreviousWeek, @PreviousYearWeek)
    GROUP BY [YearWeek]
)
SELECT
    'WOW (vs ' + @PreviousWeek + ')' AS [Porównanie],
    CONCAT(
        CAST(ROUND(100.0 * (
            (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @CurrentWeek) -
            (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousWeek)
        ) / NULLIF((SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousWeek), 0), 1) AS DECIMAL(10,1)),
        '%'
    ) AS [Zmiana]
UNION ALL
SELECT
    'YoY (vs ' + @PreviousYearWeek + ')',
    CONCAT(
        CAST(ROUND(100.0 * (
            (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @CurrentWeek) -
            (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousYearWeek)
        ) / NULLIF((SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousYearWeek), 0), 1) AS DECIMAL(10,1)),
        '%'
    )
FROM (SELECT 1 AS [x]) AS dummy;

-- ============================================================================
-- SECTION 3: TOP GROWING CATEGORIES (Top 5)
-- ============================================================================

PRINT '';
PRINT '================== CO UROSŁO (TOP 5) ==================';

WITH category_changes AS (
    SELECT 
        [Category],
        [Channel],
        SUM(CASE WHEN [YearWeek] = @CurrentWeek THEN [NetAmount] ELSE 0 END) AS [CurrentWeek],
        SUM(CASE WHEN [YearWeek] = @PreviousWeek THEN [NetAmount] ELSE 0 END) AS [PreviousWeek]
    FROM [reporting].[vw_SalesWeekly]
    WHERE [YearWeek] IN (@CurrentWeek, @PreviousWeek)
    GROUP BY [Category], [Channel]
)
SELECT TOP 5
    [Category] + ' (' + [Channel] + ')' AS [Kategoria],
    CONCAT(CAST(ROUND(100.0 * ([CurrentWeek] - [PreviousWeek]) / NULLIF([PreviousWeek], 0), 1) AS DECIMAL(10,1)), '%') AS [Wzrost]
FROM category_changes
WHERE [PreviousWeek] > 0 AND [CurrentWeek] > [PreviousWeek]
ORDER BY [CurrentWeek] - [PreviousWeek] DESC;

-- ============================================================================
-- SECTION 4: TOP DECLINING CATEGORIES (Top 5)
-- ============================================================================

PRINT '';
PRINT '================== CO SPADŁO (TOP 5) ==================';

WITH category_changes AS (
    SELECT 
        [Category],
        [Channel],
        SUM(CASE WHEN [YearWeek] = @CurrentWeek THEN [NetAmount] ELSE 0 END) AS [CurrentWeek],
        SUM(CASE WHEN [YearWeek] = @PreviousWeek THEN [NetAmount] ELSE 0 END) AS [PreviousWeek]
    FROM [reporting].[vw_SalesWeekly]
    WHERE [YearWeek] IN (@CurrentWeek, @PreviousWeek)
    GROUP BY [Category], [Channel]
)
SELECT TOP 5
    [Category] + ' (' + [Channel] + ')' AS [Kategoria],
    CONCAT(CAST(ROUND(100.0 * ([CurrentWeek] - [PreviousWeek]) / NULLIF([PreviousWeek], 0), 1) AS DECIMAL(10,1)), '%') AS [Spadek]
FROM category_changes
WHERE [PreviousWeek] > 0 AND [CurrentWeek] < [PreviousWeek]
ORDER BY [CurrentWeek] - [PreviousWeek] ASC;

-- ============================================================================
-- SECTION 5: CHANNEL COMPARISON
-- ============================================================================

PRINT '';
PRINT '================== PORÓWNANIE KANAŁÓW ==================';

WITH channel_sales AS (
    SELECT 
        [Channel],
        SUM(CASE WHEN [YearWeek] = @CurrentWeek THEN [NetAmount] ELSE 0 END) AS [CurrentWeek],
        SUM(CASE WHEN [YearWeek] = @PreviousWeek THEN [NetAmount] ELSE 0 END) AS [PreviousWeek],
        SUM(CASE WHEN [YearWeek] = @PreviousYearWeek THEN [NetAmount] ELSE 0 END) AS [PreviousYear]
    FROM [reporting].[vw_SalesWeekly]
    WHERE [YearWeek] IN (@CurrentWeek, @PreviousWeek, @PreviousYearWeek)
    GROUP BY [Channel]
)
SELECT 
    [Channel],
    FORMAT([CurrentWeek], 'N0') + ' PLN' AS [Sprzedaż],
    CONCAT(CAST(ROUND(100.0 * ([CurrentWeek] - [PreviousWeek]) / NULLIF([PreviousWeek], 0), 1) AS DECIMAL(10,1)), '%') AS [WOW],
    CONCAT(CAST(ROUND(100.0 * ([CurrentWeek] - [PreviousYear]) / NULLIF([PreviousYear], 0), 1) AS DECIMAL(10,1)), '%') AS [YOY]
FROM channel_sales
ORDER BY [CurrentWeek] DESC;

PRINT '';
PRINT 'Raport wygenerowany: ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
