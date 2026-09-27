# Public Content Ideas

Stable low-context workflow owner for preserving high-value user-facing examples, product capabilities, documentation angles, README material, website-documentation ideas, release-story material, and publication/post concepts discovered during SwifQL development.

This is an **idea bank, not normal implementation context**. The detailed entries live in focused shards under `.agent/public-content-ideas/` so ordinary development does not pay their context cost.

## Why this exists

During architecture, implementation, native validation, audits, and corrections, the repository regularly discovers examples that explain SwifQL better than a later documentation pass could reconstruct from memory.

Without deliberate capture, useful material is easily lost, for example:

- a particularly clean before/after DSL example;
- a feature whose implementation detail demonstrates an important SwifQL design advantage;
- an explanation that makes a complex architecture understandable to users;
- a surprising compatibility guarantee;
- a native database behavior that is worth documenting publicly;
- an implementation story suitable for an article/post;
- a concise migration example;
- a compelling benchmark, validation result, or developer-experience improvement.

Capture these while the evidence and reasoning are fresh. Publication/editing happens later and only with maintainer approval.

## Capture rule

After a meaningful research, design, implementation, correction, audit, or accepted checkpoint, the coordinator/reviewer MUST perform a very short **public-content capture check**:

> Did this work produce a genuinely useful user-facing example, capability, explanation, migration note, validation result, or publication angle that would be difficult or wasteful to rediscover later?

If **no**, do nothing and do not open this bank.

If **yes**:

1. open only this router and the single relevant shard;
2. append the smallest useful entry while the context is fresh;
3. record status/provenance/caveats so future documentation work cannot accidentally present planned behavior as shipped behavior;
4. do not polish the entry into final marketing copy unless the current task is explicitly public documentation/content work;
5. continue the development workflow without loading unrelated shards.

This capture check is analogous to keeping `.artifacts/NEW_CHAT.md` current, but the ownership is different:

- `NEW_CHAT.md` preserves transient execution continuity and is disposable;
- this bank preserves durable **candidate public communication value** and is versioned under `.agent/**` until the maintainer explicitly curates/removes/promotes entries.

## Context-budget rule

Do **not** load this bank or its shards during ordinary source work merely because it exists.

Load it only when:

- a capture check has a positive result;
- the task is README/public docs/website docs/release notes/article/post preparation;
- the maintainer explicitly asks to review/curate public-content ideas.

Never bulk-load all shards. Read the router, then exactly the relevant shard(s).

This bank does not consume architecture-owner slots.

When captured material is promoted into final README/public docs/release notes/changelog/GitHub Release/post copy, load `PUBLIC_WRITING_STYLE.md`. The idea bank owns what is worth saying; `PUBLIC_WRITING_STYLE.md` owns how the final public text is written.

## Shard layout

Current shards:

- `public-content-ideas/DIALECT_TRANSPARENT_DSL.md` - dialect-transparent DSL, semantic render scopes, incremental composition, extension architecture, and related developer-experience stories.
- `public-content-ideas/COMPATIBILITY_EVOLUTION.md` - source-compatible evolution, major-version philosophy, downstream Swift extensions, migration discipline, and the story of modernizing SwifQL without making users rewrite thousands of established queries.
- `public-content-ideas/SHARED_SEMANTIC_VALUES.md` - cross-database civil values, exact dialect boundaries, and future publication material for the shared value layer.
- `public-content-ideas/DECLARATIVE_QUERY_AUTHORING.md` - future result-builder query DSL examples, SQL-shaped clause ergonomics, the planned `SwifQL -> SQL` identity migration, and raw-SQL conversion-skill material.

Create a new shard only when a topic becomes independently useful enough that adding it to an existing shard would create context noise. Prefer stable topic names over one file per tiny idea.

Potential future shards may include, only when justified:

- `DUCK.md`
- `CONCURRENCY.md`
- `MIGRATIONS.md`
- `VALIDATION_AND_CORRECTNESS.md`

Do not pre-create empty shards.

## Entry contract

Each captured entry should be compact and include only what future public-writing work needs:

```text
## Short descriptive title

Status: idea | architecture-approved | implemented | validated | shipped | superseded
Good for: README | website docs | migration guide | release notes | article | short post

### Why users should care
A few sentences describing user value, not internal implementation trivia.

### Candidate example / visual
Small code/SQL/diagram/snippet worth preserving.

### Evidence / provenance
Stable owner, source/test/native evidence, and/or commit when available.

### Publication caveat
Anything future writers must not overclaim.
```

Entries may omit sections that add no value, but **status and publication caveat are mandatory for anything not already shipped**.

## Status discipline

Use status truthfully:

- `idea` - worth preserving, not approved architecture;
- `architecture-approved` - accepted design, not implemented/shipped;
- `implemented` - source exists but final validation/release may still be pending;
- `validated` - intended behavior has passed the relevant repository/native validation gate;
- `shipped` - part of an actual released/publicly supported version;
- `superseded` - preserve only when the historical idea remains useful for understanding/migration/publication; otherwise remove during maintainer-approved curation.

Do not turn an architecture-approved example into README wording that implies the feature exists today.

## Provenance and commits

When an idea is captured before its implementation commit exists, record the current architecture/evidence source and add the eventual commit hash later if it materially helps future writers verify the story.

Do not require every tiny idea to carry a commit hash. Use hashes where they anchor a meaningful design/implementation milestone.

## Promotion and cleanup

This bank is a staging area for communication value, not permanent duplication of public docs.

With explicit maintainer approval, future work may:

- promote entries into `README.md`;
- promote them into public website/docs `.md` sources;
- use them as release-note or migration-guide material;
- use them as article/post outlines;
- merge/deduplicate shards;
- remove entries that have been fully published or are no longer useful.

Do not automatically delete an entry merely because one public document used it; the same idea may still be useful for another channel. Curation/removal is an explicit maintainer-controlled phase.

## Quality bar

Capture only material with real future communication value.

Good candidates answer at least one of these:

- "This makes SwifQL noticeably easier/cleaner/safer for users."
- "This example explains an important capability in a few lines."
- "This implementation choice is a strong engineering story."
- "Users upgrading or extending SwifQL will benefit from knowing this."
- "This native validation result meaningfully increases trust."

Do not fill the bank with routine refactors, test counts without a story, trivial syntax, internal task bookkeeping, or generic praise.
