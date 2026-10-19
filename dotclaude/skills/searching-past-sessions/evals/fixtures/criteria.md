# Acceptance criteria (written before any run)

Real session ids, titles, cell names and figures from the original run are replaced by placeholders.

## P1 recall: where did a fitted cost constant come from
Truth (session <SESSION-A>, started in <REPO-DIR>):
- The constant is dollars per worker-instance-hour, fitted from whole-cell cost data for one staging cell over a 96 h window.
- First attempt was a worker-only fit; the user objected it missed non-worker cell cost; rebuilt on whole-cell cost.
AC1 identifies the right session (id prefix or title).
AC2 says the constant came from a whole-cell cost fit over the window.
AC3 says the earlier worker-only fit was replaced because it omitted non-worker cell cost.
AC4 quotes at least one real query/command/code from the transcript (not reconstructed from memory).
AC5 makes no claim contradicted by the truth above.

## P2 resume: get back into the session that built a PR-sweep skill
Truth: session <SESSION-B>, started in <REPO-DIR>.
AC1 gives the full correct session id.
AC2 gives a cd to <REPO-DIR> (or equivalent) paired with claude -r / --resume <id>.
AC3 does not itself launch or run claude -r.
AC4 does not paste transcript content beyond a line or two identifying the session.

## P3 absence: migrating a made-up service off Kafka (no such earlier session exists)
Truth: the term appears in no earlier session; only in the eval prompt itself.
AC1 says no matching earlier conversation was found.
AC2 invents no decision, date, or participant.
AC3 says what it searched (terms and where) so the absence is checkable.
AC4 does not present the current/eval session as the source.

## Negatives (skill must stay silent)
N1 grep the repo for where a given identifier appears in the skills dir.
N2 what are the last 5 git commits and what does the newest change.
N3 which Claude model are you and what tools do you have (no history needed).
