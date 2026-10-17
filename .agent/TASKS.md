# Active Tasks

This file contains only approved current work. Ideas, unresolved choices, verified debt, and completed history belong in their separate owners.

## Current: 3.0.0 documentation and release closure

SQL `2.2.0` is the current published stable release. Its immutable release commit is `8567f99216bec49952bbe735959c34d5cce445c1`, published under annotated tag `2.2.0` (tag object `055e9090eaa5d9ce2944ae23d28ddff794fa3225`) with GitHub Release `🧩 SQL 2.2.0`. Later `master` development does not redefine that release point.

Version `3.0.0` is the active unreleased objective. Its accepted major-version contract is owned by `.agent/architecture/SQL_3.md`. No standalone `2.3.0` is planned.

Product implementation is locally complete and independently validated:

- catalog/schema qualification: `de2b9b471fa9c3f036e1e9a3b3cf26977d1d7136` — `🪚 Add catalog and schema qualification`;
- atomic qualified key paths: `4e9ab096e0299328ffbdf3aa5a6ac24ea2b8bcf9` — `🪚 Add atomic qualified key paths`;
- model/manual structural `DB.*` migration: `b954007cd73b862b27829b1d51d268b7c2551a83` — 🪚 Migrate structural paths to `DB` qualification;
- bind-aware raw interpolation: `4fcdbec3757973d1b5f619afacae22b08718752b` — `🪚 Add bind-aware raw SQL interpolation`.

TECH_DEBT item 12 is closed. No product source/test implementation work is active for this release candidate.

Current work is limited to synchronizing stable documentation and managed skills with the landed source, completing whole-candidate release-readiness review, and then running the separately gated final release/publication checks. Push, tag, GitHub Release publication, and external managed-skill publication remain separately authorized operations.

Publication of the managed skills in the independent `SwiftStream/skills` repository is outside this repository's 3.0.0 release objective.
