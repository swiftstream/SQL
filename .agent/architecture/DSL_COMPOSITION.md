# DSL Composition Architecture

This file is the sole owner of `DSL-*` rules.

## Verified model

`SQLable` is the composable public abstraction and exposes `parts: [SQLPart]`. `SQLPart` is the ordered composition unit. DSL helpers, operators, functions, and builders ultimately produce or combine those parts.

The model is parts-based composition, not parser, AST, tokenizer, or parser-driven compilation. Composition and final SQL preparation are separate concerns: final assembly is owned by `QUERY_PREPARATION.md`, with dialect-sensitive rendering owned by `DIALECT_RENDERING.md`.

Current ordinary scalar conformances such as `String`, numeric types, `UUID`, and `Decimal` produce `SQLPartUnsafeValue`; `Date` and other special cases use their dedicated part representations. The public API also contains raw/custom structural escape hatches. They exist for deliberate structure and are not the default extension path for dynamic data.

Any future Duck functions, types, builders, and parts must use the same `SQLable`/`SQLPart` composition model and re-enter the standard preparation pipeline; they must not form a parallel Duck renderer or mini-framework.

## Rules

### DSL-001 — Core composition contract

The core composition contract is `SQLable -> [SQLPart]`.

### DSL-002 — Ordered parts

Part order is semantic and must be preserved when helpers compose or append query fragments.

### DSL-003 — Typed composition first

Extensions should compose existing typed or structured parts before introducing raw/custom SQL structure.

### DSL-004 — Raw structure and dynamic data

Raw/custom structural escape hatches may exist, but must never interpolate untrusted dynamic data. Data values use the normal bound-value path.

### DSL-005 — Standard preparation path

All composition continues into the standard preparation pipeline rather than a parallel SQL renderer. See `QUERY_PREPARATION.md` for preparation mechanics.

### DSL-006 — Composition preserves the chosen SQL contract

Part composition must preserve the public SQL identity and UX contract selected under `DESIGN-*`; composition is not a place to introduce hidden semantic substitution. See `DSL_DESIGN_AND_UX.md` for the owning SQL-first/API-design rules.

### DSL-007 — Preserve established part shape

New dialect work must not globally replace or wrap the normal part shape of established operators and fluent helpers merely to carry context for one feature. Context belongs at the semantic construct that owns it. If a new internal layer forces unrelated established consumers to unwrap that layer, redesign the layer.

This rule does not prohibit an explicitly approved major-version migration of the shared composition model when a cross-cutting structural boundary is required to preserve SQL-region semantics for multiple constructs. Such a migration must be generic, parts-native, independently audited, and justified by composition correctness rather than one dialect's renderer convenience.

### DSL-008 — Structural SQL-region ownership is a major-version tool

When an established flat clause cannot preserve required semantic ownership through normal `SQLable` composition, a dedicated value-semantic `SQLPart` for that clause is an allowed architecture tool. The clause part contains its normal child parts plus explicit ownership metadata selected by the current structural SQL region.

Ownership selection and persistence are separate responsibilities:

- a generic value-semantic SQL-region or set-result frame is the structural composition container that selects ownership for a clause kind;
- a dedicated owner-sensitive clause part persists the selected owner permanently with its child parts;
- preparation/rendering must not rediscover ownership from earlier tokens, receiver history, mutable query state, table/path identity, or dialect-specific inference.

The current root structural frame, not the deepest nested frame or latest semantic marker, is the target for standard continuation-style fluent composition. Standard continuation APIs must use one generic frame-aware structural composition primitive rather than directly appending top-level sibling parts when a root frame is present. That primitive may ask the current root frame for the owner of an open clause kind, but it must contain no PIVOT/dialect branch and must not scan earlier receiver contents for semantic history.

Real nested SQL statement/subquery/set-result regions are opaque nested structural parts. They establish their own composition frame and therefore prevent ownership from leaking into or out of the nested region. Ordinary expression parentheses are syntax only and do not establish a frame.

Requirements:

- ownership metadata must be stored structurally with the clause and copied as part of `parts`;
- ownership selection must come from the current root structural SQL-region frame through the generic composition primitive, never from a search for a specific previous construct;
- rendering may use the clause's explicit ownership to attach bounded semantic render scopes to the exact child expressions that need contextual rendering;
- the ordinary/no-owner case must preserve established SQL and binding behavior exactly;
- the structural frame must be an opaque nested value-semantic part, not begin/end markers, mutable ranges, or free-floating forward directives;
- SQL-region frames may exist only at real structural SQL boundaries such as statement/subquery or set-result regions; do not structuralize every expression merely to carry ownership;
- this pattern must not grow into a parallel statement AST or renderer merely because one clause needs explicit ownership.

Ownership identity and clause-kind identity are open extension domains. Current production source uses the public namespaced value-semantic `SQLClauseOwner` / `SQLClauseKind` model, with ordinary/no-owner represented by absence (`nil`) rather than a magic `"none"` value. Closed enums are appropriate only when the domain is genuinely exhaustive. Preserve this extension model unless a later independently audited plan proves a materially better open-value API.

Because `SQLable.parts` is public, library-owned structural frame/clause parts intentionally introduced into that array must remain safely inspectable by downstream code. Prefer public read-only structural types/state for the root frame and owner-sensitive clauses, rather than placing opaque internal concrete values into a public array and forcing downstream users to guess around them. Public inspection does not imply mutable renderer/preparation internals.

The 2.0.0 migration from historically flattened statement/subquery/set-result children to opaque structural frames, plus dedicated owner-sensitive clause parts, changes the observable `SwifQLable.parts` shape even though normal Swift query call sites and generated SQL remain unchanged where compatibility was preserved. Treat future changes of this kind as explicit major-version public-contract migrations requiring maintainer approval, downstream-extension/`parts` compatibility analysis, migration guidance, and release communication.

Downstream helpers that manually append to `self.parts` may need to migrate to a public generic structural continuation API when their intent is to continue the current framed SQL region. Copying `parts` must remain meaningful and preserve the structural tree. The evidence-proven raw-composition contract is: a framed lhs plus an unframed rhs may continue the current root structurally, while two independently framed roots remain independent values rather than having ownership merged by guesswork. Production `~` design must preserve that semantic distinction and must not infer intent from tokens or semantic history.

The 2.0.0 README/release/migration documentation must keep the reason and downstream impact of this structural change visible so users who inspect, copy, or extend `parts` are not surprised by it.
