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
5. For result builders that encode a local SQL grammar, prefer typed intermediate/result states for invalid transitions rather than token inspection or runtime-only rejection. If the builder must accept arbitrary expressions, keep existential-safe ingress such as `buildExpression(_ expression: any SQLable)` when current API values are existential. Do not assume an `@available(*, unavailable)` specific overload will exclude a semantic type while a broader available ingress remains viable; route the semantic type to a distinct typed result/state that valid builder composition does not accept.
6. Preserve result-builder control-flow support deliberately. When required by the public grammar, cover optional, `if`/`else`, and loop paths in focused tests so state restrictions do not accidentally remove ordinary composition.
7. Build normal `SQLable` output. Do not create a second renderer or bypass normal preparation.
8. Add focused validation/tests for the changed builder behavior, including durable compile-negative fixtures for local grammar invariants when compile-time rejection is part of the contract. Validate those negatives on every compiler generation required by the current repository gate; classify the actual source diagnostic rather than requiring one exact wording.
9. Audit backwards compatibility, raw dynamic interpolation, public helper/state leakage, and unrelated cleanup before handoff.
