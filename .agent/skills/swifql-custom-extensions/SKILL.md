---
name: swifql-custom-extensions
description: Create downstream custom SQL functions, fluent helpers, structural continuations, custom clause ownership, or reusable extension libraries for the canonical SQL module. The skill package keeps its historical routing identifier.
license: LICENSE.txt
---

# Extend SQL Downstream

Use this workflow when a consuming package or application needs reusable SQL composition that is not a built-in API.

1. Determine the SQL package version and source actually installed by the consumer before relying on extension APIs.
2. Classify the extension: custom SQL function, fluent helper, structural continuation, structural-value copy, custom clause ownership, or another compositional wrapper.
3. For a custom SQL function, prefer `Fn.Name.custom(_:)` with `Fn.build(_:)` and compose ordinary arguments through their existing `SQLable.parts`.
4. If a helper means “continue this query,” use `structurallyAppending(_:)`. Do not assume flattening a framed root is equivalent to continuation.
5. If the goal is to copy the same structural value rather than continue it, keep that distinction explicit; `SQLableParts(parts: query.parts)` is the normal copy path.
6. Use public `SQLClauseOwner` and `SQLClauseKind` only when the extension genuinely owns clause semantics. Inspect the installed source/tests for the exact structural pattern before introducing custom ownership.
7. Keep dynamic or untrusted data out of raw/custom SQL structure. Ordinary scalar arguments should flow through their normal `SQLable` representation and binding path.
8. Return composed results to the ordinary `SQLable` preparation pipeline. Do not add a second renderer, formatter, placeholder system, or bind collector.
9. Validate representative target-dialect output and the exact bind-value order.

A custom function with a runtime argument can stay on the normal value path:

```swift
import SQL

let runtimeValue = input
let function = Fn.build(
    .custom("my_function"),
    body: runtimeValue.parts
)

let prepared = SQL.select(function).prepare(.psql).splitted
```

For continuation, prefer the structural API directly:

```swift
let continued = query.structurallyAppending(fragment)
```

For a same-value copy where continuation is not intended:

```swift
let copied = SQLableParts(parts: query.parts)
```

Do not convert a dynamic value into a raw operator/string merely to make a custom extension easier to render. If the desired feature appears to require bypassing normal preparation, inspect the installed SQL composition model first; the extension should normally be expressible as `SQLPart` composition that rejoins standard preparation.
