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
5. Keep ordinary dynamic or untrusted values on SQL's normal value path. Do not interpolate them into raw/custom SQL structure.
6. Prepare using the actual target dialect supported by the installed version: `.psql`, `.mysql`, or `.duck` when available there.
7. Use `.plain` to inspect rendered SQL with values formatted inline. Use `.splitted` for driver-facing SQL plus the ordered bind values.
8. Stop after construction and preparation. SQL builds SQL; database execution belongs to a driver or an integration layer such as Bridges.

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
let query = SQL.root
    .select(User.table.*)
    .from(User.table)
    .where(\User.email == email)

let prepared = query.prepare(.psql)
let inspectionSQL = prepared.plain
let driverSQL = prepared.splitted.query
let bindValues = prepared.splitted.values
```

The runtime `email` must remain a value/bind input. Do not rewrite it into raw SQL merely to reproduce a desired string.

When translating SQL to the DSL, preserve statement structure first, then verify the prepared output and bind order for the target dialect. If the installed version does not expose a clean API for an uncommon construct, inspect that version's source/tests and use only APIs that actually exist rather than guessing a newer or dialect-specific helper.
