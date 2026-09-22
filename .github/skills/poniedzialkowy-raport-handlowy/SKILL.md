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

### 2. Wykonaj zapytanie i przejrzyj dane

Uruchom [scripts/generate-report.sql](./scripts/generate-report.sql) przez
`./scripts/dw.sh sql`, żeby **zobaczyć** liczby przed generowaniem plików:

```bash
./scripts/dw.sh sql "$(cat .github/skills/poniedzialkowy-raport-handlowy/scripts/generate-report.sql)"
```

Skrypt zwraca 5 sekcji: podsumowanie, zmiana WoW/YoY, top wzrosty, top spadki,
porównanie kanałów. Źródło danych: `reporting.vw_SalesWeekly` (metryka:
sprzedaż netto wg [docs/slownik-metryk.md](../../../docs/slownik-metryk.md)).

To jest krok obowiązkowy — nie generuj PDF/Excela, zanim nie przejrzysz tych
liczb. Insights w kroku 3 muszą wynikać z realnie zobaczonych danych, nie z
zgadywania.

### 3. Napisz Insights & Decyzje

To jedyna część, której SQL nie da wprost. Na podstawie danych z kroku 2
zaproponuj 2–4 punkty interpretacji (sezonowość, znane promocje, nietypowe
odchylenia, co wymaga decyzji). Nie zgaduj przyczyn, których nie widać w
danych — jeśli coś wygląda na anomalię wymagającą głębszego wyjaśnienia,
zasugeruj uruchomienie `analityk-dyzurny` zamiast zmyślać powód.

Zapisz insighty jako plik JSON (dowolna ścieżka, np. `out/insights.json`):

```json
{ "insights": ["Swetry rosną +18% — początek sezonu jesiennego, zgodnie z ubiegłym rokiem.", "Kurtki (STORE) spadły -21,6% — sprawdzić dostępność, możliwy brak towaru."] }
```

### 4. Wygeneruj PDF i/lub Excel na żądanie

Pierwsze uruchomienie samo instaluje zależności (`npm install`), jeśli
brakuje `node_modules` w folderze `scripts/` — nie rób tego ręcznie.

```bash
cd .github/skills/poniedzialkowy-raport-handlowy/scripts
node generate-report.js --insights out/insights.json          # PDF + Excel (domyślnie)
node generate-report.js --pdf --insights out/insights.json    # tylko PDF
node generate-report.js --xlsx                                # tylko Excel, bez insightów
```

Pliki trafiają do `scripts/out/` (ignorowane przez git). PDF ma stylowane
tabele (nagłówek, naprzemienne wiersze, kolor zielony/czerwony dla zmian %) i
sekcję Insights wypełnioną z pliku JSON. Excel ma analogiczne formatowanie w
osobnych arkuszach + arkusz „Insights".

### 5. Sprawdź długość i treść

PDF ma się mieścić na jednej stronie. Jeśli sekcja Insights robi się długa —
skracaj, nie dodawaj kolejnych tabel. Zweryfikuj, że insighty w PDF/Excelu
faktycznie odpowiadają liczbom z kroku 2 (nie są ogólnikowe).

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
