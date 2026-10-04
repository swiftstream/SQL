# Safety Rules

This file owns value/raw-fragment safety policy. The composition and preparation mechanics remain in `architecture/DSL_COMPOSITION.md` and `architecture/QUERY_PREPARATION.md`.

## Value paths

- Ordinary Swift scalar values currently enter the normal DSL as bound `SQLPartUnsafeValue` values.
- Preparation collects those values and emits the internal dialect bind marker; see `QUERY_PREPARATION.md` for the detailed mechanics.
- `SQLPartSafeValue` is for deliberately trusted or internally controlled inline representation. It is not a blanket path for dynamic user input.
- Use the normal bound-value path whenever an input is data rather than SQL structure.

## Raw and structural paths

- Raw/custom structural APIs exist as explicit escape hatches and as internal structural-building tools, including the public `raw(_:)` API and custom operator fragments.
- Never interpolate untrusted or dynamic user data into raw/custom SQL structure.
- Prefer typed and composable DSL extensions over raw fragments when a proper abstraction is practical.
- Do not claim that SQL statically makes every possible raw usage safe.

These rules constrain how values and structural escape hatches are used; they do not redefine the architecture or preparation pipeline.
