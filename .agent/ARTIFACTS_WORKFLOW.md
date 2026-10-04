# Artifacts Workflow

Stable operational authority for how SQL uses transient `.artifacts/**` working memory during research, planning, implementation, correction, audit, native validation, and chat handoff.

This file defines the **workflow around artifacts**. It does not make artifact contents authoritative over `AGENTS.md` or `.agent/**`.

## Core Principle

`.artifacts/**` is disposable working memory.

It exists to keep long iterative work precise without forcing one model prompt or one chat context to carry the entire task.

It may be deleted at any time, excluded from a new machine, unavailable in a clean clone, or intentionally rebuilt from current repository facts.

Therefore:

- stable rules and durable architecture never depend on `.artifacts/**` existing;
- `.artifacts/**` is ignored by Git;
- plans/reports/task files in `.artifacts/**` are evidence and execution instructions, not permanent product authority;
- after meaningful durable changes, synchronize the relevant stable `.agent/**` owner instead of relying on an artifact forever;
- if artifacts disappear, reconstruct only what is still supported by current Git/source/stable docs; never invent lost historical evidence;
- keep exactly one clearly active research/plan/task lineage for the current substantial objective. When a maintainer-authorized course correction invalidates an old lineage, remove or consolidate the obsolete artifacts instead of leaving multiple plausible executor entry points side by side;
- historical evidence worth preserving after such cleanup should be summarized into the smallest audit/rationale artifact that explains the invalidated path and durable facts. Do not keep obsolete task packages merely because they once passed their own audits.
- build products, dependency checkouts, package clones, disposable compiler workspaces, native build trees, index stores, caches, and other reproducible machine output are temporary execution material, not archival evidence. Keep them only while the active task actually needs them.
- before closing a substantial research/implementation/correction/validation lineage, capture the smallest textual result/manifests needed to preserve its conclusions, then remove reproducible `.build` trees, disposable workspaces, duplicated source/package snapshots, caches, and superseded raw-command directories.
- do not copy an existing `.artifacts` tree into another artifact workspace. If a disposable package/workspace needs source context, copy only the exact source/configuration inputs required for that probe.
- after a major release/closure, consolidate the few historical artifacts still worth retaining into one clearly named compact archive and refresh `NEW_CHAT.md`; completed handoff, retry, correction, planning, and executor packages must not remain as competing active lineages.

## Mandatory End-of-Prompt Cleanup

Every local execution agent must clean up its own disposable machine output before declaring a prompt complete, whether the prompt ended in PASS, BLOCKED, or another terminal result.

This cleanup is part of prompt completion, not an optional later maintenance task.

At minimum, before the final response the local agent must inspect the locations it used for temporary work and remove reproducible build/runtime residue that it created under:

- task/review/probe subdirectories inside `.artifacts/**`;
- `/tmp` and platform-equivalent temporary directories when the prompt created work there;
- disposable external workspaces, package clones, compiler/build trees, index stores, caches, temporary virtual environments, fixture repositories, generated dependency checkouts, and similar prompt-local machine output.

Preserve only the smallest textual evidence/manifests/logs intentionally required by the active artifact contract. Do not preserve large build products merely because they were generated during validation.

The default rule is:

```text
prompt-local + reproducible + disposable => delete before final response
```

The main exception is a build/cache directory intentionally created in the repository as reusable project state for later work, for example a root SwiftPM `.build/` that the project normally reuses. Do not delete such project-local reusable build state merely to satisfy cleanup. Conversely, a `.build/` nested inside `.artifacts/**`, `/tmp`, a disposable clone, or another prompt-local workspace is disposable and must be removed unless the maintainer explicitly asked to preserve it.

Cleanup must never use broad destructive commands against unknown paths. The agent must remove only paths it created or paths whose disposable ownership it has independently established. It must not delete user-authored evidence, unrelated temp data, reusable project caches, or untracked source merely because they are large.

Each executor/auditor prompt that can create substantial local build/temp output should restate this rule in its completion requirements so cleanup happens in the same local-agent run that created the data.

## Mandatory Use for Non-Trivial Iterative Work

For non-trivial development, especially multi-file, cross-cutting, public-API, dialect, preparation/binding, concurrency, package/toolchain, or compatibility work, use `.artifacts/**` to externalize context before implementation.

Preferred lifecycle:

```text
restore current repo context
→ focused research
→ write research evidence
→ write implementation plan
→ independently audit plan
→ decompose implementation into surgical task files
→ run implementation executor task-by-task
→ append execution evidence after every task
→ independently audit actual source/diff
→ create surgical correction task files when needed
→ validate again
→ synchronize durable docs
→ separate commit gate
```

Do not collapse a large researched implementation into one enormous executor prompt.

## Mandatory Large-Task Decomposition Rule

When implementation contains multiple natural behavior groups, multiple independent mutations, cross-owner work, or enough detail that a single executor prompt becomes long or cognitively dense, the coordinator MUST decompose it before asking an implementation executor to execute.

The implementation mechanics belong in numbered `.md` task files under `.artifacts/**`.

The executor receives one **short coordinator prompt** that only tells it:

- which repository to work in;
- which numbered task files to execute and in what order;
- to read each task immediately before executing it;
- to obey each task's allowlist/stop conditions;
- to append a report after every task;
- to continue automatically to the next task when the current task passes;
- to stop the entire run on an out-of-scope blocker rather than redesigning;
- not to stage/commit/push unless separately authorized.

The coordinator prompt must NOT duplicate the detailed requirements already stored in the task files.

### Practical split threshold

Split rather than sending one large implementation prompt whenever any of these is true:

- more than one independently verifiable behavior is changing;
- more than one subsystem/architecture owner is involved;
- implementation and validation requirements form several distinct phases;
- compatibility or concurrency corrections have more than one independent issue;
- the prompt would need long sections of detailed implementation mechanics;
- a failed middle step should prevent later work from executing.

Prefer too many precise tasks over one overloaded executor prompt, but do not create artificial one-line tasks that destroy locality. A task should represent one tightly coupled behavior group with one meaningful verification gate.

## Recommended Directory Structure

Use a task-specific slug rather than one global `PLAN.md` for substantial work.

```text
.artifacts/
├── NEW_CHAT.md
├── planning/
│   └── <work-slug>/
│       ├── RESEARCH_REPORT.md
│       ├── IMPLEMENTATION_PLAN.md
│       └── PLAN_AUDIT.md
├── implementation/
│   └── <work-slug>/
│       ├── 01-<task>.md
│       ├── 02-<task>.md
│       ├── ...
│       ├── EXECUTION_REPORT.md
│       └── COORDINATOR_PROMPT.md
├── corrections/
│   └── <work-slug>/
│       ├── 01-<correction>.md
│       ├── 02-<correction>.md
│       ├── ...
│       ├── EXECUTION_REPORT.md
│       └── COORDINATOR_PROMPT.md
├── reviews/
│   └── <focused-review>.md
└── patches/
    └── <temporary-patch-evidence>
```

Use only the directories/files needed by the current work. Do not manufacture empty bureaucracy.

## Planning Artifacts

### `RESEARCH_REPORT.md`

Stores verified implementation-time evidence needed to design the work, such as:

- relevant Git/source state;
- current APIs/types/ownership boundaries;
- dependency behavior;
- current external SQL/database/API documentation when time-sensitive;
- native database/runtime evidence when relevant;
- known constraints/unknowns;
- facts later implementation tasks must not rediscover from memory.

Research must distinguish verified facts from architectural conclusions.

### `IMPLEMENTATION_PLAN.md`

Contains the reviewed implementation design:

- exact goal/scope;
- ownership decisions;
- public API and SQL semantics;
- source topology;
- cross-boundary sequencing;
- compatibility/concurrency implications;
- validation strategy;
- explicit non-goals/deferred work.

It should be implementation-ready before an implementation executor receives any production mutation task.

### `PLAN_AUDIT.md`

Records the coordinator/reviewer's independent audit of the plan against actual source/governance/dependency/database facts.

Do not treat the plan as ready merely because the planning agent wrote it.

## Surgical Implementation Task Contract

Each numbered implementation/correction task file should contain only the context needed for that tightly coupled batch.

Use this shape when applicable:

```text
# Task NN - Title

## Goal
## Preconditions
## Allowed production paths
## Required implementation
## Compatibility / ownership rules
## Explicitly forbidden work
## Verification
## Completion report
## Stop conditions
```

Every task must make scope mechanically clear enough that the executor does not need to invent architecture.

Important:

- exact path allowlists are strongly preferred;
- state which earlier task output may be relied on;
- state what must be independently revalidated after external/native work when relevant;
- include the smallest meaningful build/test/rendered/native gate;
- if a task uncovers a plan contradiction requiring broader scope, it stops instead of silently widening scope.

## Autonomous Executor Loop

For a prepared multi-task implementation, the implementation executor follows this loop:

```text
read Task NN completely
→ inspect required current Git/source facts
→ implement only Task NN allowlist
→ run Task NN verification
→ inspect actual diff
→ append Task NN result to EXECUTION_REPORT.md
→ if PASS: immediately continue to Task NN+1
→ if BLOCKED: append blocker and stop entire run
```

The executor does not ask the maintainer for confirmation between already-approved numbered tasks.

This autonomous progression is the default reason to use task files: detailed mechanics stay local to the next step while the coordinator prompt stays small.

## `EXECUTION_REPORT.md`

Execution reports are append-only evidence.

After each task append a distinct section containing:

- actual paths changed;
- implementation facts;
- exact validation commands/results;
- generated SQL/native evidence when actually observed;
- Git state;
- deviations/blockers.

Never rewrite earlier task sections to make a failed/stopped attempt disappear. A resumed task appends a new clearly named section.

An executor report is never proof by itself. The coordinator/reviewer independently inspects actual source/diff/Git afterward.

## Correction Waves

After independent implementation audit, do not send a giant correction prompt containing every discovered defect.

Instead:

1. group findings into the smallest coherent correction behaviors;
2. create numbered files under `.artifacts/corrections/<work-slug>/`;
3. define exact allowlists and validation for each;
4. create/reset an append-only correction `EXECUTION_REPORT.md` for that wave;
5. give the implementation executor one short coordinator prompt pointing to those files;
6. let the executor run them sequentially and automatically;
7. independently audit the final source again.

If the correction audit discovers another materially distinct issue, create another focused correction wave rather than growing the old coordinator prompt.

## `COORDINATOR_PROMPT.md`

This file is intentionally compact.

It should contain orchestration only, not implementation detail already present in numbered tasks.

Minimum responsibilities:

```text
repository / role
baseline Git expectations
list of numbered task files
execute numerically
read one task immediately before work
append report after each task
continue automatically after PASS
stop on blocker
Git mutation prohibitions
compact final report shape
```

If `COORDINATOR_PROMPT.md` starts restating the detailed implementation requirements from every task, the decomposition has failed and must be corrected before execution.

## `NEW_CHAT.md` Purpose

`.artifacts/NEW_CHAT.md` is the transient continuity handoff for the **next coordinator/reviewer conversation**, not stable governance.

It should preserve enough current work context that a new chat can continue without repeating long prior conversations or accidentally reopening completed decisions.

Keep it updated after continuity-critical transitions, for example:

- branch/HEAD phase changes;
- accepted audit/correction verdicts;
- prerequisite completion;
- new active planning/implementation/correction artifact sets;
- important stop/blocker state;
- the exact next intended action;
- session/model/tool constraints that matter to continuation but do not belong as permanent repository governance.

Do not turn it into an ever-growing transcript. Replace/supersede stale continuation instructions with a current snapshot while preserving only historical rationale that remains useful.

## Recreating `.artifacts` on a New Machine or After Deletion

Because `.artifacts/**` is intentionally disposable, every future agent must be able to recover without it.

If `.artifacts/` or `NEW_CHAT.md` is missing:

1. read root `AGENTS.md` and the minimum stable `.agent/**` governance required for the task;
2. inspect current Git branch/HEAD/status directly;
3. inspect `TASKS.md`, `OPEN_DECISIONS.md`, `PROJECT_MEMORY.md`, `SOURCE_MAP.md`, and relevant architecture owners only as needed;
4. inspect the actual changed source and recent relevant Git history rather than guessing unfinished work;
5. identify the current work phase from repository evidence and maintainer instruction;
6. create `.artifacts/` directories only as needed;
7. create a fresh `.artifacts/NEW_CHAT.md` from **verified current facts**;
8. if non-trivial work is continuing, recreate a fresh research/plan/task artifact set rather than pretending deleted transient plans still exist;
9. never infer uncommitted/lost implementation evidence that is no longer present on disk.

A newly reconstructed `NEW_CHAT.md` should normally contain:

```text
repository identity/path used in this environment
current branch / HEAD / Git status
current milestone/work phase
stable governance and architecture owners relevant to continuation
verified completed/accepted work that materially constrains the next step
current uncommitted user/agent changes and preservation rules
active dependency/database/API facts needed by the work
current artifact index, if artifacts were recreated
next intended action
agent/orchestration rules required for continuation
```

Machine-local paths/tool context IDs are allowed in `NEW_CHAT.md` because it is transient, but stable `.agent/**` documentation must remain portable.

## Promotion to Stable Documentation and Public-Content Capture

At the end of an accepted implementation/correction cycle, decide what learned information is durable.

At the same continuity-critical checkpoints where `.artifacts/NEW_CHAT.md` is refreshed, also perform the lazy public-content capture check owned by `PUBLIC_CONTENT_IDEAS.md`. This does **not** mean opening the idea bank every time. First decide from the current work whether a genuinely useful README/docs/website/publication example, capability, migration note, validation result, or explanation appeared. Only on a positive result open the router plus one relevant shard and append the compact entry while its context is fresh.

`NEW_CHAT.md` and the public-content bank have different lifecycles: `NEW_CHAT.md` is transient/disposable execution continuity; `PUBLIC_CONTENT_IDEAS.md` and its shards are durable versioned candidate communication material.

Promote only durable facts/rules into the correct `.agent/**` owner:

- architecture rule -> owning architecture document;
- workflow rule -> `WORKFLOW.md`, `DEVELOPMENT_ORCHESTRATION.md`, `ARTIFACTS_WORKFLOW.md`, or `COMMIT_RULES.md`;
- source navigation fact -> `SOURCE_MAP.md`;
- durable current-state fact -> `PROJECT_MEMORY.md`;
- unresolved decision -> `OPEN_DECISIONS.md`;
- active executable work -> `TASKS.md`.

Do not promote execution diaries, transient commit hashes, local tool IDs, temporary error logs, or massive implementation reports.

## Intermediate Commit Checkpoints

Artifacts remain uncommitted, but accepted stable/source checkpoints may be committed when the maintainer explicitly authorizes the exact scope.

For long task waves, a clean intermediate commit after a verified behavior group can be useful versioning. It must happen only after the relevant task/report and independent audit gates pass, and it does not imply push authorization.

Later tasks must treat committed checkpoints as the new Git baseline rather than assuming one giant uncommitted working tree.

## Git Rule

`.artifacts/` must remain ignored by the repository `.gitignore`.

Do not stage/commit artifacts merely because they were useful during development. They are intentionally local/transient unless the maintainer explicitly changes this project policy.
