# Release Publication

Stable operational owner for publishing SQL releases. It owns **release mechanics and safety gates**, not prose; public release wording remains owned by `PUBLIC_WRITING_STYLE.md`.

Load this file only when work pushes a release candidate, creates/pushes a release tag, validates a published tag remotely, or creates/verifies a GitHub Release.

## Candidate

Before publication:

- require a clean, independently accepted release candidate on the intended branch;
- record its exact commit as `RELEASE_SHA`;
- require public docs/stable governance to describe the intended release truthfully;
- require the future release tag to be absent locally and remotely;
- preserve unrelated work;
- never force-push, reset, move an existing release tag, or rewrite published history.

A docs/governance-only release closure does not require rerunning a large local source matrix solely because text changed. It still requires fresh remote CI and consumer evidence for the exact published candidate.

## Branch publication

Push the accepted branch normally.

Before tag creation require:

- local `HEAD == RELEASE_SHA`;
- `origin/master == RELEASE_SHA`;
- branch CI identifies exact `RELEASE_SHA`;
- required workflow/job succeeds.

If branch CI fails, stop before creating the release tag.

## Stable tag

Create one annotated stable tag on exact `RELEASE_SHA`, then push only that tag normally.

Verify:

- local tag object SHA;
- local peeled commit == `RELEASE_SHA`;
- remote tag object SHA == local tag object SHA;
- remote peeled commit == `RELEASE_SHA`.

A pushed stable tag is immutable. Never move, delete, or recreate it to repair a later failure.

## Tag CI

Require tag CI to identify the exact release tag and `RELEASE_SHA`, with the required workflow/job successful. If tag CI fails, preserve the immutable tag and stop.

## Remote exact consumer

Before creating the GitHub Release, validate from a disposable external SwiftPM consumer:

- dependency URL = `https://github.com/SwiftStream/SQL`;
- requested version = exact release version;
- resolved revision/check-out = `RELEASE_SHA`;
- normal product/module `SQL` import;
- representative canonical public API;
- relevant preparation/bind behavior;
- build and run PASS;
- disposable fixture removed after concise evidence is preserved.

Do not substitute a local path, branch/revision fallback, or local mirror for the published tag.

## GitHub Release

Create the GitHub Release only after branch CI, tag identity, tag CI, and remote exact consumer PASS.

Use authenticated `gh` CLI. For a stable release:

- use `--verify-tag`;
- use the independently reviewed release body;
- do not use draft or prerelease mode;
- follow `PUBLIC_WRITING_STYLE.md`.

Read it back with `gh` and independently verify through GitHub:

- exact tag and title;
- body matches the reviewed release body;
- `draft == false`;
- `prerelease == false`;
- tag still resolves to `RELEASE_SHA`.

A GitHub Release-page failure never authorizes changing the stable tag.

## Release point

Before any later post-publication governance commit:

- local `HEAD == origin/master == RELEASE_SHA`;
- release tag peels exactly to `RELEASE_SHA`;
- GitHub Release references that tag;
- remote exact consumer passed.

This immutable tag/commit pair is the release identity.

## Post-publication branch state

After publication is proven, a separate governance commit may record the published state.

If `POST_PUBLICATION_GOVERNANCE_SHA` exists:

- it descends from `RELEASE_SHA`;
- local `HEAD == origin/master == POST_PUBLICATION_GOVERNANCE_SHA`;
- the immutable release tag still peels to `RELEASE_SHA`;
- the GitHub Release still references the release tag;
- worktree is clean.

Do **not** require `origin/master == RELEASE_SHA` after an authorized descendant post-publication commit advances the branch.

## Failure rule

Before the tag exists, a failed gate blocks tag creation. After the tag exists, later failures block further publication steps but never authorize tag mutation or history rewriting.

Record immutable release-point identity and final moving-branch identity separately in publication evidence.
