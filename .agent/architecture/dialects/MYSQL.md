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

The current MySQL dialect wraps SQL array output with single quotes.

This is a verified historical implementation fact, not a claim that MySQL has PostgreSQL/Duck-style native array semantics.

A future MySQL audit must classify this behavior carefully before any redesign.

## MySQL-specific surface

### MYSQL-007 - Exact MySQL functions remain clean `Fn.*` API

Existing MySQL-specific helpers such as `FROM_UNIXTIME` and `DATE_FORMAT` use clean canonical camelCase Swift names while preserving exact SQL spelling.

Historical snake_case function names remain compatibility aliases under the established Fn migration policy.

Do not add `MySQL...` wrappers around ordinary SQL function calls merely because current support is MySQL-specific.

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
