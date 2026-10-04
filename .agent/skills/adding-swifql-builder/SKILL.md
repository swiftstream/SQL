---
name: adding-swifql-builder
description: Add or extend a built-in SQL builder inside this repository. The skill package keeps its historical routing identifier; current source/API targets the SQL module.
---

# Add or Extend a SQL Builder

Use this procedure when adding or extending a SQL builder. Architecture authority remains [`BUILDERS_AND_QUERY_PARTS.md`](../../architecture/BUILDERS_AND_QUERY_PARTS.md).

1. Load [`BUILDERS_AND_QUERY_PARTS.md`](../../architecture/BUILDERS_AND_QUERY_PARTS.md) as the primary owner and [`SOURCE_MAP.md`](../../SOURCE_MAP.md) for navigation.
2. Inspect the nearest relevant production builder under `Sources/SQL/` and `QueryParts` only as needed to establish current patterns.
3. Decide the exact state owner in the plan before mutation.
4. Reuse `QueryParts` only for shared clause state it already owns; keep builder-specific state with the builder when that is the established boundary.
5. Build normal `SQLable` output. Do not create a second renderer or bypass normal preparation.
6. Add focused validation/tests for the changed builder behavior, including dialect or binding expectations when affected.
7. Audit backwards compatibility, raw dynamic interpolation, and unrelated cleanup before handoff.
