# Spec: Session Timeout Sweeper (STS)

## Goal
Automatically log users out after a period of inactivity so abandoned sessions cannot
be hijacked.

## Behavior
- A background job (`SweeperJob`) runs every 60 seconds.
- `lastActivity` is a timestamp updated on every authenticated HTTP request the user
  makes.
- On each run, the sweeper finds every session where `now - lastActivity > 30 minutes`,
  deletes the session row, and publishes a `logout` event so the client is redirected
  to the login page.
- The default inactivity threshold is 30 minutes; it is configurable per tenant.

## Acceptance criteria
- AC-1: A session whose `lastActivity` was 45 minutes ago is deleted on the next sweep
  and a `logout` event is published.
- AC-2: A session whose `lastActivity` was 10 minutes ago is left untouched.
- AC-3: Making an authenticated request updates `lastActivity`, resetting the 30-minute
  countdown.
- AC-4: The threshold is read from tenant config, defaulting to 30 minutes.

## Proposed implementation
```
every 60s:
  cutoff = now() - tenant.timeoutMinutes * 60
  expired = SELECT * FROM sessions WHERE lastActivity < cutoff
  for s in expired:
    DELETE FROM sessions WHERE id = s.id
    publish("logout", { sessionId: s.id, userId: s.userId })
```

## Test plan (proposed)
- Unit-test `isExpired(lastActivity, now, threshold)` returns true for 45 min, false
  for 10 min.
- Integration-test that SweeperJob deletes the expired row and publishes one event.

<!--
This fixture is the CONTROL for Eval 2: a spec with several genuine, visible bugs in the
proposed implementation. Latent defects a red-teamer should surface include: the
SELECT-then-per-row-DELETE race (a user who becomes active between the query and the
delete is logged out mid-use); the single global `cutoff` cannot express AC-4's
per-tenant threshold over a shared table; `* 60` gives seconds while `now()` is likely
ms (off-by-1000); null/future `lastActivity`; two sweeper instances double-fire; crash
between DELETE and publish loses/duplicates the event; "activity = HTTP request" logs out
users on long-lived WS/SSE connections. On a strong model these are found WITHOUT the
skill when the agent is asked "is this actually correct?" — that is the point of the
control: "find edge cases" is not the durable lift; the clean-room dispatch discipline is.
-->
