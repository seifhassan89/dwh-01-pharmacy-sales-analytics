# Naming conventions

- `stg.*`: source snapshots (temporary, full replacement).
- `dbo.Dim*`: analytical dimensions; `dbo.Fact*`: analytical facts.
- `dbo.vw_*`: reporting views.
- `usp_Load_*`: load procedures; scripts prefixed with execution order `01_..07_`.
- Dimension `PharmacyKey` is an integer source-derived key; `PharmacyBisKey` is the source business identifier.
- Fact grain is one pharmacy × one Monday week; no item or order id in fact.
