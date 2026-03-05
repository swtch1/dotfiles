---
date: 2026-03-05T13:00:23-05:00
git_commit: N/A (not a git repo)
branch: N/A
repository: ~/.claude/skills
ticket: N/A
summary: Token reduction of the spec skill — 8 changes implemented, ~12% reduction
---

# Handoff: Spec Skill Token Reduction

## Task(s)
- **COMPLETED**: Reviewed `spec/SKILL.md` for token reduction opportunities while preserving execution capability
- **COMPLETED**: Got second opinions from Codex and Gemini validating the approach
- **COMPLETED**: Implemented 8 approved changes across 3 files

## Critical Context
- `spec/SKILL.md` — the main skill file, now 346 lines (was 383). All 8 changes applied.
- The user's constraint: "everything in there is important" — compress, don't delete. Every cut was validated against execution impact.

## Working Set
- `spec/SKILL.md` — primary edit target (all 8 changes)
- `spec/assets/feature-template.md:83-88` — Implementation Delta comment block shortened
- `spec/assets/bugfix-template.md:71-75` — Implementation Delta comment block shortened
- `spec/assets/domain-template.md` — untouched
- `spec/assets/agents-template.md` — untouched
- `spec/scripts/init-specs.sh` — untouched

## Learnings
- **Probing loop cascade is behavior-critical**: Both Codex and Gemini independently flagged that compressing the probing loop MUST preserve the "cascade" instruction (answers generate new questions). Without it, agents fall back to static Q&A.
- **Domain doc cardinal rule needs chain-of-thought**: Gemini noted LLMs have a strong bias toward summarizing code. The self-review step ("re-read each line and ask...") is more effective than stating the rule once. Kept as distinct instruction.
- **Step 3 rules 6-8 are execution-critical**: "Real file paths", "pre-fill AGENTS.md Updates", and "alternatives" — Codex flagged these must keep their specificity even when compressing surrounding rules.
- **Moving vague lint to templates is illusory savings**: The skill always generates drafts when invoked, so runtime-loaded = always-loaded. Not worth the indirection.
- **Additional opportunities identified but NOT implemented** (user chose conservative approach): Step 0 "domain knowledge" note duplication (~40 tokens), Step 1 mini-spec paragraph → rules list (~40-60 tokens), Good/Bad question examples compression (~60-90 tokens), Cursor integration condensing (~40-60 tokens), markdown tables → bullet lists (~50-80 tokens). Total theoretical ceiling was ~1530 tokens (~26%) but user approved ~680 tokens (~12%).

## Action Items & Next Steps
1. **All approved changes are implemented.** No pending work.
2. If further reduction is desired, the additional opportunities listed in Learnings are pre-analyzed and ready to implement.

## Other Notes
- Second opinion results from Codex and Gemini are in this session's history — search for "Synthesized Second Opinion" for the consolidated analysis.
- Codex suggested structural reorganizations (merge Step 2+2.5 into single "Discovery" section, consolidate marker definitions into "Uncertainty Markers" subsection) that could save more but carry higher risk. These were not approved.
