# Duck Dialect Architecture

This file is the sole owner of `DUCK-*` rules and verified DuckDB-specific behavior for SQL.

Load it together with `../DIALECT_RENDERING.md` for Duck work. Load `../DSL_DESIGN_AND_UX.md` only when public API/UX design is involved, and `../QUERY_PREPARATION.md` only when preparation/value mechanics change.

This file intentionally distinguishes:

- stable Duck API/rendering contracts;
- verified DuckDB v1.5.5 engine behavior;
- current implementation state;
- current published SwifQL 2 pre-release state, known limitations, and deferred families that remain outside the first closure.

Do not duplicate these details in the cross-dialect base owner.

## Context-budget growth rule

Keep this file as one Duck owner while it remains practical to load for a focused Duck task. If future PostgreSQL-level breadth makes it too large, split only by genuinely independent Duck domains and move ownership rather than copying rules. Likely future split candidates are types/values, query features, DML/DDL, and native-validation evidence. Do not pre-create empty chunks for symmetry.

A split must keep `DUCK-*` ownership unambiguous through `ARCH_INDEX.md` and preserve the rule that a normal task loads only the Duck detail actually needed.

## Identity and naming

### DUCK-001 - Canonical Swift dialect spelling

The canonical public Swift dialect factory is:

```swift
SQLDialect.duck
```

Ordinary preparation is:

```swift
query.prepare(.duck)
```

The public Duck factory is `.duck`. The first support/compatibility/native-validation closure has passed, so `SQLDialect.all` now contains `[.psql, .mysql, .duck]`. This expands the semantic reach of every existing `check(..., all:)` assertion, which is why the collection change was delayed until the explicit closure/classification gate.

Focused Duck tests may still use `.duck` explicitly where dialect-specific expectations are required. Internal product identity may still use `"duckdb"`.

### DUCK-002 - Internal database identity

The actual database product remains DuckDB.

The internal dialect id may remain:

```swift
"duckdb"
```

Human-facing prose may say DuckDB.

Swift implementation naming uses `Duck...` / `duck...` when a database-specific prefix is genuinely needed. Do not introduce new `DuckDB...` / `duckDB...` Swift symbol prefixes.

Examples of preferred implementation spelling:

- `DuckDialect`
- `Dialect+Duck.swift`
- `Functions+DuckJSON.swift`
- `duckCatalogPathParts(...)`

Before adding a Duck prefix, first ask whether the user-facing concept should instead have a clean generic SQL name.

## Core scalar rendering

### DUCK-003 - Identifiers

Duck identifiers use double quotes.

Embedded double quotes are escaped by doubling them.

This applies to schema/table/alias/column identifiers and any nested STRUCT/UNION member/tag identifier handled by SQL.

Examples:

```sql
"events"
"x space"
"a""b"
```

Do not reject identifiers merely because they require quoting.

### DUCK-004 - Strings

String literals use single quotes.

Embedded apostrophes are escaped by doubling them.

Example:

```sql
'O''Reilly'
```

Do not raw-interpolate user string values.

### DUCK-005 - Bind markers

Duck prepared placeholders use positional `$N` markers:

```sql
$1, $2, $3
```

Value traversal/order remains owned by `QUERY_PREPARATION.md`.

Native DuckDB v1.5.5 validation has confirmed normal binding behavior for representative scalar values, PIVOT `IN (...)` values, and PIVOT `LIMIT` when the statement is otherwise prepare-able.

### DUCK-006 - Foundation Date

A Foundation `Date` is rendered deterministically as a UTC Duck TIMESTAMPTZ literal with microsecond precision:

```sql
TIMESTAMPTZ 'YYYY-MM-DD HH:MM:SS.ffffff+00:00'
```

Do not use local time zone behavior for Duck Date rendering.

### DUCK-006A - Shared temporal and interval values

The shared civil values use the ordinary Duck preparation path:

```sql
DATE '2026-09-04'
CAST('12:34:56.123456789' AS TIME_NS)
CAST('2026-09-04 12:34:56.123456789' AS TIMESTAMP_NS)
INTERVAL '2 months -3 days 4 microseconds'
```

`PureDate` keeps its canonical shared identity; positive extended years lose only the input `+` for Duck parser spelling, for example `+10000-01-01` becomes `DATE '10000-01-01'`. `TIMESTAMP_NS` has a finite physical nanosecond epoch range, so deterministic formatting outside that range is not a promise that Duck can execute every value. Shared `Interval.positiveInfinity` and `.negativeInfinity` remain explicit special states; they do not become native Duck `INTERVAL` infinity and must not be described as such.

### DUCK-007 - Foundation Data and exact base64 SQL stay transparent

Historical direct `Data.parts` is protected compatibility surface and remains PostgreSQL-shaped. Duck support must not globally reinterpret that existing expression and must not introduce a semantic `binary(...)` facade that chooses different named SQL functions by dialect.

Base64 SQL is modeled through exact function identity:

- PostgreSQL `decode(..., 'base64')` remains the `decode` construct;
- Duck `from_base64(...)` and MySQL `FROM_BASE64(...)` are the same exact function name with dialect-preferred casing and use canonical Swift `Fn.fromBase64(...)`;
- when included by the approved migration plan, `Fn.from_base64(...)` exists only as an immediately deprecated `renamed: "fromBase64"` compatibility bridge.

Selecting `.duck` may change casing/rendering details of the same exact function, bind markers, identifiers, and other dialect-owned syntax. It must not silently translate `decode` into `from_base64` or vice versa.

Any direct Duck BLOB/Data binding support must use normal explicit value/binding primitives and exact SQL APIs without changing historical direct `Data.parts`.

## Paths, JSON, and contextual rendering

### DUCK-008 - Normal key paths

Outside a grammar-specific context, a normal table column path remains qualified:

```swift
Path.Table("events").column("payload")
```

renders as:

```sql
"events"."payload"
```

Nested JSON path segments use Duck JSON operators and string path fields.

`asText` on the final path segment uses `->>`; otherwise JSON traversal uses `->`.

### DUCK-009 - JSON/list indexing semantics

Duck JSON indexing is zero-based.

Duck LIST/ARRAY indexing is one-based.

Do not unify these semantics under a fake common index abstraction that changes SQL meaning.

### DUCK-010 - Context-sensitive qualification must stay invisible to ordinary query source

Duck simplified PIVOT is a verified case where source-qualified column references are rejected by the engine in specific grammar positions.

Users should not have to replace normal SQL table/column expressions with Duck-prefixed wrappers merely to satisfy this renderer requirement.

The approved architecture is dialect-transparent semantic render scopes through the shared parts/preparation pipeline, consistent with `DIALECT-008` and DESIGN-014/015.

For PIVOT grammar regions that accept normal expressions but require Duck-specific qualification behavior, the relevant expression parts carry a structural scope such as the ON/USING/ORDER BY grammar role. That scope travels with the expression regardless of whether the query is written as one fluent chain, assembled through `var`/conditionals, or produced by helper methods.

Duck rendering reads this explicit scope from the recursive render context. It must not infer PIVOT context by inspecting neighboring raw operator strings or by keeping ambient mutable "inside PIVOT" state on the query.

Do not attach a generic Duck operator scope to every ordinary predicate/arithmetic/operator constructor. Contextual scopes belong only to the semantic construct whose grammar actually requires them; ordinary established part shape must remain unchanged.

Neighbor-token heuristics such as inspecting previous/next raw operators are not acceptable architecture for Duck grammar context. Remaining Duck operator-precedence requirements must be researched and solved at the narrowest truthful semantic boundary without changing ordinary PostgreSQL/MySQL composition.

## Collections and nested types

### DUCK-011 - LIST and fixed ARRAY

Duck distinguishes:

- variable-length LIST type syntax such as `INTEGER[]`;
- fixed-size ARRAY type syntax such as `INTEGER[3]`.

A fixed ARRAY length must be strictly positive.

The current public type API uses clean SQL-shaped names under `Type`, including:

```swift
Type.list(...)
Type.array(..., length: ...)
```

Do not expose a new Duck-prefixed type API for SQL type names when the clean `Type.*` surface is truthful.

### DUCK-012 - MAP / STRUCT / UNION / VARIANT

Duck supports nested values/types including MAP, STRUCT, UNION, and VARIANT.

For the type system, clean SQL-shaped `Type.*` names are preferred.

The STRUCT type function is intentionally expressed with Swift escaped-keyword syntax:

```swift
Type.`struct`(...)
```

not `structure(...)` and not `structType(...)`.

Nested STRUCT/UNION identifiers must use proper quoted identifier rendering, including reserved words, spaces, Unicode, and embedded quotes.

The current first-closure value-construction surface includes `Fn.listValue(...)`, `Fn.arrayValue(...)`, and `Fn.map(...)`. Generic STRUCT/UNION value constructors that require a reusable first-class `name := expression` abstraction remain deferred with DUCK-025, and no dedicated VARIANT value-construction API is claimed by the first closure. Do not invent raw-string or Duck-prefixed substitutes for those deferred grammar needs.

## Type mapping

### DUCK-013 - Exact type mapping over PostgreSQL convenience

Do not claim PostgreSQL-only type semantics as Duck equivalents merely because names look similar.

The Duck type surface may reuse exact shared SQL type names where semantics are compatible, but PostgreSQL-specific serial/range/OID/catalog/jsonb/network/geometry helpers are not automatically Duck APIs.

If a future dialect-aware `Type.auto(from:dialect:isPrimary:)` convenience is approved, it must return `nil` when SQL cannot infer a semantics-preserving Duck type/default behavior. Reuse one semantic mapping owner rather than duplicating type inference across dialect-specific helpers.

In particular, primary-key integer inference must not silently invent PostgreSQL `serial` semantics for Duck.

Sequence/default behavior is modeled separately.

## Functions

### DUCK-014 - Function API stays clean

Duck-specific SQL functions live under normal camelCase `Fn.*` Swift names while emitted SQL retains the exact Duck function spelling.

The current first-closure function surface includes validated JSON, numeric, string, time, sequence, nested-value, LIST/lambda, table/file, COLUMNS, and related exact SQL helpers. Exact SQL identity remains mandatory; later function families require the same source/API/native review before becoming support claims.

Do not prefix ordinary function calls with `Duck` merely because current support is Duck-only.

Do not silently map a Duck function to a differently named PostgreSQL/MySQL function.

## Query features

### DUCK-015 - Reuse common SQL DSL first

Duck support should reuse existing common SQL composition whenever the SQL concept is already expressible.

Examples:

- FROM-first composition reuses `SQL.from(...).select(...)`;
- GROUP BY ALL reuses `.groupBy(SQL.all)`;
- normal ORDER BY / LIMIT / OFFSET reuse shared query primitives when grammar matches;
- generic expressions/functions/aliases remain normal SQL expressions.

Do not add parallel Duck builders only for visual symmetry.

### DUCK-016 - Native Duck query features remain clean at call sites

The implemented first-closure Duck/native query surface includes:

- QUALIFY;
- ORDER BY ALL;
- SAMPLE/TABLESAMPLE;
- UNION BY NAME / ALL BY NAME;
- SEMI / ANTI / POSITIONAL / ASOF joins;
- NATURAL / USING join forms;
- star EXCLUDE / REPLACE / RENAME;
- COLUMNS(...);
- PIVOT / UNPIVOT;
- INSERT BY NAME / OR IGNORE / OR REPLACE;
- MERGE;
- ATTACH / DETACH / USE;
- COPY;
- macros;
- sequences;
- nested values;
- table-function composition.

A feature being Duck-only today does not automatically authorize a `Duck...` public query API. Apply DESIGN-014 and the clean SQL-concept rule first.

Sampling is represented by the generic `Sample`/`TableSample` semantic model:
method identity, ordered arguments/roles, and seed/repeatability remain
available to the dialect renderer. Duck's verified `USING SAMPLE` and
`TABLESAMPLE` parser-constant positions inline only supported typed literal
values through the existing safe-value pipeline; ordinary later values remain
bindable, and unsupported arbitrary sampling expressions fail closed rather
than being interpolated. Custom-dialect sampling fixtures validate extension
shape only and do not claim BigQuery, Snowflake, or other production dialect
support.

Duck lambdas retain the generic `SQLLambda` surface and structural parameter
identifiers/body expressions. The dialect's canonical verified lowering is
`lambda <parameter> : <body>` (including quoted and escaped identifiers);
`SQLDialect.lambda(_:)` owns that punctuation while ordinary body values keep
left-to-right prepared binding. Nested lambdas and outer-column captures
compose through the same recursive parts pipeline. This records exact Duck
lowering only and does not claim support for another dialect's lambda syntax.

The direct generic forms for the modifier-bearing features are:

```swift
query.orderBy(SQL.all)
query.orderBy(.desc(SQL.all, nulls: .last))
query.join(.positional, source)
query.join(.naturalFullOuter, source)
lhs.union(byName: rhs)
lhs.union(allByName: rhs)
```

## PIVOT

### DUCK-017 - Simplified PIVOT native contract

DuckDB v1.5.5 native validation established the following for simplified PIVOT:

- unqualified ON expressions work;
- source-table-qualified columns in ON fail with a binder error;
- source-table-qualified columns inside USING aggregate expressions fail;
- GROUP BY works with unqualified column names and rejects qualified source paths;
- ORDER BY works with unqualified PIVOT output column names and rejects source-table-qualified paths;
- explicit `IN` values work as normal prepared parameters;
- numeric, apostrophe-containing text, and Unicode `IN` values passed prepare/bind/execute;
- LIMIT works as a normal prepared parameter when explicit IN makes the statement structurally prepare-able;
- dynamic simplified PIVOT without explicit IN can execute as plain SQL but DuckDB v1.5.5 cannot prepare it as one C prepared statement because dynamic output-column discovery expands internally into multiple statements.

Do not misclassify the no-IN preparation limitation as a general placeholder or LIMIT defect.

### DUCK-018 - PIVOT UX contract

Do not introduce PIVOT-specific public wrapper types for columns, ON expressions, aggregates, or ordering when existing SQL expressions and paths can model the SQL cleanly.

Ordinary PIVOT source should stay clean and use existing SQL expressions, paths, functions, aliases, and ordering concepts.

Required clean source direction:

```swift
SQL.pivot(cities)
    .on(cities.column("year"), in: 2000, 2010)
    .using(Fn.sum(cities.column("population")) => "total")
    .groupBy(cities.column("country"))
    .orderBy(.desc(cities.column("country")))
    .limit(2)
```

The dialect renderer, not the user, owns Duck's unqualification requirement in PIVOT grammar zones.

For simplified PIVOT `GROUP BY`, the documented correct source remains a column-name path such as:

```swift
.groupBy(cities.column("country"))
```

DuckDB v1.5.5 accepts column names there and rejects qualified/expression forms. However, after `var query: SQLable` existential erasure, the unchanged global `.groupBy(_ fields: SQLable...)` surface cannot truthfully become a PIVOT-only compile-time `KeyPathLastPath` constraint without either changing ordinary GROUP BY overload behavior, adding hidden PIVOT routing, or changing the clean call shape. Do not add a global PIVOT-validation overload or wrapper to simulate a static guarantee the erased receiver cannot express.

`KeyPathLastPath` remains established public compatibility/extension surface and remains appropriate for APIs whose own static grammar is genuinely column-name-only. For PIVOT GROUP BY, preserve the generic SQL DSL surface, render correct column paths according to the structural owner, document/native-test the valid Duck grammar, and allow DuckDB to reject dialect-invalid arbitrary expressions rather than distorting established global GROUP BY semantics.

For ON and USING expression regions, use bounded structural semantic render scopes rather than PIVOT-specific expression wrappers. The reconciled diagnostic has established that bounded scopes survive `var SQLable`, helpers, copied parts, nesting, independent scopes, and ordered binding collection when the semantic owner can attach the scope to a bounded subtree.

For simplified PIVOT `GROUP BY` and `ORDER BY`, clause ownership remains separate from grammar validity. The structural frame owns qualification/rendering context; it does not attempt to turn the erased global GROUP BY API into a PIVOT-only compile-time grammar checker.

The independent root clause-ownership audit and focused disposable evidence diagnostic have validated the cross-dialect major-version architecture: a generic SQL-region frame selects ownership for open clause kinds through one generic root-frame-aware continuation primitive; dedicated owner-sensitive GROUP BY / ORDER BY parts persist the selected owner; bounded semantic render scopes apply Duck's contextual qualification rules only to the affected children. PIVOT is a consumer of this shared composition architecture, not the owner of it.

The structural ownership matrix passed the required nested SELECT/PIVOT, nested PIVOT, set-result/CTE, copied-`parts`, external-extension, binding-order, QueryParts/builder, raw-composition, and byte-for-byte PostgreSQL/MySQL compatibility cases. `PIVOT-CLAUSE-OWNERSHIP-001` is closed, and the corresponding structural-frame + dedicated-clause implementation is now production source in the 2.0.0 line.

Do not automatically escalate to semantic statement objects. Do not implement Duck-specific frame routing, scan receiver history for PIVOT, use free-floating forward ownership directives, infer ownership from paths/tables, or expose `belong: .pivot` / PIVOT-specific wrappers in ordinary query source.

## Native validation evidence

### DUCK-019 - Native validation is a release gate for grammar-sensitive features

Renderer tests prove SQL output, not DuckDB parser/binder/execution acceptance.

For new grammar-sensitive Duck features, native DuckDB validation is required when the API relies on assumptions that string tests cannot prove.

Native DuckDB v1.5.5 validation has already established:

- COLUMNS regex prepared form;
- COLUMNS explicit-name prepared form;
- COLUMNS lambda prepared form;
- corrected nested STRUCT/UNION identifier cases;
- the complete MERGE B1-B11 matrix described in DUCK-020B;
- the complete PIVOT qualification/binding matrix described in DUCK-017.

The first-closure mandatory native matrix is complete against DuckDB v1.5.5: 15/15 validation domains and 986/986 accepted native cases passed, including 834 positive cases and 152 retained-negative cases. Required public probes, mapping edges, source shapes, SQL fixtures, fail-closed self-tests, public-correlation self-tests, and final assertions also passed.

Future Duck waves must add their own native cases rather than treating this completed first-closure matrix as proof for newly added grammar/features.

## DML / DDL and advanced statements

### DUCK-020 - SQL fidelity for advanced statements

Duck DML/DDL support is additive and exact-SQL oriented.

The implemented first-closure advanced-statement surface includes validated INSERT/UPDATE/DELETE compatibility plus approved Duck extensions, CREATE/ALTER/DROP forms, schemas, enums/types, sequences, indexes, MERGE, COPY, macros, and catalog/database statements. Exact support/negative boundaries are recorded in the sections below; do not infer broader support from the family name alone.

Do not hide unsupported Duck semantics behind PostgreSQL-looking helpers. Examples from research include PostgreSQL index methods and unsupported constraint/foreign-key behaviors that must remain unclaimed unless current Duck documentation/native tests prove support.

Keep the detailed Duck feature/negative matrix in this file as future advanced areas are added and native-validated; do not duplicate Duck-specific support claims in the common dialect owner.

### DUCK-020A - Ordinary DML support and unclaimed boundaries

The verified DuckDB v1.5.5 ordinary-DML contract is:

- `INSERT ... VALUES` and `INSERT ... SELECT` are supported with normal SQL-shaped composition and prepared values. A String supplied as a table target is a structural identifier and does not become a value bind.
- `INSERT ... BY NAME` is supported when the source is a `SELECT`; matching is by source and target column name, including omitted target columns that have defaults. `BY NAME VALUES` is rejected by DuckDB and remains mechanically renderable but unclaimed by SQL.
- `INSERT OR IGNORE` and `INSERT OR REPLACE` are supported as their exact SQL identities. SQL does not remap either form by dialect or expose them as a portable conflict policy.
- The direct INSERT source is `SQL.insert.or.ignore.into[table: table]` or `SQL.insert.or.replace.into[table: table]`, optionally followed by `.fields(...)`; INSERT BY NAME uses `.by.name`.
- `ON CONFLICT DO NOTHING` without a target and `ON CONFLICT (<column>) DO NOTHING` with a column target are supported. Column-target `DO UPDATE SET` using the `EXCLUDED` source, with an optional `WHERE`, is supported when expressed through the ordinary SQL-shaped `set(_:)` composition.
- Historical `ON CONFLICT ON CONSTRAINT ...` remains mechanically renderable for compatibility, but DuckDB v1.5.5 rejects it as unimplemented; it is unclaimed for Duck.
- `INSERT ... RETURNING` and `DELETE ... RETURNING` support structural columns, `*`, and literal expressions. DuckDB v1.5.5 rejects prepared parameters inside these RETURNING expressions during preparation. SQL preserves ordinary binding and does not add runtime validation or rejection for that database limitation.
- Ordinary `UPDATE` `SET`, `FROM`, and scalar-subquery `SET`/`WHERE` forms are supported and remain direct SQL composition. Multi-target `UPDATE` is rejected by DuckDB v1.5.5 and remains mechanically renderable but unclaimed. `UPDATE ... RETURNING` executes in the verified runtime but remains mechanically expressible and unclaimed because the current official Duck UPDATE contract does not document it.
- `DELETE ... USING` supports table sources, an aliased parenthesized subquery source, and multiple comma-separated sources. In the verified qualified RETURNING boundary, target-qualified columns are accepted while source-qualified columns are rejected because the USING source is not visible to RETURNING; the latter remains unclaimed without SQL-side runtime rejection. Columns, `*`, literal expressions, and USING composition otherwise remain direct SQL forms.
- Basic `TRUNCATE <table>` is supported, including schema-qualified structural table targets.

These are feature-specific support and unclaimed claims for the verified runtime,
not a general portability promise. These ordinary-DML boundaries were included
in the final Duck closure revalidation before `.duck` was added to
`SQLDialect.all`, and they remain the exact current support/non-claim boundary
for this section.

### DUCK-020B - MERGE direct-composition contract and native boundaries

DuckDB v1.5.5 native validation establishes the following MERGE contract:

- `SQL.merge(into:using:on:)` and the incremental
  `SQL.merge(into:).using(...).on(...)` form are composition-equivalent
  generic SQL builders. Neither form introduces a Duck-only builder, AST, or
  renderer hook.
- Structural table targets, source tables, aliases, parenthesized source
  queries, prepared predicates, and normal left-to-right binding all work.
- Duck's one- and multi-column `USING (<columns>)` shorthand is supported and
  renders structural last-path identifiers. The public `using(columns:)`
  overload is a structural column-name API: a qualified key path is reduced by
  SQL to its last path. Separately, raw qualified source/target expressions
  in Duck's `USING (<columns>)` grammar are native-invalid.
- `WHEN MATCHED`, `WHEN NOT MATCHED`, `WHEN NOT MATCHED BY SOURCE`, and
  `WHEN NOT MATCHED BY TARGET` branches preserve append order and reuse the
  established `.then.update.set(...)`, `.then.delete`, `.then.insert`,
  `.then.insert.by.name`, and
  `.then.insert.fields(...).values.values(...)` action vocabulary.
- MERGE branch predicates are direct atomic composition: `merge.when.matched.then...`, `merge.when.not.matched.then...`, `merge.when.not.matched.by.source.and(condition).then...`, and `merge.when.not.matched.by.target.then...`.
- Conditional branches, multi-column updates, whole-row updates, conditional
  deletes, INSERT BY NAME, explicit-column INSERT values, a BY SOURCE explicit
  column/value INSERT whose values do not depend on a source row, and the
  verified transaction rollback boundary execute with normal prepared
  parameters.
- MERGE `RETURNING` exposes the bare Duck `merge_action` identifier, `*`,
  target columns, and expressions. `merge_action()` is a different unsupported
  function-shaped form and is not synthesized by SQL.
- A complete fail-closed B1-B11 matrix verified runtime identity
  `v1.5.5`, prepare/bind/execute status, parameter counts, every bind,
  results/post-state, branch order, transaction behavior, RETURNING visibility,
  BY SOURCE/BY TARGET, INSERT BY NAME, USING shorthand, and the required
  dangerous siblings.

The following remain mechanically renderable but unclaimed or rejected by
DuckDB v1.5.5: raw qualified `USING` shorthand (the public overload emits
unqualified last paths), `MATCHED BY TARGET`, UPDATE/DELETE actions on
`NOT MATCHED BY TARGET`, DELETE on `NOT MATCHED`, bare or source-dependent
INSERT actions on `NOT MATCHED BY SOURCE` because that branch has no source-row
visibility, source-qualified MERGE RETURNING expressions, prepared parameters
inside MERGE RETURNING, and function-shaped `merge_action()`. Explicit
column/value INSERT under `NOT MATCHED BY SOURCE` is supported when its values
are target-independent. These boundaries are native engine behavior; SQL
keeps MERGE as direct SQL composition and does not translate it to an upsert
form.

## Table DDL support and per-action classification

### DUCK-020C - CREATE and ALTER TABLE are claimed per SQL action

DuckDB v1.5.5 validation establishes the following feature-specific table-DDL
claims. These claims do not make `CreateTableBuilder`, `NewColumn`,
`UpdateTableBuilder`, or any other historical builder broadly Duck-compatible.
Mechanically rendered forms remain available for compatibility even when they
are explicitly unclaimed for Duck.

CREATE TABLE:

| Source shape or method | Duck classification |
| --- | --- |
| `CreateTableBuilder` basic typed columns | Supported for the exact emitted SQL, including schema-qualified and safely quoted identifiers. This is not a builder-wide claim. |
| `CreateTableBuilder.checkIfNotExists()` | Supported; repeated creation preserves the existing table and data under `IF NOT EXISTS`. |
| `ColumnDefault.default(_:)` | Supported for safe literal values, `NULL`, date, and exact expression source shapes. Use the value overload when a literal must be inline and bind-free. |
| `NewColumn.default(constant:)` | Mechanically preserved but unclaimed: the established source emits a value without the `DEFAULT` keyword, which is not valid Duck CREATE TABLE syntax. |
| `NewColumn.default(expression:)` and `default(sequence:)` | Mechanically preserved; only exact SQL-shaped expressions that include the required grammar are claimable. No sequence-specific Duck claim is made here. |
| Primary key, unique, not-null, check, and named check constraints in CREATE | Supported when the emitted constraint syntax is exact; native enforcement was verified for primary key, unique, not-null, unnamed check, and named check. |
| `Constraint.references` at CREATE time | Supported for the established omitted-referenced-column source shape when the parent table supplies a suitable key. The source shape has no referenced-column-list argument. `ReferentialAction.noAction` and `.restrict` are supported; `.cascade`, `.setNull`, and `.setDefault` remain unclaimed because DuckDB rejects those foreign-key actions. |
| Direct CTAS composition | Supported for `CREATE TABLE ... AS SELECT ...` using existing structural parts. |
| Direct OR REPLACE CTAS composition | Supported through `SQL.create.or.replace.table[any: table]` and ordinary CTAS composition; no phrase convenience builder is needed. |
| CTAS with a column constraint list | Unclaimed/negative: DuckDB rejects constraints combined with the tested CTAS form. |
| Inferred generated column | Supported through `GeneratedColumn(name, as: expression)` inside `tableDefinitions(...)`. |
| Explicit `GENERATED ALWAYS AS ... VIRTUAL` and omitted `VIRTUAL` | Supported through `GeneratedColumn(name, type, generatedAlwaysAs: expression, storage: .virtual)` or omitted storage; omitted `VIRTUAL` follows DuckDB's virtual default. |
| `GENERATED ALWAYS AS ... STORED` | Mechanically renderable through `GeneratedColumn(..., storage: .stored)` but unclaimed/negative: DuckDB rejects stored generated columns. Direct insert into a generated column is also rejected by the engine. |
| Generated expressions containing prepared parameters | Unclaimed/negative at native prepare time; the renderer preserves ordinary value binding and does not add runtime rejection. |

ALTER TABLE:

| `UpdateTableBuilder` method or source action | Duck classification |
| --- | --- |
| `renameTable(to:)` | Supported as the emitted standalone `ALTER TABLE ... RENAME TO ...` statement. |
| `addColumn` basic overloads | Supported for a basic column; the string overload's `checkIfNotExists` form is also supported. Correct `ColumnDefault` source is supported. |
| `addColumn` with `NewColumn` constant defaults or column constraints | Mechanically preserved but unclaimed where the established source emits malformed default grammar or DuckDB rejects add-column constraints. |
| `dropColumn` | Supported for simple, `IF EXISTS`, and `CASCADE` forms, subject to DuckDB dependency/data preconditions. Missing-column and dependent-key failures remain native errors. |
| `setDefault` constant/expression overloads | Supported for exact literal/expression source shapes. The sequence overload remains mechanically rendered and unclaimed in this wave. |
| `dropDefault` | Supported. |
| `setNotNull` | Supported when existing rows satisfy the constraint; native failure for existing `NULL` values is preserved. |
| `dropNotNull` | Supported. |
| `renameColumn` | Supported as the emitted standalone rename statement. |
| `addPrimaryKey` | Supported for single- and multi-column keys, with native duplicate enforcement. |
| `addUnique` | Mechanically preserved but unclaimed: DuckDB v1.5.5 rejects the emitted ALTER action. |
| `addCheck` named and unnamed | Mechanically preserved but unclaimed: DuckDB v1.5.5 rejects both emitted ALTER actions. |
| `addForeignKey` named and unnamed | Mechanically preserved but unclaimed: DuckDB v1.5.5 rejects both emitted ALTER actions. |
| `dropConstraint` | Unclaimed: the established method emits a standalone `DROP CONSTRAINT ...` without `ALTER TABLE`; DuckDB rejects that historical form, and the tested `ALTER TABLE ... DROP CONSTRAINT` form is not implemented by DuckDB v1.5.5. |
| Historical comma-combined actions | Duck-unclaimed as one statement. DuckDB accepts the individually supported actions but rejects a combined `ALTER TABLE` statement with multiple actions. The historical batching and builder output remain unchanged; SwifQL does not split statements by dialect. |
| Direct `ALTER COLUMN ... TYPE`, `SET TYPE`, `SET DATA TYPE`, and `USING` composition | Supported through atomic `.alter.column[any: column].type(...)`, `.set.type(...)`, and `.set.data.type(...).using(...)` composition; all tested type spellings and the conversion `USING` boundary passed native validation. |
| `dropIndex` and `createIndex` actions | Outside this table-DDL claim; no Duck support is asserted by this matrix. |

All unsupported or unclaimed forms above remain mechanically renderable. The
Duck renderer does not add runtime rejection, and no Duck-specific table DDL
wrapper or broad builder conformance is implied. Transaction rollback of table
DDL was separately verified. The first Duck closure is complete and `.duck`
is now part of `SQLDialect.all`; the table-DDL support/non-claim boundary above
remains exact.

### DUCK-026 - Schema-level DDL is claimed per exact source/action

The following claims are limited to the direct SQL-shaped source and exact
actions exercised against DuckDB v1.5.5 (`d8cdaa33fd`, codename `Variegata`).
They do not make a historical builder broadly Duck-compatible, and they do not
claim that an emitted statement is portable to another dialect.

| Source/action | DuckDB v1.5.5 classification |
| --- | --- |
| Direct `CREATE SCHEMA`, `IF NOT EXISTS`, and empty `OR REPLACE` | Supported; quoted edge-case names and transactional create/drop rollback were verified. |
| Non-empty `OR REPLACE SCHEMA` with a child object | Native dependency error; the existing schema and child remain. |
| `DROP SCHEMA` default/`RESTRICT`, `CASCADE`, and `IF EXISTS` | Default and `RESTRICT` reject dependent objects; `CASCADE` removes the tested dependency; missing `IF EXISTS` succeeds. |
| Existing `CreateSchemaBuilder` and `DropSchemaBuilder` | Historical source and exact output are preserved; no broad Duck builder claim is made. |
| Direct regular, `OR REPLACE`, replacement-column, schema/catalog-qualified, quoted-name, `TEMP`, and `TEMPORARY` view source | Supported for the tested actions. Schema-qualified temporary views are native-invalid. |
| Direct `ALTER VIEW ... RENAME`, `DROP VIEW` default/`RESTRICT`/`CASCADE`/`IF EXISTS`, and transactional rename rollback | Supported for the tested actions. Dependent view names are not rewritten, and a dependent view can remain stored but broken after its source view is dropped. |
| Prepared values in `CREATE VIEW` structural/name positions | Native-invalid; child query value parameters remain ordinary prepared bindings where the query grammar accepts them. |
| Direct ENUM label literals, ENUM-from-`SELECT`, schema-qualified types, `STRUCT`, `UNION`, and scalar aliases used by actual tables/queries | Supported for the tested actions. Literal labels are parser string literals (including apostrophe/Unicode/quoted-label cases), not ordinary value binds; SELECT input deduplicates and ignores `NULL`. |
| Type `OR REPLACE`, `IF NOT EXISTS`, `DROP TYPE`, and transaction rollback | The tested replace/if-not-exists/rollback actions are supported. Dropping a used type leaves the tested table metadata in place; no stronger dependency claim is made. |
| Direct basic, unique, `IF NOT EXISTS`, compound, expression, schema-target, quoted-name, `USING ART`, and transactional index source | Supported for the tested actions; unique enforcement was verified. `OR REPLACE` is native-invalid. |
| Direct index methods `BTREE`, `HASH`, `GIST`, `GIN`, `SPGIST`, and `BRIN`; partial-index `WHERE` source | Native-invalid in the tested v1.5.5 boundary. `ART` is the verified positive method. |
| Direct `DROP INDEX` default/qualified/`IF EXISTS`/`RESTRICT`/`CASCADE` | Supported for the tested actions, including rollback. |
| Historical `UpdateTableBuilder.createIndex`/`dropIndex` and `IndexItem` | Byte-for-byte source/output compatibility is preserved and independently probed; no Duck support is claimed for historical forms that fall outside the direct positive matrix. |

All rows are feature/action claims, not a promise that every spelling exposed
by the general SQL composer executes on DuckDB. Unlisted forms remain
mechanically renderable and unclaimed.

### DUCK-027 - Sequence and macro support is claimed per exact source/action

Fail-closed native validation passed against DuckDB v1.5.5, source
d8cdaa33fd, codename Variegata. The validation covered query success,
prepare/bind/execute status, result values, catalog post-state, two-connection
visibility, transaction behavior, dependency behavior, and the required
negative parser/binder boundaries. The following claims are limited to the
direct source shapes below; they do not make historical DDL builders broadly
Duck-compatible.

#### Sequences

| Source/action | DuckDB v1.5.5 classification |
| --- | --- |
| CREATE SEQUENCE, OR REPLACE, IF NOT EXISTS, and schema-qualified persistent names | Supported for the tested exact forms. OR REPLACE resets options/current value; IF NOT EXISTS preserves the existing sequence. OR REPLACE combined with IF NOT EXISTS is a native parser error. |
| TEMP / TEMPORARY sequence creation and drop | Supported for the tested exact forms. The temporary object is visible in its creating connection and absent from the second connection. Explicitly schema-qualifying a temporary sequence is native-invalid. |
| START, START WITH, signed nonzero INCREMENT BY, MINVALUE, MAXVALUE, CYCLE, and their NO siblings | Supported as direct value-bearing composition. Sequence metadata is BIGINT-shaped. INCREMENT BY 0 is a native parser error. Positive and negative increments, explicit bounds, no-cycle boundaries, and ascending/descending cycle wrap were verified. |
| Quoted reserved, Unicode, and embedded-double-quote sequence names | Supported for the tested create/catalog/drop forms through Path.Identifier; the embedded-name nextval string spelling remains DuckDB utility-parser territory. |
| DROP SEQUENCE default, IF EXISTS, RESTRICT, CASCADE, and create/drop rollback | Supported for the tested exact actions. Dependency-sensitive default expressions are classified separately below. |
| Prepared placeholders in sequence option positions | Native-invalid at prepare/parse time for START, START WITH, INCREMENT BY, MINVALUE, and MAXVALUE. SQL keeps the numeric option methods safe-inline and does not add a dialect-specific runtime rejection. |
| Int64 upper-bound literals | The tested literal 9223372036854775806 with MAXVALUE 9223372036854775807 is accepted and returns the exact start value. No broader overflow guarantee is claimed. |

Fn.nextVal and Fn.currVal intentionally accept ordinary SQLable children. A
String therefore renders as a normal Duck string literal in .plain and remains
a normal prepared value in .splitted; prepared invocation with a name,
including a schema-qualified name string, was native-positive. currval before
any nextval reports DuckDB's “sequence is not yet defined in this session”
sequence error. In the pinned v1.5.5 two-connection matrix, after one
connection advances a sequence, currval in the other connection succeeds and
observes the latest sequence value; the first connection also observes that
latest value. Sequence consumption is not rewound by transaction rollback.

The explicit expression source SQL.default(Fn.nextVal("order_id_seq")) is
supported in the tested CREATE TABLE and insert flow. A literal sequence name
in a default is native-positive. A prepared parameter inside DEFAULT
nextval(?) is rejected by DuckDB's binder, and the tested ALTER TABLE ...
DEFAULT nextval(?) prepare path returns DuckDB's multiple-statement
preparation diagnostic. Dropping a sequence with a live table default is
dependency-blocked by RESTRICT; CASCADE removes the tested dependent table.
Removing the default first through SET DEFAULT NULL or DROP DEFAULT permits
the sequence drop. The historical NewColumn.default(sequence:) spelling
remains mechanically preserved and unclaimed, and Type.auto(...,
isPrimary: true) continues to emit PostgreSQL serial/bigserial; neither
shortcut is a Duck sequence claim.

#### Macros and function calls

| Source/action | DuckDB v1.5.5 classification |
| --- | --- |
| Scalar zero-parameter, untyped positional, typed, and mixed-typed macros | Supported for the tested direct forms. Duplicate parameter names are rejected natively. |
| Scalar OR REPLACE, IF NOT EXISTS, TEMP / TEMPORARY, persistent schema-qualified names, quoted names, and transaction create/drop rollback | Supported for the tested exact forms. OR REPLACE combined with IF NOT EXISTS is a native parser error. Temporary macros are isolated from the second connection; schema-qualified temporary macros are native-invalid. |
| CREATE FUNCTION as a macro alias and DROP FUNCTION | Native-positive for the tested scalar alias form. SQL reuses existing .function atoms; no separate function builder is claimed. |
| DROP MACRO, optional TABLE, IF EXISTS, RESTRICT, and CASCADE | Supported for the tested exact forms, including both table-macro drop spellings where native-positive. |
| Prepared scalar macro invocation arguments | Native-positive with ordinary prepared values. A prepared value embedded in a macro body is native-invalid; a prepared constant macro body is native-positive. |
| Macro dependency and transaction behavior | Dropping a base macro can leave a derived macro stored but invalid when invoked; the tested create/drop rollback boundaries restore catalog state. |
| Zero-parameter, untyped, and typed AS TABLE macros; invocation in FROM | Supported for the tested exact forms. Prepared table-macro invocation arguments are native-positive. |
| Table-macro temporary isolation and drop forms | Temporary table macros are isolated from the second connection. DROP MACRO TABLE and the tested optional-table spelling are native-positive. |
| Fn.call(Path.Identifier, ...) | Generic unqualified, schema-qualified, and catalog-plus-schema-qualified identifier paths with zero, one, or multiple ordinary arguments are supported as direct function-call composition. The terminal name uses SQLDialect.identifier(_); catalog/schema/table/column/alias hooks remain distinct. |
| Native macro defaults/named calls using := | Native-positive in the pinned runtime, including default and named calls; invalid default ordering is rejected natively. This public abstraction remains intentionally deferred under DUCK-025. |
| Native macro overload definitions | Native-positive for the tested multi-signature form. Overload infrastructure remains unclaimed/deferred because it would require a structured multi-signature statement representation. |

The canonical public source remains direct composition:

~~~swift
let sequence = Path.Identifier(schema: "analytics", name: "order_id_seq")

SQL.create.sequence.if.not.exists[any: sequence]
    .start(with: 1)
    .increment(by: 2)
    .minValue(1)
    .maxValue(99)
    .cycle

SQL.default(Fn.nextVal("order_id_seq"))

let x = MacroParameter("x")
let typed = MacroParameter("value", .integer)

SQL.create.macro[any: Path.Identifier("twice")]
    .macroParameters(x)
    .as(x * 2)

SQL.create.macro[any: Path.Identifier("rows")]
    .macroParameters(typed)
    .as.table
    .select(typed)

Fn.call(Path.Identifier("twice"), 21)
~~~

MacroParameter is value-semantic and bind-free. Its ordinary SQLable parts
contain only the immutable structural parameter reference name. The
macroParameters(...) constructor owns declaration syntax and appends the
optional exact type spelling. Both roles route the name through the generic
identifier hook; no macro-specific state or dialect hook exists. It has no
uniqueness/type validation, default-value field, or product-specific prefix.
macroParameters is the sole focused parenthesized list constructor; the
scalar/table source uses the existing generic .as expression overload and
.as.table atoms. No asTable, macro builder, overload builder, or raw macro-body
escape hatch is part of the claimed surface.

### DUCK-028 - ATTACH, DETACH, and USE catalog integration is claimed per exact source/action

The direct catalog-management source is generic SQL composition over the
existing `Path.Catalog` namespace type. Native validation covers the exact
source shapes and actions below against DuckDB v1.5.5 (`d8cdaa33fd`, codename
`Variegata`). It does not make a broad Duck-specific builder or execution API
claim.

#### ATTACH

The canonical public source is:

~~~swift
let analytics = Path.Catalog("analytics")

SQL.attach("warehouse.duckdb", as: analytics)
SQL.attach(
    "warehouse.duckdb",
    mode: .ifNotExists,
    as: analytics,
    options: [.readOnly, .blockSize(16_384)]
)
~~~

The emitted order is exactly:

~~~text
ATTACH [OR REPLACE | IF NOT EXISTS] <source> [AS <catalog>] [(options)]
~~~

`AttachMode.none`, `.ifNotExists`, and `.orReplace` are the only mode values.
The ATTACH source is a parser String literal in pinned DuckDB v1.5.5. The
canonical `attach(String, ...)` overload safely appends that source inline in
both `.plain` and `.splitted` preparation through the normal dialect string
literal renderer, so dynamic String content is escaped and the source
contributes zero binds. DuckDB v1.5.5 accepts a literal string source but
rejects `?`, an arbitrary source expression, `NULL`, and a non-string source at
its parser boundary. Value-bearing ATTACH options remain ordinary bindable
expressions.

An omitted `as:` lets DuckDB infer the catalog name from the source. An
explicit `as:` accepts only `Path.Catalog`; the alias is a structural catalog
name rendered through `SQLDialect.catalogName(_:)` and never becomes a bind.
Reserved, Unicode, and embedded-double-quote catalog names use the existing
catalog renderer and path semantics.

`AttachOption` is a value-semantic structured option. Its open
`AttachOption.Name` initializer permits downstream option names; the option
list owns parentheses and comma ordering, and an option renders as `NAME` or
`NAME <value>`. The verified core conveniences are:

| Option | Native boundary in the validated source shapes |
| --- | --- |
| `READ_ONLY` | Name-only option; read-only attachment succeeds and write attempts fail natively. |
| `COMPRESS` | Unquoted and quoted values, arbitrary expression values, and prepared values succeed for an in-memory database. |
| `TYPE` | Unquoted and quoted `duckdb` values, arbitrary expression values, and prepared values succeed. Extension-specific type values are not claimed. |
| `DEFAULT_TABLE` | Quoted and prepared values succeed; direct catalog references use the configured table. |
| `BLOCK_SIZE` | Valid literal and prepared values succeed for a new local database file; invalid non-power-of-two values remain native errors. |
| `ROW_GROUP_SIZE` | Valid literal and prepared values succeed for a new local database file; invalid values remain native errors. |
| `STORAGE_VERSION` | Valid quoted values (`v1.0.0` and `latest`) and prepared values succeed; unknown versions remain native errors. |
| `ENCRYPTION_KEY` | Quoted and prepared values succeed in the validated local attachment form. Secrets and external key-management behavior are outside this claim. |
| `ENCRYPTION_CIPHER` | Valid quoted and prepared values succeed when paired with an encryption key; invalid cipher names remain native errors. |
| `RECOVERY_MODE` | Valid unquoted and prepared values succeed; invalid enum values remain native errors. |

DuckDB also accepts the compatibility token `READ_WRITE` in the validated
runtime, but SQL intentionally exposes no convenience for it. The current
runtime rejects `ACCESS_MODE`; it is not part of the public option domain.
Remote HTTP/S3 sources and extension-specific database actions remain
unclaimed. `IF NOT EXISTS` preserves an existing attachment, `OR REPLACE`
replaces an alias when given a distinct local source, their combination is a
native parser error, and attachment changes participate in transaction
rollback.

#### DETACH

The public source is structural and bind-free:

~~~swift
SQL.detach(Path.Catalog("analytics"))
~~~

DuckDB rejects detaching the current default database. Use another catalog
first, then detach the former default. Missing catalogs and qualified access
after detachment retain DuckDB's native binder errors.

#### USE

The exact overloads are:

~~~swift
SQL.use(Path.Catalog("analytics"))
SQL.use(Path.Schema("reporting"))
SQL.use(Path.Catalog("analytics").schema("reporting"))
~~~

All three targets are structural and bind-free. The catalog overload changes
the current catalog and uses its `main` schema; the schema overload resolves
the schema in the current catalog; the catalog-and-schema overload selects
both explicitly. The validated one-component conflict resolves as a schema in
the current catalog. `current_catalog()` and `current_schema()` expose the
resulting state. Attachments and the selected default catalog are connection
state: a second connection does not see an attachment created by the first.

Catalog-qualified object paths continue to use the established generic path
chain:

~~~swift
Path.Catalog("analytics")
    .schema("reporting")
    .table("events")
    .column("id")
~~~

The catalog, schema, table, column, and alias renderers remain distinct. No
second database/catalog identifier type is introduced. The first Duck closure
is complete and `.duck` is now part of `SQLDialect.all`; the
ATTACH/catalog/session support/non-claim boundary above remains exact.

### DUCK-029 - COPY and table-file functions are claimed per exact source/action

The direct COPY and table-file surface is generic SQL composition over the
existing structural path types and function system. Native validation covers
the exact source shapes and actions below against DuckDB v1.5.5
(`d8cdaa33fd`, codename `Variegata`). It does not make a broad Duck-specific
execution, file-management, or extension-management claim.

#### COPY

The canonical public sources are:

~~~swift
let events = Path.Table("events")
let source = Path.Catalog("source")
let destination = Path.Catalog("destination")

SQL.copy(events, to: "events.parquet", options: .format("parquet"))
SQL.copy(events, from: "events.csv", options: .format("csv"), .header)
SQL.copy(
    query: SQL.select(events.column("id")).from(events),
    to: "events.json",
    options: .format("json")
)
SQL.copy(fromDatabase: source, to: destination, options: .schema)
~~~

The claimed statement forms are exactly:

~~~text
COPY <structural table> TO <ordinary destination> [(options)]
COPY <structural table> FROM (<ordinary source>) [(options)]
COPY (<query>) TO <ordinary destination> [(options)]
COPY FROM DATABASE <structural catalog> TO <structural catalog> [(SCHEMA)]
~~~

Table targets and both database catalogs are structural and bind-free. File
paths, query children, COPY destinations, and option values remain ordinary
SQLable values and retain normal preparation behavior. Query children are
rendered inside the single parenthesized query source before the destination
and option values in the normal child order.

The pinned runtime accepts both direct prepared `COPY table FROM $1` and
parenthesized prepared `COPY table FROM ($1)`. Parenthesized source syntax is
the stable public representation because it also covers arbitrary expressions
and one exact source shape works for literal, prepared, and expression
inputs. The renderer does not branch on preparation mode and the public
builder never emits a direct unparenthesized source.

`CopyOption` is a value-semantic structured option with an open
`CopyOption.Name` initializer. An option renders as `NAME` or `NAME <value>`;
the statement owns parentheses, comma ordering, and the option list. The
verified first-release conveniences are:

| Option | Public form |
| --- | --- |
| `FORMAT` | `CopyOption.format(_:)` |
| `HEADER` | `CopyOption.header` and `CopyOption.header(_:)` |
| `DELIMITER` | `CopyOption.delimiter(_:)` |
| `COMPRESSION` | `CopyOption.compression(_:)` |
| `NULL` | `CopyOption.null(_:)` |
| `ARRAY` | `CopyOption.array` and `CopyOption.array(_:)` |
| `ROW_GROUP_SIZE` | `CopyOption.rowGroupSize(_:)` |
| `COMPRESSION_LEVEL` | `CopyOption.compressionLevel(_:)` |
| `SCHEMA` | `CopyOption.schema` for `COPY FROM DATABASE` |

The option name domain remains open so downstream native options do not require
a library change. Direction/format combinations are left to DuckDB. Native
partitioned-write and return-file behavior was characterized but is not part
of this first public convenience set; neither are overwrite/append helpers.

#### Table functions and glob

The final SQL-shaped canonical helper identities are:

~~~swift
Fn.readCSV("events.csv", options: .header(true), .delimiter("|"), .sampleSize(2))
Fn.readParquet("events.parquet", options: .unionByName(true))
Fn.readJSON("events.json", options: .format("array"))
Fn.glob("*.parquet")
~~~

They emit `read_csv`, `read_parquet`, `read_json`, and `glob`, respectively,
and compose through the ordinary existing `.from(...)` API. The pinned runtime
autoloads the tested JSON support; no explicit extension-management behavior
is part of the claim. `read_csv` covers the verified `header`, `delim`, and
`sample_size` options. `read_parquet` covers the verified `union_by_name`,
`filename`, and `hive_partitioning` options. `read_json` covers the verified
`format` option.

`TableFunctionOption` is a value-semantic structured option with an open
`TableFunctionOption.Name` initializer. Its exact grammar is `name = value`,
with the name structural and the value an ordinary bindable SQLable child.
The option list preserves positional-before-named and named-option ordering.
This exact table-function grammar is distinct from the deferred generic
`name := expression` abstraction; no `:=` primitive is introduced here.

Single paths and glob patterns are claimed. Duck LIST multiple-file input was
native-characterized but is not claimed by the public API because no new
multiple-file list representation was required or frozen. The first Duck
closure is complete and `.duck` is now part of `SQLDialect.all`; the
COPY/table-function support/non-claim boundary above remains exact.

### DUCK-030 - Expression Frontier quantified/aggregate native boundary

DuckDB v1.5.5 (`d8cdaa3`, `Variegata`) was natively probed for the declarative expression frontier before any production implementation.

Quantified comparison support is positive for all of the following exact shapes:

```sql
2 = ANY (SELECT ...)
2 = SOME (SELECT ...)
2 > ALL (SELECT ...)

2 = ANY ([1, 2, 3])
2 = SOME ([1, 2, 3])
4 > ALL ([1, 2, 3])

2 = ANY (array_value(1, 2, 3))
4 > ALL (array_value(1, 2, 3))

2 = ANY (ARRAY(SELECT ...))
4 > ALL (ARRAY(SELECT ...))
```

Typed empty LIST semantics matched quantified SQL expectations in the pinned runtime: `ANY` over an empty rhs returned false and `ALL` returned true. PostgreSQL-shaped row-valued quantified subqueries such as `row(1, 2) = ANY (SELECT a, b ...)` also parsed, bound, and executed successfully.

This does **not** make PostgreSQL `ARRAY[...]`, Duck LIST literals, and Duck fixed ARRAY constructors one portable constructor. The public DSL must preserve their exact SQL/type identities while allowing the same quantified-comparison semantic family to accept dialect-supported operand forms.

Ordered-set and hypothetical-set support is intentionally asymmetric:

- `percentile_cont(...) WITHIN GROUP (ORDER BY ...)`, `percentile_disc(...)`, and `mode()` executed successfully;
- hypothetical-set `rank(...)`, `dense_rank(...)`, `percent_rank(...)`, and `cume_dist(...)` with `WITHIN GROUP` were parser-rejected as unknown ordered aggregates.

Do not rewrite the rejected hypothetical-set forms to differently named Duck functions or window functions.

Aggregate modifier behavior in the pinned runtime also confirms:

- `FILTER (WHERE predicate)` and `FILTER (predicate)` both execute;
- comma-separated FILTER predicates are parser-invalid;
- `array_agg(DISTINCT x ORDER BY x DESC)` executes;
- with aggregate DISTINCT, an ORDER BY expression not present in the DISTINCT argument list is binder-rejected.

These facts refine capability claims only. They do not authorize source mutation, change the SQL-first ownership defined by DESIGN-025, or make every PostgreSQL aggregate/window combination a Duck equivalent.

## Catalog paths

### DUCK-021 - Catalog is a SQL namespace concept, not a Duck-branded user concept

Public catalog qualification should use a clean generic SQL namespace API rather than a Duck-branded user concept. Target direction is:

```swift
Path.Catalog("warehouse")
    .schema("reporting")
    .table("events")
```

with dialect-aware rendering/support determining where catalog qualification is valid.

If an internal Duck-specific helper remains necessary, use `duck...` naming.

## Pre-release evolution gate

### DUCK-022 - Published beta API changes require explicit compatibility judgment

The first validated Duck surface is published in the `2.0.0-beta.5.0.0` pre-release. It is therefore real public pre-release API and must not be described as unreleased merely because final `2.0.0` has not been declared stable.

A later 2.0 beta may still correct a genuinely mistaken beta-only API when the major version has not reached stable release, but the change must explicitly account for the already-published pre-release surface instead of assuming that no users can depend on it. Do not add compatibility aliases mechanically; add them only when the compatibility value justifies the permanent API cost.

The canonical published Duck dialect spelling is `.duck`. No `.duckdb` compatibility alias is currently required because `.duckdb` was not the canonical spelling of the released Duck surface. Future Duck API additions still require the full API review described by DUCK-023.

This rule does not authorize changing established pre-Duck SwifQL APIs used by existing users.

### DUCK-023 - API-surface review for future Duck feature waves

Before any future Duck feature implementation begins, classify the intended new Duck surface into:

1. reuse existing SwifQL API unchanged;
2. generic clean SQL-concept API;
3. clean inferred helper type that users normally do not name;
4. genuinely Duck-specific implementation symbol using `Duck...` / `duck...`;
5. unresolved UX requiring focused research.

The first 2.0.0 closure already completed this review for PIVOT, UNPIVOT, MERGE, COLUMNS, star modifiers, nested values, sequences, macros, catalog paths, sampling, and COPY/ATTACH option types. Apply the same classification discipline to later administration/runtime and extension-specific families rather than reopening the completed first-closure decisions.

The `duck-sql-surface-redesign` research/classification, Gate A bounded semantic render-scope work, Gate B structural clause-ownership work, production implementation, native/public closure, and independent audits are complete for the first 2.0.0 Duck closure. Future source changes must follow the stable architecture and current release contract rather than repeating the completed broad API inventory or assuming that first-closure acceptance authorizes unrelated Duck expansion.

### DUCK-024 - First `.duck` closure boundary

The first `.duck` closure is complete. It covers and native-/compatibility-validates the ordinary application/analytics/schema surface approved by the maintainer: core rendering/binds/values/date behavior; paths/catalogs/JSON; exact scalar/nested types and values that do not require the deferred generic `:=` abstraction; high-value exact functions/operators; SELECT-family clauses; GROUPING SETS/ROLLUP/CUBE; lambdas/list functions; joins; set operations; star/COLUMNS; scope-proven PIVOT/UNPIVOT; DML/RETURNING/MERGE where clean composition is proven; truthful CREATE/ALTER/DROP for tables/schemas/views/types/indexes/constraints; sequences/macros where they do not require the deferred generic `:=` abstraction; ATTACH/DETACH/USE; COPY; common table/file functions; DuckDB v1.5.5 native validation; and downstream compatibility validation.

The completed closure adds `.duck` to `SQLDialect.all`, which is now `[.psql, .mysql, .duck]`.

Later typed waves do not retroactively block that closure: INSTALL/LOAD, CREATE SECRET, broad PRAGMA/configuration, CHECKPOINT, VACUUM/ANALYZE administration, SET/RESET VARIABLE, EXPORT/IMPORT DATABASE, SHOW/DESCRIBE/SUMMARIZE convenience, extension-specific SQL universes, and other administration/runtime families remain separate future work.

### DUCK-025 - Generic SQL `name := expression` is deferred

Do not introduce a premature generic `name := expression` public abstraction in the current Duck wave. STRUCT/UNION value constructors, macro defaults/named calls, or other features that strictly require a reusable first-class `:=` abstraction are deferred unless they can be represented cleanly through an already-established exact API without inventing a generic named-argument layer.

Do not conflate SQL `name := expression` with table-function `name = value` options. The future generic `:=` design remains explicit technical/API debt, not an implementation shortcut for this closure.
