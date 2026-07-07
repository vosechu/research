# Expert agents

Five SLC (Security, Legal, Compliance) consulting agents, each loaded with deep
NR institutional knowledge. Canonical source lives here in `dotclaude/`; `link.sh`
symlinks this dir to `~/.claude/agents/` so the agents are available in every
project. The `research` repo's `.claude/agents/` also symlinks back to these files.

| Agent | Use when... |
|---|---|
| `@security-expert` | Security implications — SSO/SAML, encryption, threat models, vulnerability scanning, SecRev process |
| `@legal-expert` | Licenses, ToS/EULA, DPAs, open source policy, vendor agreements, IP/trademark |
| `@compliance-expert` | FedRAMP, SOC 2, PCI DSS, ISO 27001/42001, HIPAA, vendor GRC maturity, audit readiness |
| `@it-procurement-expert` | Tool Catalog, VMO process, New Tool Intake, Zscaler, VRI vs SLCRev |
| `@ai-privacy-expert` | AI/ML governance, Nerd Completion / LLM gateway, ISO 42001, data privacy, GDPR, customer data in AI |

All agents can search NR Confluence via the Bedrock KB MCP (knowledge_base_id
`HY4AE7VVIR`), search the web, and reference `rules/engineering-standards.md`.

Provenance: the original end-to-end SLCBot design (CLI + Slackbot + orchestrator)
is in [`slcbot-design.md`](slcbot-design.md); these agents are its standalone
form. To build more agents, see the `building-expert-agents` skill.
