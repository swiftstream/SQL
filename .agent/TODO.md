# Future Ideas

This file is only for low-priority, maintainer-approved ideas that are neither active tasks, unresolved decisions, verified debt, nor completed history.

## Next authoring/DX follow-up after Declarative DDL

- Declarative DDL is now implemented, independently audited, and primary-accepted. The next queued SwifQL authoring/DX slice is focused research/planning for an additive SwiftUI-style declarative query authoring layer such as `SwifQL { Select(...); From(...); Where { ... } }`. Preserve the existing SwifQL engine/fluent APIs and SQL-first/operator-based predicate philosophy; runtime query builders may support result-builder control flow where semantically appropriate. This broader query-authoring slice is independent of SwiftDuckDB's now-unblocked declarative-migration work and is not active until the maintainer chooses to start it. Transient product-intent handoff: `.artifacts/planning/swifql-declarative-query-authoring-future-2026-09-18/SWIFQL_DECLARATIVE_QUERY_AUTHORING_IDEA_HANDOFF.md`.

## Dialect documentation follow-ups

- Run a dedicated PostgreSQL documentation/research mega-task to expand `architecture/dialects/POSTGRES.md` from live source/tests and current official PostgreSQL behavior, with explicit compatibility review before any behavior change.
- Run a dedicated MySQL documentation/research mega-task to expand `architecture/dialects/MYSQL.md` from live source/tests and current official MySQL behavior, with explicit compatibility review before any behavior change.