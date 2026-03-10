---
name: second-opinion
description: "Get external AI review from Codex and Gemini models. Use when the user asks for a second opinion, wants feedback from another AI, says 'double-check this', 'verify this approach', 'validate my thinking', or explicitly requests external AI review. Also trigger when the user seems uncertain about a major decision and could benefit from cross-model validation."
---

# Second Opinion

Consult external AIs for review and validation. Two tools available — use one or both depending on context.

## Models

- **Codex model**: `gpt-5.3-codex`
- **Gemini model**: `gemini-3.1-pro-preview`

## When Invoked Without Explicit Context

If triggered with no specific query (e.g., bare `/second-opinion` command), look at what you just sent to the user.  If you were proposing something they want you to get a second opinion on that proposal. If still nothing obvious, ask the user what they want reviewed — don't guess.

## Tool Selection

| Situation | Tool | Why |
|-----------|------|-----|
| Plan/architecture review | `codex` | Deep reasoning, codebase-aware exploration |
| Implementation review | `codex` | Can navigate repo to check edge cases |
| API/SDK correctness | `gemini -p` | Strong at factual verification |
| Technical claim validation | `gemini -p` | Cross-reference accuracy |
| Major implementation / "both" | Both | Maximum coverage |

Default when user says "get a second opinion": fire **both**.

## Commands

### Codex (codebase-aware review)

```bash
codex exec -m <Codex model> -s read-only -C <repo-path> "$(cat <<'EOF'
<query with context — file paths and line numbers, not code blocks>

IMPORTANT: Provide feedback and analysis only. You may explore the codebase with commands but DO NOT modify any files.
EOF
)"
```

### Gemini (correctness verification)

```bash
gemini -m <Gemini model> -p "$(cat <<'EOF'
<verification query with specific details>

IMPORTANT: Provide verification and analysis only. DO NOT modify any files.
EOF
)"
```

## Query Guidelines

- Reference files by path and line range — both tools work better with pointers than pasted code
- Both tools have full repo access — reference files by path and line range rather than pasting code
- Provide the "what" and "why", not just "review this"
- Frame specific questions: security implications, edge cases, correctness, alternatives

## Integration

- Evaluate responses against codebase realities and each other
- Flag conflicting advice between the two tools — present both perspectives
- If either identifies issues you missed, acknowledge them
- If anything is unclear, ask the user — don't guess

## Gotchas

1. **Both are read-only** — always include `DO NOT modify any files` in the prompt.
2. **Codex may hallucinate file paths** — verify referenced paths exist before acting on feedback.
3. **Gemini can be confidently wrong** — cross-check factual claims against actual docs/code.
4. **Both tools have repo access** — reference files by path and line range. Neither needs code pasted inline.
