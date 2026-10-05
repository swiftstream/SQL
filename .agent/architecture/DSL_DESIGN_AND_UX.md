# DSL Design and UX

This document is the sole owner of SQL's durable public-API design and developer-experience principles. It explains how SQL should feel to use, how new SQL surfaces should be modeled, and how to decide whether an API belongs in the generic DSL, a dialect-specific surface, a semantic convenience layer, or an explicit raw escape hatch.

Detailed part composition lives in `DSL_COMPOSITION.md`. Dialect rendering mechanics live in `DIALECT_RENDERING.md`. Preparation mechanics live in `QUERY_PREPARATION.md`. Builder state/materialization lives in `BUILDERS_AND_QUERY_PARTS.md`.

## Primary design gates

`DESIGN-001` and `DESIGN-015` are the first two gates for every new public API or internal architecture that can affect query composition.

1. **SQL DSL first:** the user should feel that they are writing the SQL idea directly in Swift, with type safety and composition, not operating a database-driver object model or accommodating renderer internals.
2. **Composition invariance:** the same valid query must keep the same semantics when written as one fluent chain or assembled incrementally through variables, conditions, helpers, nested expressions, and separate methods/files.

If a proposal violates either gate, reject or redesign it before implementation even if it would be easy to test or internally convenient.

## DESIGN-001 — SQL-first mental model

SQL is type-safe Swift for writing SQL. It is not an ORM, database abstraction language, or semantic query language that hides SQL behind unrelated concepts.

The primary user mental model is:

> I already know the SQL dialect. SQL lets me write that SQL safely and compositionally in Swift.

A database programmer should be able to read an SQL DSL query and predict the generated SQL without learning hidden translation rules.

## DESIGN-002 — Public API mirrors SQL vocabulary

A public API named after a concrete SQL keyword, type, function, operator, clause, or statement represents that concrete SQL construct.

### Atomic keyword composition versus semantic clause APIs

When SQL grammar is only a sequence of independently meaningful keywords or modifiers, the public DSL should preserve those atoms as independently composable steps instead of inventing a camelCase convenience for every fixed phrase.

Preferred direction for pure keyword composition:

```swift
SQL.create.or.replace.table
SQL.insert.or.ignore.into
```

Do not add phrase-collapsing APIs such as `orReplace` or `insertOrIgnoreInto` merely to concatenate a fixed sequence of SQL keywords. Otherwise the DSL becomes a fluent wrapper whose API surface grows as the Cartesian product of keyword combinations instead of remaining direct SQL composition.

This rule does **not** mean that every multi-word SQL phrase must be split into one Swift property per keyword. A combined API is correct when it performs one concrete SQL/DSL operation with its own operands, arguments, structural ownership, or typed semantic role.

Examples:

```swift
query.groupBy(a, b)
query.orderBy(OrderByItem(a, .desc))
query.where(predicate)
query.returning(a, b)
```

`groupBy(...)` and `orderBy(...)` are clause constructors: they accept clause content, own clause structure, and perform a concrete operation. Writing `.group.by(...)` or `.order.by(...)` would make the DSL less clear without exposing any additional useful composition.

A combined public symbol is therefore justified when it represents something more than fixed keyword concatenation, for example:

- a clause/statement constructor with arguments or owned child structure, such as `groupBy(...)`, `orderBy(...)`, or `returning(...)`;
- one concrete SQL identifier/function/type name whose spelling maps to one SQL identity, such as Swift camelCase for a snake_case SQL function or identifier;
- a real multi-keyword SQL operator or grammar construct with its own operand/argument semantics, where the phrase acts as one semantic operation rather than arbitrary modifier chaining;
- a typed value or builder mode that intentionally represents one semantic choice, such as a join-mode value;
- a released historical compatibility surface that cannot be removed without an independently approved breaking change.

The review question is: **if the combined Swift symbol disappeared, would anything be lost besides spelling several independent SQL keywords separately?** If the answer is no, prefer atomic composition. If the symbol owns arguments, structure, validation, typing, or a real semantic operation, a combined API may be the cleaner SQL DSL.

Also check whether an existing semantic constructor already owns the real operation. If it does, do not create a Cartesian family of sibling methods by baking modifiers into the method name when those modifiers can remain atomic or typed inputs. For example, if `join(mode, target)` already owns JOIN construction, prefer adding an exact typed join mode over adding `naturalJoin`, `naturalLeftJoin`, `naturalFullOuterJoin`, and similar siblings. Likewise, if direct INSERT composition already has `.insert`, `.into`, target, and field-list primitives, do not add `insertOrIgnoreInto` / `insertOrReplaceInto` merely to pre-compose fixed modifiers.

Even for justified combined APIs, do not collapse additional optional modifiers into the name when they can compose independently. New unreleased APIs that merely collapse keyword sequences should be corrected directly before release rather than preserved with compatibility aliases.

Swift naming and SQL spelling are separate concerns:

- public Swift identifiers follow normal Swift lowerCamelCase / UpperCamelCase conventions;
- emitted SQL preserves the database's real keyword/function/type spelling, including `snake_case` or uppercase where the SQL grammar uses it;
- do not copy SQL underscores into new Swift API names merely because the SQL function contains underscores.

Examples:

- `Type.integer` represents SQL `INTEGER` and must not silently mean `SERIAL`, `IDENTITY`, or an implicit sequence-backed integer.
- `Fn.jsonBuildArray(...)` represents SQL `json_build_array(...)`; it must not silently become another dialect's differently named function.
- `Fn.jsonGroupArray(...)` represents DuckDB `json_group_array(...)`.
- `Fn.div(...)` represents SQL `div(...)`; it must not silently become `divide(...)` or `//`.
- `.qualify(...)` represents `QUALIFY`.
- a builder/entry point named for `MERGE` represents SQL `MERGE INTO`, not a generic upsert abstraction that happens to render MERGE.

When a dialect uses a different SQL construct, add that dialect's real construct as its own typed API rather than reinterpreting an existing SQL-named API.

## DESIGN-003 — API taxonomy

Every new public surface should fit one of these categories.

### A. Generic exact-SQL API

Use when the same SQL concept and grammar are intentionally shared across supported dialects.

Examples:

- SELECT
- WHERE
- EXISTS
- UNION
- common exact function names where name and argument grammar genuinely match.

The API should use the SQL vocabulary directly.

### B. Dialect-specific exact-SQL API

Use when a construct belongs to one dialect or has a materially dialect-specific grammar.

Dialect-specific support does **not** automatically justify a database-prefixed public Swift API. The ordinary user-facing DSL should name the SQL concept cleanly and let the selected dialect own rendering differences whenever that can be done truthfully.

Examples of preferred direction:

- `SQL.pivot(...)`, not a database-prefixed PIVOT entry point;
- `SQL.merge(...)`, not a database-prefixed MERGE entry point;
- `Path.Catalog(...)` when the concept being modeled is a catalog rather than the database product itself;
- clean `Fn.*` / `Type.*` symbols whose exact support is documented/tested per dialect.

A database prefix is appropriate only when the API intentionally exposes database identity, when incompatible same-named concepts cannot share a truthful Swift surface, or for implementation symbols where the distinction materially improves ownership/clarity.

Historical released forms such as `PostgresArray` / `PgArray` remain compatibility surface and are not a naming requirement for new dialect work.

For DuckDB-specific Swift implementation symbols that genuinely require a database prefix, use `Duck...` for types and `duck...` for helpers/functions. Do not introduce new `DuckDB...` / `duckDB...` Swift symbol prefixes. The canonical Swift dialect factory is `SQLDialect.duck`, so ordinary preparation is `prepare(.duck)`. Keep the real database spelling only where the value is actual database identity rather than Swift API naming, such as the internal dialect id `"duckdb"` and human-facing prose.

Dialect-specific functions may still live under clean `Fn` names when the public name is the exact SQL function name; source filenames may use focused `Duck` grouping where useful.

### C. Explicit semantic/convenience API

Use sparingly when the API intentionally abstracts a user intent rather than naming one concrete SQL construct.

Its name must make that semantic/convenience role obvious.

Existing examples include:

- `Type.auto(...)`
- `OrderByItem.random` / `SQLHybridOperator.random`.

A semantic convenience may render dialect-specific syntax only when it names a genuinely semantic intent rather than collapsing distinct exact SQL constructs. Each dialect branch must be explicit and tested. Legacy conveniences do not authorize creating new hidden translations in SQL-named APIs.

A convenience must not become a portability facade that silently swaps one named SQL construct for another. For example, PostgreSQL `decode(..., 'base64')` and Duck/MySQL `from_base64(...)` are distinct SQL functions and therefore require distinct exact SQL APIs. Selecting a dialect may change harmless spelling/casing or syntax required by the same exact construct, but it must not translate `decode` into `from_base64` or vice versa.

### D. Explicit expert escape hatch

Use `.raw`, custom types, or similarly explicit APIs when the user intentionally supplies SQL outside the typed surface.

Raw/custom APIs are escape hatches, not the implementation strategy for ordinary first-class SQL features.

## DESIGN-004 — Transparency over magical portability

SQL does not promise that every API is portable to every database.

Prefer a truthful SQL API with an explicit dialect support boundary over a generic-looking API that approximates another database's feature. A dialect-specific support boundary does not by itself require a database-prefixed Swift name; DESIGN-014 governs the user-facing shape.

Rules:

- do not rename functions/types/statements behind the user's back;
- do not translate one exact named SQL function/construct into a differently named construct merely because another dialect offers similar semantics;
- dialect-specific casing of the same SQL function name may vary where the databases spell that same construct differently, e.g. `FROM_BASE64` versus `from_base64`, while the Swift API remains the exact camelCase `fromBase64`;
- do not degrade semantics silently;
- do not claim support merely because another dialect parser might accept similar text;
- do not introduce automatic lifecycle behavior, such as hidden sequence creation, unless the public API explicitly models that lifecycle;
- unsupported or unverified SQL remains unclaimed rather than guessed.

Mechanical rendering by the historical non-validating preparation pipeline is not itself a support claim.

## DESIGN-005 — Composability before new abstraction

Before adding a new builder or fluent API, verify whether existing `SQLable` composition already expresses the exact SQL naturally.

Prefer reusing the existing DSL when the resulting Swift remains clear and faithful to SQL.

Examples discovered during DuckDB design:

- FROM-first SQL is already naturally representable as `SQL.from(...).select(...)`; a separate FROM-first builder would duplicate the DSL.
- `GROUP BY ALL` is naturally representable through existing composition when `ALL` is already an exact SQL part.

Create a new API only when it adds one of these real benefits:

- missing SQL vocabulary;
- typed grammar constraints;
- correct clause placement/state ownership;
- safe identifier/value handling;
- materially better readability without hiding SQL.

Do not create abstractions merely for symmetry between dialects.

## DESIGN-006 — Swift call shape should resemble SQL grammar

Method names, argument order, labels, and builder phases should make the corresponding SQL easy to recognize.

Guidelines:

- preserve SQL clause order where practical;
- use SQL terms as labels (`on`, `using`, `returning`, `groupBy`, `qualify`, etc.);
- use distinct APIs for distinct SQL grammar forms rather than runtime guessing;
- model mutually exclusive grammar states with types/enums/initializers where that prevents invalid SQL;
- do not infer one SQL mode from the runtime type or value of an unrelated argument;
- when one SQL function has multiple dialect-specific grammar forms but the same exact function name, prefer additive overloads whose Swift signatures mirror those forms.

The DSL should remain readable left-to-right as SQL.

## DESIGN-007 — Local implementation style reference

The current PostgreSQL implementation is the primary local best-practice reference for how new dialect code should be shaped and organized.

Useful patterns:

- focused `SQLDialect` subclass overrides for true dialect hooks;
- exact SQL function names through `Fn.Name` and direct typed-part composition;
- historical specialized APIs such as `PostgresArray` are compatibility evidence only, not naming precedent for new dialect surfaces;
- semantic source organization under `Dialect/`, `Functions/`, `Builders/`, `Parts/`, `Path/`, and `SQLable+Parts/` rather than a separate mini-framework per database;
- focused exact-SQL tests plus realistic composed queries.

Copy the architecture/style, not PostgreSQL semantics or historical quirks. Current official documentation for the target database is authoritative for target-dialect SQL.

## DESIGN-008 — Type safety protects structure, not SQL knowledge

Type safety should help users construct valid SQL structure while keeping the SQL visible.

Good uses of types include:

- enums for finite SQL modes;
- typed join modes;
- typed ordering/nulls options;
- typed nested database types;
- builders that make invalid clause combinations difficult or impossible;
- safe separation between identifiers, inline structural SQL, and bound values.

Avoid type systems that replace familiar SQL vocabulary with a second conceptual language.

A user who knows SQL should not need to learn an unrelated SQL DSL ontology before being productive.

## DESIGN-009 — Values and identifiers remain explicit

SQL distinguishes SQL structure from dynamic data.

- Dynamic values should use the normal value/binding pipeline when SQL grammar permits.
- Identifiers use identifier-aware typed parts and dialect quoting.
- Trusted structural SQL may use explicit operator/custom/raw mechanisms only where appropriate.
- Do not interpolate untrusted runtime values or identifiers into raw SQL strings to simplify a builder implementation.

Swift-native values such as `Date` may have dialect-specific literal/value rendering when the public API genuinely names that Swift value rather than a concrete SQL function. This does not authorize a new semantic wrapper to choose among differently named SQL functions. Historical direct `Data.parts` remains a protected compatibility shape; new Duck binary/base64 support must use exact SQL APIs and normal value/binding primitives rather than a cross-dialect `binary(...)` facade.

## DESIGN-010 — Backwards compatibility is part of UX

For this established library, predictable upgrades are a developer-experience requirement.

The major-version number is not permission to gratuitously redesign the established query DSL. Users may have hundreds or thousands of SwifQL queries, so ordinary existing query source should continue to compile without mechanical rewrites across upgrades whenever the existing API can be preserved safely.

Rules:

- existing public query DSL names, argument labels/order, fluent call shapes, and reference/value usage remain source compatible unless a separately approved unavoidable correctness/safety conflict proves otherwise;
- a major release may strengthen internal invariants, concurrency guarantees, diagnostics, or add new APIs, but those changes should be implemented behind the existing DSL surface when technically possible;
- existing PostgreSQL/MySQL output remains byte-for-byte stable;
- existing tests are regression contracts;
- new dialect support is additive;
- do not repair a new-dialect implementation by rewriting legacy SQL expectations;
- when a public signature change appears necessary, first prove that a source-compatible wrapper/view/overload cannot preserve the existing call site, then return the material decision to the maintainer before mutation.

A deliberate major redesign is a separate product/API decision. Merely preparing a major release does not authorize opportunistic DSL breakage.

## DESIGN-011 — Testing proves both SQL fidelity and real use

A new public SQL surface is not complete with only one snapshot-like assertion.

Testing should cover:

1. the exact SQL construct/name/grammar the API promises;
2. focused edge cases and overloads;
3. realistic composed queries that resemble application code;
4. all dialects for which support is deliberately claimed;
5. bind placeholder and value ordering where dynamic values are involved;
6. backwards compatibility for shared infrastructure changes.

Dialect-specific APIs are tested only for the dialects deliberately supported. Historical mechanical rendering in another dialect does not create a new support contract.

See `TESTING_RULES.md` for the detailed testing policy.

## DESIGN-012 — Swift naming is SQL-shaped camelCase, SQL spelling stays exact

SQL is an SQL DSL. Its public Swift names should remain visually and lexically close to the SQL a database engineer already knows while still following Swift camelCase syntax.

Canonical Swift naming therefore **preserves SQL vocabulary while exposing the useful internal components of that vocabulary**. CamelCase may split a glued database token into recognizable SQL-derived pieces. True abbreviations use one consistent position-aware casing rule, while ordinary shortened fragments remain ordinary camelCase components. The API must not translate an SQL fragment into a different English word.

Rules:

- public methods, properties, variables, enum cases, function helpers, and public argument labels use `lowerCamelCase`; public types/protocols use `UpperCamelCase`;
- SQL underscore separators become camelCase boundaries, then each SQL-derived component uses the repository's casing rules: `json_build_array` -> `jsonBuildArray`, `grouping_id` -> `groupingId`, `concat_ws` -> `concatWS`, `from_json` -> `fromJSON`, `read_csv` -> `readCSV`, `read_json` -> `readJSON`, `ts_rank_cd` -> `tsRankCD`;
- when one SQL token visibly concatenates recognizable pieces, Swift exposes those boundaries while retaining the SQL-derived pieces: `setseed` -> `setSeed`, `nextval` -> `nextVal`, `currval` -> `currVal`, `initcap` -> `initCap`, `isfinite` -> `isFinite`, `localtime` -> `localTime`, `localtimestamp` -> `localTimestamp`, `timeofday` -> `timeOfDay`, `lpad` -> `lPad`, `btrim` -> `bTrim`, `strpos` -> `strPos`, `substr` -> `subStr`, `ntile` -> `nTile`;
- selected compact SQL tokens are themselves decomposed where the useful database vocabulary is clearer as multiple Swift components: `tsvector` -> `ts + vector`, `tsquery` -> `ts + query`, `timestamptz` -> `timestamp + tz`, `recordset` -> `record + set`, `regexp` -> `reg + exp`;
- do **not** expand or translate SQL abbreviations into different words merely to make the Swift name more descriptive: `val` stays `Val`, `curr` stays `curr`, `l`/`r` stay `l`/`r`, `elems` stays `Elems`, `mins` stays `mins`, and `secs` stays `secs`;
- true abbreviations are cased uniformly by position: when an abbreviation begins a `lowerCamelCase` identifier, the whole abbreviation is lowercase; when it is a later component, the whole abbreviation is uppercase. Therefore SQL `json` -> leading `json` / medial `JSON`, `jsonb` -> `jsonb` / `JSONB`, `csv` -> `csv` / `CSV`, `ts` -> `ts` / `TS`, `tz` -> `tz` / `TZ`, `ws` -> `ws` / `WS`, and `cd` -> `cd` / `CD`;
- `Id` is the explicit repository exception to the general abbreviation rule: identifier-like SQL `id` is `id` when leading and `Id` when medial, never `ID`;
- ordinary shortened fragments are not abbreviations and never become all-caps: `str` -> leading `str` / medial `Str`, `pos` -> `pos` / `Pos`, `val` -> `val` / `Val`, `curr` remains an ordinary word fragment;
- compound lexical pieces are position-aware camelCase, not abbreviations: `recordset` decomposes to leading `recordSet` / medial `RecordSet`; `regexp` decomposes to leading `regExp` / medial `RegExp`; `base64` remains leading `base64` / medial `Base64`;
- existing concise public labels such as `pathElems:`, `mins:`, and `secs:` remain valid when they already mirror the project's SQL-shaped vocabulary; do not expand them mechanically;
- `Fn.Name` is public Swift API too: its canonical member should use the same SQL-shaped camelCase base name as the corresponding `Fn` helper while storing/emitting the exact SQL identifier;
- preserve established database/type/function terms as indivisible fragments only where splitting them would reduce SQL recognizability or blur a different SQL construct. This is not a blanket exemption for glued words: `recordset`, `tsvector`, `tsquery`, `timestamptz`, `substr`, `btrim`, and `strpos` are explicitly split by the policy above;
- SQL spelling remains exact in emitted SQL/internal SQL identity. A Swift rename never authorizes changing `setseed` to `set_seed`, `FROM_UNIXTIME` to another function, or any other database token;
- naming is not semantic substitution: `Fn.setSeed(...)` still represents the concrete SQL function `setseed(...)`, and `Fn.nextVal(...)` still represents concrete SQL `nextval(...)`; DESIGN-002/004 continue to forbid remapping one named SQL construct to another.

Examples of canonical SQL-shaped naming:

- Swift `Fn.setSeed(...)` -> SQL `setseed(...)`;
- Swift `Fn.nextVal(...)` -> SQL `nextval(...)`;
- Swift `Fn.currVal(...)` -> SQL `currval(...)`;
- Swift `Fn.subStr(...)` -> SQL `substr(...)`;
- Swift `Fn.bTrim(...)` -> SQL `btrim(...)`;
- Swift `Fn.strPos(...)` -> SQL `strpos(...)`;
- Swift `Fn.concatWS(...)` -> SQL `concat_ws(...)`;
- Swift `Fn.localTimestamp` -> SQL `localtimestamp`;
- Swift `Fn.timeOfDay()` -> SQL `timeofday()`;
- Swift `Fn.fromUnixTime(...)` -> SQL `FROM_UNIXTIME(...)`;
- Swift `Fn.fromJSON(...)` -> SQL `from_json(...)`;
- Swift `Fn.readCSV(...)` -> SQL `read_csv(...)`;
- Swift `Fn.readJSON(...)` -> SQL `read_json(...)`;
- Swift `Fn.toJSON(...)` -> SQL `to_json(...)`;
- Swift `Fn.jsonTypeOf(...)` -> SQL `json_typeof(...)`;
- Swift `Fn.jsonbTypeOf(...)` -> SQL `jsonb_typeof(...)`;
- Swift `Fn.toJSONB(...)` -> SQL `to_jsonb(...)`;
- Swift `Fn.lPad(...)` -> SQL `lpad(...)`;
- Swift `Fn.toTSVector(...)` -> SQL `to_tsvector(...)`;
- Swift `Fn.toTSQuery(...)` -> SQL `to_tsquery(...)`;
- Swift `Fn.plainToTSQuery(...)` -> SQL `plainto_tsquery(...)`;
- Swift `Fn.tsRankCD(...)` -> SQL `ts_rank_cd(...)`;
- Swift `Fn.makeTimestampTZ(...)` -> SQL `make_timestamptz(...)`;
- Swift `Fn.jsonPopulateRecordSet(...)` -> SQL `json_populate_recordset(...)`;
- Swift `Fn.jsonBuildArray(...)` -> SQL `json_build_array(...)`;
- Swift `Fn.generateSeries(...)` -> SQL `generate_series(...)`;
- Swift `Fn.groupingId(...)` -> SQL `grouping_id(...)`.

Examples of intentionally preserved database terms:

- `Fn.substring(...)` remains `substring` because that full SQL function name is already a complete recognizable term and is separately modeled from `substr`/`subStr`;
- `nvl`, leading `jsonb...`, and standard mathematical/SQL notation remain intact where no clearer project-approved component split exists;
- `cumeDist` remains the direct camelCase of SQL `cume_dist`;
- `fromBase64` remains the established `Base64` spelling.

When a new or existing public name is reviewed, use this decision order:

1. identify the exact SQL identifier/construct and its database spelling;
2. split underscores into camelCase boundaries;
3. identify clear internal boundaries inside glued SQL tokens, including approved compound splits such as `recordSet`, `TSVector`, `TimestampTZ`, `subStr`, and `strPos`;
4. classify each component as a true abbreviation, an ordinary shortened fragment, or a compound lexical piece; apply position-aware abbreviation casing, the explicit `Id` exception, and ordinary camelCase to non-abbreviations;
5. never replace an SQL-derived fragment with a different English synonym;
6. compare neighboring SQL APIs for project consistency;
7. confirm that a database engineer can still recognize the exact SQL construct from the Swift name;
8. only then decide compatibility handling from release history.

Do not create a permanent compatibility alias merely because an intermediate unreleased branch used a bad canonical spelling. Correct unreleased mistakes directly. Conversely, an established historical public spelling that may already be used by downstream clients remains source-compatible: add the final SQL-shaped canonical spelling, keep the old spelling only as `@available(*, deprecated, renamed: "...")`, and delegate to the canonical implementation with byte-for-byte identical SQL.

This compatibility policy applies to **all historical noncanonical public names**, not only `snake_case`. Existing historical snake_case declarations remain compatibility bridges, while any other historical spelling that violates the SQL-shaped camelCase policy receives the same additive treatment when release history requires it.

Canonical implementations and ordinary tests/docs use the SQL-shaped camelCase API. Compatibility tests prove every retained legacy spelling renders byte-for-byte identical SQL. New work must not expand SQL abbreviations or normalize their initialism casing merely to make the API read like general-purpose English Swift.

## DESIGN-013 — Decision checklist for a new API

Before implementing a new public API, answer these questions in order:

1. What exact SQL should the user recognize?
2. Is this the same SQL construct/grammar across dialects, or a dialect-specific construct?
3. Does the current composable DSL already express it clearly and safely?
4. If not, is the missing piece a token/fluent part, a typed expression, a builder/state model, a type, a function helper, or a true dialect-rendering hook?
5. Does the proposed Swift name correspond to the emitted SQL, or is it an explicitly named semantic convenience?
6. Is any hidden substitution, semantic degradation, or runtime guessing occurring?
7. Can dynamic values and identifiers remain in the normal safe/bound pipelines?
8. Does the source location match existing repository organization and PostgreSQL-style precedent?
9. What focused exact-SQL tests prove the API contract?
10. What realistic query proves the API composes naturally?
11. Could the implementation change existing PostgreSQL/MySQL output or source compatibility?
12. Is the target-dialect behavior established by current official documentation rather than similarity or memory?
13. Could a downstream user reasonably need to add their own value, helper, dialect behavior, or protocol conformance here without changing SQL itself, and does the proposed public shape preserve that extension path?

If these questions do not have clear answers, research/plan the API further before implementation.

## DESIGN-014 — Dialect-transparent user-facing DSL

Dialect support should normally be visible at preparation/execution time, not through database implementation wrappers scattered through ordinary query source.

Rules:

- when the user is expressing an SQL concept, prefer the clean SQL-shaped API regardless of which supported dialect will render it;
- use the selected `SQLDialect`, structured parts, dialect hooks, or other reviewed contextual rendering mechanisms to adapt syntax/qualification where the SQL concept is the same but the dialect grammar differs;
- do not make users replace normal table/column/function/order expressions with database-prefixed wrappers merely to satisfy a renderer limitation;
- database-specific implementation types may exist when needed, but ordinary call sites should not have to name them when type inference or a clean generic entry point can hide them;
- dialect-transparent rendering may adapt syntax/qualification/casing required by the same exact modeled SQL construct, but it must not silently substitute a differently named SQL function/statement/type/operator or degrade semantics in violation of DESIGN-002/004;
- if the existing parts pipeline lacks enough semantic context to render a dialect correctly, improve the shared rendering architecture rather than accumulating neighboring-token heuristics or one-off database wrappers.

The review target is simple: normal Swift query source should read like the SQL idea the user intends, not like an object model for a particular database driver.

## DESIGN-015 - Query semantics survive incremental composition

Public query APIs must remain correct when users compose queries incrementally rather than as one fluent expression.

Equivalent query structure must preserve equivalent semantics when assembled through any reasonable combination of:

- a single fluent chain;
- `var query: SQLable` reassignment;
- `if` / `guard` controlled clause inclusion;
- helper methods returning `SQLable` fragments or expressions;
- fragments created in different methods/files and combined later;
- nested expressions, functions, subqueries, and builders.

Do not implement meaning as ambient builder mode, source-order side state, or an assumption that related method calls occurred consecutively in Swift. Semantic metadata needed by rendering must travel with the composed part/expression that owns it.

Do not introduce generic hidden statement-routing into established methods such as `groupBy`, `orderBy`, `limit`, or `returning` merely to make a new unreleased builder retain private state through type erasure. That changes the meaning and structural behavior of old DSL entry points for the benefit of a new implementation layer. First seek a design where the new construct composes honestly through ordinary parts and scoped metadata.

For the current Duck PIVOT/UNPIVOT/MERGE design wave, bounded semantic render scopes remain the approved contextual-rendering mechanism. The root clause-ownership audit plus focused disposable evidence diagnostic have now validated a generic major-version composition architecture under `DSL-008`: the current root SQL-region/set-result frame selects an open clause owner by clause kind through one generic frame-aware continuation primitive; a dedicated owner-sensitive clause part persists that selection; bounded render scopes adapt only the affected children. This is not permission for hidden receiver-history routing: continuation methods must not search for PIVOT or inspect semantic history.

Focused semantic statement representation remains only a future architecture escalation boundary for genuinely different evidence, not a fallback that an implementation task may choose automatically.

This does not make invalid SQL valid. If a caller conditionally omits a required parent construct but still appends a clause that only makes sense inside that construct, the resulting query may correctly be invalid. Likewise, SQL is not required to distort an established global SQL API merely to make every dialect-specific invalid form unrepresentable at Swift compile time after semantic ownership has been erased. If a stricter dialect grammar cannot be expressed truthfully without changing ordinary overload behavior, adding hidden routing, or exposing renderer accommodation in user source, preserve the direct SQL DSL and let target-dialect validation reject invalid SQL. The invariant is that equivalent valid composition shapes render identically, not that SQL guesses or proves all grammar.

## DESIGN-016 - Preserve established public extension contracts deliberately

Public helper protocols and extension-oriented surfaces are compatibility contracts even when they look like implementation utilities.

`KeyPathLastPath` is established public API and is used by public query surfaces such as RETURNING, conflict targets, constraints, key paths, and path types. It remains useful as a precise grammar constraint for new APIs whose own static signature truthfully owns column-name-only grammar. Do not force it into an established erased global method merely to simulate a dialect-specific compile-time restriction that overload resolution cannot actually enforce.

Do not remove or replace such a protocol merely to modernize internal architecture. If a future major version has a materially better replacement, first provide the clearest practical bridge/deprecation path and include a concise migration note with extension examples for downstream users who may conform their own local types.

New internal architecture should expose a small public extension point when that falls naturally from the design and remains type-safe/maintainable. Do not contort the core model or leak mutable internals solely to make every mechanism externally customizable.

## DESIGN-017 - Existing users do not pay for internal evolution

SQL is an established library whose users may own hundreds or thousands of queries and private extension code. Repository-visible call sites are only a fraction of the real compatibility surface.

Therefore:

- existing PostgreSQL/MySQL query source must continue compiling unchanged unless a separately approved bug fix proves a specific old behavior wrong;
- established generated PostgreSQL/MySQL SQL and binding order remain byte-for-byte regression contracts unless that same explicitly approved bug fix changes them;
- downstream `extension SwifQLable`, custom operators, helper methods, public-protocol conformances, path abstractions, and `SQLDialect` subclasses are first-class compatibility concerns even when their source cannot be inspected here;
- internal data-shape changes must not silently alter overload resolution, `parts` composition, public protocol meaning, or dialect-hook dispatch relied on by downstream code;
- a new feature must adapt to established contracts whenever that can be done cleanly; established users must not be forced to rewrite their DSL merely because a new internal model would be easier for the implementation;
- a major release is not a waiver for avoidable breakage. Use a breaking change only when the old public contract itself must change for a demonstrated correctness/design reason and no clean source-compatible path exists;
- when a breaking change is genuinely unavoidable, document the exact reason, migration path, and downstream-extension impact before implementation.

The standard is not merely "our test suite still passes." The standard is that a normal user updating the library should not inherit a debugging project because the library changed its internals.

An explicitly approved major-version structural composition migration may change the observable `parts` tree when that is required to preserve SQL-region ownership through existential/copy/nested composition. In that case ordinary SQL-shaped query call sites should remain source-compatible, while downstream code that assumes flattened statement/clause parts or manually appends continuation parts receives a documented migration to the public structural composition API.

## DESIGN-018 - Downstream extensibility is a first-class API requirement

SQL is intentionally extendable from application code and downstream packages. A user should not need to fork SQL or submit a pull request merely to add a legitimate private SQL/dialect/semantic value that the core library does not need to know exhaustively.

When a public semantic category is open in principle, do not model it as a closed Swift `enum` merely because SQL currently knows only a few values. Prefer an extensible public value-semantic type with a public initializer and stable public identity representation, with library-known values exposed as static conveniences. A namespaced string-backed identity is an appropriate pattern when arbitrary downstream names are meaningful and the core can carry unknown values opaquely.

Illustrative shape:

```swift
public struct SemanticRole: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public static let builtIn: Self = .init(
        namespace: "swifql",
        name: "builtIn"
    )
}

extension SemanticRole {
    public static let applicationSpecific: Self = .init(
        namespace: "com.example.application",
        name: "applicationSpecific"
    )
}
```

Use a closed `enum` only when the modeled SQL grammar/domain is genuinely exhaustive and an unknown downstream value would be invalid or unsafe rather than merely unknown to SQL.

For optional semantic ownership, prefer absence (`nil`) for the ordinary/no-owner case instead of reserving a magic open-domain identity such as `"none"`, unless evidence shows that an explicit ordinary owner is materially required.

The same extensibility rule applies to visibility. When a type, initializer, protocol hook, value wrapper, or structural helper is a plausible safe downstream extension point, prefer making that boundary public from the start instead of keeping it internal solely to minimize API surface. Public extensibility must remain value-semantic and must not expose mutable renderer/preparation internals or weaken safety invariants.

Review downstream extensibility proactively. Existing users may maintain private `SQLable` helpers, custom parts/operators, path abstractions, protocol conformances, and `SQLDialect` subclasses that will never appear in this repository. Preserving their ability to extend SQL is part of the product design, not an accidental implementation detail.

## DESIGN-019 - Cross-dialect architecture before dialect-triggered internals

A new dialect may be the first place that exposes a missing internal capability, but that dialect must not silently become the ontology of the shared architecture.

Before adding or changing a shared rendering, preparation, binding, semantic-scope, ownership, value/identifier, operator, clause, or structural-composition primitive, research the **semantic class of the problem across dialects**, not only the dialect that triggered the work.

The minimum design check is:

1. inspect every currently supported dialect whose existing behavior could pass through the primitive;
2. inspect known adjacent/unimplemented constructs in those dialects that are likely to need the same semantic category later;
3. sample several major external SQL dialect families when that can reveal materially different grammar requirements, such as PostgreSQL-family, MySQL-family, SQLite, SQL Server/T-SQL, Oracle, BigQuery/GoogleSQL, and Snowflake;
4. classify which dimension actually varies: identifier vs value, bindable value vs parser constant, literal token vs expression, qualification, casing, placeholder form, clause ownership, statement ownership, or another grammar role;
5. design the shared primitive around that semantic dimension with open/value-semantic extension points where the domain is open, while keeping each dialect's concrete policy in the dialect layer;
6. prove that a future dialect can consume the primitive without changing established public query source, existing `parts` meaning, or previously released dialect hooks.

This is architecture foresight, not permission to implement speculative SQL features. Do not add public APIs, dialect branches, enums, scopes, or hooks merely because another database might use them someday. Research enough cross-dialect evidence to avoid naming or shaping a shared primitive around one product-specific accident, then implement only the capability required by the current approved task.

Examples of the required distinction:

- if one dialect requires a value to be a parser constant in a particular grammar position, model the grammar role/context generically rather than creating a `Duck...` value wrapper;
- if different dialects may choose bind, safe literal, or another exact representation for the same contextual value, do not freeze the shared hook to the first dialect's binary decision unless cross-dialect evidence proves that Boolean policy is the durable semantic boundary;
- if a semantic owner is needed, name/model the owner by the SQL grammar role it owns, not by the database product that first required it.

A proposal fails this gate if supporting a foreseeable equivalent PostgreSQL/MySQL/other-dialect grammar later would require a breaking public-source rewrite, changing the meaning of an established generic hook, replacing a closed product-shaped enum/type, or introducing a parallel renderer because the original primitive encoded one dialect too narrowly.

## DESIGN-020 - Declarative query authoring preserves SQL boolean grammar

The additive result-builder query-authoring surface is implemented. This section defines its durable public design semantics.

The builder remains a SQL-shaped authoring layer over the existing SQL composition/preparation model. It must not introduce a second predicate AST, hidden ORM-style semantics, or an alternate binding/rendering pipeline. The canonical package/module/root spelling is `SQL`. Declarative construction uses the overloaded `SQL { ... }` function; fluent construction starts from the direct global `SQL` root value, for example `SQL.select(...)` or `SQL.from(...)`. The concrete formed-SQL carrier is `SQLContent`: it may represent a complete statement or meaningful composed SQL content, but does not imply raw text, execution, or whole-statement validity. `SQLFragment` is intentionally rejected because complete statements use the same carrier; `SQLExpression` is intentionally rejected because expression already has a narrower SQL-grammar meaning; `SQLValue` is intentionally rejected before publication because it is ambiguous with literal/bind values. `SQLQuery` exposes fixed shorthand `Query = SQLContent` rather than an associated query representation. Fluent lookup comes from the existing `SQLable` instance surface; do not duplicate that surface with static forwarding members. The unpublished intermediate spellings `SQL.root`, concrete-type `SQL`, and `SQLValue` have no compatibility obligation.

The target query shape uses the established model/property-wrapper path surface rather than invented plain model-member pseudo-columns. For example:

```swift
SQL {
    Select(User.$id, User.$email)
    From(User.table)

    Where {
        User.$isActive == true

        if let email {
            User.$email == email
        }
    }

    OrderBy(User.$createdAt, .desc)
    Limit(100)
}
```

The corresponding SQL idea is:

```sql
SELECT "User"."id", "User"."email"
FROM "User"
WHERE "User"."isActive" = TRUE
  AND "User"."email" = 'john@example.com'
ORDER BY "User"."createdAt" DESC
LIMIT 100
```

when `email == "john@example.com"`. If `email == nil`, the conditional predicate disappears and the SQL becomes:

```sql
SELECT "User"."id", "User"."email"
FROM "User"
WHERE "User"."isActive" = TRUE
ORDER BY "User"."createdAt" DESC
LIMIT 100
```

### Default WHERE composition is AND

Surviving direct children of `Where { ... }` are joined with SQL `AND`, preserving source order and binding order.

```swift
Where {
    User.$isActive == true
    User.$age >= 18
}
```

means:

```sql
WHERE "User"."isActive" = TRUE
  AND "User"."age" >= 18
```

This matches the established SQL query-builder behavior where multiple stored WHERE predicates are emitted as the first `WHERE` predicate followed by `AND` predicates.

### And and Or are explicit grouped boolean composition

`And { ... }` joins its surviving children with SQL `AND` and owns an explicit parenthesized boolean group.

`Or { ... }` joins its surviving children with SQL `OR` and owns an explicit parenthesized boolean group.

The grouping is intentional even when the group is the only child of `Where`. The Swift structure therefore makes SQL precedence visible and deterministic.

```swift
Where {
    Or {
        User.$role == .admin
        User.$role == .moderator
    }
}
```

means:

```sql
WHERE (
    "User"."role" = 'admin'
    OR "User"."role" = 'moderator'
)
```

Nested groups preserve the same rule:

```swift
Where {
    User.$isActive == true

    Or {
        User.$role == .admin

        And {
            User.$role == .user
            User.$age >= 18
        }
    }
}
```

means:

```sql
WHERE "User"."isActive" = TRUE
  AND (
      "User"."role" = 'admin'
      OR (
          "User"."role" = 'user'
          AND "User"."age" >= 18
      )
  )
```

### Swift control flow controls predicate presence, not SQL meaning

The query result builders may support normal Swift control flow where runtime query composition requires it, including optional branches and loops. Control flow decides which predicate expressions survive. SQL boolean meaning still belongs only to `Where`, `And`, `Or`, and explicit existing predicate operators.

For example:

```swift
Where {
    User.$isActive == true

    if let email {
        User.$email == email
    }

    if !roles.isEmpty {
        Or {
            for role in roles {
                User.$role == role
            }
        }
    }
}
```

with:

```swift
email = "john@example.com"
roles = [.admin, .moderator]
```

means:

```sql
WHERE "User"."isActive" = TRUE
  AND "User"."email" = 'john@example.com'
  AND (
      "User"."role" = 'admin'
      OR "User"."role" = 'moderator'
  )
```

A PostgreSQL prepared form must preserve the same structure and value order:

```sql
WHERE "User"."isActive" = TRUE
  AND "User"."email" = $1
  AND (
      "User"."role" = $2
      OR "User"."role" = $3
  )
```

with bound values in source/iteration order:

```text
john@example.com
admin
moderator
```

If `email == nil` and `roles == [.admin, .moderator]`, the SQL becomes:

```sql
WHERE "User"."isActive" = TRUE
  AND (
      "User"."role" = 'admin'
      OR "User"."role" = 'moderator'
  )
```

If `email == "john@example.com"` and `roles.isEmpty`, the SQL becomes:

```sql
WHERE "User"."isActive" = TRUE
  AND "User"."email" = 'john@example.com'
```

If both dynamic branches disappear, only the unconditional predicate remains:

```sql
WHERE "User"."isActive" = TRUE
```

### Empty dynamic predicate containers disappear

A query result builder is intentionally different from the accepted static/non-empty Declarative DDL builders. Runtime query composition must allow zero surviving predicates.

If a `Where { ... }` body has no surviving children, the entire `WHERE` clause disappears. It must not render a dangling `WHERE`, `WHERE TRUE`, or any other synthetic predicate.

```swift
Where {
    if let email {
        User.$email == email
    }

    if !roles.isEmpty {
        Or {
            for role in roles {
                User.$role == role
            }
        }
    }
}
```

with `email == nil` and `roles.isEmpty` produces no WHERE clause:

```sql
-- no WHERE clause
```

Likewise, an `And { ... }` or `Or { ... }` with zero surviving children disappears as an expression rather than emitting empty parentheses or a synthetic boolean constant. Its disappearance is then handled by the surrounding builder exactly like any other absent child.

### Declarative In supports builder and concise forms

The future declarative predicate node supports both a result-builder form and concise argument forms.

For multi-expression membership, the preferred compositional form is:

```swift
Where {
    In {
        Row {
            User.$country
            User.$city
        }

        Row {
            "NL"
            "Amsterdam"
        }

        Row {
            "DE"
            "Berlin"
        }
    }
}
```

which means:

```sql
WHERE ROW(
    "User"."country",
    "User"."city"
) IN (
    ROW('NL', 'Amsterdam'),
    ROW('DE', 'Berlin')
)
```

The first semantic child is the left-hand expression and the remaining children are the membership values. The concise form remains valid shorthand:

```swift
Where {
    In(
        Row {
            User.$country
            User.$city
        },
        Row {
            "NL"
            "Amsterdam"
        },
        Row {
            "DE"
            "Berlin"
        }
    )
}
```

and must produce the same SQL.

The same builder principle applies to scalar membership where the types are unambiguous:

```swift
Where {
    In {
        User.$role
        Role.admin
        Role.moderator
    }
}
```

means:

```sql
WHERE "User"."role" IN ('admin', 'moderator')
```

A dedicated shorthand such as `In(lhs, values)` remains useful for runtime collections and compact call sites. A builder with a structurally present left-hand expression but zero surviving right-hand membership children disappears as an expression rather than emitting `IN ()` or synthetic boolean SQL. The left-hand role must remain structural; dynamic control flow must not cause an unrelated later child to be reinterpreted as the left-hand side.

### Declarative In with an empty runtime collection disappears

The future declarative predicate node `In(lhs, collection)` has accepted empty-collection semantics inside predicate-builder contexts such as `Where`, `On`, `Having`, `Qualify`, `And`, and `Or`.

For a non-empty runtime collection:

```swift
let roles: [Role] = [.admin, .moderator]

Where {
    In(User.$role, roles)
}
```

means:

```sql
WHERE "User"."role" IN ('admin', 'moderator')
```

For an empty runtime collection:

```swift
let roles: [Role] = []

Where {
    In(User.$role, roles)
}
```

the `In` predicate contributes no child, exactly as if the caller had written:

```swift
Where {
    if !roles.isEmpty {
        In(User.$role, roles)
    }
}
```

and the SQL contains no predicate from that `In` expression. If it was the only child, the entire WHERE clause disappears:

```sql
-- no WHERE clause
```

This rule must **not** rewrite an empty list to `FALSE`, `TRUE`, `IN ()`, or any other synthetic SQL expression. It is result-builder omission semantics for the new declarative collection-form `In`, not a silent behavior change to the established raw/fluent `.in(...)` API.

Literal/variadic `In` forms should be non-empty by construction where practical. Subquery `In(lhs) { ... }` is a different grammar form and does not use collection-empty omission semantics.

The corresponding empty-collection behavior for future declarative `NotIn` remains a separate design decision unless explicitly accepted; do not infer it automatically from `In`.

### Existing predicate operators remain first-class

The declarative builder does not replace the established `SQLPredicate`, `&&`, or `||` APIs. Compact explicit boolean expressions remain valid:

```swift
Where {
    User.$age >= 18 && User.$isActive == true
}
```

means:

```sql
WHERE "User"."age" >= 18 AND "User"."isActive" = TRUE
```

and:

```swift
Where {
    User.$email == email || User.$phone == phone
}
```

means:

```sql
WHERE "User"."email" = 'john@example.com' OR "User"."phone" = '+123456789'
```

Use `And { ... }` / `Or { ... }` when explicit grouped structure, dynamic children, nested groups, or loops make the SQL clearer. Use existing operators when one compact expression is clearer.

### Implementation constraints for the future result builders

The eventual implementation must preserve these invariants:

- reuse the existing `SQLable` / parts / preparation / binding pipeline rather than creating a parallel query or predicate renderer;
- preserve exact predicate source order and bound-value order;
- make `Where`, `And`, and `Or` semantics independent of incidental result-builder implementation details;
- support runtime omission without inserting synthetic SQL truth values;
- preserve existing `&&` / `||` source compatibility and SQL behavior;
- make grouped boolean precedence explicit through owned parentheses;
- preserve composition invariance under helper functions, optional branches, loops, nested groups, and later incremental composition;
- keep the query-authoring result builders semantically separate from the intentionally static/non-empty Declarative DDL builders;
- require every future DSL design proposal and acceptance example to show the exact corresponding SQL, and prepared SQL/value order when bindings or dynamic composition are material to the decision.

## DESIGN-021 - Declarative aliases and explicit NULL predicates

The declarative query-authoring layer must preserve multiple natural SQL-shaped authoring forms when they express the same unambiguous grammar and lower to the same existing parts/preparation semantics.

### JOIN/source aliases support fluent, operator, and explicit continuation forms

For an aliasable JOIN source, all three of the following forms are accepted target UX and must produce the same SQL and identifier-safe alias semantics.

Fluent alias form:

```swift
Join(.left, Profile.table)
    .as("profile")

On {
    User.$id == Profile.$userId
}
```

Operator alias form:

```swift
Join(.left, Profile.table) => "profile"

On {
    User.$id == Profile.$userId
}
```

Explicit declarative continuation form:

```swift
Join(.left, Profile.table)

As("profile")

On {
    User.$id == Profile.$userId
}
```

All three target:

```sql
LEFT JOIN "Profile" AS "profile"
ON "User"."id" = "Profile"."userId"
```

The same equivalence applies when the JOIN owns a nested query source:

```swift
Join(.leftLateral) {
    Select {
        Post.$id
        Post.$createdAt
    }

    From {
        Post.table
    }

    Where {
        Post.$userId == User.$id
    }

    OrderBy(Post.$createdAt, .desc)
    Limit(1)
}
.as("latestPost")

On(true)
```

```swift
Join(.leftLateral) {
    Select {
        Post.$id
        Post.$createdAt    }
    From {
        Post.table
    }

    Where {
        Post.$userId == User.$id
    }

    OrderBy(Post.$createdAt, .desc)
    Limit(1)
} => "latestPost"

On(true)
```

```swift
Join(.leftLateral) {
    Select {
        Post.$id
        Post.$createdAt
    }

    From {
        Post.table
    }

    Where {
        Post.$userId == User.$id
    }

    OrderBy(Post.$createdAt, .desc)
    Limit(1)
}

As("latestPost")
On(true)
```

All three target:

```sql
LEFT JOIN LATERAL (
    SELECT
        "Post"."id",
        "Post"."createdAt"
    FROM "Post"
    WHERE "Post"."userId" = "User"."id"
    ORDER BY "Post"."createdAt" DESC
    LIMIT 1
) AS "latestPost"
ON TRUE
```

The existing `=>` alias operator is established SwifQL compatibility surface and already lowers aliases through identifier-oriented alias parts; the final major API must preserve that useful shorthand. The new `.as("alias")` form must be identifier-safe rather than routing the alias string through ordinary SQL value semantics. `As("alias")` is a declarative result-builder continuation, not raw token concatenation.

For result-builder mechanics, `As("alias")` must attach through typed/structural builder composition to the immediately open aliasable grammar owner. It must not scan previously emitted SQL tokens/parts, infer intent from arbitrary receiver history, or depend on mutable ambient "current alias target" state. If no valid aliasable owner is open, the builder should reject the form rather than guess.

### As is a general postfix declarative alias continuation

`As("alias")` is not JOIN-specific. It is the canonical explicit declarative spelling for postfix SQL aliasing wherever the active grammar item truthfully supports an alias after that item.

For SELECT result items:

```swift
Select {
    User.$id
    As("identifier")

    User.$email
    As("emailAddress")
}
```

means:

```sql
SELECT
    "User"."id" AS "identifier",
    "User"."email" AS "emailAddress"
```

The existing fluent and operator spellings remain equivalent:

```swift
Select {
    User.$id.as("identifier")
    User.$email => "emailAddress"
}
```

and produce the same SQL:

```sql
SELECT
    "User"."id" AS "identifier",
    "User"."email" AS "emailAddress"
```

For FROM items:

```swift
From {
    User.table
    As("u")
}
```

means:

```sql
FROM "User" AS "u"
```

For a reusable or nested query source:

```swift
From {
    UsersQuery(active: true, email: nil, roles: nil)
    As("activeUsers")
}
```

means:

```sql
FROM (
    SELECT ...
) AS "activeUsers"
```

For a JOIN source:

```swift
Join(.left, Profile.table)
As("profile")
On(User.$id == Profile.$userId)
```

means:

```sql
LEFT JOIN "Profile" AS "profile"
ON "User"."id" = "Profile"."userId"
```

When a dialect grammar exposes another postfix aliasable construct, `As` may apply there too. For example PostgreSQL allows an alias for the merged columns produced by `USING (...)`:

```swift
Join(.left, Profile.table)
Using(User.$id)
As("keys")
```

means in PostgreSQL:

```sql
LEFT JOIN "Profile"
USING ("id") AS "keys"
```

The builder must preserve the distinction between alias owners. In:

```swift
Join(.left, Profile.table)
As("profile")
Using(User.$id)
As("keys")
```

the first alias belongs to the JOIN source and the second alias belongs to the PostgreSQL `USING` result:

```sql
LEFT JOIN "Profile" AS "profile"
USING ("id") AS "keys"
```

Within list-producing result builders such as `Select { ... }` and `From { ... }`, an `As` continuation completes the immediately open item before comma/list materialization. The implementation must therefore group the expression/source plus its alias structurally rather than emit a comma between the item and `As`.

Dynamic control flow must preserve that ownership explicitly. This is valid:

```swift
Select {
    User.$id

    if includeEmail {
        User.$email
        As("emailAddress")
    }
}
```

When `includeEmail == true`:

```sql
SELECT
    "User"."id",
    "User"."email" AS "emailAddress"
```

When `includeEmail == false`:

```sql
SELECT "User"."id"
```

By contrast, a form that conditionally omits the aliasable item while leaving `As("emailAddress")` outside that branch must be rejected rather than attaching the alias to an unrelated earlier item.

This general rule applies only to true postfix alias grammar. It must not be generalized mechanically to every occurrence of the SQL keyword `AS`. Constructs where `AS` has different grammar ownership, such as named `WITH name AS (...)` items or type casts, keep their own dedicated SQL-shaped API.

### Explicit NULL predicate nodes coexist with operator and fluent sugar

The declarative predicate layer adds explicit SQL-shaped nodes:

```swift
IsNull(Profile.$deletedAt)
IsNotNull(Profile.$deletedAt)
```

They are exact semantic equivalents of the already-established operator sugar:

```swift
Profile.$deletedAt == nil
Profile.$deletedAt != nil
```

and of the existing fluent forms:

```swift
Profile.$deletedAt.isNull
Profile.$deletedAt.isNotNull
```

For example:

```swift
Where {
    IsNull(Profile.$deletedAt)
}
```

means:

```sql
WHERE "Profile"."deletedAt" IS NULL
```

and:

```swift
Where {
    IsNotNull(Profile.$deletedAt)
}
```

means:

```sql
WHERE "Profile"."deletedAt" IS NOT NULL
```

The explicit nodes are not a new NULL-semantics engine. They must reuse the same existing SQL predicate/operator parts and produce the same SQL/binding behavior as the established `== nil`, `!= nil`, `.isNull`, and `.isNotNull` surfaces.

These forms may be used inside any accepted predicate-builder context, including `Where`, `On`, `Having`, `Qualify`, `And`, and `Or`.

## DESIGN-022 - FROM item composition, dynamic column aliases, and WITH ORDINALITY

The future declarative `From { ... }` surface is a list of SQL FROM items, but nested statement clauses do not require an explicit inner `SQL { ... }` wrapper when they are authored directly inside that builder. The result-builder implementation must reuse the existing structural SQL-region/frame architecture rather than infer boundaries by scanning emitted SQL tokens.

### Direct nested statements inside From are first-class

This is accepted target UX:

```swift
From {
    Select {
        Order.$userId
        Fn.count(Order.$id)
        As("orderCount")
    }

    From {
        Order.table
    }

    GroupBy {
        Order.$userId
    }

    As("orderStats")

    Organization.table
}
```

and means:

```sql
FROM
    (
        SELECT
            "Order"."userId",
            count("Order"."id") AS "orderCount"
        FROM "Order"
        GROUP BY "Order"."userId"
    ) AS "orderStats",
    "Organization"
```

The direct nested-statement form must be implemented by extending/reusing the existing `SQLStructuralFramePart` statement/set-result boundary model and root-frame-aware structural continuation contract. Clause children that belong to the open nested statement continue that statement frame; a new FROM item begins a new item boundary. The implementation must use typed/structural result-builder composition and must not rediscover statement ownership from previously rendered tokens, textual SQL, or ambient mutable "current subquery" state.

An explicit nested root remains fully supported:

```swift
From {
    SQL {
        Select {
            Order.$userId
        }

        From {
            Order.table
        }
    }

    As("orderStats")
}
```

and targets:

```sql
FROM (
    SELECT "Order"."userId"
    FROM "Order"
) AS "orderStats"
```

The explicit `SQL { ... }` form is therefore an optional explicit statement value/boundary, not a mandatory wrapper imposed by `From`.

Reusable `SQLQuery` values remain already-formed statement values and likewise require no extra `SQL { ... }` wrapper.

### Columns supports concise and result-builder forms

Where SQL grammar permits an alias column-name list, the declarative continuation supports both concise and closure forms.

Concise:

```swift
Values {
    Row(.admin, 100)
    Row(.moderator, 50)
}

As("rolePriority")
Columns("role", "priority")
```

Builder form:

```swift
Values {
    Row(.admin, 100)
    Row(.moderator, 50)
}

As("rolePriority")
Columns {
    "role"

    if priorityEnabled {
        "priority"
    }
}
```

When `priorityEnabled == true`, PostgreSQL/Duck-style SQL is:

```sql
(
    VALUES
        ('admin', 100),
        ('moderator', 50)
) AS "rolePriority" ("role", "priority")
```

When `priorityEnabled == false`:

```sql
(
    VALUES
        ('admin', 100),
        ('moderator', 50)
) AS "rolePriority" ("role")
```

String children of `Columns { ... }` are identifier names, never SQL string values. The builder may also accept other existing structural-name values where the grammar truthfully needs a column name.

If all dynamic children of an optional alias-column list disappear, the entire `Columns { ... }` continuation disappears rather than emitting empty parentheses:

```swift
From {
    User.table
    As("u")

    Columns {
        if includeLegacyAliases {
            "id"
        }
    }
}
```

with `includeLegacyAliases == false` means:

```sql
FROM "User" AS "u"
```

This empty-list omission rule applies only where the SQL column-alias list itself is optional. A required record-definition list is a different grammar construct and must not silently disappear.

### WITH ORDINALITY is one atomic SQL modifier

For table functions and `ROWS FROM`, the target spelling is:

```swift
From {
    Fn.generateSeries(10, 12)
    WithOrdinality()
    As("series")
    Columns("value", "position")
}
```

which means:

```sql
FROM generate_series(10, 12)
WITH ORDINALITY
AS "series" ("value", "position")
```

The DSL does **not** split this into generic sibling tokens such as:

```swift
With()
Ordinality()
```

because SQL `WITH` is not one universal composable prefix. It introduces many unrelated grammar constructs across SQL/PostgreSQL, including statement-head `WITH [RECURSIVE]` CTEs, `WITH ORDINALITY` on table functions, `WITH TIES` inside FETCH, cursor `WITH HOLD`, `WITH [NO] DATA`, `WITH CHECK OPTION`, storage-parameter `WITH (...)`, and other construct-specific forms. Those concepts keep their own SQL-shaped APIs.

The public API should therefore prefer semantic compound constructs where the SQL grammar itself defines an atomic phrase. `WithOrdinality()` is analogous to `GroupBy`, `OrderBy`, `DistinctOn`, or `IsNotNull`: it preserves the literal SQL phrase without exposing a meaningless standalone `With()` token.

This rule does not imply creating a `WithFoo` symbol for every occurrence of the keyword `WITH`. Other grammar owners should choose their most natural local API, for example CTE `With { ... }` / `With(.recursive) { ... }` and FETCH options that express `WITH TIES` inside the FETCH construct.

### TABLESAMPLE owns its source item

The canonical declarative TABLESAMPLE spelling is source-owning:

```swift
From {
    TableSample(User.table) {
        System(10)
        Repeatable(42)
    }
}
```

For PostgreSQL this targets:

```sql
FROM "User"
TABLESAMPLE SYSTEM (10)
REPEATABLE (42)
```

For DuckDB the same semantic sampling request may render dialect-specific unit syntax, for example:

```sql
FROM "User"
TABLESAMPLE SYSTEM (10 PERCENT)
REPEATABLE (42)
```

The source-owning `TableSample(User.table) { ... }` form is preferred over a sibling suffix that relies on whichever FROM item happened to appear previously. A concise argument-form shorthand may coexist with the builder form.

The implementation must preserve the existing open semantic sampling model (`SampleMethod`, ordered arguments/roles, repeatability, dialect-owned rendering) rather than close TABLESAMPLE to only built-in methods.

### Outer sibling JOIN after FROM

In one outer `@SQLBuilder` statement, a completed `From { ... }` with a statically guaranteed final source may be followed by sibling `Join(...)` and its existing legal `As`/`On`/`Using` continuations. These expressions extend the same FROM clause and must have the same SQL and binding order as the equivalent JOIN inside the `From` body. Another sibling JOIN continues the immediately current final source chain. A later independent outer clause or neutral fragment finalizes the FROM current; JOIN cannot attach across that boundary. This outer rule is additional to, and does not alter, direct nested statement items inside `From`. Loop-only and optional-only FROM bodies without a static source guarantee remain valid completed clauses but cannot own a sibling JOIN. Statically empty `From { }`, JOIN-continuation-only roots, and faithful nested `From`-then-`Select` N17 remain rejected. The outer N17b `From`-then-`Select` observation remains compile-positive without endorsing that SQL order.

### Guaranteed `From` carrier ingress (narrow ranking exception)

An unannotated `From { ... }` body with a statically guaranteed final source must infer a distinct guaranteed carrier (`FromBuilder.GuaranteedResult`) so sibling JOIN ownership can survive the expression. The legacy `From` overload returning `FromBuilder.Result` stays signature-identical and is annotated `@_disfavoredOverload` only so the guaranteed overload can rank first for those bodies. Explicit `FromBuilder.Result` annotations and helper return types still select the legacy overload and carry no sibling-JOIN ownership proof. No-guarantee loop/optional bodies remain legacy results under S10/D2/D3/D4. The defaulted compatibility argument belongs only on the new overload. This is the sole underscored ranking exception; toolchain ranking changes reopen ingress and must not silently switch to a legacy-signature mutation or a differently named `From` entry. Erasure to plain `SwifQLable` removes the proof. Task 00 R1 re-probe phase 2 is the feasibility evidence for this ingress shape; production still requires the normal implementation workflow.

## DESIGN-023 - VALUES rows, alias columns, and owner-sensitive DEFAULT

The declarative VALUES surface is a first-class query-result construct, not merely a FROM helper.

### Values owns semantic rows

Primary result-builder form:

```swift
Values {
    Row("admin", 100)
    Row("moderator", 50)
}
```

For PostgreSQL and DuckDB this means:

```sql
VALUES
    ('admin', 100),
    ('moderator', 50)
```

For MySQL standalone/table-constructor grammar the same semantic rows render with the dialect-required `ROW(...)` keyword:

```sql
VALUES
    ROW('admin', 100),
    ROW('moderator', 50)
```

The public `Row` node is therefore semantic. It must not hard-code whether the target dialect prints a literal `ROW` keyword.

For multiple row fields, the preferred compositional spelling is the result-builder form:

```swift
Row {
    User.$country
    User.$city
}
```

The concise argument form remains available as shorthand:

```swift
Row(User.$country, User.$city)
```

These two spellings must describe the same semantic row and lower identically for the same grammar owner/dialect.

Inside VALUES, the same preferred row-builder form applies:

```swift
Values {
    Row {
        "admin"
        100
    }

    Row {
        "moderator"
        50
    }
}
```

while the concise form remains valid:

```swift
Values {
    Row("admin", 100)
    Row("moderator", 50)
}
```

A concise `Values(Row(...), Row(...))` form may also coexist as shorthand.

`Row { ... }` supports ordinary result-builder control flow in field positions:

```swift
Values {
    for role in roles {
        Row {
            role.name

            if priorityEnabled {
                role.priority
            }
        }
    }
}
```

After Swift control flow resolves, every surviving VALUES row must have the same non-zero arity. Mismatched or zero-column rows are invalid rather than being padded, truncated, or rewritten.

A `Values { ... }` body that produces zero rows is invalid. VALUES itself must not disappear or synthesize an empty relation. If the caller wants an optional VALUES source, the entire VALUES construct belongs inside ordinary Swift control flow at its enclosing grammar owner.

### VALUES in FROM uses normal alias and Columns continuations

```swift
From {
    Values {
        Row("admin", 100)
        Row("moderator", 50)
    }

    As("rolePriority")

    Columns {
        "role"
        "priority"
    }
}
```

targets PostgreSQL/Duck-style SQL:

```sql
FROM (
    VALUES
        ('admin', 100),
        ('moderator', 50)
) AS "rolePriority" ("role", "priority")
```

and dialect-specific MySQL row-constructor rendering under the same public API.

Alias requirements are owner/dialect grammar, not intrinsic VALUES rendering. Standalone VALUES does not require an alias; a VALUES-derived table in a dialect that requires a derived-table alias must be validated accordingly.

`Columns { ... }` follows DESIGN-022 and remains dynamic. PostgreSQL permits partial column alias lists, while dialects that require alias-list arity to equal source arity may validate that separately. Do not reduce the public PostgreSQL capability to the lowest common denominator.

### Column aliases and typed record definitions remain distinct concepts

A plain alias column list:

```sql
AS "x" ("id", "name")
```

is represented by `Columns { ... }`.

A PostgreSQL record-returning function definition:

```sql
AS "x" ("id" INTEGER, "name" TEXT)
```

is a different grammar concept because it supplies output names **and types**. It requires a dedicated typed definition builder/API rather than mixing typed entries into ordinary `Columns { ... }`. Exact public naming for that typed record-definition surface remains open.

### DEFAULT is owner-sensitive

A future explicit `Default()` value is valid where the owning SQL grammar permits DEFAULT, notably INSERT VALUES:

```swift
Insert(User.table) {
    Columns {
        User.$id
        User.$name
        User.$createdAt
    }

    Values {
        Row(1, "John", Default())
        Row(2, "Kate", Default())
    }
}
```

targeting:

```sql
INSERT INTO "User" (
    "id",
    "name",
    "createdAt"
)
VALUES
    (1, 'John', DEFAULT),
    (2, 'Kate', DEFAULT)
```

`Default()` is not a generic value expression for standalone VALUES/SELECT contexts. Its validity must come from the structural owner rather than from raw token concatenation.

### VALUES participates in query-result/set composition

VALUES may form a standalone statement/query result and participate in set operations through the same structural statement/set-result architecture:

```swift
SQL {
    Values {
        Row(1, "one")
        Row(2, "two")
    }

    Union {
        Select {
            Number.$id
            Number.$name
        }

        From {
            Number.table
        }
    }
}
```

The result-builder layer must reuse the existing statement/set-result frame model rather than treat VALUES as an unrelated mini-language.

### Row is one semantic construct across VALUES and expression grammar

Both `Row { ... }` and `Row(...)` are accepted public UX for one semantic row abstraction, with the closure form preferred for multi-field compositional authoring and the argument form retained as shorthand.

The same semantic Row is also the canonical general SQL row-constructor expression used in row comparisons, multi-column membership, and other expression grammar. The owning grammar region plus target dialect decides exact token spelling where SQL dialects differ.

For example:

```swift
Where {
    Row {
        User.$country
        User.$city
    } == Row {
        "NL"
        "Amsterdam"
    }
}
```

targets PostgreSQL-style row comparison:

```sql
WHERE ROW(
    "User"."country",
    "User"."city"
) = ROW(
    'NL',
    'Amsterdam'
)
```

while the same semantic Row inside PostgreSQL/DuckDB VALUES may render as a bare parenthesized VALUES row and inside MySQL standalone/table-constructor VALUES may render with the dialect-required `ROW(...)` keyword. Public API should not expose separate user-facing row concepts merely to mirror those rendering differences.

## DESIGN-024 - Declarative expression grammar and structural expression continuations

The new-major declarative query DSL extends the existing parts/preparation engine with SQL-shaped semantic expression nodes and typed structural continuations. It does not introduce a second expression AST or renderer.

Existing fluent/operator APIs remain first-class compatibility and concise authoring surfaces where they already exist.

### CASE supports searched and simple forms

Searched CASE:

```swift
Case {
    When(User.$age < 18) {
        "minor"
    }

    When(User.$age < 65) {
        "adult"
    }

    Else {
        "senior"
    }
}
```

targets:

```sql
CASE
    WHEN "User"."age" < 18 THEN 'minor'
    WHEN "User"."age" < 65 THEN 'adult'
    ELSE 'senior'
END
```

Simple CASE:

```swift
Case(User.$status) {
    When(Status.active) {
        "enabled"
    }

    When(Status.pending) {
        "waiting"
    }

    Else {
        "disabled"
    }
}
```

targets:

```sql
CASE "User"."status"
    WHEN 'active' THEN 'enabled'
    WHEN 'pending' THEN 'waiting'
    ELSE 'disabled'
END
```

A concise `When(condition, result)` / `Else(result)` shorthand may coexist with closure forms. `Else` is optional because SQL permits its absence. An empty CASE body is invalid.

### Conditional-value expressions get explicit SQL-shaped nodes

Canonical examples:

```swift
Coalesce {
    User.$displayName
    User.$email
    "Anonymous"
}

NullIf(User.$displayName, "")

Greatest {
    User.$score
    User.$bonus
    0
}

Least(User.$limit, maximum)
```

target their literal SQL constructs:

```sql
COALESCE("User"."displayName", "User"."email", 'Anonymous')
NULLIF("User"."displayName", '')
GREATEST("User"."score", "User"."bonus", 0)
LEAST("User"."limit", $1)
```

Existing `Fn.coalesce(...)` remains available. The declarative nodes do not normalize dialect-specific NULL behavior.

### BETWEEN owns both bounds

Preferred declarative predicates:

```swift
Between(User.$age, 18, 65)
NotBetween(User.$age, 18, 65)
```

target:

```sql
"User"."age" BETWEEN 18 AND 65
"User"."age" NOT BETWEEN 18 AND 65
```

PostgreSQL-style symmetric semantics use a typed modifier rather than multiplying symbol names:

```swift
Between(User.$score, .symmetric, minimum, maximum)
NotBetween(User.$score, .symmetric, minimum, maximum)
```

target:

```sql
"User"."score" BETWEEN SYMMETRIC $1 AND $2
"User"."score" NOT BETWEEN SYMMETRIC $1 AND $2
```

### Pattern predicates have explicit nodes alongside fluent sugar

Declarative nodes:

```swift
Like(User.$name, "John%")
NotLike(User.$name, "%test%")
ILike(User.$email, "john%")
NotILike(User.$email, "%spam%")
SimilarTo(User.$code, "(A|B)%")
```

map directly to literal SQL operators. Existing `.like`, `.iLike`, `.notLike`, `.notILike`, `.similarTo`, and related fluent APIs remain valid.

Pattern escape belongs to the predicate itself, for example:

```swift
Like(User.$code, #"ABC\_%"#, escape: "\\")
```

rather than becoming a free sibling continuation.

Do not emulate unsupported dialect constructs through hidden expression rewrites merely for portability; for example, do not silently translate `ILIKE` into `LOWER(lhs) LIKE LOWER(rhs)`.

### NULL-safe distinctness predicates are explicit

```swift
IsDistinctFrom(User.$email, inputEmail)
IsNotDistinctFrom(User.$email, inputEmail)
```

target dialects with literal support as:

```sql
"User"."email" IS DISTINCT FROM $1
"User"."email" IS NOT DISTINCT FROM $1
```

Any cross-dialect semantic mapping to a different native operator, such as MySQL null-safe equality, requires separate evidence and must not be assumed merely from superficial similarity.

### Scalar nested SQL uses ordinary structural SQL values

Do not introduce a mandatory `ScalarSubquery` / `Subquery` wrapper when expression grammar already owns a nested query operand.

For example:

```swift
Where {
    User.$salary > SQL {
        Select {
            Fn.avg(Employee.$salary)
        }

        From {
            Employee.table
        }
    }
}
```

targets:

```sql
WHERE "User"."salary" > (
    SELECT avg("Employee"."salary")
    FROM "Employee"
)
```

The same rule applies to reusable `SQLQuery` values. The expression owner supplies required parentheses around the structural statement value.

### Row-builder and concise Row forms are equivalent

Preferred multi-field form:

```swift
Row {
    User.$country
    User.$city
}
```

shorthand:

```swift
Row(User.$country, User.$city)
```

Both represent the same semantic row across VALUES and expression grammar.

Multi-column membership likewise supports both builder and concise In forms. Preferred compositional form:

```swift
In {
    Row {
        User.$country
        User.$city
    }

    Row {
        "NL"
        "Amsterdam"
    }

    Row {
        "DE"
        "Berlin"
    }
}
```

shorthand:

```swift
In(
    Row {
        User.$country
        User.$city
    },
    Row {
        "NL"
        "Amsterdam"
    },
    Row {
        "DE"
        "Berlin"
    }
)
```

Both target:

```sql
ROW("User"."country", "User"."city") IN (
    ROW('NL', 'Amsterdam'),
    ROW('DE', 'Berlin')
)
```
### CAST has a direct declarative node
```swift
Cast(User.$age, .text)
```

targets standard SQL:

```sql
CAST("User"."age" AS TEXT)
```

Existing `Fn.cast` and dialect-specific/raw cast conveniences remain compatibility surfaces. The canonical declarative node should prefer standard `CAST(... AS ...)` unless an owning dialect feature specifically requires another form.

### FILTER is a predicate-builder continuation

Inside a result-builder expression item:

```swift
Select {
    Fn.count(Order.$id)

    Filter {
        Order.$status == Status.paid
        IsNull(Order.$deletedAt)
    }

    As("paidOrders")
}
```

targets:

```sql
SELECT
    count("Order"."id")
    FILTER (
        WHERE "Order"."status" = 'paid'
          AND "Order"."deletedAt" IS NULL
    ) AS "paidOrders"
```

`Filter { ... }` reuses the accepted predicate-builder semantics from `Where`, `On`, `Having`, and `Qualify`: direct surviving children combine with AND in source order, while explicit `And` / `Or` own their parentheses.

Do not copy historical comma-separated multi-predicate behavior blindly. The SQL FILTER construct owns one boolean expression.

### OVER supports structural continuation and inline expression forms

When authoring one result-builder expression item, SQL-order continuation is preferred:

```swift
Select {
    Fn.rowNumber()

    Over {
        PartitionBy(User.$organizationId)
        OrderBy(User.$createdAt, .desc)
    }

    As("position")
}
```

targeting:

```sql
SELECT
    row_number()
    OVER (
        PARTITION BY "User"."organizationId"
        ORDER BY "User"."createdAt" DESC
    ) AS "position"
```

When a complete windowed expression is needed inline as an operand, constructor style remains available:

```swift
Qualify {
    Over(Fn.rowNumber()) {
        PartitionBy(User.$organizationId)
        OrderBy(User.$createdAt, .desc)
    } <= 3
}
```

targeting:

```sql
QUALIFY
    row_number() OVER (
        PARTITION BY "User"."organizationId"
        ORDER BY "User"."createdAt" DESC
    ) <= 3
```

Existing fluent `.over(...) / .over { ... }` APIs may remain available. The declarative grammar does not require one spelling to replace all contexts.

### WITHIN GROUP is a structural aggregate continuation

```swift
Select {
    Fn.percentileCont(0.5)

    WithinGroup {
        OrderBy(Income.$amount, .asc)
    }

    As("median")
}
```

targets:

```sql
SELECT
    percentile_cont(0.5)
    WITHIN GROUP (
        ORDER BY "Income"."amount" ASC
    ) AS "median"
```

Aggregate continuations may compose in SQL grammar order, for example an ordered-set aggregate followed by `Filter { ... }`, or an aggregate followed by `Filter { ... }` and then `Over { ... }`, provided the owning dialect grammar permits that combination.

### Quantified comparisons are accepted conceptually; UpperCamel Any is rejected by compiler evidence

The DSL must support SQL quantified comparisons such as:

```sql
value = ANY (...)
value > ALL (...)
value = SOME (...)
```

with nested-query and dialect-appropriate collection/array operands.

The focused downstream Swift compiler matrix resolved the original `QUERY-RB-015` question negatively across Xcode Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Xcode Swift 6.4:

- an unescaped declaration named `Any` is rejected because `Any` is a Swift keyword;
- an escaped imported declaration can exist, but bare `Any(...)` / `Any { ... }` still resolves as attempted existential construction and fails;
- qualification/backticks can force the imported declaration but are rejected as DSL spelling smell;
- `All(...)` and `Some(...)` are individually clean, but mixing them with a uniquely renamed ANY would make one SQL quantifier family inconsistent.

Therefore bare UpperCamel `Any` is not a candidate for the final public API. Subsequent compiler work also rejects bare `Any.sql(...)`. DESIGN-026 owns the maintainer-selected exception: exact-uppercase `ANY` for this one fundamental Swift collision, while non-conflicting `All` and `Some` retain normal SQL UpperCamel casing.

### Next expression-design frontier

Expression Frontier 01 is complete under DESIGN-025 and DESIGN-026. The next focused design pass owns JSON/JSONB operators and SQL/JSON paths, PostgreSQL ranges/multiranges, COLLATE, AT TIME ZONE, and remaining dialect/operator families. QUERY-RB-019 remains only an implementation/extensibility decision for the eventual generic custom-aggregate builder entry point and does not block the next expression frontier.

## DESIGN-025 - Aggregate argument grammar is structurally owned by the aggregate call

The declarative expression layer models aggregate-internal argument grammar inside the aggregate function call itself. It does not flatten aggregate `DISTINCT`, aggregate-local `ORDER BY`, query-level `DISTINCT`, PostgreSQL `DISTINCT ON`, `WITHIN GROUP`, `FILTER`, and `OVER` into one interchangeable modifier stream.

This section accepts the user-facing grammar and ownership rules. Production implementation remains a later researched/audited wave.

### Existing aggregate helpers remain the primary SQL identity

Do not require ordinary built-in aggregate calls to be wrapped in a generic `Aggregate(...)` object merely to access advanced grammar. An aggregate helper may gain an additive result-builder overload while its established concise form remains first-class.

Preferred compositional form:

```swift
Fn.arrayAgg {
    Order.$id

    OrderBy(Order.$createdAt, .desc)
}
```

targets PostgreSQL/Duck grammar:

```sql
array_agg(
    "Order"."id"
    ORDER BY "Order"."createdAt" DESC
)
```

The concise existing form remains valid shorthand:

```swift
Fn.arrayAgg(Order.$id)
```

```sql
array_agg("Order"."id")
```

Direct expression children before an aggregate-local `OrderBy` are ordinary aggregate arguments and materialize with commas in source order. `OrderBy` is a distinct typed child role owned by the aggregate body, so no comma precedes it.

For a multiple-argument aggregate:

```swift
Fn.stringAgg {
    Order.$label
    separator

    OrderBy(Order.$createdAt, .asc)
}
```

targets, where that exact aggregate grammar is supported:

```sql
string_agg(
    "Order"."label",
    $1
    ORDER BY "Order"."createdAt" ASC
)
```

with `separator` as the first bound value. If later aggregate arguments or ordering expressions contain bound values, the ordinary one-pass preparation traversal preserves their left-to-right structural order after that value.

This is aggregate-body grammar, not query-level `ORDER BY` ownership. Reuse the existing ordering-item vocabulary where truthful, but do not route aggregate ordering through the statement/root-frame `SQLOrderByPart` owner merely because both spell SQL `ORDER BY`.

### Aggregate DISTINCT owns the regular argument list

Inside an aggregate body, plain SQL `DISTINCT` applies to the aggregate's regular argument list:

```swift
Fn.arrayAgg {
    Distinct(Order.$productId)

    OrderBy(Order.$productId, .desc)
}
```

targets:

```sql
array_agg(
    DISTINCT "Order"."productId"
    ORDER BY "Order"."productId" DESC
)
```

Where an exact aggregate genuinely accepts multiple regular arguments, the compositional spelling may use the same builder-first rule:

```swift
SomeMultiArgumentAggregate {
    Distinct {
        firstExpression
        secondExpression
    }
}
```

with concise shorthand:

```swift
SomeMultiArgumentAggregate {
    Distinct(firstExpression, secondExpression)
}
```

both targeting the exact grammar:

```sql
some_multi_argument_aggregate(
    DISTINCT first_expression,
    second_expression
)
```

The aggregate helper's own SQL signature remains authoritative: the builder does not make an aggregate accept an arity or argument combination that the database function does not support.

The established public `Distinct` spelling is compatibility surface, including PostgreSQL `Distinct(on:)`. The future aggregate builder must distinguish the plain DISTINCT semantic form structurally and reject `DISTINCT ON` in aggregate-argument ownership without inspecting already-rendered tokens. This does not resolve or alter the separate SELECT-modifier decision in `QUERY-RB-001`.

An aggregate body does not mix ordinary regular arguments with a sibling plain `Distinct` argument owner. Dynamic Swift control flow may choose the complete regular-argument branch:

```swift
Fn.arrayAgg {
    if deduplicate {
        Distinct(Order.$id)
    } else {
        Order.$id
    }

    OrderBy(Order.$id, .desc)
}
```

When `deduplicate == true`:

```sql
array_agg(
    DISTINCT "Order"."id"
    ORDER BY "Order"."id" DESC
)
```

When false:

```sql
array_agg(
    "Order"."id"
    ORDER BY "Order"."id" DESC
)
```

An empty surviving `Distinct { ... }` is invalid; it must not silently fall back to the default non-distinct aggregate semantics.

For PostgreSQL, an aggregate that combines DISTINCT with aggregate-local ORDER BY additionally requires the ORDER BY expressions to come from the DISTINCT argument list. The public DSL must preserve that exact SQL rule but must not introduce rendered-expression equality checks or token/string analysis merely to simulate database semantic validation.

### Explicit aggregate ALL is not conflated with quantified ALL

PostgreSQL aggregate grammar permits `ALL` before the regular argument list, but it is the default aggregate behavior. The declarative first slice therefore treats ordinary direct arguments as the default non-distinct/ALL case and does not reuse quantified-comparison `All(...)`, whose SQL ownership and parentheses are different.

Existing raw/fluent composition remains available for callers who explicitly need literal aggregate `ALL`. A future typed explicit-ALL convenience requires its own demonstrated UX value; it must not overload the quantified-comparison node merely for keyword symmetry.

### Star-form aggregates remain literal star grammar

`count(*)` is an aggregate-star grammar form, not a synthetic zero-value argument and not `count(1)`.

Current SQL can spell the exact star argument through the established star composition surface:

```swift
Fn.count(SQL.asterisk)
```

```sql
count(*)
```

Do not introduce a semantic `CountAll` replacement. The existing zero-argument `Fn.count()` all-row mismatch across built-in dialects is separate verified technical debt; fixing that compatibility surface is not part of declarative aggregate design.

### WITHIN GROUP remains a different aggregate grammar

Aggregate-local ORDER BY for a general-purpose aggregate:

```swift
Fn.arrayAgg {
    Order.$id
    OrderBy(Order.$createdAt, .desc)
}
```

```sql
array_agg(
    "Order"."id"
    ORDER BY "Order"."createdAt" DESC
)
```

is distinct from an ordered-set aggregate:

```swift
Fn.percentileCont(0.5)

WithinGroup {
    OrderBy(Income.$amount, .asc)
}
```

```sql
percentile_cont(0.5)
WITHIN GROUP (
    ORDER BY "Income"."amount" ASC
)
```

In `WITHIN GROUP` grammar, expressions before the continuation are direct arguments evaluated once per aggregate call, while the ORDER BY expressions are the aggregated inputs. Hypothetical-set PostgreSQL aggregates use the same ownership:

```swift
Fn.rank(inputScore)

WithinGroup {
    OrderBy(Score.$value, .asc)
}
```

```sql
rank($1)
WITHIN GROUP (
    ORDER BY "Score"."value" ASC
)
```

with `inputScore` as bound value `$1`.

The builder must not turn `WITHIN GROUP` into aggregate-local argument `OrderBy` or vice versa merely because both contain SQL ordering syntax.

### FILTER, OVER, and AS remain postfix expression owners

After the aggregate call is structurally complete, accepted expression continuations retain their SQL ownership:

```swift
Fn.sum(Order.$total)

Filter {
    Order.$status == Status.paid
}

Over {
    PartitionBy(Order.$userId)
}

As("paidTotal")
```

targets a dialect supporting that composition as:

```sql
sum("Order"."total")
FILTER (
    WHERE "Order"."status" = 'paid'
)
OVER (
    PARTITION BY "Order"."userId"
)
AS "paidTotal"
```

`Filter { ... }` continues to own one boolean expression using DESIGN-024 predicate-builder semantics. It must not inherit the historical fluent multi-predicate comma-list defect.

Do not infer from this structural ordering that every aggregate-modifier combination is supported by every dialect. PostgreSQL permits general aggregate functions as window functions but does not permit aggregate-argument DISTINCT or aggregate-argument ORDER BY in that window-call form, and ordered-set/hypothetical-set aggregates are not window functions there. DuckDB supports DISTINCT and argument ORDER BY for aggregate window functions. MySQL aggregate-internal DISTINCT/ORDER BY capabilities are function-specific, for example `GROUP_CONCAT`, rather than one universal aggregate grammar.

The DSL preserves the literal SQL construct and lets the selected database's real capability boundary remain visible; it must not rewrite one unsupported aggregate form into a different function or clause to simulate portability.

### Implementation and extension constraints

The eventual aggregate builder must:

- lower into ordinary `SQLable` / `SQLPart` composition and the existing one-pass preparation/binding pipeline;
- represent regular arguments, plain DISTINCT ownership, aggregate-local ordering, and star grammar structurally enough that punctuation/ownership never depends on previous-token scanning;
- preserve source-order binding through regular/direct arguments, aggregate-local ordering expressions, FILTER predicates, and later expression continuations;
- keep query-level SELECT DISTINCT / DISTINCT ON ownership separate from aggregate DISTINCT;
- preserve every established concise `Fn.*`, `Distinct`, `.filter`, and `.over` compatibility surface unless a separately approved defect correction changes one;
- provide a narrow downstream/custom aggregate extension path without forcing built-in aggregate calls through a generic wrapper. Exact spelling of that generic extension entry remains `QUERY-RB-019`;
- validate support per exact aggregate/dialect rather than treating the existence of the builder grammar as a support claim for every function or database.

## DESIGN-026 - ARRAY constructors and quantified comparisons keep exact SQL identity

Expression Frontier 01 closes the public semantic design for SQL ARRAY construction, collection subscripts/slices, and quantified comparisons. The accepted API deliberately follows exact SQL grammar instead of inventing a portable collection abstraction.

Production implementation remains a later planned/audited wave. All constructs must lower into the existing parts/preparation/binding and structural-frame architecture rather than creating a second expression AST or renderer.

### Overlapping Swift nominal types become grammar-role namespaces

When an SQL concept collides with an existing normal Swift nominal type, do not shadow that type and do not fall back to a generic `.sql` escape if the SQL grammar has meaningful distinct forms. Preserve the real Swift type as a namespace and name each member for the grammar role it constructs.

For SQL ARRAY, the maintainer-selected target is:

```swift
Array.items {
    1
    2
    User.$score
}
```

targeting PostgreSQL:

```sql
ARRAY[1, 2, "User"."score"]
```

with concise form:

```swift
Array.items(1, 2, User.$score)
```

The separate ARRAY(subquery) grammar uses a separate role member:

```swift
Array.subquery {
    Select { Order.$id }
    From { Order.table }
}
```

rather than a labeled closure such as `Array.sql(subquery: { ... })`.

This follows the general result-builder UX rule: when a closure is the primary semantic body, prefer a direct trailing closure. If a label exists only to distinguish grammar branches, move that distinction into the function/member name rather than producing `Something(label: { ... })` with stacked parentheses.

Final cross-toolchain compiler evidence proves the required mechanism and exact spelling: a constrained extension of the real standard-library `Array`, `extension Array where Element == Never`, exposes standalone-safe `Array.items(...)` / `Array.items { ... }` and `Array.subquery(...)` / `Array.subquery { ... }` without disturbing ordinary `Array<Int>`, `Array(repeating:count:)`, sequence construction, inferred literals, or qualified `Swift.Array` source. All four forms coexist cleanly in one imported client across Swift 6.2.3, Xcode/Swiftly 6.3.3, and Swift 6.4. An unconstrained extension remains unsuitable because `Element` cannot be inferred.

Free SQL-constructor `Array(...)`, bare `Array { ... }`, `Array(elements: { ... })`, and generic `Array.sql...` forms are non-canonical under this rule.

### Dynamic ARRAY elements preserve source and bind order

```swift
Array.items {
    first

    if let middle {
        middle
    }

    for value in tail {
        value
    }
}
```

For runtime values `10`, `20`, `30`, `40`, PostgreSQL preparation must preserve:

```sql
ARRAY[$1, $2, $3, $4]
```

with bound values:

```text
[10, 20, 30, 40]
```

Control flow controls child presence only. It does not synthesize NULLs or any other replacement element.

### Empty ARRAY is still an ARRAY value

An element builder with no surviving children renders an empty constructor:

```swift
Array.items {}
```

```sql
ARRAY[]
```

It does not disappear. PostgreSQL requires type context for an untyped empty ARRAY, so typing remains ordinary composition:

```swift
Cast(
    Array.items {},
    .integerArray
)
```

```sql
CAST(ARRAY[] AS INTEGER[])
```

The ARRAY node must not infer a type from unrelated query context or inject a synthetic element.

### Multidimensional ARRAY keeps nested semantic constructors

Preferred compositional form:

```swift
Array.items {
    Array.items {
        1
        2
    }

    Array.items {
        3
        4
    }
}
```

Concise shorthand:

```swift
Array.items(
    Array.items(1, 2),
    Array.items(3, 4)
)
```

Both preserve the explicit semantic nesting:

```sql
ARRAY[
    ARRAY[1, 2],
    ARRAY[3, 4]
]
```

Do not erase inner ARRAY constructors merely because PostgreSQL also accepts shorter multidimensional syntax. Rectangularity/common-element-type validation remains database semantics; the DSL must not pad, truncate, or reinterpret children.

### ARRAY(subquery) is a distinct structural overload

Builder-first nested-statement form:

```swift
Array.subquery {
    Select {
        Order.$id
    }

    From {
        Order.table
    }

    Where {
        Order.$userId == User.$id
    }
}
```

targets:

```sql
ARRAY(
    SELECT "Order"."id"
    FROM "Order"
    WHERE "Order"."userId" = "User"."id"
)
```

An already-formed `SQLContent` / `SQLQuery` value uses:

```swift
Array.subquery(orderIds)
```

No mandatory `Subquery(...)` wrapper is introduced. Separate grammar-role members keep `ARRAY[...]` and `ARRAY(subquery)` ownership unambiguous without labeled builder closures or rendered-token inspection.

PostgreSQL and DuckDB both accept exact `ARRAY(subquery)` grammar. DuckDB v1.5.5 returns a LIST for this form. That shared spelling does not authorize PostgreSQL `ARRAY[...]` element construction to render as Duck LIST literal syntax or `array_value(...)`.

### ARRAY/LIST indexing reuses the established subscript surface

Single-element lookup remains:

```swift
User.$scores[2]
```

targeting PostgreSQL/Duck collection syntax:

```sql
"User"."scores"[2]
```

The verified PostgreSQL requirement to parenthesize general expression bases, for example `(array_agg(...))[1]`, remains separate TECH_DEBT and must be corrected structurally rather than worked around by the declarative ARRAY API.

### Slice is a lowercase structural subscript operand

Do not introduce a public type named `Slice` or `ArraySlice`. The SQL concept is a slice specifier inside `[...]`, so the accepted structural operand is lowercase `slice`:

```swift
User.$scores[slice(2, 4)]
User.$scores[slice(through: 4)]
User.$scores[slice(from: 2)]
User.$scores[slice()]
```

targeting PostgreSQL and the shared two-bound Duck syntax:

```sql
"User"."scores"[2:4]
"User"."scores"[:4]
"User"."scores"[2:]
"User"."scores"[:]
```

Bounds are ordinary SQL expressions and preserve normal left-to-right bind order.

DuckDB additionally supports a third step component and negative indexes/bounds. The exact Duck-capable extension is:

```swift
items[slice(2, 8, step: 2)]
```

```sql
items[2:8:2]
```

This overload is a real dialect capability difference: PostgreSQL does not gain hidden step support, and the renderer must not translate a stepped slice into a different PostgreSQL function.

### Ordinary comparison and established containment APIs remain first-class

Collection values use the already-established comparison operators where the selected database defines those comparisons:

```swift
lhs == rhs
lhs != rhs
lhs < rhs
lhs <= rhs
lhs > rhs
lhs >= rhs
```

Existing containment compatibility source is preserved:

```swift
lhs ||> rhs
lhs <|| rhs
```

targeting:

```sql
lhs @> rhs
lhs <@ rhs
```

No replacement declarative wrapper is required merely for naming symmetry.

### SQL collection && and || do not steal SQL's established boolean operators

PostgreSQL ARRAY and Duck LIST support literal collection overlap `&&` and concatenation `||`. SQL already assigns the same Swift tokens to boolean AND/OR over `SQLable`, so changing those overloads would silently break established source semantics.

The existing `.overlaps` surface also cannot be reused because it represents the distinct SQL keyword `OVERLAPS`.

Expression Frontier 01 therefore accepts **no new semantic alias** for these two operators. Exact raw composition remains the truthful escape hatch:

```swift
lhs[any: Op.custom("&&")][any: rhs]
lhs[any: Op.custom("||")][any: rhs]
```

targeting:

```sql
lhs && rhs
lhs || rhs
```

This is preferable to inventing `ArrayOverlap`, `CollectionOverlap`, or another facade that would misname Duck LIST semantics or collide conceptually with SQL `OVERLAPS`. A future general binary-operator authoring improvement may make the raw spelling prettier, but it must preserve these exact tokens and cannot reopen the boolean-operator compatibility contract.

### `Any.sql` is not a viable extension of the collision rule

The `.sql` collision namespace applies where Swift exposes a real nominal type that can participate in clean static-member lookup. `Any` is different: at a downstream call site it is the language's builtin existential type/keyword rather than a normal extensible nominal type.

A focused imported-module probe tested an escaped public namespace:

```swift
public enum `Any` {
    public static func sql(...)
}
```

The declaration itself is legal, and module-qualified:

```swift
ProbeModule.Any.sql(...)
```

works. But bare:

```swift
Any.sql(...)
```

still resolves `Any` to Swift's builtin existential and fails on every tested toolchain with:

```text
type 'Any' has no member 'sql'
```

Ordinary `Any`, `Any?`, `[Any]`, `Any.self`, `Any.Type`, `as Any`, closures returning `Any`, and generic returns remain clean. The failure is specifically bare static-member lookup.

Do not require module qualification merely to spell SQL ANY. This is a narrow language-collision exception, not a reason to change unrelated names.

The naming rule is therefore:

- when an SQL concept collides with a normal Swift nominal type, use that real type as a namespace and choose a member that names the concrete SQL grammar role;
- when a closure is the primary semantic body, prefer a direct trailing closure and avoid `Something(label: { ... })` if the grammar distinction can live in the callable/member name;
- when an exact SQL keyword collides with a fundamental Swift language construct and neither ordinary UpperCamel spelling nor clean namespace-member lookup is possible, an exact uppercase SQL callable is permitted as an explicit exception;
- do not propagate that exception to neighboring SQL names that have no Swift conflict.

### Quantified comparisons keep ordinary SQL casing except the exceptional ANY collision

The original UpperCamel `Any(...)` and attempted bare `Any.sql(...)` directions are compiler-rejected:

- unescaped `Any` cannot be declared as a Swift identifier;
- escaped imported `Any` does not win bare call resolution;
- bare `Any.sql(...)` resolves to builtin Swift `Any` and fails;
- backticks/module qualification are not acceptable public DSL ergonomics.

The maintainer-selected target is therefore deliberately asymmetric:

```swift
value == ANY(operand)
value > All(operand)
value == Some(operand)
```

`ANY` is the exceptional exact-SQL uppercase callable forced by Swift's fundamental `Any` collision. `All` and `Some` have no equivalent conflict and therefore stay in the normal public SQL UpperCamel callable style. Do not uppercase `ALL` / `SOME` merely for visual family symmetry, and do not lowercase `all` / `some` merely to match the workaround required for ANY.

Final cross-toolchain compiler evidence proves the exact asymmetric family is clean: `ANY(...)` / `ANY { ... }`, `All(...)` / `All { ... }`, and `Some(...)` / `Some { ... }` all compile in one imported module across Swift 6.2.3, Xcode/Swiftly 6.3.3, and Swift 6.4 while ordinary Swift `Any`, existential `any`, and opaque `some` syntax remain unaffected.

The emitted SQL remains exact:

```sql
value = ANY (operand)
value > ALL (operand)
value = SOME (operand)
```

`SOME` remains a first-class spelling even where the database treats it as a synonym for `ANY`; do not normalize the user's chosen construct in emitted SQL.

### Quantified ARRAY/collection operands remain explicit

PostgreSQL ARRAY example:

```swift
User.$role == ANY(
    Array.items {
        Role.admin
        Role.moderator
    }
)
```

Concise shorthand:

```swift
User.$role == ANY(Array.items(.admin, .moderator))
```

Prepared PostgreSQL:

```sql
"User"."role" = ANY(
    ARRAY[$1, $2]
)
```

with values:

```text
[admin, moderator]
```

Do not add `ANY { role1; role2 }` as implicit collection construction. Quantifier trailing closure is reserved for nested-query grammar; collection identity must stay explicit so PostgreSQL ARRAY, Duck LIST, fixed Duck ARRAY, and other exact SQL values remain distinguishable.

DuckDB v1.5.5 native evidence confirms that the same quantified-comparison semantic family accepts Duck LIST literals/values, fixed `array_value(...)`, typed empty LISTs, and `ARRAY(subquery)` expressions. Public source must still use the exact Duck operand construct; no PostgreSQL ARRAY-element constructor is silently translated.

### Quantified subqueries own their statement body directly

Builder-oriented subquery form:

```swift
Where {
    User.$score > All {
        Select {
            Threshold.$value
        }

        From {
            Threshold.table
        }

        Where {
            Threshold.$kind == kind
        }
    }
}
```

targets:

```sql
WHERE "User"."score" > ALL (
    SELECT "Threshold"."value"
    FROM "Threshold"
    WHERE "Threshold"."kind" = $1
)
```

with values:

```text
[kind]
```

An already-formed nested statement is concise:

```swift
User.$score > All(thresholds)
```

The quantifier supplies required parentheses around its structural query value. No extra `Subquery` wrapper is required.

DuckDB v1.5.5 also natively validates PostgreSQL-shaped row-valued quantified subqueries:

```sql
ROW(...) = ANY (SELECT a, b ...)
ROW(...) > ALL (SELECT a, b ...)
```

MySQL supports quantified subqueries but has no PostgreSQL-style native ARRAY constructor/type family. The DSL must not simulate array quantification through JSON, MEMBER OF, IN, EXISTS, or another construct.

### Empty quantified operands keep database truth semantics

The DSL does not rewrite empty quantified collections/subqueries to synthetic booleans.

Native Duck evidence confirms the standard empty-rhs outcomes in the tested family:

```text
ANY(empty) -> false
ALL(empty) -> true
```

PostgreSQL ARRAY/subquery semantics remain database-owned, including NULL behavior. The public quantifier node only preserves exact operand and operator structure.

### Dialect capability is explicit, not a rendering trick

| Exact construct | PostgreSQL | DuckDB v1.5.5 | MySQL 8.4 |
| --- | --- | --- | --- |
| `ARRAY[element, ...]` | supported | not claimed/mapped | no native ARRAY family |
| `ARRAY(subquery)` | supported | supported, returns LIST | not claimed |
| scalar ANY/SOME/ALL subquery | supported | supported | supported |
| row-valued quantified subquery | supported | native-positive | not claimed by this frontier |
| quantified ARRAY/collection expression | ARRAY supported | LIST/fixed ARRAY/ARRAY(subquery) native-positive | no native ARRAY family |
| two-bound `[lower:upper]` slice | supported | supported | not this SQL family |
| stepped `[begin:end:step]` slice | not supported | supported | not this SQL family |
| `@>`, `<@`, `&&`, `||` collection operators | ARRAY family | LIST family | not this SQL family |

Shared Swift semantic nodes are justified only where the SQL ownership is genuinely shared. Different database constructs remain different APIs or capability paths.

### Expression Frontier 01 closure

The following former open decisions are resolved by DESIGN-026:

- QUERY-RB-015: UpperCamel bare `Any` rejected by compiler evidence;
- QUERY-RB-016: SQL ARRAY namespace uses compiler-validated grammar-role members on a constrained extension of the real Swift `Array`: `Array.items(...)` / `Array.items { ... }` for `ARRAY[...]`, and `Array.subquery(...)` / `Array.subquery { ... }` for `ARRAY(subquery)`;
- QUERY-RB-017: no new misleading alias for collection `&&` / `||`; preserve boolean operators and use exact raw operator composition;
- QUERY-RB-018: structural lowercase `slice(...)` owns bracket-slice syntax, with Duck-only step capability explicit;
- QUERY-RB-020: bare UpperCamel `Any` and bare `Any.sql(...)` are compiler-rejected; compiler-validated public spelling is exceptional uppercase `ANY(...)` / `ANY { ... }`, while non-conflicting `All(...)` / `All { ... }` and `Some(...)` / `Some { ... }` retain normal SQL casing.

QUERY-RB-019 remains an implementation/extensibility decision for the eventual generic custom-aggregate builder entry point. It does not block the accepted Expression Frontier 01 semantics or the start of Expression Frontier 02.

## DESIGN-027 - JSON/SQL-JSON, exact binary operators, ranges, COLLATE, and time-zone expressions preserve grammar ownership

Expression Frontier 02 keeps exact database grammar visible instead of creating one portable JSON/path/range abstraction. The accepted architecture deliberately separates constructs that happen to operate on related values but own different SQL grammar.

Production implementation remains a later planned/audited wave. All accepted constructs must lower into ordinary `SQLable` / `SQLPart` composition and the existing preparation/binding pipeline. No second expression AST, parser, or renderer is authorized.

### JSON is three grammar families, not one API

Keep these families distinct:

1. navigation/extraction operators such as PostgreSQL/Duck `->` / `->>` and PostgreSQL `#>` / `#>>`;
2. symbolic JSON/JSONB predicates and mutation operators such as `@>`, `<@`, `?`, `?|`, `?&`, `@?`, `@@`, `||`, `-`, and `#-`;
3. SQL/JSON query constructs such as `JSON_EXISTS`, `JSON_QUERY`, and `JSON_VALUE`, whose argument list owns additional SQL grammar such as PASSING, RETURNING, wrapper/quotes behavior, ON EMPTY, and ON ERROR.

Do not flatten these into one generic `JSONPath` or `JsonOperator` abstraction.

### Existing key-path JSON traversal is compatibility, not the new ontology

Current multi-segment `SwifQLPartKeyPath` behavior is preserved as compatibility. PostgreSQL and Duck render established path segments through JSON traversal while MySQL has historical different rendering.

New explicit JSON APIs must not depend on that dialect-polymorphic legacy behavior to define their semantics. Existing source remains valid, but future explicit JSON constructs own their SQL grammar directly.

### No cross-dialect semantic JSONPath type is accepted

PostgreSQL SQL/JSON path expressions, Duck JSON Pointer / lookup-oriented JSONPath, and MySQL JSON path are materially different path languages.

Do not introduce one public typed `JSONPath` value that claims those languages are interchangeable.

For the accepted first SQL/JSON layer, path expressions are owned by the exact surrounding SQL construct rather than by one shared path-language type. A runtime Swift string may therefore enter a dedicated SQL/JSON-path **grammar role** whose dialect policy decides whether that value can remain normally bound or must use the dialect's safe parser-constant/literal rendering. This does not change the value into an identifier and does not authorize raw interpolation.

MySQL 8.4, for example, requires the `JSON_VALUE` path operand to be a string literal. That parser requirement belongs to dialect-owned rendering of the path argument role, not to a fake cross-dialect `JSONPath` ontology or to a different public function name.

Arbitrary SQL expressions in the path position are supported only where the selected database genuinely permits them. A future typed path-builder requires its own dialect/language design gate.

### SQL/JSON query functions are first-class structural owners

The accepted declarative identities are:

```swift
JSONExists(document, path)
JSONQuery(document, path)
JSONValue(document, path)
```

When the exact dialect grammar has optional clauses, the compositional form owns one direct trailing result-builder body:

```swift
JSONValue(Document.$payload, path) {
    Passing(limit, as: "limit")
    Passing(offset, as: "offset")
    Returning(.integer)
    DefaultOnEmpty(0)
    ErrorOnError()
}
```

targeting PostgreSQL grammar equivalent to:

```sql
JSON_VALUE(
    "Document"."payload",
    $1
    PASSING $2 AS "limit", $3 AS "offset"
    RETURNING INTEGER
    DEFAULT $4 ON EMPTY
    ERROR ON ERROR
)
```

with bound values:

```text
[path, limit, offset, 0]
```

Direct `Passing(...)` children coalesce structurally into one SQL PASSING clause in source order. Runtime control flow controls the presence of individual bindings only; it must not emit repeated PASSING keywords or reconstruct clauses by scanning previous tokens.

The closure is the primary optional-clause body, so do not replace this with labeled-closure forms such as `JSONValue(document, path, options: { ... })`.

### SQL/JSON option nodes name exact grammar
The final SQL/JSON option-node inventory must remain SQL-shaped.

Accepted ownership principles:
- `Passing(value, as: name)` owns one PASSING variable binding; `name` is structural identifier identity, not a bound value;
- `Returning(type)` owns RETURNING type grammar;
- ON EMPTY and ON ERROR behavior must remain distinct typed roles;
- JSON_QUERY wrapper and quote behavior remain distinct roles owned inside JSON_QUERY;
- source ordering and SQL grammar ordering are structural, never recovered from rendered text.

Final cross-toolchain compiler evidence closes the option-node spelling. The accepted public vocabulary is:

```swift
Passing(value, as: "name")

Returning(.integer)
Returning(.jsonb)
Returning(.text, format: .json)
Returning(.text, format: .jsonUTF8)

NullOnEmpty()
ErrorOnEmpty()
DefaultOnEmpty(value)

NullOnError()
ErrorOnError()
DefaultOnError(value)

TrueOnError()
FalseOnError()
UnknownOnError()

WithoutWrapper()
WithoutArrayWrapper()

WithWrapper()
WithWrapper(.conditional)
WithWrapper(.unconditional)

WithArrayWrapper()
WithArrayWrapper(.conditional)
WithArrayWrapper(.unconditional)

KeepQuotes()
OmitQuotes()
KeepQuotes(.onScalarString)
OmitQuotes(.onScalarString)

EmptyArrayOnEmpty()
EmptyObjectOnEmpty()
EmptyArrayOnError()
EmptyObjectOnError()
```

These exact call sites compile cleanly in an imported public module across Xcode Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Xcode Swift 6.4. `Passing(..., as: ...)` requires no escaped declaration label. Mixed builder bodies, including runtime `if`, compile cleanly. Real SQL source has no public declaration collision with this vocabulary.

The nodes mirror SQL token order rather than wrapping behavior inside reversed mini-languages such as `OnEmpty(.default(...))`. Owner-specific builders must admit only grammar-valid subsets during implementation planning; shared names such as `ErrorOnError()` may appear in multiple owners where SQL genuinely reuses that exact behavior.

### Shared SQL identity does not imply shared path language or capability

`JSONValue` is a genuine shared SQL identity but not a promise of equal grammar:

- PostgreSQL supports SQL/JSON path with PASSING, RETURNING, ON EMPTY, and ON ERROR;
- Duck exposes `json_value(json, path)` with its own lookup path semantics and does not inherit PostgreSQL clause grammar;
- MySQL exposes `JSON_VALUE(document, path)` with RETURNING / ON EMPTY / ON ERROR but no PostgreSQL PASSING clause and its own path language/type restrictions.

Therefore the same public SQL identity may exist where truthful while optional builder children remain capability-checked per dialect.

`JSONExists` is shared only where the exact SQL identity exists. Do not map it to a differently named MySQL path-existence function.

`JSONQuery` is not claimed for a dialect until its exact same construct and grammar have been independently verified.

### Exact binary operator authoring is a generic expression category

Frontier 02 exposes a shared need across JSON, arrays/lists, ranges/multiranges, and future dialect surfaces: an exact binary infix expression whose token cannot safely become a Swift operator overload.

The accepted expert escape is:

```swift
lhs.op(.custom("@?"), rhs)
lhs.op(.custom("&&"), rhs)
lhs.op(.custom("-|-"), rhs)
```

targeting deliberately grouped SQL:

```sql
(lhs @? rhs)
(lhs && rhs)
(lhs -|- rhs)
```

This is an exact structural escape, not a semantic portability facade.

The helper owns parentheses unconditionally. That makes composition independent of dialect precedence quirks and allows it to lower through ordinary parts as:

```text
( + lhs parts + space + exact operator part + space + rhs parts + )
```

Binding remains ordinary left-to-right preparation. No precedence table, renderer branch, token-history scan, or new expression AST is required.

Use existing typed Swift/SQL operators when their meaning is already truthful. For example, ordinary comparison operators and established containment compatibility remain preferred over `.op(.custom(...))`.

The existing verbose form:

```swift
lhs[any: Op.custom("@?")][any: rhs]
```

remains raw compatibility, but new explicit symbol-heavy expression work should prefer the grouped `.op` escape.

Do not reuse `Op.fulltext` for JSON-path `@@`; identical token spelling does not make PostgreSQL text-search and JSON-path predicate ownership the same semantic API.

### Explicit JSON navigation may use the exact binary escape without inventing aliases

Where an exact first-class Swift operator spelling is unavailable or would collide with Swift grammar, explicit navigation can remain literal:

```swift
document.op(.custom("->"), key)
document.op(.custom("->>"), key)
document.op(.custom("#>"), pathArray)
document.op(.custom("#>>"), pathArray)
```

This does not replace established legacy key-path traversal or exact `Fn.json*` / `Fn.jsonb*` function identities.

Frontier 02 deliberately adds no new named `Op` constants for these punctuation-heavy tokens. Names such as `doubleAt` / `hashArrow` are less SQL-shaped than the tokens themselves, while semantic names would falsely assign overloaded SQL tokens to one domain. The accepted spelling remains `.op(.custom(token), rhs)`.

### COLLATE is an expression continuation with identifier ownership

Preferred compositional form:

```swift
Select {
    User.$name
    Collate("C")
    As("name")
}
```

targets:

```sql
SELECT "User"."name" COLLATE "C" AS "name"
```

Inline expression form remains available:

```swift
OrderBy(
    Collate(User.$name, "C"),
    .asc
)
```

The collation operand is structural identifier identity, not a bound string value. A string convenience must lower to identifier parts. Schema-qualified identity must remain representable through `Path.Identifier` or equivalent existing identifier structure.

Builder-oriented `Collate(...)` is a typed postfix continuation attached structurally to the immediately open expression. It must not search rendered tokens or previous receiver history.

### AT TIME ZONE is a PostgreSQL/Duck exact expression, not MySQL portability sugar

Preferred builder continuation:

```swift
Select {
    Event.$createdAt
    AtTimeZone(zone)
    As("localCreatedAt")
}
```

Inline form:

```swift
AtTimeZone(Event.$createdAt, zone)
```

Prepared PostgreSQL/Duck shape:

```sql
"Event"."createdAt" AT TIME ZONE $1
```

with:

```text
[zone]
```

The zone operand is an ordinary SQL expression/value and preserves normal binding.

Repeated continuation is valid where the database grammar permits it:

```swift
Select {
    eventTime
    AtTimeZone("Asia/Tokyo")
    AtTimeZone("America/Chicago")
}
```

PostgreSQL `AT LOCAL` is a distinct exact construct:

```swift
Select {
    Event.$createdAt
    AtLocal()
}

AtLocal(Event.$createdAt)
```

Do not silently map `AtTimeZone` to MySQL `CONVERT_TZ` or to MySQL's restricted CAST-specific `AT TIME ZONE` grammar. Mechanical rendering in an unsupported dialect is not a support claim.

### Range/multirange reuse existing exact SQL identities

Do not create a parallel `SQLRange` semantic value model merely to access PostgreSQL range grammar.

Existing exact identities remain first-class where PostgreSQL overloads them by operand type:

```swift
Fn.lower(period)
Fn.upper(period)

lhs + rhs
lhs * rhs
lhs - rhs

lhs ||> rhs
lhs <|| rhs
```

These already correspond to exact SQL function/operator identities for range and multirange operands.

Missing ordinary PostgreSQL functions remain exact `Fn` additions using the repository's canonical camel decomposition:

```swift
Fn.isEmpty(period)       // isempty(...)
Fn.lowerInc(period)      // lower_inc(...)
Fn.upperInc(period)      // upper_inc(...)
Fn.lowerInf(period)      // lower_inf(...)
Fn.upperInf(period)      // upper_inf(...)
Fn.rangeMerge(...)       // range_merge(...)
Fn.multiRange(...)       // multirange(...)
Fn.unNest(...)           // unnest(...)

Fn.rangeAgg(...)         // range_agg(...)
Fn.rangeIntersectAgg(...) // range_intersect_agg(...)
```

`range_agg` and `range_intersect_agg` are aggregate identities and therefore inherit DESIGN-025 aggregate-argument ownership rather than introducing a range-specific aggregate builder.

Do not manufacture uniform overloads where PostgreSQL signatures differ:

- `range_merge(anyrange, anyrange)` owns two range arguments;
- `range_merge(anymultirange)` owns one multirange argument;
- `multirange(anyrange)` owns one range argument;
- `unnest(anymultirange)` returns a set of ranges.

Missing built-in multirange SQL type identities are additive `Type` capabilities. New Swift names follow current camelCase policy even though historical range properties remain compatibility spellings:

```swift
Type.int4MultiRange      // int4multirange
Type.int8MultiRange      // int8multirange
Type.numMultiRange       // nummultirange
Type.tsMultiRange        // tsmultirange
Type.tsTZMultiRange      // tstzmultirange
Type.dateMultiRange      // datemultirange
```

Do not rename historical `Type.int4range` / `Type.tstzrange` merely to make the old family visually match the new additions; that is unrelated compatibility churn.

PostgreSQL's current polymorphic pseudo-type inventory also exposes additive gaps in `Type.swift`. At minimum the range-family additions must include:

```swift
Type.anyMultiRange              // anymultirange
Type.anyCompatibleRange         // anycompatiblerange
Type.anyCompatibleMultiRange    // anycompatiblemultirange
```

The broader missing `anycompatible` family (`anycompatible`, `anycompatiblearray`, `anycompatiblenonarray`) should be filled as one exact PostgreSQL pseudo-type capability when this Type slice is implemented rather than creating a selectively incomplete family.

Special symbolic operators `&&`, `<<`, `>>`, `&<`, `&>`, and `-|-` use the exact binary-operator escape unless a pre-existing typed operator already truthfully owns the same SQL token/semantics. Range/multirange `+`, `*`, `-`, `@>`, `<@`, and ordinary comparisons reuse existing exact operators.

### Historical MySQL JSON rendering is not architecture evidence

Existing compatibility tests preserve PostgreSQL-style historical function names such as `json_extract_path(...)` in MySQL preparation output.

That historical rendered output is not evidence that MySQL natively supports those PostgreSQL function identities or path semantics. Frontier 02 must preserve existing compatibility until a separately approved correction, but it must not build new shared JSON architecture on that assumption.

The compatibility gap remains stable TECH_DEBT and requires independent native MySQL investigation before behavior changes.

### Expression Frontier 02 state after DESIGN-027

Stable architecture now owns:

- separation of JSON navigation, JSON symbolic operators, and SQL/JSON query-function grammar;
- no fake cross-dialect `JSONPath` type;
- first-class `JSONExists`, `JSONQuery`, and `JSONValue` structural ownership where exact dialect identity is verified;
- direct trailing builder ownership for SQL/JSON optional clauses;
- generic always-grouped exact binary `.op` composition;
- postfix/inline `Collate`, `AtTimeZone`, and PostgreSQL `AtLocal` expression ownership;
- reuse of exact existing range/multirange function/operator identity rather than a new Range ontology;
- additive multirange `Type` and exact `Fn` capability direction.

### JSON_TABLE belongs to the later typed record/table-function frontier

Do not expand Expression Frontier 02 into `JSON_TABLE`.

PostgreSQL and MySQL both expose exact `JSON_TABLE(... COLUMNS (...))` constructs, but the construct is table-producing grammar with typed output columns, ordinality, nested path column groups, aliases, and column-level path/error behavior. That directly intersects the still-open typed record-returning/table-function column problem already owned by QUERY-RB-014.

DuckDB does not gain a fake JSON_TABLE mapping; its exact table-producing JSON identities are `json_each` and `json_tree`.

Therefore JSON_TABLE is explicitly deferred to the later record/table-function expression frontier under QUERY-RB-014. Frontier 02 may design the reusable SQL/JSON option vocabulary that future JSON_TABLE columns can reuse where exact grammar matches, but it does not design JSON_TABLE's row/column builder now.

### Range/multirange dialect boundary

PostgreSQL's native range/multirange family is deliberately PostgreSQL-specific in this frontier.

DuckDB's documented built-in and nested type inventory includes ARRAY/LIST/MAP/STRUCT/UNION/VARIANT but no PostgreSQL range/multirange data-type family. MySQL's native type inventory likewise does not expose PostgreSQL range/multirange types.

Do not translate PostgreSQL range values/operators into pairs, arrays, JSON, BETWEEN predicates, or application-side Swift ranges for portability. Exact PostgreSQL `Type`, `Fn`, arithmetic, containment, and `.op` expressions remain truthful even when unsupported elsewhere.

### Expression Frontier 02 closure

Expression Frontier 02 is architecture-complete under DESIGN-027.

The PostgreSQL range/multirange inventory is stable: exact existing arithmetic/comparison/containment identities are reused; specialized symbolic operators use grouped `.op(.custom(...), rhs)`; missing exact `Fn` additions include bound/introspection functions, `rangeMerge`, `multiRange`, `unNest`, `rangeAgg`, and `rangeIntersectAgg`; missing built-in multirange and relevant polymorphic `Type` identities are additive under current Swift naming rules.

QUERY-RB-021 is closed by downstream compiler evidence for the exact SQL/JSON option vocabulary. Named punctuation `Op` constants are closed negatively: `.op(.custom(token), rhs)` is the accepted exact escape. JSON_TABLE is deferred to QUERY-RB-014 and is not an Expression Frontier 02 blocker.

Production implementation remains unauthorized. The next step is the normal researched implementation-plan workflow with independent plan audit before any production mutation.

## DESIGN-028 - Declarative continuations use typed-current partial composition with closed control-flow boundaries

The declarative query result-builder layer uses a shared structural continuation principle for postfix aliases, JOIN qualifications, and direct nested statement clauses:

> While one semantic item is open, its current grammar state remains statically typed. Legal continuations are encoded as typed `buildPartialBlock` transitions. A control-flow branch or completed item may be erased/materialized only after it is structurally finalized and no continuation can legally attach to it.

This rule closes QUERY-RB-011, QUERY-RB-002, and QUERY-RB-012.

The design is compiler-validated across Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Swift 6.4 through three focused probes. Production implementation must preserve the same ownership invariants while lowering into the existing parts/structural-frame pipeline.

### Open item state is typed; completed history may be materialized

A builder partial result may conceptually carry:

```swift
Partial<Current>
```

where:

- `Current` is the immediately open semantic item/state;
- completed prior items are already finalized/materialized;
- legal postfix/owner-specific continuations are overloads whose accepted `Current` type encodes grammar validity;
- starting a new item finalizes the old `Current` and opens a new typed current;
- final builder output finalizes the last current item.

The exact implementation carrier type is not frozen here. The invariant is.

Do not erase the open current into `Any`, `any Protocol`, an untyped node list, or generic raw parts before ownership-sensitive continuations are consumed.

### General postfix As uses typed aliasability

For a list item such as:

```swift
Select {
    User.$id
    As("identifier")

    User.$email
    As("emailAddress")
}
```

the first item remains statically aliasable until `As` is consumed.

Conceptually:

```text
OpenExpression
  + As
  -> AliasedExpression
```

An aliased state does not expose another ordinary item-alias transition, so repeated aliasing can reject at compile time.

The same public `As("alias")` request may attach to different SQL owners only when the static current state explicitly exposes an alias slot. The `As` node itself does not scan previous siblings or infer owner identity from rendered parts.

### JOIN continuation is a typed owner-state machine

JOIN continuation ownership is represented by distinct static states equivalent to:

```text
JoinOpen
JoinSourceAliased
JoinOnQualified
JoinUsing
JoinUsingAliased
```

Accepted transitions include:

```text
JoinOpen + As
  -> JoinSourceAliased

JoinOpen + On
JoinSourceAliased + On
  -> JoinOnQualified

JoinOpen + Using
JoinSourceAliased + Using
  -> JoinUsing

JoinUsing + As
  -> JoinUsingAliased
```

This means one public spelling remains sufficient:

```swift
Join(.left, Profile.table)
As("profile")
Using(User.$id)
As("keys")
```

The first `As` is a source alias because the current state is the JOIN source. The second `As` is a PostgreSQL USING-result alias because the current state is `JoinUsing`.

No separate public `SourceAs`, `UsingAs`, mutable current-owner variable, or token-history inspection is required.

Illegal transitions such as orphan `On` / `Using`, repeated source alias, `On -> Using`, `Using -> On`, late source alias after qualification, and repeated USING-result alias must be rejected structurally.

### Closed FROM body, open outer clause

Finalizing the inner `FromBuilder` body does not require erasing an outer, statically guaranteed FROM clause's continuation proof. At the `SQLBuilder` root, a guaranteed `From` may remain the typed current clause; owner-specific `buildPartialBlock` transitions consume sibling JOIN and legal qualification requests and update that same clause's structural item sequence. Starting an independent outer item or entering a finalized control-flow boundary materializes the clause and removes its continuation target. A maybe-empty FROM result and a value deliberately erased to plain `SwifQLable` expose no sibling JOIN transition. Proof of the guaranteed source travels with the typed value, including a concrete `let from = From { ... }`; it is not recovered from rendered tokens, a neutral-fragment sweep, ambient mutable state, or a prior arbitrary clause. Preserve public `FromBuilder.Result` source compatibility or obtain a separate API ruling before changing it. The legacy `From` ingress may carry `@_disfavoredOverload` under DESIGN-022's narrow ranking exception only; a future compiler ranking change reopens ingress. Existing nested and dynamic-empty contracts remain intact.

### Direct nested statements inside From use typed statement-clause states

The accepted DESIGN-022 syntax remains:

```swift
From {
    Select {
        Order.$userId
        Fn.count(Order.$id)
        As("orderCount")
    }

    From {
        Order.table
    }

    GroupBy {
        Order.$userId
    }

    As("orderStats")

    Organization.table
}
```

The outer `From` builder recognizes a nested statement start as one typed current item. Nested statement clauses extend that current through static grammar states rather than becoming independent outer FROM items.

Representative state progression may be equivalent to:

```text
NestedSelectOpen
  -> NestedFromOpen
  -> NestedWhereOpen
  -> NestedGroupOpen
  -> NestedOrderOpen
  -> NestedLimitOpen
  -> AliasedDerivedItem
```

The exact implementation type names are internal.

The same public `From { ... }` spelling is valid both for the outer FROM builder and as the nested statement's FROM clause. Compiler evidence proves this can resolve without introducing public `InnerFrom` / `NestedFrom` names.

A new ordinary outer FROM item finalizes the nested statement as one derived item before opening the next item.

### Representative statement clause order is structural

The typed nested-statement state machine must encode the supported clause order rather than accepting arbitrary clause permutations and repairing them at render time.

At minimum, representative SQL order such as:

```text
Select
-> From
-> Where
-> GroupBy
-> OrderBy
-> Limit
```

is represented by legal state transitions.

A form such as:

```swift
From {
    Select { ... }
    GroupBy { ... }
    From { ... }
}
```

must not become valid merely because all three nodes are individually known SQL clauses.

Future clauses such as HAVING, QUALIFY, WINDOW, FETCH, row locking, and set-result continuations extend this typed statement-state grammar when their own design decisions close.

### Control-flow boundaries finalize locally

Dynamic control flow is an ownership boundary.

This is valid:

```swift
Select {
    User.$id

    if includeEmail {
        User.$email
        As("emailAddress")
    }
}
```

The branch-local `User.$email + As` item is finalized before the optional branch returns outward.

Likewise:

```swift
From {
    TableA

    if includeStats {
        Select { ... }
        From { ... }
        As("stats")
    }

    TableB
}
```

The optional branch returns a closed/finalized group. The outer builder may then start `TableB` as a new item.

By contrast:

```swift
From {
    if includeStats {
        Select { ... }
        From { ... }
    }

    As("stats")
}
```

must reject: the outer `As` cannot reach into a finalized optional group.

The same rule applies to `if/else`, optional binding, and loops. Each branch/iteration finalizes its own open state before becoming an outer child/group.

### Type erasure is allowed only after ownership closes

Compiler evidence shows some control-flow hooks may need an erased finalized-boundary representation for practical Swift type inference.

This is acceptable only when:

- all ownership-sensitive continuations have already been applied;
- the branch/item is structurally complete;
- the erased/finalized representation exposes no `As`, `On`, `Using`, statement-clause, or other postfix continuation transition;
- it may only be emitted as a completed item/group or followed by a new item start.

This is not ambient mutable builder state and not an untyped continuation model.

### Existing structural frames remain the SQL-region representation

Typed result-builder states are authoring-time composition machinery only.

They must finalize into the existing:

- `SQLable`
- `SQLPart`
- `SQLStructuralFramePart`
- `_SQLStructuralComposition`
- preparation/binding pipeline

They do not become a second query AST or renderer.

Nested statement finalization should reuse the existing statement/set-result frame boundary model instead of duplicating structural SQL-region ownership in a parallel tree.

### Stable evidence

A1 postfix alias / control-flow probe:

`.artifacts/research/declarative-query-structural-continuation-a1-probe-2026-09-21/PROBE_REPORT.md`

A2 JOIN state-machine probe:

`.artifacts/research/declarative-query-structural-continuation-a2-join-probe-2026-09-21/PROBE_REPORT.md`

A3 direct nested FROM probe:

`.artifacts/research/declarative-query-structural-continuation-a3-from-probe-2026-09-21/PROBE_REPORT.md`

All three return STRONG_PASS for their scoped ownership invariants. A2 and A3 include the full Swift 6.2.3 / 6.3.3 / 6.4 matrix.

### Structural Continuation Frontier 03 closure

Structural Continuation Frontier 03 is architecture-complete under DESIGN-028.

Closed decisions:

- QUERY-RB-011 — general postfix `As` typed continuation;
- QUERY-RB-002 — JOIN source/qualification/USING-result continuation ownership;
- QUERY-RB-012 — direct nested statement grouping inside outer `From`.

Production implementation remains unauthorized. Remaining declarative-query architecture decisions continue before implementation planning is frozen.

## DESIGN-029 - SELECT duplicate-row modifiers stay inside the Select builder

SELECT-level duplicate-row grammar belongs to the SELECT owner, not to individual result expressions.

The canonical declarative form for ordinary DISTINCT is:

```swift
Select {
    Distinct()

    User.$id
    User.$email
}
```

targeting:

```sql
SELECT DISTINCT
    "User"."id",
    "User"."email"
```

`Distinct()` occupies the SELECT header/modifier state before ordinary output items. A duplicate modifier appearing after an ordinary output item is invalid. Repeated duplicate modifiers are invalid.

### DISTINCT ON is a separate compound SELECT modifier

Canonical builder-first PostgreSQL/Duck form:

```swift
Select {
    DistinctOn {
        User.$country
        User.$city
    }

    User.$id
    User.$country
    User.$city
}
```

Concise shorthand:

```swift
Select {
    DistinctOn(User.$country, User.$city)

    User.$id
    User.$country
    User.$city
}
```

targeting:

```sql
SELECT DISTINCT ON (
    "User"."country",
    "User"."city"
)
    "User"."id",
    "User"."country",
    "User"."city"
```

`DistinctOn` is preferred over canonical new use of historical `Distinct(on:)` because the compound Swift symbol mirrors the compound SQL grammar and keeps plain DISTINCT ownership visually separate.

An empty `DistinctOn` is invalid. Plain `Distinct()` and `DistinctOn(...)` are mutually exclusive.

PostgreSQL and Duck may expose the exact DISTINCT ON identity where supported. MySQL must not emulate it through GROUP BY, windows, or other rewrites.

PostgreSQL's leftmost-ORDER-BY rule for DISTINCT ON is a PostgreSQL dialect restriction, not a shared Swift grammar restriction, because Duck does not share that requirement.

### Historical field-bearing Distinct remains compatibility-composite

Existing public compatibility includes:

```swift
Distinct(User.$id)
Distinct(on: User.$country)
```

The released variadic `Distinct(field...)` type means `Distinct()` and `Distinct(field...)` necessarily share one Swift nominal type. Compiler evidence proves a result builder cannot distinguish those two forms statically without changing the compatibility type.

That limitation is accepted because historical field-bearing `Distinct(field...)` is already semantically a combined SQL fragment:

```sql
DISTINCT field1, field2, ...
```

Therefore, when it occurs in the SELECT-modifier-first position, it may remain a compatibility-composite that contributes both the DISTINCT modifier and its carried initial output expressions:

```swift
Select {
    Distinct(User.$id) // historical, non-canonical compatibility form
    User.$email
}
```

may truthfully lower to:

```sql
SELECT DISTINCT "User"."id", "User"."email"
```

This form is non-canonical because it visually conflates duplicate-row ownership with output-expression ownership, but it is not a different SQL operator and need not be rejected merely to obtain stronger type purity.

Historical `Distinct(on:)` likewise remains compatibility surface outside the canonical new declarative spelling.

### Header-owned Select(.distinct) is not canonical

A finite header modifier such as:

```swift
Select(.distinct) {
    User.$id
    User.$email
}
```

is compiler-clean and statically unambiguous, but it is not selected as canonical API.

Moving DISTINCT outside the compositional body solely to compensate for a harmless historical type collision would weaken the established builder-first design. The in-builder `Distinct()` form remains SQL-shaped, readable, dynamically composable, and semantically correct.

### Stable compiler evidence

Focused downstream source-shape evidence:

`.artifacts/research/declarative-query-select-modifier-spelling-probe-2026-09-21/PROBE_REPORT.md`

Prompt SHA-256:

`9b0a50f97d71237688abf3466d2ae3b5413bb1eefc590629ba5c843accb127d1`

The probe validates across Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Swift 6.4:

- canonical `Distinct()` source shape;
- canonical concise and builder-first `DistinctOn`;
- compile-time rejection of late/repeated/mixed duplicate modifiers;
- coexistence with historical `Distinct(field...)` / `Distinct(on: ...)`;
- header-owned modifier feasibility as a non-selected alternative.

QUERY-RB-001 is closed.

Production implementation remains unauthorized.

## DESIGN-030 - Declarative set operations are explicit query-result continuations with left-fold semantics

Set operations belong to complete query results, not select-list expressions or arbitrary statement fragments.

The canonical declarative continuation vocabulary is:

```swift
SetUnion { ... }
UnionAll { ... }

Intersect { ... }
IntersectAll { ... }

Except { ... }
ExceptAll { ... }
```

Duck-specific exact identities are:

```swift
UnionByName { ... }
UnionAllByName { ... }
```

`SetUnion` emits the exact SQL `UNION` operator. This one name differs from the SQL keyword because the released public `Union` class already occupies that Swift declaration name. Keep the direct trailing-closure rule for every operation; do not replace the primary branch body with labeled closure forms. A separately assembled right operand uses ordinary `SQL` / `SQLable` composition rather than a second public query-wrapper concept:

```swift
let rhs = SQL {
    Select { ArchivedUser.$id }
    From { ArchivedUser.table }
}

SQL {
    Select { User.$id }
    From { User.table }
    SetUnion(rhs)
}
```

This is intentional under DESIGN-001 and DESIGN-015. The declarative type-state layer owns whether a set-operation continuation may attach to the current left query result and how the resulting set expression is grouped. It does not certify that an arbitrary right-hand `SQLable` is a database-valid complete query. A caller may supply a fragment or otherwise invalid SQL as the operand; target-dialect/database validation may reject the rendered result. Extracting an inline right operand into a variable, helper, or separate file must not require switching from ordinary `SQL` composition to a second public “complete query” abstraction.

### Existing Union compatibility remains intact

Released compatibility such as:

```swift
Union(lhs, rhs)
Union(all: lhs, rhs)
Union([lhs, rhs])
```

remains valid and continues to produce a complete `Union` result. Existing one-argument `Union(completeResult)` calls also remain legacy construction of a `Union` value; they are not typed set-operation requests.

An initializer with a trailing result-builder closure can be added to `Union`, but it returns the same static `Union` type as its released constructors. It therefore cannot serve as the distinct typed continuation request while preserving their meaning. In a Swift 6.3.3 imported-module feasibility probe, a top-level factory returning a separate continuation type failed with `invalid redeclaration of 'Union'`. Do not add a closure initializer to `Union` as a substitute for the separate request type.

```swift
SetUnion {
    Select { ... }
    From { ... }
}
```

The continuation request keeps its distinct `SetUnion` name/type, but its right operand may be an ordinary `SQLable`. `SQL { ... }` is the canonical way to assemble a separate right operand:

```swift
let rhs = SQL {
    Select { ArchivedUser.$id }
    From { ArchivedUser.table }
}

SQL {
    Select { User.$id }
    From { User.table }
    SetUnion(rhs)
}
```

The exact public overloads and their result-builder selection must still pass a fresh imported-module feasibility gate before implementation. That gate must validate the `Union` name collision boundary, released constructor coexistence, all eight operation transitions, optional continuation behavior, and left-side ownership negatives. It does not require arbitrary or erased `SQLable` operands to fail at compile time. Accepting such operands is a deliberate SQL-first/composition tradeoff: SQL preserves the requested structure, while the caller and target database remain responsible for whether the resulting SQL is meaningful and valid.

### Set continuation applies only to a complete open query result

A declarative set-operation continuation requires one complete open query result to its left.

Valid:

```swift
SQL {
    Select { User.$id }
    From { User.table }

    SetUnion {
        Select { ArchivedUser.$id }
        From { ArchivedUser.table }
    }
}
```

Invalid continuation ownership includes:

- orphan `SetUnion` / `UnionAll` / `Intersect` / `Except` continuations without a left query result;
- two adjacent base results without a set operator;
- continuation into a finalized/closed nested result.

These are left-side ownership errors: the builder must know which open query result receives the continuation. Right-operand SQL validity is deliberately outside that guarantee. The design does not require compile-time rejection of an empty or otherwise nonsensical right operand when ordinary `SQLable` composition can represent it; such input may render SQL rejected by the target database. Left-side continuation ownership remains encoded structurally through the DESIGN-028 typed-current principle rather than through runtime token inspection.

### Chaining is deterministic left fold

Source-order continuation means the next set operation applies to the complete result accumulated immediately before it.

For:

```swift
SQL {
    QueryA

    SetUnion {
        QueryB
    }

    Intersect {
        QueryC
    }
}
```

the intended result is:

```sql
(
    (QueryA)
    UNION
    (QueryB)
)
INTERSECT
(QueryC)
```

not:

```sql
(QueryA)
UNION
(
    (QueryB)
    INTERSECT
    (QueryC)
)
```

The declarative DSL does not silently inherit native SQL `INTERSECT` precedence.

Rationale:

- Swift continuation syntax is naturally left-associative in source order;
- existing fluent chaining already has left-fold semantics;
- explicit grouping produces deterministic semantics across dialect precedence tables;
- user intent remains stable if dialect precedence differs.

### Right-hand grouping is expressed by nesting

If the user wants the right side to be a nested set result, they express that structure directly:

```swift
SQL {
    QueryA

    SetUnion {
        QueryB

        Intersect {
            QueryC
        }
    }
}
```

targeting:

```sql
(QueryA)
UNION
(
    (QueryB)
    INTERSECT
    (QueryC)
)
```

This is structural ownership, not hidden precedence inference.

### Every binary operand is structurally parenthesized

Each supplied set-operation operand lowers through the existing statement/set-result frame model as its own parenthesized operand. Valid SQL use expects that operand to represent a query result, but SQL does not add a separate public completeness proof for the right-hand value.

This preserves branch-local ownership of:

- `ORDER BY`;
- `LIMIT` / `OFFSET` / future FETCH;
- future row-locking clauses where the dialect permits them;
- nested set results;
- bound-value order.

Final `ORDER BY` / `LIMIT` after the chain belong to the outer `.setResult` root, matching current structural-frame behavior.

No new precedence table, token scan, or set-result AST is required.

### Optional continuation is supported

A dynamic branch may own the continuation itself:

```swift
SQL {
    QueryA

    if includeArchive {
        SetUnion {
            QueryB
        }
    }
}
```

When present, the continuation applies to the immediately open outer query result. When absent, that result remains unchanged.

The optional request must remain statically owned through a dedicated continuation/result state; the left result cannot be erased before attachment. Verify this exact spelling and transition with the fresh imported-module feasibility gate.

This differs from placing the owner inside a finalized branch and attempting to continue it from outside, which remains invalid under DESIGN-028.

### Right operand uses ordinary SQL composition

The `SetUnion` request may carry its right operand as ordinary `SQLable` / parts composition. No second public “complete query” carrier is required.

This value erasure is acceptable because the right operand is payload, not the current continuation owner. The left/current result state and set-operation kind remain statically typed through ownership-sensitive attachment, which is the DESIGN-028 guarantee that matters here. No runtime owner lookup or continuation validation is introduced, and no right-operand provenance type leaks into the public developer experience.

### UNION BY NAME is Duck-specific exact grammar

`UnionByName` and `UnionAllByName` represent Duck's exact set-operation identities.

Do not map them to name-alignment rewrites in PostgreSQL/MySQL or synthesize NULL-filling behavior outside the database's exact construct.

### Compiler evidence boundary

The public nominal `Union` type prevents a separate same-spelled top-level continuation factory: Swift 6.3.3 reports `invalid redeclaration of 'Union'`. A closure initializer on that class has static type `Union`, just like the released constructors. This is insufficient evidence for distinct typed attachment, so use a separate `SetUnion` request type. Its right operand may use ordinary `SQLable` composition. Validate the exact overloads, all eight operator transitions, existing constructor compatibility, optional branches, and left-side ownership negatives through fresh external `import SQL` clients before implementation. The 2026-09-29 evidence that `SetUnion(SQLable)` accepts arbitrary or erased fragments remains factually useful, but that permissiveness is no longer classified as an API defect: this correction deliberately preserves direct SQL composition and leaves right-operand SQL validity to the caller and target database.

### SELECT / Set-Result Frontier 04 closure

SELECT / Set-Result Frontier 04 is architecture-complete under DESIGN-029 and DESIGN-030.

Closed decisions:

- QUERY-RB-001 — SELECT `DISTINCT` / `DISTINCT ON` ownership;
- QUERY-RB-007 — declarative `UNION` / `INTERSECT` / `EXCEPT` ownership and deterministic grouping.

Implementation remains subject to the repository's research, plan, independent audit, task, and source-review gates. Other declarative-query decisions continue under their owning architecture sections.

## DESIGN-031 - Row locking is one typed `For { ... }` clause per exact SQL locking clause

Declarative row locking belongs to the tail of a complete lockable SELECT statement.

One public `For { ... }` builder represents exactly one SQL locking clause:

```swift
For {
    Update()

    Of {
        User.table
        Account.table
    }

    SkipLocked()
}
```

targeting PostgreSQL/MySQL-style grammar:

```sql
FOR UPDATE OF "User", "Account" SKIP LOCKED
```

Concise `Of(...)` remains available:

```swift
For {
    Share()
    Of(User.table)
    Nowait()
}
```

### Lock strength is the first required typed state

Accepted lock-strength nodes are:

```swift
Update()
NoKeyUpdate()
Share()
KeyShare()
```

The locking builder begins with exactly one strength. A second strength in the same `For` is invalid.

Cross-dialect capability is exact:

- PostgreSQL: `UPDATE`, `NO KEY UPDATE`, `SHARE`, `KEY SHARE`;
- MySQL: `UPDATE`, `SHARE`;
- Duck row-lock support is not claimed by this design.

Do not map an unsupported strength to a stronger/weaker lock mode.

### OF is a structural table-reference list

Builder-first form:

```swift
Of {
    User.table
    Account.table
}
```

Concise shorthand:

```swift
Of(User.table, Account.table)
```

`OF` owns table/from-reference identity, not safe values. It must therefore lower through structural identifiers/from-reference identity rather than parameter binding.

A dialect may further restrict which table aliases/names are valid in this position.

`Of` is optional and may appear at most once inside one `For` clause.

### Wait behavior is exact finite grammar

Accepted nodes:

```swift
Nowait()
SkipLocked()
```

They correspond exactly to:

```sql
NOWAIT
SKIP LOCKED
```

`Nowait` follows the project's normal Swift decomposition for one SQL lexical word.

Wait behavior is optional and mutually exclusive inside one locking clause.

### Multiple SQL locking clauses are multiple sibling `For` continuations

PostgreSQL and MySQL both permit multiple locking clauses for different table sets.

Canonical source:

```swift
SQL {
    Select { User.$id }
    From {
        User.table
        Account.table
    }

    For {
        Update()
        Of(User.table)
        SkipLocked()
    }

    For {
        Share()
        Of(Account.table)
        Nowait()
    }
}
```

Each sibling `For` finalizes one independent locking clause before the next begins.

Do not create one synthetic `For` builder containing an array of lock specifications.

### `For` is a statement/result continuation under DESIGN-028

The locking clause attaches only to a complete SELECT statement state that remains lockable for the selected dialect.

Conceptually:

```text
LockableSelect
  + ForLock
  -> LockedSelect

LockedSelect
  + ForLock
  -> LockedSelect
```

This is typed statement-state composition, not receiver-history/token scanning.

A finalized nested query may own its own locking clause before being closed; an outer `For` does not reach into a finalized subquery or WITH item.

### PostgreSQL-invalid result states must not masquerade as lockable PostgreSQL SELECTs

PostgreSQL 18 currently forbids its row-locking clauses with result states including:

- `DISTINCT` / `DISTINCT ON`;
- `GROUP BY`;
- `HAVING`;
- `WINDOW`;
- `UNION` / `INTERSECT` / `EXCEPT` results and their direct operands.

The declarative state model should preserve enough structural identity to prevent PostgreSQL-specific locking support from being advertised on these states where practical.

This does not imply that the shared Swift grammar must globally erase capabilities another dialect genuinely supports. Dialect capability/validation remains authoritative when restrictions differ.

### Clause ordering follows the statement tail

Locking follows the statement's ordering/pagination tail according to the target grammar.

The typed statement-state design must place `For` in the legal tail position rather than repairing clause order during rendering.

PostgreSQL `LIMIT/OFFSET/FETCH` followed by `For { ... }` remains representable.

### SQL semantics stay with the database

The DSL does not reinterpret:

- lock duration;
- transaction/autocommit requirements;
- strongest-clause conflict resolution;
- NOWAIT/SKIP LOCKED concurrency behavior;
- replication caveats.

Those remain database semantics.

The DSL owns exact syntax, identifier safety, dialect capability, and structural clause placement only.

### Stable evidence and compatibility

Current source has no dedicated public `For`, `NoKeyUpdate`, `Share`, `KeyShare`, `Of`, `Nowait`, or `SkipLocked` owner surface. Symbol scan found no conflicting top-level declarations.

The typed-state mechanism required by this design is already compiler-validated by DESIGN-028's A1/A2/A3 probes across Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Swift 6.4.

Official PostgreSQL 18 and MySQL 8.4 grammar independently confirm the exact shared/extra locking vocabulary.

QUERY-RB-004 is closed.

Production implementation remains unauthorized.

## DESIGN-032 - WITH is a typed statement prefix composed from named `With` items

The declarative WITH clause is a typed prefix that precedes exactly one primary statement/result.

Canonical ordinary multi-item form:

```swift
SQL {
    With("regionalSales") {
        Select { ... }
        From { ... }
    }

    With("topRegions") {
        Select { ... }
        From { "regionalSales" }
    }

    Select { ... }
    From { "topRegions" }
}
```

targets one SQL WITH clause:

```sql
WITH "regionalSales" AS (...),
     "topRegions" AS (...)
SELECT ...
```

Every expression that reaches the statement prefix with concrete static type `With` is one ordinary CTE item, regardless of which `With` initializer created it. Consecutive concrete `With` items at statement start coalesce structurally into one clause. Once the primary statement/result begins, another same-level `With` is invalid.

The compile-time proof is therefore about prefix position and sequencing:

```text
this concrete With occupies a legal WITH-prefix position
```

It is not proof of initializer provenance.

### Existing `With` nominal compatibility remains authoritative

Released compatibility includes a public `With` class with an initializer equivalent to:

```swift
With(table, columns: [...], query)
```

and fluent multi-item attachment through `.with(...)`.

The historical initializer remains broad: its table/name, columns, and query payload are ordinary released `SwifQLable` composition. Do not narrow, relabel, or reinterpret that initializer merely to make the new declarative root stricter.

Compiler evidence proves the same public nominal type can gain a declarative initializer:

```swift
With("name") {
    QueryBody
}
```

without ambiguity while preserving the released initializer and fluent compatibility.

Swift does not permit a free `func With` to coexist with the existing `class With` in the same module. Therefore the declarative call is an initializer on the released nominal type, not a parallel free function or a second public ordinary-WITH wrapper.

After either initializer returns, the static type is the same `With`. The declarative root must not attempt to recover which initializer created the value through runtime provenance flags, rendered-token inspection, `parts` inspection, or ambient mutable state.

A released legacy `With` deliberately placed at the beginning of the new declarative root is therefore also one ordinary prefix item:

```swift
let legacy: With = With(
    Table("activeUsers"),
    oldQuery
)

SQL {
    legacy
    Select { ... }
}
```

This changes only the unreleased declarative-root interaction. It does not change released `With(...)` construction or fluent `.with(...)` behavior.

### Explicit erasure loses WITH-prefix proof

The WITH-prefix role depends on the expression reaching the result builder as concrete static type `With`.

If the caller deliberately erases that value:

```swift
let concrete: With = ...
let erased: SQLable = concrete
```

the erased value follows ordinary `SQLable` composition and does not retain a WITH-prefix ownership proof.

The builder must not inspect runtime type, rendered SQL, or stored parts to recover that proof. This follows DESIGN-028's general rule that deliberate type erasure may lose ownership-sensitive continuation state.

### `WithRecursive` is a distinct clause-start state

`RECURSIVE` belongs to the entire WITH clause, not to one item.

Canonical recursive form:

```swift
SQL {
    WithRecursive("base") {
        Select { ... }
    }

    With("tree") {
        Select { ... }
        From { "tree" }
    }

    Select { ... }
}
```

targets:

```sql
WITH RECURSIVE "base" AS (...),
               "tree" AS (...)
SELECT ...
```

`WithRecursive(name)` means: start a `WITH RECURSIVE` clause whose first item has this name. It does not claim the first item itself self-references and is not an initializer-provenance marker for ordinary `With`.

The typed prefix state therefore distinguishes at least:

```text
ordinary WITH prefix open
recursive WITH prefix open
optional finalized prefix group
complete primary statement
```

`WithRecursive` is legal only as the first prefix item. A later or repeated `WithRecursive` is invalid. Ordinary concrete `With` items may extend either ordinary or recursive prefixes.

### Declarative WITH item headers are typed before the body payload

The declarative initializer may declare output-column names before its body:

```swift
With("regionalSales") {
    Columns {
        "region"
        "total"
    }

    Select { ... }
}
```

`Columns` owns structural output identifiers, not bound values.

PostgreSQL/Duck exact materialization grammar is represented by:

```swift
With("regionalSales") {
    Materialized()
    Select { ... }
}
```

or:

```swift
With("regionalSales") {
    NotMaterialized()
    Select { ... }
}
```

Combined header:

```swift
With("regionalSales") {
    Columns {
        "region"
        "total"
    }
    Materialized()

    Select { ... }
}
```

The declarative item-construction builder may keep header states typed. Repeated `Columns`, both materialization modes, header nodes after the body starts, and a syntactically empty declarative body are invalid construction shapes.

These guarantees are local to the declarative initializer call. Once construction returns `With`, the nominal carries no permanent proof that it originated from this stricter builder.

`Materialized` / `NotMaterialized` are exact PostgreSQL/Duck item grammar. Do not translate them to MySQL optimizer hints or otherwise claim equivalent MySQL syntax.

### One WITH item carries one body payload

Semantically, each WITH item contributes one body payload inside `AS (...)`.

The declarative initializer requires a body expression/payload to be present, but SQL does not introduce a second public “complete query” wrapper to certify that arbitrary body SQL is database-valid. Preassembled/helper query-producing `SQLable` composition should remain practical.

This naturally composes with DESIGN-030:

```swift
With("ids") {
    Select { Current.$id }
    From { Current.table }

    UnionAll {
        Select { Archived.$id }
        From { Archived.table }
    }
}
```

Ownership-sensitive continuations inside a declaratively built body may remain typed until that body expression is formed. After construction, the enclosing value is simply `With`.

The released legacy initializer remains broader and may contain a historical `SwifQLable` payload that was not produced by the declarative item builder. Accepting that concrete `With` as a prefix item does not retroactively certify its body.

Dialect support for data-modifying WITH bodies remains exact: shared Swift identity does not imply every body kind is valid on every target database. SQL does not promise parser, dialect, projection, or database-validity proof for arbitrary body payloads.

### Optional WITH items preserve prefix ownership

Dynamic presence is supported at item boundaries:

```swift
SQL {
    With("base") {
        Select { ... }
    }

    if includeStats {
        With("stats") {
            Select { ... }
        }
    }

    Select { ... }
}
```

The optional branch contains one finalized prefix item/group. It may be appended to an open ordinary or recursive prefix without erasing that prefix's ownership-sensitive static state.

An optional first/only WITH item is also structurally representable:

```swift
SQL {
    if includeStats {
        With("stats") {
            Select { ... }
        }
    }

    Select { ... }
}
```

If the branch is absent, the primary statement remains a statement without WITH.

### Prefix ownership is compile-time structural

The following remain invalid by missing typed transitions rather than runtime repair:

- `With` after the primary statement/result;
- `WithRecursive` after an ordinary `With` prefix has started;
- repeated `WithRecursive`;
- a WITH-only statement without a primary result;
- two adjacent primary results;
- repeated declarative WITH-item headers;
- declarative item header after the body starts;
- syntactically empty declarative item body.

These rules do not include initializer-provenance discrimination. Any concrete static `With` may occupy an otherwise legal ordinary prefix-item position.

No rendered-token scan, runtime provenance mode, runtime owner recovery, or ambient mutable `current CTE` state is used.

### Dialect-specific recursive extensions remain separate

PostgreSQL `SEARCH` / `CYCLE` and Duck recursive `USING KEY` are larger dialect-specific grammars.

They are not folded into the base shared WITH item design. Future support should extend the typed WITH prefix/item states rather than create a generic recursive-query mini-language.

### Stable compiler evidence

Focused WITH prefix evidence:

`.artifacts/research/declarative-query-with-prefix-spelling-probe-2026-09-21/PROBE_REPORT.md`

Prompt SHA-256:

`919008e110243ec08f0407f1dee81c28fea452b9c9023263794364eafa020bb5`

The probe returns `WITH_STRONG_PASS` across Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Swift 6.4.

That evidence supports:

- released and declarative initializer coexistence on the same `With` nominal;
- released fluent `.with` coexistence;
- broad concrete-`With` prefix intake;
- statically typed ordinary, recursive, and optional prefix states;
- statically typed declarative item-header sequencing;
- WITH-only, late/repeated recursive, second-primary, duplicate/late-header, and empty-declarative-body negatives;
- optional WITH items and set-result body composition in the fixture;
- no runtime owner/token scan in the fixture.

The probe did not distinguish legacy from declarative `With` after construction. Its root transitions accepted the concrete `With` nominal regardless of initializer provenance.

A later DQ-06 Plan 03 requirement, R39, attempted to require declarative `With` to compile in prefix position while an otherwise concrete legacy `With` statically rejected there. That requirement is superseded: it was a planning restriction, not an independent SQL semantic, and it is impossible to satisfy from the shared static type without adding a second static carrier or runtime provenance.

No new compiler probe is required to establish this stable architecture correction. Production implementation remains gated by fresh imported-module evidence against the current live `SQLBuilder`, including concrete-`With` versus erased-`SQLable` intake, initializer coexistence, ordinary/recursive/optional transitions, primary finalization, helper/preassembled body composition, exact lowering/bind order, and the structural negatives above. That future gate must not reintroduce R39 or a public completeness wrapper.

### Statement Tail Frontier 05 closure

Statement Tail Frontier 05 is architecture-complete under DESIGN-031 and DESIGN-032.

Closed decisions:

- QUERY-RB-004 — row-locking clause ownership/spelling;
- QUERY-RB-005 — multi-WITH naming, same-nominal concrete-`With` prefix policy, recursive prefix ownership, and declarative item-header/body-presence grammar.

Production implementation remains unauthorized. Remaining declarative-query architecture decisions continue before implementation planning is frozen.

## DESIGN-033 - Declarative runtime-collection `NotIn` uses predicate omission when empty

The declarative runtime-collection membership APIs treat collection emptiness as predicate presence, not as a request to synthesize SQL set-theory constants.

For a non-empty runtime collection:

```swift
let blockedRoles: [Role] = [.banned, .suspended]

Where {
    NotIn(User.$role, blockedRoles)
}
```

targets:

```sql
WHERE "User"."role" NOT IN ('banned', 'suspended')
```

For an empty runtime collection:

```swift
let blockedRoles: [Role] = []

Where {
    NotIn(User.$role, blockedRoles)
}
```

the `NotIn` node contributes no predicate child, exactly as if the caller had written:

```swift
Where {
    if !blockedRoles.isEmpty {
        NotIn(User.$role, blockedRoles)
    }
}
```

If it was the only surviving child, the surrounding predicate clause/group disappears according to DESIGN-020.

### This is deliberate builder-presence semantics, not SQL empty-set rewriting

SQL `NOT IN` is the negation/complement of membership subject to normal SQL NULL semantics. The declarative runtime-collection convenience deliberately does not try to render an empty SQL value list.

The empty collection case must not emit:

```sql
NOT IN ()
TRUE
FALSE
1 = 1
```

or any other synthetic replacement.

The rule mirrors declarative `In(lhs, runtimeCollection)` only after explicit adjudication: both collection conveniences mean "apply this membership filter when the caller supplied at least one runtime element".

### Dynamic membership-builder children follow the same presence rule

For builder-oriented `NotIn` where the left-hand expression is structurally fixed and all right-hand membership children disappear through runtime control flow, the complete node disappears rather than emitting malformed or synthetic SQL.

The left-hand expression never changes role, and a later unrelated child cannot become the membership owner.

### Exact forms remain exact

This decision does not change:

- the existing raw/fluent `.notIn(...)` compatibility API;
- literal/variadic `NotIn` forms, which should be non-empty by construction where practical;
- subquery `NotIn(lhs) { ... }`, whose empty-result behavior remains database execution semantics;
- explicit quantified comparisons such as `<> All(subquery)`;
- SQL NULL behavior.

A caller who needs exact SQL semantics should use an exact non-empty literal/subquery form rather than rely on runtime-collection omission.

QUERY-RB-010 is closed.

Production implementation remains unauthorized.

## DESIGN-034 - PostgreSQL typed record/table-function definitions use `Column.definition` and typed `As` ownership

PostgreSQL anonymous-record table functions and `ROWS FROM` member definitions require a typed output-row declaration whose grammar is distinct from ordinary alias column names.

Canonical direct-function form:

```swift
From {
    Fn.jsonToRecord(document)

    As("record") {
        Column.definition("id", .integer)
        Column.definition("name", .text)
    }
}
```

targets:

```sql
FROM json_to_record($1) AS "record" (
    "id" INTEGER,
    "name" TEXT
)
```

The trailing builder belongs to the exact SQL `AS alias (column_definition...)` owner. It is not an ordinary name-only `Columns { ... }` alias continuation.

### `Column` remains the namespace; `.definition` names the grammar role

`Column<Value>` is already the project's real generic schema/model nominal type.

Focused compiler evidence proves a constrained extension:

```swift
extension Column where Value == Never {
    public static func definition(_ name: String, _ type: Type) -> ...
}
```

can expose standalone-safe calls:

```swift
Column.definition("id", .integer)
Column.definition("name", .text)
```

without disturbing ordinary:

```swift
Column<Int>("id")
Column<String>(name: "name", type: .text)
```

`Never` naturally satisfies the existing `Value: Codable` constraint on every supported Swift toolchain; no new conformance, sentinel type, or model-value specialization is required.

An unconstrained `extension Column` is not sufficient because bare `Column.definition(...)` leaves `Value` uninferred. An artificial public sentinel specialization would work but is rejected as unnecessary grammar coupling.

This follows DESIGN-026's existing rule for overlapping nominal types: preserve the real nominal type as a namespace and name the concrete grammar role on it.

### `Column.definition` is not a model/DDL column

The returned definition node owns only:

- structural output identifier name;
- exact SQL type identity.

It does not inherit or expose:

- `Column<Value>` property-wrapper semantics;
- defaults;
- DDL constraints;
- primary keys;
- model encoding/decoding state.

A record-definition builder must not accept a model `Column<Int>` merely because both use the `Column` namespace.

An empty typed-definition builder is invalid.

### Typed `As` has alias and no-alias forms

Three public `As` shapes coexist:

```swift
As("record")

As("record") {
    Column.definition("id", .integer)
}

As {
    Column.definition("id", .integer)
}
```

The first remains ordinary aliasing.

The second is the PostgreSQL direct table-function form:

```sql
AS "record" ("id" INTEGER)
```

The third is the PostgreSQL `ROWS FROM` member form:

```sql
AS ("id" INTEGER)
```

Compiler evidence proves all three overload shapes coexist without ambiguity across Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Swift 6.4.

### `RowsFrom { ... }` is a PostgreSQL table-source owner

Canonical form:

```swift
RowsFrom {
    Fn.jsonToRecord(document)
    As {
        Column.definition("id", .integer)
        Column.definition("name", .text)
    }

    Fn.generateSeries(1, 10)
}
```

targets:

```sql
ROWS FROM(
    json_to_record($1) AS ("id" INTEGER, "name" TEXT),
    generate_series(1, 10)
)
```

One member function plus its optional typed `As { ... }` definition list is one typed current item under DESIGN-028. The next function opens the next ROWS FROM member.

Do not implement member attachment by scanning prior rendered function text.

### `WithOrdinality()` is a table-source continuation, not a function-specific API

Existing DESIGN-022 compound spelling remains canonical:

```swift
From {
    Fn.generateSeries(1, 10)
    WithOrdinality()
    As("g")
    Columns {
        "value"
        "position"
    }
}
```

targeting:

```sql
FROM generate_series(1, 10)
WITH ORDINALITY
AS "g" ("value", "position")
```

The same continuation is valid on `RowsFrom { ... }` where PostgreSQL permits it.

`WithOrdinality()` appends the database-owned ordinal column to the table-function result. The outer ordinary `Columns` continuation may rename output columns, including the ordinal column.

Typed record definitions and name-only outer alias columns remain distinct concepts.

### Dialect capability is exact

These typed record-definition forms are PostgreSQL table-function grammar.

Do not map them to MySQL `JSON_TABLE`, Duck `json_each/json_tree`, generic object decoding, or synthetic casts.

Duck fixed-schema JSON table functions remain ordinary table-function FROM sources. MySQL/PostgreSQL `JSON_TABLE` owns a different `COLUMNS(...)` grammar and is handled separately in Frontier 06.

### Stable compiler evidence

Focused record-definition spelling evidence:

`.artifacts/research/declarative-query-record-column-definition-spelling-probe-2026-09-21/PROBE_REPORT.md`

Prompt SHA-256:

`a101a42dc7de5d4ea2dfb5be4536474bede0e68251441879ad17dd085620cc4c`

The probe proves on all four supported toolchains:

- standalone `ColumnDefinition` is technically clean but unnecessary;
- unconstrained bare `Column.definition` fails generic inference;
- `Column<Never>.definition` provides clean bare namespace lookup;
- ordinary model `Column<Value>` source remains unchanged;
- typed and ordinary `As` overloads coexist;
- empty definition builders reject compile time;
- model `Column<Int>` cannot enter the record-definition builder.

QUERY-RB-014 remains open only for JSON_TABLE column-grammar naming/ownership and final Frontier 06 closure.

Production implementation remains unauthorized.

## DESIGN-035 - `JSONTable` owns recursive SQL/JSON `COLUMNS` grammar through role-specific `Column` namespace members

`JSONTable` is a table-producing SQL/JSON construct with its own recursive `COLUMNS(...)` grammar. It is not a typed-record alias list, not an ordinary model-column list, and not a wrapper around Duck fixed-schema JSON table functions.

Canonical table-function source:

```swift
JSONTable(document, "$.favorites[*]") {
    Columns {
        Column.ordinality("id")
        Column.path("kind", .text, "$.kind")
    }
}
```

targets the exact SQL shape:

```sql
JSON_TABLE(
    document,
    '$.favorites[*]'
    COLUMNS (
        "id" FOR ORDINALITY,
        "kind" TEXT PATH '$.kind'
    )
)
```

### JSON_TABLE column roles live on the existing `Column` namespace

The accepted role-specific members are:

```swift
Column.ordinality("id")

Column.path("kind", .text, "$.kind")
Column.path("kind", .text) // PostgreSQL omitted-PATH form

Column.exists("hasDirector", .boolean, "$.director")
Column.exists("hasDirector", .boolean) // PostgreSQL omitted-PATH form
```

They use the same constrained namespace mechanism as DESIGN-034:

```swift
extension Column where Value == Never { ... }
```

and return dedicated JSON_TABLE child values. They do not return `Column<Never>` and do not alter ordinary model `Column<Value>` construction.

`Column.definition(...)` remains a different grammar role for PostgreSQL anonymous-record definitions and is rejected inside JSON_TABLE `Columns { ... }`.

### Scalar path columns own SQL/JSON option grammar

Simple form:

```swift
Column.path("title", .text, "$.title")
```

Option-bearing form:

```swift
Column.path("title", .text, "$.title") {
    NullOnEmpty()
    ErrorOnError()
}
```

PostgreSQL-rich exact form may additionally compose DESIGN-027 option identities where the database grammar permits them:

```swift
Column.path("title", .text, "$.title") {
    FormatJSON(.utf8)
    WithWrapper(.conditional)
    KeepQuotes()
    EmptyArrayOnEmpty()
    ErrorOnError()
}
```

`FormatJSON()` means `FORMAT JSON`; `FormatJSON(.utf8)` means `FORMAT JSON ENCODING UTF8`.

Option-state composition is typed. Duplicate mutually exclusive options and representative invalid ordering are rejected structurally rather than repaired after rendering.

### EXISTS columns use a distinct role

Canonical form:

```swift
Column.exists("hasDirector", .boolean, "$.director") {
    FalseOnError()
}
```

Other exact DESIGN-027 error behaviors remain available where supported:

```swift
TrueOnError()
UnknownOnError()
ErrorOnError()
```

Do not represent EXISTS columns as scalar path columns with a boolean return type; the SQL grammar role is distinct.

### NestedPath directly owns its nested column body

Canonical nested form:

```swift
NestedPath("$.films[*]") {
    Column.path("title", .text, "$.title")
    Column.path("director", .text, "$.director")
}
```

The trailing closure itself is the body of SQL `COLUMNS(...)`; no redundant inner `Columns { ... }` wrapper is introduced.

Nested paths recurse structurally:

```swift
NestedPath("$.films[*]") {
    Column.path("title", .text, "$.title")

    NestedPath("$.actors[*]") {
        Column.path("actor", .text, "$.name")
    }
}
```

An empty nested body is invalid.

PostgreSQL path naming remains available as secondary metadata:

```swift
NestedPath("$.films[*]", as: "films") {
    Column.ordinality("position")
    Column.path("title", .text, "$.title")
}
```

The ordinary `as:` argument label is appropriate here because the path name is secondary to the required path argument and primary trailing body.

### Top-level `JSONTable` builder owns one required `Columns` clause

PostgreSQL-rich form:

```swift
JSONTable(document, "$.favorites[*]", as: "root") {
    Passing(filter, as: "filter")

    Columns {
        Column.ordinality("id")
        Column.path("kind", .text, "$.kind")

        NestedPath("$.films[*]", as: "films") {
            Column.path("title", .text, "$.title") {
                KeepQuotes()
                NullOnEmpty()
                ErrorOnError()
            }

            Column.exists("hasDirector", .boolean, "$.director") {
                FalseOnError()
            }
        }
    }

    ErrorOnError()
}
```

The top-level state owns, in exact grammar order:

- optional PostgreSQL `PASSING` items;
- exactly one required non-empty `Columns { ... }` clause;
- supported top-level error behavior;
- optional PostgreSQL path-name `as:` metadata.

Repeated `Columns`, missing/empty `Columns`, `Passing` after `Columns`, and repeated top-level ON ERROR behavior are invalid.

### Ordinary alias `Columns { ... }` remains a separate overload family

Name-only alias columns keep their existing identity:

```swift
AliasColumnsOwner {
    Columns {
        ColumnName("a")
        ColumnName("b")
    }
}
```

JSON_TABLE simultaneously uses:

```swift
JSONTable(document, path) {
    Columns {
        Column.ordinality("id")
    }
}
```

Compiler evidence proves both public `Columns { ... }` families coexist without ambiguity because their trailing-builder child types are disjoint.

Do not rename one to `JSONColumns` merely to simplify implementation.

### Dialect capability stays exact

PostgreSQL and MySQL share the major JSON_TABLE column-role families: ordinality, scalar path columns, exists columns, and nested paths.

PostgreSQL additionally exposes richer SQL/JSON options including `PASSING`, path naming, `FORMAT JSON`, wrapper/quotes behavior, omitted PATH forms, and top-level error grammar according to its documented capability.

MySQL must not inherit unsupported PostgreSQL-only options merely because the Swift owner names are shared.

Duck `json_each` / `json_tree` remain separate fixed-schema table functions and are never mapped to `JSONTable`.

### No early erasure or namespace leakage

Ownership-sensitive transitions are decided while concrete child/state types remain available.

Storage may erase completed column children after successful builder acceptance, but no early erasure is required to decide role/order validity.

`Column<Never>` does not appear in downstream spelling or ABI-facing child identities; users write only `Column.ordinality`, `Column.path`, `Column.exists`, and `Column.definition`.

### Stable compiler evidence

Focused JSON_TABLE source-shape evidence:

`.artifacts/research/declarative-query-json-table-column-spelling-probe-2026-09-21/PROBE_REPORT.md`

Prompt SHA-256:

`906d71fd60325aaa1428c83a88ddc0ae5608c9a182bb23765b855d5069b9f1db`

The probe returns `JSON_TABLE_STRONG_PASS` across Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Swift 6.4:

- all frozen namespace members compile cleanly;
- scalar/exists option builders compile and reject representative invalid combinations/orderings;
- recursive `NestedPath` composes without a nested `Columns` wrapper;
- top-level JSONTable ownership positives/negatives are compile-time structural;
- ordinary alias `Columns { ... }` coexists without ambiguity;
- DESIGN-034 typed `As` continues to coexist;
- model `Column<Value>` and `Column.definition` roles remain rejected inside JSON_TABLE columns.

### Typed Record / Table-Function Frontier 06 closure

Typed Record / Table-Function Frontier 06 is architecture-complete under DESIGN-034 and DESIGN-035.

QUERY-RB-014 is closed.

Production implementation remains unauthorized. Only the aggregate-extensibility decision QUERY-RB-019 remains open before the declarative-query architecture can enter implementation-plan freeze.

## DESIGN-036 - `Fn.aggregate` is the narrow generic aggregate-call extension point

The generic downstream/custom aggregate extension path is a dedicated aggregate-call primitive on the existing `Fn` namespace.

Canonical direct form:

```swift
Fn.aggregate(.custom("weighted_sum")) {
    value
    weight
    OrderBy(timestamp, .desc)
}
```

with a downstream function identity:

```swift
extension Fn.Name {
    static let weightedSum: Self = .init("weighted_sum")
}

Fn.aggregate(.weightedSum) {
    value
    weight
}
```

`Fn.aggregate` enables DESIGN-025 aggregate-argument grammar for exactly the supplied function identity. It does not assert that the selected database actually defines that function or permits every aggregate modifier combination.

### Public builder infrastructure is narrow and reusable

The accepted reusable public infrastructure is conceptually:

```swift
@resultBuilder
public enum AggregateArgumentBuilder { ... }

public struct AggregateArguments { ... }

extension Fn {
    public static func aggregate(
        _ fn: Name,
        @AggregateArgumentBuilder _ body: () -> AggregateArguments
    ) -> SQLable
}
```

`AggregateArgumentBuilder` and `AggregateArguments` are public because downstream packages may expose first-class SQL-shaped wrappers using the exact same grammar.

Ordinary aggregate call sites do not name either type.

Implementation-specific builder state carriers may need public visibility for cross-module result-builder compilation, but they must remain nested implementation details and must not appear in downstream wrapper signatures or ordinary call sites.

### Downstream packages can keep first-class SQL-shaped helpers

A downstream package may define:

```swift
extension Fn.Name {
    static let weightedSum: Self = .init("weighted_sum")
}

extension Fn {
    static func weightedSum(
        @AggregateArgumentBuilder _ body: () -> AggregateArguments
    ) -> SQLable {
        aggregate(.weightedSum, body)
    }
}
```

and expose:

```swift
Fn.weightedSum {
    value
    weight
    OrderBy(timestamp, .desc)
}
```

Compiler evidence proves the builder closure can be forwarded directly as `aggregate(.weightedSum, body)` across all supported Swift toolchains.

No extra `aggregate(_:_: AggregateArguments)` overload is required solely for forwarding.

### Built-in aggregates reuse the primitive without changing call sites

Built-ins remain SQL-shaped and first-class:

```swift
Fn.arrayAgg {
    Order.$id
    OrderBy(Order.$createdAt, .desc)
}

Fn.stringAgg {
    Order.$label
    separator
    OrderBy(Order.$createdAt, .asc)
}
```

Those builder overloads may delegate internally to `Fn.aggregate(.arrayAgg, body)` / `Fn.aggregate(.stringAgg, body)`.

The generic primitive is an implementation/extensibility foundation, not the preferred spelling for known built-ins.

### `Fn.build` remains universal scalar/raw function construction

Existing low-level forms remain unchanged:

```swift
Fn.build(.custom("my_scalar"))
Fn.build(.custom("my_scalar"), body: ...)
```

`Fn.build` does not gain aggregate-result-builder overloads.

This separation prevents arbitrary scalar function construction from accidentally accepting aggregate-local DISTINCT / ORDER BY grammar.

### Generic aggregate grammar matches DESIGN-025

`Fn.aggregate` accepts the same structural aggregate-call grammar as built-in builder overloads:

- zero or more ordinary regular arguments;
- multiple ordinary arguments in source order;
- plain aggregate `Distinct` owning the complete regular-argument list;
- aggregate-local `OrderBy` after the regular argument list, with no comma before SQL `ORDER BY`;
- complete runtime `if/else` ownership switching between plain and DISTINCT argument modes;
- explicit star grammar;
- zero-direct-argument aggregate calls where the selected function genuinely permits them.

Representative calls:

```swift
Fn.aggregate(.custom("pair_agg")) {
    Distinct {
        a
        b
    }
}

Fn.aggregate(.custom("zero_agg")) {
}

Fn.aggregate(.custom("my_count")) {
    SQL.asterisk
}
```

The generic primitive does not maintain a registry of function names, arities, or dialect capabilities.

### Structural grammar negatives are typed

The builder state machine structurally rejects representative invalid ownership:

- ordinary argument after aggregate-local `OrderBy`;
- ordinary sibling arguments mixed with a sibling plain `Distinct` owner;
- repeated `Distinct` owners;
- aggregate-local `OrderBy` inside the `Distinct { ... }` argument-list body.

Dynamic branches choose a complete argument-ownership mode before later aggregate-local ordering is attached.

No previous-token scanning or rendered-SQL analysis is allowed.

### Legacy `Distinct(on:)` remains a same-type semantic-mode exception

Released compatibility has plain `Distinct(...)` and PostgreSQL `Distinct(on: ...)` as one nominal `Distinct` type.

Therefore a result builder cannot distinguish those two initializer modes at compile time without breaking the nominal compatibility surface or adding a phantom generic parameter.

The aggregate builder must instead preserve a semantic mode on `Distinct` itself and reject `Distinct(on:)` during aggregate semantic validation before rendering:

```text
plain argument-list DISTINCT -> accepted
DISTINCT ON mode           -> rejected
```

This validation must inspect stored semantic identity only. It must never inspect already-rendered tokens or SQL strings.

This documented legacy same-type exception does not weaken the typed ownership of the rest of the aggregate grammar.

### Aggregate result is an ordinary expression

`Fn.aggregate` returns ordinary `SQLable` expression composition.

Existing/future postfix owners continue normally:

```swift
Fn.aggregate(.weightedSum) {
    value
    weight
}

Filter { predicate }
Over { PartitionBy(group) }
As("weighted")
```

`WITHIN GROUP` likewise remains an external expression continuation under DESIGN-025 rather than becoming part of `AggregateArgumentBuilder`.

### Stable compiler evidence

Focused aggregate-extensibility evidence:

`.artifacts/research/declarative-query-aggregate-extensibility-probe-2026-09-21/PROBE_REPORT.md`

Prompt SHA-256:

`f0d42f822dfb21a1dccfc07eba560e52cf9e1bb617f720ae99ed8b488bd234fc`

The probe returns `AGG_EXT_STRONG_PASS` across Swift 6.2.3, Xcode/Swiftly Swift 6.3.3, and Swift 6.4:

- 48 positive matrix checks pass;
- 16 representative grammar negatives reject at compile time;
- `Fn.build` coexistence is clean;
- downstream stored/computed `Fn.Name` identities both compile;
- direct downstream builder-closure forwarding compiles without a fallback overload;
- built-in wrapper reuse is clean;
- zero-argument/star/dynamic DISTINCT ownership forms compile;
- aggregate result composes as an ordinary expression;
- the legacy `Distinct(on:)` limitation is distinguishable through stored semantic mode without token scanning.

### Aggregate Extensibility Frontier 07 closure

Aggregate Extensibility Frontier 07 is architecture-complete under DESIGN-036.

QUERY-RB-019 is closed.

All declarative-query architecture decisions tracked in `OPEN_DECISIONS.md` are now closed.

Production implementation remains unauthorized. The next phase is a frozen implementation plan covering the complete accepted declarative-query architecture, followed by an independent Sol plan audit before any production source mutation.

## DESIGN-037 - SQL preserves fragment-first composition; the database owns whole-statement validity

This decision restores and makes explicit the original fragment-first composition philosophy established under SwifQL and now carried by SQL. It supersedes any conflicting requirement elsewhere in this document that makes `SQL { ... }` prove whole-statement SQL grammar, clause ordering, or statement completeness at Swift compile time.

`SQL { ... }` is a SQL composition root, not a complete-statement validator. Its result may be a complete executable statement or any meaningful SQL fragment. A fragment does not need to be independently executable by a database.

Canonical composition:

```swift
let activeUsers = SQL {
    Where { User.$isActive == true }
}

let paging = SQL {
    Limit(20)
    Offset(40)
}

let query = SQL {
    Select {
        User.$id
        User.$email
    }
    From { User.table }
    activeUsers
    paging
}
```

The independent fragments render as `WHERE "User"."isActive" = TRUE` and `LIMIT 20 OFFSET 40`; together they compose the corresponding SELECT/FROM/WHERE/LIMIT/OFFSET text.

### Specialized builders own local rendering, not whole-query validation

A specialized builder owns only the mechanics needed to render its own body truthfully: projection/source/order separators, predicate `AND` composition, parentheses, and equivalent local structure. Its children may come from variables, functions, loops, conditionals, or reusable values whenever their type is meaningful for that builder.

For example:

```swift
let fields: [SQLable] = [User.$id, User.$email]
let predicates: [SQLable] = [User.$isActive == true, User.$age >= 18]
let sorting: [OrderByItem] = [.desc(User.$createdAt)]

SQL {
    Select { for field in fields { field } }
    From { User.table }
    Where { for predicate in predicates { predicate } }
    OrderBy { for item in sorting { item } }
}
```

Local type distinctions may remain when they are necessary for deterministic rendering, safety, or unambiguous ownership inside that construct. They must not exist merely to reject a larger SQL composition because SQL predicts that a database would reject its placement or ordering.

### Whole-statement clause order is intentionally representable

This is valid SQL source:

```swift
SQL {
    Select { User.$id }
    Limit(10)
    Where { User.$isActive == true }
}
```

and should faithfully compose:

```sql
SELECT "User"."id"
LIMIT 10
WHERE "User"."isActive" = TRUE
```

even if the selected database later rejects it. Reusable fragments may likewise be assembled in any order. Database/parser/driver validation owns whole-statement SQL validity.

This freedom must not require prior erasure to `SQLable`; direct declarative composition follows the same fragment-first principle.

### Compiler contracts protect Swift/API invariants, not SQL validity

Compile-negative tests are appropriate only for real Swift/API contracts or local construct invariants required for deterministic rendering, safety, or unambiguous ownership. They must not freeze:

- a clause being the first child of `SQL { ... }`;
- a partial query fragment that is not independently executable;
- whole-statement clause ordering or completeness;
- cross-dialect SQL validity that can truthfully be represented and rendered.

Therefore previous assumptions that `Where`, `GroupBy`, `Having`, `Qualify`, `OrderBy`, `Limit`, or `Offset` have no standalone/root fragment ingress are superseded. Statement-order negatives such as `HAVING -> WHERE` or `QUALIFY -> HAVING` are likewise superseded when their only rationale is whole-statement validity.

More generally, earlier typed-current rules in DESIGN-028/030/032 and related implementation evidence remain authoritative only for local composition semantics that survive DESIGN-037. They are not authority for rejecting otherwise renderable SQL fragments or statement permutations.

The same rule applies inside SQL-shaped value/DML builders when rendering is deterministic. `Row`, `Values`, `Default`, and `Insert` must not reject emptiness, differing row arity, standalone/default placement, clause order, or incompleteness merely to predict database validity. Structural safety rules remain valid when they protect a different contract, such as ensuring an identifier-list child is actually representable as an identifier rather than silently treating an arbitrary value expression as a name.

### Implementation consequence

The declarative result-builder implementation must be simplified or widened wherever necessary to preserve maximal fragment composition. Existing rendering, binding order, identifier safety, structural-frame behavior, and dialect-specific preparation semantics remain protected.

Any current implementation plan, compiler-contract candidate, or audit that assumes whole-statement compile-time grammar enforcement must be re-adjudicated against DESIGN-037 before staging or commit.
