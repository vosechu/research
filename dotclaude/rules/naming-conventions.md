# Naming Conventions

## Structure: A/HC/LC

Every function name follows: `prefix? + action (A) + high context (HC) + low context? (LC)`

| Name | Action | High Context | Low Context |
|---|---|---|---|
| `getUser` | `get` | `User` | |
| `getUserMessages` | `get` | `User` | `Messages` |
| `handleClick` | `handle` | `Click` | |
| `shouldRetryRequest` | (prefix) | `Retry` | `Request` |

High context = the primary thing. Low context = qualifier. Order matters: `shouldUpdateComponent` (you update it) vs `shouldComponentUpdate` (it updates itself).

## S-I-D: Every Name Must Be

- **Short** — quick to type and remember
- **Intuitive** — reads naturally, close to common speech
- **Descriptive** — reflects what it does/possesses

No contractions (`onItmClk` → `onItemClick`).
No context duplication (`MenuItem.handleMenuItemClick` → `MenuItem.handleClick`).

## Boolean Prefixes (closed set)

| Prefix | Meaning | Example |
|---|---|---|
| `is` | Characteristic or current state | `isEnabled`, `isNumeric` |
| `has` | Possesses a value or capability | `hasProducts`, `hasPermission` |
| `should` | Positive conditional tied to action | `shouldRetry`, `shouldWrap` |
| `did` | Past-tense completion state | `didChange`, `didLoad` |
| `can` | Ability or permission | `canEdit`, `canRetry` |

No other boolean prefixes. Never use negative names (`notReady`, `noHeaders`) — invert the logic instead.

## Variable Prefixes (closed set)

| Prefix | Meaning |
|---|---|
| `min` / `max` | Boundaries or limits |
| `prev` / `next` | State transitions |
| `raw` / `parsed` | Before/after processing |
| `total` / `count` | Aggregates |

## Common Opposites (always use as pairs)

`add/remove` · `create/delete` · `open/close` · `start/stop` · `begin/end` · `first/last` · `get/set` · `show/hide` · `enable/disable` · `old/new` · `prev/next` · `source/target` · `min/max` · `push/pop` · `read/write` · `encode/decode` · `enqueue/dequeue` · `publish/subscribe` · `serialize/deserialize` · `marshal/unmarshal`

Key distinction: **add/remove** need a destination (add *to* a list). **create/delete** don't (create a post, delete a post). Don't mix pairs.

## Singular/Plural

Singular for one value, plural for collections. Never pluralize lazily — `blog.js` and `blogs.js` are impossible to grep.

## Core Verb Vocabulary

Pick one verb per concept. The rest are banned synonyms.

| Concept | Use | Do NOT use |
|---|---|---|
| Read/access data | `get` | `fetch`, `retrieve`, `obtain`, `acquire`, `load`, `find` |
| Assign/mutate | `set` | `assign`, `update`, `put`, `write`, `store` |
| Make new thing | `create` | `make`, `generate`, `produce`, `construct`, `init` |
| Erase permanently | `delete` | `destroy`, `kill`, `nuke`, `purge`, `wipe` |
| Take from collection | `remove` | `drop`, `discard`, `detach`, `unset` |
| Return to default | `reset` | `clear`, `restore`, `revert`, `reinitialize` |
| Build from parts | `compose` | `assemble`, `combine`, `merge`, `construct` |
| React to event | `handle` | `on` (as prefix), `process`, `respond`, `react` |
| Check a condition | `is`/`has`/`should` | `check`, `test`, `verify`, `validate`, `assert` |
| Transform shape | `transform` | `convert`, `morph`, `reshape` |
| Make string/output | `format` | `render`, `stringify`, `print`, `display` |
| Parse string/input | `parse` | `deserialize`, `extract`, `read` |

Projects may extend this table with domain-specific verbs. Verbs for HTTP services, message
queues, background jobs, compilers, and databases live in
[naming-conventions-domains.md](naming-conventions-domains.md), which loads on its own when
you open a source file. Document project-specific overrides in the project's
`.claude/rules/naming-conventions.md`.
