# Development Workflow

Non-trivial SQL work follows this ordered flow:

```text
DETAILED RESEARCH
-> DETAILED PLAN
-> SAVE PLAN INTO .artifacts
-> INDEPENDENT PLAN AUDIT
-> NUMBERED SURGICAL TASKS WHEN NEEDED
-> PRECISE IMPLEMENTATION
-> INDEPENDENT DIFF / SOURCE / GIT AUDIT
-> NUMBERED CORRECTION WAVE IF NEEDED
-> FINAL AUDIT
-> EXPLICIT COMMIT GATE
```

Detailed coordinator/executor roles and delegation rules are owned by `DEVELOPMENT_ORCHESTRATION.md`. Detailed `.artifacts/**` structure, task/report mechanics, `COORDINATOR_PROMPT.md`, `EXECUTION_REPORT.md`, and `NEW_CHAT.md` reconstruction are owned by `ARTIFACTS_WORKFLOW.md`.

## Gates

- Trivial typo or format-only work may skip a formal artifact plan, but it still requires scope and result verification.
- Non-trivial implementation cannot start directly from an unreviewed idea. Research must establish current behavior, scope, risks, and acceptance evidence before planning.
- Material unresolved API or architecture choices are surfaced to the maintainer after research; they are not delegated to the implementation executor.
- Public/API/core-composition work must pass the SQL-first DESIGN-001 gate and incremental-composition DESIGN-015 gate before implementation planning is considered complete.
- Any new shared under-the-hood rendering/preparation/binding/scope/ownership/composition primitive must also pass DESIGN-019 before implementation: research the semantic requirement across all affected supported dialects, likely adjacent not-yet-implemented constructs, and several major external SQL dialect families when useful; prove the primitive is named/shaped around a reusable grammar role rather than the dialect that first exposed the gap. This is a design gate, not permission to implement speculative features.
- The plan must explain why the proposed implementation is architecturally necessary and clean, not merely how to make it pass tests. Workarounds, speculative routing layers, compatibility unwraps, duplicate state, token-neighbor heuristics, and renderer-driven public wrappers are blockers unless their necessity is independently demonstrated and explicitly approved.
- Tests/native validation prove an accepted design after implementation; they never upgrade a smell into an accepted architecture merely by passing.
- The plan declares exact mutation scope, forbidden paths, compatibility constraints, downstream-extension risk, validation, and stop conditions.
- Broad or cognitively dense implementation/correction work is decomposed into numbered task files. The executor receives one short generic coordinator prompt and reads tasks one at a time.
- The executor appends evidence after every task, continues automatically after PASS, and stops the whole run on a genuine out-of-scope blocker.
- Validation starts with the smallest relevant check and expands with the change's risk and scope.
- Executor reports are evidence inputs, never proof of repository state. Independent review inspects the actual files, status, diff, direct callers, generated SQL/native evidence, and relevant tests.
- Audit findings become a new focused numbered correction wave rather than one giant correction prompt.
- Stable documentation is synchronized only when the durable fact owned by that document changes. Transient execution history remains in `.artifacts/`.
- After meaningful research/design/implementation/correction/audit, perform the lazy public-content capture check owned by `PUBLIC_CONTENT_IDEAS.md`. If no genuinely useful README/docs/publication material appeared, do not open the bank. If the check is positive, append only to the relevant shard before leaving the context where the example/reasoning is fresh.
- Accepted intermediate stable/source checkpoints may be committed when the maintainer explicitly authorizes the exact scope; later work treats that commit as the new baseline.
- Git behavior, preservation, staging, commit, and push authorization are owned by `.agent/COMMIT_RULES.md`.
