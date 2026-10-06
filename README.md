[![Mihael Isaev](https://user-images.githubusercontent.com/1272610/53677263-7ecbfe00-3cc6-11e9-9049-2d2b9a2d7947.png)](http://mihaelisaev.com)

<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-6-brightgreen.svg" alt="Swift 6">
    </a>
    <a href="https://discord.gg/q5wCPYv">
        <img src="https://img.shields.io/discord/612561840765141005" alt="Swift.Stream">
    </a>
</p>
<br>

# SQL

**SQL (formerly SwifQL)** is a strongly typed, declarative, composable Swift DSL for building SQL.

The package, product, Swift module, and public query root are all named `SQL`. The canonical repository is `SwiftStream/SQL`.

SQL is deliberately **SQL-first**. It is not an ORM and it does not execute queries. It gives you a Swift-native way to describe SQL while keeping the database language visible, composable, type-safe where your model gives us type information, and extensible when you need something unusual.

PostgreSQL, MySQL, and DuckDB are supported by the current preparation surface. Use SQL directly with your database driver or put a higher-level integration/execution layer on top of it.

## Installation

SQL 2.0.0 requires Swift 6.3 or newer.

```swift
.package(
    url: "https://github.com/SwiftStream/SQL",
    from: "2.0.0"
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

Simple SQL should stay simple. Monster-complex SQL should still be possible without escaping into a second query language.

That is the main design goal: **write SQL ideas in Swift, compose them like Swift values, and let the selected dialect prepare the final statement**.

## Type-safe tables and columns

Model-backed authoring is first-class in SQL 2.

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

This is the normal high-level API for model-backed query code.

When you intentionally do not have a model type, explicit paths are available too:

```swift
let users = Path.Table("users")
let email = users.column("email")
```

`Path.Table(...)` and `Path.Column(...)` are an additional explicit path API, not a replacement for `User.table` or type-safe key paths.

## Fluent SQL

The direct fluent root mirrors normal SQL-shaped authoring:

```swift
let query = SQL
    .select(\User.$id, \User.$email, \User.$name)
    .from(User.table)
    .where(\User.$active == true)
    .orderBy(.asc(\User.$name))
    .limit(20)
```

The root is simply `SQL`:

```swift
SQL.select(...)
SQL.insertInto(...)
SQL.update(...)
SQL.delete(from: ...)
SQL.where(...)
```

There is no `SQL.root` indirection.

## Result Builder DSL

The same SQL parts can be written with `SQL { ... }` and clause-local result builders:

```swift
let query = SQL {
    Select {
        \User.$id
        \User.$email
        \User.$name
    }

    From {
        User.table
    }

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

This is not a separate query engine. Fluent SQL, declarative clauses, reusable fragments, and `SQLQuery` all feed the same composition/preparation/binding pipeline.

Declarative clauses are ordinary composable SQL values, so you can extract and reuse them when that makes a query easier to read.

## Reusable queries

`SQLQuery` lets a normal Swift value own a reusable parameterized query:

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

Because `SQLQuery` is itself `SQLable`, it composes as an ordinary SQL value:

```swift
let source = From {
    UserQuery(
        active: true,
        email: nil,
        roles: ["admin", "moderator"]
    )
    .as("activeUsers")
}
```

The protocol-local `Query` shorthand resolves to `SQLContent`. Most application code never needs to spell the concrete carrier directly.

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

SQL intentionally does not own connection pools, transaction policy, result decoding policy, or execution lifecycle.

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

### Migration identifiers are intentionally strings

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
SELECT DATE '2026-09-04', TIME '12:34:56.123456789', TIMESTAMP '2026-09-04 12:34:56.123456789', INTERVAL '2 months -3 days 4 microseconds'
```

These values model database semantics rather than pretending every temporal value is a `Foundation.Date` or every interval is a fixed duration.

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

The goal is not to pretend PostgreSQL, MySQL, and DuckDB are identical. The goal is to keep one composable Swift SQL model while the selected dialect owns the rendering differences that actually belong to that database.

Dialect-specific capabilities remain dialect-specific.

## Composition

Everything useful in SQL is meant to compose.

A whole statement is composable:

```swift
let users = SQL {
    Select {
        \User.$id
    }

    From {
        User.table
    }
}
```

A clause is composable:

```swift
let activeUsers = Where {
    \User.$active == true
}
```

A reusable query is composable:

```swift
let source = From {
    UserQuery(
        active: true,
        email: nil,
        roles: nil
    )
    .as("u")
}
```

And nested/subquery/set-operation composition stays on the same `SQLable` pipeline rather than switching to a separate AST or string-template engine.

## Aliases and casts

The `=>` operator is intentionally useful for both aliasing and SQL casts.

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

The project also supports JSON paths, nested values, array/list operations, and other dialect-aware SQL families without turning them into ORM abstractions.

## More SQL

SQL 2 includes a much broader surface than basic SELECT/INSERT/UPDATE/DELETE, including:

- joins, subqueries, CTEs, and set operations;
- aggregates, FILTER, ordering, grouping, and analytical SQL;
- JSON and nested values;
- PostgreSQL arrays and related operators;
- DuckDB LIST/lambda helpers and nested types;
- PIVOT / UNPIVOT;
- MERGE;
- COPY;
- DML + RETURNING;
- DDL and schema operations;
- sequences and macros;
- table and file functions;
- catalog/file-oriented DuckDB SQL;
- custom SQL functions, operators, paths, and raw/static structure when a typed surface does not exist yet.

The library is intentionally not limited to the examples in this README.

If the database can express the SQL, the long-term goal is that SQL should make it practical to express that idea in Swift without hiding what the query actually means.

## How it works under the hood

The original SwifQL idea is still the core of SQL 2, just with a much stronger composition model.

`SQL` is the public starting point. Values that participate in SQL conform to `SQLable` and expose composable `SQLPart` values.

At a high level:

```text
SQL.select(...)
SQL { ... }
Select { ... }
Where { ... }
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

That is why very different authoring styles can mix together without creating separate query engines.

Most SQL capabilities are small composable pieces. If a function, operator, clause, or dialect feature is missing, the architecture is intentionally designed so it can usually be added as another SQL value/part instead of requiring an ORM rewrite or another parser.

Advanced extensions that manually work with `parts` should preserve structural composition rather than blindly flattening arrays. See [MIGRATION.md](MIGRATION.md) for the compatibility note.

That flexibility is one of the library's main ideas: **you should not hit a wall just because your query stopped being simple**.

## Swift 6 and concurrency

SQL 2 uses Swift 6 language mode and requires Swift 6.3+.

The query/bind graph is intentionally not hidden behind unchecked `Sendable` conformances.

When crossing an actor boundary, keep query construction/preparation on the originating isolation and send an application-owned Sendable snapshot containing the data your driver actually needs.

## Migrating from SwifQL

The project was renamed from **SwifQL** to **SQL** for the 2.0 stable release.

The common source migration is intentionally mechanical:

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

The important part is what did **not** disappear:

```swift
\User.$id
\User.$email
User.table
```

The model-backed, type-safe query surface remains first-class.

There is no compatibility module named `SwifQL`. After `import SQL`, retained old `SwifQL*` symbol spellings may still exist as deprecated/renamed bridges where provided.

For the complete v1 → v2 checklist and advanced compatibility details, see [MIGRATION.md](MIGRATION.md).

For the complete 2.0.0 release overview, see [RELEASE_NOTES.md](RELEASE_NOTES.md).

## Contributing

If you cannot find a function or SQL construct out of the box, check the existing source first — a lot of the library is intentionally built from small `SQLable` extensions.

If something is genuinely missing, issues and pull requests are welcome ❤️

Tests live under `Tests/SQLTests`.

And if SQL saves you some time, giving the project a ⭐️ is always appreciated 🙂
