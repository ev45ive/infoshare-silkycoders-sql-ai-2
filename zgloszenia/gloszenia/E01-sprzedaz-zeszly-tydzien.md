**Od:** Marta Zielinska <m.zielinska@nordvik.pl>
**Do:** Zespol analiz
**Data:** wtorek, 22 wrzesnia 2026, 09:05
**Temat:** sprzedaz w zeszlym tygodniu

Czesc,

mam dzisiaj o 14:00 spotkanie z zarzadem i potrzebuje jednej liczby: *ile*
sprzedalismy w *zeszlym tygodniu*. Interesuje mnie rozbicie na *sklep internetowy*
i *sklepy stacjonarne* — zarzad pyta, czy online nam *rosnie*.

Dorzuc prosze porownanie z tygodniem wczesniej, zebym wiedziala, czy to byl
dobry czy slaby tydzien.

Dzieki,
Marta
Dyrektor Sprzedazy

 
# Doprecyzowanie zakresu analizy
- kategorie - online vs stacjonarne ✅
- sztuki czy pieniądze - **OBA** (jednostki i PLN) ✅
- kalendarzowy tydzien (pn-nd) - ISO-8601 W38 (Sep 14-20) ✅
- okres porównawczy - dynamika (WoW) z W37 ✅

---

# WYNIK ANALIZY

## Sprzedaż w zeszłym tygodniu (W38: Sep 14–20, 2026)

| Kanał | Sztuki | Sprzedaż netto PLN | vs W37 |
|-------|--------|-------------------|--------|
| Sklep internetowy | 1,012 | 148,893.07 | **+7.3%** ✅ wzrost |
| Sklepy stacjonarne | 3,575 | 515,858.96 | −6.7% |
| **RAZEM** | **4,587** | **664,752.03** | **−3.9%** |

## Wniosek
✅ **TAK, online rośnie.** Sprzedaż internetowa wzrosła o 7.3% wartościowo i 5.6% ilościowo. Kanały fizyczne spadły (−6.7%), więc dysproporcja jest wyraźna.

## Źródło
- Tabela: `dbo.FactSales`
- Metryka: sprzedaż netto = `NetAmount` ([slownik-metryk.md](../../docs/slownik-metryk.md))
- Okres: ISO tydzień 2026-W37 vs 2026-W38
- Dane: 2026-01-01 do 2026-09-20


# Kroki
- Model danych, fakty,wymiary
- Metryki - definicje
- Ziarno dla tabeli faktów
- Okres, kres porównawczy