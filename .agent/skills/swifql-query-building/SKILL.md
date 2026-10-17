---
name: swifql-query-building
description: Build, translate, review, or prepare SQL in downstream Swift code that imports SQL. The skill package keeps its historical routing identifier, but its canonical API target is the SQL module.
license: LICENSE.txt
---

# Build Queries with SQL

Use this workflow for downstream code that consumes the canonical `SQL` module.

1. Determine the SQL package version the consumer actually uses. Check `Package.swift`, `Package.resolved`, the resolved checkout, or installed source as appropriate. Do not assume the latest API exists.
2. Start from the SQL you intend to express. Keep the SQL DSL call site SQL-shaped rather than inventing a separate abstraction first.
3. For uncommon or version-sensitive syntax, inspect the installed SQL source and tests before choosing an API. Do not invent symbols from memory.
4. Classify every input as SQL structure or dynamic data. Identifiers, clauses, operators, and deliberately modeled syntax are structure; ordinary runtime values are data.
5. Keep ordinary dynamic or untrusted values on SQL's normal value/bind path. If the resolved package version exposes bind-aware `SQLRaw` and explicit raw structure is genuinely required, runtime value data may use labeled `\(bind:)` interpolation inside that raw fragment. Never use ordinary Swift/String interpolation to splice runtime data into raw SQL text, and never bind identifiers or SQL structure as data.
6. Prepare using the actual target dialect supported by the installed version: `.psql`, `.mysql`, or `.duck` when available there.
7. Use `.plain` to inspect rendered SQL with values formatted inline. Use `.splitted` for driver-facing SQL plus the ordered bind values.
8. Stop after construction and preparation. SQL builds SQL; database execution belongs to a driver or an integration layer such as Bridges.

For explicit structural identifiers, current `master` uses the canonical `DB.*` namespace. If the resolved consumer is on SQL 2.x, use the structural API actually present in that version rather than backporting newer names.

For exact symbolic binary SQL, use the installed version's grouped operator escape when available instead of concatenating a raw expression:

```swift
let predicate = lhs.op(.custom("@?"), rhs)
```

The token is deliberate SQL structure and the right-hand side keeps its ordinary SQLable preparation and binding behavior. The `@?` token is PostgreSQL syntax; the `.op` composition primitive itself is generic.

For SQL/JSON, verify the owner against the target dialect rather than assuming that matching function names are portable. In SQL 2.2, the validated boundary is:

- PostgreSQL: `JSONExists`, `JSONValue`, and `JSONQuery`, with PostgreSQL-owned option grammar such as `Passing(...)`;
- DuckDB: `JSONExists` and `JSONValue` with bound paths, without PostgreSQL option grammar;
- MySQL: `JSONValue` / `JSON_VALUE` only.

Runtime paths remain data. On MySQL 8.4, a runtime Swift `String` path stays bound but the native JSON_VALUE grammar rejects that parameter position. Do not turn runtime path bytes into SQL text to work around it. A fixed trusted path can be supplied explicitly as SQL structure when that is genuinely what the application owns:

```swift
let value = JSONValue(document, SQL.raw("'$.name'"))
```

That raw fragment is static caller-owned structure. In package versions that expose bind-aware `SQLRaw`, labeled `\(bind:)` is available for runtime **value** positions inside intentionally raw SQL, but it does not make a parameter legal in grammar positions that the target database rejects. SQL/JSON option and direct `DefaultOnEmpty` behavior is owner- and dialect-specific; do not generalize it into an arbitrary value-literalization rule.

For civil and interval data, choose the semantic type that matches the value:

- `PureDate` for a timezone-free civil date;
- `PureTime` for nanosecond-capable time of day, not an elapsed duration;
- `DateTime` for a timezone-free civil date and time;
- `Interval` for structural months/days/microseconds, not a flattened `TimeInterval`.

Keep `Foundation.Date` for instant / `TIMESTAMPTZ` semantics. Historical SwifQL 2 releases introduced the shared semantic values beginning with `2.0.0-beta.6.0.0`; current consumers must inspect the resolved package version before assuming availability. `DateTime` and `Interval` retain `.text` automatic inference, so use explicit schema types when `.timestamp` or `.interval` is the intended contract. Verify the target dialect's supported range and precision before assuming portability; MySQL is exact-or-hard-fail and Duck `TIMESTAMP_NS` and interval special states have important boundaries.

A representative downstream query follows the same shape as its SQL:

```swift
import SQL

let email = inputEmail
let query = SQL
    .select(User.table.*)
    .from(User.table)
    .where(\User.email == email)

let prepared = query.prepare(.psql)
let inspectionSQL = prepared.plain
let driverSQL = prepared.splitted.query
let bindValues = prepared.splitted.values
```

Use direct `SQL.<fluent>` for fluent construction and `SQL { ... }` for declarative construction. Name `SQLContent` only when an explicit concrete formed-SQL type is required; ordinary query examples should normally rely on inference. For reusable `SQLQuery` conformers, prefer the protocol-local `var query: Query { ... }` spelling rather than writing `SQLContent` at the witness.

The runtime `email` must remain a value/bind input. Prefer the typed DSL value path. If an unsupported surrounding construct genuinely requires raw SQL and the installed version exposes `SQLRaw`, keep the structure trusted/static and interpolate only the value as `\(bind: email)`; never use ordinary String interpolation merely to reproduce a desired SQL string.

For package versions that expose aggregate argument builders, keep aggregate-local grammar inside the function call rather than falling back to raw SQL. The ordinary argument body accepts normal `SQLable` expressions, including existential values such as `SQL.asterisk`. Use `Distinct { ... }` for aggregate DISTINCT ownership, and keep aggregate-local `OrderBy(...)` as a sibling after the ordinary arguments or after `Distinct`, never inside the `Distinct { ... }` body:

```swift
let value: any SQLable = DB.Column("value")

let aggregate = Fn.arrayAgg {
    Distinct {
        value
    }
    OrderBy(value, .desc)
}
```

Existing concise aggregate overloads remain valid. `Fn.count()` renders `count(*)`; `Fn.count { SQL.asterisk }` also renders `count(*)`; an empty builder body `Fn.count {}` renders `count()`. Verify these spellings against the resolved package version before using them.

When translating SQL to the DSL, preserve statement structure first, then verify the prepared output and bind order for the target dialect. If the installed version does not expose a clean API for an uncommon construct, inspect that version's source/tests and use only APIs that actually exist rather than guessing a newer or dialect-specific helper.
