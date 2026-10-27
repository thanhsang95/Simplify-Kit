<!--
Write this file when the change adds or changes a public interface (Contracts),
or when there is a real technical trade-off to record (Decision), or both.
With neither, skip it: `## Design` → `Skipped — <the reason>` in proposal.md.

Contracts: every interface a caller outside the changed module uses, which
/sk:apply will build and test against — exported functions or types, HTTP
endpoints, component props, CLI commands, events or messages, database schema.
Written in the repository's own language, so a reviewer can say "that
signature is wrong" before any code exists. Leave the section out when the
change touches no public interface.

Decision: only for a real trade-off — a decision a future reader would
otherwise have to reverse-engineer from the diff, or would be tempted to undo
without knowing what it cost. Restating the spec in implementation words is
not a design document. Leave Decision through Consequences out when there is
no trade-off.
-->

# Design — <change id>

## Contracts

### `<name>` — <where it lives, e.g. src/field-selector.ts>

```<language>
<signature, request/response shape, props, or schema — exactly as it will be written>
```

- **Serves:** <the `#### Scenario` names this interface makes testable>
- **Errors:** <what a caller gets when it fails — or "none">
- **Changes:** <new | changed from `<old signature>`> — a changed contract names every caller it breaks

## Decision

<What was chosen.>

## Why

<What it buys, and what it costs.>

## Alternatives considered

- **<alternative>** — <why not>

## Consequences

<What this makes harder later, what it forecloses, what it obliges the next
change to honour.>
