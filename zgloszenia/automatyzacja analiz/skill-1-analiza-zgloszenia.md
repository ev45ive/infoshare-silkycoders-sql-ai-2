# Narzędzie 1 — Skill: `analiza-zgloszenia`

Pierwsze narzędzie, które zbudujesz. Do tej pory prowadziłeś analizę „z ręki" —
za każdym razem trochę inaczej. Skill zamienia to w powtarzalny przebieg z
jednym, stałym formatem wyniku.

## Jak to zrobić

Wklej poniższy brief do `/create-skill` i odpowiedz na pytania, które zada AI.
Potem rozstrzygnij trzy decyzje z sekcji niżej — to Twoje decyzje, nie AI.

---

Stwórz skill o nazwie `analiza-zgloszenia`.

**Kiedy ma się uruchamiać:** gdy dostaję od biznesu zgłoszenie z pytaniem, na
które trzeba odpowiedzieć liczbą policzoną z hurtowni.

**Czego NIE obejmuje:** recenzowania cudzego SQL, śledzenia pochodzenia liczby
w istniejącym raporcie, pisania kodu produkcyjnego.

**Zasady pracy:** obowiązują te z
`.github/instructions/analiza-danych.instructions.md` — skill ma je egzekwować,
a nie powtarzać ich treści.

**Przebieg, który ma wymuszać:**

1. Streść zgłoszenie własnymi słowami i wypisz, czego w nim brakuje.
2. Przedstaw plan analizy: jakie tabele i widoki, jakie ziarno, jaki okres,
   jaki punkt odniesienia.
3. Wykonaj zapytania. Pokaż SQL razem z wynikiem.
4. Zweryfikuj wynik i dopiero potem przedstaw wniosek.
5. Zbuduj notatkę w stałym formacie (patrz niżej).

**Format notatki końcowej:**

- **Odpowiedź** — jedna liczba lub jedno zdanie.
- **Jak policzone** — użyte tabele i widoki, definicja metryki ze wskazaniem
  źródła.
- **SQL** — pełne zapytanie.
- **Wynik** — tabela z liczbami.
- **Zastrzeżenia** — co może podważyć tę liczbę.

---

## Do rozstrzygnięcia (odpowiedz sam, zanim zatwierdzisz skill)

1. **Czy skill ma się zatrzymywać na punktach kontrolnych, czy lecieć do
   końca?** Zatrzymywanie kosztuje czas, ale łapie źle zrozumiane pytanie na
   początku, a nie na końcu.
2. **Co ma się stać, gdy zgłoszenie jest niejednoznaczne?** Dopytać i czekać,
   czy przyjąć założenie i wyraźnie oznaczyć je w notatce?
3. **Dla kogo jest notatka końcowa** — dla Ciebie do dalszej pracy, czy do
   przesłania wprost osobie zgłaszającej? To zmienia język i poziom
   szczegółowości.

## Sprawdź, że działa

Uruchom skill na zgłoszeniu, które właśnie rozwiązałeś ręcznie. Powinien dojść
do tej samej liczby — tylko szybciej i w stałym formacie. Jeśli doszedł do
innej, to ciekawszy wynik niż sukces: sprawdź dlaczego.
