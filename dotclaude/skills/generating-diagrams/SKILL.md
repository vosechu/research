---
name: generating-diagrams
description: Use this skill to turn a system into a picture. If the user wants you to produce any of these — architecture diagram, flowchart, sequence diagram, ER (entity-relationship) diagram, C4 context/container/component diagram, UML class diagram, data-flow, network, or trust-boundary/auth-flow diagram — invoke it. Works for any tool: Mermaid, D2, PlantUML, Whimsical, SVG. This is what the user is after when they say "draw," "diagram," "visualize," "map out," "sketch," "show how X works," "put together a flowchart," or list components with arrows ("Customer S3 -> query cell -> NRDB," "workers assume a role into the customer account — draw it up"). Naming a diagram type, or asking to picture a system's structure, flow, entities, relationships, accounts/VPCs, or boundaries, is itself the trigger — act on it without waiting for the words "make a diagram." Skip only for prose/text summaries, NRQL or metric charts, slide-deck copy, or fixing render errors in a diagram you didn't create.
---

# Generating diagrams

Generate technical architecture diagrams as **diagram-as-code**, letting a layout
engine place the shapes. This skill exists because hand-placing shapes by
coordinate — fighting an auto-router box by box — reliably produces crossing
lines and labels stacked on boxes. The fixes here come from a real failed attempt
plus published practice (sources at the bottom).

## The rule that matters

**Describe the graph as text; let a layout engine place it. Never hand-place
shapes at x/y coordinates.** Express *relationships and grouping*; delegate
*placement*.

Why: a coordinate-nudging approach to a Whimsical board, across many iterations,
produced exactly the mess this skill prevents — crossings and label collisions
that the engine would have avoided. Text DSLs also cost up to ~24x fewer tokens
than coordinate formats (draw.io XML, Excalidraw JSON), so the model generates and
edits them reliably. Reach for a coordinate or board API (Whimsical
`flexbox_compose`, raw SVG) only when placement must be pixel-exact and you accept
owning the layout.

## Pick a format

| Use | Format | Why |
|---|---|---|
| Living docs, READMEs, inline GitHub/Confluence | **Mermaid** | Most training data, simplest syntax, renders everywhere. Weak spot: dagre auto-layout crosses lines on dense graphs. |
| Dense graphs where account/VPC grouping carries meaning, or you want real AWS icons | **D2** or **PlantUML + awslib** | First-class containers (`vpc { api; db }`), ELK/TALA layout, official icon sets. Mermaid has none. |
| Pixel-exact placement | Whimsical / SVG | Last resort. You own the layout. |

"D2 is cleanest" is contested — the loudest benchmark is D2's own vendor, though
independent practitioners agree. Try it for dense AWS diagrams; don't treat it as
settled.

## Layout

- **One abstraction level per diagram** (C4: Context → Container → Component →
  Code). Mixing levels is the "big ball of mud." Most needs are Context +
  Container.
- **One flow direction, stated up front.** `LR` for pipelines (agents → gateway →
  S3 → query, read left-to-right); `TD` for call hierarchies. Whimsical import
  needs one direction for the whole diagram — no per-subgraph `direction`.
- **Group by trust/ownership boundary** (AWS Cloud → Region → VPC → subnet) as
  containers, never by hand-placing. **Drop any boundary constant across the
  diagram** — single region means no Region box.
- **Edge crossings are the engine's job.** When they persist, force locality by
  grouping related nodes into a container. If dagre can't resolve it, switch to
  D2/ELK.

## Encoding

- **One thing per visual channel.** Color = ownership OR flow, never both. (A good
  default: box color = ownership, arrow color = flow.)
- **Title + legend on every diagram.** Survive B&W print and color blindness.
- **Every edge: one direction, one label, naming the intent** — "reads via
  AssumeRole / STS", not "uses".
- **Every node states type + technology** — "S3 bucket", "Trino query engine".

## The generation loop

This loop is the most evidence-backed quality lever (DiagrammerGPT, COLM 2024 —
a planner proposes layout as text, an auditor critiques the render, the planner
refines). Run it; don't one-shot a dense diagram.

1. **Plan as text first** — list nodes, their groups, edges with labels, before
   any DSL. Catches structure problems early.
2. **Generate the DSL** with direction + grouping specified up front.
3. **Render it** (mermaid.live, a renderer, or paste into Whimsical).
4. **Critique the rendered image** — look at the PNG, hunt for crossing lines,
   label/box collisions, grouping violations.
5. **Regenerate** the offending part. Shorten colliding labels; move long
   explanations to numbered call-outs with a key, not fat edge labels.
6. **Validate syntax** through the renderer before claiming done — models emit
   subtly invalid DSL.

## Whimsical specifics

If the target is a Whimsical board (via the desktop MCP):

- Paste Mermaid onto a board (`Cmd`+`V`) and it renders as editable shapes:
  `subgraph` → grouped shapes, `classDef` + inline `:::class` → colors,
  `linkStyle N` → connector color by 0-based index.
- **One direction for the whole diagram.** Per-subgraph `direction` mangles the
  import.
- Use inline `:::className` with a matching `classDef`, not the `class NODE name`
  statement.
- Keep labels plain text — the importer's node-shape grammar doesn't list HTML
  like `<b>`. `<br>` is risky; replace with a space if it renders literally.
- The MCP auto-groups connected nodes into a flowchart and re-runs auto-layout —
  this is what fights hand-placement. If you use the MCP, build the whole graph as
  one flowchart and let it lay out. Don't place boxes, then wire them.

## Failure modes → fixes

| Symptom | Fix |
|---|---|
| Crossing lines | Group related nodes into a container; one flow direction; D2/ELK if dagre fails. |
| Label collides with box | Render→critique→refine; shorten labels; numbered call-outs + key. |
| Auto-layout fights grouping | Express grouping as containers/subgraphs; don't hand-place. |
| No visual hierarchy | Split into C4 levels — one abstraction per diagram. |
| Generic boxes, not recognizable services | AWS icon set (D2 / PlantUML awslib). Mermaid can't. |
| Invalid DSL | Round-trip through the renderer before accepting. |

## Sources

[C4 model](https://c4model.com/diagrams) ·
[DiagrammerGPT, COLM 2024](https://diagrammergpt.github.io/) ·
[format/token comparison](https://dev.to/akari_iku/analyzing-the-best-diagramming-tools-for-the-llm-age-based-on-token-efficiency-5891) ·
[D2 vs Mermaid](https://aaronjbecker.com/posts/mermaid-vs-d2-comparing-text-to-diagram-tools/) ·
[AWS diagram conventions](https://www.naddison.com/blog/2025_04_20_how_to_create_good_aws_architecture_diagrams/) ·
[LLM diagram loop](https://smcleod.net/2024/10/generating-diagrams-with-with-ai-/-llms/)
