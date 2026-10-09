# MySQL Dialect Architecture

This file is the sole owner of `MYSQL-*` rules and MySQL-specific SQL behavior.

Status: **compact seed owner**. It records only verified current repository facts and stable compatibility constraints. A dedicated future MySQL documentation mega-task should expand this file from source/tests/current official MySQL documentation without changing established behavior casually.

Load it together with `../DIALECT_RENDERING.md` for MySQL-specific work.

## Identity

### MYSQL-001 - Public dialect identity

The established public factory is:

```swift
SQLDialect.mysql
```

The current internal dialect id is:

```swift
"mysql"
```

These are long-standing compatibility surface.

## Shared temporal and interval values

MySQL rendering is exact-or-hard-fail for the shared civil values:

- finite `PureDate` years `1000...9999` use `CAST('YYYY-MM-DD' AS DATE)`;
- `PureTime` with no fraction uses `TIME`, and microsecond-exact fractions use `TIME(6)`; non-microsecond nanoseconds are unsupported without rounding, while exact `24:00:00` remains supported;
- finite `DateTime` years `1000...9999` use `DATETIME` or exact `DATETIME(6)`;
- unsupported years, precisions, and special states fail closed rather than silently coercing;
- `Interval` has no false first-class generic MySQL interval value/schema claim.

Representative supported output is:

```sql
CAST('2026-09-04' AS DATE)
CAST('12:34:56.123456' AS TIME(6))
CAST('2026-09-04 12:34:56.123456' AS DATETIME(6))
```

## Rendering

### MYSQL-002 - Current key-path behavior

The current MySQL dialect renders optional schema/table qualification and the final path component.

Unlike PostgreSQL/Duck JSON traversal, the current implementation does not walk all nested `SQLPartKeyPath.paths` with `->`/`->>` semantics.

This is a verified current implementation fact and must not be silently changed during unrelated work.

A future MySQL-specific audit should document the intended JSON/path contract separately from historical behavior.

### MYSQL-003 - Identifier behavior is historical and audit-sensitive

The current MySQL dialect does not override the base schema/table/alias/column identifier hooks, so those names currently render without PostgreSQL-style double quoting from this dialect class.

Do not infer a broader MySQL identifier guarantee from this seed doc. A future dedicated MySQL audit must compare current source/tests with current official MySQL quoting rules before proposing any compatibility-sensitive correction.

### MYSQL-004 - Bind markers

MySQL bind markers use:

```sql
?
```

The same marker spelling is reused for each bound value. Traversal/value ordering remains owned by `QUERY_PREPARATION.md`.

### MYSQL-005 - Date behavior

The current MySQL dialect renders Foundation `Date` through MySQL `FROM_UNIXTIME(...)` semantics using the value's Unix timestamp.

The canonical Swift helper naming migration uses `Fn.fromUnixTime(...)`, while emitted SQL remains exact MySQL spelling `FROM_UNIXTIME(...)`.

Do not change this behavior during unrelated Duck/Swift 6 work.

### MYSQL-006 - Array behavior is historical compatibility surface

The current MySQL dialect wraps the historical `SQLPartArray` array-output path with single quotes.

EF01-A's dedicated `SQLArray` grammar namespace does not reuse that compatibility path. Its exact `ARRAY[...]` / `ARRAY(subquery)` parts may mechanically prepare under `.mysql`, but that is not a claim of native MySQL array semantics and must not be translated to JSON or another MySQL construct.

EF01-B's structural `slice` operand likewise flows through the existing generic subscript renderer. Any MySQL output such as `[lower:upper]` or `[lower:upper:step]` is render-compatibility evidence only, not a native MySQL slice support claim, and must not be remapped to JSON or another function/operator family.

EF01-C ships the shared `ANY(...)` / `All(...)` / `Some(...)` quantified-comparison family for MySQL's actual quantified-subquery grammar. Positive MySQL ownership is limited to quantified subqueries; there is no native PostgreSQL-style ARRAY family, and the DSL must not simulate array quantification through JSON, MEMBER OF, IN, EXISTS, or another semantic rewrite.

EF01-D ships the shared aggregate-argument builder surface and generic `Fn.aggregate` extension point through ordinary SQL-part composition. This is a structural composition capability, not a claim that MySQL accepts PostgreSQL-style aggregate-local ordering for every aggregate identity. MySQL aggregate-local ordering remains function-specific; callers must use only grammar supported by the selected MySQL function, and the DSL must not translate unsupported aggregate syntax into a different function, JSON construct, or semantic rewrite.

The historical quote-wrapped behavior remains a verified compatibility fact for its existing path. A future MySQL audit must classify that behavior carefully before any redesign.

## MySQL-specific surface

### MYSQL-007 - Exact MySQL functions remain clean `Fn.*` API

Existing MySQL-specific helpers such as `FROM_UNIXTIME` and `DATE_FORMAT` use clean canonical camelCase Swift names while preserving exact SQL spelling.

Historical snake_case function names remain compatibility aliases under the established Fn migration policy.

Do not add `MySQL...` wrappers around ordinary SQL function calls merely because current support is MySQL-specific.

### MYSQL-009 - EF02 JSON_VALUE path/default roles are parser-restricted and literal-safe

MySQL 8.4.11 native validation establishes exact `JSON_VALUE(document, path)`. Exact `JSON_EXISTS(document, path)` and `JSON_QUERY(document, path)` identities are absent; do not substitute differently named MySQL JSON functions.

The JSON_VALUE path operand is parser-literal grammar in the verified server. A parameter marker and tested expression forms are rejected at PREPARE/parse time. A runtime Swift String path therefore requires dialect-owned contextual parser-literal rendering rather than ordinary binding.

That contextual rendering is authorized only after implementation provides dialect-correct escaping-safe literal encoding. The current inherited MySQL `safeValue(String)` / `stringValue(_:)` only quote-wraps and does not escape embedded apostrophes, so it is not accepted as the security mechanism. Apostrophe-containing JSON keys must remain one escaped literal payload; apostrophe doubling is native-positive and does not depend on backslash-escape mode.

JSON_VALUE DEFAULT is also parser-restricted in the tested capability boundary: literal DEFAULT is positive, while parameter markers, function expressions, arithmetic expressions, and user variables are negative. Direct runtime defaults therefore require the same contextual literal-safety contract. Unsupported structural forms remain unclaimed.

MySQL JSON_VALUE owns its own RETURNING / ON EMPTY / ON ERROR grammar. PostgreSQL PASSING is unsupported, and PostgreSQL FORMAT JSON ownership must not be projected onto MySQL.

## Future expansion

### MYSQL-008 - Required future mega-audit

A dedicated MySQL documentation/research tranche should eventually expand this owner with a verified matrix for:

- identifier quoting and aliases;
- strings/primitive values;
- dates/time zones;
- JSON/path behavior;
- casts/types;
- arrays/list-like compatibility semantics;
- functions/operators;
- DML/DDL;
- conflict/upsert forms;
- prepared-query behavior;
- current test coverage;
- historical compatibility quirks.

Until that audit exists, keep this file compact and do not invent missing MySQL guarantees for symmetry with Duck documentation.
