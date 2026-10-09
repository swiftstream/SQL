---
name: adding-swifql-sql-function
description: Add or change a built-in compositional SQL function helper inside the canonical SQL module. The skill package keeps its historical routing identifier.
---

# Add a Compositional SQL Function

Use this procedure when adding a compositional SQL function helper. Architecture and value-safety authority remain [`DSL_COMPOSITION.md`](../../architecture/DSL_COMPOSITION.md) and [`SAFETY_RULES.md`](../../SAFETY_RULES.md).

1. Load [`DSL_COMPOSITION.md`](../../architecture/DSL_COMPOSITION.md), [`SAFETY_RULES.md`](../../SAFETY_RULES.md), and [`SOURCE_MAP.md`](../../SOURCE_MAP.md).
2. Inspect neighboring current files under `Sources/SQL/Functions/**` and the current `Fn` construction before choosing the helper shape.
3. Classify the function as scalar/compositional or aggregate-style. Scalar helpers continue to use the ordinary `Fn.build` composition path. When the function is an aggregate and the current architecture exposes `AggregateArgumentBuilder`, prefer a builder overload that forwards to `Fn.aggregate` rather than duplicating aggregate assembly.
4. Preserve existing concise overloads unless the accepted plan explicitly removes them. An aggregate builder overload should be additive and should preserve concise rendering parity where both forms represent the same call.
5. For aggregate builder wrappers, forward the closure directly:

```swift
public static func exampleAggregate(
    @AggregateArgumentBuilder _ body: () -> AggregateArguments
) -> SQLable {
    aggregate(.exampleAggregate, body)
}
```

Do not add a fallback `Fn.aggregate(Name, AggregateArguments)` merely to make wrapper forwarding convenient, and do not expose nested builder state types in the wrapper signature.
6. Classify each argument as SQL structure or dynamic data. Keep dynamic data on the normal bound-value path; use trusted inline representation only for deliberately controlled structure.
7. Prefer composition of existing parts and current `Fn` helpers. For aggregate argument grammar, keep DISTINCT ownership and aggregate-local ORDER BY in the shared aggregate builder rather than reimplementing them per function.
8. Add focused parity/compatibility tests for both the new builder form and any retained concise form. Preserve established zero/star semantics exactly; do not silently rewrite an empty builder body to a star argument.
9. Add dialect-specific expectations only where semantics or rendering actually differ.
10. Avoid opportunistic renaming or refactoring of historical function APIs and unrelated helpers.
