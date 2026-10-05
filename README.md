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

**SQL (formerly SwifQL)** is a strongly typed, declarative, composable Swift DSL for building SQL. If you were looking for SwifQL, you're in the right place: the project was renamed from **SwifQL** to **SQL** when it moved to the **SwiftStream** organization.

Canonical repository: `SwiftStream/SQL`. The package, product, Swift module, and public query root are all named `SQL`.

SQL builds SQL; execution belongs to your database driver or integration layer. PostgreSQL, MySQL, and DuckDB are supported by the current SQL-building surface.

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

## Quick start

Start from the SQL you want to express:

```sql
SELECT "users"."id", "users"."email"
FROM "users"
WHERE "users"."email" = 'john@example.com'
LIMIT 10
```

The direct fluent API keeps the familiar SQL-shaped flow:

```swift
let users = Path.Table("users")
let email = users.column("email")

let query = SQL
    .select(users.column("id"), email)
    .from(users)
    .where(email == "john@example.com")
    .limit(10)

let prepared = query.prepare(.psql)
```

The same query can be written declaratively with `SQL { ... }`:

```swift
let users = Path.Table("users")
let email = users.column("email")

let query = SQL {
    Select {
        users.column("id")
        email
    }

    From {
        users
    }

    Where {
        email == "john@example.com"
    }

    Limit(10)
}
```

Reusable queries can hide conditional SQL behind an ordinary Swift value:

```swift
struct UserQuery: SQLQuery {
    let active: Bool
    let email: String?
    let roles: [String]?

    var query: Query {
        Select {
            Path.Column("id")
            Path.Column("email")
            Path.Column("created_at")
        }

        From {
            Path.Table("users")
        }

        Where {
            Path.Column("active") == active

            if let email {
                Path.Column("email") == email
            }

            if let roles {
                Or {
                    for role in roles {
                        Path.Column("role") == role
                    }
                }
            }
        }
    }
}
```

The call site only needs the parameters:

```swift
let users = UserQuery(
    active: true,
    email: email,
    roles: roles
)

let prepared = users.prepare(.psql)
```

Because `SQLQuery` is itself `SQLable`, reusable queries compose directly without unwrapping `.query`:

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

The protocol-local `Query` name keeps the concrete carrier out of the normal authoring path. If advanced code genuinely needs an explicit concrete type—for example a function return type or a heterogeneous layer normalized to one SQL carrier—use `SQLContent`. All forms use the same parts/preparation/binding pipeline.

## Migrating from v1 / SwifQL

For most projects, the first migration is intentionally mechanical.

**v1 / Swift 5:**

```swift
.package(url: "https://github.com/SwifQL/SwifQL", from: "1.5.0")
```

```swift
import SwifQL

let query = SwifQL
    .select(...)
    .from(...)
```

**v2 / Swift 6.3+:**

```swift
.package(url: "https://github.com/SwiftStream/SQL", from: "2.0.0")
```

```swift
import SQL

let query = SQL
    .select(...)
    .from(...)
```

The product/module changed from `SwifQL` to `SQL`, and the canonical root changed from `SwifQL.<fluent>` to `SQL.<fluent>`. There is **no compatibility module named `SwifQL`** in v2. After `import SQL`, retained old `SwifQL*` symbol spellings may still compile where a deprecated/renamed bridge is provided, so compiler rename diagnostics can guide the remaining source migration.

For the complete migration checklist and advanced compatibility notes, see [MIGRATION.md](MIGRATION.md).

---

## Historical SwifQL 2 documentation

The material below documents earlier SwifQL 2 releases and remains for historical migration/reference purposes. Examples that use `import SwifQL`, `SwifQL...`, the old product name, or old source paths describe those earlier releases rather than the new canonical SQL module.

SwifQL can be used stand-alone, with frameworks like Vapor and Hummingbird, or with database drivers like SwiftDuckDB and others.

For server-side projects we recommend [Bridges](https://github.com/SwifQL/Bridges), which is built on top of SwifQL and keeps the full flexibility of the query DSL. For iOS and Android we recommend SwiftDuckDB, a driver built on top of SwifQL that brings the same query-building flexibility directly to embedded DuckDB.

It supports PostgreSQL, MySQL, and DuckDB. It's also not hard to add other dialects 🙂 just check [SwifQL/Dialect](https://github.com/SwifQL/SwifQL/tree/master/Sources/SwifQL/Dialect) folder

Please feel free to ask any questions in issues, and also you could find me in the [Discord app](https://discordapp.com) as `@iMike#3049` or even better just join **#swifql** channel on [SwiftStream's Discord server](https://discord.gg/q5wCPYv) 🙂

> NOTE:
>
> If you haven't found some functions available out-of-the-box
> then please check files like `SwifQLable+Select` and others in `Sources/SwifQL` folder
> to ensure how easy it is to extend SwifQL to support anything you need 🚀
>
> And feel free to send pull requests with your awesome new extensions ❤️

### Support SwifQL development by giving a ⭐️

## Historical version guidance

For the earlier SwifQL release line, **1.5.0 was the last stable Swift 5 release**. The later SwifQL 2 beta line moved to Swift 6 and eventually became the SQL 2.0.0 release documented above.

The last SwifQL-named prerelease was **2.0.0-beta.6.1.0**. These examples are retained so existing projects and old release notes remain understandable; new projects should use the SQL 2.0.0 installation at the top of this README.

## Historical installation examples

### Swift 5 / existing Vapor 4 projects

```swift
.package(url: "https://github.com/SwifQL/SwifQL", from: "1.5.0")
```

### Swift 6.3+ / SwifQL 2

```swift
.package(url: "https://github.com/SwifQL/SwifQL", exact: "2.0.0-beta.6.1.0")
```

### With Vapor 4 + [Bridges](https://github.com/SwifQL/Bridges) + PostgreSQL
```swift
.package(url: "https://github.com/vapor/vapor", from:"4.0.0-rc"),
.package(url: "https://github.com/SwifQL/VaporBridges", from:"1.0.0-rc"),
.package(url: "https://github.com/SwifQL/PostgresBridge", from:"1.0.0-rc"),
.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "VaporBridges", package: "VaporBridges"),
    .product(name: "PostgresBridge", package: "PostgresBridge")
]),
```

### With Vapor 4 + [Bridges](https://github.com/SwifQL/Bridges) + MySQL
```swift
.package(url: "https://github.com/vapor/vapor", from:"4.0.0-rc"),
.package(url: "https://github.com/SwifQL/VaporBridges", from:"1.0.0-rc"),
.package(url: "https://github.com/SwifQL/MySQLBridge", from:"1.0.0-rc"),
.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "VaporBridges", package: "VaporBridges"),
    .product(name: "MySQLBridge", package: "MySQLBridge")
]),
```

### Pure
```swift
.package(url: "https://github.com/SwifQL/SwifQL", exact: "2.0.0-beta.6.1.0"),
.target(name: "App", dependencies: [
    .product(name: "SwifQL", package: "SwifQL"),
]),
```

### Pure on NIO2
```swift
.package(url: "https://github.com/SwifQL/SwifQL", exact: "2.0.0-beta.6.1.0"),
.package(url: "https://github.com/SwifQL/SwifQLNIO", from:"2.0.0"),
.target(name: "App", dependencies: [
    .product(name: "SwifQL", package: "SwifQL"),
    .product(name: "SwifQLNIO", package: "SwifQLNIO"),
]),
```

#### Pure on NIO1 (deprecated)
```swift
.package(url: "https://github.com/SwifQL/SwifQL", from:"1.0.0"),
.package(url: "https://github.com/SwifQL/SwifQLNIO", from:"1.0.0"),
.target(name: "App", dependencies: ["SwifQL", "SwifQLNIO"]),
```

#### With Vapor 3 + Fluent (deprecated)
```swift
.package(url: "https://github.com/SwifQL/SwifQL", from:"1.0.0"),
.package(url: "https://github.com/SwifQL/SwifQLVapor", from:"1.0.0"),
.target(name: "App", dependencies: ["Vapor", "SwifQL", "SwifQLVapor"]),
```

## Declarative Table DDL

SwifQL `2.0.0-beta.6.1.0` adds a small SQL-shaped declarative surface for table creation and alteration.

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

To add columns, build one `ALTER TABLE` statement:

```swift
let alterUsers = AlterTable("users") {
    AddColumn("display_name", .text)
}

alterUsers.prepare(.psql).plain
```

will give:

```sql
ALTER TABLE "users" ADD COLUMN "display_name" text
```

Table, schema, and column identifiers are explicit strings so historical DDL declarations do not change when current model metadata changes. These builders are intentionally static and non-empty, and `AlterTable` always represents one SQL `ALTER TABLE` statement. SwifQL only builds the SQL; migration versioning, history, transactions, and execution remain the consuming library or application's responsibility.

## Shared Semantic Values

SwifQL `2.0.0-beta.6.0.0` first published four shared value types for database-facing civil and interval semantics: `PureDate`, `PureTime`, `DateTime`, and `Interval`. The `2.0.0-beta.6.0.1` hotfix keeps the same SQL/API behavior and aligns the Swift tools floor with the validated Swift 6.3 line.

```swift
let date = PureDate(year: 2026, month: 9, day: 4)!
let time = PureTime(hour: 12, minute: 34, second: 56, nanosecond: 123_456_789)!
let timestamp = DateTime(
    year: 2026,
    month: 9,
    day: 4,
    hour: 12,
    minute: 34,
    second: 56,
    nanosecond: 123_456_789
)!
let interval = Interval(months: 2, days: -3, microseconds: 4)

SwifQL.select(date, time, timestamp, interval).prepare(.psql).plain
```

will give:

```sql
SELECT DATE '2026-09-04', TIME '12:34:56.123456789', TIMESTAMP '2026-09-04 12:34:56.123456789', INTERVAL '2 months -3 days 4 microseconds'
```

- `PureDate` is a proleptic-Gregorian civil date with astronomical `Int64` years, including canonical year zero/BCE and extended-year spellings such as `+10000-01-01`. It has finite and explicit positive/negative infinity states, no time zone, and is not an instant; its explicit `Foundation.Date` conversion requires a Gregorian `Calendar` and `TimeZone` and can fail.
- `PureTime` is nanosecond-capable time of day, not a duration. Its domain is `00:00:00` through the distinct `24:00:00` endpoint; leap second `60` is rejected.
- `DateTime` combines a timezone-free `PureDate` and `PureTime`. It has finite and explicit positive/negative infinity states, is not `Foundation.Date`, and exact `24:00:00` input becomes the following date's midnight. Foundation conversion requires an explicit Gregorian calendar and time zone.
- `Interval` keeps independent months, days, and microseconds, including explicit positive/negative infinity states. Mixed signs are allowed, it is not `Comparable` or a fixed `TimeInterval`, and exact `Duration` conversion is available only when months and days are zero.

The four values use the ordinary SwifQL value/binding path, so `.splitted.values` preserves the original Swift values and their traversal order. `PureDate` and `PureTime` infer `.date` and `.time`; `Foundation.Date` remains `.timestamptz`. `DateTime` and `Interval` retain the historical `.text` fallback, so use explicit `.timestamp` or `.interval` schema types when that contract is intended.

Dialect output is intentionally exact rather than universal. PostgreSQL and Duck preserve nanosecond lexical values in their supported forms; MySQL emits only finite values and precisions it can represent exactly, and fails closed for unsupported years, special states, or non-microsecond nanoseconds. Duck's `TIMESTAMP_NS` still has a finite physical range, and shared interval infinity values are not native Duck interval infinity.

## Philosophy

This lib gives an ability to build absolutely any SQL query from simplest to monster complex.

Example of simple query
```sql
SELECT * FROM "User" WHERE "email" = 'john.smith@gmail.com'
```
build it with pure SwifQL this way
```swift
SwifQL.select(User.table.*).from(User.table).where(\User.email == "john.smith@gmail.com")
```
or with SwifQL + [Bridges](https://github.com/SwifQL/Bridges)
```swift
SwifQL.select(User.table.*).from(User.table).where(\User.$email == "john.smith@gmail.com")
// or shorter
User.select.where(\User.$email == "john.smith@gmail.com")
```

## Usage

### Preparation

> 💡 TIP: It is simpler and more powerful with [Bridges](https://github.com/SwifQL/Bridges)

Of course you have to import the lib
```swift
import SwifQL
```

#### For v1 Your table models should be conformed to `Tableable` protocol
```swift
extension MyTable: Tableable {}
```

#### For v2 Your table models should be conformed to `Table` protocol
```swift
extension MyTable: Table {}
```

### How to build query

> Instead of writing `Model.self` you should write `Model.table`, cause without Vapor you should conform your models to `Table`, and with Vapor its `Model`s are already conforms to `Table`.

```swift
let query = SwifQL.select(\User.email, \User.name, \User.role)
                  .from(User.table)
                  .orderBy(.asc(\User.name))
                  .limit(10)
```
or with SwifQL + [Bridges](https://github.com/SwifQL/Bridges)
```swift
let query = SwifQL.select(\User.$email, \User.$name, \User.$role)
                  .from(User.table)
                  .orderBy(.asc(\User.$name))
                  .limit(10)
// or shorter
User.select(\.$email, \.$name, \.$role).orderBy(.asc(\User.$name)).limit(10)
```

### How to print raw query

There are two options

##### 1. Get just plain query
```swift
let rawSQLString = query.prepare(.psql).plain
```

or when using SwifQLSelectBuilder() - see below

```swift
let rawSQLBuilderString = query.build().prepare(.psql).plain
```

##### 2. Get object splitted into: formatted raw SQL string with $ symbols, and separated array with values
```swift
let splittedQuery = query.prepare(.psql).splitted
let formattedSQLQuery = splittedQuery.query // formatted raw SQL string with $ symbols instead of values
let values = splittedQuery.values // an array of [Encodable] values
```

Then just put it into your database driver somehow 🙂 or use [Bridges](https://github.com/SwifQL/Bridges)

### How to execute query?

SwifQL is only about building queries. For execution you have to use your favourite database driver.

Below you can see an example for SwifQL + Vapor4 + [Bridges](https://github.com/SwifQL/Bridges) + PostgreSQL

> 💡 You can get connection on both `Application` and `Request` objects.

Example for `Application` object e.g. for `configure.swift` file
```swift
// Called before your application initializes.
public func configure(_ app: Application) throws {
    app.postgres.connection(to: .myDb1) { conn in
        SwifQL.select(User.table.*).from(User.table).execute(on: conn).all(decoding: User.self).flatMap { rows in
            print("yaaay it works and returned \(rows.count) rows!")
        }
    }.whenComplete {
        switch $0 {
        case .success: print("query was successful")
        case .failure(let error): print("query failed: \(error)")
        }
    }
}
```
Example for `Request` object
```swift
func routes(_ app: Application) throws {
    app.get("users") { req -> EventLoopFuture<[User]> in
        req.postgres.connection(to: .myDb1) { conn in
            SwifQL.select(User.table.*).from(User.table).execute(on: conn).all(decoding: User.self)
        }
    }
}
```

> 💡 In examples above we use `.all(decoding: User.self)` for decoding results, but we also can use `.first(decoding: User.self).unwrap(or: Abort(.notFound))` to get only first row and unwrap it since it may be nil.

## Insert Into

### Single record
SQL example
```sql
INSERT INTO "User" ("email", "name") VALUES ('john@gmail.com', 'John Doe'), ('sam@gmail.com', 'Samuel Jackson')
```
SwifQL representation
```swift
SwifQL.insertInto(User.table, fields: \User.email, \User.name).values("john@gmail.com", "John Doe")
```
or with SwifQL + [Bridges](https://github.com/SwifQL/Bridges)
```swift
User(email: "john@gmail.com", name: "John Doe").insert(on: conn)
```

### Batch
SQL example
```sql
INSERT INTO "User" ("email", "name") VALUES ('john@gmail.com', 'John Doe'), ('sam@gmail.com', 'Samuel Jackson')
```
SwifQL representation
```swift
SwifQL.insertInto(User.table, fields: \User.email, \User.name).values(array: ["john@gmail.com", "John Doe"], ["sam@gmail.com", "Samuel Jackson"])
```
or with SwifQL + [Bridges](https://github.com/SwifQL/Bridges)
```swift
let user1 = User(email: "hello@gmail.com", name: "John")
let user2 = User(email: "byebye@gmail.com", name: "Amily")
let user3 = User(email: "trololo@gmail.com", name: "Trololo")
[user1, user2, user3].batchInsert(on: conn)
```
## Update

### General Update
SQL example
```sql
UPDATE "User" SET "name" = 'Mike'
```
SwifQL representation
```swift
SwifQL.update(User.table).set[items: User.$name == "Mike"]
```

### In Schema Update
SQL example
```sql
UPDATE "VIP"."User" SET "name" = 'Mike'
```
SwifQL representation
```swift
let vip = User.inSchema("VIP")
SwifQL.update(vip.table).set[items: vip.$name == "Mike"]
```

## Builders

For now there are only one implemented builder

### Select builder

`SwifQLSelectBuilder` - by using it you could easily build a select query but in multiple lines without carying about ordering.

```swift
let builder = SwifQLSelectBuilder()
builder.where(\User.id == 1)
builder.from(User.table)
builder.limit(1)
builder.select(User.table.*)
let query = builder.build()
return query.execute(on: req, as: .psql)
            .first(decoding: User.self)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
```

So it will build query like: `SELECT "User".* FROM "User" WHERE "User"."id" = 1 LIMIT 1`.

As you can see you shouldn't worry about parts ordering, it will sort them the right way before building.

### More builders

Feel free to make your own builders and send pull request with it here!

Also more conveniences are available in [Bridges](https://github.com/SwifQL/Bridges) lib which is created on top of SwifQL and support all its flexibility

## More query examples

*Let's use `SwifQLSelectBuilder` for some next examples below, cause it's really convenient especially for complex queries.*

1. Let's imagine that you want to query count of users.

```swift
/// Just query
let query = SwifQL.select(Fn.count(\User.id) => "count").from(User.table)

/// Execution and decoding for Vapor
struct CountResult: Codable {
  let count: Int64
}
query.execute(on: req, as: .psql)
     .first(decoding: CountResult.self)
     .unwrap(or: Abort(.notFound)) // returns Future<CountResult>
```

Here you can see two interesting things: `Fn.count()` and `=> "count"`

`Fn` is a collection of function builders, so just call `Fn.` and take a look at the functions list on autocompletion.

`=>` uses for two things: 1) to write alias through `as` 2) to cast values to some other types

`// TBD: Expand list of examples`

## Aliasing
Use `=>` operator for that, e.g.:

If you want to write `SELECT "User"."email" as eml` then do it like this `SwifQL.select(\User.email => "eml")`

Or if to speak about table name aliasing:

If you want to reach `"User" as u` then do it like this `User.as("u")`

And then keypaths will work like

```swift
let u = User.as("u")
let emailKeypath = u.email
```

## Type casting
Use `=>` operator for that, e.g.:

If you want to write `SELECT "User"."email"::text` then do it like this `SwifQL.select(\User.email => .text)`

## Predicates
| Infix operator  | SQL equivalent |
| ------- | -------------- |
| > | > |
| >= | >= |
| < | < |
| <= | <= |
| == | = |
| == nil | IS NULL |
| != | != |
| != nil | IS NOT NULL |
| && | AND |

And also

`||` is for `OR`

`||>` is for `@>`

`<||` is for `<@`

> Please feel free to add more predicates in `Predicates.swift` 😉

## Operators
Please feel free to take a look at `Fn.Operator` enum in `Functions.swift`

## Functions
Please feel free to take a look at the list of function in `Functions.swift`

## Postgres JSON Object
You could build JSON objects by using `PostgresJsonObject`

SQL example
```sql
jsonb_build_object('id', "User"."id", 'email', "User"."email")
```
SwifQL representation
```swift
PgJsonObject().field(key: "id", value: \User.id).field(key: "email", value: \User.email)
```

## Postgres Array
You could build PostgreSQL arrays by using `PostgresArray`

SQL example
```sql
$$[]$$
ARRAY[]
ARRAY[1,2,3]
$$[]$$::uuid[]
ARRAY[]::text[]
```
SwifQL representation
```swift
PgArray(emptyMode: .dollar)
PgArray()
PgArray(1, 2, 3)
PgArray(emptyMode: .dollar) => .uuidArray
PgArray() => .textArray
```

Postgress range query examples
```swift
// var ingredients: [IngredientsEnum] 
SwifQL.select(FoodMenu.table.*).WHERE( \FoodMenu.$ingredients ||> [.tomato] )

// var ingredients: [String]
SwifQL.select(FoodMenu.table.*).WHERE( \FoodMenu.$ingredients ||> PgArray(["tomato"]) )

// var vendors: [UUID]
SwifQL.select(FoodMenu.table.*).WHERE( \FoodMenu.$vendors ||> PgArray([vendorUuid]) )
```

## Nesting array of objects inside of query result
Consider such response object you want to achieve:

```swift
struct Book {
  let title: String
  let authors: [Author]
}

struct Author {
  let name: String
}
```

you have to build it with use of subquery to dump Authors in JSON array and then attach them to result query. This will allow you to get all `Books` with their respective `Authors` 

This example uses Pivot table `BookAuthor` to join `Books` with their `Authors`

```swift
    let authors = SwifQL.select(Fn.coalesce(Fn.array_agg(Fn.to_jsonb(Author.table)), PgArray() => .jsonbArray))

    let query = SwifQLSelectBuilder()
    query.select(Book.table.*)

    query.from(Book.table)

    query.join(.left, BookAuthor.table, on: \Book.$id == \BookAuthor.$bookID)
    query.join(.left, Author.table, on: \Author.$id == \BookAuthor.$authorID)

    // then query.group(...) as required in your case
```

## FILTER
SQL example
```sql
COUNT("User"."id") FILTER (WHERE \User.isAdmin = TRUE) as "admins"
```
SwifQL representation
```swift
Fn.count(\User.id).filter(where: \User.isAdmin == true) => "admins"
```

## CASE ... WHEN ... THEN ... END
SQL example
```sql
CASE
  WHEN "User"."email" IS NULL
  THEN NULL
  ELSE "User"."email"
END
```
SwifQL representation
```swift
Case.when(\User.email == nil).then(nil).else(\User.email).end
// or as many cases as needed
Case.when(...).then(...).when(...).then(...).when(...).then(...).else(...).end
```

## Brackets

Yes, we really often use round brackets in our queries, e.g. in where clauses or in subqueries.

SwifQL provides you with `|` prefix and postfix operators which is representates `(` and `)`.

So it's easy to wrap some part of query into brackets, e.g.:
SQL example
```sql
"User.role" = 'admin' OR ("User.role" = 'user' AND "User"."age" >= 21)
```
SwifQL representation
```swift
let where = \User.role == .admin || |\User.role == .user && \User.age >= 21|
```

## Keypaths
| SQL | SwiftQL | SwiftQL + Bridges |
| ------- | -------------- | -------------- |
| `"User"` | `User.table` | `the same` |
| `"User" as u` | `User.as("u")` you could declare it as `let u = User.as("u")` | `the same` |
| `"User".*` | `User.table.*` | `the same` |
| `u.*` | `u.*` | `the same` |
| `"User"."email"` | `\User.email` | `\User.$email` |
| `u."email"` | `u.email` | `u.$email` |
| `"User"."jsonObject"->"jsonField"` | `\User.jsonObject.jsonField` | `only through full path for now` |
| `"User"."jsonObject"->"jsonField"` | `Path.Table("User").column("jsonObject", "jsonField")` | `the same` |

## Tests

For now tests coverage is maybe around 70%. If you have timе and interest please feel free to send pull requests with more tests.

You could find tests in `Tests` folder

### How it works under the hood

`SwifQL` object needed just to start writing query, but it's just an empty object that conforms to `SwifQLable`.

You can build your query with everything which conforms to `SwifQLable`, because `SwifQLable` is that very piece which will be used for concatenation to build a query.

> If you take a look at the lib's files you may realize that the most of files are just extensions to `SwifQLable`.

All available operators like `select`, `from`, `where`, and `orderBy` realized just as a function in `SwifQLable` extension and these functions always returns `SwifQLable` as a result. That's why you can write a query by calling `SwifQL.select().from().where().orderBy()` one by one. That's awesome cause it feels like writing a raw SQL, but it also gives you an ordering limitation, so if you write `SwifQL.select().where().from()` then you'll get wrong query as a result. But this limitation is resolved by using special builders, like `SwifQLSelectBuilder` (read about it later below).

So let's take a look how lib builds a simple `SELECT "User".* FROM "User" WHERE "User"."email" = 'john.smith@gmail.com'` query

First of all we should split query into the parts. Almost every word and punctuation here is a `SwifQLable` piece.

- `SELECT` is `Fn.Operator.select`
- ` ` is `Fn.Operator.space`
- `"User"` is `User.table`
- `.*` is `postfix operator .*`
- ` ` is `Fn.Operator.space`
- `FROM` is `Fn.Operator.from`
- `"User"` is `User.table`
- ` ` is `Fn.Operator.space`
- `WHERE` is `Fn.Operator.where`
- ` ` is `Fn.Operator.space`
- `"User"."email"` is `\User.email` keypath
- ` ` is `Fn.Operator.space`
- `==` is `infix operator ==`
- ` ` is `Fn.Operator.space`
- `'john.smith@gmail.com'` is `SwifQLPartUnsafeValue` (it means that this value should be passed as $1 to the database)

That's crazy, but awesome, right? 😄 But it's under the hood, so no worries! 😃 I just wanted to explain, that if you need something more than already provided then you'll be able to add needed operators/functions easily just by writing little extensions.

> And also there is no overhead, it works pretty fast, but I'd love to hear if you know how to make it faster.

This way gives you almost absolute flexibility in building queries. More than that as lib support `SQLDialect`'s it will build this query different way for PostgreSQL and MySQL, e.g.:

- PostgreSQL: `SELECT "User".* FROM "User" WHERE "User"."email" = 'john.smith@gmail.com'`
- MySQL: `SELECT User.* FROM User WHERE User.email = 'john.smith@gmail.com'`

## Contributing

Please feel free to contribute!
