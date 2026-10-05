---
name: swifql-sql-conversion
description: Convert raw SQL or legacy SwifQL call sites into canonical SQL DSL representations using the installed package's actual APIs, dialect, preparation, and bind behavior.
license: LICENSE.txt
---

# Convert SQL into the SQL DSL

Use this workflow when downstream Swift code starts from raw SQL text or an older SwifQL call site and needs a canonical representation for the installed `SQL` package.

This skill is a conversion procedure. It is not a SQL parser, AST, renderer, database executor, or source-library modification workflow.

## When to use

Use this skill for tasks such as:

- convert a raw SQL statement into `SQL { ... }`;
- convert a raw SQL statement into direct fluent `SQL.<fluent>`;
- provide both declarative and fluent forms for comparison;
- migrate a legacy SwifQL call site to the canonical `SQL` module/API;
- explain which part of an uncommon statement has typed/declarative coverage and which part must remain an explicit raw structural boundary.

For ordinary query construction that does not begin from raw SQL or legacy SwifQL, use the general query-building procedure instead.

## 1. Resolve the actual package before translating

Determine the SQL package version and source the consumer really uses.

Inspect, as appropriate:

- `Package.swift`;
- `Package.resolved`;
- the resolved checkout;
- installed source and tests;
- the migration guide supplied by that version.

Do not assume the repository's current HEAD APIs exist in an older resolved package.

The current canonical major-version shape is:

```swift
import SQL

let fluent = SQL
    .select(...)
    .from(...)

let declarative = SQL {
    Select { ... }
    From { ... }
}
```

`SQLContent` is the concrete fragment/result carrier when an explicit concrete type is required. It is not the fluent root spelling.

Do not target `SQL.root`.

## 2. Choose the target dialect

Identify the intended preparation dialect before choosing syntax:

- `.psql` for PostgreSQL;
- `.mysql` for MySQL;
- `.duck` for DuckDB;

when those dialects exist in the resolved package version.

If the caller does not specify a dialect and the SQL contains vendor-specific syntax, state the dialect assumption before converting.

Do not create a false portability facade. Preserve vendor-specific semantics instead of silently translating them to a different construct.

## 3. Preserve the SQL structure first

Before writing Swift, identify:

- statement family;
- clause order;
- projections;
- sources and aliases;
- joins and join predicates;
- filters;
- grouping/having;
- windows/qualification when present;
- ordering;
- pagination;
- nesting/subqueries;
- set operations;
- DML/DDL structure;
- dialect-specific syntax.

Preserve the input's semantic structure. Do not "simplify" a vendor-specific form into something merely similar.

## 4. Separate structure from data

Treat these as SQL structure:

- table/schema/column identifiers;
- SQL clauses and keywords;
- operators;
- ordering directions;
- static dialect syntax;
- deliberately modeled structural fragments.

Treat these as data:

- user input;
- runtime scalar values;
- runtime dates/times;
- runtime list elements used as values;
- other untrusted or dynamic values.

Dynamic or untrusted data must stay on the ordinary SQL value/bind path.

Never move runtime data into `SQL.raw(...)` merely to reproduce the original SQL text.

A literal embedded in the source SQL may legitimately become a Swift value and therefore a bind. Preserve semantics, not necessarily the original quoting bytes.

## 5. Choose declarative, fluent, or raw structural output

Prefer the declarative form when the installed package exposes a verified builder for the construct:

```swift
SQL {
    Select { ... }
    From { ... }
    Where { ... }
}
```

Use direct fluent composition when:

- the caller asks for fluent output;
- the construct is verified in the fluent/core API but not in the declarative layer;
- a concise fluent representation is clearer.

The fluent root is the direct global `SQL` value:

```swift
SQL
    .select(...)
    .from(...)
    .where(...)
```

For uncommon or version-sensitive syntax, inspect installed source/tests before choosing a helper.

If no verified declarative helper exists but the fluent/core API supports the construct, return the fluent/core form and say that declarative coverage is unavailable in that resolved version.

If no typed/core representation exists, keep only the unsupported **static structure** in the existing raw structural escape hatch, for example `SQL.raw("...")` or an existing query's `.raw("...")`, and clearly label that boundary.

Do not invent a DSL symbol.

### What to return

For a conversion request, return only the representations the caller actually needs. When useful, include:

- target dialect or explicit assumption;
- canonical declarative form;
- canonical direct fluent/raw form;
- runtime value/bind mapping;
- preparation/verification snippet;
- an explicit unsupported/deferred boundary.

If the caller asks for only declarative or only fluent output, do not force both forms.

## 6. Identifier policy

If the consumer already has verified typed model/table metadata, use it.

If no model metadata is available, do not invent types such as `User.table` or `User.$id`.

Use explicit structural identifiers from the installed API, for example:

```swift
let users = Path.Table("users")
let id = Path.Column("id")
let email = Path.Column("email")
```

Use table-qualified paths when the SQL requires qualification.

## 7. Worked conversion example

Raw SQL:

```sql
SELECT id, email AS email_address
FROM users
WHERE email = $1
ORDER BY created_at DESC
LIMIT 100
```

Assume PostgreSQL and a runtime value:

```swift
let email = inputEmail
let users = Path.Table("users")
```

Canonical declarative form:

```swift
import SQL

let query = SQL {
    Select {
        Path.Column("id")
        Path.Column("email").as("email_address")
    }

    From {
        users
    }

    Where {
        Path.Column("email") == email
    }

    OrderBy(Path.Column("created_at"), .desc)
    Limit(100)
}
```

Canonical direct fluent form:

```swift
import SQL

let query = SQL
    .select(
        Path.Column("id"),
        Path.Column("email").as("email_address")
    )
    .from(users)
    .where(Path.Column("email") == email)
    .orderBy(.desc(Path.Column("created_at")))
    .limit(100)
```

The runtime `email` stays a value input. Do not interpolate runtime or untrusted data into a raw SQL string merely to reproduce the original text.

Prepare and inspect using the target dialect:

```swift
let prepared = query.prepare(.psql)

let inspectionSQL = prepared.plain
let driverSQL = prepared.splitted.query
let bindValues = prepared.splitted.values
```

Verify both SQL shape and bind ordering.

## 8. Unsupported or version-sensitive syntax

For a construct you do not recognize confidently:

1. identify the resolved package version;
2. search that version's source and tests for the SQL family/operator/clause;
3. prefer the existing typed/declarative API when it exists;
4. otherwise prefer existing fluent/core composition;
5. otherwise use a clearly marked static raw structural boundary;
6. keep all dynamic data outside raw structure;
7. prepare the result for the target dialect and inspect `.plain` plus `.splitted`.

Do not infer an API from another SQL library, from a newer release, or from the database documentation alone.

Database documentation tells you which SQL exists. Installed SQL package source/tests tell you which Swift representation actually exists.

## 9. Legacy SwifQL migration

For old call sites, migrate toward the installed canonical SQL surface rather than blindly renaming text.

Typical current migration shape:

```swift
// Legacy spelling:
let oldQuery = SwifQL
    .select(Path.Column("id"))
    .from(Path.Table("users"))

// Canonical spelling:
let query = SQL
    .select(Path.Column("id"))
    .from(Path.Table("users"))
```

Canonical module import is:

```swift
import SQL
```

Do not migrate to `SQL.root`.

When an explicit concrete result type is necessary, use `SQLContent` in versions where that is the current carrier.

Some historical SwifQL-prefixed declarations may remain as deprecated in-module compatibility in particular versions. Consult that version's `MIGRATION.md`, source, and tests for symbol-specific renames.

Do not blindly replace every `SwifQL` prefix: some historical names may map to differently named canonical declarations, may be intentionally retained, or may not exist in the resolved version.

## 10. Reusable SQLQuery output

When the converted statement belongs in a reusable parameterized query component and the resolved version supports the current `SQLQuery` API, prefer its protocol-local `Query` shorthand rather than exposing the concrete carrier unnecessarily.

Current canonical shape:

```swift
struct ActiveUserQuery: SQLQuery {
    let email: String

    var query: Query {
        Select {
            Path.Column("id")
            Path.Column("email")
        }

        From {
            Path.Table("users")
        }

        Where {
            Path.Column("email") == email
        }
    }
}
```

Do not repeat `@SQLBuilder` on the ordinary conformer witness merely because the protocol requirement carries the builder attribute.

## 11. Verification checklist

Before presenting the conversion, verify:

- the target dialect or assumption is explicit;
- every Swift symbol exists in the resolved package;
- statement structure and vendor semantics are preserved;
- runtime/untrusted values are not interpolated into raw structure;
- declarative output uses only verified builders;
- fluent output starts from direct `SQL`, not `SQL.root`;
- `SQLContent` is used only when concrete typing is needed;
- `.plain` renders the expected statement shape;
- `.splitted.query` has the expected placeholders;
- `.splitted.values` preserves the expected bind order;
- unsupported syntax is labeled rather than hidden behind an invented helper.

## 12. Stop conditions

Stop and inspect source/tests instead of guessing when:

- the requested SQL syntax is uncommon or vendor-specific;
- the consumer is pinned to an older version;
- a symbol remembered from another version is not found;
- declarative and fluent APIs differ materially;
- the raw fallback would need to contain runtime/untrusted data;
- exact bind order is unclear;
- conversion would require modifying the SQL package itself.

This skill stops at construction and preparation. Database execution belongs to a driver or integration layer.

## Maintenance rule

This skill intentionally does not claim complete SQL grammar coverage.

Every later accepted query-surface wave must perform a conversion-skill impact check. Update this skill in that wave's docs/skills closure when canonical constructs or spellings change. If the existing procedure remains correct, record `NO_CHANGE` rather than editing it gratuitously.
