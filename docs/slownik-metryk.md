# Słownik metryk

Definicje obowiązujące w raportowaniu Nordvik. Jeśli zapytanie liczy metrykę
inaczej niż opisano poniżej, to zapytanie wymaga wyjaśnienia — nie definicja.

## Sprzedaż

| Metryka | Definicja | Skąd |
| --- | --- | --- |
| **Sprzedaż brutto** | Wartość sprzedanego towaru z VAT, po odjęciu rabatu | `FactSales.GrossAmount` |
| **Rabat** | Kwota obniżki udzielonej na pozycji | `FactSales.DiscountAmount` |
| **Sprzedaż netto** | Sprzedaż brutto bez VAT. Stawka VAT na odzież wynosi 23%, czyli `brutto / 1,23` | `FactSales.NetAmount` |
| **Sztuki** | Liczba sprzedanych sztuk | `SUM(FactSales.Quantity)` |

Domyślną metryką sprzedaży w raportach zarządczych jest **sprzedaż netto**.
Sprzedaży brutto używamy tylko tam, gdzie wprost mowa o kwocie zapłaconej przez
klienta.

## Rentowność

| Metryka | Definicja |
| --- | --- |
| **Koszt własny (COGS)** | `SUM(Quantity × UnitCost)` |
| **Marża brutto** | Sprzedaż netto − koszt własny − wartość zwrotów za ten sam okres |
| **Marża %** | Marża brutto / sprzedaż netto |

Zwroty obniżają marżę okresu, w którym zostały przyjęte, a nie okresu pierwotnej
sprzedaży.

## Transakcje i koszyk

| Metryka | Definicja | Uwaga |
| --- | --- | --- |
| **Liczba transakcji** | `COUNT(DISTINCT TransactionNo)` | Jeden paragon to jedna transakcja, niezależnie od liczby pozycji |
| **Średni koszyk** | Sprzedaż netto / liczba transakcji | |
| **UPT** (units per transaction) | Sztuki / liczba transakcji | Typowo 2–4 |

`COUNT(*)` na tabeli faktów liczy **pozycje paragonu**, nie paragony. To dwie
różne liczby.

## Produktywność sklepu

| Metryka | Definicja | Uwaga |
| --- | --- | --- |
| **Przychód na m²** | Sprzedaż netto / powierzchnia sprzedaży | Dotyczy wyłącznie sklepów stacjonarnych. Sklep internetowy nie ma powierzchni i porównuje się go osobno |

`DimStore.SalesAreaM2` zawiera **bieżącą** powierzchnię. Jeśli sklep był
przebudowywany (`DimStore.RemodelDate`), porównanie przychodu na m² sprzed i po
przebudowie liczy obie strony według dzisiejszej powierzchni — przy takim
porównaniu trzeba to zaznaczyć.

## Zapas i dostępność

| Metryka | Definicja |
| --- | --- |
| **Stan magazynowy** | Liczba sztuk na koniec dnia handlowego dla SKU w sklepie |
| **Dostępność** | Udział SKU ze stanem > 0 w liczbie SKU objętych zapasem, liczony na dzień i sklep |
| **Sell-through** | Sztuki sprzedane w sezonie / (sztuki sprzedane w sezonie + stan na koniec okresu) |

Sell-through liczymy zawsze w obrębie jednego sezonu. Zestawienie sprzedaży z
kilku miesięcy ze stanem z jednego dnia daje wynik bez sensu.

## Zwroty

| Metryka | Definicja |
| --- | --- |
| **Wskaźnik zwrotów** | Sztuki zwrócone / sztuki sprzedane w tym samym okresie i przekroju |

Powody zwrotu: `DAMAGED`, `WRONG_SIZE`, `CHANGED_MIND`, `OTHER`.
Kanał internetowy ma strukturalnie wyższy wskaźnik zwrotów niż sklepy
stacjonarne — porównujemy kanały osobno, nie łącznie.

## Kalendarz

- **Tydzień handlowy** — ISO-8601, od poniedziałku do niedzieli. `DimDate.YearWeek`
  w formacie `2026-W38`.
- **Rok ISO** może różnić się od kalendarzowego na przełomie roku — do grupowania
  tygodni używaj `IsoYear` razem z `IsoWeek`, nigdy `Year` z `IsoWeek`.
- **Sezon** — `SS` (luty–lipiec) i `AW` (sierpień–styczeń), np. `AW26`.
