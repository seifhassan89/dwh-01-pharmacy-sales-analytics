# Setup and run order

Use a disposable SQL Server for the synthetic dataset. The demo source creation script refuses an existing `OnlinePharmacyDB`. Never run integration tests on a real database.

1. `datasets/01_create_sample_source.sql` (on isolated demo instance only).
2. `scripts/01_schema.sql` through `scripts/07_run_pipeline.sql`, in numeric order.
3. `tests/quality_checks.sql`, `tests/reconciliation.sql`, and `tests/integration_tests.sql`.
4. Inspect `SELECT * FROM WeeklySalesPharmacyDWH.dbo.vw_WeeklyPharmacySales;`.

SQL integration execution is not verified in this delivery environment.
