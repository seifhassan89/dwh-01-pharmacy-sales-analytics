# Weekly Pharmacy Sales DWH — Project Board

**Business goal:** Aggregate sales for each pharmacy by creation week (Monday–Sunday), for orders currently Delivered.

**Architecture:** Source → Staging → Validation → Kimball Dimensions & Weekly Fact → Semantic View.

## Epics
1. Requirements & planning
2. Architecture & grain definition
3. Git initialization & naming standards
4. Source ingestion / staging
5. Validation & transformation
6. Kimball dimensional modeling & fact loading
7. Integration tests & financial reconciliation
8. Documentation and release

**Acceptance:** 1 row per Pharmacy/Week, correct revenue and distinct orders, idempotent reruns, canceled week cleanup, documented limitations.
