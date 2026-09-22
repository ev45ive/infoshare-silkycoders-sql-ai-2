# Plan: Sales Last Week Analysis (E01-sprzedaz-zeszly-tydzien)

## Task
Answer Marta's meeting request (due 14:00 today, 2026-09-22):
- Sales from calendar week Sept 14–20, 2026 (ISO Week 38)
- Breakdown by channel: Online vs Physical stores
- Metrics: Net Revenue, Units Sold, Transaction Count
- Include comparison with prior week (Sept 7–13, ISO Week 37) with WoW % change
- Format: Simple summary for executive audience (no detailed store-by-store)

## Clarifications
✓ Metric definition: Net Revenue (standard per docs), Units Sold, Transaction Count
✓ Time period: ISO Week 38 (Sept 14–20) vs Week 37 (Sept 7–13)
✓ Scope: Online + Physical subtotals only (no store-level detail)
✓ Detail level: Two rows (Online, Physical) with YoY comparison

## Data Source
- Primary: `vw_SalesWeekly` view (reporting.vw_SalesWeekly.sql)
  - Grain: Weekly by `Channel`, `YearWeek`, aggregated metrics
  - Fields available: Units, Transactions (GrossAmount available, need to confirm NetAmount access)
  - *Note: Verify if vw_SalesWeekly exposes NetAmount or if we need to join FactSales*

## SQL Query Style
When writing SQL blocks for this analysis, follow these conventions:

**Block Comments** — `/* ... */` at top of query explaining business purpose and scope:
```sql
/*
    Weekly sales by channel (Online vs Physical stores) for weeks 37–38, 2026.
    
    Metrics: Net Revenue (NetAmount), Units Sold, Transaction Count
    Grain: One row per week + channel combination
    Used for: Marta's executive summary, WoW comparison
*/
SELECT ...
```

**Section Headers** — `--` before major query blocks:
```sql
-- Aggregate weekly sales by channel from FactSales
SELECT f.[DateKey], st.[Channel], ...
```

**Column Formatting** — Wrap all names in brackets: `[ColumnName]`, `[dbo].[TableName]`

**Avoid:** Line-by-line comments, restating SQL syntax, technical details (focus on *what* and *why*, not *how*)

## Implementation Steps

### Phase 1: Verify View Schema (Single Query)
1. Inspect `vw_SalesWeekly` structure to confirm available fields
   - Check if NetAmount is exposed (vs only GrossAmount)
   - Confirm Units and Transaction count columns
   - *If NetAmount missing:* Fall back to aggregating from FactSales directly

### Phase 2: Execute Analysis Query (Single Query)
2. Query weeks 37–38 for both channels
   - Filter: `YearWeek IN ('2026-W37', '2026-W38')` and `Channel IN ('ONLINE', 'STORE')`
   - Group by: `YearWeek`, `Channel`
   - Select: NetAmount, Units, TransactionCount (or COUNT(DISTINCT TransactionNo))
   - Order: `YearWeek DESC`, `Channel`

### Phase 3: Calculate WoW Growth
3. Post-query in SQL or manual calculation:
   - WoW % = ((W38 value - W37 value) / W37 value) × 100
   - Format for Marta: "↑ X%" or "↓ X%" with direction

### Phase 4: Format & Present
4. Create executive summary table:
   | Channel | W37 Revenue | W38 Revenue | WoW% | W37 Units | W38 Units | WoW% | W37 Txns | W38 Txns | WoW% |
   5. Provide brief narrative: trend direction (growth/decline) + online vs physical comparison
   6. *Optional:* Flag any unusual movements or notes for Marta's presentation

## Relevant Files
- `RetailDW/Views/reporting.vw_SalesWeekly.sql` — primary view (check structure first)
- `RetailDW/Tables/dbo.FactSales.sql` — fallback if view is insufficient
- `RetailDW/Tables/dbo.DimStore.sql` — Channel field definition
- `RetailDW/Tables/dbo.DimDate.sql` — YearWeek and IsoWeek logic
- `docs/slownik-metryk.md` — confirm metric definitions (especially NetAmount vs GrossAmount)

## Verification
1. ✓ Query returns exactly 4 rows (W37+W38, Online+Physical)
2. ✓ Revenue/Units/Txns values are positive and reasonable
3. ✓ WoW % calculations are correct (verify 1–2 cells manually)
4. ✓ Online and Physical are distinct channels (not mixed rows)
5. ✓ Present findings to user for approval before delivering to Marta

## Timeline
- Immediate: Run discovery queries (~2 min)
- Then: Execute main analysis query (~1 min)
- Then: Calculate WoW, format table (~2 min)
- Then: Deliver to user (~5 min)
- **Buffer:** ±30 min before 14:00 deadline

## Scope Boundaries
**In Scope:**
- Weekly Net Revenue, Units, Transaction counts
- Two-channel breakdown (Online vs Physical)
- Week-over-week comparison with % growth
- Simple executive summary narrative

**Out of Scope:**
- Store-by-store detail (excluded per Marta's simple request)
- Product/category breakdown (not requested)
- Margin/profitability analysis (not part of this ticket)
- Historical trend (only 2 weeks for comparison)
