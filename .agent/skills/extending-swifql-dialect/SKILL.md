---
name: extending-swifql-dialect
description: Add or change a built-in SQL dialect inside the canonical SQL repository/module using the research-first compatibility workflow. The skill package keeps its historical routing identifier.
---

# Extend a SQL Dialect

Use this research-first procedure when adding or changing a SQL dialect.

The cross-dialect architecture owner is [`DIALECT_RENDERING.md`](../../architecture/DIALECT_RENDERING.md). Always pair it with exactly the relevant dialect owner:

- Duck: [`dialects/DUCK.md`](../../architecture/dialects/DUCK.md)
- PostgreSQL: [`dialects/POSTGRES.md`](../../architecture/dialects/POSTGRES.md)
- MySQL: [`dialects/MYSQL.md`](../../architecture/dialects/MYSQL.md)

Treat that pair as one dialect architecture bundle for context-budget purposes.

1. Load the base dialect owner plus only the target dialect owner. Load [`DSL_DESIGN_AND_UX.md`](../../architecture/DSL_DESIGN_AND_UX.md) whenever public API/naming/UX is in scope. Load [`QUERY_PREPARATION.md`](../../architecture/QUERY_PREPARATION.md) only when preparation/value mechanics change. Use [`TESTING_RULES.md`](../../TESTING_RULES.md), [`STYLE_GUIDELINES.md`](../../STYLE_GUIDELINES.md), and [`SOURCE_MAP.md`](../../SOURCE_MAP.md) as needed.
2. Inspect live Git, source, tests, and the target dialect owner before proposing implementation.
3. Use existing source as local style evidence, not semantic authority. PostgreSQL is historically the richest local implementation, but do not copy its public naming quirks or SQL semantics into another dialect.
4. Before implementation, research current official database behavior and save/update a compatibility matrix in `.artifacts/**`.
5. The matrix covers identifiers, primitive values/string escaping, dates/time zones, binds, arrays/lists/nested values, JSON/key paths, casts/types, DML/DDL, operators/functions, native features, preparation limitations, and test/`SQLDialect.all` impact.
6. Do not infer compatibility from another database's syntactic similarity.
7. Preserve SQL transparency and dialect-transparent UX. A feature being supported by only one dialect does not automatically justify a database-prefixed public API. Prefer a clean SQL-shaped call site and let dialect-aware preparation own syntax differences where the modeled concept is the same.
8. If the existing parts pipeline lacks semantic context required for correct dialect rendering, improve the shared architecture rather than accumulating neighboring-token heuristics or forcing users into database wrappers.
9. Preserve established supported-dialect output byte-for-byte unless a separately approved bug fix changes it.
10. For Duck Swift naming, canonical public dialect syntax is `.duck` / `prepare(.duck)`. If a genuinely Duck-specific implementation prefix is needed, use `Duck...` / `duck...`, never new `DuckDB...` / `duckDB...` Swift prefixes. Human prose may say DuckDB and the internal id may remain `"duckdb"`.
11. Write a detailed implementation-ready `.artifacts` plan and independently audit it before code.
12. Decompose large implementation into sequential surgical tasks with explicit native-validation gates when renderer tests cannot prove parser/binder behavior.
13. After implementation/native audit passes, update only the target dialect owner with new verified facts. Do not duplicate those details in `DIALECT_RENDERING.md` or other dialect docs.

For PostgreSQL/MySQL, the current dialect owners are intentionally compact seeds until dedicated mega-audits expand them. Do not invent missing details for symmetry.
