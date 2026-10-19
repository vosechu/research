---
paths:
  - "**/*.{js,jsx,ts,tsx}"
  - "**/*.{rb,py,go,java,kt,cs}"
  - "**/*.{sql,psql}"
---

# Naming Conventions: Domain Verb Extensions

Extends the core verb vocabulary in [naming-conventions.md](naming-conventions.md). These
don't replace the core verbs; they cover concepts the core table doesn't address. Add only
the tables for domains the project actually occupies.

## HTTP / Web Services

| Verb | Meaning | Example |
|---|---|---|
| `fetch` | Make an external HTTP request (async, may fail) | `fetchAccountDetails()` |
| `submit` | Send user-initiated data to a server | `submitForm()`, `submitOrder()` |
| `redirect` | Send client to a different URL | `redirectToLogin()` |
| `render` | Produce HTML/DOM output from data | `renderDashboard()` |
| `route` | Dispatch a request to a handler | `routeRequest()` |
| `validate` | Check user input at the system boundary | `validatePayload()` |
| `authorize` | Check if a principal has permission | `authorizeRequest()` |
| `authenticate` | Verify identity | `authenticateUser()` |

`fetch` is allowed here as distinct from `get`. `get` returns data you already have access
to (in-memory, local DB). `fetch` crosses a network boundary. If your service only does one
or the other, just use `get`.

## Message Queues / Kafka / Event Streaming

| Verb | Meaning | Example |
|---|---|---|
| `publish` | Send a message to a topic/exchange | `publishEvent()`, `publishMetric()` |
| `consume` | Receive and process messages from a topic | `consumeEvents()` |
| `enqueue` | Add to an ordered queue | `enqueueJob()` |
| `dequeue` | Take from an ordered queue | `dequeueJob()` |
| `ack` | Acknowledge successful processing | `ackMessage()` |
| `nack` | Reject / negative-acknowledge | `nackMessage()` |
| `emit` | Fire an event for listeners (in-process) | `emitMetric()`, `emitEvent()` |
| `dispatch` | Route a message/event to a specific handler | `dispatchCommand()` |
| `replay` | Re-process historical messages | `replayFromOffset()` |

`emit` is in-process (EventEmitter pattern). `publish` crosses a process boundary (Kafka,
AMQP, SNS). Don't swap them.

## Background Jobs / Workers / Pipelines

| Verb | Meaning | Example |
|---|---|---|
| `schedule` | Register work to run at a future time | `scheduleRetry()`, `scheduleExport()` |
| `execute` | Run a unit of work synchronously | `executeStep()`, `executeQuery()` |
| `spawn` | Start an async/parallel unit of work | `spawnWorker()` |
| `retry` | Re-attempt a failed operation | `retryWithBackoff()` |
| `poll` | Repeatedly check for new work/state | `pollForResults()` |
| `drain` | Process remaining items then stop | `drainQueue()` |
| `cancel` | Abort scheduled/in-progress work | `cancelJob()` |
| `resume` | Continue paused/interrupted work | `resumeFromCheckpoint()` |

## Data Pipelines / Compilers / Translators

| Verb | Meaning | Example |
|---|---|---|
| `translate` | Convert one representation to another (AST→IR, SPL→NRQL) | `translateExpr()` |
| `emit` | Produce output-format strings from internal representation | `emitQuery()` |
| `resolve` | Look up a name/symbol in a mapping or registry | `resolveFunction()` |
| `build` | Construct a node/structure from primitive parts | `buildComparison()` |
| `optimize` | Transform a structure to improve it (IR→IR) | `optimizeQuery()` |
| `normalize` | Canonicalize input before processing | `normalizeWhitespace()` |
| `walk` | Traverse a tree structure (visiting, not converting) | `walkDependencies()` |
| `rewrite` | Replace patterns in a tree (tree→tree of same type) | `rewriteSubqueries()` |

`translate` converts between types (AST→IR). `rewrite` transforms within the same type
(IR→IR). `walk` visits without producing a new structure. If your "walk" produces a
different type, call it `translate`.

## Database / Persistence

| Verb | Meaning | Example |
|---|---|---|
| `query` | Read from a data store with criteria | `queryByStatus()` |
| `insert` | Add a new record | `insertAccount()` |
| `update` | Modify an existing record | `updateBalance()` |
| `upsert` | Insert or update depending on existence | `upsertConfig()` |
| `migrate` | Transform schema or data between versions | `migrateToV3()` |
| `seed` | Populate initial/test data | `seedTestAccounts()` |
| `flush` | Write buffered data to storage | `flushBatch()` |
