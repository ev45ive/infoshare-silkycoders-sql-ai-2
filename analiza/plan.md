# Plan: Sprzedaż w zeszłym tygodniu (E01-sprzedaz-zeszly-tydzien)

## Zadanie
Odpowiedź na zapytanie Marty Zielińskiej (termin: 14:00, 2026-09-22):
- Sprzedaż z tygodnia 14–20 września (ISO tydzień W38)
- Rozbicie na kanały: Online vs Sklepy stacjonarne
- Metryki: Przychód netto, Liczba sztuk, Liczba transakcji
- Porównanie z tygodniem poprzednim (W37) z wzrostem week-over-week (WoW %)
- Format: Krótkie podsumowanie dla zarządu (bez szczegółów sklepów)

## Potwierdzone założenia
✓ Metryka: Przychód netto (NetAmount) — standard per docs  
✓ Okres: ISO W38 (14–20 września) vs W37 (7–13 września)  
✓ Zakres: Podsumowanie kanałów (Online + Sklepy stacjonarne)  
✓ Szczegółowość: Dwa wiersze (Online, Sklepy) z porównaniem WoW  

## Źródła danych
- Głównie: `vw_SalesWeekly` (reporting.vw_SalesWeekly.sql)
- Fallback: Agregacja z `FactSales` + wymiary `DimDate`, `DimStore`

## Fazy implementacji

### Faza 1: Weryfikacja struktury widoku
- Sprawdzenie czy `vw_SalesWeekly` zawiera pole `NetAmount`
- Potwierdzenie dostępności kolumn: Units, TransactionNo

### Faza 2: Wykonanie głównego zapytania
- Query dla W37 i W38, pogrupowane po Channel
- Agregacja: NetAmount, Units, COUNT(DISTINCT TransactionNo)
- Oczekiwany wynik: 4 wiersze (2 tygodnie × 2 kanały)

### Faza 3: Weryfikacja wyników
Query 1: Trend sprzedaży netto za 8 tygodni (W31–W38)
Query 2: Liczba sklepów raportujących w W38 (powinno być 6)
Query 3: Kompletność dni w W38 (powinno być 7 dni)

### Faza 4: Obliczenie WoW i formatowanie
- WoW % = ((W38 - W37) / W37) × 100
- Tabela dla Marty: Channel | W37 Przychód | W38 Przychód | WoW % | itd.

### Faza 5: Dostarczenie
- Krótkie podsumowanie (1–2 akapity)
- Identyfikacja trendu (wzrost/spadek) online vs stacjonarne
- Gotowa do wysłania do Marty

## Pliki źródłowe
- `RetailDW/Views/reporting.vw_SalesWeekly.sql`
- `RetailDW/Tables/dbo.FactSales.sql`
- `RetailDW/Tables/dbo.DimStore.sql` (Channel)
- `RetailDW/Tables/dbo.DimDate.sql` (YearWeek)
- `docs/slownik-metryk.md` (definicje metryk)

## W zakresie
- Przychód netto, Units, Liczba transakcji za tygodnie W37–W38
- Rozbicie na kanały (Online vs Sklepy)
- Porównanie week-over-week z wzrostem %
- Narrative do zarządu

## Poza zakresem
- Szczegóły sklepów (nie dotyczy tego zgłoszenia)
- Kategorie produktów
- Analiza marż (nie dotyczy tego zgłoszenia)
- Trend historyczny (tylko 2 tygodnie)

## SQL Queries

### Query 1: Sprzedaż netto za 8 kolejnych tygodni (W31–W38)
```sql
-- Purpose: Show weekly net revenue trend over 8 weeks to detect if W38 is anomalous
-- This helps assess whether W38 sales are typical or unusually high/low

SELECT 
    dd.[YearWeek],
    st.[Channel],
    SUM(fs.[NetAmount]) AS TotalNetRevenue,
    SUM(fs.[Quantity]) AS TotalUnits,
    COUNT(DISTINCT fs.[TransactionNo]) AS TotalTransactions

FROM [RetailDW].[dbo].[FactSales] fs
INNER JOIN [RetailDW].[dbo].[DimDate] dd ON fs.[DateKey] = dd.[DateKey]
INNER JOIN [RetailDW].[dbo].[DimStore] st ON fs.[StoreKey] = st.[StoreKey]

WHERE dd.[YearWeek] IN ('2026-W31', '2026-W32', '2026-W33', '2026-W34', '2026-W35', '2026-W36', '2026-W37', '2026-W38')

GROUP BY dd.[YearWeek], st.[Channel]
ORDER BY dd.[YearWeek] ASC, st.[Channel];
```

### Query 2: Ile sklepów (wg Channel) raportowało w W38
```sql
-- Purpose: Verify all 6 stores (5 physical + 1 online) reported transactions in W38
-- If count < 6, some stores may be offline or have data lag

SELECT 
    st.[Channel],
    COUNT(DISTINCT st.[StoreKey]) AS StoreCount,
    STRING_AGG(st.[StoreName], ', ') AS StoreNames

FROM [RetailDW].[dbo].[FactSales] fs
INNER JOIN [RetailDW].[dbo].[DimDate] dd ON fs.[DateKey] = dd.[DateKey]
INNER JOIN [RetailDW].[dbo].[DimStore] st ON fs.[StoreKey] = st.[StoreKey]

WHERE dd.[YearWeek] = '2026-W38'

GROUP BY st.[Channel];
```

### Query 3: Czy W38 ma kompletne 7 dni danych
```sql
-- Purpose: Verify W38 contains all 7 days (Monday–Sunday per ISO-8601)
-- If < 7 days, the week is incomplete and revenue is artificially low

SELECT 
    dd.[YearWeek],
    COUNT(DISTINCT dd.[Date]) AS DayCount,
    MIN(dd.[Date]) AS WeekStart,
    MAX(dd.[Date]) AS WeekEnd,
    STRING_AGG(DISTINCT CAST(dd.[Date] AS VARCHAR(10)), ', ' ORDER BY CAST(dd.[Date] AS VARCHAR(10))) AS AllDates

FROM [RetailDW].[dbo].[FactSales] fs
INNER JOIN [RetailDW].[dbo].[DimDate] dd ON fs.[DateKey] = dd.[DateKey]

WHERE dd.[YearWeek] = '2026-W38'

GROUP BY dd.[YearWeek];
```

### Query 4: Główne zapytanie analityczne (W37 vs W38)
```sql
-- Purpose: Get total Net Revenue, Units Sold, and Transaction Count for weeks 37 and 38
-- Grouped by Channel (ONLINE vs STORE) to show Marta online vs physical performance
-- Uses YearWeek ISO standard (Mon–Sun) for consistent week boundaries

SELECT 
    [YearWeek],
    [Channel],
    SUM([NetAmount]) AS TotalNetRevenue,
    SUM([Units]) AS TotalUnits,
    COUNT(DISTINCT [TransactionNo]) AS TotalTransactions

FROM [RetailDW].[dbo].[FactSales] fs
INNER JOIN [RetailDW].[dbo].[DimDate] dd ON fs.[DateKey] = dd.[DateKey]
INNER JOIN [RetailDW].[dbo].[DimStore] st ON fs.[StoreKey] = st.[StoreKey]

WHERE dd.[YearWeek] IN ('2026-W37', '2026-W38')
  AND st.[Channel] IN ('ONLINE', 'STORE')

GROUP BY dd.[YearWeek], st.[Channel]
ORDER BY dd.[YearWeek] DESC, st.[Channel];
```

## Status
- [ ] Wykonanie Query 1 (trend 8 tygodni)
- [ ] Wykonanie Query 2 (weryfikacja sklepów)
- [ ] Wykonanie Query 3 (kompletność dni)
- [ ] Wykonanie Query 4 (główna analiza W37 vs W38)
- [ ] Analiza wyników i obliczenie WoW %
- [ ] Formatowanie raportu dla Marty
- [ ] Zatwierdzenie przez użytkownika
- [ ] Dostarczenie do Marty
