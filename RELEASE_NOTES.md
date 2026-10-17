# 3.0.0

Version 3.0.0 is the current stable major release. It adds first-class catalog/schema/database object qualification, carries that metadata through model/manual key paths and aliases, and adds bind-aware raw SQL value interpolation while preserving the existing single preparation/binding pipeline.

## Database qualification

Database structure can now be expressed with immutable `DB` values:

```swift
let catalog: DB.Catalog = "warehouse"
let schema = DB.Schema(catalog: catalog, name: "analytics")
let events = schema.table("events")
let userID = events.column("user", "id")
```

The same values are `SQLable`, so the selected dialect renders their structural identity through the ordinary query pipeline. Qualified columns lower to one key-path part carrying optional catalog/schema/table plus ordered path segments.

Models that own a schema now declare the structural value directly:

```swift
struct Event: Decodable, Table, Schemable {
    static let tableName = "events"
    static let schema = DB.Schema("analytics")
}
```

A catalog-aware model can add `Catalogable`:

```swift
struct Event: Decodable, Table, Catalogable {
    static let tableName = "events"
    static let schema = DB.Schema("analytics")
    static let catalog = DB.Catalog("warehouse")
}
```

Model qualification, typed/formatted/manual key paths, source aliases, DDL references, and structural `DB.*` values share this qualification model. Existing custom dialect hooks remain source-compatible.

## Bind-aware raw SQL values

When SQL structure must remain explicit but some positions contain runtime values, bind-aware raw interpolation provides explicit labeled values:

```swift
let id = 42
let name = "Ada"

let query = SQL.raw(
    "WHERE id = \(bind: id) AND name = \(bind: name)"
)
```

For PostgreSQL and Duck, the split form preserves existing `$N` placeholders; MySQL preserves `?`. Values remain in strict left-to-right occurrence order, including repeated equal values. Typed `Optional.some` and `.none` remain individual original bind occurrences.

Existing raw String routes remain source-compatible:

```swift
SQL.raw("CURRENT_TIMESTAMP")
query.raw("RETURNING id")
"FOR UPDATE".raw
```

Ordinary Swift interpolation in those String routes is still caller-owned text and is **not** a bind. Use `\(bind:)` for runtime value data only; identifiers, operators, clauses, and other SQL structure are not bind data. A bind does not make a placeholder legal where a database grammar forbids parameters.

Preparation now retains private text-vs-generated-bind provenance, so caller-owned text that happens to contain marker-like bytes is preserved exactly instead of being rediscovered by string scanning. This does not introduce a second renderer, parser, public AST, or new dialect hook.

## Validation

The accepted bind-aware raw candidate passed:

- Swiftly Apple Swift 6.3.3;
- Xcode 26.6 / Apple Swift 6.3.3;
- Xcode 27 / Apple Swift 6.4;
- 20 focused bind-aware raw tests on all three toolchains;
- normal-import executable consumer assertions on all three toolchains;
- 900 tests in 76 suites on all three full-package lanes;
- independent final product audit with no findings.

SQL 3.0.0 is published as the current stable release. Its immutable `3.0.0` tag remains the release point even as later `master` documentation/governance commits advance the branch.

---

# SQL 2.2.0

SQL 2.2.0 expands exact expression authoring, adds first-class SQL/JSON owners, and adds PostgreSQL range/multirange helpers while keeping the existing composition, preparation, and binding model.

Install with:

```swift
.package(
    url: "https://github.com/SwiftStream/SQL",
    from: "2.2.0"
)
```

## SQL ARRAY values and slices

Build SQL ARRAY expressions directly:

```swift
let values = SQLArray.items(1, 2, Path.Column("score"))
```

PostgreSQL gives:

```sql
ARRAY[1, 2, "score"]
```

The builder form supports normal Swift control flow while preserving source order:

```swift
let values = SQLArray.items {
    first

    if let middle {
        middle
    }

    for value in tail {
        value
    }
}
```

Subquery ARRAY grammar has its own form:

```swift
let ids = SQLArray.subquery {
    Select { Path.Column("id") }
    From { Path.Table("orders") }
}
```

Slices stay structural:

```swift
let middle = Path.Column("scores")[slice(2, 4)]
```

```sql
"scores"[2:4]
```

DuckDB also has the validated stepped slice form `slice(2, 8, step: 2)`. PostgreSQL support is limited to its validated slice grammar.

## Quantified comparisons

Exact `ANY`, `ALL`, and `SOME` comparisons compose with explicit operands:

```swift
let predicate =
    Path.Column("score") == ANY(SQLArray.items(1, 2, 3))
```

PostgreSQL gives:

```sql
"score" = ANY (ARRAY[1, 2, 3])
```

Subquery forms are available too:

```swift
let predicate = Path.Column("score") > All {
    Select { Path.Column("threshold") }
    From { Path.Table("limits") }
}
```

`ANY(...)` uses the uppercase SQL spelling because Swift already owns `Any`. `All(...)` and `Some(...)` keep normal callable Swift names.

## Aggregate argument builders

Aggregate-local arguments, `DISTINCT`, and ordering can stay inside the aggregate call:

```swift
let values = Fn.arrayAgg {
    Path.Column("value")
    OrderBy {
        OrderByItem.desc(Path.Column("createdAt"))
        OrderByItem.asc(Path.Column("id"))
    }
}
```

PostgreSQL gives:

```sql
array_agg("value" ORDER BY "createdAt" DESC, "id" ASC)
```

Existing concise aggregate overloads remain available. Downstream extensions can use the same public aggregate builder through `Fn.aggregate`.

## Exact operators and postfix continuations

For a fixed binary SQL operator that does not have a useful Swift operator spelling:

```swift
let expression = Path.Column("lhs")
    .op(.custom("@?"), Path.Column("rhs"))
```

PostgreSQL gives:

```sql
("lhs" @? "rhs")
```

The complete expression is grouped. The operator token is caller-chosen SQL structure, while ordinary value operands keep normal binding.

Expression continuations also include `Collate(...)` and `AtTimeZone(...)`. PostgreSQL additionally supports `AtLocal()`.

`AT TIME ZONE` is validated for PostgreSQL and DuckDB, and runtime timezone values stay bindable. `AT LOCAL` is PostgreSQL-specific.

## SQL/JSON

SQL 2.2.0 adds first-class SQL/JSON owners with dialect-specific capability boundaries.

| Dialect | Verified owners |
| --- | --- |
| PostgreSQL | `JSONExists`, `JSONValue`, `JSONQuery` |
| DuckDB | `JSONExists`, `JSONValue` |
| MySQL 8.4 | `JSONValue` / `JSON_VALUE` |

### PostgreSQL

PostgreSQL paths remain bindable, and PostgreSQL owns option grammar such as `Passing(...)`, `Returning(...)`, and the supported `ON EMPTY` / `ON ERROR` forms:

```swift
let value = JSONValue(Path.Column("payload"), "$.p") {
    Passing(2, as: "limit")
    Returning(.integer)
    DefaultOnEmpty(0)
    ErrorOnError()
}
```

`PASSING` is PostgreSQL-specific. PostgreSQL `JSONQuery` also exposes only the verified owner-specific returning/format forms.

### DuckDB

DuckDB supports `JSONExists` and `JSONValue` with bound paths:

```swift
let exists = JSONExists(document, path)
let value = JSONValue(document, path)
```

DuckDB does not gain PostgreSQL `PASSING` / returning / empty / error option grammar, and this release does not claim DuckDB `JSONQuery`.

### MySQL

The verified MySQL owner is `JSONValue` / `JSON_VALUE`.

A runtime Swift `String` path stays on the normal bind path:

```swift
let value = JSONValue(document, runtimePath)
```

MySQL 8.4 requires parser-literal path grammar and rejects a parameter marker in that position. SQL therefore does not move runtime path bytes into generated SQL text automatically.

For a fixed trusted path that your source code owns as SQL structure:

```swift
let value = JSONValue(
    document,
    SQL.raw("'$.name'")
)
```

That raw fragment is static SQL structure. It is not runtime path interpolation.

MySQL `JSON_VALUE` has its own supported `RETURNING` / `ON EMPTY` / `ON ERROR` grammar. This release does not claim MySQL `JSONExists`, `JSONQuery`, or `PASSING`.

## PostgreSQL ranges and multiranges

PostgreSQL range and multirange support uses exact SQL function/operator identities instead of introducing a second range model.

For example:

```swift
let empty = Fn.isEmpty(SQL.raw("int4range(1, 5)"))

let merged = Fn.rangeMerge(
    SQL.raw("int4range(1, 3)"),
    SQL.raw("int4range(5, 8)")
)
```

which render as:

```sql
isempty(int4range(1, 5))
range_merge(int4range(1, 3), int4range(5, 8))
```

Aggregate range helpers use the same aggregate argument machinery:

```swift
let ranges = Fn.rangeAgg {
    SQL.raw("period")
    OrderBy(SQL.raw("sort_key"), .asc)
}
```

Specialized symbolic operators use the grouped exact-operator API:

```swift
let overlaps = lhs.op(.custom("&&"), rhs)
```

Multirange and polymorphic type identities include `Type.int4MultiRange` and the related PostgreSQL `Type.anyCompatible*` family.

These range/multirange APIs are PostgreSQL-specific.

## Cross-dialect correctness fixes

Several established APIs now render the SQL their source spelling implies.

### `Fn.count()` counts all rows

```swift
Fn.count()
```

renders:

```sql
count(*)
```

### Multiple aggregate FILTER predicates use `AND`

```swift
Fn.count().filter(where: firstPredicate, secondPredicate)
```

Multiple predicates now form one ordered boolean expression joined with `AND`. Native `FILTER` support is covered for PostgreSQL and DuckDB. MySQL rendering remains compatibility output only; this does not claim native MySQL `FILTER` support.

### PostgreSQL `TABLESAMPLE` keeps PostgreSQL argument grammar

PostgreSQL rendering no longer inherits DuckDB `PERCENT` / `ROWS` tokens:

```sql
TABLESAMPLE system(10)
TABLESAMPLE system(30) REPEATABLE (40)
```

### PostgreSQL general-expression subscripts are grouped

General expression bases are parenthesized where PostgreSQL requires it:

```sql
(array_agg("score"))[1]
(array_agg($1))[$2]
```

Direct column references and already-completed subscripts remain direct.

## Migration and requirements

SQL 2.2.0 is additive for normal SQL 2.1 source. Existing declarative and fluent query code does not need a source migration to adopt the new expression families.

Swift 6.3 or newer remains required.

# SQL 2.1.0

SQL 2.1.0 completes the concise side of the declarative query DSL. Simple fixed clauses no longer need closure syntax just to hold one or a few values, while the existing result-builder forms remain first-class for conditions, loops, and richer clause-local composition.

The same query can now stay compact:

```swift
let query = SQL {
    Select(\User.$id, \User.$email)
    From(User.table)
    Where(\User.$email == "john@example.com")
    OrderBy(.asc(\User.$email))
    Limit(20)
}
```

and grow into result-builder form only where Swift control flow is useful:

```swift
let query = SQL {
    Select(\User.$id, \User.$email)
    From(User.table)

    Where {
        \User.$active == true

        if let email {
            \User.$email == email
        }
    }

    OrderBy {
        OrderByItem.asc(\User.$email)

        if newestFirst {
            OrderByItem.desc(\User.$id)
        }
    }

    Limit(20)
}
```

New additive concise declarative forms include:

```swift
From(User.table)
From(User.table, Profile.table)

Where(predicate)
Having(predicate)
Qualify(predicate)

GroupBy(\User.$role, \User.$active)

OrderBy(
    .asc(\User.$email),
    .desc(\User.$id)
)
```

`From(...)` also closes the gap between the shipped source and the stable declarative design that already documented concise FROM authoring.

Builder forms such as `From { ... }`, `Where { ... }`, `Having { ... }`, `Qualify { ... }`, `GroupBy { ... }`, and `OrderBy { ... }` are not deprecated or reduced. Concise and builder forms lower through the same existing SQL composition, preparation, and binding pipeline.

## Ordinary Swift operators stay ordinary Swift

SQL 2.1 also fixes a long-standing overload-preference compatibility problem on Swift 6.3.x. Merely importing SQL could cause broad SQLable overloads for ordinary arithmetic or ordering to win over the standard library, so unrelated expressions could infer as `any SQLable`.

The broad SQLable overloads for:

```text
+  -  *  /
>  <  >= <=
```

now remain available for SQL expressions but are lower-priority when Swift has a better ordinary overload.

With `import SQL`, ordinary Swift keeps its normal types:

```swift
let integer = 5
// Int

let floating = 5.0
// Double

let text = ""
// String

let total = UInt64(7) * 10 + 3
// UInt64

let negative = Int64(-1) < 0
// Bool
```

while model-backed expressions still build SQL:

```swift
let expression = \User.$score + 1
let predicate = \User.$age >= 18
```

The `==` / `!=` family is intentionally unchanged. SQLable equality must continue to construct SQL predicates, especially `== nil` / `!= nil` for `IS NULL` / `IS NOT NULL`. Concrete primitive equality remains `Bool` on the validated Swift 6.3.3 and Swift 6.4 toolchains. In generic or overloaded code where ordinary Swift equality is intended, keep operands concrete and make the `Bool` expectation explicit when that improves clarity.

This release is additive and requires no source migration from SQL 2.0.0. The Swift requirement remains Swift 6.3 or newer.

Install with:

```swift
.package(
    url: "https://github.com/SwiftStream/SQL",
    from: "2.1.0"
)
```

# SQL 2.0.0

SwifQL is now **SQL**. The package, product, Swift module, query root, and repository all use the SQL name, and the project now lives at `SwiftStream/SQL`.

Install SQL 2.0.0 with:

```swift
.package(
    url: "https://github.com/SwiftStream/SQL",
    from: "2.0.0"
)
```

and:

```swift
.product(name: "SQL", package: "SQL")
```

## SwifQL → SQL

The main migration is mechanical.

was

```swift
import SwifQL

let query = SwifQL
    .select(\User.$id)
    .from(User.table)
```

became

```swift
import SQL

let query = SQL
    .select(\User.$id)
    .from(User.table)
```

There is no compatibility module named `SwifQL`. After `import SQL`, retained old `SwifQL*` symbol spellings may still be available as deprecated/renamed bridges where provided.

The type-safe model DSL did not go away: `\User.$id`, `\User.$email`, and `User.table` remain first-class APIs. `Path.Column(...)` / `Path.Table(...)` are still available when an explicit path without a model type is what you want.

See [MIGRATION.md](MIGRATION.md) for the complete v1/v2 migration checklist.

## Fluent and declarative SQL

The familiar fluent API is now rooted directly at `SQL`:

```swift
let query = SQL
    .select(\User.$id, \User.$email)
    .from(User.table)
    .where(\User.$email == "john@example.com")
    .limit(10)
```

The same parts/preparation engine also has SQL-shaped result-builder authoring:

```swift
let query = SQL {
    Select {
        \User.$id
        \User.$email
    }

    From {
        User.table
    }

    Where {
        \User.$email == "john@example.com"
    }

    Limit(10)
}
```

Declarative fragments remain ordinary composable SQL values rather than a second query engine or ORM.

## Reusable `SQLQuery` values

Complex conditional SQL can live behind a small reusable value:

```swift
struct UserQuery: SQLQuery {
    let active: Bool
    let email: String?
    let roles: [String]?

    var query: Query {
        Select {
            \User.$id
            \User.$email
        }

        From {
            User.table
        }

        Where {
            \User.$active == active

            if let email {
                \User.$email == email
            }

            if let roles {
                Or {
                    for role in roles {
                        \User.$role == role
                    }
                }
            }
        }
    }
}
```

The call site stays small:

```swift
let users = UserQuery(
    active: true,
    email: email,
    roles: roles
)

let prepared = users.prepare(.psql)
```

`SQLQuery` is itself `SQLable`, so callers can compose `UserQuery(...)` directly without unwrapping `.query`. The protocol-local `Query` shorthand resolves to `SQLContent`. Most application code never needs to spell the concrete carrier.

## Swift 6

SQL 2.0.0 requires Swift 6.3 or newer and uses Swift 6 language mode.

The query and bind graph is not made artificially `Sendable` with unchecked conformances. If an actor boundary needs query data, prepare/build on the originating isolation and send an application-owned Sendable snapshot instead.

## PostgreSQL, MySQL, and DuckDB

The current preparation model supports:

```swift
query.prepare(.psql)
query.prepare(.mysql)
query.prepare(.duck)
```

SQL 2 substantially expands the available SQL surface while keeping dialect-aware rendering behind the same composable API. The release includes the accepted DuckDB surface together with the established PostgreSQL and MySQL support.

Representative additions across the 2.0 development line include analytics, JSON/nested values, joins and set operations, PIVOT/UNPIVOT, MERGE, COPY, DML/RETURNING, DDL, sequences, macros, table/file functions, and more.

## Declarative table DDL

Create and alter tables with SQL-shaped builders:

```swift
let createUsers = CreateTable("users") {
    NewColumn("id", .uuid).primaryKey()
    NewColumn("email", .text).unique().notNull()
}

createUsers.prepare(.psql).plain
```

will give:

```sql
CREATE TABLE "users" ("id" uuid PRIMARY KEY, "email" text UNIQUE NOT NULL)
```

```swift
let alterUsers = AlterTable("users") {
    AddColumn("display_name", .text)
}
```

Table/schema/column identifiers are explicit so historical migration declarations do not silently change when current model metadata changes. SQL builds these statements. Migration history, transactions, and execution remain outside this library.

## Shared semantic values

SQL includes `PureDate`, `PureTime`, `DateTime`, and structural `Interval` for database-facing civil and interval semantics.

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

SQL.select(date, time, dateTime, interval).prepare(.psql).plain
```

will give:

```sql
SELECT DATE '2026-09-04', TIME '12:34:56.123456789', TIMESTAMP '2026-09-04 12:34:56.123456789', INTERVAL '2 months -3 days 4 microseconds'
```

## Breaking changes worth checking

### Package/module/root rename

was

```swift
import SwifQL
SwifQL.select(...)
```

became

```swift
import SQL
SQL.select(...)
```

### Structural `parts` extensions

Advanced extensions that manually concatenated `SQLable.parts` should use the structural composition helpers instead of flattening statement/subquery ownership.

### Predefined `Fn.Name` values are immutable

was

```swift
Fn.Name.coalesce = .custom("my_coalesce")
```

became

```swift
let name = Fn.Name.custom("my_coalesce")
let fn = Fn.build(name)
```

Normal function calls such as `Fn.coalesce(...)` remain unchanged.

## Validation

The final `SQLContent` / `SQLQuery.Query` candidate passed the full package suite on all three release lanes:

```text
Swiftly / Apple Swift 6.3.3: 737 tests / 63 suites
Xcode 26.6 / Apple Swift 6.3.3: 737 tests / 63 suites
Xcode 27 / Apple Swift 6.4: 737 tests / 63 suites
```

Focused `SQLQuery` and identity suites passed 7/7 and 5/5. Fresh normal-import clients also passed on all three toolchains with `var query: Query`, explicit `SQLContent` typing, 37/37 direct-root representatives, PostgreSQL/MySQL/DuckDB bind checks, and deprecated SwifQL fluent/builder/unary parity.

For migration details see [MIGRATION.md](MIGRATION.md). The README contains the short v1 → v2 path and current installation examples.

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

Table, schema, and column identifiers are explicit strings so historical DDL declarations do not silently change when current model metadata or key paths change. The DDL result builders are intentionally static and non-empty. Direct runtime branching and loops are not part of this first grammar.

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

`PureDate` and `PureTime` model timezone-free civil values. `PureDate` supports astronomical years and explicit temporal infinity states. `DateTime` is a timezone-free civil combination with finite and explicit infinity states, not an instant or `Foundation.Date`. Exact `24:00:00` canonicalizes to the next day's midnight. `Interval` preserves independent signed months, days, and microseconds plus explicit infinity states, so it is not a fixed duration or `Comparable`. `Foundation.Date` interop for `PureDate` and `DateTime` requires an explicit Gregorian `Calendar` and `TimeZone` and can fail.

All four types use the ordinary value/binding path. Automatic inference remains intentionally limited: `PureDate` maps to `.date`, `PureTime` to `.time`, and `Foundation.Date` keeps `.timestamptz`. `DateTime` and `Interval` retain `.text` fallback and should use explicit `.timestamp` or `.interval` schema types when required. Check the selected dialect's range and precision before assuming portability: MySQL uses exact-or-hard-fail rendering, Duck `TIMESTAMP_NS` has a finite physical range, and shared interval infinity is not native Duck interval infinity.

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
