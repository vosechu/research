# Engineering Standard template

An engineering standard exists to **codify a cross-team rule or practice so that architect-level arguments happen once, not every time a team starts a project**. When a PR reviewer or an architect points at a standard, the conversation ends — the rule is settled.

A standard is not a tutorial, a design doc, a blog post, or a "this is how our team does it" page. If it reads like opinion, it carries no weight. If it has no rationale, teams will request exceptions until there are more exceptions than adherers.

## Relationship to NR standards process

This template is a **content guide** for authoring a New Relic standard that fits in the [STAN space](https://newrelic.atlassian.net/wiki/spaces/STAN) (Quality, Engineering, or Security). The [Standards Overview](https://newrelic.atlassian.net/wiki/spaces/STAN/pages/2627863652) defines the groups, stewardship, and the review cadence. Standards are **owned by architect stewardship teams**, not individual contributors; a draft standard needs steward sign-off before it lands in STAN.

**Key process rules to know before drafting:**

- **Levels:** Every standard declares a level. `REQUIRE` (must follow), `ADOPT` (should follow), `ASSESS` (evaluate on a per-team basis), `TRIAL` (pilot before standardizing), `HOLD` (avoid; better alternative exists), `DEPRECATE` (phase out). See [terminology](https://newrelic.atlassian.net/wiki/spaces/STAN/pages/2626816521).
- **Exceptions:** Standards anticipate exceptions. A well-written standard names the situations where it doesn't apply, so architects don't have to field the same exception question repeatedly.
- **Quarterly review:** Standards are reviewed quarterly by their stewardship group. A standard that hasn't been reviewed this cycle is a yellow flag for teams considering whether to still rely on it.
- **To propose a new standard:** surface in `#architecture` (Slack) and route through the [Standards Backlog](https://newrelic.atlassian.net/wiki/spaces/STAN/pages/2628059643).

Use the canonical STAN-space structure (summary / level / group header, DESCRIPTION, GUIDANCE with per-rule Details + Rationale). This template adds content discipline on top.

## The NR standard shape

Every well-formed NR standard follows this pattern:

```markdown
| summary | <one-sentence rule> |
|---|---|
| level | <REQUIRE / ADOPT / ASSESS / TRIAL / HOLD / DEPRECATE> |
| group | <TECHNIQUE / TECHNOLOGY / PROCESS / ...> |

# DESCRIPTION
<Why this standard exists. What breaks without it.>

# GUIDANCE
## <Rule 1 name>
<The rule, stated as a MUST / SHOULD / MAY.>

### Details
<What exactly the rule requires. Examples.>

### Rationale
<Why this rule, not another. What it prevents.>

## <Rule 2 name>
<...>
```

The **rule / Details / Rationale** triad is load-bearing. Skip Rationale and teams lose the ability to argue edge cases; they'll either demand exceptions or silently ignore the rule.

## Content discipline

### The summary sentence earns its place

The summary table field is what someone sees before they click through. Make it testable.

**Lands:** "Teams MUST maintain an updated README.md in their repo."

**Misses:** "Documentation is important for team success."

The first is checkable. The second is an opinion and invites eye-rolling.

### Every rule has a Rationale — no exceptions

The single most common failure mode: a rule with no rationale. Teams read "Use protobuf for new services" without "because [specific reason]," and the rule reads as tribal preference. First time they have a reason not to, they won't.

A rationale explains what the rule **prevents**, not what it **achieves**. "Prevents accidental API-surface divergence between services" is stronger than "Ensures consistency."

If you can't write a rationale, the rule is not a standard — it's a preference. Kill the rule or go find the rationale.

### MUST / SHOULD / MAY map to the level

Use the RFC 2119 verbs consistently with the level declared in the header:

- `REQUIRE` standards use **MUST** for their rules.
- `ADOPT` standards use **SHOULD** for their rules.
- `ASSESS` / `TRIAL` standards typically use **MAY** or explicit "evaluate whether" language.

A `REQUIRE` standard whose rules all say "should" is confusing; a reviewer won't know whether an exception needs an architect's blessing.

### Name the exceptions inline

Every rule has edge cases. State them in Details, not in a separate "exceptions" section at the bottom.

**Lands:** "Teams MUST publish a license manifest for Ruby projects. Does not apply to internal-only tools where no third-party gems are used."

**Misses:** Leaving the exception unstated, then fielding three Slack questions a quarter about it.

### Keep rules atomic

Each H2 rule covers one testable thing. If a rule has three Details bullets describing three distinct requirements, split it into three rules.

**Lands:**
```markdown
## README MUST describe what the project does
### Details: ~3 sentences, concrete verb + noun, define acronyms.

## README MUST link to long-form documentation
### Details: ...
```

**Misses:** a single "README must be good" rule with twelve Details bullets covering content, links, dependencies, and FAQ.

Atomic rules are also easier to exception individually.

### No AI-writing tells

Standards that read like marketing copy lose authority. Specifically avoid:

- Puff: "comprehensive," "robust," "pivotal," "testament to"
- Hedging: "genuinely," "honestly," "truly"
- Filler: "It's worth noting that," "In many ways," "At the end of the day"
- First-person-plural preaching: "We believe that excellence means..."

Standards are prescriptive documents. Write them that way. If a reviewer could plausibly read it as aspirational, it'll be ignored on the first Monday morning.

See `references/doc-writing-core.md` and the `avoid-ai-writing` skill for a longer list of tells.

## Length

A narrow standard (one rule, tight scope) can be 40 lines. A broad standard (README, Test Plans) might be 250. Length is not the metric; whether a reviewer can point at a specific rule and end an argument is.

Things that almost always bloat a standard:

- Restating why standards exist in general (that's the Standards Overview)
- Long explanations of the terminology (link to the terminology page)
- Tutorial-style examples showing every variation
- Aspirational framing ("we aspire to...")

Things that are worth the length when present:

- More rules, if the standard covers multiple distinct testable requirements
- More Details under each rule, if the rule is easy to misinterpret
- More worked exception scenarios, if teams keep asking the same edge-case question

## Process

1. **Confirm this is a standard, not team guidance.** A cross-team, architect-blessed, quarterly-reviewed rule → standard. A single team's convention → team README or `.claude/rules/` file. Don't route team preferences through STAN.
2. **Surface in `#architecture` before drafting.** An architect or existing standard steward may already have work in progress on the topic. Drafting blindly duplicates effort and fragments the standard's home.
3. **Add each section to your task list.** Use TaskCreate with one task per rule. Drafting rule-by-rule with its Rationale forces the Rationale to exist; writing all rules first and "going back for rationales" never works.
4. **Write the summary + level + group first.** These constrain every rule that follows. Without them, the rules can drift in scope.
5. **For each rule, write the Rationale before the Details.** The Rationale disciplines the rule — if you can't say why, you're not ready to write what.
6. **Check: can every rule be exception-requested meaningfully?** A rule without a clear bar for exception ("pre-existing code," "vendor constraint," "FedRAMP override") invites endless handwaving. The Rationale tells a reader what a good exception argument looks like.
7. **Pass to a steward for review before putting it in STAN.** Standards without stewardship sign-off don't carry the weight that makes them useful.
