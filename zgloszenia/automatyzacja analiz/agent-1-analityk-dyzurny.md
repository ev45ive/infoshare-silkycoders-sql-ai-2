# Narzędzie 3 — Agent: `analityk-dyzurny`

Pierwszy **agent**, nie skill. Zanim go zbudujesz, warto wiedzieć, po co w ogóle
rozróżniamy jedno od drugiego.

| | Skill | Agent |
| --- | --- | --- |
| Czym jest | **procedura** — „tak to robimy" | **stanowisko pracy** — „kto to robi i czego mu wolno" |
| Kiedy działa | wywołany w środku dowolnej rozmowy | prowadzi całą sesję od początku do końca |
| Narzędzia | te, które akurat są dostępne | **własny, ograniczony zestaw** |
| Typowe zadanie | jeden powtarzalny krok | wielokrokowe dochodzenie |
| Może używać skilli | — | **tak, i powinien** |

Do liczenia jednej metryki agent jest przerostem formy. Do pytania „dlaczego
to się zmieniło?" — nie, bo takie zadanie ma nieznaną z góry liczbę kroków i
trzeba w nim kontrolować, gdzie agent idzie.

## Jak to zrobić

Utwórz plik `.github/agents/analityk-dyzurny.agent.md`. Możesz poprosić AI,
żeby go napisał na podstawie briefu poniżej — ale **przeczytaj wynik**, zanim
go zapiszesz. To Ty odpowiadasz za to, co ten agent może zrobić.

---

Stwórz agenta o nazwie `analityk-dyzurny`.

**Do czego służy:** wyjaśnianie, **dlaczego** zmieniła się wartość metryki —
spadła sprzedaż, wzrosły zwroty, pogorszyła się marża. Nie do liczenia metryk
na zamówienie.

**Narzędzia:** tylko do odczytu — zapytania do bazy, czytanie plików,
wyszukiwanie. **Bez narzędzi do edycji plików i bez uruchamiania poleceń**,
które zmieniają stan czegokolwiek.

**Sposób pracy:**

1. Potwierdź, że zmiana w ogóle wystąpiła i jaka jest jej skala. Pokaż ją na
   tle kilku wcześniejszych okresów, żeby odróżnić zmianę od normalnego wahania.
2. Rozkładaj zmianę kolejno po dostępnych wymiarach. Po każdym rozkładzie
   sprawdź, czy różnica **koncentruje się** w wąskiej grupie, czy rozkłada się
   równomiernie. Idź dalej tam, gdzie się koncentruje.
3. Gdy zawęzisz do konkretnej grupy — zanim ogłosisz przyczynę, sprawdź, czy
   dane sprzedażowe w ogóle mogą ją wyjaśnić. Jeśli nie, poszukaj wyjaśnienia
   poza nimi.
4. Oddziel to, co widzisz w danych, od tego, co z tego wnioskujesz.
5. Zakończ rekomendacją: co konkretnie i kto ma z tym zrobić.

**Punkty kontrolne — zatrzymaj się i poczekaj na moją zgodę:**

- po przedstawieniu **planu** dochodzenia, przed pierwszym zapytaniem,
- po **pierwszym rozkładzie**, gdy proponujesz kierunek dalszego drążenia,
- przed sformułowaniem **wniosku o przyczynie**.

**Format podsumowania:** obserwacja (liczba i skala) → gdzie się koncentruje →
hipoteza przyczyny z dowodem → czego nie wiemy → rekomendacja.

---

## Do rozstrzygnięcia (odpowiedz sam)

1. **Ile punktów kontrolnych naprawdę chcesz?** Trzy dają kontrolę, ale
   spowalniają. Jeden na końcu jest szybki, ale wtedy dowiadujesz się o błędnym
   kierunku po fakcie. Jak to wygląda przy zgłoszeniu „na 14:00"?
2. **Skąd agent ma czerpać dane spoza sprzedaży?** Wypisz mu wprost, jakie
   obszary danych są w hurtowni dostępne — czy sam ma je odkryć?
3. **Czy agent ma prawo powiedzieć „nie wiem"?** Zadanie „wyjaśnij dlaczego"
   wywiera presję na znalezienie przyczyny za wszelką cenę. Co ma zrobić, gdy
   dane nie wystarczają?

## Sprawdź, że działa

Uruchom agenta na zgłoszeniu, które właśnie rozwiązałeś ręcznie. Obserwuj nie
tyle wynik, co **czy zatrzymuje się tam, gdzie kazałeś**. Agent, który
przelatuje przez punkty kontrolne, jest gorszy niż brak agenta — daje złudzenie
nadzoru.
