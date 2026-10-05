# Context Loading Rules

This is the single owner of progressive context loading and the default context budget.

## Normal loading sequence

1. Read the root `AGENTS.md`.
2. For non-trivial iterative development/orchestration, load `DEVELOPMENT_ORCHESTRATION.md` and `ARTIFACTS_WORKFLOW.md` as operational authorities when their mechanics are needed. They do not consume architecture-owner slots and should not be loaded for routine architecture questions that do not involve execution workflow.
3. When starting/resuming a substantial roadmap item, feature wave, or major corrective effort, read `MASTER_PLAN.md` before transient `.artifacts` so a task lineage cannot silently override the stable course.
4. Use `.agent/ARCH_INDEX.md` to select one primary architecture owner.
5. For dialect work, load `architecture/DIALECT_RENDERING.md` plus exactly the relevant dialect owner under `architecture/dialects/` (`DUCK.md`, `POSTGRES.md`, or `MYSQL.md`). Treat this pair as one dialect architecture bundle for context-budget purposes. Do not load the other dialect owners unless the task is explicitly cross-dialect. A task that introduces or changes a shared under-the-hood dialect/rendering/preparation/binding/scope/ownership/composition primitive is explicitly cross-dialect under DESIGN-019: load the affected supported dialect owners and use bounded primary-source research for representative external dialect families only far enough to validate the shared abstraction shape; do not turn that check into broad speculative feature research.
6. For any task that creates or changes public SQL/DSL API, naming, dialect-specific-vs-generic boundaries, convenience semantics, composition behavior, or developer experience, load `architecture/DSL_DESIGN_AND_UX.md` before designing source changes. DESIGN-001 and DESIGN-015 are primary gates.
7. Outside the dialect bundle, load at most two supporting architecture owners when the task genuinely crosses their boundaries. In a normal focused dialect task, prefer only one additional architecture owner beyond the dialect bundle unless preparation mechanics force another.
8. Load `STYLE_GUIDELINES.md`, `SAFETY_RULES.md`, and/or `TESTING_RULES.md` only when the edit type needs those policies; policy documents do not consume architecture-owner slots.
9. Use `SKILL_INDEX.md` when a reusable operational procedure applies; load at most one skill by default.
10. Use `SOURCE_MAP.md` before broad source discovery, then inspect the smallest source/test subset needed. Use the PostgreSQL implementation as a local style reference only when `DSL_DESIGN_AND_UX.md` or the selected skill routes the task there; do not rediscover the whole repository by default.
11. Treat `PUBLIC_CONTENT_IDEAS.md` and `.agent/public-content-ideas/**` as lazy communication context, not normal development context. Do not load them merely because they exist. First perform the public-content capture check from the current work; only if positive, or if the task explicitly concerns README/public docs/website docs/release notes/articles/posts, load the router and exactly the relevant shard(s). For any task that actually writes or rewrites README, `MIGRATION.md`, `RELEASE_NOTES.md`, `CHANGELOG.md`, GitHub Releases, or maintainer-facing public posts, also load `PUBLIC_WRITING_STYLE.md`; it is the stable owner of example-first public prose and does not consume an architecture-owner slot. These files do not consume architecture-owner slots.
12. For work that actually pushes a release candidate, creates/pushes a release tag, validates a published tag remotely, or creates/verifies a GitHub Release, load `RELEASE_PUBLICATION.md`. Routine README/release-note editing does not load release mechanics merely because the text discusses a release. This operational owner does not consume an architecture-owner slot.
13. Treat external reference repositories as zero by default; route deliberate external evidence through `REFERENCE_PROJECTS.md`.
14. Stop loading when ownership, design contract, scope, and evidence are sufficient.

Cross-cutting governance or architecture audits may deliberately exceed this default budget. Resume focused loading afterward.