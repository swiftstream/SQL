# Public Writing Style

This is the stable owner of writing style for user-facing public material: `README.md`, `MIGRATION.md`, `RELEASE_NOTES.md`, `CHANGELOG.md`, GitHub Releases, website/public documentation, and maintainer posts about SQL.

It owns **how public material is written**. It does not govern agent-facing or implementation-internal documentation. Architecture owners and live source/tests still own technical truth.

## Core rule: show it, then explain it

SQL public writing is example-first.

Prefer this order:

1. name the concrete user-visible feature/change;
2. show the Swift call site;
3. show generated SQL when it materially clarifies what the Swift means;
4. explain only the non-obvious behavior, limitation, or migration consequence;
5. link to deeper documentation only when the reader actually needs it.

Use PostgreSQL as the default generated-SQL example unless the feature is dialect-specific. Use split query/bind output when binding behavior is the point. Do not mechanically repeat SQL output when it adds no information.

Format SQL snippets for comfortable reading in GitHub Markdown. Avoid long one-line statements that force horizontal scrolling. Break long statements at major clauses such as `SELECT`, `FROM`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, and `LIMIT`, and split long projection/value lists onto indented lines when that improves readability. Reflow presentation whitespace only. Preserve SQL tokens, order, literals, bind semantics, and dialect behavior. If exact byte-for-byte renderer whitespace is itself the subject of the example or assertion, show that exact output and label it accordingly instead of reformatting it.

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

Avoid turning internal implementation/audit vocabulary into public prose. Task numbers, correction waves, audit names, evidence ledgers, coordinator terminology, internal gates, artifact hashes, rejected API names, unpublished alternatives, and implementation-history trivia do not belong in normal public docs.

Do not explain an absence the reader has no reason to expect. Describe the current public API positively instead of saying that an internal or rejected alternative does not exist.

Avoid slogans, tautologies, and architecture shorthand that require project history to understand. Prefer a concrete statement of what the user writes, what it produces, and why that is useful.

Do not use semicolons to join prose in user-facing public material. Write separate sentences or use a natural conjunction instead. Semicolons are allowed only when they are part of code, SQL, shell commands, URLs, generated syntax, or quoted source text.

The tone may be informal and enthusiastic when natural, but examples and technical truth come first.

## README

README is the first-use document for the current package, not a release audit or development history.

At the top:

- use the human-facing project name and keep compatibility badges aligned with the current supported minimum;
- explain what SQL is and what the user can do with it;
- state supported databases without making one dialect dominate the project identity;
- keep current installation instructions directly usable.

General README prose should be version-agnostic. Use version numbers where the version itself matters, such as installation requirements or an explicit migration link. Put release-specific fixes and historical behavior in release notes/changelog, and put old-to-new source transitions in `MIGRATION.md`.

Describe only public concepts a current user needs. Do not mention rejected names, superseded designs, canonical-repository trivia, or internal compatibility history merely to explain that they are absent.

When several syntaxes express one concept, name the concept first and present the syntaxes as forms of it. For example, fluent chaining and `SQL { ... }` are both declarative query authoring, not competing paradigms.

Keep the composition model visible. Show that `SQLable` expressions, predicates, clauses, statements, and reusable queries can be created separately, stored, passed around, and combined later. Do not overstate this as grammar-free composition. Each fragment still has to appear where SQL grammar allows it.

Keep current behavioral caveats only when they change how users should write code. Explain the actionable rule directly. Keep the history of why the caveat exists out of README.

README examples should normally start from a concrete SQL idea and show the public Swift API. Show generated PostgreSQL SQL when it helps the reader verify what the DSL means, and show dialect-specific output only when the difference matters.

## Context budget and single ownership

Keep public docs compact. README owns current usage, MIGRATION owns source transitions, RELEASE_NOTES owns release detail, CHANGELOG owns compact history, and GitHub Releases own concise announcements.

Link instead of copying the same explanation. Reuse an example only when the second document must stand on its own. Prefer one strong, self-contained example over several near-duplicates.

After editing a public document, scan the whole affected file for stale version wording, internal/rejected terminology, duplication, unexplained jargon, and examples that no longer match the current API.

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

Historical SwifQL releases may be consulted for maintainer tone and example shape, but never as technical authority for current APIs.

## Swift Stream social release announcements

After a verified GitHub Release, prepare two short social announcements: English for Discord and Russian for Telegram.

These are not shortened copies of the GitHub Release body. They are channel-native maintainer posts whose job is to make the most important user-visible change immediately understandable and give readers one canonical link for the full release.

### Shared approach

Start from the release's strongest practical value.

Choose only the few changes most likely to make a user care about the release. For a substantial feature release, usually two to four points are enough. For a focused fix release, one concrete sentence may be enough.

Prefer:

- the project name and exact version immediately;
- one clear hook or primary improvement;
- short concrete feature/fix statements;
- inline API names only when they make the change clearer;
- the canonical GitHub Release URL;
- contributor credit when a release materially comes from a community report or contribution.

Do not:

- reproduce the full changelog or release notes;
- enumerate every minor addition;
- include validation/test statistics;
- include internal planning, implementation, audit, evidence, or workflow terminology;
- use generic corporate excitement such as `We are thrilled to announce`;
- invent a slogan;
- make the Discord and Telegram posts literal translations of one another.

Keep the tone recognizably maintainer-written: direct, compact, practical, and allowed to be enthusiastic when the change deserves it.

Do not repeat the project name or version in the opening sentence when the heading already contains them. Start the body directly with the value, for example `Big expression-building update:` or `Расширяем работу с выражениями:`.

Mention migration, compatibility, or required user action only when the release actually contains a breaking change, mandatory migration, configuration change, workaround, or other action the reader needs to take. Do not add reassuring boilerplate such as `No migration required` when nothing needs to be done.

End with the canonical GitHub Release URL as a bare link. Do not introduce it with labels such as `Full release:`, `Full release notes:`, `Полный релиз:`, or `Полный список изменений:`.

If the release has a breaking change or requires user action, say the action plainly in the social post. Do not hide an important migration instruction behind the link.

### Discord — English

Use concise developer English.

When a dedicated project channel exists, begin with the channel context followed by the release/version, for example:

`#sql **Released SQL 2.2.0**`

For a feature release:

1. name the release;
2. state the main value in one short sentence;
3. use a compact bullet list only when several changes deserve equal weight;
4. finish with the GitHub Release link.

Prefer one screenful over a mini-blog post.

Good Discord copy is often denser than Telegram copy. Inline code such as `JSONValue`, `ANY`, or `Fn.arrayAgg` is useful when the API name itself communicates the feature. Avoid large code blocks unless a single tiny example is the whole point of the release.

Emoji may be used sparingly to carry the maintainer tone or the release theme. Do not decorate every bullet.

### Telegram — Russian

Use natural Russian maintainer voice rather than a literal translation of the English post.

Start with the release emoji before the bold heading:

`🧩 **Релиз SQL v2.2.0**`

Do not place the release emoji at the end of the Telegram heading.

Then explain the practical changes in short paragraphs or a compact list. Telegram may be slightly more conversational than Discord and may briefly explain why a change matters.

Prefer wording such as:

- `Добавлено...`
- `Теперь можно...`
- `Исправлено...`
- `Если вы используете..., то...`

For a release with several meaningful features, two to four short bullets are appropriate. For a small fix, keep it to one or two sentences.

If users must change configuration or source, give the actionable instruction directly in the post.

Finish with the canonical GitHub Release link when readers may want the complete details.

Blank lines are useful for readability. Avoid turning the post into formal release notes.

### Fidelity

Both social posts must be generated from already accepted release truth.

They may simplify, prioritize, and omit details, but must not broaden support claims, erase dialect/platform limitations that matter to the highlighted feature, or advertise unreleased work.

When a concise social sentence would become misleading without a caveat, either include the caveat in one short sentence or choose a different release highlight.

## Accuracy rules

Before publishing an example:

- verify every public symbol, model property, and call shape exists in current source;
- verify exact SQL/result against current tests or direct preparation when practical;
- keep the example internally consistent with declarations shown earlier in the document;
- distinguish released/stable/pre-release/future states truthfully;
- do not advertise deferred features;
- do not invent a compatibility alias, package version, driver URL, generated SQL string, or platform promise;
- keep PostgreSQL/MySQL/Duck behavior distinct when the output is genuinely dialect-specific.

When documentation style conflicts with technical accuracy, accuracy wins; rewrite the example rather than weakening the truth.
