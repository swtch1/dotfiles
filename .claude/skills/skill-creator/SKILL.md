---
name: skill-creator
description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations.
license: Complete terms in LICENSE.txt
---

# Skill Creator

## Skill Structure

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter: name + description (required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/     - Executable code; token-efficient, deterministic, run without loading into context
    ├── references/  - Docs loaded into context as needed; keeps SKILL.md lean
    └── assets/      - Output files (templates, images, fonts); never loaded into context
```

**Frontmatter quality matters.** `name` and `description` determine when Claude uses the skill. Be specific. Use third-person: "This skill should be used when..." not "Use this skill when..."

**Progressive disclosure:** Metadata (~100 words) always in context → SKILL.md body loads on trigger (<5k words) → Bundled resources load as needed.

### Resource Guidelines

| Resource | Include when | Example |
|----------|-------------|---------|
| `scripts/` | Same code rewritten repeatedly, or deterministic reliability needed | `scripts/rotate_pdf.py` |
| `references/` | Claude needs docs while working; if >10k words, add grep patterns to SKILL.md | `references/schema.md` |
| `assets/` | Files used in output, not in reasoning | `assets/template/`, `assets/logo.png` |

- Information lives in SKILL.md OR references, never both. Prefer references for detailed content.
- Scripts may still need reading for patching or environment-specific adjustments.

## Skill Creation Process

Follow steps in order. Skip only when clearly not applicable.

### Step 1: Understand Usage with Concrete Examples

Skip if usage patterns are already clear.

Gather concrete examples of how the skill will be used — from the user directly or by proposing examples for validation. Key questions:

- "What functionality should this skill support?"
- "Can you give examples of how it would be used?"
- "What would a user say that should trigger this skill?"

Avoid asking too many questions at once. Conclude when the skill's scope is clear.

### Step 2: Plan Reusable Contents

For each concrete example, analyze: (1) how to execute from scratch, (2) what scripts, references, or assets would help when doing it repeatedly.

| Example query | Analysis | Resource |
|--------------|----------|----------|
| "Rotate this PDF" | Same rotation code rewritten each time | `scripts/rotate_pdf.py` |
| "Build me a todo app" | Same boilerplate each time | `assets/hello-world/` template |
| "How many users logged in today?" | Re-discovering table schemas each time | `references/schema.md` |

### Step 3: Initialize the Skill

Skip if the skill already exists.

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

Creates skill directory with SKILL.md template (frontmatter + TODO placeholders) and example `scripts/`, `references/`, `assets/` directories. Delete unneeded example files after.

### Step 4: Edit the Skill

The skill is for another Claude instance. Focus on information that is **beneficial and non-obvious** — procedural knowledge, domain-specific details, gotchas.

**Start with bundled resources** (`scripts/`, `references/`, `assets/`). May require user input (e.g., brand assets, API docs). Delete unused example directories from init.

#### Writing SKILL.md

**Writing Style:** Imperative/infinitive form (verb-first). Objective, instructional language: "To accomplish X, do Y" not "You should do X."

**Token Efficiency:** Every token in SKILL.md is a token unavailable for the actual task. Optimize ruthlessly:

- **Don't teach Claude what it knows.** Provide procedural knowledge (exact commands, gotchas, project-specific patterns), not conceptual knowledge. Claude knows what CI/CD is — it doesn't know that `glab ci view` opens a TUI that breaks non-interactive sessions.
- **Density over prose.** Tables, code blocks, terse imperative bullets. Never a paragraph where a bullet suffices. A quick-reference code block with 12 commands beats 12 paragraphs describing them.
- **Include a Gotchas section.** Highest ROI per token — these prevent mistakes Claude would otherwise make. Flag anti-patterns, inconsistent APIs, non-obvious behaviors.
- **Concrete over abstract.** Show the exact command/pattern: `glab ci trace <JOB_ID> -R <PROJECT>` beats "use the trace subcommand to view job logs."
- **Target <100 lines for SKILL.md body.** If longer, move detail to `references/`. A lean skill that fits in context alongside the task beats a comprehensive skill that crowds it out.

Answer these to complete SKILL.md:
1. What is the skill's purpose? (1-2 sentences)
2. When should it trigger?
3. How should Claude use it? (Reference all bundled resources)

### Step 5: Package the Skill

```bash
scripts/package_skill.py <path/to/skill-folder> [output-directory]
```

Validates (frontmatter, naming, structure, description quality, file organization) then creates a distributable zip. Fix reported errors and re-run.

### Step 6: Iterate

1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Update SKILL.md or bundled resources
4. Test again
