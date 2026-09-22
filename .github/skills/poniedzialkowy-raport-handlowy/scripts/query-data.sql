-- ============================================================================
-- PONIEDZIAŁKOWY PRZEGLĄD HANDLOWY — dane surowe dla generate-report.js
-- Ten plik zwraca 6 recordsetów (bez PRINT/formatowania tekstowego) do
-- konsumpcji przez skrypt Node.js budujący PDF/Excel.
-- Logika wyboru tygodnia identyczna jak w generate-report.sql.
-- ============================================================================

DECLARE @CurrentWeek  NVARCHAR(10);
DECLARE @PreviousWeek NVARCHAR(10);
DECLARE @PreviousYearWeek NVARCHAR(10);

DECLARE @TodayDayOfWeek TINYINT;  -- ISO format: Monday=1
DECLARE @ReportWeekIsoYear SMALLINT;
DECLARE @ReportWeekIsoWeek TINYINT;

SELECT @TodayDayOfWeek = [DayOfWeek]
FROM [dbo].[DimDate]
WHERE [Date] = CAST(GETDATE() AS DATE);

IF @TodayDayOfWeek IN (1, 2)
BEGIN
    SELECT @ReportWeekIsoYear = [IsoYear],
           @ReportWeekIsoWeek = [IsoWeek] - 1
    FROM [dbo].[DimDate]
    WHERE [Date] = CAST(GETDATE() AS DATE);

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

-- RECORDSET 0: metadata o okresie
SELECT
    @CurrentWeek       AS [CurrentWeek],
    @PreviousWeek      AS [PreviousWeek],
    @PreviousYearWeek  AS [PreviousYearWeek],
    MIN([WeekStart])   AS [WeekStart],
    MAX([WeekEnd])     AS [WeekEnd]
FROM [reporting].[vw_SalesWeekly]
WHERE [YearWeek] = @CurrentWeek;

-- RECORDSET 1: podsumowanie wykonania (wartości surowe)
SELECT
    SUM([NetAmount])                                          AS [NetAmount],
    SUM([Transactions])                                       AS [Transactions],
    SUM([NetAmount]) / NULLIF(SUM([Transactions]), 0)         AS [AvgBasket]
FROM [reporting].[vw_SalesWeekly]
WHERE [YearWeek] = @CurrentWeek;

-- RECORDSET 2: zmiana WoW i YoY
WITH sales_by_week AS (
    SELECT [YearWeek], SUM([NetAmount]) AS [NetAmount]
    FROM [reporting].[vw_SalesWeekly]
    WHERE [YearWeek] IN (@CurrentWeek, @PreviousWeek, @PreviousYearWeek)
    GROUP BY [YearWeek]
)
SELECT
    'WoW' AS [Label],
    @PreviousWeek AS [ComparedTo],
    ROUND(100.0 * (
        (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @CurrentWeek) -
        (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousWeek)
    ) / NULLIF((SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousWeek), 0), 1) AS [PctChange]
UNION ALL
SELECT
    'YoY',
    @PreviousYearWeek,
    ROUND(100.0 * (
        (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @CurrentWeek) -
        (SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousYearWeek)
    ) / NULLIF((SELECT [NetAmount] FROM sales_by_week WHERE [YearWeek] = @PreviousYearWeek), 0), 1);

-- RECORDSET 3: top rosnące kategorie (Top 5, tylko realny wzrost)
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
    [Category],
    [Channel],
    ROUND(100.0 * ([CurrentWeek] - [PreviousWeek]) / NULLIF([PreviousWeek], 0), 1) AS [PctChange]
FROM category_changes
WHERE [PreviousWeek] > 0 AND [CurrentWeek] > [PreviousWeek]
ORDER BY [CurrentWeek] - [PreviousWeek] DESC;

-- RECORDSET 4: top spadające kategorie (Top 5, tylko realny spadek)
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
    [Category],
    [Channel],
    ROUND(100.0 * ([CurrentWeek] - [PreviousWeek]) / NULLIF([PreviousWeek], 0), 1) AS [PctChange]
FROM category_changes
WHERE [PreviousWeek] > 0 AND [CurrentWeek] < [PreviousWeek]
ORDER BY [CurrentWeek] - [PreviousWeek] ASC;

-- RECORDSET 5: porównanie kanałów
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
    [CurrentWeek]                                                                        AS [NetAmount],
    ROUND(100.0 * ([CurrentWeek] - [PreviousWeek]) / NULLIF([PreviousWeek], 0), 1)        AS [WowPct],
    ROUND(100.0 * ([CurrentWeek] - [PreviousYear]) / NULLIF([PreviousYear], 0), 1)        AS [YoyPct]
FROM channel_sales
ORDER BY [CurrentWeek] DESC;
