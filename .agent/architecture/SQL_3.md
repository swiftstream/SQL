# SQL 3.x Architecture and Accepted Design

This file is the compact SQL 3 major-line overlay. It records the accepted delta from the SQL 2.2 baseline and the stable implementation state carried through SQL 3.x. SQL 3.0.0 remains the previous immutable published release at commit `ae6aedb064f882b67488c8fb27ead5bc0a65bc43` and annotated tag `3.0.0`; SQL 3.1.0 is the current stable line represented by this release snapshot.

Load this file for SQL 3.x architecture, migration, compatibility, release-history, or follow-up work. Historical SQL 2.2 behavior remains relevant only where this overlay explicitly contrasts the previous stable line.

## Status

- Current stable release: SQL 3.1.0.
- Immutable release commit: `b0c81191c3494d91b84b5382092e99c64d5c4647`.
- Annotated release tag: `3.1.0`, tag object `8f751b9ec46b43f88148956948dae3b7c31fadd7`.
- Verified GitHub Release: `🛡️ SQL 3.1.0`, release ID `419720138`, published at `2026-10-21T15:24:50Z`.
- Canonical corrected GitHub Release body SHA-256: `70f157572d14ff2233bed91145b437b2a6988bed1799861e71812524c82d56a7`.
- SQL 3.1 source delta: `34a6b9cf60f47860624d41654b03d8b52f0a23c1` adds Swift 6 table-metadata isolation compatibility and lower-snake-case implicit table names.
- Previous immutable release commit: `ae6aedb064f882b67488c8fb27ead5bc0a65bc43`.
- Previous annotated release tag: `3.0.0`, tag object `966136c265d23c59477416ccb710c612fe888511`.
- Previous verified GitHub Release: `🗃️ SQL 3.0.0`, release ID `415777873`.
- No standalone SQL 2.3.0 exists.
- The accepted major-version design is independently audited.
- Foundation, qualified key-path/dialect integration, model/manual structural namespace integration, and bind-aware `SQL.raw` were published in 3.0.0 and are carried forward by 3.1.0.
- Bind-aware raw interpolation is closed as product work: `SQLRaw` plus labeled `\(bind:)` preserves existing `raw(String)`/`String.raw` compatibility and uses the ordinary one-pass preparation/bind pipeline.

## Compatibility posture

A major release permits the accepted migrations below, not unrelated breakage.

Preserve unless explicitly changed here:

- `Table` and `@Column`;
- `AnyTable` table identity;
- broad `Decodable.table` and `Decodable.as(...)`;
- `GenericTableAlias<M: Decodable>`;
- top-level `Schema<T>`;
- SQLable composition, `parts`, preparation, bind order, and fragment-first semantics;
- existing open `SQLDialect` hooks and downstream source compatibility.

Do not add optional schema/catalog bags to every `AnyTable`.

## SQL 3.1 compatibility delta

SQL 3.1 keeps the public model syntax but changes the metatype/isolation contract so `AnyTable`, `Table`, and `ColumnRoot` remain usable from nonisolated Swift 6 code without consumer annotations or unsafe concurrency escape hatches. `Table` also carries the accepted `SendableMetatype` requirement; this is metatype compatibility, not an assertion that table instances or query graphs are `Sendable`.

The default `AnyTable.tableName` for simple nominal type names is now lower snake case. Examples include `Todo -> todo`, `UserProfile -> user_profile`, `URLValue -> url_value`, and `HTTPServer -> http_server`. Explicit `static var tableName` remains exact and is the required migration path for applications whose persisted schema depended on the former implicit type-description spelling. Treat this as possibly breaking. Generic, nested, qualified, or otherwise decorated type shapes should use an explicit stable table name.

## Model capabilities

`Schemable` now carries structural schema identity:

```swift
public protocol Schemable {
    static var schema: DB.Schema { get }
}
```

The schema is required and non-optional. The historical 2.x implicit `"public"` default is not part of the 3.0.0 contract.

Catalog-aware models add:

```swift
public protocol Catalogable: Schemable {
    static var catalog: DB.Catalog { get }
}
```

For model-default qualification, explicit `Catalogable.catalog` overrides a catalog embedded in `Schemable.schema`.

Typed `Catalog<T>` is additive. Existing `Schema<T>` remains.

## Structural namespace

SQL 2.2 remains `Path.*` only. Do not preview or deprecate toward `DB.*` in 2.2.

`DB.*` is the canonical structural namespace at the 3.0.0 boundary and replaces the broad public `Path.*` namespace while preserving useful type-state.

Accepted semantic progression includes:

```text
DB.Table -> DB.Table.Column
DB.Schema -> DB.Schema.Table -> DB.Schema.Table.Column
DB.Catalog -> required schema state -> table -> column
```

`Path.Identifier` migrates to `DB.Object`.

`DB.Schema` requires a schema name and may carry an outer catalog.

`DB.Catalog` and `DB.Schema` are `Equatable, Sendable`. Do not infer `Hashable`.

## Key-path state

Catalog-aware typed/model/manual key paths use one semantic part:

```swift
SQLPartKeyPath(
    catalog: String? = nil,
    schema: String? = nil,
    table: String? = nil,
    paths: [String],
    asText: Bool = false
)
```

Do not use a sibling catalog-prefix part for this state.

Public `SQLKeyPathable` gains `catalog: String?` with a default `nil`, so existing downstream conformers do not need a new witness.

Do not add `catalog` to higher-level `Keypathable` in the accepted major-version design.

Typed `FormattedKeyPath(T.self, ...)`, `T.manualKeyPath(...)`, and `T.mkp(...)` share capability semantics with ordinary typed table key paths:

- plain `Table`: table only;
- `Table & Schemable`: schema + table, retaining an embedded schema catalog;
- `Table & Catalogable`: explicit model catalog overrides embedded schema catalog.

String-based FormattedKeyPath remains table-only.

Preserve the distinction between copying a complete semantic part and deliberate projections such as first-path or terminal-name materialization.

## Aliases

An aliased source may retain full catalog/schema/table identity. References after aliasing are alias-only. Source qualification must not leak behind the alias.

Alias JSON traversal uses the alias as reference owner plus the selected dialect's existing JSON behavior.

## Dialect boundaries

PostgreSQL keeps its ordered JSON traversal: first path segment is the column, later segments use `->`, and final text extraction uses `->>`.

Duck keeps ordered JSON traversal, final `->>`, required grouping, and atomic removal of catalog/schema/table from the one semantic key-path part in accepted unqualified PIVOT/UNPIVOT scopes.

MySQL keeps historical terminal `paths.last` behavior. Do not import PostgreSQL/Duck arrow semantics by implication.

Catalog metadata is shared semantic input, not a promise of uniform native SQL support across dialects.

Existing open `SQLDialect` hooks remain source-compatible. Additive context/catalog hooks default-forward and introduce no new mandatory downstream override. An unchanged custom dialect is not automatically advertised as catalog-aware.

## Composition and preparation

The implementation stays on the existing:

```text
SQLable -> parts -> one preparation traversal -> SQLPrepared
```

Qualification metadata is structural and bind-free.

Do not introduce a parallel AST, second renderer, second bind pass, replay, hidden routing layer, renderer-owned public wrapper, or whole-statement validator.

DESIGN-037 fragment-first remains authoritative.

## Major migration obligations

The deliberate source migrations are:

1. `Schemable.schemaName: String` / implicit public behavior -> required `Schemable.schema: DB.Schema`.
2. broad public `Path.*` structural namespace -> canonical `DB.*`.

Migration material must show concrete old/new examples and custom-dialect impact. Historical SQL 2.x guidance must not imply that 3.x-only APIs existed on those releases. Current SQL 3.x documentation may teach the landed surface explicitly, and SQL 3.1 migration material must call out the possibly-breaking implicit `tableName` change.

## Implementation and closure order

After SQL 2.2 closed, the 3.0.0 work proceeded through:

1. DB value/capability/type-state foundation — implemented and committed.
2. Atomic qualified key-path parts and built-in dialect integration — implemented and committed.
3. Model/Decodable/typed-FKP/manual structural namespace integration — implemented and committed.
4. Bind-aware raw interpolation — implemented and committed as a separately bounded wave.
5. Stable documentation synchronization, whole-candidate validation, exact branch/tag CI, public exact-version consumer validation, and 3.0.0 GitHub Release publication — complete.
6. SQL 3.1 Swift 6 model-metadata compatibility and implicit table-name normalization — implemented, validated on Swift 6.3.3 / 6.4, validated through legacy and async Vapor 4 consumers, and synchronized into the stable 3.1.0 release snapshot.

Bind-aware raw interpolation is not a standalone 2.3 release. Its accepted surface uses explicit labeled value interpolation (`\(bind:)`) while ordinary Swift interpolation into the legacy String raw route remains caller-owned SQL text.
