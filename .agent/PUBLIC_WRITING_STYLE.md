# Public Writing Style

This is the stable owner of maintainer-facing writing style for `README.md`, `MIGRATION.md`, `RELEASE_NOTES.md`, `CHANGELOG.md`, GitHub Releases, website/public documentation, and maintainer posts about SQL.

It owns **how public material is written**. Architecture owners and live source/tests still own technical truth.

## Core rule: show it, then explain it

SQL public writing is example-first.

Prefer this order:

1. name the concrete user-visible feature/change;
2. show the Swift call site;
3. when SQL is involved, show the SQL it generates;
4. explain only the non-obvious behavior, reason, limitation, or migration consequence;
5. link to deeper documentation only when the reader actually needs it.

Do not replace a useful example with an abstract paragraph or an exhaustive internal feature inventory.

For SQL features, the preferred shape is:

~~~markdown
### PIVOT

```swift
let query = ...
```

will give:

```sql
PIVOT ...
```
~~~

The example must use current public API and exact current SQL behavior.

## Canonical API first

Public examples must lead with the highest-level established type-safe API that users normally write. When a model-backed form exists, prefer examples such as `\User.$id` and `User.table`; show `Path.Column(...)` / `Path.Table(...)` only when documenting that explicit path API, writing SQL without a model type, or as a clearly labeled alternative. Never let a lower-level example imply that a higher-level type-safe API was removed or degraded.

Exception: schema-migration / historical DDL examples must keep schema, table, and column identifiers as explicit strings. Never derive migration identifiers from current model metadata or key paths.

## Migration style: `was` → `became`

When source actually changes, make the migration mechanical and visible.

Preferred:

~~~markdown
## Breaking change

Aliases syntax has changed.

was

```swift
oldSource
```

became

```swift
newSource
```
~~~

A breaking-change section should answer “what do I change in my code?” before explaining internal reasons.

Do not call something a breaking change merely because internals changed. If ordinary user source stays the same, say so and show the unchanged source when that clarification is useful.

## Voice

Use direct, practical developer language.

Good:

- `How to declare...`
- `Usage examples`
- `will give`
- `was` / `became`
- `Now you can...`
- `If you use ... then ...`
- a short sentence followed immediately by code.

Avoid corporate release-note language such as:

- `This release delivers a comprehensive modernization...`
- `Key strategic enhancements include...`
- `The architectural foundation has been significantly evolved...`

Avoid turning internal implementation/audit vocabulary into public prose. Task numbers, correction waves, audit names, evidence ledgers, coordinator terminology, internal gates, and artifact hashes do not belong in normal public docs or release posts.

The tone may be informal and enthusiastic when natural, but examples and technical truth come first.

## README

README is the first-use document, not a release audit.

At the top:

- explain what SQL is and where it can be used;
- point server-side users to the normal server integration path;
- point mobile users to the normal embedded-driver path when relevant;
- state supported databases without making one dialect dominate the project identity;
- keep current installation instructions directly usable.

Do not lead with internal dialect identifiers, closure terminology, compatibility-gate history, or implementation details such as `SQLDialect.all` unless the reader is in the part of README where that API is actually relevant.

Installation examples must point to a version/tag that exists for the release state being documented. A pre-release may be described as a pre-release; do not say it is unavailable when its tag is the intended install target.

README examples should normally start with the SQL idea and then show the SQL DSL representation, matching the established project philosophy.

## MIGRATION.md

`MIGRATION.md` is a sequence of actions for an existing user.

For every migration item, prefer:

1. who is affected;
2. `was` example if source changes;
3. `became` example;
4. one concise reason/behavior note;
5. what does **not** need to change, when that prevents unnecessary migration work.

Do not write a long release feature catalog in the migration guide. Features that require no migration belong primarily in release notes/README examples.

If an internal change preserves normal query source, show that normal source still works rather than making the user infer it from architecture prose.

End with a short practical checklist.

## RELEASE_NOTES.md

Release notes tell the user what they can do now.

Organize around user-visible capabilities and real migration points, not internal implementation phases.

For SQL/API additions, show representative calls and output. Prefer a few strong examples over a list of dozens of feature-family names.

For a large release, a concise summary list may follow the examples, but it must not be the only explanation.

Place real breaking changes in clearly labeled sections with `was` / `became` source.

Validation can be stated briefly near the end when it is meaningful to users; do not make internal test/evidence statistics the narrative of the release.

## CHANGELOG.md

The changelog is a compact human-readable history, not a duplicate audit log.

Each version should make the important changes scannable, but still include representative code for changes whose meaning is unclear from one sentence.

Prefer concrete headings (`Swift 6`, `Structural query composition`, `PIVOT`, `Fn.Name`) over generic buckets such as only `Added`, `Changed`, `Fixed` when those buckets make the release harder to understand.

Link to `RELEASE_NOTES.md` and `MIGRATION.md` for the complete story instead of duplicating every example three times.

## GitHub Releases

A GitHub Release post should be usable without opening the repository diff.

Preferred structure:

1. short release title naming the main user-visible change(s);
2. one or two sentences at most before the first useful example;
3. feature headings;
4. Swift examples and exact SQL/result examples where relevant;
5. `Breaking change` sections only for actual source migrations;
6. a short install snippet when the version/tag matters;
7. link to migration/full notes when useful.

The title does not need to enumerate every feature. It should read like a maintainer describing the release, not a generated changelog summary. For a large stable release, a concise title such as `🚀 SQL 2.0.0` is preferable to a generated multi-clause marketing headline. Open with concrete user value and put the install snippet near the top.

## Reference style from historical SwifQL releases

The maintainer's established release-writing style is visible in releases such as:

- `1.5.0` — `union` / `with` examples followed by the SQL they “will give”;
- `2.0.0-beta.2.0.0` — explicit `Breaking change`, literal `was` / `became`, then schema/alias usage examples with result comments;
- `2.0.0-beta.3.0.0` — concise breaking rename plus immediate model/property-wrapper examples;
- `2.0.0-beta.3.2.0` — problem statement followed by two concrete encoding examples and their JSON output;
- `2.0.0-beta.5.0.0` — large-release example with a short summary, install snippet near the top, feature headings, Swift-to-SQL examples, explicit `was` / `became` breaking changes, and a brief validation close.

Use these as tone/shape references, not as technical authority for current APIs.

## Accuracy rules

Before publishing an example:

- verify the public symbol exists in current source;
- verify the exact SQL/result against current tests or direct preparation when practical;
- distinguish released/stable/pre-release/future states truthfully;
- do not advertise deferred features;
- do not invent a compatibility alias, package version, driver URL, generated SQL string, or platform promise;
- keep PostgreSQL/MySQL/Duck behavior distinct when the output is genuinely dialect-specific.

When documentation style conflicts with technical accuracy, accuracy wins; rewrite the example rather than weakening the truth.
