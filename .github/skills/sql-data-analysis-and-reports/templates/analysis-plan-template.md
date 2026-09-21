# Analysis Plan: <Ticket ID / Business Question>

- **Date:** <YYYY-MM-DD>
- **Requester:** <name/role>
- **Ticket:** <link or ID, if any>

## Business Question
<Restate the question in one or two sentences.>

## Hypothesis
<2-4 sentences: what the report is expected to show and why it answers the
business question.>

## Confirmed Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| Granularity | <daily/weekly/monthly/overall> | |
| Metrics | <revenue/quantity/margin/counts/...> | |
| Dimensions | <product/category/store/region/customer/tier/date> | |
| Scope | <all data / filtered subset> | |
| Filters & sort | <filter conditions, sort order> | |

## Data Sources
| Table/View | Purpose | Notes |
|------------|---------|-------|
| <schema.table> | <why it's needed> | <caveats, e.g. missing FKs> |

## Planned Queries (by Phase)
### Phase 1: <name>
- **Goal:** <what this phase proves/produces>
- **Query outline:** <short description or pseudo-SQL>
- **Dependency:** <none / depends on Phase N>
- **Sampling needed?** <yes if source table > ~100k rows, else no>

### Phase 2: <name>
- **Goal:**
- **Query outline:**
- **Dependency:**
- **Sampling needed?**

<Add phases as needed.>

## Verification Checklist
- [ ] Each phase query runs without error
- [ ] Row counts match expectations (no unexpected 0s or duplicates)
- [ ] Null/FK gaps identified and explained
- [ ] Results reconcile across phases (e.g. subtotals sum to totals)

## Status
<Ready for review / Confirmed / In progress / Complete>
