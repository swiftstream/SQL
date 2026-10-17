# Query Preparation Architecture

This file is the sole owner of `PREP-*` rules and the detailed preparation/output contract.

## Verified preparation path

`SQLable.prepare(_:)` and `SQLable.prepareObservingUnsafeValues(_:)` enter the same library-owned recursive preparation renderer. It runtime-dispatches known concrete `SQLPart` types, recursively renders the internal scoped-part wrapper with a value-semantic `SQLRenderContext`, shares one ordered values/formatted-values collector across the selected render, assembles one ordered internal prepared-output segment stream, and returns prepared output from that traversal. The segment stream distinguishes caller/dialect text from generated bound-value positions without introducing a public SQL AST or a second render. Observation mode augments this same renderer; it is not a second part walk or a parallel SQL-generation path.

Nested `SQLPartArray` values and scoped expressions are traversed in order through that same renderer and dialect. Nested values and formatted values preserve the same depth-first order, with dialect array delimiters around assembled array fragments. No semantic-statement layer is part of the current approved preparation foundation; that remains the separately gated escalation boundary defined by `DIALECT-013`.

An unsafe value appends its value to `_values`, appends the dialect-formatted representation to `_formattedValues`, and contributes a generated bind-provenance segment unless the selected dialect path consumes or inlines that occurrence. Caller-owned SQL text, including bytes equal to a dialect's historical internal marker spelling, remains an ordinary text segment and is never reclassified as a bind by scanning returned SQL. In observation mode, **when the selected render can prove a complete trace**, each unsafe occurrence is recorded in traversal order as either `bound(index)` or `notBound`. A bound index is the exact zero-based index assigned by the same ordered collector and therefore corresponds to `SQLPrepared.splitted.values[index]`. A zero-SQL observation marker may record an explicitly consumed unsafe occurrence without changing SQL bytes or adding a bound value. When an established semantic/custom hook cannot prove complete observation, preparation preserves its exact SQL/value behavior but returns `.unavailable` provenance rather than inventing per-occurrence dispositions. The exact external bind-key syntax is owned by `DIALECT_RENDERING.md`.

`PureDate`, `PureTime`, `DateTime`, and `Interval` use this ordinary unsafe-value path. Each contributes one value occurrence; the one preparation traversal and ordered collector preserve the actual dynamic Swift value in `splitted.values` while the selected dialect formats the plain representation. They do not introduce a second codec, renderer, or binding pass.

Observed provenance is fail-closed. `SQLUnsafeValueTrace.complete` means every unsafe occurrence reachable through the selected render is accounted for by that same traversal. If a semantic hook cannot make that completeness claim, preparation still preserves the hook's exact SQL/value output but returns `.unavailable`; the renderer must not recover completeness by replaying `parts`, performing a second census, or inspecting a separately evaluated graph.

Established `Data` composition remains unchanged. Hybrid operator preparation preserves the historical PostgreSQL/MySQL behavior while supported dialects may select an explicit representation key. Duck selects the `.duck` representation; a legacy two-branch hybrid without an explicit Duck representation fails deterministically rather than silently borrowing another dialect branch.

An unknown or unhandled part falls through the current `default: break` branch and contributes no output for that part. Adding a concrete part that needs special rendering without dispatch support can therefore silently omit SQL and is a correctness hazard.

`SQLPrepared.plain` and `SQLPrepared.splitted` derive from the same prepared segment stream and collector order. `plain` copies text segments byte-for-byte and formats generated bind segments from `_formattedValues`; `splitted` copies the same text segments byte-for-byte, formats generated bind segments with dialect bind keys, and returns the original `_values` order. `SQLFormatter` post-processes this prepared provenance only; it does not inspect `SQLPart`, scan caller-owned text for marker strings, build SQL structure, or understand DSL semantics.

## Rules

### PREP-001 — Single assembly path

`prepare(_:)` is the single final part-to-SQL assembly path.

### PREP-002 — Dispatch completeness

Every newly used concrete part requiring special rendering must have defined dispatch behavior. The current unknown-part no-op fallback is a correctness hazard, not a completeness guarantee.

### PREP-003 — Aligned order

Generated bind-segment order, values order, and formatted-values order stay aligned through preparation, formatting, and prepared output.

### PREP-004 — Formatter boundary

`SQLFormatter` is post-processing only over prepared text/bind provenance. It does not build SQL structure, inspect DSL semantics, or recover bind positions by scanning caller-owned SQL text.

### PREP-005 — Shared prepared outputs

Plain and splitted output derive from the same prepared query and value ordering.

### PREP-006 — No parallel pipeline

No dialect may introduce a parallel SQL-generation or binding pipeline.

### PREP-007 — Structural SQL-region frames recurse through the same renderer

The evidence-proven major-version structural composition model may place opaque statement/subquery/set-result frame parts inside `parts`. Preparation recursively renders a frame's child parts through the same `prepare(_:)` traversal and the same ordered `values` / `formattedValues` collectors. A frame must not create a second renderer, formatter, or binding pass.

Entering a nested SQL-region frame establishes a fresh statement-local `SQLRenderContext`, so semantic render scopes owned by the parent statement do not leak into the nested statement/set-result region. This context reset does not reset or fork the binding collectors: value collection remains one deterministic depth-first traversal across the full structural tree.

Dedicated owner-sensitive clause parts persist already-selected ownership and may derive bounded child render scopes from that stored owner. Preparation must never rediscover clause ownership by scanning earlier parts, tokens, paths, or statement history.

### PREP-008 — Unsafe-value provenance is same-render observation

`prepareObservingUnsafeValues(_:)` must observe the exact selected preparation traversal. It must reuse the same recursive renderer, dialect dispatch, render context, and ordered bound-value collector that produce its returned `SQLPrepared`. Observation must not evaluate the query graph a second time, replay caller `parts`, or build provenance from an independently rendered/censused graph.

### PREP-009 — Bound indices are collector indices

Every complete-trace `bound(index)` occurrence denotes the exact zero-based slot assigned by the selected render's one bound-value collector. That occurrence must correspond to `prepared.splitted.values[index]`. An unsafe occurrence that participates in rendering but does not enter the collector is `notBound`; a library-owned zero-SQL observation marker may represent that fact without changing SQL bytes or collector order.

### PREP-010 — Completeness is fail-closed

A provenance trace may be `.complete` only when the selected render accounts for every unsafe occurrence that the active rendering path can consume, inline, or bind. When an established semantic/custom rendering hook cannot provide that proof, observed preparation must preserve its exact SQL and value behavior while returning `.unavailable`. Do not infer completeness by rescanning returned SQL, replaying semantic children, or exposing mutable renderer state to extensions.

### PREP-011 — Caller text is never bind provenance

Caller-owned and dialect-emitted text must remain `.text` provenance even when its bytes equal the dialect's historical internal bind marker. Only the renderer's actual bound unsafe-value occurrence may create a generated bind segment. Plain and split formatting must therefore preserve arbitrary marker-like caller text byte-for-byte while replacing only generated bind segments in collector order.
