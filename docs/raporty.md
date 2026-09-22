# Raporty

Widoki w schemacie `reporting` to warstwa, z której korzysta biznes. Każdy
powstał pod konkretnego odbiorcę i pod konkretne pytanie.

| Widok | Ziarno | Kto używa |
| --- | --- | --- |
| `vw_SalesDaily` | dzień × sklep × kategoria | raport dzienny, baza pod agregacje własne |
| `vw_SalesWeekly` | tydzień ISO × kanał × region × kategoria | poniedziałkowy przegląd handlowy |
| `vw_ProductPerformance` | SKU | zakupy i merchandising — rotacja i sell-through |
| `vw_MarginAnalysis` | miesiąc × model | przegląd marżowy merchandisingu |
| `vw_StoreScorecard` | miesiąc × sklep | karta wyników dla kierowników sklepów |
| `vw_StockAvailability` | dzień × sklep × kategoria | kontrola dostępności towaru |

## Zasady korzystania

**Widok to nie definicja.** Widoki powstawały w różnym czasie i pod różne
potrzeby. Zanim użyjesz liczby z widoku w odpowiedzi dla biznesu, porównaj to,
co widok liczy, z [słownikiem metryk](slownik-metryk.md). Gdy się nie zgadza —
podaj obie wartości i wskaż źródło każdej z nich.

**Sprawdź przekrój, zanim zaufasz sumie.** Widok zaprojektowany pod jedno
pytanie nie musi odpowiadać na inne. Zanim użyjesz widoku do porównania
kanałów, regionów albo sklepów, sprawdź, czy rzeczywiście zwraca wszystkie
pozycje danego przekroju.

**Agregacja widoku po kolumnach spoza jego ziarna jest bezpieczna tylko dla
miar addytywnych.** Sztuki i kwoty można sumować. Liczby transakcji, średniego
koszyka, UPT, udziałów procentowych i sell-through — nie. Te trzeba przeliczyć
z tabeli faktów.

## Raporty cykliczne

- **Poniedziałkowy przegląd handlowy** — sprzedaż netto ubiegłego tygodnia,
  zmiana tydzień do tygodnia i rok do roku, najwięksi kontrybutorzy zmiany
  wzrostowej i spadkowej, komentarz do odchyleń. Odbiorca: dyrektor sprzedaży,
  poniedziałek rano.
- **Miesięczna karta wyników sklepów** — produktywność sklepów stacjonarnych.
  Odbiorca: kierownicy regionów.
- **Przegląd marżowy** — po zamknięciu miesiąca, razem z merchandisingiem.
