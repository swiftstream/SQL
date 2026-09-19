# Master Plan

This file owns the durable SwifQL development roadmap. Detailed research/plans/tasks/evidence belong in disposable `.artifacts/**`, but they must never contradict this roadmap or the stable owners routed by `ARCH_INDEX.md`.

## North star

SwifQL is SQL DSL first: users should think in SQL and write that SQL idea naturally, safely, and compositionally in Swift.

The first two design gates for every relevant change are:

1. `DESIGN-001` - SQL-first mental model.
2. `DESIGN-015` - equivalent valid queries preserve semantics across fluent, incremental, conditional, helper-based, nested, and cross-file composition.

If a proposal violates either gate, redesign it before implementation.

For any new **shared under-the-hood dialect/rendering/preparation/binding/scope/ownership/composition primitive**, `DESIGN-019` is an additional mandatory architecture gate: research the semantic requirement across affected supported dialects, likely adjacent not-yet-implemented constructs, and representative major external SQL dialect families before freezing the shared primitive. The triggering database must not become the ontology of shared internals.

## Mandatory development order

```text
architecture + SQL semantics + DSL/UX
-> clean implementation
-> tests/native evidence proving the accepted implementation
-> independent source/diff/Git audit
-> commit checkpoint
```

Green tests do not legitimize a workaround, compatibility unwrap, hidden routing layer, duplicated state, token-neighbor heuristic, speculative framework/AST, renderer-driven public wrapper, or source-breaking DSL redesign.

If a new abstraction creates special cases in unrelated established code, treat that as evidence against the abstraction and revisit the design.

## Compatibility constitution

PostgreSQL/MySQL are established compatibility contracts. Assume users own thousands of queries plus private `extension SwifQLable`, custom operators/helpers, public-protocol conformances, path abstractions, and `SQLDialect` subclasses.

Unless a separately approved bug fix proves one old contract wrong, preserve existing source, composition, overload behavior, public protocol meaning, `parts` expectations, generated PostgreSQL/MySQL SQL, bind order, dialect-hook dispatch, and representative downstream extension compilation.

A major release is not permission for avoidable breakage. See DESIGN-010, DESIGN-015, DESIGN-016, and DESIGN-017.

## Approved rendering direction

The existing parts/preparation pipeline remains primary.

Approved additive primitives are value-semantic render scopes/context, a library-owned scoped nested part, recursive context-aware preparation, additive forwarding dialect hooks, and `SwifQLable.scoped(_:)`.

Attach scopes only at the semantic construct that truly owns the grammar context. Do not globally rewrite ordinary predicate/arithmetic/operator part shape for one dialect.

Focused semantic statement representation remains only a future escalation boundary after a separate maintainer decision proves ordinary/scoped parts plus the evidence-proven structural SQL-region model genuinely insufficient. For the current Duck PIVOT/UNPIVOT/MERGE wave, bounded semantic render scopes remain canonical for contextual rendering and Gate B has now passed with a generic major-version SQL-region/set-result frame architecture plus dedicated owner-sensitive clauses. Do not pre-install hidden routing into established `groupBy`, `orderBy`, `limit`, `returning`, or similar DSL methods; the generic continuation path must operate only on the current root frame and contain no dialect/PIVOT branch.

## Declarative DDL authoring state

The first declarative DDL authoring slice is implemented, independently plan-audited, independently source/diff/Git-audited, and primary-accepted.

Accepted generic SQL-owned surface:

```text
TableDefinition
TableDefinitionBuilder
CreateTable
AlterTableAction
AlterTableActionBuilder
AddColumn
AlterTable
```

The new DDL values remain ordinary `SwifQLable` / `SwifQLPart` composition over the existing preparation pipeline. No parallel AST/renderer or migration runtime exists in SwifQL.

Historical-schema-safe authoring uses explicit string table/schema/column identifiers; current model metadata and key paths must not rewrite old migration declarations. The DDL result builders are intentionally static/non-empty and reject direct runtime branching/loops.

`CreateTable` snapshots child parts at initialization. `AlterTable` models exactly one SQL ALTER TABLE statement; the first `AddColumn` surface is intentionally String + SwifQL.Type only.

This accepted checkpoint unblocks consumers such as SwiftDuckDB to build their own migration-plan/execution layer around SwifQL DDL values. SwiftDuckDB migration version/history/transaction semantics remain outside SwifQL.

The broader future `SwifQL { Select / From / Where / ... }` result-builder authoring slice remains separate and may be researched independently without reopening the accepted DDL contracts.

## Duck direction

Canonical public spelling is `.duck`. Ordinary Duck query source remains SQL-shaped and dialect-transparent; Duck-only support does not automatically justify a `Duck...` public wrapper. Dialect-transparent rendering may adapt syntax/qualification/casing for the same exact SQL construct, but it must not become a portability facade that swaps differently named SQL constructs such as `decode` and `from_base64`. The first Duck closure has passed its support/compatibility/native-validation gates and `.duck` is now included in `SQLDialect.all`; future changes to that built-in collection still require explicit test-classification and compatibility review.

A target PIVOT call should remain conceptually clean, e.g. `SwifQL.pivot(cities).on(cities.column("year"), in: 2000, 2010)...`, with dialect-specific qualification handled behind the DSL rather than exposed as wrapper objects.

For simplified PIVOT, native DuckDB v1.5.5 evidence already proves qualified ON/USING/GROUP BY/ORDER BY forms fail, explicit bound IN values work, bound LIMIT works with explicit IN, and no-IN dynamic PIVOT cannot be prepared as one C statement. The correct GROUP BY source remains a column path, but after `SwifQLable` existential erasure do not distort the established generic GROUP BY API with a fake PIVOT-only compile-time `KeyPathLastPath` restriction; preserve `KeyPathLastPath` as public compatibility surface for APIs that can truthfully own such static grammar constraints.

The approved first `.duck` closure covers ordinary application/analytics/schema SQL, including views, and leaves administration/runtime families such as INSTALL/LOAD, secrets, broad PRAGMA/configuration, checkpoint/vacuum/analyze administration, variables, export/import, SHOW/DESCRIBE/SUMMARIZE convenience, and extension-specific universes for later typed waves. The generic SQL `name := expression` abstraction is also deferred; current closure work must not invent it indirectly.

## Current Duck and Swift 6 state

The first Duck closure is implemented, native-/compatibility-validated, independently audited, and committed. Gate A bounded semantic render scopes and Gate B structural clause ownership are now production architecture rather than planning-only evidence. The structural SQL-region/set-result frame model, owner-sensitive GROUP BY/ORDER BY parts, PIVOT/UNPIVOT/MERGE support, first-closure DML/DDL/catalog/file-function surface, and `.duck` membership in `SQLDialect.all` are current source truth.

The package now uses SwiftPM tools 6.3 with Swift 6 language mode. Release CI validates this line with Apple Swift 6.3.3 while intentionally preserving non-Sendable query/bind graphs where their semantics are not truthfully Sendable. Consumer actor boundaries normalize on caller isolation and move only consumer-owned checked-Sendable snapshots across actors; this is guidance for consumers, not a new parallel SwifQL preparation architecture.

Future Duck administration/runtime waves and the deferred generic SQL `name := expression` abstraction remain separate work. Any new shared rendering/preparation/composition primitive still requires the normal architecture/research/audit gates; completed first-closure evidence is not blanket permission to widen Duck claims or redesign established PostgreSQL/MySQL behavior.

Current live source and stable architecture owners define the implementation baseline. Disposable artifacts may record execution evidence, but they do not override those authorities.

## Current Shared Semantic Value state

The accepted shared semantic value source and integration are complete, with cross-platform consumer evidence and fresh independent audits accepted CLEAN. `PureDate`, `PureTime`, `DateTime`, and `Interval` were first published in prerelease `2.0.0-beta.6.0.0` and remain current source truth. `2.0.0-beta.6.0.1` remains the immutable Swift 6.3 tools/CI compatibility hotfix. The current release candidate/current prerelease is `2.0.0-beta.6.1.0`, which adds the accepted Declarative DDL authoring surface without redesigning the shared value APIs or existing query source. Downstream dependency handoff remains a separate consumer-repository step.

## Future validation gates

Substantial waves require design/UX review before implementation, source/diff review afterward, PostgreSQL/MySQL exact regression checks, bind-order checks where relevant, DESIGN-015 composition checks, downstream consumer fixtures when extension compatibility is at risk, native DuckDB validation where renderer tests are insufficient, `git diff --check`, and exact changed-path review.

## Documentation roadmap

Keep detailed principles in their single owners rather than duplicating them here. Maintain Duck docs now; later run dedicated PostgreSQL and MySQL documentation/research mega-audits. Public-content ideas remain lazy-loaded candidate material, never implementation authority.