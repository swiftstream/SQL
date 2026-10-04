# Dialect Rendering Architecture

This file is the sole owner of cross-dialect `DIALECT-*` rules.

Per-dialect details have separate owners under `architecture/dialects/` and should not be duplicated here:

- `dialects/DUCK.md` -> `DUCK-*`
- `dialects/POSTGRES.md` -> `POSTGRES-*`
- `dialects/MYSQL.md` -> `MYSQL-*`

Load this base owner plus only the dialect-specific owner needed by the task. Cross-dialect audits may load more than one dialect owner deliberately.

## Verified common model

`SQLDialect` is an open class. Equality compares dialect identity through `id`.

The dialect is selected at preparation time for both ordinary and observed preparation:

```swift
query.prepare(dialect)
query.prepareObservingUnsafeValues(dialect)
```

Both entrypoints use the same preparation renderer; observation does not authorize a dialect-specific or provenance-specific parallel SQL pipeline.

The public DSL should normally stay SQL-shaped and dialect-transparent. Differences in identifier spelling, key-path rendering, values, dates, bind markers, collection syntax, and other exact syntax belong behind dialect-aware preparation rather than database-prefixed wrappers scattered through ordinary query code.

The shared semantic values `PureDate`, `PureTime`, `DateTime`, and `Interval` are additive value hooks in this same preparation pipeline. Existing custom `SQLDialect` subclasses remain source-compatible through default hook implementations; built-in dialects own the exact supported rendering and boundary behavior. Per-dialect range, precision, and special-state facts remain in the dialect owners below.

`.any` is a base `SQLDialect` intended only for short truly universal SQL. It is not a substitute for a concrete dialect when parts require database-specific rendering.

`SQLDialect` is public/open compatibility surface. New contextual hooks must preserve existing external subclasses where technically possible, normally by adding forwarding overloads rather than replacing established signatures.

## Ownership boundary

This base file owns:

- common dialect identity/factory rules;
- common hook architecture;
- bind-syntax ownership boundaries;
- hybrid/operator dispatch rules;
- semantic/context-aware rendering policy;
- custom/open dialect compatibility;
- routing to per-dialect owners.

Per-dialect owners contain:

- canonical public dialect factory spelling;
- internal dialect id;
- identifier/string/date/data behavior;
- collection/JSON/type semantics;
- exact feature support and limitations;
- native validation evidence;
- dialect-specific UX and naming constraints;
- dialect-specific pre-release blockers.

Prepared marker traversal, collected-value order, and formatter mechanics remain owned by `QUERY_PREPARATION.md`.

Public API identity, naming, and dialect-transparent UX remain owned by `DSL_DESIGN_AND_UX.md`.

## Rules

### DIALECT-001 - Dialect hooks

Dialect-sensitive rendering stays behind `SQLDialect` hooks used by the single preparation pipeline.

Do not create an independent renderer for one database when the existing parts/preparation architecture can express the behavior cleanly.

### DIALECT-002 - Support claims are feature-specific

A dialect being implemented does not imply that every SQL construct or another dialect's historical helper is portable to it.

Support claims must match current source, tests, and where required native database evidence.

### DIALECT-003 - Universal dialect limits

`.any` is only for short universal SQL such as transaction control when no dialect-sensitive part is involved.

Do not use `.any` to avoid defining proper behavior for a supported dialect.

### DIALECT-004 - Compatibility research

Adding or materially extending a dialect requires explicit research of at least:

- identifiers and quoting;
- strings and primitive values;
- dates/timestamps/time zones;
- bind syntax;
- arrays/lists/nested values;
- JSON/key paths;
- casts/types and inference;
- DML/DDL;
- operators/functions;
- hybrid behavior;
- native database-specific features;
- preparation limitations;
- test and `SQLDialect.all` impact.

Similarity to another database is not evidence.

### DIALECT-005 - Bind ownership split

Dialect-specific placeholder spelling belongs to the dialect owner.

Traversal order, marker replacement, value collection, and prepared-output mechanics belong to `QUERY_PREPARATION.md`.

### DIALECT-006 - Hybrid behavior must be explicit

Every supported dialect needs an explicit representation for `SQLHybridOperator` or any future dialect-polymorphic operator mechanism.

Preserve the established public two-argument PostgreSQL/MySQL initializer for downstream source compatibility. The additive three-argument initializer provides an explicit Duck representation. Preparing a legacy two-branch custom hybrid with `.duck` does not silently reuse another dialect representation: if no explicit Duck representation exists, preparation fails deterministically. The shared value may carry an open value-semantic mapping from a public representation key to an operator, and a dialect may select its key through an additive hook; legacy whole-`hybridOperator(_:)` overrides remain authoritative.

A new dialect support claim must not rely on another dialect's syntax as semantic evidence.

Semantic nested SQL types follow the same boundary: `Type.list`, `Type.array`,
`Type.map`, `Type.struct`, and `Type.union` retain their constructor, children,
length, and raw member names in a value-semantic representation carried by
`SQLPartType`. The additive `SQLDialect.type(_:)` hook owns the final grammar
and identifier policy; its default is the historical textual `Type` spelling,
so raw `Type(String)` values and existing dialect subclasses remain compatible.
The historical textual compatibility projection may contain legacy
preformatted/prequoted spelling, but semantic nested-type rendering must not
reparse or depend on that projection: constructor identity, child types,
length, and raw member names remain available independently through
`TypeStructure` and `SQLPartType`.

Sampling uses the same semantic boundary. `SampleMethod`, `SampleArgumentRole`,
and `SampleConstruct` are open value identities; `SQLPartSampling` retains
the construct (`USING SAMPLE` versus `TABLESAMPLE`), ordered arguments and
roles, and seed/repeatability until `SQLDialect.sampling(_:)` returns ordinary
parts to the existing recursive renderer. The default hook keeps argument
values bindable. A dialect may choose parser-constant representation only for
the grammar positions it owns and has evidence for; it must not stringify or
reparse arbitrary expressions. Fixture-only dialect examples do not make a
production support claim.

SQL lambdas follow the same rule. `SQLLambda` exposes one
`SQLPartLambda` carrying ordered structural parameter identities and body
parts; it does not pre-render `lambda`, `:`, arrows, or other dialect
punctuation. `SQLDialect.lambda(_:)` returns ordinary parts through the
recursive renderer, with the default preserving the historical
`lambda <parameters> : <body>` spelling and body bind order. A downstream
dialect may choose another exact lambda grammar from the same semantic value
without token scanning or body stringification.

ASOF joins keep materially different SQL condition roles explicit. The
ordinary join APIs continue to preserve caller-supplied ON and USING exactly;
an explicit matchCondition API emits MATCH_CONDITION before an optional ON or
USING clause. SQL does not infer temporal predicates or remap Duck ON/USING
to another dialect's MATCH_CONDITION grammar.

### DIALECT-007 - Rendering follows the public design contract

Dialect hooks may adapt syntax, qualification, placeholder spelling, or harmless SQL keyword/function casing required to express the same exact modeled SQL construct, but must not silently substitute a differently named SQL function/type/operator/statement or degrade semantics. For example, the same exact `from_base64` function may render with dialect-preferred casing such as `FROM_BASE64` versus `from_base64`, but a `decode` API must never be translated into `from_base64` merely because both can participate in base64 workflows.

Use `DSL_DESIGN_AND_UX.md` for exact-SQL identity, convenience boundaries, and dialect-transparent user-facing API rules.

### DIALECT-008 - Semantic context beats token heuristics

When the same structured part requires different rendering in a particular SQL grammar position, pass explicit semantic/contextual information through the parts/preparation pipeline rather than guessing context by scanning neighboring raw operator strings.

Do not accumulate database-specific `previous token` / `next token` parsing heuristics inside `prepare(_:)` as a normal architecture pattern.

The approved mechanism is a structural semantic render scope carried with the affected nested parts. Scope is metadata about the grammar role of those parts, not ambient mutable state on a builder/query and not begin/end raw tokens.

Render scopes must be attached by the semantic owner that actually needs contextual rendering. Do not globally wrap ordinary predicates, arithmetic, LIKE/IN/BETWEEN/NULL operators, or other established expression constructors merely so one dialect can infer a grammar position. If a scope leaks into unrelated structural consumers and needs compatibility unwraps or special-case bridges, that is evidence that the scope was attached at the wrong layer and the design must be reconsidered.

The canonical public Duck factory is `SQLDialect.duck`; the product identity remains DuckDB and the internal dialect id may remain `"duckdb"`.

A scoped part must remain one composable structural unit when it is copied, appended, stored in a `SQLable` variable, returned by a helper, conditionally included, nested inside a function/subquery, or assembled later in another method. Rendering semantics must therefore not depend on one uninterrupted fluent call chain or on neighboring clauses remaining adjacent in the original Swift source.

Preparation should recursively render nested scoped parts with a value-semantic render-context stack while preserving one shared ordered binding/value collection state. Entering a scope produces a derived context for its children; leaving it restores the parent context naturally through value semantics rather than mutable global/query state.

The scope primitive must remain compatible with the existing parts pipeline and established `SQLDialect` hooks.

Under the evidence-proven major-version structural SQL-region frame architecture in `DSL-008`, entering a nested statement/subquery/set-result frame establishes a statement-local render-context isolation boundary: semantic scopes owned by an outer statement region do not automatically leak into the nested SQL region. This rule is cross-dialect composition infrastructure, not a PIVOT-specific dialect exception. The focused Gate B diagnostic validated this behavior with both built-in PIVOT-style cases and an external custom dialect/scope consumer.

### DIALECT-009 - Preserve custom dialect subclasses

When evolving an existing `SQLDialect` hook, prefer an additive context-aware overload whose default implementation forwards to the established hook.

Example direction:

```swift
open func keyPath(_ keyPath: SQLPartKeyPath) -> String

open func keyPath(
    _ keyPath: SQLPartKeyPath,
    context: SQLRenderContext
) -> String {
    keyPath(keyPath)
}
```

Context-aware overloads should continue to forward to established hooks by default so existing behavior does not need to understand new scopes.

Current source exposes a public `SQLDialect.init()`. The external-consumer fixture verified custom subclass construction from another module and the additive context-aware hook path. Future hook changes must preserve that source-compatible boundary.

### DIALECT-010 - Dialect-transparent ordinary query source

The selected dialect should normally affect preparation/rendering, not force ordinary user queries to name database implementation wrappers.

A construct being currently supported by only one dialect does not automatically justify a database-prefixed public API.

If the common parts pipeline lacks the semantic information required to render a clean API correctly, improve the shared architecture instead of pushing renderer limitations into user code.

### DIALECT-011 - Per-dialect detail ownership

Do not expand this base file with feature matrices or database-specific syntax details.

Route those facts to exactly one dialect owner under `architecture/dialects/` and link to it from supporting docs.

This keeps normal context loading bounded while allowing each dialect owner to become detailed over time.

### DIALECT-012 - Render scopes are extension-friendly without exposing renderer internals

The render-scope abstraction should provide a narrow public, value-semantic extension point when that can be done without exposing mutable preparation state or requiring third-party code to invent an unknown `SQLPart` that the core renderer would silently drop.

The current narrow extension point is the public, value-semantic `SQLRenderScope(namespace:name:)` plus `SQLable.scoped(_:)`. `SQLRenderContext` is public and read-only, while the concrete scoped part and recursive renderer remain library-owned. A downstream module can define a semantic scope, wrap a normal `SQLable`, and observe that scope through an additive context-aware dialect hook without relying on mutable ambient state.

Keep scope identifiers namespaced and value-semantic. Scope identity derived from open owner and kind values must preserve their raw components structurally and injectively; delimiter-concatenated display text must never be the semantic identity. Do not expose mutable preparation state, raw global strings with collision-prone semantics, or unknown-part escape hatches.

Extensibility is a design goal, not permission to add unsafe escape hatches. If a clean public extension point would require leaking renderer internals or false compatibility guarantees, keep that portion internal until the underlying API can support it honestly.

### DIALECT-013 - Semantic statement representation is an escalation path, not a foundation

Render scopes solve local contextual rendering differences while preserving the existing parts pipeline. They are not required to model every possible cross-dialect statement transformation forever.

Do not pre-install generic semantic-statement routing into established methods such as `groupBy`, `orderBy`, `limit`, or `returning` merely because a future unreleased builder might benefit from hidden state retention through type erasure. That changes old composition semantics for speculative future needs and is not an acceptable foundation.

A dedicated value-semantic clause part that carries its own explicit ownership metadata is not, by itself, the forbidden hidden statement-routing mechanism. `DSL-008` permits that representation as part of the audited major-version structural composition model when an established flat clause genuinely needs structural ownership. The clause must carry its own metadata through `parts`; an established fluent method must not discover ownership by scanning receiver history, neighboring tokens, or ambient mutable state.

The evidence-proven architecture selects ownership through the current root structural SQL-region/set-result frame. Standard continuation-style fluent methods use one generic frame-aware structural composition primitive: they may ask the current root frame for the owner associated with an open clause kind, build the dedicated clause with that owner, and append it through the same generic path. They must not search the receiver for PIVOT or another semantic construct. The generic structural primitive contains no dialect/PIVOT branch.

A frame is an opaque nested value-semantic structural part, not a free-floating forward directive or begin/end marker. Nested statement/set-result frames prevent clause ownership and statement-local semantic render scopes from leaking across real SQL-region boundaries. Ordinary parentheses remain ordinary syntax and do not themselves create a frame.

### DIALECT-014 - Shared rendering primitives are cross-dialect semantic contracts

A dialect-specific bug or grammar restriction may justify a new shared rendering/preparation primitive only after the design identifies the reusable semantic dimension independently of that dialect.

Before introducing a shared hook, scope, owner, part metadata field, binding policy, or renderer branch boundary:

- compare the requirement against every currently supported dialect affected by that path;
- inspect likely adjacent constructs in those dialects even if SQL has not implemented them yet;
- sample several major external SQL dialect families when their grammar can expose whether the proposed abstraction is too narrow;
- separate grammar-role metadata from per-dialect policy;
- keep product identity out of shared semantic names unless the value actually represents database identity;
- prefer open value-semantic scope/owner identities when future dialects/downstream extensions may legitimately add meanings;
- keep existing hook behavior as the default forwarding path for custom `SQLDialect` subclasses;
- do not choose a Boolean or closed enum merely because the first dialect has two observed outcomes if other dialects may require a third rendering mode.

For contextual values in particular, distinguish at design time between at least:

- normal bindable runtime value;
- parser/binder constant that still uses the dialect's safe literal rendering;
- structural identifier/name;
- structural SQL token/option;
- context-sensitive expression whose rendering changes but whose value remains bindable.

Do not collapse those categories into one convenience wrapper or one product-specific flag. The shared primitive should carry enough semantic context for each dialect to choose its exact representation without changing ordinary user source.

A single local scope check inside one dialect override is acceptable when that dialect currently has one contextual policy. Do not grow that method into a linear product-specific guard/`if` forest as additional independent policies appear. Once a dialect owns multiple contextual policies, factor their dispatch behind a private value-semantic resolver/table or an equivalently clean local mechanism while keeping the shared public hook context-based and unchanged. Do not pre-install such a registry before multiple real policies justify it.

This rule does not authorize speculative feature implementation. It requires cross-dialect research to validate the **shape of the internal extension point**, while the current task still implements only approved behavior.

Only if verified dialect grammar later requires structural reordering, omission, duplication, or whole-statement decisions that cannot be expressed truthfully by ordinary/scoped parts plus the evidence-proven structural-region model may a focused semantic statement representation be proposed. That proposal requires its own research, compatibility analysis, plan audit, and maintainer approval before implementation.

For the current 2.0.0 Duck PIVOT/UNPIVOT/MERGE implementation, bounded render scopes plus the generic structural-frame + dedicated-clause architecture are production truth. The PIVOT ownership blocker is closed and the implementation/native/compatibility gates have passed. Focused semantic-statement representation remains unapproved and is still only a future escalation path if the existing parts/scopes/structural-region model proves genuinely insufficient.

Any future semantic statement representation must re-enter the same recursive preparation/binding pipeline and must not become a generalized full-query AST or parallel renderer unless a separate architecture decision explicitly proves that such a redesign is required.

This is a documented extension boundary, not current technical debt and not permission to build the layer preemptively.

### DIALECT-015 - Generic terminal structural identifiers

Generic terminal names for structural SQL objects use the value-semantic `Path.Identifier` shape and the `SQLPartIdentifier` part. The path supports unqualified, schema-qualified, and catalog-plus-schema-qualified forms. Qualifiers continue to render through the established catalog and schema hooks; only the terminal object name uses the additive `SQLDialect.identifier(_:)` hook.

The base `SQLDialect.identifier(_:)` implementation returns the supplied name unchanged so legacy downstream subclasses that do not override the new hook remain source-compatible. PostgreSQL and Duck double-quote and double embedded double quotes for this category. MySQL backtick-quotes and doubles embedded backticks. Existing catalog, schema, table, column, alias hooks, and their old output are separate compatibility contracts and must not be reinterpreted through this hook.

This shared dimension is for generic structural names such as VIEW, TYPE, and INDEX names, plus local declaration names such as Duck macro parameters. A MacroParameter uses the same terminal identifier part and therefore the same generic hook; it does not require a macro-specific dialect hook. This does not authorize fixed-phrase builders, reuse of table/column/alias semantics, or a second renderer. Direct SQL atoms remain the composition mechanism for the surrounding grammar.

### DIALECT-016 - Observation-aware semantic hooks preserve old custom dialects

When a semantic hook can consume, inline, or otherwise hide unsafe values from the ordinary central binding path, unsafe-value observation uses an additive overload rather than replacing the established hook. Current semantic observation overloads cover sampling, lambda rendering, and star replacement.

The established old hook remains authoritative for ordinary `prepare(_:)`. The base observation-aware overload must invoke that old virtual hook exactly once and preserve its returned parts/output, but the provenance result is incomplete unless the implementation can account for the unsafe occurrences hidden behind that semantic boundary. This keeps old external subclasses source/behavior compatible while preventing a false-complete trace.

A built-in or downstream dialect may opt into complete provenance by overriding the additive observation-aware hook and returning `SQLObservedParts.complete(...)`. Any unsafe value consumed by that hook rather than returned for ordinary recursive binding must be represented in order with the public stateless `SQLUnsafeValueObservation.notBound(_:)` marker. Unsafe values left in returned parts continue through the one shared renderer/collector and receive their normal bound indices there.

Observation-aware hooks must not receive mutable renderer internals, mutate the collector directly, replay caller graphs, or create a second rendering pass. Complete provenance is a claim about the exact selected render, not about an independently reconstructed semantic graph.
