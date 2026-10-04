# Development Orchestration

Model-independent authority for coordinating SQL repository work with LLMs or other implementation executors.

This file owns **roles, delegation, review, and gates**. Detailed `.artifacts/**` structure and task/report mechanics are owned by `ARTIFACTS_WORKFLOW.md`.

## Roles

### Coordinator / Reviewer

For non-trivial work, the stronger reasoning/review layer:

- restores current context from real Git, source, and stable docs;
- performs or directs focused research;
- designs and independently audits the implementation plan;
- surfaces unresolved architecture/API decisions to the maintainer before implementation;
- rejects implementation-driven architecture: green tests, executor convenience, or an existing prototype never outrank DESIGN-001/015, compatibility, or clean implementation requirements;
- decomposes substantial work into numbered surgical task files;
- gives the implementation executor only a short coordinator prompt;
- independently inspects actual source, diff, Git state, and validation after execution;
- turns audit findings into focused correction task files;
- synchronizes durable stable documentation after accepted work;
- performs the lazy public-content capture check after meaningful work and appends only genuinely valuable README/docs/publication material to the relevant `PUBLIC_CONTENT_IDEAS.md` shard while the context is fresh;
- keeps commit and push as separate explicit gates.

Executor reports are evidence, never proof.

### Implementation Executor

The executor implements an already-reviewed task contract:

- reads the next numbered task immediately before work;
- modifies only its explicit scope/allowlist;
- follows closed mechanics without redesigning architecture;
- stops rather than inventing a workaround, temporary bridge, compatibility unwrap, duplicate state, hidden routing layer, raw SQL escape, or other smell when the reviewed task cannot be implemented cleanly as written;
- runs required validation and inspects the actual diff;
- appends execution evidence;
- continues automatically to the next already-approved task after PASS;
- stops the whole run on a genuine out-of-scope blocker.

The executor does not broaden scope merely to keep moving.

## Default Flow

```text
verify current repository state
→ focused research
→ reviewed plan
→ independent plan audit
→ numbered surgical task files
→ short coordinator prompt
→ autonomous sequential execution + append-only evidence
→ independent source/diff/Git audit
→ numbered correction wave if needed
→ independent re-audit
→ durable-doc synchronization
→ explicit commit gate
→ explicit push gate when requested
```

For non-trivial iterative work, `ARTIFACTS_WORKFLOW.md` externalizes this flow under `.artifacts/**`.

## Delegation Rule

Never send an implementation executor one huge prompt containing several independent behaviors or a full correction audit.

Instead:

1. group work into tightly coupled, independently verifiable behaviors;
2. put detailed mechanics, allowlists, validation, compatibility rules, and stop conditions into numbered task files;
3. give the executor one compact `COORDINATOR_PROMPT.md` that lists those files and the autonomous task loop.

If the coordinator prompt starts duplicating task details, fix the decomposition before execution.

## Planning Gate

Non-trivial production work requires reviewed planning when it crosses multiple files/owners or changes public API, SQL semantics, dialect behavior, preparation/binding, builders, concurrency, package/toolchain behavior, or compatibility boundaries.

The plan must be grounded in current source/Git/dependency facts and must first prove that the proposed architecture satisfies SQL-first DESIGN-001, composition-invariant DESIGN-015, established-user compatibility, the repository's no-workaround policy, and DESIGN-019 whenever shared under-the-hood dialect/rendering/preparation/composition infrastructure changes. For DESIGN-019 work, the coordinator must explicitly compare the semantic requirement across affected supported dialects, likely adjacent unimplemented constructs, and representative major external dialect families before freezing the shared primitive's name, type shape, policy domain, or extension hook. It must then close:

- scope/non-goals;
- ownership and SQL/API semantics;
- allowed/forbidden mutation paths;
- compatibility constraints;
- relevant concurrency/lifecycle constraints;
- validation and native/live database evidence when applicable;
- stop conditions.

Known plan defects are corrected before implementation.

## Independent Audit

After executor work, independently inspect:

- complete Git status and changed paths;
- actual changed/created source and direct callers;
- relevant architecture/ownership boundaries;
- for any new shared dialect/rendering/preparation primitive, DESIGN-019 evidence that the abstraction remains reusable across affected supported dialects and representative external dialect families rather than encoding the triggering dialect too narrowly;
- public API and legacy source compatibility;
- generated SQL fidelity and binding order where applicable;
- package/dependency changes;
- forbidden/deferred scope;
- actual validation evidence;
- every independently confirmed dangerous case/blocker is protected by a durable regression test or the correct higher-fidelity fixture (external consumer, native database fixture, compile-time overload probe) before the finding is closed, including meaningful positive/negative sibling cases rather than only the first reproduction.

If defects remain, create a new focused numbered correction wave instead of one large correction prompt. A correction that changes production behavior but leaves its confirmed failure mode unprotected by regression evidence is not audit-complete and must not open the commit gate.

## Prompt Rules

Agent/executor prompts are written in English unless the maintainer explicitly requests otherwise.

Every prompt should identify the repository/context, role, exact scope or task files, mutation permissions, Git prohibitions, stop conditions, and expected evidence.

Do not make prompts self-contained by duplicating large task files. For artifact-driven execution, self-containment means the prompt explicitly points to the authoritative local task artifacts the executor must read.

## Context Discipline

Do not bulk-load all task files into coordinator/executor context.

- Coordinator/reviewer loads only the artifacts, stable owners, and source needed for the current planning/audit step.
- Executor reads the next numbered task immediately before executing it.
- `PUBLIC_CONTENT_IDEAS.md` and its shards are not normal development context. Perform the capture check from memory/current work first; open the router plus one relevant shard only when the check is positive or the current task is explicitly public documentation/content work.
- Operational docs do not consume architecture-owner slots; architecture loading remains governed by `CONTEXT_LOADING_RULES.md`.

## Git Gates

Implementation remains unstaged unless the maintainer explicitly authorizes staging/commit scope.

Normal implementation tasks forbid staging, commit/amend, merge/rebase/reset/restore/clean/stash, branch mutation, push, unrelated fixes, and history rewriting.

Commit and push are separate phases governed by `COMMIT_RULES.md` and explicit maintainer authorization.

Good intermediate results may be committed when the maintainer explicitly authorizes that checkpoint and its exact scope. Such commits are versioning checkpoints, not permission to broaden the task or push.

## Disposable Working Memory

`.artifacts/**` may be deleted or absent on another machine. Stable workflow/architecture must remain recoverable from `AGENTS.md`, `.agent/**`, Git, source, and current maintainer instruction.

Use `ARTIFACTS_WORKFLOW.md` for artifact structure, `NEW_CHAT.md` reconstruction, task/report conventions, correction waves, and promotion of durable facts back into stable docs.
