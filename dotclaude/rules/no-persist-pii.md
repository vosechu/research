# Do Not Persist Private Employee PII

Do not commit files that expose NR employee information people reasonably expect to remain private. Normal work context (assignment lists, tracker rows, ticket assignees, spec owners, delegation logs, meeting attendees for public meetings) is fine — this is the same information that already appears in Jira, Confluence, GitHub, and Slack posts inside the org.

**What's fine to commit:**
- Assignment and delegation lists (name + task + status)
- Ticket assignees, PR authors, spec owners
- Meeting attendees or participants from public / company-wide forums
- Any person's name where they are already publicly associated with the work in Jira/Confluence/GitHub

**What's NOT fine to commit:**
- Membership lists of private or invite-only Slack channels, mailing lists, working groups
- Team Store dumps — names + manager chains + titles + team memberships assembled from lookups, rather than incidentally appearing in work artifacts
- Direct message participants, 1:1 notes, or any information shared in a confidential setting
- Emails (even @newrelic.com) when not already public in the work record
- Health, performance, comp, or HR-adjacent information about anyone
- Home addresses, personal phone numbers, or any personal contact info

**Why:** Internal work surfaces like assignments are already visible to colleagues through Jira/Confluence. Private channel membership, 1:1 content, and directory lookups carry a reasonable expectation of privacy — those should stay out of version control.

**How to apply:**
- When the user asks to capture delegation status, spec ownership, or ticket assignees, write names into the file as normal.
- When doing Team Store or people-directory lookups, present results in conversation but don't bulk-write them to files unless the user explicitly asks for a committed reference.
- When asked to capture who's in a private Slack channel or invite-only group, refuse or stage the file as gitignored and flag why.
- If unsure whether a given surface is "already public in the work record," ask the user.
