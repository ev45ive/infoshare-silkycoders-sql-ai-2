---
name: analiza-zgloszenia
description: "Analiza zgłoszenia biznesowego: od pytania (tzw. wrzutka), przez SQL, do wyniku i podsumowania. Skill wymusza powtarzalny przebieg z punktami kontrolnymi i stałym formatem wyjścia."
applyTo: "zgloszenia/**/*.md"
---

# Skill: analiza-zgloszenia

Skill do analizy zgłoszeń biznesowych w RetailDW. Bierze niejasne pytanie → zwraca liczbę + uzasadnienie.

## Kiedy się uruchamia

- Dostajesz zgłoszenie biznesowe z pytaniem, które trzeba odpowiedzieć liczbą z hurtowni
- Przykłady: „Ile sprzedaży w ostatnim tygodniu?", „Porównaj marżę w dwóch okresach", „Jaka jest dostępność towaru?"

## Czego NIE obejmuje

- Recenzowania cudzego SQL (to jest code review, nie analiza)
- Śledzenia pochodzenia liczby w istniejącym raporcie (to jest debug, nie analiza)
- Pisania kodu do bazy (procedury, widoki, tabele — to jest inżynieria danych)
- Raportowania biznesowego (twój wyjścia to surowiec, oddasz biznesowi — nie piszesz dla nich)

## Workflow — 5 Faz z Punktami Kontrolnymi

### Faza 1: Doprecyzowanie
**Cel**: Upewnić się, że rozumiesz pytanie, zanim zaczniesz SQL.

1. Przepisz zgłoszenie własnymi słowami
2. Wypisz, czego w nim brakuje:
   - **Okres** — od kiedy do kiedy?
   - **Zakres** — które sklepy, kanały, kategorie, produkty?
   - **Metryka** — co dokładnie mierzymy?
   - **Jednostka** — sztuki, złotówki, transakcje, procent, coś innego?
   - **Punkt odniesienia** — z czym porównujemy (niezdefiniowany, poprzedni okres, plan, średnia)?

3. **Jeśli coś brakuje**: Zapytaj, ale zasugeruj najrozsądniejszą domyślną wartość. Niech requester potwierdzi lub przesłoży.

4. **CHECKPOINT**: Pokaż propozycję doprecyzowania i czekaj na akceptację zanim pójdziesz dalej.

### Faza 2: Definicja Metryki
**Cel**: Znaleźć lub ustalić, co dokładnie mieirimy.

1. Sprawdź [docs/slownik-metryk.md](../../docs/slownik-metryk.md) — czy metryka tam jest?
2. Jeśli jest:
   - Użyj jej definicji
   - Podaj źródło (link do słownika)
3. Jeśli nie ma lub jest wieloznaczna:
   - Przedstaw obie/wszystkie interpretacje ze źródłami
   - Poproś o rozstrzygnięcie
   - NIE wybieraj cicho jedną

4. **CHECKPOINT**: Zatwierdź definicję przed przejściem do SQL.

### Faza 3: Plan Analizy
**Cel**: Zanim napiszesz SQL, wiedz, co liczysz i skąd.

1. Wypisz:
   - Które **tabele i widoki** będziesz używać
   - **Ziarno danych** — jeden wiersz to co? (jedna transakcja? jedna linia sprzedaży? jeden dzień?)
   - Jeśli istnieje widok raportowy liczący to, o co pytamy — czy go użyjesz, czy liczysz inaczej? Jeśli inaczej — uzasadnij.

2. Naszkicuj kształt wyniku: ile wierszy, jakie kolumny, czy będzie agregacja?

3. **CHECKPOINT**: Pokaż plan, czekaj na "OK" — dopiero wtedy piszesz SQL.

### Faza 4: Wykonanie & Weryfikacja
**Cel**: Policzyć liczbę i upewnić się, że ma sens — weryfikacja to osobne zapytanie, nie tylko "czy wygląda ok".

1. Napisz SQL zgodnie z formatem (patrz poniżej: SQL Style)
2. Wykonaj zapytanie główne
3. **Pokaż SQL razem z wynikiem** — bez tego nikt nie odtworzy liczby
4. **Wykonaj co najmniej jedno zapytanie weryfikujące** (osobne od głównego, nie tylko oglądanie tego samego wyniku):
   - **Kontekst trendu** — policz tę samą metrykę dla kilku sąsiednich okresów (np. 4–8 poprzednich tygodni/miesięcy) i sprawdź, czy wynik główny leży w rozsądnym zakresie względem historii, czy jest anomalią
   - **Niezależna ścieżka** — jeśli to możliwe, policz tę samą wielkość inną drogą (inny widok, inna agregacja, inny poziom ziarna) i porównaj — powinny zgadzać się co do rzędu wielkości
   - **Kompletność danych** — sprawdź `COUNT(*)`/`MIN(Date)`/`MAX(Date)` na danych źródłowych dla deklarowanego okresu, żeby wykluczyć brakujące dni/sklepy/kanały
5. **Pokaż wynik weryfikacji** razem z zapytaniem głównym — nie tylko konkluzję "sprawdzone"
6. Jeśli wynik weryfikacji odstaje od głównego (inny rząd wielkości, nieoczekiwana rozbieżność) — wyjaśnij to **zanim** zbudujesz wniosek biznesowy. Nie ukrywaj rozbieżności w Zastrzeżeniach — to blocker, nie footnote.

### Faza 5: Wyjście
**Cel**: Sformalizować wynik w format, który można powtórzyć i zweryfikować.

**Format notatki** (zapisz jako strukturę w markdown):

```
## Odpowiedź
[jedna liczba albo jedno zdanie pełne]

## Jak policzone
- **Tabele**: [lista tabel i widoków]
- **Metryka**: [nazwa ze wskazaniem źródła, np. "Sprzedaż (NetAmount wg docs/slownik-metryk.md)"]
- **Ziarno**: [co to jest jeden wiersz wyniku?]
- **Okres**: [od-do konkretne daty]
- **Zakres**: [sklepy, kanały, produkty — cokolwiek wąskie]

## SQL
[pełne zapytanie w bloku kodu SQL]

## Wynik
[tabela lub liczba z wynikiem]

## Weryfikacja
- **Metoda**: [kontekst trendu / niezależna ścieżka / kompletność danych — która z nich]
- **Zapytanie weryfikujące**: [SQL w bloku kodu]
- **Wynik weryfikacji**: [tabela/liczba]
- **Ocena**: [zgadza się z wynikiem głównym / odstaje — i jak to wyjaśniono]

## Zastrzeżenia
- [co mogłoby podważić tę liczbę?]
- [co jest wyłączone albo założone?]
- [czy jest okienko w danych?]
```

**Podsumowanie dla biznesu** (krótkie, do podzielenia się):
- Liczba, kierunek zmiany (jeśli porównanie)
- Główny czynnik (1 zdanie)
- Zastrzeżenie (jeśli ważne)
- Bez żargonu bazodanowego

---

## SQL Style

### Blok komentarza
```sql
/*
    Weekly sales by channel (Online vs Physical stores) for weeks 37–38, 2026.
    
    Metrics: Net Revenue (NetAmount), Units Sold, Transaction Count
    Grain: One row per week + channel combination
    Used for: Marta's executive summary, WoW comparison
*/
```

### Kolumny w nawiasach kwadratowych
```sql
SELECT  d.[Date]                            AS [SalesDate],
        st.[StoreCode]                      AS [Store],
        f.[NetAmount]                       AS [Revenue]
FROM    [dbo].[FactSales] AS f
  JOIN  [dbo].[DimDate] AS d ON d.[DateKey] = f.[DateKey]
  JOIN  [dbo].[DimStore] AS st ON st.[StoreKey] = f.[StoreKey]
WHERE   d.[YearWeek] IN ('2026-W37', '2026-W38')
```

---

## Zakresy

**W Zakresie:**
- Liczbowe odpowiedzi na pytania biznesowe
- Weryfikacja liczby drugą, niezależną drogą
- Wyjaśnianie, czemu liczba wyszła taka, a nie inna
- Dokumentowanie wyjścia w stałym formacie

**Poza Zakresem (NIGDY):**
- Produkowanie raportów dla biznesu (ty liczysz, oni je oformują)
- Produkcji widoków/procedur do bazy (to robota inżyniera danych)
- Recenzowanie czyjegoś SQL (code review to osobny skill)
- Śledzenie pochodzenia liczby w istniejących raportach (debug istniejącego, nie analiza nowego)

## Obowiązujące Instrukcje

Skill egzekwuje zasady z [`.github/instructions/analiza-danych.instructions.md`](.../instructions/analiza-danych.instructions.md) — nie powtarza ich treści, ale wymusza ich przestrzeganie w każdym kroku.

Dodatkowe reguły od [AGENTS.md](../../AGENTS.md) — zakresy poza hurtownią, kontekst Nordvik, niedostępne pliki.
