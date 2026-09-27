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

The broader declarative query result-builder authoring slice remains separate and does not reopen the accepted DDL contracts. This query-authoring wave is now the current design/research priority. Its final major-version UX must remain direct SQL in Swift, reuse the existing parts/preparation/binding engine, preserve existing raw/fluent composition wherever cleanly possible, and prefer clause-local result builders such as `Select { ... }`, `From { ... }`, `Where { ... }`, `GroupBy { ... }`, `Having { ... }`, `OrderBy { ... }`, nested query/set-operation builders, and other SQL-shaped forms that are accepted through design review. Exact Swift -> SQL examples are mandatory during design.

## Major-version roadmap after declarative query authoring

The durable sequence after the declarative query-authoring capability is accepted is:

1. **Reusable query components (`SQLQuery`):** add a SwiftUI-style protocol/value pattern for reusable parameterized query structs built from the same result-builder DSL. A conforming value should expose its query declaratively, prepare directly through the ordinary SQL preparation pipeline, and itself be usable compositionally as a nested/subquery source wherever an ordinary SQL query is accepted. Do not create a parallel query engine or execution abstraction.
2. **Major naming/package/repository migration:** move the primary public identity from `SwifQL` to `SQL`, including the root query namespace/result-builder spelling `SQL { ... }`, `SwifQLable -> SQLable`, and the corresponding reviewed renames of other public/internal `SwifQL...` symbols where the old project name is no longer appropriate. The repository/public package destination is planned as `github.com/swiftstream/SQL`. This is an intentional major-version migration wave, not an incidental search/replace.
3. **Compatibility and migration closure:** inventory every source-breaking rename or behavior correction before implementation, record literal `was -> became` migration guidance, assess compatibility bridges/deprecations where they materially reduce user pain, update migration/release/public-content material, and provide coding-agent/LLM migration guidance. Do not let a breaking change exist only in an implementation diff or transient artifact.
4. **SQL conversion skill:** provide a maintained downstream skill that can transform raw SQL into the final result-builder representation and into the final raw/fluent SQL DSL representation. The final published skill should target the post-migration `SQL` API; during its design it should also preserve enough legacy knowledge to help migrate existing SwifQL call sites. Avoid publishing a skill against a namespace that is immediately renamed and then having to rewrite its canonical examples.
5. **Documentation/publication consolidation:** promote accepted declarative-query examples, reusable-query examples, migration examples, compatibility notes, and major-version stories into README/public docs/release notes as appropriate, using the public-content capture workflow rather than trying to reconstruct them after release.

The `SQLQuery` capability is conceptually the immediate follow-up to result-builder query authoring because it packages that grammar into reusable parameterized values. Its final public spelling should be `SQLQuery`; if implementation sequencing makes the `SwifQL -> SQL` namespace migration happen first or in the same wave, do that rather than publishing a temporary public `SwifQLQuery` name that would immediately be renamed.

The target developer experience must preserve the following shape in detail:

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

This exact SwiftUI-style getter shape is the canonical target. The final `SQLQuery` protocol should expose a result-builder-attributed `query` requirement so conforming getters inherit the SQL builder transform and do not need an explicit nested `SQL { ... }` wrapper. If the concrete `SQL` result type requires an associated type or another generic detail internally, keep that complexity out of ordinary conformer source.

A query value must then be directly preparable:

```swift
let users = UsersQuery(
    active: true,
    email: "john@example.com",
    roles: [.admin, .moderator]
)

let prepared = users.prepare(.psql)
```

and must lower to the same SQL/binding pipeline as writing the body directly:

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

The `SQLQuery` value itself must also compose as a subquery inside another declarative query, rather than requiring callers to unwrap `.query` manually. Alias/source ownership must remain explicit at the composition site, for example:

```swift
From {
    UsersQuery(active: true, email: nil, roles: nil)
        .as("activeUsers")
}
```

targeting:

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

Likewise a reusable `SQLQuery` must be acceptable anywhere the relevant grammar permits a nested query, including JOIN/subquery/EXISTS/IN contexts after those clause-specific APIs are finalized.

Do not make `SQLQuery` an executor, ORM repository, mutable builder object, or separate AST. It is a reusable SQL-producing value over the same `SQLable`/parts/preparation contract.

The ordering above intentionally finalizes the `SQL` namespace before the conversion skill becomes canonical public guidance. If an internal/provisional conversion skill is useful while result builders are being designed, it may exist as disposable/research tooling, but the stable downstream skill targets the final `SQL` surface.

### Major-version migration ledger discipline

For this major-version line, every accepted source-breaking public change must be recorded before implementation with:

- old spelling/behavior;
- new spelling/behavior;
- why the break is justified;
- migration example;
- compatibility/deprecation bridge decision;
- downstream extension impact;
- README/MIGRATION/CHANGELOG/release-note/public-content follow-up.

`MASTER_PLAN.md` owns the durable roadmap and high-level accepted breaking migrations. Detailed migration design belongs in the relevant architecture owner and implementation artifacts; future public explanation/examples are captured through `PUBLIC_CONTENT_IDEAS.md` and its focused shards. No major-version breaking change may rely on chat history as its only record.

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