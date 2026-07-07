# SLCBot Design Spec

**Date:** 2026-04-09
**Author:** Chuck (Staff Engineer, Data Platform)
**Status:** Draft

## Problem

Getting new tools and technologies approved at New Relic through the SLC Review process is painful across the entire pipeline:

1. **Unclear expectations** — Engineers don't know upfront what each review group (Security, Legal, Compliance, IT, AI/Privacy) cares about or how difficult approval will be.
2. **Tedious ticket creation** — Gathering license info, ToS details, vendor security posture, Tool Catalog status, and compliance framework impact is manual and slow.
3. **Slow review cycle** — Submissions are incomplete, leading to back-and-forth with reviewers that drags on for weeks.

## Solution

SLCBot is a Ruby tool that automates SLC Review research and ticket preparation. It uses 5 LLM-powered expert agents (via Nerd Completion / Claude 4.6 Opus) to assess a tool across every review domain and produce a readiness report with a "fight level" score.

**Core value proposition:** Engineers can rapidly understand how big of a fight they have on their hands before committing to an SLCRev, and when they do file, the ticket arrives pre-populated with the context each reviewer needs.

## Architecture

### Three Layers

```
┌─────────────────────────────────────┐
│           Interface Layer           │
│  ┌───────────┐   ┌───────────────┐  │
│  │  CLI Tool  │   │  Slackbot     │  │
│  │  (Phase 1) │   │  (Phase 2)    │  │
│  └─────┬─────┘   └──────┬────────┘  │
│        └────────┬────────┘           │
├─────────────────┼───────────────────┤
│           Core Engine               │
│  ┌──────────────┴──────────────┐    │
│  │     Assessment Orchestrator  │    │
│  │  (dispatches expert agents,  │    │
│  │   merges results, scores)    │    │
│  └──────┬───────────────┬──────┘    │
│   ┌─────┴─────┐   ┌─────┴─────┐    │
│  │  Research  │   │  5 Expert  │    │
│  │  Services  │   │  Agents    │    │
│   └───────────┘   └───────────┘    │
├─────────────────────────────────────┤
│           Data Layer                │
│  Tool Catalog (Google Sheets API)   │
│  Jira (SLCRev ticket CRUD)         │
│  Web (license/ToS/vendor lookup)    │
│  LLM (Nerd Completion → Bedrock)   │
└─────────────────────────────────────┘
```

- **Interface Layer** — CLI first (Phase 1), Slackbot added later (Phase 2). Both call the same orchestrator.
- **Core Engine** — The orchestrator takes a "tool assessment request" (tool name + context), dispatches research services and expert agents in parallel, collects results, and produces a structured readiness report.
- **Data Layer** — Adapters for external systems. Each is a separate Ruby class with a clean interface so they can be swapped/mocked.

### LLM Provider: Nerd Completion

All LLM calls go through Nerd Completion, NR's internal LLM gateway. This is required per engineering standards — no direct Anthropic API calls.

**Model:** `claude-opus-4-6` for all expert agents. Accuracy matters more than latency for SLC reviews.

**Configuration:**

```ruby
client = Anthropic::Client.new(
  api_key: ENV["NERD_COMPLETION_TOKEN"],
  base_url: ENV.fetch("NERD_COMPLETION_URL", "https://nerd-completion.service.nr-ops.net")
)
```

**Custom headers per request:**

```
nc-requesting-component-id: slcbot
nc-user-id: <username>
nc-account-id: <cost-center-id>
```

**Rate limits:** 2M tokens/min (cross-region) for Opus. With 5 parallel agents, well within limits.

**Auth:** Service token requested from #air-team. For the Slackbot (Phase 2), this is a persistent service token. For CLI (Phase 1), can use either a service token or the user's own Nerd Completion token.

## The Five Expert Agents

Each agent is an LLM-powered specialist with a focused system prompt, access to specific research data, and a structured output format. They all receive the same input (tool name, description, use case, data access needs) and produce a domain-specific assessment.

All agents use Claude 4.6 Opus via Nerd Completion.

### 1. Security Agent

**Concerns:** Authentication (SSO/SAML requirement is a hard gate), data flows, encryption at rest/transit, vulnerability posture, threat model implications, Trivy/CodeQL scan relevance, CIS benchmarks.

**Key questions it answers:**
- Does this tool meet NR's SSO/SAML requirement?
- What data does it access/store? Is any of it customer data?
- Does the vendor publish SOC 2 / penetration test reports?
- What's the attack surface (browser extension vs SaaS vs self-hosted)?

**Output:** Red/yellow/green rating + specific concerns + what the Security sub-task reviewer will likely ask.

### 2. Legal Agent

**Concerns:** License type (permissive vs copyleft vs prohibited), EULA/ToS analysis, data processing agreements, IP/trademark, open source attribution requirements, DMCA.

**Key questions it answers:**
- What license does the software use? Is it approved per NR's Open Source Usage Policy?
- Does the ToS grant the vendor rights to NR's data?
- Is there a DPA available for GDPR compliance?
- Does distribution trigger attribution or copyleft obligations?

**Output:** License classification (approved/exception-required/prohibited) + ToS red flags + what Legal will likely require.

### 3. Compliance Agent

**Concerns:** FedRAMP boundary impact, HIPAA inclusion/exclusion, SOC 2 scope, ISO 27001/42001, PCI DSS, vendor GRC maturity, data sovereignty.

**Key questions it answers:**
- Does this tool need to be in the FedRAMP boundary?
- Does the vendor have FedRAMP authorization or equivalent?
- Will this tool handle data subject to HIPAA/PCI?
- Does it affect any existing certification scope?

**Output:** Framework impact matrix (which certifications are affected) + vendor certification status + FedRAMP/HIPAA include/exclude recommendation.

### 4. IT/Procurement Agent

**Concerns:** Tool Catalog status (already approved? already denied?), existing alternatives, SSO availability, cost, VMO process requirements, Zscaler blocking status.

**Key questions it answers:**
- Is this tool already in the Tool Catalog? What's its status?
- Is there an already-approved alternative?
- Does it require a VMO ticket and budget approval?
- Is it currently blocked by Zscaler?

**Output:** Tool Catalog status + alternatives list + procurement path (VMO ticket needed? budget approval?).

### 5. AI/Data Privacy Agent

**Concerns:** AI-specific review (ISO 42001), data processing for ML/AI, customer data usage in AI features, LLM gateway requirements (nerd-completion), automated decision-making, data discovery/classification implications.

**Key questions it answers:**
- Does this tool use AI/ML on NR data?
- Does it send data to third-party AI services?
- Should it go through the LLM gateway instead?
- Does it trigger the AI-specific SLC review requirements?

**Output:** AI risk assessment + data flow concerns + whether ISO 42001 scope is affected.

### Why 5 Agents Instead of 1

Each agent gets a focused system prompt loaded with domain-specific NR policy (e.g., the Security agent's prompt includes the full SSO/SAML gate, Trivy requirements, CIS benchmarks). A single mega-prompt would exceed useful context, dilute domain expertise, and make prompt iteration harder. The 5-agent split also means each domain can evolve independently — the Compliance agent's prompt will change every audit cycle, while the Legal agent's prompt is more stable.

The trade-off is 5x the LLM calls. At Opus pricing through Bedrock, a full assessment is ~$0.50-1.00 in tokens. For a tool that replaces hours of manual research, this is acceptable.

### Agent Orchestration

The orchestrator dispatches all 5 agents in parallel using Ruby's `Async` gem (fiber-based concurrency — appropriate since all work is I/O-bound HTTP calls to Nerd Completion). Each returns a structured hash:

```ruby
{
  rating: :red | :yellow | :green,
  concerns: ["SSO not available on free tier", ...],
  reviewer_questions: ["Will this be used in FedRAMP boundary?", ...],
  summary: "..."
}
```

### Structured Output Extraction

Agents use Claude's **tool use** (function calling) to return structured JSON. Each agent call includes a tool definition matching the output schema above. This avoids regex parsing of free-text responses and gives us validated JSON with typed fields. If the model returns malformed tool use (rare with Opus), the orchestrator retries once; if that fails, it falls back to a text-only response marked as `rating: :yellow` with a note that structured extraction failed.

### Fight Level Scoring

The orchestrator computes an overall fight level from the 5 agent ratings:

| Condition | Fight Level |
|-----------|-------------|
| Any agent rates `:red` | **HIGH** — expect a difficult, lengthy review |
| 2+ agents rate `:yellow` | **MODERATE** — some concerns, prepare answers |
| 1 agent rates `:yellow`, rest `:green` | **LOW** — minor issue, likely straightforward |
| All agents rate `:green` | **RUBBER STAMP** — may not even need a new SLCRev |

Hard gate failures (SSO unavailable, prohibited license, no CDD) override to **BLOCKED** regardless of other ratings.

### Error Handling

- **Per-agent timeout:** 60 seconds. If an agent times out, its section shows "Assessment timed out — manual review needed" with `rating: :yellow`.
- **Retry policy:** 1 retry on transient errors (5xx, timeout, 429 with backoff per `Retry-After` header). No retry on other 4xx (auth errors).
- **Partial reports:** If 1-2 agents fail, the report still renders with the successful agents' output. Failed sections are clearly marked. If 3+ agents fail, the orchestrator aborts and reports the error.
- **Rate limiting:** Nerd Completion allows 100 req/min sustained. 5 parallel agents is well within this. For the Slackbot (Phase 2), add a per-user cooldown of 1 assessment per 5 minutes to prevent abuse.

### Output Mapping: 5 Agents → 3 Jira Sub-tasks

SLCRev tickets have 3 mandatory sub-tasks (Security, Legal, Compliance), but we have 5 agents. The mapping for Phase 2 ticket creation:

| Agent | Jira Sub-task | Placement |
|-------|---------------|-----------|
| Security | Security Sub-task | Primary content |
| Legal | Legal Sub-task | Primary content |
| Compliance | Compliance Sub-task | Primary content |
| IT/Procurement | Parent ticket description | "Procurement Context" section |
| AI/Data Privacy | Parent ticket description + Compliance Sub-task | Appended as "AI/Data Privacy Considerations" |

The IT/Procurement assessment goes in the parent ticket because it's context for the requester (alternatives, catalog status), not a reviewer deliverable. AI/Data Privacy findings go in both the parent (for the requester) and the Compliance sub-task (since ISO 42001 is part of compliance scope).

## Research Services

Non-LLM data-fetching components that feed the expert agents. Each is a plain Ruby class that returns structured data.

### ToolCatalogLookup

Reads the NR Tool Catalog Google Sheet (`1lkxjGtf-pKbDYQyVKyJJx3BTWDUAYeUqBUmTdIW7MDU`) via the Sheets API. Returns: approval status, category, notes, whether it's Zscaler-blocked, any existing alternatives listed.

**Schema risk:** The Tool Catalog is a manually-maintained Google Sheet. Columns may be renamed or reordered. The lookup identifies columns by header text (row 1), not by column index. If expected headers are missing, it returns `status: :error` with a descriptive message rather than silently returning wrong data.

### LicenseFetcher

Given a tool/package name, looks up the license on the appropriate registry (npm, PyPI, RubyGems, GitHub) or scrapes the project page. Returns: license type (MIT, Apache 2.0, GPL, etc.), NR classification (approved/exception-required/prohibited per Open Source Usage Policy), and the raw license text.

### TosFetcher

Fetches the tool's Terms of Service / EULA page. Returns: raw text for LLM analysis. The Legal agent processes this — the fetcher just retrieves it.

**Token budget:** ToS documents can be 5,000-15,000 words (~20K tokens). The fetcher truncates to the first 8,000 tokens and appends a note: "ToS truncated at 8K tokens — full document available at [URL]." This keeps the Legal agent's total prompt under 30K tokens while capturing the most important clauses (which are typically front-loaded in ToS documents). If the ToS is a PDF, the fetcher extracts text via `pdf-reader` gem.

**Fragility:** ToS pages are often behind click-through gates, rendered client-side (JS), or served as PDFs. The fetcher tries in order: (1) direct HTTP GET, (2) if JS-heavy, shell out to `curl | pandoc`, (3) if PDF, extract with `pdf-reader`. If all fail, the Legal agent runs with `tos_available: false` and flags "ToS could not be automatically retrieved — manual review needed" in its output. The CLI can accept a `--tos-url` flag for manual override.

### VendorSecurityFetcher

Searches for the vendor's security page, trust center, or compliance documentation. Looks for: SOC 2 reports, FedRAMP authorization status (checks FedRAMP marketplace), ISO certifications, penetration test availability, DPA/data processing agreements.

**Strategy:** Tries common URL patterns (`/security`, `/trust`, `/compliance`, `trust.{domain}`) and falls back to a web search for "{vendor} SOC 2 security compliance." Also checks the FedRAMP Marketplace API for authorization status. If no security page is found, the Security and Compliance agents run with `vendor_security_data: :unavailable` and flag the gap.

### Research Service Failure Modes

All research services return a result object that includes a `status` field (`:ok`, `:unavailable`, `:error`). When a service fails:

- **`:unavailable`** — The data source exists but returned no useful data (e.g., tool not in catalog, no ToS page found). The corresponding agent runs with partial context and flags the gap.
- **`:error`** — The service itself failed (API down, auth error, timeout). The agent runs with no data from that service and includes a warning.

Agents are designed to produce useful output even with incomplete research data — they just flag what's missing and rate more conservatively (`:yellow` instead of `:green` when data is absent).

### JiraClient

CRUD operations against the NR Jira project (project key: NR, ticket type: SLCRev). For Phase 1 (research), this is read-only — used to check if an SLCRev already exists for this tool. Phase 2 adds ticket creation with pre-populated sub-tasks.

### Data Flow

```
Input: { tool: "Snyk", use_case: "SCA scanning", data_access: "source code repos" }
  │
  ├─→ ToolCatalogLookup   → { status: :approved, notes: "..." }
  ├─→ LicenseFetcher       → { license: "Apache-2.0", classification: :approved }
  ├─→ TosFetcher           → { tos_text: "..." }
  ├─→ VendorSecurityFetcher→ { soc2: true, fedramp: false, dpa: true }
  ├─→ JiraClient           → { existing_slcrev: "NR-12345", status: "Done" }
  │
  └─→ All fed into 5 Expert Agents in parallel (Claude 4.6 Opus)
       │
       └─→ Orchestrator merges → Readiness Report
```

## CLI Interface (Phase 1)

### Commands

```bash
# Primary command — full assessment
slcbot assess "Snyk" --use-case "SCA scanning" --data-access "source code"
# --use-case and --data-access are required flags. The CLI errors without them.

# Quick lookup — just check the Tool Catalog, no LLM
slcbot lookup "Snyk"

# Interactive mode (Phase 2 — deferred until Slack interview design is finalized)
# slcbot assess --interactive
```

### Output: Readiness Report

```
═══════════════════════════════════════
  SLCBot Assessment: Snyk
  Fight Level: MODERATE
═══════════════════════════════════════

TOOL CATALOG STATUS: Approved (existing entry)
LICENSE: Apache-2.0 (Approved)
EXISTING SLCREV: NR-12345 (Done — approved 2025-06-15)

── Security ──────────────────── LOW RISK
  SSO/SAML: Available (Enterprise plan)
  Data access: Source code repos (read-only)
  Vendor SOC 2: Yes (Type 2)
  Concern: None identified

── Legal ─────────────────────── LOW RISK
  License: Apache-2.0 (Permissive — approved)
  ToS: Standard SaaS terms, no unusual data rights
  DPA: Available on request

── Compliance ────────────────── MODERATE
  FedRAMP: Not authorized — if used in FedRAMP
    boundary, will need exclusion or alternative
  HIPAA: N/A (no PHI involved)
  ISO 27001: In scope if processing NR data

── IT/Procurement ────────────── ALREADY APPROVED
  Tool Catalog: Approved
  VMO: Existing contract
  Alternative: Dependabot (also approved)

── AI/Data Privacy ───────────── LOW RISK
  No AI/ML processing of NR data
  ISO 42001: Not in scope

── RECOMMENDATION ──────────────────────
  This tool is already approved. If your use case
  matches the existing approval, no new SLCRev needed.
  If expanding scope (e.g., new data types), file a
  "Change to Existing Service" SLCRev.

  Estimated review difficulty: LOW
  Likely blockers: None identified
═══════════════════════════════════════
```

## Slackbot Interface (Phase 2)

### Interview Flow

```
Engineer: /slcbot
Bot: Hi! I'll help you assess a tool for SLC review.
     What tool or technology are you evaluating?
Engineer: DataDog RUM
Bot: What's the use case?
     - New tool for the team
     - Replacing an existing tool
     - POC / evaluation
     - Adding a feature to an already-approved tool
Engineer: [clicks "New tool for the team"]
Bot: What kind of data will it access?
     - No NR data (internal tooling only)
     - Source code
     - Customer telemetry data
     - Customer PII / account data
     - NR corporate data
Engineer: [clicks "Customer telemetry data"]
Bot: Will this be used in production (FedRAMP boundary)?
Engineer: No, just staging
Bot: Got it. Researching DataDog RUM now...
Bot: [posts readiness report as a rich Slack message]
Bot: Want me to create an SLCRev ticket with these findings pre-filled?
Engineer: Yes
Bot: Created NR-67890. Sub-tasks created for Security,
     Legal, and Compliance with pre-populated summaries.
     Link: https://new-relic.atlassian.net/browse/NR-67890
```

### Slack-Specific Components

- **SlackApp** — Built on `slack-ruby-client` gem (there is no official Slack Bolt SDK for Ruby). Handles slash command via Slack Events API, interactive messages (button clicks for multiple choice), and threaded conversation state. Socket Mode for development, HTTP events for production.
- **InterviewStateMachine** — Tracks where the user is in the interview. Each step maps to a question + expected input type. Stored in-memory or Redis for multi-turn conversations.
- **JiraTicketCreator** — Extends the read-only JiraClient from Phase 1. Creates the parent SLCRev ticket + 3 sub-tasks (Security, Legal, Compliance) with pre-populated descriptions drawn from the expert agent outputs.
- **ReportFormatter** — Transforms the readiness report into Slack Block Kit format (colored sections, expandable details).

## Project Structure

```
slcbot/
├── Gemfile
├── bin/
│   └── slcbot                   # CLI entry point
├── lib/
│   └── slcbot/
│       ├── orchestrator.rb      # Dispatches research + agents, merges
│       ├── agents/
│       │   ├── base_agent.rb
│       │   ├── security.rb
│       │   ├── legal.rb
│       │   ├── compliance.rb
│       │   ├── it_procurement.rb
│       │   └── ai_data_privacy.rb
│       ├── research/
│       │   ├── tool_catalog_lookup.rb
│       │   ├── license_fetcher.rb
│       │   ├── tos_fetcher.rb
│       │   ├── vendor_security_fetcher.rb
│       │   └── jira_client.rb
│       ├── report/
│       │   └── readiness_report.rb
│       ├── cli.rb               # Thor command definitions
│       └── slack/               # Phase 2
│           ├── app.rb
│           ├── interview.rb
│           ├── report_formatter.rb
│           └── ticket_creator.rb
├── prompts/                     # System prompts for each agent (version-controlled in git)
│   ├── security.md
│   ├── legal.md
│   ├── compliance.md
│   ├── it_procurement.md
│   └── ai_data_privacy.md
└── spec/
```

## Secrets Management

All credentials are stored in environment variables, never in source code. A `.env.example` file documents required variables without values.

| Variable | Purpose | Source |
|----------|---------|--------|
| `NERD_COMPLETION_TOKEN` | LLM gateway auth | #air-team service token |
| `NERD_COMPLETION_URL` | LLM gateway endpoint | Defaults to production URL |
| `GOOGLE_SHEETS_CREDENTIALS` | Path to Google Sheets service account JSON | Google Cloud Console |
| `JIRA_API_TOKEN` | Jira read (Phase 1) / write (Phase 2) | Jira API token settings |
| `JIRA_USERNAME` | Jira auth email | Service account |
| `SLACK_BOT_TOKEN` | Slack app (Phase 2 only) | Slack app admin |
| `SLACK_SIGNING_SECRET` | Slack request verification (Phase 2) | Slack app admin |

For Phase 1 (CLI), only `NERD_COMPLETION_TOKEN`, `GOOGLE_SHEETS_CREDENTIALS`, and `JIRA_API_TOKEN`/`JIRA_USERNAME` are required.

## Caching

Research results are cached to avoid redundant API calls and LLM invocations:

- **Tool Catalog lookups:** Cached for 24 hours (the sheet doesn't change more often than that). Cache key: normalized tool name.
- **License lookups:** Cached for 7 days (licenses rarely change). Cache key: package name + registry.
- **Full assessment results:** Cached for 24 hours. Cache key: tool name + use case + data access hash.
- **ToS/vendor security pages:** Cached for 7 days. Cache key: URL.

Phase 1 uses a simple file-based cache (`~/.slcbot/cache/`). Entries are cleaned up on startup — anything past its TTL is deleted. Phase 2 (Slackbot) uses Redis if available, falling back to file cache. The `--no-cache` CLI flag bypasses all caches for a fresh assessment.

## Observability

Per NR standard O-10, the tool reports its own telemetry to New Relic:

- **Custom events:** Each assessment run emits a `SLCBotAssessment` custom event with: tool name, fight level, per-agent ratings, total duration, token usage, cache hit/miss per service.
- **Logs:** Structured JSON logs via `logger` to stdout. In the Slackbot (Phase 2), these are collected by the standard NR infrastructure agent.
- **Errors:** Exceptions are reported as `SLCBotError` custom events with stack traces.

This data feeds Phase 3 knowledge refinement — we can query NRDB to see which tools are most commonly assessed, which agents flag the most concerns, and where assessments fail.

## Nerd Completion Integration Notes

- **Anthropic-compatible endpoint:** Nerd Completion exposes `POST /v1/messages` which is wire-compatible with the Anthropic API. The `anthropic` Ruby gem works by setting `base_url` to the Nerd Completion endpoint.
- **Model identifier:** Use `claude-opus-4-6` as the model string. Verify the exact identifier with #air-team during setup, as Nerd Completion may use its own model aliases. The model ID is configured via `NERD_COMPLETION_MODEL` env var (defaults to `claude-opus-4-6`) so it can be updated without code changes.
- **Custom headers:** Nerd Completion requires `nc-requesting-component-id`, `nc-user-id`, and `nc-account-id` headers. The injection method depends on the `anthropic` gem's HTTP backend — spike this during Phase 1 scaffolding. If the gem doesn't support custom headers natively, wrap the HTTP call or use the REST API directly with `Faraday`.
- **Jira auth:** Uses basic auth (username + API token) via `jira-ruby`. Phase 1 uses a shared service account for read-only lookups. Phase 2 uses the same service account with write permissions.
- **Jira permissions (Phase 2):** Creating SLCRev tickets with sub-tasks requires the "Create Issues" and "Create Sub-tasks" permissions in the NR Jira project. Request a service account with these permissions from the Jira admin team before starting Phase 2.
- **Jira idempotency (Phase 2):** Before creating a ticket, the bot checks for an existing open SLCRev for the same tool name. If found, it links to the existing ticket instead of creating a duplicate. The interview state machine also stores a `ticket_created` flag to prevent double-submission on Slack retries.
- **Google Sheets auth:** The service account JSON must be for a Google Cloud project with the Sheets API enabled. The Tool Catalog sheet must be shared (read-only) with the service account email. Document this in the README setup instructions.

## Key Gems

| Gem | Purpose |
|-----|---------|
| `anthropic` | Claude API client (pointed at Nerd Completion) |
| `thor` | CLI framework |
| `google-apis-sheets_v4` | Tool Catalog Google Sheet |
| `jira-ruby` | Jira API client |
| `slack-ruby-client` | Slack API client (Phase 2) — 82M downloads, MIT, actively maintained |
| `async` | Parallel agent dispatch (fiber-based, I/O-bound safe) |
| `nokogiri` | Web scraping for ToS/license pages |
| `pdf-reader` | PDF text extraction for ToS documents |
| `rspec` | Testing |

## Build Phases

### Phase 1: Research Engine + CLI

**Goal:** Working CLI that produces readiness reports.

**Dependencies:** Nerd Completion service token (from #air-team), Google Sheets API credentials (Tool Catalog), web access for license/ToS/vendor lookups. System dependency: `pandoc` (for JS-heavy page conversion in TosFetcher).

**Build order:**
1. Project scaffolding (Gemfile, structure, tests)
2. Research services (ToolCatalogLookup, LicenseFetcher, VendorSecurityFetcher, TosFetcher)
3. Expert agents (system prompts + structured output parsing)
4. Orchestrator (parallel dispatch, result merging, scoring)
5. CLI interface (Thor commands, report rendering)
6. JiraClient (read-only — check for existing SLCRevs)

**Deliverable:** `slcbot assess "ToolName"` produces a readiness report.

### Phase 2: Slackbot + Jira Write

**Goal:** Slack interview flow, ticket creation.

**Dependencies:** Slack app registration, Jira API write permissions (service account with "Create Issues" + "Create Sub-tasks" in NR project), hosting via Developer Platform (per standard D-1).

**Build order:**
1. Slack app setup (Bolt-style, slash command registration)
2. Interview state machine
3. Report formatter (Block Kit)
4. JiraTicketCreator (parent + sub-tasks, see "Output Mapping" above for 5→3 mapping)
5. End-to-end integration

**Deliverable:** `/slcbot` in Slack walks through interview, creates ticket.

**Interview completeness note:** The Slack interview must also ask about budget/cost and whether the tool replaces an existing one, so the IT/Procurement agent has sufficient context. The interview questions in the flow above are illustrative — the full question set will be defined during Phase 2 implementation.

### Phase 3: Knowledge Refinement

Phase 3 is out of scope for this spec. The only Phase 1/2 architectural decision it influences: assessment results are persisted as JSON in the cache directory (and as `SLCBotAssessment` custom events in NRDB) so that future analysis of assessment patterns is possible without additional instrumentation.

## SLC Review Context

### NR Certifications & Frameworks

The following are actively maintained and audited (FY26 cycle):
- FedRAMP Moderate
- SOC 2 Type 2
- PCI DSS
- ISO 27001
- ISO 42001 (new — AI Management Systems)
- HIPAA (replacing HITRUST)
- TISAX
- GDPR / EU-US Privacy Shield
- CSA STAR

### SLCRev Ticket Structure

SLCRev tickets live in the NR Jira project. Each SLCRev has 3 mandatory sub-tasks:
1. **Security Sub-task** — threat modeling and architectural sign-off
2. **Legal Sub-task** — data scope, IP, licensing approval
3. **Compliance Sub-task** — FedRAMP/HIPAA inclusion/exclusion, vendor GRC maturity

Three work item types: New Feature Launch, Change to Existing Service/Feature, Tool POC.

### Hard Gates

These are non-negotiable requirements that will block any tool:
- **SSO/SAML required** for any app accessing NR corp or customer data
- **Approved CDD/IDD required** — unapproved design docs cause rejection
- **VMO review required** for all tools (even free ones)
- **No click-through agreements** — only authorized signers can bind the company

### Key Resources

- Tool Catalog (approved/non-approved software): Google Sheet `1lkxjGtf-pKbDYQyVKyJJx3BTWDUAYeUqBUmTdIW7MDU`
- SLC Review submission: #ask-security-legal-compliance Slack channel
- SLCRev prioritization: linked to Engineering Leadership operating plan
- Nerd Completion (LLM gateway): source.datanerd.us/air/nerd-completion, support via #air-team
- Open Source Usage Policy: Confluence OSPO space
