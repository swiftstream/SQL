# Declarative Query Authoring

Focused idea bank for future README/docs/release/publication material about the major-version SQL-shaped result-builder query DSL.

## SQL-shaped result builders without a second query engine

Status: implemented and validated
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

The result-builder query API is implemented, validated, and published in stable `2.0.0` from the canonical `SwiftStream/SQL` repository. The package/product/module and direct query root are `SQL`, and declarative construction uses `SQL { ... }`.

## Predicate composition mirrors boolean SQL

Status: implemented, validated, and published in stable 2.0.0
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

Implemented under DESIGN-020 and published in stable `2.0.0`. `Where { ... }` composes direct children with `AND`; explicit `And { ... }` / `Or { ... }` groups own parentheses, and runtime-empty predicate groups disappear rather than emitting synthetic truth values.

## Clause-local builder ergonomics

Status: implemented, validated, and published in stable 2.0.0
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

These clause-local builder shapes are implemented and published in stable `2.0.0`; short argument forms remain useful alongside the vertical closure forms.

## Major identity migration: SwifQL to SQL

Status: implemented, validated, and published in stable 2.0.0
Good for: migration guide | release notes | README | article | short post

### Why users should care

The major-version public identity is now the shorter, direct SQL name:

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

The canonical package/product/module and fluent/declarative root are `SQL`. The migration includes `SwifQLable -> SQLable`, reviewed corresponding `SwifQL...` renames, and the completed repository move to `https://github.com/SwiftStream/SQL`.

There is no compatibility module named `SwifQL`; retained old `SwifQL*` spellings may exist only as deprecated/renamed bridges inside module `SQL` where provided.

### Publication caveat

The source/API/package/repository migration is current and shipped in stable `2.0.0`. The immutable `2.0.0` tag resolves to release commit `07ea7555158aac3750152ebd898474d083dab6dc`, and the stable GitHub Release is published.

## Raw SQL conversion skill

Status: validated
Good for: website docs | README | migration guide | agent/LLM workflow post

### Why users should care

The source-owned `swifql-sql-conversion` skill now gives downstream coding agents a version-aware procedure for turning raw SQL or legacy SwifQL call sites into the canonical `SQL` DSL without guessing APIs. It can return declarative `SQL { ... }` when the resolved package exposes verified builders, direct `SQL.<fluent>`/core composition when that is the supported representation, and an explicit raw boundary only for unsupported static SQL structure.

Runtime or untrusted data never moves into raw SQL for textual convenience: it stays on the normal value/bind path, and the procedure verifies prepared SQL shape plus bind order. The skill also retains migration guidance for historical SwifQL call sites while targeting `import SQL`, direct `SQL`, and `SQLContent` only where explicit concrete typing is required.

### Evidence / provenance

- source-owned skill: `.agent/skills/swifql-sql-conversion/SKILL.md`;
- implementation commit: `3518edee9c12a29b6f55c94dc0fdb87ecd1c8ab9` (`📖 Add SQL conversion skill`);
- PRIMARY validation: C01-C12, 12/12 PASS;
- independent content/API/procedure audit: CLEAN 45/45;
- every later accepted query-surface wave must impact-check the conversion skill and update it only when canonical constructs or spellings change; `NO_CHANGE` is valid otherwise.

### Publication caveat

This status records the validated source-owned skill in the SQL repository. SQL `2.0.0` and the `SwiftStream/SQL` repository are published; publication of the separate skill to the independent `SwiftStream/skills` repository remains an external workflow and is not implied here.

## Reusable parameterized queries with SQLQuery

Status: implemented and freshly validated
Good for: README | website docs | release notes | article | short post

### Why users should care

Result-builder query syntax now composes naturally into reusable Swift values, similar to how SwiftUI packages view structure into reusable `View` types. A query type keeps its own parameters and exposes one declarative SQL body, while remaining directly preparable and nestable through the ordinary SQLable composition pipeline.

### Candidate example / visual

```swift
struct UsersQuery: SQLQuery {
    let active: Bool
    let email: String?
    let roles: [Role]?

    var query: Query {
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

The same query value composes without manual `.query` unwrapping:

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

The same principle is regression-tested through FROM/alias, JOIN, scalar SELECT projection, EXISTS, IN-subquery, and direct root composition.

### Evidence / provenance

- reusable-query implementation commit `616c45775cada4481da3fe2b704b921f675ac264` (`✨ Add reusable SQLQuery components`);
- direct-root/type correction commit `1f656ffe22404b2cdb39546ea3dcfdee7be6abc8` (“🛠 Restore direct `SQL` fluent root”);
- public-doc sync `6fd973e9a3edad075eb50ff4fbb52380bc4ca3ee` and managed-skill sync `4558af69c7a99520ddb79374bae4ff877d726c1a`;
- `Sources/SQL/SQLQuery.swift` and `Tests/SQLTests/SQLQueryTests.swift`;
- exact final focused validation: SQLQuery 7/7 PASS and SQLIdentityPhaseA 5/5 PASS;
- exact final full validation: 737 tests / 63 suites PASS on Swiftly 6.3.3, Xcode 26.6 Swift 6.3.3, and Xcode 27 Swift 6.4;
- exact final downstream normal-import client matrix: PASS x3 with protocol-local `Query`, explicit `SQLContent`, direct composition without `.query`, and dialect/bind checks;
- direct-root representatives: 37/37 PASS x3;
- deprecated SwifQL fluent/builder/unary parity and bind parity: PASS x3;
- direct-root source/API/diff audit: CLEAN, 50/50 PASS.

### Publication caveat

`SQLQuery` is implemented, freshly validated, and published in stable `2.0.0` in the canonical `SQL` source tree. It defines fixed shorthand `Query = SQLContent` and requires `@SQLBuilder var query: Query { get }`; ordinary conformers write `var query: Query { ... }` without repeating the builder attribute or adding a nested `SQL { ... }` wrapper. This keeps conditional filters, loops, and other SQL construction details inside the reusable query type while call sites simply create and compose `UsersQuery(...)` values without manual `.query` unwrapping. `SQLContent` is named only when explicit concrete formed-SQL typing is genuinely required. The exact release candidate passed the three-lane package matrix and downstream client matrix before immutable tag/release publication.

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

Status: implemented, validated, and published in stable SQL 2.2.0 (EF01-A)
Good for: README | website docs | release notes | article

### Why users should care

The declarative expression layer uses the SQL construct the user actually writes rather than a generic “collection” abstraction that silently chooses different database features.

For PostgreSQL, the builder-first form is:

```swift
SQLArray.items {
    1
    2
    User.$score
}
```

with concise shorthand:

```swift
SQLArray.items(1, 2, User.$score)
```

both targeting:

```sql
ARRAY[1, 2, "User"."score"]
```

Nested constructors remain visibly compositional:

```swift
SQLArray.items {
    SQLArray.items { 1; 2 }
    SQLArray.items { 3; 4 }
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
SQLArray.subquery {
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

Implemented by EF01-A commit `aa6920f5cb794304418747337b89e7e6a2ae53e4` under corrected DESIGN-026. The dedicated non-generic `SQLArray` namespace is required because the earlier constrained stdlib-`Array` namespace fails on supported Swift 6.3.3 lanes. The exact `SQLArray.items(...)` / `SQLArray.items { ... }` and `SQLArray.subquery(...)` / `SQLArray.subquery { ... }` forms pass normal-import validation on Swiftly 6.3.3, Xcode 26.6 / Swift 6.3.3, and Xcode 27 / Swift 6.4. Ordinary Swift `Array`, `PostgresArray`, and `PgArray` remain unaffected. Builder bodies stay as direct trailing closures, and the new exact constructors do not remap PostgreSQL `ARRAY[...]` to Duck LIST/fixed-ARRAY or MySQL JSON semantics.

## Structural SQL slices stay inside the existing subscript grammar

Status: implemented, validated, and published in stable SQL 2.2.0 (EF01-B)
Good for: README | website docs | release notes | article | short post

### Why users should care

SQL slicing is not a separate query feature. The lowercase structural `slice` value owns only the bracket interior, while the existing subscript implementation continues to own brackets, chaining, PostgreSQL base grouping, preparation, and bind collection.

Exact forms:

```swift
Scores.$values[slice(2, 4)]
Scores.$values[slice(through: 4)]
Scores.$values[slice(from: 2)]
Scores.$values[slice()]
```

```sql
"scores"."values"[2:4]
"scores"."values"[:4]
"scores"."values"[2:]
"scores"."values"[:]
```

DuckDB also has the positively validated stepped form:

```swift
Scores.$values[slice(2, 8, step: 2)]
```

```sql
"scores"."values"[2:8:2]
```

General-expression bases reuse the existing PostgreSQL grouping rule rather than inventing slice-specific rendering:

```swift
Fn.arrayAgg(Score.$value)[slice(2, 4)]
```

```sql
(array_agg("Score"."value"))[2:4]
```

Bounds remain ordinary SQL expressions and preserve bind order lower -> upper -> step. PostgreSQL/MySQL stepped output may be mechanically renderable, but that is not a support claim and the DSL does not translate it to another function or operator family.

### Evidence / provenance

- `.agent/architecture/DSL_DESIGN_AND_UX.md` DESIGN-026 / DESIGN-037
- EF01-B implementation commit `aa0189107cd79cd6fa82f4b36d29f7c60885e4c7`
- Validation 01: 782 tests / 67 suites on all three current Mac lanes
- independent source/diff audit: CLEAN 102/102

### Publication caveat

Implemented and validated during the SQL 2.2.0 development line; this capability is now published in stable SQL 2.2.0.

## Quantified comparisons read like SQL without fighting Swift.Any

Status: implemented, validated, and published in stable SQL 2.2.0 (EF01-C)
Good for: README | website docs | release notes | article | short post

The shipped family is intentionally asymmetric. Swift makes bare UpperCamel `Any` and bare `Any.sql(...)` unusable, so SQL `ANY` is the exceptional exact-uppercase callable: `ANY(...)` / `ANY { ... }`. `All` and `Some` have no Swift naming conflict and therefore keep normal SQL UpperCamel callable style. Do not uppercase `ALL` / `SOME` just for visual symmetry, and do not lowercase `all` / `some` merely because `ANY` needs an exception.

PostgreSQL ARRAY operand:

```swift
User.$role == ANY(
    SQLArray.items {
        Role.admin
        Role.moderator
    }
)
```

Concise shorthand:

```swift
User.$role == ANY(SQLArray.items(.admin, .moderator))
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

Implemented by EF01-C commit `00081fd2e8494a82179d0b2eac3d86d1ef8b7660` under DESIGN-026. Validation 01 passed 792 tests / 68 suites on Swiftly 6.3.3, Xcode 26.6 / Swift 6.3.3, and Xcode 27 / Swift 6.4; the normal-import consumer passed all six call families alongside ordinary Swift `Any` and legacy `.any/.all`. Independent source/diff audit was CLEAN 125/125. This capability was implemented during the SQL 2.2.0 development line and is now published in stable SQL 2.2.0.

## Aggregate modifiers stay inside the SQL aggregate they belong to

Status: implemented, validated, and published in stable SQL 2.2.0 (EF01-D commit `4940af0490728d3818f5368235575077cb175a3b`)
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

Implemented by EF01-D commit `4940af0490728d3818f5368235575077cb175a3b` under DESIGN-025 and DESIGN-036. Correction 02 validation passed 807 tests / 69 suites on Swiftly 6.3.3, Xcode 26.6 / Swift 6.3.3, and Xcode 27 / Swift 6.4; all four local compile-negative grammar fixtures rejected on both Swift 6.3.3 and Swift 6.4, the external normal-import consumer passed all three lanes, the six-of-six managed-skill gate passed with five required updates and one no-change verdict, and the independent source/diff/evidence audit was CLEAN 105/105. This capability was implemented during the SQL 2.2.0 development line and is now published in stable SQL 2.2.0. Dialect capability remains exact: PostgreSQL and Duck differ in which aggregate modifiers may be combined with window `OVER`, and MySQL aggregate-local ordering is function-specific rather than a universal PostgreSQL-style aggregate grammar.

## Sibling `JOIN` matches nested `JOIN` (dual form)

Status: implemented and published; commit `1982790` is historical provenance, and the capability is carried forward through current stable SQL 3.0.0
Good for: README | website docs | release notes | article | short post

### Why users should care

SQL allows `JOIN` either nested inside a `FROM` list or as a following clause. SwifQL accepts both spellings and guarantees the same SQL and bind order — no “preferred form” tax, no second query model.

### Historical wave example / visual — not current API guidance

The snippets below preserve the source shape used to explain the original sibling-JOIN wave. They use historical `SwifQL` / `Path.*` spellings and must not be reused as current API examples; current public guidance follows the canonical `SQL` module and `DB.*` structural namespace.

```swift
// Historical sibling form — JOIN follows the completed FROM
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

Historical wave note: commit `1982790` introduced this sibling-JOIN capability before the final major-version closure. The capability is now published as part of stable `2.0.0`. Explicit `FromBuilder.Result` annotations remain legacy completed clauses without sibling-JOIN ownership. The final 2.0.0 query DSL also includes declarative `Where { ... }`; do not reuse this old wave boundary as current API guidance.


