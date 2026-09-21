---
name: sql-data-analysis-and-reports
description: 'Use when answering a business or analytics ticket with SQL against the RetailDW warehouse — building a hypothesis, confirming scope (tables, views, dimensions, granularity, metrics, filters), planning phased/sampled analysis, and producing a report with documented queries. Trigger phrases: "analyze sales/returns/inventory/customers", "answer this ticket", "build a report", "SQL analysis plan".'
argument-hint: 'Business question or ticket ID (e.g. DPO-2105)'
---

# SQL Data Analysis & Reports

Turns a business question or ticket into a verified SQL analysis plan, executed
queries, and a written report — without guessing at scope or metric definitions.

## When to Use
- A stakeholder ticket asks a business question that needs a SQL answer (counts, trends, summaries).
- User asks for a "report", "analysis", or "breakdown" over RetailDW data (sales, returns, inventory, customers).
- No existing reporting view/procedure already answers the question as-is.

## Procedure

### 1. Capture the business problem
If the user hasn't already stated it, ask for the business question or ticket.
Run it against the [ticket clarification checklist](../../instructions/ticket-clarification.instructions.md):
metric definition, time period, scope, data source, deadline, acceptance criteria.
Raise gaps as questions — do not assume a definition that isn't documented
(see root [AGENTS.md](../../../AGENTS.md) "Do not guess/hallucinate/assume" rules).

### 2. Draft a business hypothesis
Write 2-4 sentences stating what the report should show and why it answers the
business question, before touching SQL. This becomes the "Hypothesis" section
of the plan.

### 3. Identify tables, views, and dimensions
Look up candidates in `RetailDW/Tables`, `RetailDW/Views`, [data-model.md](../../../docs/data-model.md),
and [glossary.md](../../../docs/glossary.md). Check whether an existing view or
stored procedure already answers the question (e.g. `reporting.vw_*`,
`reporting.usp_*`) before planning new queries. If it's unclear which table/column
defines a term, ask the user rather than pick one.

### 4. Confirm analysis parameters
Use `vscode_askQuestions` in a single batch covering, with one recommended
default per question:
- **Granularity** — daily / weekly / monthly / overall
- **Metrics** — revenue, quantity, margin, counts, etc.
- **Dimensions** — product/category, store/region, customer/tier, date
- **Scope** — all data vs. a filtered subset (date range, entity exclusions)
- **Filters & sort** — how results should be filtered and ordered

### 5. Write the analysis plan to a file
Create `docs/analysis/<ticket-id>-plan.md` using the
[analysis plan template](./templates/analysis-plan-template.md). Include the
hypothesis, confirmed parameters, one planned query per phase, and the
verification checks for each phase.

### 6. Get plan sign-off
Ask the user to confirm the plan or request changes. Loop back to step 4/5 on
requested changes before running any query.

### 7. Track phases as todos
Use `manage_todo_list` with one todo per query/phase from the plan, marking
exactly one `in-progress` at a time.

### 8. Run phases, sampling large tables first
Execute phases in order. Before running a query against a table whose row
count exceeds **~100,000 rows**, first run it against a sample
(`TOP n` ordered by a stable key, or `TABLESAMPLE`) to validate logic and
catch errors cheaply. Tables under that threshold (true for all current
RetailDW fact tables) can be queried in full directly. After each phase,
verify row counts and null rates before moving to the next phase.

### 9. Produce the queries
Write final queries following the [SQL query style template](./templates/sql-query-style-template.sql)
(same convention as [query-template.sql](../../../query-template.sql)): a
header banner, and inline comments that explain *why* a clause exists
(business reason), never restating what the SQL already shows.

### 10. Write the report
Create `docs/analysis/<ticket-id>-report.md` using the
[report template](./templates/report-template.md): findings, data caveats
(e.g. missing keys, stale data, definition conflicts), the exact queries used,
and recommended next steps.

## Resources
- [Analysis plan template](./templates/analysis-plan-template.md)
- [SQL query style template](./templates/sql-query-style-template.sql)
- [Report template](./templates/report-template.md)
