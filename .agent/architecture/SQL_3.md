# 3.0.0 Architecture and Accepted Design

This file is the compact 3.0.0 major-version overlay. It records the accepted delta from the SQL 2.2 baseline and the implementation state of those changes on `master`. The product implementation described here has landed locally; 3.0.0 is not a published stable release until final release closure, tag, CI, public consumer, and publication gates complete.

Load this file for 3.0.0 planning, migration, release-closure, or audit work. Do not load it for ordinary SQL 2.2 work.

## Status

- Current stable release: SQL 2.2.0.
- Active development objective: 3.0.0 documentation, whole-candidate validation, and release closure.
- No standalone SQL 2.3.0 is planned.
- The accepted major-version design is independently audited.
- Foundation, qualified key-path/dialect integration, model/manual structural namespace integration, and bind-aware `SQL.raw` are implemented, independently validated, and locally committed on `master`.
- Bind-aware raw interpolation is closed as product work: `SQLRaw` plus labeled `\(bind:)` preserves existing `raw(String)`/`String.raw` compatibility and uses the ordinary one-pass preparation/bind pipeline.
- Current stable release remains SQL 2.2.0 until the 3.0.0 release gates complete.

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

Migration material must show concrete old/new examples and custom-dialect impact. Historical SQL 2.x guidance must not imply that 3.0.0-only APIs existed on those releases; current 3.0.0 release-candidate documentation may teach the landed surface explicitly.

## Implementation and closure order

After SQL 2.2 closed, the 3.0.0 work proceeded through:

1. DB value/capability/type-state foundation — implemented and committed.
2. Atomic qualified key-path parts and built-in dialect integration — implemented and committed.
3. Model/Decodable/typed-FKP/manual structural namespace integration — implemented and committed.
4. Bind-aware raw interpolation — implemented and committed as a separately bounded wave.
5. Stable documentation/managed-skill synchronization, whole-candidate validation, and 3.0.0 release closure — active.

Bind-aware raw interpolation is not a standalone 2.3 release. Its accepted surface uses explicit labeled value interpolation (`\(bind:)`) while ordinary Swift interpolation into the legacy String raw route remains caller-owned SQL text.
