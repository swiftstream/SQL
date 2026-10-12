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
