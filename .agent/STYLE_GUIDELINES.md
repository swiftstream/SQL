# Style Guidelines

These are common SQL Swift/source conventions, within the architecture owners routed by `ARCH_INDEX.md`.

## Compatibility and scope

- Preserve the existing public API and established PostgreSQL/MySQL behavior by default, including source composition, overload resolution, exact rendered SQL, bind ordering, and extension-oriented public protocols/hooks.
- Assume real users have large query inventories and private `extension SQLable`, custom operators, helper methods, path types, and dialect subclasses that this repository cannot inspect. Do not make them pay for an internal redesign with mass rewrites or debugging.
- Prefer additive changes for this established library. A major-version boundary permits unavoidable corrections, not gratuitous DSL churn.
- Keep new public surfaces narrow and use the least access level needed.
- Do not perform unrelated modernization, broad renaming, package-platform or language changes, or cosmetic repository-wide rewrites inside a feature task.

## Implementation shape

- Architecture, SQL semantics, and user-facing DSL/UX are authoritative before implementation details; tests validate an accepted implementation afterward.
- Prefer the existing architecture, focused extensions/files where natural, and direct readable control flow.
- Keep one semantic owner for each behavior or state.
- Choose a concrete implementation before introducing speculative protocols, factories, managers, semantic statement layers, or framework expansion.
- A workaround is not acceptable merely because it is localized or well tested. If a new abstraction forces compatibility unwraps, token reconstruction, duplicate state, temporary bridges, or special cases in unrelated established code, treat that as evidence against the abstraction and re-evaluate it.
- Describe the implementation as parts-based composition and runtime dispatch. Parser, AST, and tokenization are not the primary SQL implementation model. Focused semantic statement representation is an escalation tool only after verified grammar proves scoped ordinary parts cannot express the required structure cleanly.
- Use the project's real terminology consistently: `SQLable`, `SQLPart`, `QueryParts`, `SQLDialect`, `SQLPrepared`, and `SQLFormatter`.
- New public Swift symbols use SQL-shaped camelCase with position-aware abbreviation casing. Exact all-uppercase public callables are not a general style: they are permitted only as narrowly documented exceptions when a fundamental Swift language collision makes the normal SQL spelling and a clean namespace-member spelling impossible. The current accepted design has exactly one such exception, SQL `ANY` -> Swift `ANY`; it is compiler-validated across Swift 6.2.3, Xcode/Swiftly 6.3.3, and Swift 6.4. Neighboring non-conflicting `All` and `Some` stay in normal SQL casing. True abbreviations are lowercase when they begin a lowerCamelCase identifier and uppercase when medial: `json_build_array` -> `jsonBuildArray`, `from_json` -> `fromJSON`, `jsonb_typeof` -> `jsonbTypeOf`, `to_jsonb` -> `toJSONB`, `read_csv` -> `readCSV`, `to_tsvector` -> `toTSVector`, `concat_ws` -> `concatWS`. `Id` is the explicit project-wide exception and an absolute naming rule for Swift identifiers in this repository: use `id` leading and `Id` medial, **never `ID` anywhere in a Swift identifier** (`accountId`, `userId`, `groupId`, never `accountID`, `userID`, `groupID`). The rationale is the word `Identifier`, not an `IDentifier` initialism. This rule applies to public API, internal source, examples, tests, docs code samples, generated names under project control, and future migration work; exact external SQL/database spellings remain unchanged when the database itself owns the identifier text. Ordinary fragments such as `str`/`pos` remain normal camelCase (`strPos`, `subStr`), while compounds such as `recordset`, `regexp`, and `base64` become `recordSet`/`RecordSet`, `regExp`/`RegExp`, and `base64`/`Base64` by position. SQL-derived pieces are never translated into different English words. SQL spelling remains exact in generated SQL/internal function identities.
- Historical public noncanonical `Fn` symbols are compatibility surface only when release history requires preservation. The stable migration policy is to provide the SQL-shaped canonical counterpart with identical SQL behavior and keep an established old declaration as `@available(*, deprecated, renamed: "...")` delegating to that counterpart. This includes snake_case and other historical noncanonical spellings. Do not preserve an unreleased intermediate mistake merely to create compatibility debt.
- Public API naming, SQL transparency, convenience boundaries, dialect-specific-vs-generic choices, and developer-experience rules are owned by `architecture/DSL_DESIGN_AND_UX.md`; do not redefine them here.
- Result-builder UX strongly prefers a direct trailing closure when the closure is the primary semantic body. Avoid public DSL shapes like `Something(label: { ... })` when the label exists only to distinguish grammar roles: nested labeled-closure calls create punctuation noise and parenthesis stacking that obscures the SQL shape. Prefer moving that distinction into the callable/member name so the body stays trailing, e.g. `Array.items { ... }` rather than `Array(elements: { ... })`, and `Array.subquery { ... }` rather than `Array.sql(subquery: { ... })`. A labeled closure remains acceptable when it is genuinely secondary to other required arguments or Swift's type system leaves no comparably clear trailing-closure design.

## Dialect implementation reference

- For source organization and implementation shape, follow the PostgreSQL local precedent routed through `architecture/DSL_DESIGN_AND_UX.md`: focused dialect hooks, semantic-area source folders, direct typed-part composition, and clean SQL-shaped user-facing APIs.
- A construct being supported by only one current dialect does not by itself justify a database-prefixed public Swift name. Prefer dialect-transparent call sites and keep database identity in rendering/support ownership where possible.
- If a DuckDB-specific Swift implementation symbol genuinely needs a database prefix, use `Duck...` for types and `duck...` for functions/helpers, never new `DuckDB...` / `duckDB...` prefixes. The canonical public dialect spelling is `.duck`, e.g. `prepare(.duck)`. Reserve the exact `"duckdb"` spelling for actual database identity/internal ids and human-facing prose, not Swift API prefixes.
- Current official documentation for the target database remains the semantic source of truth; local PostgreSQL code is a style reference, not a semantic compatibility oracle.

## Comments and authority

- Comments explain non-obvious intent, invariants, or compatibility constraints; they do not narrate obvious code or attribute work to a coding agent.
- Generated or otherwise unreviewed code is not automatically maintainer-style authority.
