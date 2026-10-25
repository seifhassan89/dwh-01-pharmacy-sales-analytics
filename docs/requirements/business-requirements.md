# Business requirements

## Objective
Answer: **How much did each pharmacy sell during each Monday–Sunday week, and how many delivered orders contributed?**

## Scope and metric contract
- Source: `OnlinePharmacyDB.dbo.Orders`, `OrderItems`, `Pharmacies`, `OrderStateTypes`.
- An eligible order has **current** status `Delivered` and at least one valid OrderItem.
- Time basis: `Orders.CreatedOn` **creation week**, not the delivery completion date.
- Week: Monday 00:00 through next Monday 00:00 (end label is Sunday).
- Grain: `(WeekStartDateKey, PharmacyKey)` with exactly one row for each qualifying pharmacy-week.
- `TotalSales`: sum of item `Price * Quantity`, rounded to two decimals at the **weekly** level.
- `TotalOrders`: count of distinct eligible order IDs within a pharmacy-week.
- Reporting excludes `TestFlag = 1`; fact includes them for traceability.

## Not in scope
Delivery fees, separate taxes/discounts/refunds, FX normalization, slowly changing dimensions, delivered-at time, downstream dashboards, and CDC.

## Acceptance criteria
1. A multiple-item order counts once and all item amounts contribute.
2. Two pharmacies in one week are separate rows; separate weeks are separate rows.
3. Repeated load preserves counts and totals (idempotence).
4. Changes to price/status are reconciled, including removing empty historic weeks.
5. No duplicate or orphan pharmacy-week rows; week starts Monday.
6. Source-to-Gold reconciliation reports **zero** differences.
7. Same scripts run with synthetic demo data in a disposable SQL Server instance.

## Constraints
- Complete source tables required for full-snapshot refresh; do not run against partial feeds.
- SQL Server 2016 SP1+; `GO` batches require SSMS or `sqlcmd`.
- Source field names/types must match documented contracts; no confidential operational data is distributed.
