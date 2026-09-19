# Active Tasks

This file contains only approved current work. Ideas, unresolved choices, verified debt, and completed history belong in their separate owners.

## Current capability state

Shared Semantic Values are complete and were first published in SwifQL `2.0.0-beta.6.0.0`; `2.0.0-beta.6.0.1` remains the immutable Swift 6.3 tools/CI compatibility hotfix. The current release candidate/current prerelease is `2.0.0-beta.6.1.0`, which adds the accepted Declarative DDL authoring surface. No follow-up SwifQL implementation task is active for either completed capability.

The maintainer accepted SwiftDuckDB Research 01, Plan Correction 01, P00 temporal executable evidence, and the fresh independent Plan Re-audit 01 CLEAN result. SwifQL is the accepted shared owner for:

```text
PureDate
PureTime
DateTime
Interval
```

The shared-value capability passed its source, binding/rendering, external-consumer, cross-platform, documentation, immutable-validation, and independent root-audit gates before publication. It remains available from `2.0.0-beta.6.0.0`; `2.0.0-beta.6.0.1` remains its toolchain/CI hotfix, while the current release candidate is `2.0.0-beta.6.1.0` with the accepted Declarative DDL authoring capability.

Publication closes the SwifQL work for this capability. Any future SwifQL mutation requires a new explicit maintainer objective and exact task scope; the completed shared-value lineage does not authorize unrelated refactors, Bridges/PostgresBridge modernization, macros, migrations, Table decoding, or wider cross-dialect abstractions.

The accepted temporal/value invariants include:

```text
PureDate
- proleptic Gregorian
- astronomical Int64 year
- finite + positiveInfinity + negativeInfinity
- explicit isFinite

PureTime
- time-of-day only
- 0...86_400_000_000_000 ns inclusive
- exact standalone 24:00 distinct from midnight
- second 0...59

DateTime
- canonical civil date+time, not an instant
- own positiveInfinity + negativeInfinity
- finite state contains finite PureDate only
- date + exact 24:00 canonicalizes to next-day midnight

Interval
- exact months/days/microseconds basis
- shared positiveInfinity + negativeInfinity
- not Comparable
```

All Research-accepted conveniences are mandatory capability work: every accepted item is assigned to either an initial implementation slice or the mandatory follow-up convenience slice in the accepted plan. Do not silently drop a convenience.

Automatic SQL type inference in A1 is intentionally limited to semantically honest cross-dialect cases. Both `Column.autoType` and `Type.auto(from:isPrimary:)` must remain consistent. `DateTime` and `Interval` do **not** receive generic automatic SQL type mappings in A1; callers use explicit schema `Type` where dialect semantics differ.

Foundation `Date -> .timestamptz` compatibility remains unchanged.

Macros remain explicitly out of scope and are not recommended.

Authoritative planning evidence lives under the SwiftDuckDB artifact lineage:

```text
/Users/imike/Development/SwiftDuckDB/.artifacts/planning/value-result-type-expansion-2026-09-04/IMPLEMENTATION_PLAN.md
/Users/imike/Development/SwiftDuckDB/.artifacts/corrections/value-result-type-expansion-plan-correction-01-2026-09-04/PLAN_CORRECTION_01.md
/Users/imike/Development/SwiftDuckDB/.artifacts/validation/value-result-type-expansion-p00-temporal-2026-09-04/P00_TEMPORAL_SEMANTICS_REPORT.md
/Users/imike/Development/SwiftDuckDB/.artifacts/reviews/value-result-type-expansion-plan-reaudit-01-2026-09-04/PLAN_REAUDIT_01_REPORT.md
```

This file records only durable active-work truth; transient executor details remain in `.artifacts/**`.

## Completed state retained for context

Unsafe-Value Render Provenance is completed, independently audited, and published as the immutable pre-release `2.0.0-beta.5.1.0`. The published API provides generic same-render unsafe-value provenance while preserving established SwifQL preparation, SQL rendering, binding-order, and custom-dialect compatibility. The published artifact is remotely consumable through SwiftPM and resolves to the accepted release revision.

The completed Unsafe-Value Render Provenance prerequisite remains immutable and must not be widened or regressed by A1.

The first Duck SQL-surface redesign closure is implemented, native-/compatibility-validated, independently audited, committed, and published in the `2.0.0-beta.5.0.0` pre-release. Tasks 01-27 are complete, including the final `.duck` expansion into `SQLDialect.all` and the native/compatibility closure required for that expansion.

The Swift 6.3 strict-concurrency migration is implemented, independently audited, committed, and included in `2.0.0-beta.5.0.0`. `Package.swift` uses SwiftPM tools 6.3 and Swift 6 language mode; final validation used Apple Swift 6.3.3 with complete strict-concurrency checking. The migration intentionally preserves non-Sendable query/bind graphs where their semantics are not truthfully Sendable.

Task 29 stable documentation, migration guidance, release notes, final audit, release-doc polish, and the follow-up GitHub repository-URL correction are complete. The final URL correction is commit `b0976b2c86f089b66e342ab9ec8851deb6aba24c` (`📖 Fix repository URLs`).

The approved first Duck closure covers ordinary application/analytics/schema SQL including views and the validated catalog/file-function surface. Administration/runtime families such as INSTALL/LOAD, secrets, broad PRAGMA/configuration, checkpoint/vacuum/analyze administration, variables, export/import, SHOW/DESCRIBE/SUMMARIZE convenience, extension-specific SQL universes, and the generic SQL `name := expression` abstraction remain deferred.

Work outside the active A1 capability still requires a new explicit maintainer objective. Do not revive historical `.artifacts` task/correction lineages as active work; reconstruct fresh artifacts from current Git/source/stable authority when needed.
