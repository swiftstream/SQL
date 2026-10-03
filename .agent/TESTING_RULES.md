# Testing and Validation Rules

This file defines SwifQL testing policy. Architecture-specific assertions remain governed by the owning architecture document routed through `.agent/ARCH_INDEX.md`; this file does not define architecture IDs or duplicate detailed preparation or dialect contracts.

## Swift Testing framework

- Swift Testing is the normal and required test framework for the SwifQL test target.
- New tests import `Testing` and use a human-readable behavior name with `@Test("...")`.
- Use `#expect(...)` for normal assertions.
- Use `Issue.record(...)` for an explicit unexpected or impossible branch when a direct expectation or throwing-test flow is not cleaner.
- Throwing operations whose failure should fail the test normally use a throwing test function with direct `try`.
- Do not reintroduce XCTest imports or assertions without a separately justified compatibility reason.

## Release validation and tag safety

- `swift-tools-version` declares the package's minimum Swift tools compatibility floor; it is an executable package contract, not documentation-only metadata.
- The repository CI compiler/image must be compatible with and at least as new as that declared floor.
- Before creating a release tag, push the exact release-candidate commit and require the required GitHub Actions workflow to complete successfully for that exact commit SHA.
- A red, pending, missing, stale, or different-SHA run does not authorize tag creation.
- After pushing a release tag, require the tag-triggered required workflow to complete successfully before treating the release artifact as validated.
- Never move, delete, or force-update a published tag to repair a failed release; prepare a later patch tag instead.

## Tests follow design, never justify it

Architecture, SQL semantics, public DSL shape, and user experience are reviewed and accepted before tests are treated as evidence for an implementation.

A green test suite proves only that the implementation matches those tests. It does not prove that the architecture is clean, the abstraction is necessary, the UX is acceptable, or the compatibility cost is justified.

Rules:

- do not create tests whose practical purpose is to legitimize a workaround, compatibility unwrap, hidden routing layer, speculative abstraction, duplicated state, or bridge introduced only because another new layer disturbed established behavior;
- when a new implementation requires such a special case, review the implementation architecture first. If the layer is not independently necessary, remove the layer and its defensive tests rather than freezing the workaround as a contract;
- tests must encode an already accepted semantic/API contract, a real regression contract, or an independently verified database behavior;
- implementation/design review may reject code even when every test is green;
- test count is never a quality target by itself.

The development priority is:

```text
architecture / SQL semantics / DSL UX
-> clean implementation
-> tests and external evidence that prove the accepted behavior
```

## Coverage layers

Meaningful accepted SQL behavior is covered through the applicable combination of three layers:

1. **Focused SQL fragment/API coverage** for each meaningful SQL part, operator, builder method, helper or function overload, edge case, and value shape.
2. **Real-life composed query coverage** showing the feature inside realistic full or multi-part query construction when composition is part of its intended use.
3. **Dialect coverage** for every implemented dialect affected by the behavior.

A large real-life query does not replace focused fragment or overload cases. A fragment microtest does not replace real-life composition when composition is a meaningful risk. Realistic coverage should combine tables, schemas, aliases, predicates, values, functions, clauses or builders, subqueries or CTEs, DML or DDL, and bindings when relevant.

## Dialect classification

Classify every SQL-rendering test before writing expectations:

- Identical rendering across all implemented dialects uses `check(..., all:)`.
- The same capability across multiple dialects with different rendering uses explicit expectations for every affected implemented dialect.
- An intentionally dialect-specific capability uses explicit expectations only for dialects where that capability is intentionally supported or rendered.

Omission of an implemented dialect must be deliberate, not accidental. Adding a new dialect requires auditing both every `check(..., all:)` case and every explicit-dialect case. Rendered SQL is regression evidence for SwifQL rendering; it does not prove server-side semantic support of a feature.

## Bindings and deterministic output

When binding behavior changes, validate the bind placeholder query, values order and content when relevant, realistic multi-value cases where ordering could regress, and consistency between `.plain` and `.splitted` preparation. Deterministic input should produce deterministic output and stable bind order.

## Current test helpers

- `QueryWithDialect` provides `.psql(...)`, `.mysql(...)`, and canonical `.duck(...)` helpers.
- `check(_:all:)` currently iterates `SQLDialect.all` and compares plain output for each dialect.
- The focused `check` helper can compare a supplied binded query.

`SQLDialect.all` now contains PostgreSQL, MySQL, and Duck because Duck's first support/compatibility/native-validation closure gate has passed. `check(..., all:)` therefore exercises all three built-in dialects. Adding or removing any dialect from `SQLDialect.all` changes the semantic reach of every `all` assertion, so such collection changes still require an explicit audit/classification of both `all` cases and explicit-dialect cases before the collection changes.

## SQL fidelity and Swift naming assertions

- When a public API represents a concrete SQL keyword, type, function, operator, clause, or statement, focused tests assert that exact SQL construct rather than only a semantically similar result. For example, `Type.integer` must not be considered correct if it emits `SERIAL`, and Swift `Fn.jsonBuildArray(...)` must emit SQL `json_build_array(...)`, not `json_array(...)`.
- New public Swift API uses SQL-shaped camelCase with position-aware abbreviation casing. Tests use the canonical spelling and assert exact database spelling in generated SQL. Naming tests must protect the exact intended forms: `nextVal`, not `nextValue`; `lPad`, not `leftPad`; `concatWS`; `subStr`; `strPos`; `toTSVector`; `makeTimestampTZ`; `recordSet`; `fromJSON`; `toJSONB`; `readCSV`; `groupingId`, never `groupingID`. They must also protect leading abbreviation lowering (`jsonBuildArray`, `jsonbTypeOf`, `tsRankCD`) and compound position rules (`regExp`/`RegExp`, `recordSet`/`RecordSet`, `base64`/`Base64`).
- Existing public noncanonical `Fn` symbols use the stable additive naming migration when release history requires compatibility: add the SQL-shaped canonical counterpart and keep the established old symbol as `@available(*, deprecated, renamed: "...")`. Migration tests must prove both spellings generate byte-for-byte identical SQL while ordinary feature tests/docs use the canonical API. Unreleased intermediate naming mistakes are corrected directly rather than fossilized as aliases.
- Convenience APIs may intentionally render different dialect syntax only when the API is explicitly semantic/convenience-oriented rather than named as one concrete SQL construct. Such behavior still requires explicit per-dialect expectations.
- New dialect-specific SQL should receive tests using its real SQL vocabulary and grammar, following the existing PostgreSQL-specific test style where applicable.

## Regression discipline

- Existing PostgreSQL and MySQL output remains byte-for-byte unchanged unless a separately approved bug fix intentionally changes it.
- **Every independently confirmed dangerous case must become a durable regression test before the finding is considered closed.** A dangerous case includes a reproduced semantic leak, compatibility break, wrong bind/literal decision, incorrect clause ownership, nested-scope leak, downstream-extension failure, overload-resolution trap, dialect-policy collision, invalid structural-part interpretation, or any other failure mode that could plausibly reappear after refactoring. Fixing production code without encoding the reproduced failure boundary in tests is incomplete.
- When an audit discovers a family of related dangerous cases, protect the full meaningful boundary, not only the one example that first reproduced the bug. Add positive and negative controls as applicable: direct vs nested composition, owned vs unowned context, raw/custom vs semantic parts, supported dialect vs unaffected dialects, fluent vs erased/copied/helper composition, and downstream custom extension behavior. The test set should make the architectural invariant obvious to a future maintainer.
- Regression tests must preserve the original failure mode as closely as practical. Do not replace a concrete reproduced bug with a weaker synthetic assertion that could pass while the original behavior regresses again.
- If the dangerous case was found only through an external normal-import consumer, native database fixture, or compile-time overload probe, keep an appropriate durable test/fixture at the layer that can actually reproduce it. Repository-local tests are not an adequate substitute when they cannot observe the same boundary.
- A review/correction verdict may be `PASS` only when every confirmed blocker/dangerous case in its scope is either protected by a durable regression test/fixture or explicitly documented as impossible to encode automatically with an independently approved alternative verification gate.
- Existing PostgreSQL and MySQL placeholder/value ordering remains unchanged for established query shapes unless a separately approved bug fix intentionally changes it.
- A test-framework migration must not rewrite SQL expectations or production behavior.
- New dialect work must not repair a compatibility regression by changing an old PostgreSQL/MySQL expected string.
- Governance does not impose TDD or a blanket coverage percentage.

## Compile-time API regressions

DESIGN-037 keeps SQL composition fragment-first. Do not create compile-negative tests merely to enforce whole-statement SQL validity, clause ordering, statement completeness, or the standalone placement of a renderable SQL fragment; those concerns belong to the target database/parser/driver.

The normal SwifQL test target is the default durable home for compile-positive API and exact rendering/binding regressions. A separate normal-import downstream fixture is required when repository-local tests cannot observe the same cross-module overload or result-builder boundary.

A dedicated compile-negative harness is exceptional, not a default layer. Add one only after a concrete Swift/API invariant has been independently confirmed, cannot be represented as an ordinary positive/runtime regression, and cannot be protected adequately by a normal-import external fixture. Exact compiler diagnostic wording is never the contract, and compiler/toolchain/module infrastructure failure must never be accepted as an expected semantic rejection.

The current DESIGN-037 re-adjudication found no justified compile-negative contract among the former R3 N01-N33 matrix; those cases belong in ordinary positive compilation/rendering coverage. Runtime tests remain separately required for generated SQL, values, bind ordering, and other executable semantics.

## Downstream compatibility fixtures

Repository-local tests cannot see private extension code used by real consumers. Substantial changes to core composition, public protocols, operators, path types, `SwifQLable.parts`, or dialect hooks therefore require a temporary external consumer fixture when compatibility risk is material.

The fixture should import SwifQL normally and exercise representative patterns such as `extension SwifQLable` fluent helpers, custom Swift operators that compose `parts`, public helper-protocol conformances such as `KeyPathLastPath`, a custom `SQLDialect` subclass overriding established hooks, and incremental PostgreSQL/MySQL query construction.

If a new internal design breaks representative downstream extension code, treat the design as blocked unless the old public contract itself is explicitly and independently approved for change. The fixture protects established users; it is not an excuse to preserve a bad new API.

## Contextual rendering and composition equivalence

When semantic render scopes or another contextual-rendering mechanism is introduced or changed, tests must prove that semantics belong to the composed structure rather than one fluent call sequence.

Cover, as applicable:

- the same valid query written as one fluent chain;
- incremental `SwifQLable` variable reassignment with conditional clause inclusion;
- scoped expressions/fragments returned from helper functions and combined later;
- nested functions/subqueries while an outer render scope remains active for the relevant descendants;
- nested scopes with correct parent restoration;
- placeholder/value ordering identical to the equivalent unscoped composition rules;
- unaffected PostgreSQL/MySQL output remaining byte-for-byte stable.

If render scopes expose a public downstream extension surface, add a temporary external consumer compile fixture that imports SwifQL normally and proves the intended extension pattern without `@testable import`. If custom `SQLDialect` subclassing is part of that claimed extension contract, the fixture must prove construction/subclassing from another module rather than relying only on in-module tests.

## Cross-dialect shared-primitive validation

When DESIGN-019 applies because a change adds or reshapes shared rendering/preparation/binding/scope/ownership/composition infrastructure, validation must prove more than the triggering dialect's positive case.

At minimum:

- existing supported dialects crossing the changed pipeline retain exact SQL/bind behavior;
- a downstream custom `SQLDialect` that does not opt into the new semantic context retains default historical behavior;
- where the primitive exposes an open context/policy hook, an external custom dialect exercises that hook with a non-product-specific scope/role to prove the extension shape is genuinely reusable;
- focused tests distinguish structural identifiers/tokens from dynamic values and distinguish ordinary bindable values from grammar positions that require a parser constant or another contextual representation;
- composition tests prove the semantic role does not leak from nested expressions or unrelated raw/custom tokens;
- if cross-dialect research identified a foreseeable third rendering mode beyond the triggering dialect's two observed outcomes, tests/fixtures must demonstrate that the shared type/hook does not encode a closed binary assumption that would require a later breaking change.

External database research used to satisfy DESIGN-019 is architecture evidence, not a new support claim and not a requirement to add speculative product APIs or integration-test every sampled database. Executable tests remain scoped to supported/currently implemented behavior plus representative downstream extension fixtures.
