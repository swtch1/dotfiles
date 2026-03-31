# Merge Request Skill — Critical Invariants

These behaviors and content MUST survive any rewrite of the merge-request skill.
Before merging changes to SKILL.md or the templates, verify every item below
is still present and functional. If an item moves (e.g., from SKILL.md to a
template), that's fine — but it must land somewhere the model will read.

---

## Description Quality

1. **AI verbosity is the #1 failure mode.** The skill must explicitly warn
   that AI-generated descriptions trend verbose. "Humans skim. Every line
   must earn its place" is the minimum — calling out AI as the source of
   the problem is better.

2. **Two audiences.** The description serves the reviewer reading it now
   AND the engineer searching `git log` months later. Both personas must
   be mentioned as motivation.

3. **Group changes by intent, not by file.** The description must organize
   changes around *what they accomplish*, not which files they touch.
   File-by-file changelogs are explicitly prohibited.

4. **"What NOT to include" list.** Every template must include anti-patterns:
   file-by-file changelogs, restated commit messages, obvious implementation
   details, fluffy preambles, lists of every function touched.

## Speedscale: Security Checklist

5. **Exact 4-item checklist text.** The checklist must contain these items
   verbatim — they come from a compliance requirement, not a style preference:
   ```
   - [ ] Security impact of change has been considered
   - [ ] Code follows company security practices and guidelines
   - [ ] Pull request linked to task tracker
   - [ ] If this is a breaking change a story has been created and assigned to Ken
   ```

6. **Each item has verification rules.** The skill must tell the model HOW
   to verify each checkbox — not just list them. Specifically:
   - "Security impact considered" = review diff for credentials, auth, endpoints, deps
   - "Follows practices" = no hardcoded secrets, no disabled TLS, no SQLi, no debug endpoints
   - "Linked to tracker" = ticket ref in title + Summary section
   - "Breaking change / Ken" = depends on backward-compat assessment

7. **Verification rules include pass criteria for "nothing found."**
   Having considered security and found no issues IS a pass — the box
   gets checked. This must be stated explicitly or the model will leave
   boxes unchecked when there's nothing to report.

## Breaking Changes

8. **Breaking changes block MR creation.** When a breaking change is
   detected, the model must STOP and notify the user before creating the
   MR. For Speedscale repos, the model must refuse to create the MR if
   the user hasn't confirmed the Ken story exists.

9. **Breaking change assessment criteria.** The skill must list what
   constitutes a breaking change: API signature/behavior changes, removed
   or renamed fields/endpoints/config keys/CLI flags, changed defaults,
   required consumer updates.

## Ticket Extraction

10. **Search branch names AND commit messages.** Ticket numbers may appear
    in either location. The skill must check both, not just the branch name.

11. **Support non-SPD ticket patterns.** While `SPD-NNNN` is the primary
    pattern for Speedscale repos, the skill should also recognize other
    patterns (e.g., `JIRA-NNNN`) in branch names and commits.

## Process

12. **Push before creating.** The skill must push the branch (if not
    already pushed) before creating the MR.

13. **Output the MR URL.** After creation, the MR URL must be displayed.

---

## How to Use This File

When editing the merge-request skill:
1. Make your changes to SKILL.md and/or templates
2. Walk through each invariant above
3. For each one, confirm it's present in the files the model will actually read
4. If you moved something, verify the pointer/instruction to read the new location exists

When running evals, the regression eval set (`evals/evals.json`) tests for
several of these invariants. A passing eval suite doesn't guarantee full
coverage, but a failing one means something was definitely lost.
