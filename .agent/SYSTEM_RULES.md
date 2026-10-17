# System Rules

These are the repository-wide invariants. Detailed architecture contracts belong to their single owners in `.agent/architecture/` and are routed by `ARCH_INDEX.md`.

## Evidence and planning

- Non-trivial work is gated by verified research, a detailed plan saved in `.artifacts/`, an independent plan audit, implementation, and independent repository audit.
- Stable documentation distinguishes verified current implementation from planned architecture.
- If a reviewed material assumption becomes false, stop the affected work and re-plan rather than improvising.

## Ownership and compatibility

- Every architecture ID has exactly one authoritative owner.
- Public-library changes are additive and backwards-compatible by default.
- Preserve existing PostgreSQL and MySQL source behavior, generated SQL, bind order, overload behavior, and normal query composition unless a separately approved bug-fix scope intentionally changes a specific contract.
- Treat downstream Swift extensions, custom operators/helpers, public-protocol conformances, and custom `SQLDialect` subclasses as real compatibility surface even though their source is not visible in this repository. Internal evolution must not force downstream users to debug or rewrite hundreds or thousands of established queries.
- A major release is not permission for gratuitous DSL breakage. If an internal redesign can preserve established user source, it must do so.
- Public DSL/API design must follow `architecture/DSL_DESIGN_AND_UX.md`: SQL-first vocabulary, transparent exact-SQL identities, dialect-transparent ordinary query source, and clearly named semantic conveniences.
- Architecture, semantics, and user-facing DSL quality are decided before implementation. Implementation quality is decided before tests are accepted as evidence. Green tests never legitimize a workaround, compatibility patch, speculative abstraction, hidden routing layer, or other architectural smell.
- Prefer the existing architecture, narrow APIs, and direct concrete implementation over speculative abstractions or framework expansion.
- Reuse existing composable SQL when it already expresses the target syntax clearly; do not create redundant builders or a parallel dialect mini-framework for symmetry.
- If a proposed implementation needs a special-case bridge only because another new layer changed established structural behavior, stop and reconsider the new layer instead of stacking another workaround on top.
- Do not perform opportunistic modernization, broad renaming, or unrelated cleanup outside approved scope.

## Documentation discipline

- Synchronize documentation selectively when an owned durable fact changes; do not duplicate another owner's contract.
- Stable repository authority lives in `.agent/`. Research, plans, evidence, task decomposition, and implementation history remain transient in `.artifacts/`.
- Reports and agent claims are evidence inputs, not proof; the actual repository state must be audited.
- Agent-created temporary Git branches, backup/rewrite refs, and linked/detached worktrees are prompt/task-scoped disposable state. Remove them before terminal completion once their recovery purpose is safely superseded by verified durable state/evidence; never delete pre-existing or user-owned Git resources. If safe removal cannot yet be proven, the terminal report must name the retained resource and its cleanup condition instead of silently leaving it behind.
