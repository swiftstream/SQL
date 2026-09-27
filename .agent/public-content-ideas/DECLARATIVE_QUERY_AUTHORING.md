# Declarative Query Authoring

Focused idea bank for future README/docs/release/publication material about the major-version SQL-shaped result-builder query DSL.

## SQL-shaped result builders without a second query engine

Status: architecture-approved direction, active design
Good for: README | website docs | release notes | article | short post

### Why users should care

The declarative authoring layer is intended to read like SQL while remaining ordinary Swift composition. It reuses the existing parts/preparation/binding engine instead of introducing a parallel AST or ORM-style query model.

Primary multi-item clauses should be able to use readable closure forms while concise argument forms remain available for simple cases.

### Candidate example / visual

```swift
SQL {
    Select {
        User.$id
        User.$email.as("emailAddress")
    }

    From {
        User.table
    }

    Where {
        User.$isActive == true

        if let email {
            User.$email == email
        }

        if !roles.isEmpty {
            Or {
                for role in roles {
                    User.$role == role
                }
            }
        }
    }

    OrderBy(User.$createdAt, .desc)
    Limit(100)
}
```

Target SQL idea:

```sql
SELECT
    "User"."id",
    "User"."email" AS "emailAddress"
FROM "User"
WHERE "User"."isActive" = TRUE
  AND "User"."email" = 'john@example.com'
  AND (
      "User"."role" = 'admin'
      OR "User"."role" = 'moderator'
  )
ORDER BY "User"."createdAt" DESC
LIMIT 100
```

### Evidence / provenance

- `.agent/architecture/DSL_DESIGN_AND_UX.md` DESIGN-001/002/005/006/015/020
- active declarative query design objective in `.agent/TASKS.md`

### Publication caveat

The result-builder query API is design work, not shipped source. Final names/shapes outside already accepted DESIGN-020 predicate semantics remain subject to design review. The final major-version namespace is planned as `SQL`, while current source remains `SwifQL` until the dedicated naming migration wave.

## Predicate composition mirrors boolean SQL

Status: architecture-approved
Good for: README | website docs | release notes | short post

### Candidate example / visual

```swift
Where {
    User.$isActive == true

    Or {
        User.$role == .admin
        User.$role == .moderator
    }
}
```

```sql
WHERE "User"."isActive" = TRUE
  AND (
      "User"."role" = 'admin'
      OR "User"."role" = 'moderator'
  )
```

Direct children of `Where` compose with `AND`; `And { ... }` and `Or { ... }` own explicit parentheses; empty runtime predicate containers disappear instead of emitting synthetic truth values.

### Publication caveat

Architecture-approved under DESIGN-020 but not yet implemented/shipped.

## Clause-local builder ergonomics

Status: idea under active design
Good for: README | website docs | article

### Candidate examples / visual

```swift
Select {
    User.$id
    User.$email.as("emailAddress")
}

From {
    User.table
    Organization.table
}

GroupBy {
    User.$country
    User.$city
}

OrderBy {
    Order(User.$createdAt, .desc)
    Order(User.$id, .asc)
}
```

The intended theme is consistent: when a clause naturally owns a list, the closure form reads vertically like SQL; short argument forms remain useful for one/few items.

### Publication caveat

These shapes are still being designed. Do not present them as final API until accepted into the stable design owner and implemented.

## Major identity migration: SwifQL to SQL

Status: roadmap-approved, not implemented
Good for: migration guide | release notes | README | article | short post

### Why users should care

The final major-version public identity is planned to become the shorter, direct SQL name:

```swift
SQL {
    Select {
        User.$id
        User.$email
    }
    From {
        User.table
    }
}
```

instead of a final public result-builder spelling rooted at `SwifQL { ... }`.

The planned migration includes `SwifQLable -> SQLable`, reviewed corresponding `SwifQL...` renames, and repository/package relocation to `github.com/swiftstream/SQL`.

### Publication caveat

Current released/pre-release source is still SwifQL. This is a planned major-version migration and must not be described as current until the dedicated migration wave is implemented, validated, audited, and published.

## Raw SQL conversion skill

Status: roadmap-approved, not implemented
Good for: website docs | README | migration guide | agent/LLM workflow post

### Why users should care

A future downstream skill should turn raw SQL into either:

1. the final declarative result-builder representation; or
2. the final raw/fluent SQL DSL representation.

It should also retain enough legacy SwifQL knowledge to help coding agents migrate existing call sites during the major namespace transition.

### Publication caveat

The canonical public skill should target the final `SQL` namespace rather than being published against a namespace that is immediately renamed.

## Reusable parameterized queries with SQLQuery

Status: roadmap-approved, not implemented
Good for: README | website docs | release notes | article | short post

### Why users should care

Result-builder query syntax should compose naturally into reusable Swift values, similar to how SwiftUI packages view structure into reusable `View` types. A query type keeps its own parameters and exposes one declarative SQL body, while remaining directly preparable and nestable as a subquery.

### Candidate example / visual

```swift
struct UsersQuery: SQLQuery {
    let active: Bool
    let email: String?
    let roles: [Role]?

    var query: SQL {
        Select {
            User.$id
            User.$email.as("emailAddress")
            User.$createdAt
        }

        From {
            User.table
        }

        Where {
            User.$isActive == active

            if let email {
                User.$email == email
            }

            if let roles {
                Or {
                    for role in roles {
                        User.$role == role
                    }
                }
            }
        }
    }
}
```

Direct use:

```swift
let prepared = UsersQuery(
    active: true,
    email: "john@example.com",
    roles: [.admin, .moderator]
)
.prepare(.psql)
```

Target SQL:

```sql
SELECT
    "User"."id",
    "User"."email" AS "emailAddress",
    "User"."createdAt"
FROM "User"
WHERE "User"."isActive" = TRUE
  AND "User"."email" = 'john@example.com'
  AND (
      "User"."role" = 'admin'
      OR "User"."role" = 'moderator'
  )
```

The same query value should compose without manual `.query` unwrapping:

```swift
From {
    UsersQuery(active: true, email: nil, roles: nil)
        .as("activeUsers")
}
```

Target SQL:

```sql
FROM (
    SELECT
        "User"."id",
        "User"."email" AS "emailAddress",
        "User"."createdAt"
    FROM "User"
    WHERE "User"."isActive" = TRUE
) AS "activeUsers"
```

The same principle should extend to JOIN, EXISTS, IN-subquery, and other grammar positions that accept a nested query.

### Publication caveat

`SQLQuery` is roadmap-approved follow-up work after declarative query result builders and is not implemented/shipped. The canonical target is a SwiftUI-style result-builder-attributed `query` protocol requirement so conforming types can write the SQL clauses directly in `var query: SQL { ... }` without an explicit nested `SQL { ... }` wrapper. Reusable parameterized query values, direct preparation, and subquery composition are required product semantics.

## Three equivalent alias authoring forms and general declarative As

Status: architecture-approved
Good for: README | website docs | migration guide | release notes

### Candidate examples / visual

The final DSL keeps three equivalent postfix alias styles wherever the grammar item supports a true alias.

SELECT result item:

```swift
Select {
    User.$id
    As("identifier")

    User.$email
    As("emailAddress")
}
```

```sql
SELECT
    "User"."id" AS "identifier",
    "User"."email" AS "emailAddress"
```

Equivalent fluent/operator source:

```swift
Select {
    User.$id.as("identifier")
    User.$email => "emailAddress"
}
```

produces the same SQL.

JOIN fluent:

```swift
Join(.left, Profile.table)
    .as("profile")

On(User.$id == Profile.$userId)
```

JOIN operator shorthand:

```swift
Join(.left, Profile.table) => "profile"

On(User.$id == Profile.$userId)
```

JOIN explicit declarative continuation:

```swift
Join(.left, Profile.table)

As("profile")

On(User.$id == Profile.$userId)
```

All three JOIN forms target:

```sql
LEFT JOIN "Profile" AS "profile"
ON "User"."id" = "Profile"."userId"
```

The same `As("...")` continuation applies to FROM items, nested/reusable query sources, and dialect constructs that truly expose postfix alias grammar. It must not be used as a generic replacement for every SQL occurrence of the keyword `AS`.

The implementation must preserve identifier-safe alias semantics, clause-item grouping/comma placement, dynamic-branch ownership, and typed structural attachment rather than previous-token scanning.

### Publication caveat

Architecture-approved target UX under DESIGN-021 but not yet implemented/shipped as result-builder syntax. The legacy `=>` operator already exists today; the new declarative forms remain future major-version work.

## Explicit NULL predicates alongside operator sugar

Status: architecture-approved
Good for: README | website docs | release notes

### Candidate example / visual

```swift
Where {
    IsNull(Profile.$deletedAt)
    IsNotNull(Profile.$archivedAt)
}
```

```sql
WHERE "Profile"."deletedAt" IS NULL
  AND "Profile"."archivedAt" IS NOT NULL
```

Equivalent established forms remain available:

```swift
Profile.$deletedAt == nil
Profile.$archivedAt != nil

Profile.$deletedAt.isNull
Profile.$archivedAt.isNotNull
```

### Publication caveat

`== nil`, `!= nil`, `.isNull`, and `.isNotNull` already exist in current SwifQL. `IsNull(...)` / `IsNotNull(...)` are architecture-approved declarative additions, not yet shipped.

## FROM items without mandatory nested SQL wrappers

Status: architecture-approved
Good for: README | website docs | release notes | article

### Candidate example / visual

A nested statement can be authored directly as one FROM item:

```swift
From {
    Select {
        Order.$userId
        Fn.count(Order.$id)
        As("orderCount")
    }

    From {
        Order.table
    }

    GroupBy {
        Order.$userId
    }

    As("orderStats")

    Organization.table
}
```

Target SQL:

```sql
FROM
    (
        SELECT
            "Order"."userId",
            count("Order"."id") AS "orderCount"
        FROM "Order"
        GROUP BY "Order"."userId"
    ) AS "orderStats",
    "Organization"
```

An explicit nested `SQL { ... }` value remains supported when the user wants an explicit statement boundary; it is not mandatory merely because the statement appears inside `From { ... }`.

### Why this matters

SwifQL 2 already has published structural SQL-region frames and root-frame-aware continuation. The final result-builder implementation should reuse that architecture so nested statement ownership is structural rather than recovered by scanning SQL tokens.

### Publication caveat

The structural-frame infrastructure exists today, but direct nested result-builder statement grouping inside `From { ... }` is future major-version API.

## Dynamic Columns alias lists

Status: architecture-approved
Good for: README | website docs | release notes

```swift
Values {
    Row(.admin, 100)
    Row(.moderator, 50)
}

As("rolePriority")

Columns {
    "role"

    if priorityEnabled {
        "priority"
    }
}
```

When enabled:

```sql
(
    VALUES
        ('admin', 100),
        ('moderator', 50)
) AS "rolePriority" ("role", "priority")
```

When disabled:

```sql
(
    VALUES
        ('admin', 100),
        ('moderator', 50)
) AS "rolePriority" ("role")
```

String children of `Columns { ... }` are identifiers. If an optional alias-column list has zero surviving children, the entire list disappears rather than producing empty parentheses.

## WITH ORDINALITY stays atomic

Status: architecture-approved
Good for: README | website docs | design article

```swift
From {
    Fn.generateSeries(10, 12)
    WithOrdinality()
    As("series")
    Columns("value", "position")
}
```

```sql
FROM generate_series(10, 12)
WITH ORDINALITY
AS "series" ("value", "position")
```

Do not split this into generic `With()` / `Ordinality()` tokens. SQL uses `WITH` for many unrelated constructs, so each grammar owner keeps its own SQL-shaped API.

## VALUES as a first-class declarative query result

Status: architecture-approved
Good for: README | website docs | release notes | article

```swift
Values {
    Row {
        "admin"
        100
    }

    Row {
        "moderator"
        50
    }
}

As("rolePriority")

Columns {
    "role"
    "priority"
}
```

Concise shorthand remains available:

```swift
Values {
    Row("admin", 100)
    Row("moderator", 50)
}
```

PostgreSQL/Duck target:

```sql
(
    VALUES
        ('admin', 100),
        ('moderator', 50)
) AS "rolePriority" ("role", "priority")
```

MySQL uses the same semantic Swift rows but renders its required `ROW(...)` table-value syntax. Every surviving VALUES row has the same non-zero arity; zero-row VALUES is invalid rather than silently disappearing. Dynamic omission belongs around the whole VALUES construct when the caller wants no source.

`Values` is also a standalone query-result/set-operation participant rather than only a FROM helper. Future `Default()` is owner-sensitive and valid only in grammar positions such as INSERT VALUES that actually permit SQL DEFAULT.

### Publication caveat

The final declarative VALUES API is architecture-approved under DESIGN-023 but not yet implemented. The same semantic `Row` is now architecture-approved for both VALUES and general row-expression grammar; typed PostgreSQL record-definition naming remains open.

## Declarative expression grammar keeps SQL readable

Status: architecture-approved
Good for: README | website docs | release notes | article

### One semantic Row, builder-first

Preferred:

```swift
Where {
    In {
        Row {
            User.$country
            User.$city
        }

        Row {
            "NL"
            "Amsterdam"
        }

        Row {
            "DE"
            "Berlin"
        }
    }
}
```

Concise shorthand remains available:

```swift
Where {
    In(
        Row(User.$country, User.$city),
        Row("NL", "Amsterdam"),
        Row("DE", "Berlin")
    )
}
```

Both target:

```sql
WHERE ROW("User"."country", "User"."city") IN (
    ROW('NL', 'Amsterdam'),
    ROW('DE', 'Berlin')
)
```

### Structural expression continuations

Result-builder expression items may read in literal SQL order:

```swift
Select {
    Fn.sum(Order.$total)

    Filter {
        Order.$status == Status.paid
    }

    Over {
        PartitionBy(Order.$userId)
        OrderBy(Order.$createdAt, .asc)
    }

    As("runningPaidTotal")
}
```

targeting:

```sql
SELECT
    sum("Order"."total")
    FILTER (WHERE "Order"."status" = 'paid')
    OVER (
        PARTITION BY "Order"."userId"
        ORDER BY "Order"."createdAt" ASC
    ) AS "runningPaidTotal"
```

Inline forms remain available where an expression must be complete at one call site, for example `Over(Fn.rowNumber()) { ... }`.

The accepted expression family also includes SQL-shaped `Case` / `When` / `Else`, `Coalesce`, `NullIf`, `Greatest`, `Least`, `Between` / `NotBetween`, pattern predicates, `IsDistinctFrom` / `IsNotDistinctFrom`, direct nested `SQL { ... }` scalar operands, `Cast`, `Filter`, and `WithinGroup`.

### Publication caveat

DESIGN-024 is architecture-approved target UX, not shipped implementation. Final DESIGN-026 naming rejects bare UpperCamel `Any(...)` and bare `Any.sql(...)`; exceptional exact-uppercase `ANY` is compiler-validated, while non-conflicting `All` and `Some` retain normal SwifQL UpperCamel casing.

## Exact ARRAY authoring without a fake cross-database collection abstraction

Status: architecture-approved
Good for: README | website docs | release notes | article

### Why users should care

The declarative expression layer is being designed around the SQL construct the user actually writes rather than a generic “collection” abstraction that silently chooses different database features.

For PostgreSQL, the preferred builder-first target is:

```swift
Array.items {
    1
    2
    User.$score
}
```

with concise shorthand:

```swift
Array.items(1, 2, User.$score)
```

both targeting:

```sql
ARRAY[1, 2, "User"."score"]
```

Nested constructors remain visibly compositional:

```swift
Array.items {
    Array.items { 1; 2 }
    Array.items { 3; 4 }
}
```

```sql
ARRAY[
    ARRAY[1, 2],
    ARRAY[3, 4]
]
```

and a nested statement uses the real `ARRAY(subquery)` grammar rather than a synthetic `Subquery` wrapper:

```swift
Array.subquery {
    Select { Order.$id }
    From { Order.table }
    Where { Order.$userId == User.$id }
}
```

```sql
ARRAY(
    SELECT "Order"."id"
    FROM "Order"
    WHERE "Order"."userId" = "User"."id"
)
```

The same design deliberately does **not** render PostgreSQL `ARRAY[...]` as DuckDB `[...]` / `array_value(...)` or MySQL `JSON_ARRAY(...)`; those are different SQL concepts with different type semantics.

### Publication caveat

Architecture-approved under final DESIGN-026. The exact `Array.items(...)` / `Array.items { ... }` and `Array.subquery(...)` / `Array.subquery { ... }` forms are compiler-validated across Swift 6.2.3, Xcode/Swiftly 6.3.3, and Swift 6.4. The real standard-library `Array` remains the namespace; members name the concrete SQL grammar role instead of using a generic `.sql` escape. Builder bodies stay as direct trailing closures, avoiding `Something(label: { ... })` punctuation noise. Free SQL-constructor `Array(...)`, bare `Array { ... }`, `Array(elements: { ... })`, and generic `Array.sql...` forms are non-canonical.

## Quantified comparisons read like SQL without fighting Swift.Any

Status: architecture-approved
Good for: README | website docs | release notes | article | short post

The maintainer-selected family is intentionally asymmetric. Swift makes bare UpperCamel `Any` and bare `Any.sql(...)` unusable, so SQL `ANY` becomes an exceptional exact-uppercase callable: `ANY(...)` / `ANY { ... }`. `All` and `Some` have no Swift naming conflict and therefore keep normal SwifQL UpperCamel callable style. Do not uppercase `ALL` / `SOME` just for visual symmetry, and do not lowercase `all` / `some` merely because `ANY` needs an exception.

PostgreSQL ARRAY operand:

```swift
User.$role == ANY(
    Array.items {
        Role.admin
        Role.moderator
    }
)
```

Concise shorthand:

```swift
User.$role == ANY(Array.items(.admin, .moderator))
```

Prepared SQL:

```sql
"User"."role" = ANY(
    ARRAY[$1, $2]
)
```

with values `[admin, moderator]`.

Nested-query quantifier:

```swift
Where {
    User.$score > All {
        Select { Threshold.$value }
        From { Threshold.table }
        Where { Threshold.$kind == kind }
    }
}
```

```sql
WHERE "User"."score" > ALL (
    SELECT "Threshold"."value"
    FROM "Threshold"
    WHERE "Threshold"."kind" = $1
)
```

`Some(...)` remains a first-class spelling and emits SQL `SOME`; it is not normalized to `ANY`.

DuckDB v1.5.5 native validation confirms quantified comparison against subqueries, LIST values, fixed ARRAY values, `ARRAY(subquery)`, and row-valued subqueries. MySQL support remains limited to its actual quantified-subquery grammar; no PostgreSQL ARRAY construct is silently translated into JSON or another MySQL feature.

### Publication caveat

Architecture-approved under DESIGN-026 but not yet implemented/shipped. The lowercase family and ARRAY spelling were compiler-probed across Swift 6.2.3, 6.3.3, and 6.4 before acceptance.

## Aggregate modifiers stay inside the SQL aggregate they belong to

Status: architecture-approved
Good for: README | website docs | release notes | article | short post

### Why users should care

Advanced aggregate syntax should not require a generic wrapper or a second query model. Existing exact `Fn.*` identities remain the entry point, while a builder form exposes the SQL grammar inside the function call.

Builder-first:

```swift
Fn.arrayAgg {
    Distinct(Order.$id)
    OrderBy(Order.$id, .desc)
}
```

```sql
array_agg(
    DISTINCT "Order"."id"
    ORDER BY "Order"."id" DESC
)
```

Existing shorthand stays concise:

```swift
Fn.arrayAgg(Order.$id)
```

```sql
array_agg("Order"."id")
```

The ownership remains literal: aggregate `DISTINCT` is not SELECT `DISTINCT` or PostgreSQL `DISTINCT ON`; aggregate-local `ORDER BY` is not query-level ordering; and ordered-set aggregates keep their separate `WITHIN GROUP` grammar:

```swift
Fn.percentileCont(0.5)

WithinGroup {
    OrderBy(Income.$amount, .asc)
}
```

```sql
percentile_cont(0.5)
WITHIN GROUP (
    ORDER BY "Income"."amount" ASC
)
```

### Evidence / provenance

- `.agent/architecture/DSL_DESIGN_AND_UX.md` DESIGN-025
- PostgreSQL/Duck aggregate grammar research from Expression Frontier 01

### Publication caveat

DESIGN-025 is architecture-approved target UX, not implemented/shipped result-builder source. Dialect capability remains exact: PostgreSQL and Duck differ in which aggregate modifiers may be combined with window `OVER`, and MySQL aggregate-local ordering is function-specific rather than a universal PostgreSQL-style aggregate grammar.

## Sibling `JOIN` matches nested `JOIN` (dual form)

Status: implemented in source (local commit `1982790`, not yet pushed/released)
Good for: README | website docs | release notes | article | short post

### Why users should care

SQL allows `JOIN` either nested inside a `FROM` list or as a following clause. SwifQL accepts both spellings and guarantees the same SQL and bind order — no “preferred form” tax, no second query model.

### Candidate example / visual

```swift
// Sibling form — JOIN follows the completed FROM
SwifQL {
    Select { Path.Table("User").column("id") }
    From { Path.Table("User") }
    Join(.left, Path.Table("Profile"))
    On(Path.Table("User").column("id") == "owner")
}
```

```swift
// Nested form — identical SQL and binds
SwifQL {
    Select { Path.Table("User").column("id") }
    From {
        Path.Table("User")
        Join(.left, Path.Table("Profile"))
        On(Path.Table("User").column("id") == "owner")
    }
}
```

```sql
SELECT "User"."id"
FROM "User"
LEFT JOIN "Profile" ON "User"."id" = $1
-- values: ["owner"]  (psql/duck; mysql uses ?)
```

Guaranteed-source ownership survives a local:

```swift
let from = From { Path.Table("User") }   // FromBuilder.GuaranteedResult

SwifQL {
    from
    Join(.left, Path.Table("Profile")).as("p")
    On(true)
    Join(.inner, Path.Table("Organization"))
    Using("id")
    As("org")
}
```

```sql
FROM "User"
LEFT JOIN "Profile" AS "p" ON TRUE
INNER JOIN "Organization" USING ("id") AS "org"
```

Boundaries stay sharp: orphan `Join`/`On`/`Using`, loop-only/optional-only `FROM`, closed control-flow groups (F01), and `SwifQLable`-erased values cannot own a sibling `JOIN`.

### Evidence / provenance

- Implemented under `.agent/architecture/DSL_DESIGN_AND_UX.md` DESIGN-022 (Outer sibling JOIN after FROM; Guaranteed `From` carrier ingress) and DESIGN-028 (Closed FROM body, open outer clause)
- Tests: `DeclarativeQueryFromJoinTests` D04-S38–S43; independent audit `SIBLING_JOIN_SOURCE_AUDIT: CLEAN`
- Lineage: `.artifacts/planning/declarative-query-join-sibling-continuation-plan-2026-09-25/`

### Publication caveat

Shipped in the working tree as commit `1982790` but **not pushed/released**. Present as current source capability only after the maintainer authorizes publication. Explicit `FromBuilder.Result` annotations remain legacy completed clauses without sibling-JOIN ownership. A declarative `Where` builder is **not** in this surface yet — do not show `Where { ... }` as current API.


