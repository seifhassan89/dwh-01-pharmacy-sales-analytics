# Weekly Pharmacy Sales Data Warehouse

**Data Engineering Portfolio — Project 01 | Kimball + Staging + SCD Type 1**

An end-to-end SQL Server dimensional warehouse that turns transactional pharmacy orders into weekly pharmacy sales. This independent educational project follows the *workflow and documentation deliverables* of Data warehouse concepts.

> **Fact grain:** One row per pharmacy per Monday-starting week. `TotalSales = SUM(Price × Quantity)` and `TotalOrders = COUNT(DISTINCT OrderId)` for orders **currently Delivered**, based on `Orders.CreatedOn` week, **not delivery date**.

## Business question
How much did each pharmacy sell per week, and how many delivered orders contributed?

## Architecture
**OnlinePharmacyDB → Staging (`stg`) → Validation → Kimball DWH (`dbo`) → Reporting View**

The DWH includes `DimDate`, `DimPharmacy`, `FactWeeklyPharmacySales`, and a `DimOrderStatus` ETL lookup. `DimOrderStatus` is **not** a foreign key in the fact. Sample business data is synthetic.

Open these **editable native draw.io drawings** using [diagrams.net](https://app.diagrams.net/):

- [Data architecture](docs/data_architecture.drawio)
- [Data flow](docs/data_flow.drawio)
- [Star schema ERD](docs/data_models.drawio)
- [ETL workflow](docs/etl.drawio)

## Project structure
```text
setup/       Installation and execution order
datasets/    Safe synthetic source data generator
docs/        Requirements, architecture, data catalog, mapping, 4 editable draw.io diagrams
  notion-import/  Notion-ready markdown and task database CSV
scripts/     01 Schema → 02 Staging → 03 Validation → 04 Dimensions → 05 Fact → 06 View → 07 Run
tests/       Quality checks, reconciliation, integration tests
```

## Getting started
1. Use a **disposable SQL Server instance** for demo data. Run `datasets/01_create_sample_source.sql`; it aborts if source DB already exists.
2. Execute `scripts/01_schema.sql`, then the remaining SQL files **in numeric order through `07_run_pipeline.sql`**.
3. Execute `tests/quality_checks.sql`, `tests/reconciliation.sql`, and `tests/integration_tests.sql` on the demo instance.
4. Query:
```sql
USE WeeklySalesPharmacyDWH;
GO
SELECT Pharmacy, WeekStart, WeekEnd, TotalOrders, TotalSales
FROM dbo.vw_WeeklyPharmacySales
ORDER BY WeekStart, Pharmacy;
```

**Demo target:** five fact rows, four visible reporting rows (test pharmacy hidden). Verify against SQL Server locally.

## ETL approach
- **Staging:** `stg.Pharmacies`, `stg.OrderStateTypes`, `stg.Orders`, `stg.OrderItems` hold a complete, replacement snapshot.
- **Validation:** stop on duplicate business keys, invalid quantities or prices, orphan item references, or unknown pharmacy/status.
- **Dimensional model:** `dbo.DimDate`, `dbo.DimPharmacy` (source-derived integer key) and lookup `dbo.DimOrderStatus`; weekly aggregated `FactWeeklyPharmacySales`.
- **SCD:** used SCD type 1 for a learning purpose as no full history needed at my task for training case.
- **Fact sync:** update changed pharmacy-weeks, insert new ones, remove stale ones. Serialized ETL uses a SQL application lock.
- **Reporting:** `dbo.vw_WeeklyPharmacySales` excludes test pharmacies.

## Metric and scope assumptions
- `TotalSales` excludes separate delivery fees, discounts, refunds and tax adjustments unless reflected in item price.
- Current Delivered status is applied at each ETL run; historical creation-week results may change.
- Orders with no items do not contribute; status is not modeled as an additional fact grain.
- Week Monday–Sunday; `DimDate` defaults to 2020–2030. No currency conversion.
- The pipeline requires a **complete** source snapshot, and is not safe for partial feeds; no incremental CDC.

## Quality and documentation
- [Business requirements](docs/requirements/business-requirements.md) and [project plan](docs/requirements/project-plan.md).
- [Architecture](docs/architecture/architecture.md), [Data dictionary](docs/data/data-dictionary.md), and [Source-to-target mapping](docs/data/source-to-target-mapping.md).
- [Naming conventions](docs/naming-conventions.md).
- [Notion import package](docs/notion-import/) (`project-overview.md` + `tasks.csv`). No remote Notion workspace was changed.
- [Data-quality tests](tests/quality_checks.sql), [reconciliation](tests/reconciliation.sql), [integration tests](tests/integration_tests.sql).

**Verification:** XML/packaging/file consistency checks performed. SQL Server execution has **not** been performed here. Run the demo end-to-end and record results before saying tests passed.

## Future improvements
CDC/incremental loads, scheduling, audit logs, source-consistent snapshot isolation, automated CI with SQL Server, and business-approved delivery-date revenue/adjustment rules.

## Attribution
This is an independent pharmacy business-case implementation using **Kimball + Staging**,.