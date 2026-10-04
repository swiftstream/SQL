# Migrating from SwifQL to SQL

The package/product/module identity has changed from `SwifQL` to `SQL`.

Start with the module import:

```swift
import SwifQL
// becomes
import SQL
```

Then migrate old symbol spellings using the compiler's `deprecated, renamed:` diagnostics.

| Old | New |
|---|---|
| product `SwifQL` | product `SQL` |
| `import SwifQL` | `import SQL` |
| `SwifQL.select(...)` | `SQL.root.select(...)` |
| `SwifQL { ... }` | `SQL { ... }` |
| `SwifQL(query)` | `SQL(query)` |
| `SwifQLable` | `SQLable` |
| `SwifQLPart` | `SQLPart` |
| `SwifQLPrepared` | `SQLPrepared` |
| `SwifQLRenderContext` | `SQLRenderContext` |
| `SwifQLSelectBuilder` | `SQLSelectBuilder` |
| `SwifQLJoinBuilder` | `SQLJoinBuilder` |

## Module compatibility

There is no compatibility product, target, or module named `SwifQL` in the new package identity. `import SwifQL` is intentionally not part of the compatibility contract.

Compatibility is symbol-level inside module `SQL`: after `import SQL`, retained old `SwifQL*` spellings continue to compile where provided, but they are deprecated and renamed to the canonical SQL-prefixed API.

For example:

```swift
import SQL

let oldSpelling = SwifQL.select(Path.Column("id")) // deprecated -> SQL.root
let canonical = SQL.root.select(Path.Column("id"))
```

The two call sites use the same canonical implementation identity; the old spelling is only a migration bridge.

## Package dependency

The local package manifest now exports only product `SQL`. The remote repository has not been renamed or republished by this migration workflow, so do not assume a new GitHub URL is live yet.

When consuming a release that contains this identity migration from the current repository location, select product `SQL`:

```swift
.package(url: "https://github.com/SwifQL/SwifQL", /* version containing this migration */),
.target(name: "App", dependencies: [
    .product(name: "SQL", package: "SwifQL"),
])
```

## SQL semantics

This identity migration is not intended to change SQL rendering, bind ordering, dialect behavior, structural composition, or preparation semantics. The same PostgreSQL, MySQL, and DuckDB behavior remains behind the renamed package/module/API surface.

Validated migration candidate:

- Swiftly Apple Swift 6.3.3: 730 tests / 62 suites
- Xcode Apple Swift 6.3.3: 730 tests / 62 suites
- Xcode Apple Swift 6.4: 730 tests / 62 suites

## Recommended migration order

1. Update the package product dependency from `SwifQL` to `SQL`.
2. Replace `import SwifQL` with `import SQL`.
3. Build the project.
4. Follow compiler rename diagnostics for remaining `SwifQL*` symbols.
5. Prefer `SQL { ... }` for declarative construction and `SQL.root` for fluent construction.
6. Keep any intentionally historical source/examples unchanged only where they document an older release.

---

# Earlier migration: SwifQL 1.x to SwifQL 2.x

The current SwifQL 2 release candidate/current pre-release is `2.0.0-beta.6.1.0`.

```swift
.package(
    url: "https://github.com/SwifQL/SwifQL",
    exact: "2.0.0-beta.6.1.0"
)
```

If you are moving from SwifQL 1.5.x or from an earlier 2.0 beta, this guide shows the changes that may require something from your code. Shared semantic values are available starting with `2.0.0-beta.6.0.0`, and `2.0.0-beta.6.0.1` remains the Swift toolchain compatibility hotfix. `2.0.0-beta.6.1.0` adds declarative table DDL authoring; existing query source does not need to migrate to adopt it.

The good news is that normal SQL-shaped SwifQL queries mostly stay normal SQL-shaped SwifQL queries.

For example, this is still the idea:

```sql
SELECT "User"."email", "User"."name"
FROM "User"
WHERE "User"."email" = 'john@gmail.com'
ORDER BY "User"."name" ASC
LIMIT 10
```

```swift
SwifQL
    .select(\User.email, \User.name)
    .from(User.table)
    .where(\User.email == "john@gmail.com")
    .orderBy(.asc(\User.name))
    .limit(10)
```

The important migration points are below.

## Swift 6

SwifQL 2 uses Swift 6 language mode.

### Before

A SwifQL 1.5 project could stay on a Swift 5 language mode package.

### Now

The current SwifQL 2 prerelease requires Swift 6.3 or newer and is built with:

```swift
// swift-tools-version:6.3
```

and:

```swift
swiftLanguageModes: [.v6]
```

Release validation uses Apple Swift 6.3.3.

The macOS deployment target is still 10.15, so the Swift 6 migration does not raise that runtime platform floor by itself.

If you have a long-lived Vapor 4 / Swift 5 project and do not want to move it yet, SwifQL 1.5.x remains the simple choice.

## `SwifQLable.parts` is structural now

This is the main breaking change for custom SwifQL extensions.

If your app only builds queries through normal public SwifQL methods, you probably do not need to change anything here.

If you have helpers that manually append to `parts`, read this section.

### Was

A helper could flatten two arrays together:

```swift
extension SwifQLable {
    func appendingMyFragment(_ fragment: SwifQLable) -> SwifQLable {
        SwifQLableParts(parts: self.parts + fragment.parts)
    }
}
```

That loses the meaning of a real statement/subquery/set-result boundary once queries become more complex.

### Became

If your helper means “continue the current query”, use structural continuation:

```swift
extension SwifQLable {
    func appendingMyFragment(_ fragment: SwifQLable) -> SwifQLable {
        structurallyAppending(fragment)
    }
}
```

The normal query still looks the same:

```swift
let users = Path.Table("users")

let query = SwifQL
    .select(users.*)
    .from(users)
    .where(users.column("is_active") == true)
```

but SwifQL can now keep real SQL regions intact while that query is copied, erased to `SwifQLable`, nested, passed through builders, or continued later.

Do not mechanically replace every `parts` copy with `structurallyAppending(_:)`.

This is still valid when you intentionally want a copy of the same structural value:

```swift
let copied = SwifQLableParts(parts: query.parts)
```

## Inspecting structural query parts

If your extension needs to inspect the public representation, inspect the structural types instead of assuming that every statement is one flat token array.

```swift
if let frame = query.parts.first as? SwifQLStructuralFramePart {
    print(frame.region)

    for child in frame.children {
        if let groupBy = child as? SwifQLGroupByPart {
            print(groupBy.owner as Any)
            print(groupBy.fields)
        }

        if let orderBy = child as? SwifQLOrderByPart {
            print(orderBy.owner as Any)
            print(orderBy.items)
        }
    }
}
```

This matters most to libraries and advanced local extensions that inspect `parts` directly. Ordinary query source should not need to know about the frame.

## Custom clause ownership remains extensible

If you build your own advanced SwifQL extension, clause ownership is not a closed enum.

```swift
extension SwifQLClauseOwner {
    static let report = SwifQLClauseOwner(
        namespace: "com.example.reporting",
        name: "report"
    )
}

extension SwifQLClauseKind {
    static let reportOrder = SwifQLClauseKind(
        namespace: "com.example.reporting",
        name: "reportOrder"
    )
}

let scope = SwifQLClauseOwner.report.renderScope(for: .reportOrder)
```

The important part is that custom extensions continue through normal SwifQL composition/preparation instead of inventing a second renderer.

## Predefined `Fn.Name` values are immutable

If you only use functions normally, nothing changes:

```swift
SwifQL.select(Fn.coalesce("hello", "world"))
```

If you used a predefined function-name slot as mutable global storage, migrate it.

### Was

```swift
Fn.Name.coalesce = .custom("my_coalesce")
```

### Became

```swift
let name = Fn.Name.custom("my_coalesce")
let fn = Fn.build(name)
```

Predefined names are now immutable so Swift 6 does not turn shared mutable function-name state into a concurrency problem.

## Actors: build the query here, send a snapshot there

SwifQL 2 is clean under Swift 6 strict concurrency, but that does **not** mean every query object or every bind value is `Sendable`.

Do not solve actor warnings by sending a `SwifQLable`, `SwifQLSplittedQuery`, or arbitrary `[Encodable]` across actors with unchecked conformances.

The recommended shape is:

```text
SwifQL query on caller isolation
        ↓
prepare / normalize
        ↓
consumer-owned Sendable snapshot
        ↓
actor / database layer
```

For example:

```swift
import SwifQL

enum BindSnapshot: Sendable {
    case string(String)
    case int(Int)
}

struct QuerySnapshot: Sendable {
    let sql: String
    let binds: [BindSnapshot]
}

enum SnapshotError: Error {
    case unsupportedBind
}

func makeSnapshot(_ split: SwifQLSplittedQuery) throws -> QuerySnapshot {
    let binds = try split.values.map { value -> BindSnapshot in
        if let value = value as? String { return .string(value) }
        if let value = value as? Int { return .int(value) }
        throw SnapshotError.unsupportedBind
    }

    return QuerySnapshot(sql: split.query, binds: binds)
}

actor ConnectionActor {
    func execute(_ snapshot: QuerySnapshot) {
        // pass the snapshot to your driver
    }
}

final class Wrapper {
    let connection: ConnectionActor

    init(connection: ConnectionActor) {
        self.connection = connection
    }

    nonisolated(nonsending)
    func execute(_ query: SwifQLable) async throws {
        let split = query.prepare(.duck).splitted
        let snapshot = try makeSnapshot(split)
        await connection.execute(snapshot)
    }
}
```

Your real snapshot should support the bind types your database layer really accepts.

The rule is simple: keep the SwifQL graph on the caller isolation, and cross the actor boundary only with data that your own code can truthfully make `Sendable`.

## `SQLDialect.all` now contains three built-in dialects

Code that treated `SQLDialect.all` as “PostgreSQL + MySQL” should stop assuming there are exactly two entries.

### Was

```swift
// effectively PostgreSQL + MySQL
SQLDialect.all
```

### Now

```swift
SQLDialect.all // [.psql, .mysql, .duck]
```

For example, a test helper that loops over `SQLDialect.all` now also runs against DuckDB.

If you need one exact dialect, keep asking for that dialect explicitly:

```swift
query.prepare(.psql)
query.prepare(.mysql)
query.prepare(.duck)
```

## DuckDB uses the same SQL-shaped SwifQL style

There is no separate “Duck query language” in SwifQL.

For example:

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

One DuckDB-specific runtime detail worth knowing: dynamic simplified PIVOT without an explicit `IN (...)` can be valid SQL but cannot always be prepared as one C prepared statement because DuckDB discovers the output columns while expanding it. If your execution path requires a prepared statement, prefer an explicit `IN (...)` form when appropriate.

Administration/runtime families such as INSTALL/LOAD, secrets, broad PRAGMA/configuration, CHECKPOINT, VACUUM/ANALYZE administration, variables, EXPORT/IMPORT DATABASE, SHOW/DESCRIBE/SUMMARIZE, extension-specific SQL, and the generic `name := expression` API are not part of the current SwifQL 2 DuckDB support.

## Static `raw(_:)` now uses the text you pass

The static raw route was corrected while keeping its established spacing behavior.

```swift
SwifQLableParts.raw("TAIL").prepare(.psql).plain
// " TAIL"

"TAIL".raw.prepare(.psql).plain
// "TAIL"
```

Normal flat composition remains:

```text
BASE TAIL
```

If you accidentally depended on the old static-raw bug, update that call site to the SQL you actually intend to emit.

## Some predefined roots now return fresh values

The source syntax does not change:

```swift
SwifQL
AttachOption.readOnly
CopyOption.header
CopyOption.array
CopyOption.schema
```

They now produce fresh values instead of sharing stored non-Sendable instances.

If your code only uses them to build SQL, there is nothing to migrate. Do not rely on object identity for these predefined values.

## PostgreSQL date formatting changed internally, not in your SQL

You still write the same query source.

The PostgreSQL formatter is now instance-local for Swift 6 concurrency correctness, while the generated PostgreSQL date SQL remains compatible with the previous behavior.

No migration is needed unless your code depended on internal formatter identity rather than SwifQL's public SQL output.

## Quick migration checklist

- Move the consuming project to Swift 6.3 or newer when adopting the current SwifQL 2 prerelease.
- Pin the current pre-release with `exact: "2.0.0-beta.6.1.0"`.
- Check local/package extensions that manually append or pattern-match `SwifQLable.parts`.
- Use `structurallyAppending(_:)` when a helper means “continue this framed query”.
- Replace mutations of predefined `Fn.Name` values with `Fn.Name.custom(_:)` / `Fn.build(_:)`.
- Check code/tests that assume `SQLDialect.all` contains exactly two dialects.
- Keep SwifQL query/bind graphs on caller isolation and cross actors with your own Sendable snapshot.
- If you use DuckDB, check the documented supported feature set before assuming an administration/runtime feature exists.

The final Swift 6.3.3 validation passed 448 tests in 42 suites with zero concurrency errors and zero concurrency warnings.
