# Architecture Index

This is the authoritative architecture router and ID-family map. Every architecture ID has exactly one owner; supporting documents link to that owner instead of duplicating its full rules.

## Architecture owners

| ID family | Sole owner | Concept |
| --- | --- | --- |
| `DESIGN-*` | `architecture/DSL_DESIGN_AND_UX.md` | public DSL design, SQL fidelity, API taxonomy, discoverability, and developer experience |
| `DSL-*` | `architecture/DSL_COMPOSITION.md` | composable DSL and part-level composition |
| `PREP-*` | `architecture/QUERY_PREPARATION.md` | preparation dispatch, value collection, prepared output, and formatter boundary |
| `DIALECT-*` | `architecture/DIALECT_RENDERING.md` | cross-dialect identity, hook architecture, bind ownership, contextual rendering, and hybrid selection |
| `DUCK-*` | `architecture/dialects/DUCK.md` | Duck-specific rendering, support matrix, UX/naming, native evidence, and pre-release blockers |
| `POSTGRES-*` | `architecture/dialects/POSTGRES.md` | PostgreSQL-specific rendering and compatibility facts |
| `MYSQL-*` | `architecture/dialects/MYSQL.md` | MySQL-specific rendering and compatibility facts |
| `BUILD-*` | `architecture/BUILDERS_AND_QUERY_PARTS.md` | builders and `QueryParts` materialization |

Do not create placeholder architecture chunks merely for symmetry. Dialect-specific owners are an explicit exception because each supported dialect is an independent, progressively loadable compatibility domain. A compact dialect seed is allowed when it records verified current facts plus a clearly marked future-audit boundary. Never duplicate one rule under both `DIALECT-*` and a dialect-specific ID family.

## Task routing

- New public SQL/DSL API, naming, UX, portability boundary, convenience behavior, or dialect-specific-vs-generic API choice: `DSL_DESIGN_AND_UX.md` primary; load the mechanism owner as supporting context.
- New `SQLable`, `SQLPart`, or composition primitive with an already-decided public contract: `DSL_COMPOSITION.md` primary; `DSL_DESIGN_AND_UX.md` supporting when public API shape is involved; `QUERY_PREPARATION.md` supporting only when dispatch changes.
- New concrete part requiring preparation dispatch: `QUERY_PREPARATION.md` primary; `DSL_COMPOSITION.md` supporting.
- Dialect or new-database rendering: load `DIALECT_RENDERING.md` plus exactly the relevant dialect owner (`dialects/DUCK.md`, `dialects/POSTGRES.md`, or `dialects/MYSQL.md`). Treat that pair as the dialect architecture bundle. Add `DSL_DESIGN_AND_UX.md` only for API/UX/support-contract decisions and `QUERY_PREPARATION.md` only when dispatch/value mechanics change, with `TESTING_RULES.md` as policy. Cross-dialect audits may deliberately load multiple dialect owners.
- Formatter, bind-marker traversal, or value-order behavior: `QUERY_PREPARATION.md` primary; `DIALECT_RENDERING.md` supporting when placeholder syntax changes.
- Builder or `QueryParts` behavior: `BUILDERS_AND_QUERY_PARTS.md` primary; `DSL_DESIGN_AND_UX.md` supporting for new public builder UX; `DSL_COMPOSITION.md` supporting for part composition.
- A function that only composes existing parts: route public API/name/grammar decisions to `DSL_DESIGN_AND_UX.md`; use `DSL_COMPOSITION.md` for the composition mechanics. It does not receive a new architecture owner.
- Tests only: route to the owner of the behavior under test, with `TESTING_RULES.md` as policy.

## Supporting governance and context budget

Operational development authorities are routed separately from technical architecture owners:

- Workflow phases/gates: `WORKFLOW.md`.
- Model-independent coordinator/reviewer and implementation-executor orchestration: `DEVELOPMENT_ORCHESTRATION.md`.
- Disposable `.artifacts/**` research/plan/task/report/handoff workflow: `ARTIFACTS_WORKFLOW.md`.
- Git safety: `COMMIT_RULES.md`.
- Progressive loading: `CONTEXT_LOADING_RULES.md`.
- Source navigation: `SOURCE_MAP.md`.
- Lazy durable README/docs/website/publication idea capture: `PUBLIC_CONTENT_IDEAS.md` plus focused `.agent/public-content-ideas/**` shards. Do not load during ordinary development unless the capture check is positive or the task is explicitly public-content work.
- Source/value/testing policy: `STYLE_GUIDELINES.md`, `SAFETY_RULES.md`, and `TESTING_RULES.md`; these do not own architecture IDs.

Operational orchestration/artifact/public-content owners do not consume architecture-owner slots.

Normal work loads one primary owner and at most two supporting architecture owners. Dialect work uses one explicit context-budget bundle: `DIALECT_RENDERING.md` plus exactly one relevant dialect-specific owner, then at most the genuinely necessary supporting owners. Cross-cutting audits may be explicit exceptions.
