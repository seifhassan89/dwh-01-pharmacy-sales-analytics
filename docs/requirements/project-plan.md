# Project plan and completion evidence

| Stage | Artifact | Gate |
|---|---|---|
| Requirements | `business-requirements.md` | Grain, week basis, scope, measures explicit |
| Architecture | `docs/architecture/*.md` | Keys, dependencies and flows documented |
| Initialization | README and numbered SQL scripts | Deterministic execution order |
| Staging | `01_schema.sql`, `02_staging.sql` | Extract complete tables to `stg` |
| Quality gate | `03_validate_staging.sql` | Bad values/keys fail closed |
| Dimensional modeling | `04_load_dimensions.sql`, `05_load_weekly_fact.sql` | Weekly fact and two dimensional FKs |
| Reporting | `06_reporting.sql` | View filters test pharmacies |
| Orchestration | `07_run_pipeline.sql` | Serial full-snapshot pipeline |
| Verification | tests folder | Quality + reconciliation + demo mutations |
| Handoff | README, mapping, dictionary | Clear limitations and reproducible commands |

The repository has not been connected or modified automatically. SQL Server runtime verification is required before a live release.
