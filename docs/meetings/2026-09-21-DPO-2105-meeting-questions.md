# DPO-2105 — Clarification report

**Ticket:** [exercises/tickets/DPO-2105.md](../../exercises/tickets/DPO-2105.md)
**Requester:** Piotr Nowicki (Zarząd — asystent)
**Date:** 2026-09-21

## Missing from ticket – checklist

- [ ] **Clear metric/question definition**: Ticket asks for "liczba aktywnych klientów" but doesn't specify which definition of "active" to use. Codebase has **conflicting definitions**:
  - [docs/customer-metrics.md](../customer-metrics.md#L3) — active = purchase in last **90 days**
  - [RetailDW/Views/reporting.vw_CustomerActivity.sql](../../RetailDW/Views/reporting.vw_CustomerActivity.sql#L30) — `IsActive` = last purchase within **30 days** of the max `SalesDate` in the data
- [ ] **Time period / as-of date**: Not specified. The existing view uses `MAX(SalesDate)` from `FactSalesItem` as the reference date, not the current calendar date — need to confirm whether "today" or "latest data date" should be used.
- [ ] **Scope**: Not specified — unclear if this means all customers, or filtered by region/tier/store.
- [ ] **Data source or expected report**: Ticket says "if it already exists in our reports, just use it" — but doesn't confirm which report/view is authoritative. `reporting.vw_CustomerActivity` exists but uses the 30-day rule, conflicting with the documented 90-day rule.
- [x] **Priority/deadline**: Present — needed by tomorrow morning for a board meeting.
- [ ] **Acceptance criteria**: Not specified — no way for the requester to validate the number once delivered.

## Open questions

1. Which "active customer" definition should be used for this report — the documented **90-day** rule ([docs/customer-metrics.md](../customer-metrics.md#L3)) or the **30-day** rule implemented in [reporting.vw_CustomerActivity.sql](../../RetailDW/Views/reporting.vw_CustomerActivity.sql#L30)? These currently disagree.
2. Should "as of" mean the actual current date, or the latest date present in the sales data (as the existing view does)?
3. Is any scope restriction needed (region, tier, store), or is this a single company-wide total?
4. Is `reporting.vw_CustomerActivity` the report management expects, or is this a new/ad-hoc number?
5. How should the requester validate the final number (e.g., compare against a specific dashboard, prior board report, or tolerance)?

## Sources checked

- [docs/customer-metrics.md](../customer-metrics.md): defines "active customer" as purchase within last 90 days — **conflicts** with the view implementation.
- [RetailDW/Views/reporting.vw_CustomerActivity.sql](../../RetailDW/Views/reporting.vw_CustomerActivity.sql): computes `IsActive` using a 30-day window from the max `SalesDate`, joined against current (`IsCurrent = 1`) `DimCustomer` rows.
- [docs/data-model.md](../data-model.md): overview of `DimCustomer`, `FactSales`, `FactSalesItem` — confirms `DimCustomer` carries full history with tier/region.
- [docs/reporting-notes.md](../reporting-notes.md): only documents the official monthly sales summary procedure; no mention of an "active customers" report for the board.
- [docs/glossary.md](../glossary.md): no definition of "active customer" present, only `Tier`, `SnapshotID`, etc.
- [RetailDW/Tables/dbo.DimCustomer.sql](../../RetailDW/Tables/dbo.DimCustomer.sql): confirms `IsCurrent` flag used to identify current customer version.
