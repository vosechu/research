# Audience by role

**Read this when you know who will read the document and what they do for a living.** The same facts need a different first paragraph for an executive, a director, and an engineer. This is a fourth axis: it stacks on top of any template, next to [human mechanics](appendix-human.md) and [global audience](global-audience.md). The core still applies: [doc-writing-core](doc-writing-core.md).

Pick the role first, then decide what leads. Most failed messages have good content in the wrong order for the reader.

## Pick the role

| Role | Needs in the first paragraph | Cut or move below | End with |
|---|---|---|---|
| Executive (CxO, VP) | The decision or recommendation, the cost in money, the risk, the deadline | How you got there, the mechanism, background | The ask and a date |
| Director or manager | What changes for their team: priorities, capacity, dates, and what gets delayed | Detail of the mechanism | The decision you need and a date |
| Engineer or practitioner | The problem, the mechanism, precise details. For an ask: how this connects them to the mission | Benefits lists, vague promises | A specific first step |

A message can have two readers. A request for engineers sometimes passes through a manager first: the manager needs the director row, and the engineer needs the engineer row. Write both, in that order, or send two messages.

## Executives

- **Lead with the recommendation in one sentence.** Then three key reasons, then the main risks and assumptions, then the ask and a deadline. This is the pyramid principle: answer first, support below. **[C]**
- **State the amount.** Give the total investment in money. **[C]**
- **Include only the technical detail the decision needs.** Put the rest behind a link. The mechanism is evidence, and evidence supports the answer; it doesn't come first. **[C]**
- **Name the deadline.** State the date by which you need the decision. **[C]**

## Directors and managers

- **Say what changes for their team.** Name the priorities, the capacity, and the dates that move. A director reads every request as a trade against work that the team already committed to. **[C]**
- **Give options, with what each one gains and costs.** Then recommend one. A single option with no cost listed reads as a request for a blank check. **[C]**
- **State the exact decision and the date.** "Approve option 1 by Friday" can be answered. "Let me know your thoughts" can't. **[C]**
- **Offer a way to reduce the cost.** For example: a smaller first step, a later date, or help from your own team. **[C]**

## Engineers: documentation versus asks

When the document describes a system (a design, a runbook, a PR), the core rules are enough. Give precise detail, and lead with the problem.

When the document asks engineers to take on work, a list of benefits usually fails. These parts come from public narrative practice and from research on motivation and volunteers. A good ask has all of them:

1. **Why you care.** Say what values called you to this work, what you did, and, if it's true, why you can't continue alone. This is the story of self in Ganz's public narrative. **[C]**
2. **What the reader shares with you.** Name the values that you and the reader share, such as the craft or the team. This is the story of us. **[C]**
3. **Why now.** State the urgent challenge to those values, and what the reader can do about it. This is the story of now. **[C]**
4. **A person or customer who is helped.** In a field experiment, 17 fundraising callers spent about 10 minutes with one scholarship student. One month later they had raised significantly more in donations than either of two control groups. Name one real case. **[C]**
5. **What the reader owns, learns, and shares.** Self-determination theory names three needs that underlie motivation: autonomy (what they decide), competence (how they get trained and supported), and relatedness (who they work with). **[C]**
6. **A specific first step.** Link one real issue or PR, so that the reader doesn't have to find a starting point. **[C]**

Skeleton for a short ask, with each beat in one to three sentences:

```
[Why I built it, and what changes for it]
[Who it helps, with one real example]
[What you would own, and who will teach and review]
[The first step: link]
```

### Observations from a rewrite

These come from one case: the maintainer rewrote a draft of this kind of ask, and the rewrite was stronger than the draft that followed the six parts above. They have no source. Treat them as defaults.

- **Build "us" on the mission, not only the craft.** The stronger draft said that the readers are close to customers and have seen the struggle of a migration, then said that the author doesn't want customers to suffer anymore. Shared craft (parsing, compilers) is a weaker bond than a shared problem that the reader already knows.
- **Give the real reason for the timing.** "I can't continue alone" is generic. A checkable cause is stronger: for example, that after open sourcing the author can no longer approve their own pull requests.
- **Say what you don't know.** "The remaining amount may not be translatable, but I intend to find out" presents an open problem. Engineers tend to be drawn to open problems more than to finished products.
- **Say what you get from the work, in the first person.** One plain sentence about enjoying it does more than a list of facts.
- **Frame the ask as an exchange.** "In exchange, you get to help our customers and learn how a query compiler works" reads as a fair deal.
- **Make the first step a puzzle.** An invitation to look at one hard, real change attracts people who like hard problems, and a task such as "review PR 18" does not. A playful challenge can read differently across cultures, so weigh it against [global audience](global-audience.md).
- **Answer the reader's likely objection.** If the readers may think that they lack a skill or access (for example, no Splunk account), say in one sentence that they don't need it.

## Confidence in these rules

The executive rules to lead with the recommendation, state the risks, state the investment amount, and name a deadline come from two practitioner guides that the maintainer read in full ([Pyramid Principle Applied](https://managementconsulted.com/pyramid-principle/) and [Alfred's executive summary guide](https://get-alfred.ai/blog/how-to-write-an-executive-summary)). They are guides, not controlled studies.

The engineer rules rest on three sources that the maintainer read in full: the Grant field experiment, the volunteer-engagement paper, and the Commons Library guide to Ganz's method. Two limits apply. The Grant paper tested the "perceived impact" explanation only in a lab experiment, not in the fundraising field experiment. The volunteer paper is a survey of 450 volunteers, so it shows links between the three needs and engagement, not that volunteers require them. One cited-by-search source, a study of newcomer barriers in open-source projects, could not be read (HTTP 403), so no rule here relies on it.

The director rules rest on guides for writing decisions to senior readers, not on studies of requests between engineering teams, so each match is partial:
- **Options, then one recommendation:** the [Stanford Law policy memo guidelines](http://law.stanford.edu/wp-content/uploads/2015/04/Policy-Memo-Guidelines-2.pdf) say to explain the pros and cons of each option and to identify the one that is recommended, and a [former senior civil servant's guide to submissions](https://civilservant.org.uk/skills-submissions.html) says to give the merits and demerits of each option and to recommend a specific course of action. Both read in full.
- **The decision and the date:** the civil service guide has a "Timing" section for the time scale within which the decision must be taken. The Stanford guide has no deadline wording. The US Army correspondence regulation says to use a date "if a reply is needed by a certain date" and not to impose one "without a compelling reason," so a date is for a real need. The [Behavioural Insights Team handbook](https://www.bi.team/wp-content/uploads/2014/04/BIT-EAST-handbook.pdf) says to be specific about recommended actions.
- **What changes for the team:** only an inference. The abstract of [Frederick and colleagues (2009)](https://doi.org/10.1086/599764) says consumers must generate the alternatives that a choice displaces, and often fail to. The studies are about purchases, and neither guide covers what a request displaces.
- **A way to reduce the cost:** only an inference. The same handbook shows that reducing the effort of an action raised take-up, for the person who acts. That is not the same as offering a smaller request.

Treat all four as defaults, and adjust when the reader tells you something different. [Sources](sources.md) lists what was read and what was not.

---

**Sources cited:**
- Ganz public narrative: [The Power of Story: The Story of Self, Us and Now](https://commonslibrary.org/the-power-of-story-the-story-of-self-us-and-now/) (Leading Change Network; a guide to Ganz's method).
- Beneficiary contact: [Grant, Campbell, Chen, Lapedis, and Lee (2007), "Impact and the art of motivation maintenance"](https://faculty.wharton.upenn.edu/wp-content/uploads/2012/05/GrantCampbellChenCottoneLapedisLee_ImpactAndArt.pdf), Organizational Behavior and Human Decision Processes 103, 53-67.
- Volunteer needs: [Fernandes and Aires de Matos, "Towards a better understanding of volunteer engagement"](https://knowledge.unv.org/sites/default/files/2023-09/Towards%20a%20better%20understanding%20of%20volunteer%20engagement.pdf).
- Executive structure: [Pyramid Principle Applied](https://managementconsulted.com/pyramid-principle/), [How to Write an Executive Summary That Gets Acted On](https://get-alfred.ai/blog/how-to-write-an-executive-summary).
