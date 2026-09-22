---
name: poniedzialkowy-raport-handlowy
description: "Generuje cykliczny, jednostronicowy przegląd handlowy za ubiegły tydzień: sprzedaż netto, zmiana WoW/YoY, co urosło/spadło, porównanie kanałów. Użyj gdy: raport poniedziałkowy, przegląd tygodniowy, podsumowanie tygodnia, jak nam poszło w zeszłym tygodniu, co urosło co spadło."
argument-hint: "opcjonalnie: numer tygodnia ISO (np. 2026-W38), domyślnie ostatni pełny tydzień"
---

# Skill: poniedzialkowy-raport-handlowy

Generuje cotygodniowy przegląd handlowy dla dyrektora sprzedaży — jedna strona,
liczby + interpretacja, gotowe na poniedziałek 9:00.

## Kiedy się uruchamia

- Zgłoszenie/prośba o „raport poniedziałkowy", „przegląd tygodniowy", „jak nam
  poszło w zeszłym tygodniu"
- Cykliczne uruchomienie na potrzeby stałego podsumowania (patrz
  [zgloszenia/E06-raport-poniedzialkowy.md](../../../zgloszenia/E06-raport-poniedzialkowy.md))

## Czego NIE obejmuje

- Głębokiej analizy przyczyn anomalii (to robi `analityk-dyzurny`) — ten skill
  tylko sygnalizuje, co wymaga uwagi
- Raportów miesięcznych/marżowych (inne widoki, inny odbiorca)
- Modyfikacji obiektów w hurtowni — baza jest tylko do odczytu

## Procedura

### 1. Ustal tydzień raportowy

Domyślnie: ostatni **pełny** tydzień ISO. Jeśli dziś jest poniedziałek lub
wtorek, „bieżący" tydzień handlowy jeszcze się nie zamknął — bierz poprzedni.
Ta logika jest już zaszyta w skrypcie (sekcja `CALCULATE REPORTING WEEKS`).

Jeśli użytkownik podał konkretny tydzień (np. `2026-W38`) — użyj go zamiast
automatycznego wyliczenia.

### 2. Wykonaj zapytanie

Uruchom [scripts/generate-report.sql](./scripts/generate-report.sql) przez
`./scripts/dw.sh sql`:

```bash
./scripts/dw.sh sql "$(cat .github/skills/poniedzialkowy-raport-handlowy/scripts/generate-report.sql)"
```

Skrypt zwraca 5 sekcji: podsumowanie, zmiana WoW/YoY, top wzrosty, top spadki,
porównanie kanałów. Źródło danych: `reporting.vw_SalesWeekly` (metryka:
sprzedaż netto wg [docs/slownik-metryk.md](../../../docs/slownik-metryk.md)).

### 3. Wypełnij szablon

Przenieś wyniki do [assets/szablon-raportu.md](./assets/szablon-raportu.md).
Top wzrosty/spadki ogranicz do 3–5 pozycji — to jest wymóg z E06 („nie
tabele z dwudziestoma wierszami").

### 4. Dopisz Insights & Decyzje

To jedyna część, której SQL nie da wprost. Zaproponuj interpretację na
podstawie liczb (sezonowość, znane promocje, nietypowe odchylenia), ale
**oznacz to jako propozycję do weryfikacji przez człowieka** — szablon już
zawiera odpowiednie zastrzeżenie. Nie zgaduj przyczyn, których nie widać w
danych; jeśli coś wygląda na anomalię wymagającą wyjaśnienia, zasugeruj
uruchomienie `analityk-dyzurny`.

### 5. Sprawdź długość

Cały raport ma się mieścić na jednej stronie. Jeśli sekcja Insights robi się
długa — skracaj, nie dodawaj kolejnych tabel.

## Zakresy

**W zakresie:**
- Liczenie sprzedaży netto, zmian WoW/YoY, top ruchów kategorii/kanałów
- Wypełnienie gotowego szablonu jednostronicowego raportu

**Poza zakresem:**
- Ustalanie przyczyn anomalii (deleguj do `analityk-dyzurny`)
- Raporty inne niż tygodniowy przegląd sprzedaży (marża, zapasy, zwroty)
- Zmiany w obiektach bazy danych

## Obowiązujące instrukcje

Ten skill działa w ramach zasad z
[.github/instructions/analiza-danych.instructions.md](../../instructions/analiza-danych.instructions.md)
(definicje metryk, weryfikacja wyniku) oraz [AGENTS.md](../../../AGENTS.md)
(baza tylko do odczytu, zakresy poza hurtownią).
