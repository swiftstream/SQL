# SQL Source Map

This is a navigation aid, not an architecture contract. Use it to locate the smallest relevant source and test subset before broad discovery.

## Package

- `Package.swift` — SwiftPM tools 6.3 manifest, one `SQL` library target, one `SQLTests` test target, Swift 6 language mode.

## Core composition, preparation, and output

- `Sources/SQL/SQLable.swift` — public `SQLable`/`SQLPart`, structural-frame-aware `SQLableParts`, ordinary and observed preparation entrypoints.
- `Sources/SQL/PreparationObservation.swift` — single shared recursive preparation renderer/collector plus unsafe-value provenance model, complete/unavailable trace state, and zero-SQL observation-marker handling.
- `Sources/SQL/StructuralComposition.swift` — public structural SQL-region/frame model, open clause owner/kind identities, `structurallyAppending(_:)`.
- `Sources/SQL/Parts/GroupByPart.swift` — owner-sensitive GROUP BY part.
- `Sources/SQL/Parts/OrderByPart.swift` — owner-sensitive ORDER BY part.
- `Sources/SQL/Prepared.swift`
- `Sources/SQL/SplittedQuery.swift`
- `Sources/SQL/Formatter.swift`

## Declarative DDL authoring

- `Sources/SQL/CreateTable.swift` — accepted declarative CREATE TABLE surface: `TableDefinition`, `CreateTable`, existing `tableDefinitions(...)`, and the `NewColumn` / `GeneratedColumn` definition conformances.
- `Sources/SQL/GeneratedColumn.swift` — `GeneratedColumnStorage` and `GeneratedColumn` semantic value ownership.
- `Sources/SQL/AlterTable.swift` — accepted one-statement ALTER TABLE surface: `AlterTableAction`, string/type-only `AddColumn`, and `AlterTable`.
- `Sources/SQL/TypeDDL.swift` — generic TYPE / ENUM DDL composition helpers, including `type(_:)` and `enum(...)`.
- `Sources/SQL/ResultBuilders/TableDefinitionBuilder.swift` — restricted non-empty static table-definition result builder; no conditional/loop hooks.
- `Sources/SQL/ResultBuilders/AlterTableActionBuilder.swift` — restricted non-empty static ALTER-action result builder; no conditional/loop hooks.
- `Tests/SQLTests/CreateTableTests.swift` — exact CREATE TABLE PostgreSQL/MySQL/Duck SQL, GeneratedColumn participation, snapshot semantics, bind neutrality, and no-semicolon coverage.
- `Tests/SQLTests/AlterTableTests.swift` — exact AddColumn/ALTER TABLE PostgreSQL/MySQL/Duck SQL, one-statement ordering, schema qualification, and no-semicolon coverage.

Historical-schema-safe declarative DDL uses explicit string identifiers. It does not derive migration-facing table/column names from current models or key paths. Runtime query authoring is a separate source family.

## Declarative query authoring

- `Sources/SQL/SQLQuery.swift` — public reusable parameterized-query protocol; `@SQLBuilder var query: SQLValue { get }` plus direct `parts -> query.parts` forwarding into the existing SQLable preparation/composition pipeline.
- `Sources/SQL/DeclarativeQuery/Core/SQLBuilder.swift` — typed root/current states, SELECT/FROM/JOIN and core-clause transitions.
- `Sources/SQL/DeclarativeQuery/Core/IdentifierListBuilder.swift` — identifier-name intake, including structural column paths.
- `Sources/SQL/DeclarativeQuery/From/FromBuilder.swift` — FROM sources, source continuations, nested statements, and nested core clauses.
- `Sources/SQL/DeclarativeQuery/Values/**` — semantic Row/VALUES builders and narrow INSERT ownership of DEFAULT.
- `Sources/SQL/DeclarativeQuery/Clauses/**` — typed WHERE/GROUP BY/HAVING/QUALIFY/ORDER BY/LIMIT/OFFSET requests and builders.
- `Tests/SQLTests/SQLQueryTests.swift` — normal-import SQLQuery regressions for builder-witness inheritance, direct preparation, structural forwarding, FROM/JOIN/projection/IN/EXISTS/root composition, and bind ordering.
- `Tests/SQLTests/DeclarativeQuery*Tests.swift` — focused SQL, bind-order, composition, and source-ownership regressions.

## Dialects

Architecture owners:

- `.agent/architecture/DIALECT_RENDERING.md` - cross-dialect rendering architecture.
- `.agent/architecture/dialects/DUCK.md` - Duck-specific contract, first-closure support matrix/native evidence, naming/UX, limitations, deferred families.
- `.agent/architecture/dialects/POSTGRES.md` - PostgreSQL-specific compatibility owner.
- `.agent/architecture/dialects/MYSQL.md` - MySQL-specific compatibility owner.

Core source:

- `Sources/SQL/Dialect/Dialect.swift` — built-in dialect factories and `SQLDialect.all == [.psql, .mysql, .duck]`.
- `Sources/SQL/Dialect/Dialect+Postgres.swift`
- `Sources/SQL/Dialect/Dialect+MySQL.swift`
- `Sources/SQL/Dialect/Dialect+Duck.swift`
- `Sources/SQL/Dialect/SQLRenderContext.swift`
- `Sources/SQL/SQLable+Parts/SQLable+Scoped.swift`

The first Duck closure is implemented. Representative Duck/closure source owners include:

- `Sources/SQL/Pivot.swift`
- `Sources/SQL/Unpivot.swift`
- `Sources/SQL/Merge.swift`
- `Sources/SQL/StarModifiers.swift`
- `Sources/SQL/StarProjectionParts.swift`
- `Sources/SQL/Lambda.swift`
- `Sources/SQL/Macro.swift`
- `Sources/SQL/Sequence.swift`
- `Sources/SQL/Attach.swift`
- `Sources/SQL/Copy.swift`
- `Sources/SQL/TableFunction.swift`
- `Sources/SQL/Path/Path+Catalog.swift`
- `Sources/SQL/Path/Path+Identifier.swift`
- `Sources/SQL/Functions/Functions+Columns.swift`
- `Sources/SQL/Functions/Functions+List.swift`
- `Sources/SQL/Functions/Functions+NestedValues.swift`
- `Sources/SQL/Functions/Functions+Table.swift`
- `Sources/SQL/Types+Nested.swift`
- `Sources/SQL/TypeDDL.swift`

This is the validated first-closure surface, not a claim that every DuckDB administration/runtime family is implemented. Deferred families remain owned by `.agent/architecture/dialects/DUCK.md` and `.agent/TECH_DEBT.md` where applicable.

## Hybrid syntax

- `Sources/SQL/Parts/HybridOperatorPart.swift`
- `Sources/SQL/HybridOperator.swift`

## Parts and fluent composition

- `Sources/SQL/Parts/**` — concrete SQL parts, including the dedicated structural GROUP BY/ORDER BY parts.
- `Sources/SQL/SQLable+Parts/**` — fluent/compositional extensions that re-enter structural continuation/preparation.

## Builders and common clause state

- `Sources/SQL/Builders/**` — builder implementations.
- `Sources/SQL/QueryParts.swift` — shared query clause state and structural materialization.
- `Sources/SQL/QueryBuilderable.swift` — builder-related protocol surface.

## Functions

- `Sources/SQL/Functions/**` — function helpers and function-related extensions. Canonical predefined `Fn.Name` values are immutable; `Functions.swift` owns `Fn.Name.custom(_:)` and `Fn.build(_:)`.

## Types, casts, predicates, and adjacent values

- `Sources/SQL/PureDate.swift` — proleptic-Gregorian civil date value.
- `Sources/SQL/PureTime.swift` — nanosecond-capable civil time-of-day value.
- `Sources/SQL/DateTime.swift` — timezone-free civil date-time value.
- `Sources/SQL/Interval.swift` — structural months/days/microseconds interval value.
- `Sources/SQL/Type.swift`
- `Sources/SQL/Type+SQLable.swift`
- `Sources/SQL/Type+Autodetect.swift`
- `Sources/SQL/Types+Nested.swift`
- `Sources/SQL/Predicates.swift`
- `Sources/SQL/ExtractFieldValue.swift`
- `Sources/SQL/Enum.swift`

## PostgreSQL-named or PostgreSQL-specific surface

- `Sources/SQL/Builders/PostgresArray.swift`
- `Sources/SQL/Builders/PostgresJsonObject.swift`
- `Sources/SQL/Functions/Functions+Postgres*.swift`
- `Sources/SQL/Functions/Functions+TextSearch.swift`

## Swift 6 / strict-concurrency-relevant roots

- `Package.swift` — Swift 6 language mode.
- `Sources/SQL/SQL.swift` — `SQLValue` concrete fragment/result carrier plus fresh computed global `SQL` fluent root and overloaded unary/result-builder `SQL(...)` functions; deprecated `SwifQL` bridges remain in-module compatibility only.
- `Sources/SQL/Attach.swift` / `Copy.swift` — fresh computed no-value option roots.
- `Sources/SQL/Dialect/Dialect+Postgres.swift` — instance-local lazy Foundation `DateFormatter`.
- `Sources/SQL/Functions/Functions*.swift` — immutable canonical predefined `Fn.Name` storage.
- `Sources/SQL/SQLable+Parts/SQLable+Raw.swift` — static raw supplied-text correction.

The query/bind graph itself remains intentionally non-Sendable where its semantics require it; consumer actor integration is documented in `MIGRATION.md` rather than implemented as a parallel library execution layer.

## Tests

- `Tests/SQLTests/SQLTestCase.swift` - shared test helpers; `check(..., all:)` now exercises PostgreSQL/MySQL/Duck via `SQLDialect.all`.
- `Tests/SQLTests/CreateTableTests.swift` / `Tests/SQLTests/AlterTableTests.swift` - accepted declarative CREATE/ALTER SQL, snapshot, binding-neutrality, and one-statement coverage.
- `Tests/SQLTests/DuckDBDialectTests.swift` and other focused Duck suites - Duck rendering/feature coverage.
- `Tests/SQLTests/StructuralBuilderCompatibilityTests.swift` - structural composition and static-raw compatibility coverage.
- `Tests/SQLTests/FnTests.swift` - function/date migration coverage.
- `Tests/SQLTests/EstablishedOperatorCompatibilityTests.swift` - established compatibility guard.
- `Tests/SQLTests/PreparationObservationTests.swift` - same-render unsafe-value provenance, one-evaluation, fail-closed custom-hook, Duck consumed-value, and built-in compatibility coverage.
- `Tests/SQLTests/PureDateTests.swift` - PureDate semantics and Foundation interop.
- `Tests/SQLTests/PureTimeTests.swift` - PureTime domain and canonical formatting.
- `Tests/SQLTests/DateTimeTests.swift` - civil composition and Foundation interop.
- `Tests/SQLTests/IntervalTests.swift` - structural interval semantics and arithmetic.
- `Tests/SQLTests/SharedValueBindingTests.swift` - ordinary unsafe-value binding and ordered collector behavior.
- `Tests/SQLTests/SharedValueRenderingTests.swift` - exact cross-dialect shared-value output and boundaries.
- `Tests/SQLTests/SharedValueInferenceTests.swift` - automatic and explicit schema inference boundaries.
- `Tests/SQLTests/**` - established focused feature and query tests.

Editor settings, generated output, local user state, backup branches, and transient `.artifacts/**` are not product architecture authority.
