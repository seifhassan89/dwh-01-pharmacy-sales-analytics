# Working agreement

- Keep requirements and grain intact: one pharmacy + Monday-week per fact row.
- Use numbered schema/procedure scripts and consistent `dbo` / `stg` qualifiers.
- Add a deterministic test for every change in business transformations.
- Never introduce confidential data, passwords, or operational source exports.
- Run staging validation, reconciliation and integration tests on a disposable instance before a pull request.
