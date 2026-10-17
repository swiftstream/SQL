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

The current SQL 2.1+ canonical shape is:

```swift
import SQL

let fluent = SQL
    .select(\User.$id, \User.$email)
    .from(User.table)

let declarative = SQL {
    Select(\User.$id, \User.$email)
    From(User.table)
}
```

For resolved SQL 2.0.x packages, verify the exact declarative overloads from that version before using 2.1 concise clause forms.

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

Dynamic or untrusted data must stay on an explicit SQL value/bind path.

Prefer the typed/declarative/fluent value path. If the resolved package exposes bind-aware `SQLRaw` and the surrounding SQL must remain an explicit raw structural fragment, runtime **value** data may use labeled `\(bind:)` interpolation. Never use ordinary Swift/String interpolation to splice runtime data into raw SQL text, and never bind identifiers/operators/clauses as data.

A literal embedded in the source SQL may legitimately become a Swift value and therefore a bind. Preserve semantics, not necessarily the original quoting bytes.

### Exact operators and SQL/JSON

When the installed version exposes the exact grouped binary-operator primitive, map a fixed vendor operator directly instead of reconstructing the whole expression as raw SQL. For example, PostgreSQL JSON-path match syntax can be represented as:

```swift
let expression = lhs.op(.custom("@?"), rhs)
```

The operator token is fixed SQL structure. Runtime values used by either operand continue through normal SQLable preparation and binding.

For SQL/JSON, choose the owner and options from the target dialect's verified capability rather than translating by name resemblance:

- PostgreSQL supports `JSONExists`, `JSONValue`, and `JSONQuery`, including PostgreSQL-owned option grammar such as `Passing(...)`;
- DuckDB supports `JSONExists` and `JSONValue` with bound paths, but not PostgreSQL SQL/JSON options or `JSONQuery`;
- MySQL supports `JSONValue` / `JSON_VALUE` in the verified SQL 2.2 surface.

On MySQL 8.4, a runtime Swift `String` path remains a bind value and is rejected by the native parser in that path position. Do not "fix" the conversion by interpolating runtime path data into raw SQL. If the original SQL contains a genuinely fixed trusted path, it may remain explicit structure:

```swift
let value = JSONValue(document, SQL.raw("'$.name'"))
```

This example is a static structural boundary. A bind-aware raw API, when available, does not make a placeholder valid in a SQL grammar position that the target database rejects; for example, it does not turn MySQL JSON_VALUE path positions into bindable positions. SQL/JSON DEFAULT behavior is owner- and dialect-specific and must not be generalized into arbitrary runtime literalization.

For PostgreSQL range/multirange SQL, prefer the installed exact PostgreSQL helpers such as `Fn.isEmpty(...)`, `Fn.rangeMerge(...)`, `Fn.rangeAgg { ... }`, and grouped `.op(.custom(...), ...)` forms when source/tests verify the requested construct. Do not project those APIs as portable MySQL or DuckDB range support.

## 5. Choose declarative, fluent, or raw structural output

Prefer the declarative form when the installed package exposes the verified construct. For SQL 2.1+, fixed clauses should normally use the concise spelling:

```swift
SQL {
    Select(\User.$id, \User.$email)
    From(User.table)
    Where(\User.$active == true)
}
```

Use the clause result-builder spelling when multiple children, optionals, conditions, or loops make it clearer:

```swift
SQL {
    Select(\User.$id, \User.$email)
    From(User.table)

    Where {
        \User.$active == true

        if let email {
            \User.$email == email
        }
    }
}
```

Concise and builder forms are one DSL and must preserve the same SQL/preparation/bind semantics.

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

If no typed/core representation exists, keep only the unsupported **SQL structure** in the raw structural escape hatch and clearly label that boundary. For fixed structure use the existing String route such as `SQL.raw("...")` or `.raw("...")`. In resolved versions that expose bind-aware `SQLRaw`, legal runtime value positions inside that raw structure may use explicit labeled `\(bind:)`; ordinary Swift interpolation remains caller-owned text.

For resolved versions that expose aggregate argument builders, convert aggregate-local DISTINCT and ORDER BY structurally instead of treating the whole aggregate call as raw SQL. For example:

```sql
array_agg(DISTINCT value ORDER BY value DESC)
```

maps to:

```swift
Fn.arrayAgg {
    Distinct {
        DB.Column("value")
    }
    OrderBy(DB.Column("value"), .desc)
}
```

Keep aggregate-local `OrderBy` outside the `Distinct { ... }` body. Ordinary arguments remain normal `SQLable` inputs, so runtime values keep their normal binding behavior. Existing concise aggregate overloads remain valid; use the builder form when the SQL grammar actually needs multiple aggregate arguments, DISTINCT ownership, local ordering, conditionals, loops, or other builder composition. Verify availability in the resolved package before choosing this representation.

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

Use explicit structural identifiers from the installed API. Current `master` uses the canonical `DB.*` namespace shown below; if the resolved consumer is still on SQL 2.x, follow that installed version's historical `Path.*` surface instead of backporting newer names.

```swift
let users = DB.Table("users")
let id = DB.Column("id")
let email = DB.Column("email")
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
let users = DB.Table("users")
```

Canonical declarative form:

```swift
import SQL

let query = SQL {
    Select {
        DB.Column("id")
        DB.Column("email").as("email_address")
    }

    From {
        users
    }

    Where {
        DB.Column("email") == email
    }

    OrderBy(DB.Column("created_at"), .desc)
    Limit(100)
}
```

Canonical direct fluent form:

```swift
import SQL

let query = SQL
    .select(
        DB.Column("id"),
        DB.Column("email").as("email_address")
    )
    .from(users)
    .where(DB.Column("email") == email)
    .orderBy(.desc(DB.Column("created_at")))
    .limit(100)
```

The runtime `email` stays a value input. Prefer the typed predicate shown above. If unsupported surrounding syntax genuinely requires raw SQL and the resolved version exposes `SQLRaw`, keep the SQL structure trusted/static and use only `\(bind: email)` for the runtime value; do not use ordinary String interpolation merely to reproduce the original text.

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
5. otherwise use a clearly marked raw structural boundary;
6. keep dynamic value data on an explicit bind path — ordinarily through typed SQLable values, or through labeled `\(bind:)` inside raw structure when the resolved version supports `SQLRaw` and the database grammar permits that parameter position;
7. prepare the result for the target dialect and inspect `.plain` plus `.splitted`.

Do not infer an API from another SQL library, from a newer release, or from the database documentation alone.

Database documentation tells you which SQL exists. Installed SQL package source/tests tell you which Swift representation actually exists.

## 9. Legacy SwifQL migration

For old call sites, migrate toward the installed canonical SQL surface rather than blindly renaming text.

Typical current migration shape:

```swift
// Legacy spelling:
let oldQuery = SwifQL
    .select(DB.Column("id"))
    .from(DB.Table("users"))

// Canonical spelling:
let query = SQL
    .select(DB.Column("id"))
    .from(DB.Table("users"))
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
            DB.Column("id")
            DB.Column("email")
        }

        From {
            DB.Table("users")
        }

        Where {
            DB.Column("email") == email
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
- runtime/untrusted values are never spliced through ordinary String interpolation; if raw structure is unavoidable and bind-aware `SQLRaw` exists, only legal value positions use labeled `\(bind:)`;
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
- raw fallback would need runtime/untrusted data but the resolved package lacks bind-aware `SQLRaw`, or the target grammar does not permit a parameter in that position;
- exact bind order is unclear;
- conversion would require modifying the SQL package itself.

This skill stops at construction and preparation. Database execution belongs to a driver or integration layer.

## Maintenance rule

This skill intentionally does not claim complete SQL grammar coverage.

Every later accepted query-surface wave must perform a conversion-skill impact check. Update this skill in that wave's docs/skills closure when canonical constructs or spellings change. If the existing procedure remains correct, record `NO_CHANGE` rather than editing it gratuitously.
