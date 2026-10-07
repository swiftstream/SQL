[![Mihael Isaev](https://user-images.githubusercontent.com/1272610/53677263-7ecbfe00-3cc6-11e9-9049-2d2b9a2d7947.png)](http://mihaelisaev.com)

<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-6.3-brightgreen.svg" alt="Swift 6.3">
    </a>
    <a href="https://discord.gg/q5wCPYv">
        <img src="https://img.shields.io/discord/612561840765141005" alt="Swift.Stream">
    </a>
</p>
<br>

# Swift Stream SQL

**SQL (formerly SwifQL)** is a strongly typed, declarative, composable Swift DSL for building SQL.

Write SQL concepts directly in Swift, compose them as values, and prepare the result for PostgreSQL, MySQL, or DuckDB. SQL builds statements. Execution stays with your database driver.

Generated SQL examples in this README use PostgreSQL `.plain` rendering unless noted otherwise. Use `.splitted` when you need query placeholders and bind values for a driver.

## Installation

Requires Swift 6.3 or newer.

```swift
.package(
    url: "https://github.com/SwiftStream/SQL",
    from: "2.1.0"
)
```

Then depend on product `SQL`:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "SQL", package: "SQL")
    ]
)
```

and import it:

```swift
import SQL
```

## Philosophy

The idea is simple: start from the SQL you actually want.

```sql
SELECT "users"."id", "users"."email"
FROM "users"
WHERE "users"."email" = 'john@example.com'
LIMIT 10
```

Then express the same idea directly in Swift:

```swift
let query = SQL
    .select(\User.$id, \User.$email)
    .from(User.table)
    .where(\User.$email == "john@example.com")
    .limit(10)
```

or declaratively:

```swift
let query = SQL {
    Select(\User.$id, \User.$email)
    From(User.table)
    Where(\User.$email == "john@example.com")
    Limit(10)
}
```

Simple SQL should stay simple. Monster-complex SQL should still be possible without escaping into a second query language.

**Write SQL ideas in Swift, compose them like Swift values, and let the selected dialect prepare the final statement.**

## Type-safe tables and columns

Model-backed authoring is first-class.

```swift
struct User: Table {
    static var tableName: String { "users" }

    @Column("id") var id: Int
    @Column("email") var email: String
    @Column("name") var name: String
    @Column("active") var active: Bool
    @Column("role") var role: String

    init() {}
}
```

Now the table and columns can be referenced through the model:

```swift
User.table
\User.$id
\User.$email
\User.$name
```

Use these references throughout model-backed queries.

When you do not have a model type, explicit paths are available too:

```swift
let users = Path.Table("users")
let email = users.column("email")
```

Use `Path.Table(...)` and `Path.Column(...)` when you need explicit paths. Model-backed code can keep using `User.table` and type-safe key paths.

## Declarative queries

SQL supports two declarative styles. Chain clauses directly, or use the result builder when that reads better for the query you are writing.

### Fluent form

Chain SQL clauses directly:

```swift
let query = SQL
    .select(\User.$id, \User.$email, \User.$name)
    .from(User.table)
    .where(\User.$active == true)
    .orderBy(.asc(\User.$name))
    .limit(20)
```

which gives:

```sql
SELECT "users"."id", "users"."email", "users"."name"
FROM "users"
WHERE "users"."active" = TRUE
ORDER BY "users"."name" ASC
LIMIT 20
```

Start directly from `SQL`:

```swift
SQL.select(...)
SQL.insertInto(...)
SQL.update(...)
SQL.delete(from: ...)
SQL.where(...)
```

### Result builder form

The same query can be written with `SQL { ... }`:

```swift
let query = SQL {
    Select(\User.$id, \User.$email, \User.$name)
    From(User.table)
    Where(\User.$active == true)
    OrderBy(.asc(\User.$name))
    Limit(20)
}
```

This prepares to the same SQL as the fluent form above.

When a clause needs multiple children, conditions, or loops, switch only that clause to its result-builder form:

```swift
let query = SQL {
    Select {
        \User.$id
        \User.$email
        \User.$name
    }

    From(User.table)

    Where {
        \User.$active == true

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

    OrderBy {
        OrderByItem.asc(\User.$name)
    }

    Limit(20)
}
```

Use concise calls for fixed SQL and clause builders when Swift control flow makes the query clearer.

Both declarative forms use the same preparation and binding behavior. Clauses are ordinary composable `SQLable` values, so you can extract and reuse them when that makes a query easier to read.

## Swift expressions in queries

Inside a query, you can mix normal Swift literals and values directly with model-backed SQL expressions. You do not need to wrap them in `SQLable` first.

As each expression is built, SQL's operator overloads produce composable `SQLable` values automatically:

```swift
let minimumID = 100
let idOffset = 1
let email = "john@example.com"

let query = SQL {
    Select(
        \User.$id,
        \User.$id + idOffset
    )
    From(User.table)
    Where(
        \User.$id >= minimumID
        && \User.$email == email
        && \User.$active == true
    )
}
```

Here `idOffset`, `minimumID`, `email`, and `true` are ordinary Swift values. They become part of SQL expressions only where they are used with SQL operands.

PostgreSQL gives:

```sql
SELECT "users"."id", "users"."id" + 1
FROM "users"
WHERE "users"."id" >= 100 AND "users"."email" = 'john@example.com' AND "users"."active" = TRUE
```

### One caveat: optional nil checks

There are two expressions to be careful with in ordinary Swift code outside a query: `== nil` and `!= nil`.

When `Wrapped: SQLable`, `Optional<Wrapped>` is also `SQLable`. That means these expressions can participate in SQL overload resolution even when they look like ordinary Swift optional checks:

```swift
let someOptional: String? = nil

let a = someOptional == nil
let b = someOptional != nil
```

Depending on the surrounding type context, `a` and `b` can resolve to `SQLable` predicates instead of `Bool`.

If you mean a normal Swift nil-check, make the result type explicit:

```swift
let someOptional: String? = nil

let a: Bool = someOptional == nil
let b: Bool = someOptional != nil
```

Inside SQL expressions, `== nil` and `!= nil` are exactly what you want:

```swift
let isMissing = \User.$email == nil
// SQL: "users"."email" IS NULL

let isPresent = \User.$email != nil
// SQL: "users"."email" IS NOT NULL
```

## Reusable queries

`SQLQuery` lets a normal Swift value own a reusable parameterized query:

```swift
struct UserQuery: SQLQuery {
    let active: Bool
    let email: String?
    let roles: [String]?

    var query: Query {
        Select(\User.$id, \User.$email)
        From(User.table)

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

Because `SQLQuery` is itself `SQLable`, it composes as an ordinary SQL value:

```swift
let source = From(
    UserQuery(
        active: true,
        email: nil,
        roles: ["admin", "moderator"]
    )
    .as("activeUsers")
)
```

`Query` is the shorthand return type provided by `SQLQuery`.

## Preparation, binds, and execution

SQL builds statements. Your driver executes them.

Prepare for the target database:

```swift
let postgres = query.prepare(.psql)
let mysql = query.prepare(.mysql)
let duck = query.prepare(.duck)
```

For a plain rendered statement:

```swift
let sql = query.prepare(.psql).plain
```

For a statement with separated bind values:

```swift
let prepared = query.prepare(.psql).splitted

let sql = prepared.query
let values = prepared.values
```

That split is the normal boundary for a database driver or integration layer:

```text
SQL / SQLable
      ↓
prepare(dialect)
      ↓
SQLPrepared
      ↓
plain SQL
or
query + values
      ↓
your driver / connection / executor
```

SQL does not manage connection pools, transaction policy, result decoding, or execution lifecycle.

## INSERT, UPDATE, and DELETE

The same model-backed references work for DML.

### INSERT

```swift
let insert = SQL
    .insertInto(
        User.table,
        fields: \User.$email, \User.$name
    )
    .values("john@example.com", "John")
```

Batch values can be appended through the same values surface.

### UPDATE

```swift
let update = SQL
    .update(User.table)
    .set[items:
        \User.$name == "Mike"
    ]
    .where(\User.$id == userID)
```

Schema-qualified model aliases remain available when you need them:

```swift
let vip = User.inSchema("VIP")

let update = SQL
    .update(vip.table)
    .set[items:
        vip.$name == "Mike"
    ]
```

### DELETE

```swift
let delete = SQL
    .delete(from: User.table)
    .where(\User.$id == userID)
```

The broader DML surface also includes RETURNING and conflict-related composition where supported by the target SQL dialect.

## Declarative table DDL

SQL includes SQL-shaped builders for table DDL:

```swift
let createUsers = CreateTable("users") {
    NewColumn("id", .uuid).primaryKey()
    NewColumn("email", .text).unique().notNull()
}
```

which gives:

```sql
CREATE TABLE "users" ("id" uuid PRIMARY KEY, "email" text UNIQUE NOT NULL)
```

And one `ALTER TABLE` statement can own multiple actions:

```swift
let alterUsers = AlterTable("users") {
    AddColumn("display_name", .text)
}
```

### Migration identifiers use strings

Database migrations are historical records. They must not silently change because the current Swift model was renamed later.

So migration-facing schema, table, and column identifiers stay explicit:

```swift
CreateTable("users") {
    NewColumn("email", .text)
}

AlterTable("users") {
    AddColumn("display_name", .text)
}
```

Do **not** derive historical migration identifiers from current `User.table` / `\User.$email` model metadata.

SQL only builds the DDL statement. Migration versions, history, transaction policy, and execution belong to the consuming application or database layer.

## Shared semantic values

SQL includes database-facing civil and interval values:

```swift
let date = PureDate(year: 2026, month: 9, day: 4)!
let time = PureTime(
    hour: 12,
    minute: 34,
    second: 56,
    nanosecond: 123_456_789
)!
let dateTime = DateTime(
    year: 2026,
    month: 9,
    day: 4,
    hour: 12,
    minute: 34,
    second: 56,
    nanosecond: 123_456_789
)!
let interval = Interval(
    months: 2,
    days: -3,
    microseconds: 4
)

SQL
    .select(date, time, dateTime, interval)
    .prepare(.psql)
    .plain
```

PostgreSQL gives:

```sql
SELECT
    DATE '2026-09-04',
    TIME '12:34:56.123456789',
    TIMESTAMP '2026-09-04 12:34:56.123456789',
    INTERVAL '2 months -3 days 4 microseconds'
```

These values model database semantics directly:

- `PureDate` is a timezone-free civil date.
- `PureTime` is a nanosecond-capable time of day.
- `DateTime` is a timezone-free civil date + time, not an instant.
- `Interval` preserves independent months, days, and microseconds.

Rendering is dialect-aware and fails closed where a selected database cannot represent a value exactly.

## Dialects

The same query value can be prepared for the built-in dialects:

```swift
query.prepare(.psql)
query.prepare(.mysql)
query.prepare(.duck)
```

Queries can share structure across PostgreSQL, MySQL, and DuckDB while each dialect owns its database-specific rendering.

## Everything composes through `SQLable`

Values, columns, expressions, predicates, functions, clauses, complete statements, and reusable `SQLQuery` values all participate through `SQLable`.

That means you can build SQL pieces wherever it is convenient, keep them in variables or constants, pass them through your own APIs, and combine them later:

```swift
let shiftedID: any SQLable = \User.$id + 1
let active: any SQLable = \User.$active == true
let hasEmail: any SQLable = \User.$email != nil
let predicate: any SQLable = active && hasEmail

let selection = Select(\User.$id, shiftedID)
let source = From(User.table)
let filter = Where(predicate)
let ordering = OrderBy(.asc(\User.$name))

let query = SQL {
    selection
    source
    filter
    ordering
}
```

PostgreSQL gives:

```sql
SELECT "users"."id", "users"."id" + 1
FROM "users"
WHERE "users"."active" = TRUE AND "users"."email" IS NOT NULL
ORDER BY "users"."name" ASC
```

A complete statement can itself become a fragment:

```swift
let users = SQL {
    Select(\User.$id)
    From(User.table)
}

let source = From(users.as("u"))
```

`SQLQuery` values compose the same way:

```swift
let source = From(
    UserQuery(
        active: true,
        email: nil,
        roles: nil
    )
    .as("u")
)
```

Nested queries, subqueries, set operations, and your own custom `SQLable` types all use the same composition model.

SQL grammar still matters. A scalar expression belongs where SQL expects an expression, a clause belongs where that clause is valid, and a statement becomes a nested statement when used as a source.

## Aliases and casts

Use `=>` for aliases and SQL casts.

Column alias:

```swift
SQL.select(
    \User.$email => "email"
)
```

Cast:

```swift
SQL.select(
    \User.$email => .text
)
```

Table aliases keep typed column access:

```swift
let u = User.as("u")

let query = SQL
    .select(u.$id, u.$email)
    .from(u.table)
```

## Predicates and operators

Normal Swift-looking operators map to SQL predicates:

| Swift | SQL |
| --- | --- |
| `>` | `>` |
| `>=` | `>=` |
| `<` | `<` |
| `<=` | `<=` |
| `==` | `=` |
| `== nil` | `IS NULL` |
| `!=` | `!=` / dialect equivalent |
| `!= nil` | `IS NOT NULL` |
| `&&` | `AND` |
| `||` | `OR` |

For example:

```swift
let predicate =
    \User.$active == true &&
    \User.$email != nil
```

which gives:

```sql
"users"."active" = TRUE AND "users"."email" IS NOT NULL
```

Functions are ordinary SQL values too:

```swift
let activeCount =
    Fn.count(\User.$id)
        .filter(where: \User.$active == true)
        => "active_count"
```

## PostgreSQL JSON and arrays

PostgreSQL-specific helpers remain available when you actually want PostgreSQL-specific SQL.

JSON object:

```swift
let json = PgJsonObject()
    .field(key: "id", value: \User.$id)
    .field(key: "email", value: \User.$email)
```

Arrays:

```swift
PgArray()
PgArray(1, 2, 3)
PgArray() => .textArray
```

The project also supports JSON paths, nested values, array/list operations, and other dialect-aware SQL families.

## More SQL

SQL includes a much broader surface than basic SELECT/INSERT/UPDATE/DELETE, including:

- joins, subqueries, CTEs, and set operations
- aggregates, FILTER, ordering, grouping, and analytical SQL
- JSON and nested values
- PostgreSQL arrays and related operators
- DuckDB LIST/lambda helpers and nested types
- PIVOT / UNPIVOT
- MERGE
- COPY
- DML + RETURNING
- DDL and schema operations
- sequences and macros
- table and file functions
- catalog/file-oriented DuckDB SQL
- custom SQL functions, operators, paths, and raw/static structure when a typed surface does not exist yet.

The examples above cover only part of the API. SQL is designed to stay close to the database language even as queries grow more complex.

## How it works under the hood

SQL is built from composable values. Values that participate in SQL conform to `SQLable` and expose `SQLPart` values.

At a high level:

```text
SQL.select(...)
SQL { ... }
Select(...) / Select { ... }
From(...) / From { ... }
Where(...) / Where { ... }
SQLQuery
custom SQLable values
        ↓
composable SQLPart structure
        ↓
selected SQLDialect
        ↓
SQLPrepared
        ↓
plain / splitted
```

These authoring styles can be mixed in the same query.

Functions, operators, clauses, and dialect-specific features are composable SQL values, so custom extensions fit the same model.

If you implement custom `SQLable` values by working with `parts` directly, preserve the existing structure instead of flattening it. See [MIGRATION.md](MIGRATION.md) for the compatibility note.

## Swift 6.3 and concurrency

SQL uses Swift 6 language mode and requires Swift 6.3+.

Query and bind values are not `Sendable` by default. When crossing an actor boundary, keep query construction/preparation on the originating isolation and send an application-owned `Sendable` snapshot containing the data your driver actually needs.

## Migrating from SwifQL

The project was renamed from **SwifQL** to **SQL**.

The common migration is:

was

```swift
import SwifQL

let query = SwifQL
    .select(\User.$id, \User.$email)
    .from(User.table)
```

became

```swift
import SQL

let query = SQL
    .select(\User.$id, \User.$email)
    .from(User.table)
```

Model-backed references remain first-class:

```swift
\User.$id
\User.$email
User.table
```

`import SwifQL` is no longer supported. After `import SQL`, retained old `SwifQL*` symbol spellings may still exist as deprecated/renamed bridges where provided.

For a step-by-step guide to migrating from SwifQL v1 → SQL v2, see [MIGRATION.md](MIGRATION.md).

For current release details, see [RELEASE_NOTES.md](RELEASE_NOTES.md).

## Contributing

If you cannot find a function or SQL construct out of the box, check the existing source first — much of the library is built from small `SQLable` extensions.

If something is genuinely missing, issues and pull requests are welcome ❤️

Tests live under `Tests/SQLTests`.

And if SQL saves you some time, giving the project a ⭐️ is always appreciated 🙂
