# analiza-zgloszenia — Skill

Skill do analizy zgłoszeń biznesowych w RetailDW. Konwertuje pytanie biznesowe → SQL → verificiną liczbę w stałym formacie.

## Jak to sprawdzić

### Opcja A: Testuj na istniejącym zgłoszeniu
Otwórz plik zgłoszenia (np. `zgloszenia/E01-sprzedaz-zeszly-tydzien.md`) i uruchom `/analyze` lub pozwól skillowi się załadować automatycznie.

Skill powinien zatrzymać się na **Fazie 1** (doprecyzowanie) i poprosić o zatwierdzenie zanim pójdzie dalej.

### Opcja B: Nowe zgłoszenie
Stwórz plik `zgloszenia/test-submission.md` z pytaniem biznesowym, a skill się uruchomi automatycznie.

## Czego oczekiwać

| Faza | Co się stanie | Gdzie czeka |
|------|---------------|-----------|
| **1. Doprecyzowanie** | Skill przeformułuje pytanie i poda, czego brakuje | Czeka na `OK` przed przejściem |
| **2. Definicja Metryki** | Sprawdzi `docs/slownik-metryk.md` i zatwierdzi, co liczysz | Czeka na zatwierdzenie definicji |
| **3. Plan Analizy** | Wypisze tabele, widoki, ziarno danych | Czeka na `OK` planu |
| **4. Wykonanie** | Napiszę SQL, wykonam, zweryfikuję wynik | Bez checkpointu — leci do końca |
| **5. Wyjście** | Sformatuje wynik + krótkie podsumowanie dla biznesu | Gotowe do podzielenia się |

## Decyzje projektowe

Skill został skonfigurowany z tymi priorytetami:

1. **Checkpoints** ✅ — Zatrzymuje się **przed** SQL, żeby przechwycić błędy zrozumienia wcześnie
2. **Ambiguity** ✅ — Pyta o brakujące informacje, ale zasugeruje rozsądną domyślę
3. **Audience** ✅ — Wynik ma dwie części:
   - **Wewnętrzną** (tabele, SQL, caveats) — do weryfikacji i dokumentacji
   - **Biznesową** (liczba + uzasadnienie) — gotową do wysłania do requestra

## Następne kroki

- [ ] Test na E01 (powinien dać ten sam wynik co ręczna analiza)
- [ ] Ewentualne dopracowanie checkpointów (jeśli są zbyt inwazyjne)
- [ ] Dodanie powiązanych skills (np. `trend-analysis`, `benchmark`)
