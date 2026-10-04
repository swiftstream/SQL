# Builders and QueryParts Architecture

This file is the sole owner of `BUILD-*` rules.

## Verified current model

Builders are ergonomic state and composition helpers that return normal `SQLable` output. `QueryParts` currently stores `joins`, `wheres`, `groupBy`, `havings`, `orderBy`, `offset`, and `limit`. Its `buildQuery()` materializes those shared clauses in the current order: joins, where clauses, grouping, having clauses, ordering, limit, then offset. `appended(to:)` adds the materialized parts to an existing `SQLable`.

`SQLSelectBuilder` stores select and from state itself, keeps shared clause state in `queryParts`, and uses `queryParts.appended(to:)` when building. The result re-enters the normal `SQLable` preparation path. Not every future builder field is automatically a `QueryParts` concern.

Dialect-specific statement builders follow the same model: feature-specific state stays in its dedicated builder type, while shared clause state remains owned by `QueryParts` and final output re-enters normal preparation.

## Rules

### BUILD-001 — Composition layer

Builders are composition and state helpers, not SQL renderers.

### BUILD-002 — Shared clause ownership

`QueryParts` owns only its implemented shared clause state and canonical materialization order.

### BUILD-003 — Normal preparation

Builder output re-enters normal `SQLable` preparation.

### BUILD-004 — Reuse without duplication

New builder state reuses `QueryParts` when it is one of the shared clause concerns already owned there, rather than duplicating that state. Other builder-specific state may remain with its builder when appropriate.

### BUILD-005 — Builders use the shared structural continuation contract

Under the evidence-proven major-version SQL-region frame architecture, `QueryParts`, `SQLSelectBuilder`, UNION/set-result materialization, and other continuation-style builders must use the same generic root-frame-aware structural composition primitive as ordinary fluent APIs. Builders must not maintain a parallel ownership map, hidden current-statement mode, or dialect-specific routing state.

Final ORDER BY on a set result belongs to the set-result root rather than the rightmost operand. CTE bodies and nested statement inputs remain opaque nested SQL-region frames. Builder materialization must preserve that structure while producing byte-for-byte historical PostgreSQL/MySQL SQL and binding order on neutral/no-owner paths.

Downstream helpers that intentionally continue a framed query should receive the same safe public structural continuation extension point rather than manually assuming top-level array append always means statement continuation.
