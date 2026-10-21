# Dialect-Transparent DSL Public Content Ideas

Focused idea bank for README/docs/publication material around SwifQL's dialect-transparent DSL architecture.

Do not load this shard during ordinary source work. Read/update it only when a positive public-content capture check points here or when preparing public documentation/content.

## Same clean query, dialect-specific rendering under the hood

Status: shipped
Good for: README | website docs | article | short post

### Why users should care

SwifQL should let users write the SQL idea they mean instead of exposing database-driver-like wrapper types throughout the query. Dialect differences belong in preparation/rendering whenever the SQL concept is truthfully the same.

This is a strong concise story for SwifQL: **the DSL stays clean while the selected dialect handles grammar details under the hood**.

### Candidate example / visual

Conceptual public call site:

```swift
let cities = Path.Table("cities")

let query = SwifQL.pivot(cities)
    .on(cities.column("year"), in: 2000, 2010)
    .using(Fn.sum(cities.column("population")) => "total")
    .groupBy(cities.column("country"))
    .orderBy(.desc(cities.column("country")))
    .limit(2)

let sql = query.prepare(.duck)
```

The user should not need database-prefixed PIVOT wrapper types for columns, ON expressions, or aggregates, because those describe implementation/database mechanics rather than the SQL idea the user is expressing.

Simple visual:

```text
clean SwifQL query
       │
       ▼
semantic parts + scopes
       │
       ▼
prepare(selected dialect)
       │
   ┌───┴────┐
   ▼        ▼
 normal   dialect-specific
 SQL idea  grammar rendering
```

### Evidence / provenance

Stable architecture owners:

- `.agent/architecture/DSL_DESIGN_AND_UX.md` DESIGN-014/015
- `.agent/architecture/DIALECT_RENDERING.md` DIALECT-008/012/013
- `.agent/architecture/dialects/DUCK.md` DUCK-010/018

Architecture checkpoint:

`65879f7248af6488222655aa33d1316a516a594f` - `📖 Define semantic render scopes`

### Publication caveat

The generic semantic render-scope mechanism and the clean structural Duck PIVOT API first shipped in `2.0.0-beta.5.0.0`, became part of the stable SQL 2.x surface, and are carried forward in current stable SQL 3.1.0. Current public material should use the canonical SQL identity while distinguishing later deferred Duck families from shipped behavior.

## Semantic render scopes: context travels with the expression

Status: shipped
Good for: website docs | article | technical deep dive | short post

### Why users should care

A major SwifQL strength is composability. Queries can be assembled through variables, conditions, helpers, and separate methods rather than one monolithic fluent chain.

Dialect-aware rendering must preserve that property. Semantic render scope is therefore structural metadata attached to the relevant nested parts, not an ambient mutable "current builder mode" and not a guess based on neighboring SQL tokens.

This makes dialect-aware behavior compositional and predictable even in large dynamically assembled queries.

### Candidate example / visual

Equivalent valid queries should preserve the same semantics whether written as one chain:

```swift
var query = SwifQL.pivot(cities)
    .on(cities.column("year"), in: 2000, 2010)
    .using(Fn.sum(cities.column("population")))
```

or assembled incrementally:

```swift
var query: SwifQLable = SwifQL.pivot(cities)

if includeYears {
    query = query.on(cities.column("year"), in: 2000, 2010)
}

query = query.using(Fn.sum(cities.column("population")))
```

or from helpers/fragments:

```swift
func populationTotal() -> SwifQLable {
    Fn.sum(cities.column("population"))
}

query = query.using(populationTotal())
```

Conceptual internal structure:

```text
Scoped(.pivotOn)
└─ KeyPath
   ├─ table: cities
   └─ column: year
```

The scope stays with those nested parts when they are copied/appended/returned/stored.

During normal rendering:

```sql
"cities"."year"
```

During Duck simplified-PIVOT ON rendering:

```sql
"year"
```

without asking the user to rewrite the path.

### Important validity nuance

The composability guarantee is not "SwifQL invents missing grammar".

For example:

```swift
var query: SwifQLable = SwifQL

if includePivot {
    query = query.pivot(cities)
}

query = query.on(cities.column("year"), in: 2000, 2010)
```

is only a valid PIVOT query when the parent PIVOT construct is actually present. Semantic scopes guarantee that **equivalent valid composition shapes preserve meaning**, not that a PIVOT-only clause becomes valid after its required parent was conditionally omitted.

### Evidence / provenance

- `.agent/architecture/DSL_DESIGN_AND_UX.md` DESIGN-015
- `.agent/architecture/DIALECT_RENDERING.md` DIALECT-008
- `.agent/TESTING_RULES.md`, contextual rendering/composition equivalence contract
- architecture commit `65879f7248af6488222655aa33d1316a516a594f`
- current SwifQL 2 source, published in `2.0.0-beta.5.0.0`: `SwifQLRenderScope`, `SwifQLRenderContext`, `SwifQLable.scoped(_:)`, structural clause ownership, and recursive scoped preparation.

### Publication caveat

The generic render-scope mechanism and Duck PIVOT APIs first shipped in `2.0.0-beta.5.0.0`, became part of the stable SQL 2.x surface, and are carried forward in current stable SQL 3.1.0. The SwifQL spellings in this captured example are historical and must be normalized to current SQL names before promotion unless the old spelling is itself the migration subject.

## Nested expressions keep their grammar context

Status: shipped
Good for: website docs | article | technical diagram

### Why users should care

A useful demonstration of structural scopes is that dialect context should reach relevant descendants even when a column is nested inside functions/operators. Users do not have to flatten or rewrite expressions to satisfy a dialect-specific grammar rule.

### Candidate example / visual

User expression:

```swift
.on(Fn.coalesce(cities.column("year"), 0))
```

Conceptual parts:

```text
Scoped(.pivotOn)
└─ Fn.coalesce
   ├─ KeyPath(cities.year)
   └─ 0
```

The Duck renderer can see `.pivotOn` while rendering the descendant key path and produce the grammar-correct unqualified reference without changing the surrounding function expression.

An even stronger nested-path example:

```text
normal context:
"events"."payload"->'year'

Duck PIVOT expression context:
"payload"->'year'
```

The renderer removes only the source-table qualification required by Duck's PIVOT grammar; it does **not** collapse the nested path to only `"year"`.

### Evidence / provenance

Architecture decision in `DIALECT_RENDERING.md` DIALECT-008 and Duck-specific qualification contract in `architecture/dialects/DUCK.md`.

### Publication caveat

The nested-path behavior is implemented, validated, shipped in the stable SQL 2.x line, and carried forward in current stable SQL 3.1.0. Public examples should use the canonical SQL identity and preserve the exact Duck-specific rendering behavior.

## Preserve `KeyPathLastPath` without faking a PIVOT-only overload

Status: validated architecture lesson
Good for: article | maintainer/developer docs | migration/extension docs

### Why users should care

SwifQL already has a public abstraction for APIs whose own static grammar truly requires a column name: `KeyPathLastPath`.

Duck simplified PIVOT `GROUP BY` also requires column-name grammar, but after an incremental chain is erased to `var query: SwifQLable`, the unchanged global `.groupBy(_ fields: SwifQLable...)` call cannot honestly become PIVOT-only at compile time. A more-specific global `KeyPathLastPath` overload would still leave the generic fallback available for arbitrary expressions and could perturb ordinary overload resolution.

The cleaner design is to preserve the natural source:

```swift
.groupBy(cities.column("country"))
```

without pretending Swift can express a PIVOT-only static guarantee after receiver erasure. SwifQL preserves the generic SQL DSL, structural ownership handles rendering context, and DuckDB remains the authority that rejects invalid PIVOT GROUP BY expressions.

This avoids both user-facing inventions such as:

```swift
DuckPivotColumn("country")
```

and a misleading global overload that would look stricter than it actually is.

### Evidence / provenance

Live source confirms `KeyPathLastPath` is public and already participates in existing public query/path APIs. The erased-receiver overload contradiction and reconciled decision are durably owned by `architecture/dialects/DUCK.md` together with DESIGN-015/016; transient planning artifacts are not required to recover this rule.

### Publication caveat

Do not describe `KeyPathLastPath` as an internal detail or as removed. It remains established public compatibility surface. The lesson is specifically that a dialect-specific compile-time restriction must not be simulated through an established erased global method when the type system cannot truthfully enforce it.

## Public extension point for semantic scopes

Status: shipped
Good for: advanced website docs | article | extension-author docs

### Why users should care

The semantic-scope mechanism used by SwifQL is available to downstream Swift extensions without exposing mutable renderer internals.

Advanced users can build clean custom DSL helpers that preserve semantic rendering context instead of falling back to raw SQL or private implementation knowledge.

### Candidate example / visual

```swift
extension SwifQLRenderScope {
    static let myFeature = SwifQLRenderScope(
        namespace: "com.example.my-library",
        name: "myFeature"
    )
}

extension SwifQLable {
    func myFeatureExpression() -> SwifQLable {
        scoped(.myFeature)
    }
}
```

The desired architecture is:

```text
external Swift extension
        │
        ▼
library-owned scoped-expression mechanism
        │
        ▼
normal SwifQL parts
        │
        ▼
context-aware dialect rendering
```

not:

```text
external code
  └─ custom unknown SwifQLPart
     └─ hope core prepare() knows how to render it
```

### Evidence / provenance

- `DIALECT_RENDERING.md` DIALECT-009 and DIALECT-012
- `DSL_DESIGN_AND_UX.md` DESIGN-015 and DESIGN-016

External-consumer validation established that `SQLDialect.init()` is public, a downstream module can subclass `SQLDialect`, and the additive context-aware hook forwards to the established hook by default.

### Publication caveat

The scope/extensibility architecture first shipped in `2.0.0-beta.5.0.0` together with the approved first-closure Duck statement APIs, became part of the stable SQL 2.x surface, and is carried forward in current stable SQL 3.1.0. Public material should distinguish historical SQL 2.x APIs, current SQL 3.x APIs, later deferred Duck families, and the Swift-5-era 1.5.x line.

## Scopes first, focused semantic statement representation only when grammar truly needs more

Status: architecture-approved
Good for: technical article | architecture docs | conference/post material

### Why users should care

This is a useful engineering story: SwifQL avoids both extremes.

It does not accumulate token-neighbor hacks, but it also does not prematurely replace its proven parts pipeline with a giant full-query AST.

Semantic render scopes solve local contextual differences. A focused semantic statement representation is reserved for the day a verified dialect difference really needs whole-statement structural transformation.

### Candidate example / visual

```text
                    SwifQLable
                        │
                        ▼
                   [SwifQLPart]
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
     normal part    scoped part   future focused
                                  statement part
          │             │             │
          └─────────────┴──────┬──────┘
                               ▼
                   one recursive preparation
                               │
                   one ordered bind/value state
                               │
                               ▼
                         selected dialect
```

Decision rule:

```text
same SQL meaning, local contextual rendering difference
    -> semantic render scope

verified dialect needs structural reorder / omission / duplication /
whole-statement decision
    -> focused semantic statement representation
```

No second general renderer is introduced preemptively.

### Evidence / provenance

`DIALECT_RENDERING.md` DIALECT-013 and architecture decision audit.

### Publication caveat

Focused semantic statement representation is a documented extension boundary, not an implemented feature and not current technical debt.

## Native PIVOT validation as a trust story

Status: validated
Good for: website docs | article | release notes | short post

### Why users should care

SwifQL's Duck PIVOT design is being driven by actual DuckDB v1.5.5 parser/binder/prepared-statement behavior rather than assumptions from SQL strings alone.

This is useful public evidence for the library's correctness philosophy.

### Candidate facts worth preserving

Native DuckDB v1.5.5 validation established that:

- source-qualified columns fail inside simplified PIVOT ON;
- source-qualified aggregate input fails inside USING;
- GROUP BY succeeds with unqualified column names and rejects qualified forms;
- ORDER BY succeeds with unqualified PIVOT output names and rejects source-qualified forms;
- explicit PIVOT `IN ($1, $2)` values successfully prepare/bind/execute, including numeric, apostrophe-containing text, and Unicode values;
- prepared `LIMIT $3` also works when explicit IN makes the statement prepare-able;
- dynamic no-IN simplified PIVOT executes as plain SQL but DuckDB v1.5.5 cannot prepare it as one statement because its dynamic pivot expansion uses multiple internal statements.

This native matrix directly motivated the clean dialect-transparent rendering design instead of unsafe raw interpolation or database-specific wrapper APIs.

### Evidence / provenance

Stable Duck facts are owned by `.agent/architecture/dialects/DUCK.md`. Current transient research/native evidence belongs only to the active Duck research artifact lineage.

### Publication caveat

The native engine facts and the redesigned PIVOT API were implemented and validated before stable `2.0.0`, became part of the SQL 2.x surface, and remain relevant in current SQL 3.x. Public content should use current SQL naming, distinguish shipped behavior from later deferred Duck work, and treat the SwifQL spellings in this shard as historical context.
