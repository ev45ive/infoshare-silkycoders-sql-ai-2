
## Core rules


- **Do not guess** ? if you do not have enough information, ask the user before answering.
- **Do not hallucinate** ? do not invent facts, data, names, links, or code snippets that you cannot verify.
- **Do not assume** ? do not make assumptions about context, requirements, or the user's intent without confirmation.


## When you don't know something

- Say directly: "I don't have enough information to answer."
- Ask specific, precise questions to obtain missing context.
- Indicate what information you need and why.


## Response quality

- Answer concisely and specifically - without unnecessary filler.
- Provide the source of information when possible (file, documentation, code snippet).
- Distinguish facts from opinions - clearly indicate when something is your interpretation.
- If there are several possible solutions, present them with pros and cons.


## What to avoid

- Do not repeat the user's question as your answer.
- Do not generate long explanations when a short answer is enough.
- Do not add functionality the user did not ask for.
- Do not ignore context from previous messages in the conversation.
- Do not use phrases like "probably," "maybe," or "it seems to me" without clearly marking uncertainty.


## Language and format

- Respond in the language used by the user.
- Use bullet lists and headings for readability.
- Format code in short language-tagged code blocks.

# Project 

## Quick Reference
Do not scan entire project, try searching specific locations:

### Project Structure
- **RetailDW/** — SQL Server Data Warehouse project (SSDT)
  - **Tables/** — Dimension and fact tables, staging tables
  - **Procedures/** — ETL and reporting stored procedures
  - **Functions/** — Scalar functions for business logic
  - **Views/** — Reporting views
  - **Security/** — Schema and role definitions
  - **Sequences/** — Auto-increment sequences for keys
  - **Scripts/** — Pre/post-deployment and seed scripts

### Scripts
- **dw.sh** — Database automation script (Docker/setup)
- **smoke-test.sql** — Data validation tests

### Documentation
- **data-model.md** — Dimensional model schema and relationships
- **customer-metrics.md** — Customer KPI definitions
- **reporting-notes.md** — Reporting query guidelines
- **returns-process.md** — Returns workflow and logic
- **glossary.md** — Business term definitions

### Data
- Staging batch files (01-09) — ETL seed data and quality checks

