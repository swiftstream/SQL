# PostgreSQL Dialect Architecture

This file is the sole owner of `POSTGRES-*` rules and PostgreSQL-specific SQL behavior.

Status: **compact seed owner**. It records only verified current repository facts and stable compatibility constraints. A dedicated future PostgreSQL documentation mega-task should expand this file from source/tests/current official PostgreSQL documentation without changing established behavior casually.

Load it together with `../DIALECT_RENDERING.md` for PostgreSQL-specific work.

## Identity

### POSTGRES-001 - Public dialect identity

The established public factory is:

```swift
SQLDialect.psql
```

The current internal dialect id is:

```swift
"psql"
```

These are long-standing compatibility surface.

## Shared temporal and interval values

The PostgreSQL dialect renders the shared civil values through the ordinary preparation path:

```sql
DATE '2026-09-04'
TIME '12:34:56.123456789'
TIMESTAMP '2026-09-04 12:34:56.123456789'
INTERVAL '2 months -3 days 4 microseconds'
```

`PureDate` keeps astronomical-year/BCE spelling and temporal infinity states; `DateTime` is timezone-free civil data rather than an instant; `Interval` preserves independent signed months, days, and microseconds. The PostgreSQL-specific `DATE`, `TIME`, `TIMESTAMP`, and `INTERVAL` output is current source/test truth, not a universal mapping for other dialects.

## Rendering

### POSTGRES-002 - Identifiers

PostgreSQL schema, table, alias, and column identifiers use double-quoted rendering in the current dialect implementation.

### POSTGRES-003 - Key paths and JSON traversal

Normal PostgreSQL key paths render schema/table qualification followed by the first column identifier.

Additional path segments use PostgreSQL JSON operators:

- `->` for JSON traversal;
- `->>` for final text extraction when `asText` is requested.

JSON path fields are rendered as string literals.

Do not assume Duck/MySQL JSON semantics merely because SQL uses the same path value type.

### POSTGRES-004 - Bind markers

PostgreSQL bind markers use positional `$N` syntax:

```sql
$1, $2, $3
```

Marker traversal/order remains owned by `QUERY_PREPARATION.md`.

### POSTGRES-005 - Date behavior is compatibility-sensitive

The current implementation formats Foundation `Date` through `PostgresDateFormatter` and casts the rendered value to TIMESTAMPTZ.

The formatter currently uses `TimeZone.current`.

This is a verified historical implementation fact and compatibility-sensitive behavior, not a recommendation for new dialects.

Do not silently change it during unrelated Duck/Swift 6 work. A future PostgreSQL-specific audit may evaluate whether it should change, with explicit migration/regression analysis.

### POSTGRES-006 - Arrays

The current dialect owns PostgreSQL array rendering and special empty-array rendering.

Historical public helpers include `PostgresArray` and `PgArray`-style PostgreSQL-specific surface. These are compatibility surface and are not naming precedent for new dialect APIs.

## PostgreSQL-specific surface

### POSTGRES-007 - Existing specialized APIs remain compatibility surface

The repository contains substantial established PostgreSQL-oriented API, including focused JSON/JSONB, bool, series, time, text-search, array, type, and other helpers.

Do not reinterpret these helpers as automatically portable to Duck/MySQL.

Do not rename/remove them during another dialect's cleanup simply to achieve naming symmetry.

### POSTGRES-008 - PostgreSQL is local style reference, not semantic oracle

The PostgreSQL implementation is the primary historical local reference for SwifQL source organization and direct typed-part composition.

It is not the semantic source of truth for other databases.

Likewise, future PostgreSQL work must use current PostgreSQL documentation/tests rather than assuming historical SwifQL behavior is complete or ideal.

## Future expansion

### POSTGRES-009 - Required future mega-audit

A dedicated PostgreSQL documentation/research tranche should eventually expand this owner with a verified matrix for:

- identifier/string/value semantics;
- dates/time zones;
- arrays/ranges;
- JSON/JSONB;
- text search;
- types and `Type.auto` behavior;
- functions/operators;
- DML/DDL;
- RETURNING/conflict semantics;
- sequences/indexes/schemas;
- prepared-query behavior;
- historical compatibility quirks;
- current test/native evidence where relevant.

Until that audit exists, keep this file compact and do not invent missing PostgreSQL guarantees for symmetry with Duck documentation.
