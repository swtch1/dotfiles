---
name: second-opinion
description: "Get a second opinion via subagent, Codex, or Gemini. Use when the user asks for a second opinion, wants feedback from another AI, says 'double-check this', 'verify this approach', 'validate my thinking', or explicitly requests external AI review. Also trigger when the user seems uncertain about a major decision and could benefit from cross-model validation."
---

# Second Opinion

Three review sources — pick based on complexity.

| Source | How | Best for |
|--------|-----|----------|
| **Subagent** | Agent tool (no CLI needed) | Fast, zero-setup, best available model in-process |
| **Codex** | `codex` CLI (`gpt-5.4`) | Codebase-aware exploration, deep reasoning |
| **Gemini** | `gemini` CLI (`gemini-3.1-pro`) | Factual verification, API/SDK correctness |

## How Many Sources?

- **Simple** (naming, style, single-function logic) → Subagent only
- **Medium** (multi-file change, API usage, design choice) → Subagent + Codex or Gemini
- **Complex** (architecture, security, large refactor) → All three

When unqualified ("get a second opinion"), gauge complexity and pick accordingly. When in doubt, use more.

## Subagent

Spawn a `general-purpose` Agent. If you're not on the best available model, the subagent routes to a higher tier automatically — highest value, lowest friction. If you're already on the best model, a subagent still provides a fresh perspective (separate context, no anchoring), but skip it for trivial reviews. Use your environment context to judge your model tier; when uncertain, spawn it.

## Codex

```bash
codex exec -m <Codex model> -s read-only -C <repo-path> "$(cat <<'EOF'
<query — reference files by path and line range, not code blocks>

IMPORTANT: Provide feedback and analysis only. DO NOT modify any files.
EOF
)"
```

## Gemini

```bash
gemini -m <Gemini model> -p "$(cat <<'EOF'
<query — reference files by path and line range, not code blocks>

IMPORTANT: Provide verification and analysis only. DO NOT modify any files.
EOF
)"
```

## Query Tips

- Reference files by path and line range — all sources work better with pointers than pasted code
- Provide the "what" and "why", not just "review this"
- Frame specific questions: security implications, edge cases, correctness, alternatives

## Gotchas

1. **External tools are read-only** — always include `DO NOT modify any files`.
2. **Codex may hallucinate file paths** — verify before acting on feedback.
3. **Gemini can be confidently wrong** — cross-check claims against actual code/docs.

## Misc

- If invoked bare (`/second-opinion`), review whatever you just proposed. If nothing obvious, ask.
- Flag conflicting advice between sources — present both perspectives.
- Set large timeouts (30m) on Bash calls to external tools.
