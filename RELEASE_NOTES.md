# Unreleased — SQL Major Identity Migration

The canonical package product and Swift module have moved from `SwifQL` to `SQL`.

Migration starts with:

```swift
import SwifQL
// becomes
import SQL
```

Then follow compiler rename diagnostics for remaining old spellings:

- `SwifQL.select(...)` -> `SQL.root.select(...)`
- `SwifQL { ... }` -> `SQL { ... }`
- `SwifQL(query)` -> `SQL(query)`
- `SwifQLable` -> `SQLable`
- `SwifQLPart` -> `SQLPart`
- `SwifQLPrepared` -> `SQLPrepared`

There is no `SwifQL` compatibility module in the new package identity. Compatibility is symbol-level only: retained old `SwifQL*` names are deprecated/renamed declarations inside module `SQL`.

This identity migration is not intended to change SQL rendering, dialect behavior, bind ordering, or preparation semantics. The corrected candidate passed 730 tests in 62 suites on Swiftly 6.3.3, Xcode Swift 6.3.3, and Xcode Swift 6.4.

The remote repository has not been renamed or republished by this migration workflow. Do not assume a new GitHub URL is live until a separate publication step is completed.

See [MIGRATION.md](MIGRATION.md) for the migration table and recommended order.

---

# Historical release notes

# SwifQL 2.0.0-beta.6.1.0 — Declarative Table DDL

This prerelease adds a small SQL-shaped declarative surface for creating and altering tables.

Install it with:

```swift
.package(
    url: "https://github.com/SwifQL/SwifQL",
    exact: "2.0.0-beta.6.1.0"
)
```

## Create tables

```swift
let query = CreateTable("users") {
    NewColumn("id", .uuid).primaryKey()
    NewColumn("email", .text).unique().notNull()
}

query.prepare(.psql).plain
```

will give:

```sql
CREATE TABLE "users" ("id" uuid PRIMARY KEY, "email" text UNIQUE NOT NULL)
```

Generated columns participate in the same table-definition grammar:

```swift
CreateTable("metrics") {
    NewColumn("base", .integer)
    GeneratedColumn("derived", as: Path.Column("base") + 1)
}
```

## Alter tables

```swift
let query = AlterTable("users") {
    AddColumn("display_name", .text)
}

query.prepare(.psql).plain
```

will give:

```sql
ALTER TABLE "users" ADD COLUMN "display_name" text
```

Multiple actions stay in one `ALTER TABLE` statement and preserve source order.

Table, schema, and column identifiers are explicit strings so historical DDL declarations do not silently change when current model metadata or key paths change. The DDL result builders are intentionally static and non-empty; direct runtime branching and loops are not part of this first grammar.

This is additive. Existing fluent/query source and legacy DDL APIs do not need to migrate. SwifQL only builds SQL: migration versioning, history, transaction policy, and execution belong to the consuming library or application.

---

# SwifQL 2.0.0-beta.6.0.1 — Swift 6.3 Toolchain Floor

This is a compatibility and release-pipeline hotfix. The minimum Swift tools version is 6.3, and release CI validates with Swift 6.3.3. SQL/API behavior is unchanged from `2.0.0-beta.6.0.0`.

Install it with:

```swift
.package(
    url: "https://github.com/SwifQL/SwifQL",
    exact: "2.0.0-beta.6.0.1"
)
```

---

# SwifQL 2.0.0-beta.6.0.0 — Shared Semantic Values

SwifQL `2.0.0-beta.6.0.0` adds shared civil-date, time-of-day, civil-date-time, and structural-interval values: `PureDate`, `PureTime`, `DateTime`, and `Interval`.

```swift
let date = PureDate(year: 2026, month: 9, day: 4)!
let time = PureTime(hour: 12, minute: 34, second: 56, nanosecond: 123_456_789)!
let dateTime = DateTime(
    year: 2026,
    month: 9,
    day: 4,
    hour: 12,
    minute: 34,
    second: 56,
    nanosecond: 123_456_789
)!
let interval = Interval(months: 2, days: -3, microseconds: 4)

SwifQL.select(date, time, dateTime, interval).prepare(.duck).plain
```

will give:

```sql
SELECT DATE '2026-09-04', CAST('12:34:56.123456789' AS TIME_NS), CAST('2026-09-04 12:34:56.123456789' AS TIMESTAMP_NS), INTERVAL '2 months -3 days 4 microseconds'
```

`PureDate` and `PureTime` model timezone-free civil values; `PureDate` supports astronomical years and explicit temporal infinity states. `DateTime` is a timezone-free civil combination with finite and explicit infinity states, not an instant or `Foundation.Date`; exact `24:00:00` canonicalizes to the next day's midnight. `Interval` preserves independent signed months, days, and microseconds plus explicit infinity states, so it is not a fixed duration or `Comparable`. `Foundation.Date` interop for `PureDate` and `DateTime` requires an explicit Gregorian `Calendar` and `TimeZone` and can fail.

All four types use the ordinary value/binding path. Automatic inference remains intentionally limited: `PureDate` maps to `.date`, `PureTime` to `.time`, and `Foundation.Date` keeps `.timestamptz`; `DateTime` and `Interval` retain `.text` fallback and should use explicit `.timestamp` or `.interval` schema types when required. Check the selected dialect's range and precision before assuming portability: MySQL uses exact-or-hard-fail rendering, Duck `TIMESTAMP_NS` has a finite physical range, and shared interval infinity is not native Duck interval infinity.

Install this prerelease with `exact: "2.0.0-beta.6.0.0"`.

---

# SwifQL 2.0.0-beta.5.0.0 🚀

SwifQL 2 now runs in Swift 6 language mode, with a much broader SQL surface and safer query composition.

Install it with:

```swift
.package(
    url: "https://github.com/SwifQL/SwifQL",
    exact: "2.0.0-beta.5.0.0"
)
```

If you are updating an existing project, also check [MIGRATION.md](MIGRATION.md).

## Swift 6

SwifQL now builds in Swift 6 language mode:

```swift
// swift-tools-version:6.0
```

```swift
swiftLanguageModes: [.v6]
```

The macOS deployment target is still 10.15.

Most importantly, moving SwifQL itself to strict concurrency did not turn the query DSL into a pile of `@unchecked Sendable` conformances.

Normal query code is still normal query code:

```swift
let query = SwifQL
    .select(\User.email, \User.name)
    .from(User.table)
    .where(\User.email == "john@gmail.com")
    .orderBy(.asc(\User.name))
    .limit(10)
```

## More SQL, same SwifQL style

A lot of the SQL surface has grown without creating a second database-specific query language.

### PIVOT

```swift
let cities = Path.Table("cities")

let query = SwifQL
    .pivot(cities)
    .on(cities.column("year"), in: 2000, 2010)
    .using(Fn.sum(cities.column("population")) => "total")
    .groupBy(cities.column("country"))
    .orderBy(.desc(cities.column("country")))
    .limit(2)

query.prepare(.duck).plain
```

will give:

```sql
PIVOT "cities" ON "year" IN (2000, 2010) USING sum("population") as "total" GROUP BY "country" ORDER BY "country" DESC LIMIT 2
```

### MERGE

```swift
let target = Path.Table("merge_target")
let source = Path.Table("merge_source")

let query = SwifQL.merge(
    into: target,
    using: source,
    on: target.column("id") == source.column("id")
)

query.prepare(.duck).plain
```

will give:

```sql
MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id"
```

You can also build it incrementally:

```swift
SwifQL
    .merge(into: target)
    .using(source)
    .on(target.column("id") == source.column("id"))
```

and get the same query.

### COPY

```swift
let events = Path.Table("events")

let query = SwifQL.copy(
    events,
    to: "events.csv",
    options: .format("csv"), .header
)

query.prepare(.duck).plain
```

will give:

```sql
COPY "events" TO 'events.csv' (FORMAT 'csv', HEADER)
```

The same release also includes the current SQL support around SELECT analytics, JSON, nested types/values, LIST/lambda helpers, joins, set operations, star/COLUMNS, UNPIVOT, DML/RETURNING, DDL, sequences, macros, ATTACH/DETACH/USE, table/file functions, and related SQL surfaces.

The point is not a separate API for every database. The point is to keep writing the SQL idea directly in Swift and let the selected dialect render it correctly.

## Dialects

SwifQL 2 keeps the same preparation model across its built-in dialects:

```swift
query.prepare(.psql)
query.prepare(.mysql)
query.prepare(.duck)
```

and:

```swift
SQLDialect.all // [.psql, .mysql, .duck]
```

So if your own tests assumed that `SQLDialect.all` always contained exactly PostgreSQL and MySQL, update that assumption.

## Breaking change: `SwifQLable.parts` keeps real SQL regions now

This mostly affects advanced extensions that manually modify `parts`.

### Was

```swift
extension SwifQLable {
    func appendingMyFragment(_ fragment: SwifQLable) -> SwifQLable {
        SwifQLableParts(parts: self.parts + fragment.parts)
    }
}
```

### Became

When the helper means “continue this query”:

```swift
extension SwifQLable {
    func appendingMyFragment(_ fragment: SwifQLable) -> SwifQLable {
        structurallyAppending(fragment)
    }
}
```

This lets statement/subquery/set-result ownership survive copied parts, type erasure, builders, nested SQL, PIVOT/UNPIVOT, and set composition without hidden token scanning.

Ordinary SQL-shaped query call sites do not need to start manipulating structural frames.

If you do inspect them, the public representation is available:

```swift
if let frame = query.parts.first as? SwifQLStructuralFramePart {
    print(frame.region)
    print(frame.children)
}
```

## Breaking change: predefined `Fn.Name` values are immutable

### Was

```swift
Fn.Name.coalesce = .custom("my_coalesce")
```

### Became

```swift
let name = Fn.Name.custom("my_coalesce")
let fn = Fn.build(name)
```

Normal function usage does not change:

```swift
SwifQL.select(Fn.coalesce("hello", "world"))
```

## Strict concurrency: send your data, not the SwifQL graph

A `SwifQLable` query and arbitrary `[Encodable]` binds are intentionally not declared `Sendable` just to satisfy the compiler.

For actor-based database wrappers, use this shape:

```text
build/prepare SwifQL on caller isolation
        ↓
convert to your own Sendable snapshot
        ↓
send the snapshot to the actor
```

For example:

```swift
struct QuerySnapshot: Sendable {
    let sql: String
    let binds: [String]
}

actor ConnectionActor {
    func execute(_ snapshot: QuerySnapshot) {
        // execute through your driver
    }
}
```

Your real snapshot should model the actual bind types your driver accepts. A complete example is in [MIGRATION.md](MIGRATION.md).

## `raw(_:)` fix

Static raw now uses the supplied text correctly while preserving the established route-specific spacing:

```swift
SwifQLableParts.raw("TAIL").prepare(.psql).plain
// " TAIL"

"TAIL".raw.prepare(.psql).plain
// "TAIL"
```

## Small Swift 6 changes with the same call sites

These still look exactly the same:

```swift
SwifQL
AttachOption.readOnly
CopyOption.header
CopyOption.array
CopyOption.schema
```

but they now return fresh values instead of reusing shared non-Sendable instances.

PostgreSQL date formatting also moved to instance-local state while keeping generated PostgreSQL SQL compatible.

## What is intentionally not in the current DuckDB support

This release does not claim every DuckDB administration/runtime feature.

INSTALL/LOAD, secrets, broad PRAGMA/configuration, CHECKPOINT, VACUUM/ANALYZE administration, variables, EXPORT/IMPORT DATABASE, SHOW/DESCRIBE/SUMMARIZE convenience, extension-specific SQL universes, and the generic SQL `name := expression` API remain separate future work.

## Validation

The current Swift 6.3.3 suite passes:

```text
448 tests / 42 suites
concurrency errors: 0
concurrency warnings: 0
```

The current DuckDB SQL support was also validated against DuckDB v1.5.5.

See [MIGRATION.md](MIGRATION.md) for the actual migration steps and [CHANGELOG.md](CHANGELOG.md) for the compact version history.
