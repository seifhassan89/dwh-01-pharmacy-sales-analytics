# SQL execution order

The folder numbers are the phases of the **Kimball + Staging** workflow. Run the source seed **only on a disposable SQL Server instance** where `OnlinePharmacyDB` does not exist.

1. *(Optional demo only)* `01_datasets/01_create_sample_source.sql`
2. `03_scripts/01_setup/01_create_database.sql`
3. `03_scripts/01_setup/02_create_staging_schema.sql`
4. `03_scripts/02_staging/01_create_staging_tables.sql`
5. `03_scripts/02_staging/02_load_source_snapshot.sql`
6. `03_scripts/03_quality/01_validate_source_snapshot.sql`
7. `03_scripts/04_warehouse/01_create_dimensions.sql`
8. `03_scripts/04_warehouse/02_create_weekly_fact.sql`
9. `03_scripts/04_warehouse/03_load_dim_date.sql`
10. `03_scripts/04_warehouse/04_load_dim_pharmacy.sql`
11. `03_scripts/04_warehouse/05_load_dim_order_status.sql`
12. `03_scripts/04_warehouse/06_load_fact_weekly_sales.sql`
13. `03_scripts/05_reporting/01_weekly_sales_view.sql`
14. `03_scripts/06_orchestration/01_create_pipeline.sql`
15. `03_scripts/06_orchestration/02_execute_pipeline.sql`

## Key distinctions

- `01_setup` creates database/schema; does not modify data on reruns.
- `02_staging` creates snapshot tables and a stored procedure to replace the snapshot.
- `03_quality` defines pre-load checks. Validation aborts on invalid data.
- `04_warehouse` defines the Kimball dimensions/fact and the load procedures.
- `05_reporting` defines the semantic view; it does not perform aggregation.
- `06_orchestration` defines and executes the ETL in a controlled sequence.
- `04_tests` is separate from deployment: run `quality_checks.sql`, `reconciliation.sql`, and (on demo source only) `integration_tests.sql`.

**Important:** The `CREATE OR ALTER PROCEDURE` scripts only *define* stored procedures; `06_orchestration/02_execute_pipeline.sql` runs them. Running a single load procedure independently might bypass preceding validation. The full snapshot is required because the fact loader removes stale weeks.
