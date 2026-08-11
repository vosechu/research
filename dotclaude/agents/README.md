# Expert agents

Two groups of agents live here. Canonical source is `dotclaude/`; `link.rb`
symlinks this dir into `~/.claude/agents/` so all of them are available in every
project. A project's own `.claude/agents/` overrides one of these by name when it
needs a specialized, project-loaded version.

## SLC experts

Five SLC (Security, Legal, Compliance) consulting agents, each loaded with deep
NR institutional knowledge.

| Agent | Use when... |
|---|---|
| `@security-expert` | Security implications — SSO/SAML, encryption, threat models, vulnerability scanning, SecRev process |
| `@legal-expert` | Licenses, ToS/EULA, DPAs, open source policy, vendor agreements, IP/trademark |
| `@compliance-expert` | FedRAMP, SOC 2, PCI DSS, ISO 27001/42001, HIPAA, vendor GRC maturity, audit readiness |
| `@it-procurement-expert` | Tool Catalog, VMO process, New Tool Intake, Zscaler, VRI vs SLCRev |
| `@ai-privacy-expert` | AI/ML governance, Nerd Completion / LLM gateway, ISO 42001, data privacy, GDPR, customer data in AI |

The SLC agents can search NR Confluence via the Bedrock KB MCP (knowledge_base_id
`HY4AE7VVIR`), search the web, and reference `rules/engineering-standards.md`.

## Game-dev team

Six engine-agnostic game-dev personas (codenamed) for any game project. They carry
cross-game *craft and opinions* only — no project lore and no engine specifics.
Each reads the project's own `CLAUDE.md`/design docs at runtime for the vision, and
the programmer loads an **engine knowledge skill** (`vintagestory-modding`,
`godot-programming`) for version-correct API detail. A game repo that wants a
specialized version drops its own `.claude/agents/<name>.md` to override.

| Agent | Codename | Use when... |
|---|---|---|
| `@game-designer` | Mochi | Systems, feedback loops, motivation, emergence, pacing, vision coherence |
| `@game-programmer` | Bramble | Implementation & code review, architecture, tick/loop, AI, save/net, performance; "how does this engine work" / "why won't my class load" (loads the engine skill) |
| `@game-qa` | Kibble | Edge cases, failure modes, scale/soak/save stress-testing, coverage gaps |
| `@community-modder` | Patches | Modding/extensibility, mod compatibility, ecosystem + upstream-fork etiquette |
| `@narrative-designer` | Parcel | Voice, tone, world-building, naming, player-facing strings |
| `@accessibility-advocate` | Pebble | Input parity, color-independent signals, cognitive load, audio→visual backups |

Provenance: the original end-to-end SLCBot design (CLI + Slackbot + orchestrator)
is in [`slcbot-design.md`](slcbot-design.md); these agents are its standalone
form. To build more agents, see the `building-expert-agents` skill.
