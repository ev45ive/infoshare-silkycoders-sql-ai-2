# Model danych

Hurtownia `RetailDW` ma cztery warstwy. Dane płyną zawsze w jedną stronę.

```
src.*          →     stg.*        →      dbo.*          →   reporting.*
strefa            dane po              wymiary i            widoki
lądowania         konwersji            fakty                raportowe
```

| Schemat | Do czego służy |
| --- | --- |
| `src` | To, co przysłał system źródłowy — wszystkie kolumny tekstowe, nic nie jest sprawdzane |
| `stg` | Te same dane po konwersji na właściwe typy; wiersze nieprzekształcalne nie trafiają tutaj |
| `dbo` | Wymiary i tabele faktów — właściwa hurtownia |
| `reporting` | Widoki, z których korzysta biznes |
| `etl` | Procedury ładujące |

## Wymiary

**`dbo.DimProduct`** — jeden wiersz na SKU. W odzieży SKU to konkretny wariant
rozmiarowo-kolorystyczny modelu, np. `W-JKT-001-CZA-M`.

- `StyleCode` / `StyleName` — model, np. `W-JKT-001`, „Kurtka pikowana damska”
- `Department` — `WOMEN`, `MEN`, `UNISEX`
- `Category` — Kurtki, Sukienki, Swetry, Jeansy, T-shirty, Koszule, Akcesoria
- `Color`, `Size` — rozmiary `XS`–`XL`, akcesoria mają `ONE`
- `ListPrice` (cena katalogowa z VAT), `UnitCost` (koszt jednostkowy)

Analiza „po modelu” to grupowanie po `StyleCode`, „po produkcie” zwykle po `SKU`.

**`dbo.DimStore`** — pięć sklepów stacjonarnych i sklep internetowy.

- `Channel` — `STORE` albo `ONLINE`
- `SalesAreaM2` — powierzchnia sprzedaży, `NULL` dla sklepu internetowego
- `RemodelDate` — data ostatniej zmiany powierzchni

**`dbo.DimDate`** — kalendarz z tygodniem ISO, miesiącem i sezonem.

## Fakty

| Tabela | Ziarno | Uwaga |
| --- | --- | --- |
| `dbo.FactSales` | jedna pozycja paragonu | `TransactionNo` powtarza się w obrębie paragonu |
| `dbo.FactInventoryDaily` | dzień × SKU × sklep | **migawka** stanu na koniec dnia, nie log ruchów |
| `dbo.FactReturns` | jedna zwrócona pozycja | `ReturnAmount` dodatni, z VAT |

`FactInventoryDaily` obejmuje tylko bieżący sezon — dla wcześniejszych dat nie
ma wierszy, bo feed magazynowy nie sięga tak wstecz.

Różnica między dwoma kolejnymi stanami w `FactInventoryDaily` **nie jest**
sprzedażą — to różnica dwóch migawek, na którą wpływa też dostawa i przesunięcie
między sklepami.

## Złączenia

Wszystkie tabele faktów łączą się z wymiarami po kluczach surogatowych:

```sql
FROM        dbo.FactSales   AS f
JOIN        dbo.DimDate     AS d  ON d.DateKey    = f.DateKey
JOIN        dbo.DimProduct  AS p  ON p.ProductKey = f.ProductKey
JOIN        dbo.DimStore    AS st ON st.StoreKey  = f.StoreKey
```

`FactReturns` wiąże się ze sprzedażą przez `TransactionNo`. Uwaga: jedna
transakcja ma wiele pozycji, więc złączenie sprzedaży ze zwrotami po samym
`TransactionNo` zwielokrotni wiersze — trzeba dołożyć `ProductKey` albo najpierw
zagregować jedną ze stron.

## Audyt ładowania

`dbo.LoadLog` — jeden wiersz na uruchomienie procedury `etl.Load*`:
`RowsRead`, `RowsLoaded`, `RowsRejected`, `Status`.
