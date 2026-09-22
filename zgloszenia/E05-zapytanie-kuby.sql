/*
    Raport kanalowy - sierpien 2026
    Kuba Wrona, 22.09.2026

    Na czwartkowe spotkanie handlowe: porownanie sklepow stacjonarnych
    ze sklepem internetowym.
*/
SELECT  s.[Channel]                 AS [Kanal],
        COUNT(*)                    AS [Transakcje],
        SUM(s.[Units])              AS [Sztuki],
        SUM(s.[NetRevenue])         AS [Przychod],
        AVG(s.[AvgBasketValue])     AS [SredniKoszyk]
FROM    [reporting].[vw_StoreScorecard] AS s
WHERE   s.[YearMonth] = '2026-08'
GROUP BY s.[Channel]
ORDER BY [Przychod] DESC;
