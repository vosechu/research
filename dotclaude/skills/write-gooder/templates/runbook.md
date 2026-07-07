# Runbook template

A runbook exists to **help a sleep-deprived on-call engineer resolve an incident at 3am without escalating, escalate to the right people when they must, and not make things worse**. Every other reader — a person reviewing the runbook, a person onboarding into the rotation, a PM estimating response time — is secondary.

A runbook is not a design doc, a postmortem, a training manual, or a narrative of how the system works. If a step requires reading background prose to execute, the step is broken.

## Relationship to NR runbook templates

There is no single canonical runbook template at NR. Different orgs have built their own:

- [DATA-space Runbook Template (3127574956)](https://newrelic.atlassian.net/wiki/spaces/DATA/pages/3127574956) — structurally the most complete. Header table, Architecture diagram, Business Impact with severity matrix, Support Contacts, Debugging queries, Resolution Processes as per-scenario step tables. Anchor on this one when you can.
- [Synthetics Runbook Template (5278761277)](https://newrelic.atlassian.net/wiki/spaces/Synthetics/pages/5278761277) — alert-focused: Alert/Error Name + Impacted Use Cases shape.
- [GTS Launch Runbook Template (4556554532)](https://newrelic.atlassian.net/wiki/spaces/SUP/pages/4556554532) — GA-launch-readiness checklist, not an operational runbook. Different artifact.

If your team already has a runbook standard, use it. If not, follow this template and lean on the DATA-space shape for the structural scaffolding.

What this template adds on top:

- A minimum viable runbook shape. Every runbook covers: symptoms, severity gate, first check with exit criteria, escalation contacts, resolution steps with exit criteria, postmortem link. Missing any of those and an on-call will make the wrong call.
- Steps written as checkable exit criteria, not narration.
- A "when to escalate" gate placed before the resolution steps, not after.
- A "what NOT to do" section, because runbooks get followed literally and destructive corrections belong up top.

## Structure

Every section below is required unless marked optional. Blank sections are fine when there's nothing to say — "no postmortem-worthy failure modes yet" is a valid line. Missing sections aren't.

### 1. Header table

One table at the top, so on-call can scan in 5 seconds.

```markdown
| Runbook name | <alert or component name> |
|---|---|
| Component / service | <component, with link to source repo> |
| Owner (team) | <@team-mention, link to Slack channel> |
| On-call rotation | <PagerDuty service name, link to PagerDuty> |
| Last verified | <date someone actually followed this runbook end-to-end> |
| Version | <e.g. 2.3> |
```

**Last verified** is load-bearing. A runbook nobody has followed in 18 months is untrustworthy. If you're about to trust a runbook for a real page, check this date first.

### 2. Symptoms

What an on-call sees that brings them here. Be specific.

- **What to put in:** the alert name, the paging condition, the error message or metric signature. Direct quotes from the alert. Screenshots of the paging dashboard if the visual pattern matters.
- **What to keep out:** architectural exposition, theory of the failure mode. Those belong further down.

A runbook often covers one alert. If it covers several, list them as sub-headings, each with its own symptom section — don't merge them.

### 3. Severity / business impact

The gate that tells on-call how hard to push and who to wake.

Use a table when the severity maps to observable criteria:

```markdown
| Circumstance | Max severity |
|---|---|
| Data delayed by 1h | 5 |
| Data delayed by 5h+ | 4 |
| Data incorrect | 3 |
| Data missing | 2 |
| Data unable to parse | 1 |
```

The DATA-space template anchors on the `911 sev` convention — use it if your org does. Customer-facing SLOs belong here too: "breaches 99.9% availability SLO after 26 min."

### 4. First check (cannot skip)

The single thing an on-call does before anything else. One step, with an exit criterion.

- **What to put in:** the one command or dashboard load that distinguishes "real incident" from "flap/false alarm." Exit criterion is binary.
- **What to keep out:** any diagnostic that takes more than 60 seconds. If it takes longer, it's part of the debugging section, not the gate.

Example that lands:

> **First check:** Load [overview dashboard](url). If the `ingest rate (5m)` metric is above 10 MB/s, this is real — continue. If below, this is a post-traffic-drop flap — silence the alert for 30 min and link to this runbook in the silence comment.

### 5. Escalate when

The gate for handing off. Placed before resolution steps, not after, because on-call should know the escalation criteria before they start any mitigation.

- **What to put in:** specific criteria (duration, customer count, data-loss threshold) that say "stop trying to fix it alone, wake someone." Names / roles / Slack channels, not just "the team."
- **What to keep out:** "use your judgment." An on-call paging at 3am doesn't have good judgment; that's what the runbook is for.

Example that lands:

> **Escalate to <@primary-architect> + open a Sev2 war room if:**
> - The mitigation steps haven't reduced the ingest backlog within 15 minutes, OR
> - Any customer account shows data loss (not just delay), OR
> - You need to touch the Kafka consumer group offsets.

### 6. Resolution steps

Numbered procedures, one per failure mode. Each step has an exit criterion — what the on-call checks to confirm the step worked.

Structure each scenario as a table when the steps are parallel (step / command / check):

```markdown
**Scenario A — consumer lag from upstream backup**

| Step | Command | Confirm |
|---|---|---|
| 1. Check consumer group lag | `kafka-lag --group log-meter` | Lag is > 0 and declining |
| 2. Scale consumer replicas | `kubectl scale deploy log-meter --replicas=6` | `kubectl get pods` shows 6 ready |
| 3. Verify lag decreasing | `kafka-lag --group log-meter` | Lag halves within 5 min |
| 4. Monitor until caught up | watch `kafka-lag --group log-meter` | Lag = 0 |
```

**Every step has a check column.** A step without an exit criterion is a step an on-call can claim to have done without actually doing it.

If one scenario has more than ~6 steps, split it or rethink the runbook — long procedures are where mistakes happen.

### 7. What NOT to do

A short list of destructive actions on-call might try that would make the incident worse. Be specific; name the action and the consequence.

Example that lands:

> - **Do NOT** delete the Kafka consumer group to "reset." The offset is the only record of which messages have been billed; losing it causes double-billing for the replayed window.
> - **Do NOT** scale the consumer below 2 replicas. The rolling-deploy uses a 2-replica guard; going lower kills availability.
> - **Do NOT** manually edit `tdp.usage` events in NRDB. Meter corrections go through the `raw-usage-correction` tool only.

If there are no obvious footguns, omit this section. But look hard first — most systems have at least one.

### 8. Debugging queries / dashboards (optional)

Useful queries, dashboard links, and log searches that help characterize the failure. Named, annotated, and linkable.

This section is the "I don't know what's wrong yet" backup. Keep it short; if every incident routes through the same three queries, promote those into the First Check.

### 9. Architecture (optional, short)

One diagram and one or two lines of prose. What components this runbook covers and where they sit.

Linked to the repo README for the component, not duplicated. Architecture lives in the README or design docs; the runbook references it.

### 10. Support contacts

A table of who to page, in what order, by what channel.

```markdown
| Role | Who | How |
|---|---|---|
| Primary on-call | Team Foo | PagerDuty: foo-oncall |
| Upstream owner | Team Bar | Slack: #bar-team |
| Business stakeholder | Product PM Baz | Slack: #product-foo |
```

### 11. Postmortem / incident history (optional)

Links to past incidents this runbook has been used for, with outcomes. Helps future on-calls learn from patterns.

Don't duplicate postmortem content; link. If a past incident resulted in a runbook change, note the change ("Added step 3 after INC-1142") so on-calls trust the edit history.

## Length

A small alert runbook might be 80 lines. A large multi-scenario service runbook might be 400. Length is not the metric; whether a sleep-deprived on-call can execute it correctly is.

Things that almost always bloat a runbook:

- Architectural narrative (link to the README)
- Theory of why the failure happens
- Postmortem content (link to the postmortem)
- Speculation about future improvements
- Rationales for each step

Things that are worth the length when present:

- More resolution scenarios, if the component has distinct failure modes
- More detail in What NOT To Do, if the system has non-obvious footguns
- More specific severity criteria, if on-call keeps miscalling severity

## Process

1. **Check whether your team already has a runbook template or convention.** If yes, use it. If no team standard exists but the DATA-space template `3127574956` fits the shape of your component, anchor on it.
2. **Add each section to your task list.** Use TaskCreate with one task per section. Drafting in order prevents skipping ahead to the resolution steps (the easy part) and starving Symptoms and Severity (the hard part — getting the gate right).
3. **Write the First Check and Escalate When gates before the resolution steps.** The gates are what distinguish a runbook from a procedure list. Get the gates right, resolution steps fall into place.
4. **Each step gets an exit criterion.** If you can't write a check column for a step, rewrite the step until you can.
5. **Dry-run the runbook against a past incident.** Pick one real incident this runbook would cover and walk through it on paper. If any step doesn't apply, the runbook is wrong (or the incident was miscategorized — either way, fix one of them).
6. **Update the `Last verified` date only when someone has followed the runbook end-to-end against a real or simulated incident within the last 6 months.** An aspirational date is worse than a blank.
