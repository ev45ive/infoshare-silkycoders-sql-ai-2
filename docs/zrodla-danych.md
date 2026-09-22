# Źródła danych

Wszystkie systemy źródłowe wystawiają pliki raz na dobę. Pliki lądują w
schemacie `src` w postaci, w jakiej przyszły — bez żadnej walidacji.

| System | Co wystawia | Nazwa pliku | Tabela |
| --- | --- | --- | --- |
| POS (kasy w sklepach) | pozycje paragonów ze sklepów stacjonarnych | `POS_yyyymmdd.csv` | `src.SalesRaw` |
| Sklep internetowy | pozycje zamówień online | `WEB_yyyymmdd.csv` | `src.SalesRaw` |
| WMS (magazyn) | stany na koniec dnia, osobny plik na dzień | `WMS_yyyymmdd.csv` | `src.InventoryRaw` |
| Portal zwrotów | przyjęte zwroty | `RET_yyyymm.csv` | `src.ReturnsRaw` |

Kolumna `SourceFile` w każdej tabeli `src.*` mówi, z którego pliku pochodzi
wiersz. `ExtractedAt` to moment wczytania pliku do strefy lądowania.

## Jak działa ładowanie

Każda z procedur `etl.LoadSales`, `etl.LoadInventory`, `etl.LoadReturns`
wykonuje dokładnie dwa kroki:

1. `src.*` → `stg.*` — konwersja typów. Wiersz, którego nie da się przekonwertować
   (data, liczba), jest pomijany.
2. `stg.*` → `dbo.Fact*` — podpięcie kluczy wymiarów i wyliczenie miar.

To **pełne przeładowanie**: obie tabele docelowe są najpierw czyszczone, więc
hurtownia zawsze odzwierciedla bieżącą zawartość strefy lądowania.

Przebieg każdego ładowania jest zapisywany w `dbo.LoadLog` — nazwa procedury,
czas, status oraz liczba wierszy odczytanych i załadowanych.

## Czego nie ma w hurtowni

- Dostaw i przesunięć międzysklepowych — mamy tylko stan wynikowy w migawce.
- Danych klienta — sprzedaż nie jest powiązana z osobą kupującą.
- Ruchu na stronie i lejka e-commerce.
