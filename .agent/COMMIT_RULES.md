# Commit and Git Preservation Rules

This file is the single stable owner of commit style and Git safety for repository work.

## Commit message style

Use the same concise semantic style established across the maintainer's Swift repositories: an emoji category prefix followed by a short imperative subject.

Preferred categories:

- `📖` documentation or governance
- `🧪` tests and test coverage
- `🛠` source fixes or corrective behavior changes
- `🪚` scoped feature implementation or migration
- `🧹` cleanup or removal
- `📦` package, toolchain, dependency, or manifest changes

Rules:

- Use imperative mood, not past tense.
- Keep the subject concise and describe one logical change.
- Name the concrete semantic change, capability, API, fix, document, or migration. Do not use a release/version umbrella, milestone, frontier, phase, integration status, or campaign name as a substitute for what changed.
- Version numbers belong in a commit subject only when the commit itself changes release/version metadata or another version-specific artifact. A feature commit should describe the feature; a documentation commit should describe the documentation truth it changes.
- Avoid vague subjects such as “advance implementation frontier”, “update integration status”, “add <major-version> foundation”, or “integrate <major-version> paths”. Prefer concrete subjects such as “add catalog-aware identifiers”, “qualify model database paths”, “add bind-aware raw interpolation”, or “document database qualification”.
- Do not repeat the current repository or project name in the subject when Git context already makes it obvious. Name it only when needed to distinguish an external project, dependency, artifact, or explicitly named API/domain concept.
- Wrap concrete type, function, property, protocol, and API symbol names in Markdown backticks when named in the subject.
- Do not add coding-agent attribution to commit messages.
- Do not put internal planning/execution identifiers or task names in commit subjects (`A1`, `A1.5`, `R1`, `Task 06`, `Correction 01`, audit/gate names, artifact lineage labels, and similar coordinator-only terminology). Describe the durable repository change instead. Use such an identifier only when it is itself a real public API/domain name or externally meaningful standard.
- Do not mix unrelated source, tests, governance, package changes, or cleanup in one commit merely because they were implemented in the same session.
- A documentation/governance closure commit may contain only the approved documentation/governance surface and directly related `.gitignore` changes.
- `.artifacts/**` is transient and must never be committed.

## Git safety

### Maintainer autopilot authorization

- PRIMARY GPT-5.6 Sol using CodexMCP2 is permanently authorized to stage and create local commits for an unambiguous, bounded, already-reviewed logical change without asking for per-commit confirmation.
- This standing authorization does not extend to push, tag, release publication, amend, rebase, merge, history rewrite, reset, restore, clean, stash, or unrelated user work.
- Push and tag always require separate explicit maintainer authorization.
- Secondary/Luna does not inherit this standing commit authority merely because PRIMARY is operating on autopilot.

- Check and record Git status before every mutating phase.
- After mutation, check status again and review the exact diff and changed-path set.
- Preserve unrelated staged, unstaged, and untracked user work.
- If an approved target already contains user edits, inspect its baseline diff and preserve those edits surgically.
- Never seek a clean working tree by destroying, restoring, or deleting user work.
- Outside the standing PRIMARY autopilot authorization above, do not stage, unstage, commit, amend, push, reset, restore, checkout user changes, clean, stash, rebase, merge, or rewrite history unless the maintainer explicitly authorizes that exact operation and scope.
- When a commit is explicitly authorized, include only the approved logical change and verify its exact path set before and after committing.
- Every implementation task declares its exact allowed mutation scope and forbidden paths.
- An unexpected conflicting edit in an approved target is a stop condition, not permission to overwrite it.

### Temporary Git resource cleanup

Temporary Git resources created by an agent are owned by that agent and are disposable unless the maintainer explicitly requests preservation. This includes temporary branches, backup refs, rewrite refs, linked worktrees, detached worktrees, and equivalent rewrite/recovery scaffolding.

- Before declaring a prompt/stage terminal, inspect both the local branch/ref set and the worktree set for resources created by the current work.
- Remove agent-created temporary resources as soon as their recovery purpose is safely superseded by verified durable state/evidence. Do not keep backup/rewrite refs or worktrees merely "just in case" after the accepted replacement is verified.
- For history rewrites, a temporary backup ref may exist only during the unsafe rewrite window. Once the rewritten chain is independently checked, required old/new identity/equivalence evidence is durably recorded, and the accepted branch points to the replacement chain, remove the rewrite worktrees, rewrite refs, and temporary backup refs before closure.
- Cleanup includes agent-created Git administrative residue for those temporary resources. If a low-level ref operation leaves a matching reflog or stale worktree metadata, remove that residue once the corresponding temporary resource is safely removable; do not leave hidden recovery scaffolding after declaring cleanup complete.
- Never delete or repurpose a branch, ref, tag, remote, worktree, or other Git resource that predates the current work or whose ownership is uncertain. User/pre-existing resources are preserved unless the maintainer explicitly authorizes their removal.
- If a temporary resource cannot yet be removed safely, do not silently leave it behind or call cleanup complete. Record its exact name/path, why it must remain, who/what still depends on it, and the concrete future cleanup condition in the terminal handoff.
- The final Git audit includes a temporary-resource census. Successful cleanup requires zero remaining agent-created temporary branches, refs, worktrees, and matching agent-created Git administrative residue. If any such temporary resource must remain, record its exact name/path, reason, dependency, and concrete cleanup condition in the terminal handoff, but do not claim cleanup complete or Git-hygiene readiness until it is removed.
