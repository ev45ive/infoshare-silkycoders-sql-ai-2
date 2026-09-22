---
description: "Zasady prowadzenia analizy danych w hurtowni RetailDW: od pytania biznesowego, przez SQL, po weryfikację wyniku i podsumowanie. Wczytaj, gdy odpowiadasz na pytanie biznesowe, liczysz metrykę, porównujesz okresy albo przygotowujesz podsumowanie dla biznesu."
name: "Jak prowadzić analizę"
---
# Jak prowadzić analizę

## 1. Doprecyzuj pytanie

Zanim napiszesz jakikolwiek SQL, ustal:

- **okres** — od kiedy do kiedy,
- **zakres** — które sklepy, kanały, kategorie, produkty,
- **metrykę** — co dokładnie mierzymy,
- **jednostkę** — sztuki, złotówki, transakcje, procent,
- **punkt odniesienia** — z czym porównujemy.

Jeśli któregoś elementu brakuje w zgłoszeniu — zapytaj. Nie przyjmuj wartości
domyślnej po cichu.

## 2. Sprawdź definicję metryki

Definicje są w [docs/slownik-metryk.md](../../docs/slownik-metryk.md). Podawaj
źródło definicji, której użyłeś.

Jeśli napotkasz sprzeczne informacje na temat tej samej metryki — przedstaw obie
wersje ze wskazaniem źródła i poproś o rozstrzygnięcie. Nie wybieraj cicho
jednej z nich.

## 3. Ustal, skąd weźmiesz dane

Wypisz tabele i widoki, których użyjesz, oraz ziarno danych (jeden wiersz to
co?). Jeśli istnieje gotowy widok raportowy liczący to, o co pytamy — użyj go
albo świadomie uzasadnij, dlaczego liczysz inaczej.

## 4. Napisz i wykonaj zapytanie

Zawsze pokaż użyty SQL razem z wynikiem. Bez tego nikt nie odtworzy ani nie
zweryfikuje liczby.

## 5. Zweryfikuj wynik, zanim go przedstawisz

- Czy rząd wielkości ma sens na tle sąsiednich okresów?
- Czy da się policzyć tę samą wielkość drugą, niezależną drogą i czy wychodzi to
  samo?
- Czy dane pokrywają cały deklarowany zakres?

Jeśli coś odstaje od oczekiwań — wyjaśnij to, **zanim** zbudujesz na tym wniosek
biznesowy. Liczba, której nie umiesz obronić, nie nadaje się do wysłania.

## 6. Oddziel obserwację od przyczyny

„Sprzedaż spadła o 27%" to obserwacja. „Spadła, bo zabrakło towaru" to hipoteza.
Nazwij hipotezę hipotezą i pokaż dane, które ją wspierają.

## 7. Podsumuj dla biznesu

Liczba, kierunek zmiany, główny czynnik, zastrzeżenia. Krótko i bez żargonu
bazodanowego — odbiorca nie zna nazw tabel.
