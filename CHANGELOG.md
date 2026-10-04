# Changelog

## Unreleased — SQL identity migration

The package/product/module identity is now `SQL`.

- product `SwifQL` -> `SQL`
- `import SwifQL` -> `import SQL`
- canonical roots are `SQL { ... }` and `SQL.root`
- canonical protocol/preparation names include `SQLable`, `SQLPart`, and `SQLPrepared`
- old `SwifQL*` symbol spellings remain deprecated/renamed inside module `SQL` where compatibility aliases/bridges are provided
- there is no compatibility module named `SwifQL` and no `@_exported import SQL` shim
- the migration is intended to preserve SQL rendering, bind order, dialect behavior, and preparation semantics

The remote repository has not been renamed or republished by this migration workflow, so existing GitHub URLs remain hosting/history references until a separate publication step occurs.

## 2.0.0-beta.6.1.0

Adds declarative table DDL authoring with `CreateTable`, `AlterTable`, and `AddColumn`. The new grammar keeps historical table/schema/column identifiers explicit, uses intentionally static non-empty DDL builders, and preserves the existing fluent/legacy DDL APIs. See [RELEASE_NOTES.md](RELEASE_NOTES.md) for examples.

## 2.0.0-beta.6.0.1

This patch aligns the package minimum Swift tools floor with the validated Swift 6.3 line and runs CI on Swift 6.3.3. It introduces no SQL/API behavior changes from `2.0.0-beta.6.0.0`.

## 2.0.0-beta.6.0.0

Shared Semantic Values are now published: `PureDate`, `PureTime`, `DateTime`, and structural `Interval` use the ordinary value path and render according to the selected dialect. See [RELEASE_NOTES.md](RELEASE_NOTES.md) for examples and dialect boundaries.

## 2.0.0-beta.5.1.0

Published prerelease with unsafe-value render provenance while preserving the established preparation and binding pipeline.

## 2.0.0-beta.5.0.0

SwifQL 2 moves the package to Swift 6, expands the SQL surface, and strengthens query composition.

### Swift 6

SwifQL now uses:

```swift
// swift-tools-version:6.0
```

```swift
swiftLanguageModes: [.v6]
```

The macOS deployment target remains 10.15.

### Dialects

SwifQL 2 keeps the same preparation model across its built-in dialects:

```swift
query.prepare(.psql)
query.prepare(.mysql)
query.prepare(.duck)
```

`SQLDialect.all` now contains:

```swift
[.psql, .mysql, .duck]
```

The expanded SQL surface includes PIVOT/UNPIVOT, MERGE, COPY, table/file functions, JSON, nested types/values, LIST/lambda helpers, joins, set operations, DML/RETURNING, common DDL, sequences, macros, and ATTACH/DETACH/USE, with dialect-specific rendering where required.

Example:

```swift
let cities = Path.Table("cities")

SwifQL
    .pivot(cities)
    .on(cities.column("year"), in: 2000, 2010)
    .using(Fn.sum(cities.column("population")) => "total")
    .groupBy(cities.column("country"))
    .orderBy(.desc(cities.column("country")))
    .limit(2)
```

will give:

```sql
PIVOT "cities" ON "year" IN (2000, 2010) USING sum("population") as "total" GROUP BY "country" ORDER BY "country" DESC LIMIT 2
```

### Structural query composition

Real statement/subquery/set-result regions are now preserved inside `SwifQLable.parts`.

If you have a custom helper that means “continue this query”, migrate it from manual array concatenation:

```swift
SwifQLableParts(parts: self.parts + fragment.parts)
```

to:

```swift
structurallyAppending(fragment)
```

Normal SQL-shaped SwifQL query source remains the same wherever the old public query source did not need to change.

### Predefined `Fn.Name` values are immutable

Instead of mutating a predefined name:

```swift
Fn.Name.coalesce = .custom("my_coalesce")
```

build a custom name explicitly:

```swift
let fn = Fn.build(.custom("my_coalesce"))
```

### Strict-concurrency integration

SwifQL query/bind graphs stay intentionally non-Sendable where that is the truthful model.

For actor-based wrappers:

```text
prepare on caller isolation
→ convert to your own Sendable snapshot
→ send the snapshot across the actor boundary
```

See [MIGRATION.md](MIGRATION.md) for a complete example.

### Static `raw(_:)` fix

```swift
SwifQLableParts.raw("TAIL").prepare(.psql).plain
// " TAIL"

"TAIL".raw.prepare(.psql).plain
// "TAIL"
```

The static form now uses the supplied text correctly while preserving the established spacing behavior.

### Fresh predefined values

These call sites are unchanged:

```swift
SwifQL
AttachOption.readOnly
CopyOption.header
CopyOption.array
CopyOption.schema
```

but they now return fresh values instead of sharing stored non-Sendable instances.

### PostgreSQL date formatting

Date formatting is now instance-local for Swift 6 concurrency correctness. Generated PostgreSQL date SQL remains compatible.

### Validation

```text
Apple Swift 6.3.3
448 tests / 42 suites
concurrency errors: 0
concurrency warnings: 0
```

The current DuckDB SQL support was validated against DuckDB v1.5.5.

Full examples and migration details are in [RELEASE_NOTES.md](RELEASE_NOTES.md) and [MIGRATION.md](MIGRATION.md).

## 1.5.0

The last stable SwifQL release line for Swift 5 projects.
