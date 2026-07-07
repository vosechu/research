# evals — evaluating-skills worked example

A self-contained eval pack in the `dotclaude/skills/double-check/evals` shape. It is both the
worked example for `evaluating-skills` and its recorded findings. The fixtures are **synthetic
and purpose-built** — two tiny skills designed so each axis of the eval produces a clean,
legible result — rather than sprawling real skills. (A real-world run is pointed to at the end.)

## Subjects (synthetic fixtures)

- **`commit-crafter`** (`fixtures/commit-crafter.SKILL.md`) — description: *"Use when writing a
  git commit message."* The **specialist**; body enforces Conventional Commits.
- **`pr-writer`** (`fixtures/pr-writer.SKILL.md`) — description: *"Use when writing a pull
  request description **or a git commit message**."* Deliberately **overlaps** commit-crafter on
  the commit surface (to exercise competition) and is broader (owns PRs too).

Designed-in expectations: on a *commit* task both match but the specialist should win; on a *PR*
task only pr-writer applies; a *rename* task should fire neither; and forcing commit-crafter on
should tighten commit-message format vs. no skill.

## How to run (native, no install)

- **Triggering** — decision-to-load proxy: present a subagent with *only* the skill
  description(s) + a situation and ask whether it'd invoke. Isolated = one description;
  competitive = both. The proxy is an **upper bound** (asked directly, the model rationalizes
  "yes"), so read the *deltas*, not absolutes. (Real auto-trigger would require installing the
  fixtures as live skills, as the wild run below did with an installed skill.)
- **Effectiveness** — force-paste the skill body into the subject vs. a clean control, then a
  blind judge grades both against pre-committed acceptance criteria and picks the better.

## Triggering — isolated baseline (each description alone)

| description | commit task | PR task | rename (near-miss) |
|---|---|---|---|
| `commit-crafter` | **YES** | NO | NO |
| `pr-writer` | YES (overlap) | **YES** | NO |

commit-crafter is the commit specialist; pr-writer matches commit *and* PR; neither matches the
near-miss. Transcripts: `ae9c34db` (commit, tightened — see caveat), `a74eb104` (PR), `ad77ebd1`
(rename); `aa678e79` (commit), `a510c1ca` (PR), `ad70ecad` (rename).

**Proxy caveat (recorded because it bit us):** the first commit probe answered *"NO — the
description matches, but no such skill exists in my roster."* The subagent checked its **real**
tool list instead of judging the hypothetical. Fix: prompt must say "assume this skill exists;
judge only whether the description matches." The re-run (`ae9c34db`) then returned a clean YES.

## Triggering — competitive (both descriptions live)

| task | winner | why |
|---|---|---|
| write a commit message | **`commit-crafter`** (A) | exact match beats the broader pr-writer |
| write a PR description | **`pr-writer`** (B) | commit-crafter doesn't cover PRs |

The **specialist wins its surface**; the broader skill wins where only it applies. No tie, no
collision. Transcripts: `adc2aacc` (commit→A), `a1ef2939` (PR→B).

## Effectiveness — commit-crafter vs. control (blind A/B)

One commit-message task (add backoff+jitter to a retry path), 2 reps/arm (n=2 — small).
Force-pasted commit-crafter vs. no-skill control; an independent judge (`a9d3bf46`) graded four
unlabeled, shuffled outputs against pre-committed ACs and clustered them.

| AC (grades output quality) | with-skill (2 reps) | control (2 reps) |
|---|---|---|
| AC1 Conventional-Commits form | pass | pass |
| AC2 subject ≤50 chars | **closer (53)** | fail (64–65) |
| AC3 body explains *why* | pass | pass |
| AC4 no vague/stray content | pass | 1 fail (stray `Co-Authored-By` trailer) |
| **Blind A/B** | **✓ stronger cluster** | — |

Judge, verbatim: *"There is a clean two-cluster split, and it falls on the subject line, not the
body (all four bodies pass AC3). Strong cluster … scoped `fix(payments):` subjects, ≤53 chars …
Weaker cluster … no scope, subjects of 64–65 chars … Output 1 mislabels the type as `feat`;
Output 3 appends an out-of-place authorship trailer."*

The judge picked the with-skill cluster **without knowing which was which**. Transcripts:
with-skill `a58fbee7`, `a66415451`; control `a521dc5e`, `aaa35f91`; judge `a9d3bf46`.

## Meta-finding

The skill's uplift is **format discipline, not reasoning**: every arm explained *why* well (the
base model is fine at that), but only the with-skill arm used a scope and a short subject.
Crucially, **the with-skill arm still fails the strict ≤50 bar (53 chars) — it wins the A/B but
doesn't clear the absolute AC.** That's "a relative win isn't an absolute pass" demonstrating
itself: report both the A/B winner *and* the AC pass/fail, or you'd overstate the skill.

## Threats to validity

- Triggering is the **decision-to-load proxy** (upper bound), not real auto-trigger — trust
  deltas, not absolutes; the misfire above shows the proxy is prompt-sensitive.
- Effectiveness n=2/arm (small; the cluster split was consistent across reps).
- Synthetic fixtures are legible by design — real skills are messier (see below).

## Applied in the wild (2026-07-01)

The same method was run against three real standards skills — PR112's `check-engineering-standards`,
dboisvert's `resilience-standards`, and the installed `nr:check-engineering-standards` (real
auto-trigger, since it's installed). Headline: the installed skill fired **0/3** on "write a CDD"
(`write-gooder` owned that surface), while `resilience-standards` fired **4/4** on resilience and
stayed silent elsewhere — complementary, no collision; and the isolated-baseline proxy showed the
installed skill's description *does* match a CDD, so its weak showing was **suppression, not
wording**. Raw transcripts for that run live in the session's `subagents/` directory.
