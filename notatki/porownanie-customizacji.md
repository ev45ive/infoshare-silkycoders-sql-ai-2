# Notatki

## Prompt, Instruction, Skill, Agent — Porównanie

| | **Co to jest** | **Metafora** | **Kiedy używać** | **Gdzie zapisać** | **Kiedy się uruchamia** |
|---|---|---|---|---|---|
| **Instructions** | Stałe wytyczne/zasady dotyczące pracy w projekcie lub z danym typem plików | Regulamin pracy / zasady BHP | Reguła dotyczy *większości* pracy w repo albo konkretnego typu plików | `.github/instructions/*.instructions.md` (workspace) lub profil użytkownika | Automatycznie: (a) gdy plik pasuje do `applyTo` (glob), (b) "on-demand" — agent sam ocenia trafność na podstawie `description`, (c) ręcznie przez "Add Context → Instructions" |
| **Prompt** | Gotowy szablon jednego konkretnego zadania z parametrami | Formularz zlecenia | Jedno, dobrze zdefiniowane zadanie, które chcesz odpalać wielokrotnie z różnym inputem | `.github/prompts/*.prompt.md` (workspace) lub profil użytkownika | Ręcznie: wpisujesz `/nazwa-promptu` w czacie, przez `Chat: Run Prompt...`, albo przycisk "play" w edytorze |
| **Skill** | Wielokrokowa procedura na żądanie, z załączonymi zasobami (skrypty, szablony, dokumenty referencyjne) | Instrukcja stanowiskowa (SOP) | Zadanie *specyficzne*, wymagające wielu kroków i/lub własnych plików pomocniczych | `.github/skills/<nazwa>/SKILL.md` (workspace) lub `~/.copilot/skills/<nazwa>/` (użytkownik) | Jak prompt (slash command `/`), ale też **automatycznie**, gdy model uzna zadanie za pasujące do `description` (chyba że `disable-model-invocation: true`) |
| **Custom Agent** | Osobna "persona" — model + zestaw narzędzi + własne instrukcje, do izolowanych/wieloetapowych zadań | Pracownik-specjalista | Potrzebujesz innej roli/ograniczonych narzędzi/izolowanego kontekstu | `.github/agents/*.agent.md` (workspace) lub profil użytkownika | Ręcznie z selektora agentów w czacie, albo jako subagent wywoływany przez inny agent na podstawie `description` |

### Kluczowa różnica praktyczna

- **Instructions** — nie "uruchamiasz" ich, one po prostu *obowiązują* (jak zasady), albo dołączają się same do kontekstu przy pasujących plikach.
- **Prompt** — świadomie *wywołujesz* jedno zadanie.
- **Skill** — jak prompt, ale rozbudowany o pliki pomocnicze i może się sam "domyślić", że jest potrzebny.
- **Agent** — zmienia *kto* wykonuje pracę (inny model/narzędzia/uprawnienia), a nie tylko *co* jest robione.
