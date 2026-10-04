---
name: adding-swifql-sql-function
description: Add or change a built-in compositional SQL function helper inside the canonical SQL module. The skill package keeps its historical routing identifier.
---

# Add a Compositional SQL Function

Use this procedure when adding a compositional SQL function helper. Architecture and value-safety authority remain [`DSL_COMPOSITION.md`](../../architecture/DSL_COMPOSITION.md) and [`SAFETY_RULES.md`](../../SAFETY_RULES.md).

1. Load [`DSL_COMPOSITION.md`](../../architecture/DSL_COMPOSITION.md), [`SAFETY_RULES.md`](../../SAFETY_RULES.md), and [`SOURCE_MAP.md`](../../SOURCE_MAP.md).
2. Inspect neighboring current files under `Sources/SQL/Functions/**` and the current `Fn` construction before choosing the helper shape.
3. Classify each argument as SQL structure or dynamic data.
4. Prefer composition of existing parts and current `Fn` helpers.
5. Keep dynamic data on the normal bound-value path; use trusted inline representation only for deliberately controlled structure.
6. Add dialect-specific expectations only where semantics or rendering actually differ.
7. Avoid opportunistic renaming or refactoring of historical function APIs and unrelated helpers.
