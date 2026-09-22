# Narzędzie 2 — Skill: `lineage-metryki`

Drugie narzędzie. Pierwsze odpowiadało na pytanie **„ile?"**. To odpowiada na
pytanie **„skąd się bierze ta liczba?"** — i jest tym, po które sięgasz, gdy
ktoś kwestionuje wynik.

Wbrew pozorom to nie jest ten sam skill co `analiza-zgloszenia`. Tam liczysz
coś od zera. Tu masz gotową liczbę i musisz rozebrać ją na części.

## Jak to zrobić

Wklej poniższy brief do `/create-skill`. Potem rozstrzygnij decyzje z sekcji na
dole.

---

Stwórz skill o nazwie `lineage-metryki`.

**Kiedy ma się uruchamiać:** gdy trzeba ustalić, skąd pochodzi konkretna liczba
w raporcie, albo dlaczego dwa źródła pokazują różne wartości tej samej metryki.

**Czego NIE obejmuje:** liczenia nowych metryk od zera, optymalizacji zapytań,
zmian w kodzie.

**Przebieg, który ma wymuszać:**

1. **Zakotwicz liczbę.** Zapisz dokładnie: która metryka, jaki obiekt ją
   zwraca, jakie filtry i jaki okres. Bez tego śledzisz nie to, co trzeba.
2. **Zbuduj łańcuch zależności w dół.** Od obiektu, który zwrócił liczbę, przez
   kolejne warstwy, aż do miejsca, w którym dane wchodzą do systemu. Wypisz
   nazwy obiektów, nie opisuj ogólnie.
3. **Policz tę samą wielkość na każdej warstwie łańcucha.** To jest sedno
   metody: schodzisz warstwa po warstwie i sprawdzasz, gdzie liczba jeszcze się
   zgadza, a gdzie już nie.
4. **Wskaż warstwę rozjazdu.** Miejsce, w którym wartość przestaje się zgadzać,
   wyznacza przyczynę. Nie zgaduj przyczyny wcześniej.
5. **Zawęź w obrębie tej warstwy.** Po jakim wymiarze rozkłada się różnica —
   czas, sklep, kanał, produkt? Zejdź do najmniejszego zakresu, który wyjaśnia
   całość różnicy.
6. **Opisz ustalenie**: gdzie jest przyczyna, jaka jest skala, co jest liczbą
   prawidłową i co trzeba zrobić, żeby to naprawić u źródła.

**Format wyniku:**

- **Diagram przepływu** (mermaid `flowchart LR`) z zaznaczoną warstwą rozjazdu.
- **Tabela kontrolna** — wartość metryki na każdej warstwie łańcucha.
- **Ustalenie** — przyczyna, skala, liczba prawidłowa.
- **Co dalej** — czy da się to obejść po stronie zapytania, czy wymaga poprawki
  u źródła.

---

## Do rozstrzygnięcia (odpowiedz sam)

1. **Jak głęboko schodzić?** Czy łańcuch kończy się na tabeli w hurtowni, czy
   masz iść aż do pliku źródłowego i systemu, który go wystawił?
2. **Co, jeśli rozjazd jest w obiekcie, którego nie wolno Ci zmienić?**
   Skill ma zaproponować obejście po stronie zapytania, zgłosić poprawkę
   zespołowi danych, czy jedno i drugie?
3. **Czy diagram ma być zawsze, czy tylko gdy łańcuch ma więcej niż dwa
   ogniwa?** Diagram dla dwóch obiektów to strata czasu — dla pięciu ratuje
   rozmowę z biznesem.

## Sprawdź, że działa

Uruchom skill na liczbie, którą już rozebrałeś ręcznie. Ma dojść do tej samej
warstwy rozjazdu — i narysować łańcuch, który możesz wkleić do maila zwrotnego
bez przepisywania.
