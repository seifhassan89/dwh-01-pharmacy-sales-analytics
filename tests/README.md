# SQL Test Suite

The tests are separated by **purpose and safety level**, similar to the SQL
script layout. Run them after the warehouse pipeline has finished.

| Order | Folder | Test file | Purpose | Safe on real data? |
| --- | --- | --- | --- | --- |
| 1 | `01_data_quality/` | `01_quality_checks.sql` | Validate keys, weekly grain, dates and staging values | Read-only |
| 2 | `02_reconciliation/` | `01_reconcile_weekly_sales.sql` | Compare staged weekly totals with the fact | Read-only |
| 3 | `03_integration/` | `01_integration_tests.sql` | Mutate synthetic orders and verify ETL behavior | **Demo instance only** |

## Run order

1. Deploy all SQL scripts documented in [`03_scripts/README.md`](../03_scripts/README.md).
2. On a **disposable instance only**, you may first create the sample source from `01_datasets/01_create_sample_source.sql`.
3. Run `03_scripts/06_orchestration/02_execute_pipeline.sql`.
4. Execute `01_data_quality/01_quality_checks.sql`.
5. Execute `02_reconciliation/01_reconcile_weekly_sales.sql`.
6. On the untouched sample baseline **only**, execute `03_integration/01_integration_tests.sql`.

## Reading a test file

Each script has a header explaining **purpose, prerequisites, and expected
result**. Subsections explain **why** each check exists, rather than narrating
every SQL keyword. A failed assertion uses `THROW`; success prints a `PASS`
message. No test should be marked *passed* before a real SQL Server execution.

## Important notes

- Integration tests intentionally change sample source rows **inside a transaction** and roll back those changes.
- The fact pipeline may create its own nested transaction; the outer test transaction keeps changes temporary.
- The source and DWH must reside on the same SQL Server instance.
- The integration suite has not been executed in this environment; validate on SQL Server before publishing test results.
