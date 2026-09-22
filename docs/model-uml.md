# Model danych — Diagram UML

```mermaid
classDiagram
    class DimDate {
        int DateKey PK
        date Date
        int Year
        int Month
        int DayOfMonth
        int WeekOfYear
        string Season
    }
    
    class DimProduct {
        int ProductKey PK
        string SKU
        string StyleCode
        string StyleName
        string Department
        string Category
        string Color
        string Size
        decimal ListPrice
        decimal UnitCost
    }
    
    class DimStore {
        int StoreKey PK
        string StoreCode
        string StoreName
        string Channel
        decimal SalesAreaM2
        date RemodelDate
    }
    
    class FactSales {
        int SalesKey PK
        int DateKey FK
        int ProductKey FK
        int StoreKey FK
        string TransactionNo
        int Quantity
        decimal GrossAmount
        decimal TaxAmount
        decimal NetAmount
    }
    
    class FactInventoryDaily {
        int InventoryKey PK
        int DateKey FK
        int ProductKey FK
        int StoreKey FK
        int QuantityOnHand
        decimal ValuationAmount
    }
    
    class FactReturns {
        int ReturnKey PK
        int DateKey FK
        int ProductKey FK
        string TransactionNo
        int Quantity
        decimal ReturnAmount
    }
    
    class LoadLog {
        int LoadLogKey PK
        string ProcedureName
        datetime StartTime
        datetime EndTime
        string Status
        int RowsRead
        int RowsLoaded
        int RowsRejected
    }
    
    FactSales --> DimDate : "DateKey"
    FactSales --> DimProduct : "ProductKey"
    FactSales --> DimStore : "StoreKey"
    
    FactInventoryDaily --> DimDate : "DateKey"
    FactInventoryDaily --> DimProduct : "ProductKey"
    FactInventoryDaily --> DimStore : "StoreKey"
    
    FactReturns --> DimDate : "DateKey"
    FactReturns --> DimProduct : "ProductKey"
    FactReturns --|> FactSales : "TransactionNo"
```

## Wymiary

- **DimDate** — data, rok, miesiąc, tydzień ISO, sezon
- **DimProduct** — artykuł (SKU), model, dział, kategoria, rozmiar, kolor, cena, koszt
- **DimStore** — sklep, kanał (STORE/ONLINE), powierzchnia, data remontu

## Tabele faktów

- **FactSales** — jedna pozycja paragonu (ilość, kwota brutto/netto)
- **FactInventoryDaily** — stan na koniec dnia × SKU × sklep
- **FactReturns** — zwrócona pozycja, powiązana ze sprzedażą przez `TransactionNo`

## Audyt

- **LoadLog** — przebieg każdego ładowania (liczba wierszy, status, czas)

## Relacje

- Wszystkie fakty łączą się z wymiarami po kluczach surogatowych
- Zwroty powiązane ze sprzedażą przez `TransactionNo`
