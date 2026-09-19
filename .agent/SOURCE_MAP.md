# SwifQL Source Map

This is a navigation aid, not an architecture contract. Use it to locate the smallest relevant source and test subset before broad discovery.

## Package

- `Package.swift` — SwiftPM tools 6.3 manifest, one `SwifQL` library target, one `SwifQLTests` test target, Swift 6 language mode.

## Core composition, preparation, and output

- `Sources/SwifQL/SwifQLable.swift` — public `SwifQLable`/`SwifQLPart`, structural-frame-aware `SwifQLableParts`, ordinary and observed preparation entrypoints.
- `Sources/SwifQL/PreparationObservation.swift` — single shared recursive preparation renderer/collector plus unsafe-value provenance model, complete/unavailable trace state, and zero-SQL observation-marker handling.
- `Sources/SwifQL/StructuralComposition.swift` — public structural SQL-region/frame model, open clause owner/kind identities, `structurallyAppending(_:)`.
- `Sources/SwifQL/Parts/GroupByPart.swift` — owner-sensitive GROUP BY part.
- `Sources/SwifQL/Parts/OrderByPart.swift` — owner-sensitive ORDER BY part.
- `Sources/SwifQL/Prepared.swift`
- `Sources/SwifQL/SplittedQuery.swift`
- `Sources/SwifQL/Formatter.swift`

## Declarative DDL authoring

- `Sources/SwifQL/CreateTable.swift` — accepted declarative CREATE TABLE surface: `TableDefinition`, `CreateTable`, existing `tableDefinitions(...)`, and the `NewColumn` / `GeneratedColumn` definition conformances.
- `Sources/SwifQL/GeneratedColumn.swift` — `GeneratedColumnStorage` and `GeneratedColumn` semantic value ownership.
- `Sources/SwifQL/AlterTable.swift` — accepted one-statement ALTER TABLE surface: `AlterTableAction`, string/type-only `AddColumn`, and `AlterTable`.
- `Sources/SwifQL/TypeDDL.swift` — generic TYPE / ENUM DDL composition helpers, including `type(_:)` and `enum(...)`.
- `Sources/SwifQL/ResultBuilders/TableDefinitionBuilder.swift` — restricted non-empty static table-definition result builder; no conditional/loop hooks.
- `Sources/SwifQL/ResultBuilders/AlterTableActionBuilder.swift` — restricted non-empty static ALTER-action result builder; no conditional/loop hooks.
- `Tests/SwifQLTests/CreateTableTests.swift` — exact CREATE TABLE PostgreSQL/MySQL/Duck SQL, GeneratedColumn participation, snapshot semantics, bind neutrality, and no-semicolon coverage.
- `Tests/SwifQLTests/AlterTableTests.swift` — exact AddColumn/ALTER TABLE PostgreSQL/MySQL/Duck SQL, one-statement ordering, schema qualification, and no-semicolon coverage.

Historical-schema-safe declarative DDL uses explicit string identifiers. It does not derive migration-facing table/column names from current models or key paths. The broader future runtime query-authoring result-builder slice remains separate.

## Dialects

Architecture owners:

- `.agent/architecture/DIALECT_RENDERING.md` - cross-dialect rendering architecture.
- `.agent/architecture/dialects/DUCK.md` - Duck-specific contract, first-closure support matrix/native evidence, naming/UX, limitations, deferred families.
- `.agent/architecture/dialects/POSTGRES.md` - PostgreSQL-specific compatibility owner.
- `.agent/architecture/dialects/MYSQL.md` - MySQL-specific compatibility owner.

Core source:

- `Sources/SwifQL/Dialect/Dialect.swift` — built-in dialect factories and `SQLDialect.all == [.psql, .mysql, .duck]`.
- `Sources/SwifQL/Dialect/Dialect+Postgres.swift`
- `Sources/SwifQL/Dialect/Dialect+MySQL.swift`
- `Sources/SwifQL/Dialect/Dialect+Duck.swift`
- `Sources/SwifQL/Dialect/SwifQLRenderContext.swift`
- `Sources/SwifQL/SwifQLable+Parts/SwifQLable+Scoped.swift`

The first Duck closure is implemented. Representative Duck/closure source owners include:

- `Sources/SwifQL/Pivot.swift`
- `Sources/SwifQL/Unpivot.swift`
- `Sources/SwifQL/Merge.swift`
- `Sources/SwifQL/StarModifiers.swift`
- `Sources/SwifQL/StarProjectionParts.swift`
- `Sources/SwifQL/Lambda.swift`
- `Sources/SwifQL/Macro.swift`
- `Sources/SwifQL/Sequence.swift`
- `Sources/SwifQL/Attach.swift`
- `Sources/SwifQL/Copy.swift`
- `Sources/SwifQL/TableFunction.swift`
- `Sources/SwifQL/Path/Path+Catalog.swift`
- `Sources/SwifQL/Path/Path+Identifier.swift`
- `Sources/SwifQL/Functions/Functions+Columns.swift`
- `Sources/SwifQL/Functions/Functions+List.swift`
- `Sources/SwifQL/Functions/Functions+NestedValues.swift`
- `Sources/SwifQL/Functions/Functions+Table.swift`
- `Sources/SwifQL/Types+Nested.swift`
- `Sources/SwifQL/TypeDDL.swift`

This is the validated first-closure surface, not a claim that every DuckDB administration/runtime family is implemented. Deferred families remain owned by `.agent/architecture/dialects/DUCK.md` and `.agent/TECH_DEBT.md` where applicable.

## Hybrid syntax

- `Sources/SwifQL/Parts/HybridOperatorPart.swift`
- `Sources/SwifQL/HybridOperator.swift`

## Parts and fluent composition

- `Sources/SwifQL/Parts/**` — concrete SQL parts, including the dedicated structural GROUP BY/ORDER BY parts.
- `Sources/SwifQL/SwifQLable+Parts/**` — fluent/compositional extensions that re-enter structural continuation/preparation.

## Builders and common clause state

- `Sources/SwifQL/Builders/**` — builder implementations.
- `Sources/SwifQL/QueryParts.swift` — shared query clause state and structural materialization.
- `Sources/SwifQL/QueryBuilderable.swift` — builder-related protocol surface.

## Functions

- `Sources/SwifQL/Functions/**` — function helpers and function-related extensions. Canonical predefined `Fn.Name` values are immutable; `Functions.swift` owns `Fn.Name.custom(_:)` and `Fn.build(_:)`.

## Types, casts, predicates, and adjacent values

- `Sources/SwifQL/PureDate.swift` — proleptic-Gregorian civil date value.
- `Sources/SwifQL/PureTime.swift` — nanosecond-capable civil time-of-day value.
- `Sources/SwifQL/DateTime.swift` — timezone-free civil date-time value.
- `Sources/SwifQL/Interval.swift` — structural months/days/microseconds interval value.
- `Sources/SwifQL/Type.swift`
- `Sources/SwifQL/Type+SwifQLable.swift`
- `Sources/SwifQL/Type+Autodetect.swift`
- `Sources/SwifQL/Types+Nested.swift`
- `Sources/SwifQL/Predicates.swift`
- `Sources/SwifQL/ExtractFieldValue.swift`
- `Sources/SwifQL/Enum.swift`

## PostgreSQL-named or PostgreSQL-specific surface

- `Sources/SwifQL/Builders/PostgresArray.swift`
- `Sources/SwifQL/Builders/PostgresJsonObject.swift`
- `Sources/SwifQL/Functions/Functions+Postgres*.swift`
- `Sources/SwifQL/Functions/Functions+TextSearch.swift`

## Swift 6 / strict-concurrency-relevant roots

- `Package.swift` — Swift 6 language mode.
- `Sources/SwifQL/SwifQL.swift` — fresh computed global `SwifQL` root.
- `Sources/SwifQL/Attach.swift` / `Copy.swift` — fresh computed no-value option roots.
- `Sources/SwifQL/Dialect/Dialect+Postgres.swift` — instance-local lazy Foundation `DateFormatter`.
- `Sources/SwifQL/Functions/Functions*.swift` — immutable canonical predefined `Fn.Name` storage.
- `Sources/SwifQL/SwifQLable+Parts/SwifQLable+Raw.swift` — static raw supplied-text correction.

The query/bind graph itself remains intentionally non-Sendable where its semantics require it; consumer actor integration is documented in `MIGRATION.md` rather than implemented as a parallel library execution layer.

## Tests

- `Tests/SwifQLTests/SwifQLTestCase.swift` - shared test helpers; `check(..., all:)` now exercises PostgreSQL/MySQL/Duck via `SQLDialect.all`.
- `Tests/SwifQLTests/CreateTableTests.swift` / `Tests/SwifQLTests/AlterTableTests.swift` - accepted declarative CREATE/ALTER SQL, snapshot, binding-neutrality, and one-statement coverage.
- `Tests/SwifQLTests/DuckDBDialectTests.swift` and other focused Duck suites - Duck rendering/feature coverage.
- `Tests/SwifQLTests/StructuralBuilderCompatibilityTests.swift` - structural composition and static-raw compatibility coverage.
- `Tests/SwifQLTests/FnTests.swift` - function/date migration coverage.
- `Tests/SwifQLTests/EstablishedOperatorCompatibilityTests.swift` - established compatibility guard.
- `Tests/SwifQLTests/PreparationObservationTests.swift` - same-render unsafe-value provenance, one-evaluation, fail-closed custom-hook, Duck consumed-value, and built-in compatibility coverage.
- `Tests/SwifQLTests/PureDateTests.swift` - PureDate semantics and Foundation interop.
- `Tests/SwifQLTests/PureTimeTests.swift` - PureTime domain and canonical formatting.
- `Tests/SwifQLTests/DateTimeTests.swift` - civil composition and Foundation interop.
- `Tests/SwifQLTests/IntervalTests.swift` - structural interval semantics and arithmetic.
- `Tests/SwifQLTests/SharedValueBindingTests.swift` - ordinary unsafe-value binding and ordered collector behavior.
- `Tests/SwifQLTests/SharedValueRenderingTests.swift` - exact cross-dialect shared-value output and boundaries.
- `Tests/SwifQLTests/SharedValueInferenceTests.swift` - automatic and explicit schema inference boundaries.
- `Tests/SwifQLTests/**` - established focused feature and query tests.

Editor settings, generated output, local user state, backup branches, and transient `.artifacts/**` are not product architecture authority.