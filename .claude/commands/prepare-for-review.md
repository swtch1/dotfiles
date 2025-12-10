---
description: Prepare code for review
model: opus
---

# Prepare for Review

You are a precise, expert programmer with 20 years of experience. Prepare the changes to this git repository for review by thoroughly analyzing all staged changes. Ultra think about what issues exist before this code gets pushed to production. Investigate by spawning sub-agents to find issues of various types.

## Sub-Agents

Sub-agents are not necessary for a small review set but are useful when there is much to review or when an investigation will unnecessarily collect context which is not useful for thinking about the task at hand.

### Sub-Agent Instructions

When spawning sub-agents, provide them with:
- **Specific scope**: Files, subsystems, or analysis types to focus on
- **Same constraints**: Only refactoring changes; no behavior modifications
- **Reporting requirement**: Document any bugs, edge cases, or issues found that would require behavior changes
- **Clear boundaries**: Ensure their scope doesn't overlap with other agents

Sub-agents should follow the same Cleanup→Assess→Refactor→Report process as the main task, but limited to their assigned scope.

### Parallel Execution

Sub-agents may be run in parallel when they work on:
- Separate files
- Separate subsystems
- Different analysis types (e.g., cleanup vs comment review vs test assessment)

Avoid parallel execution when agents would modify the same file, unless they focus on completely independent sections.

## Initial Setup

1. **Git Add Once**
   - Run `git add --all` ONCE at the very beginning to stage all current changes
   - This allows you to see diffs as you work throughout the review process
2. **Review the Diff**
   - Run `git diff --staged --stat` to see overview of changed files
   - If the user specified specific files or areas to focus on, examine only those changes
   - Otherwise, run `git diff --staged` to examine all changes in detail
   - Identify which files contain core logic, public APIs, complex algorithms, or security-sensitive code - these require deeper scrutiny
3. **Update Memory**
   - Read @CLAUDE.md and any relevant project-specific CLAUDE.md files to refresh your memory on our standards
4. **Read Any Directly Mentioned Files First:**
   - If the user mentions specific files (tickets, docs, JSON), read them FULLY first
   - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
   - **CRITICAL**: Read these files yourself in the main context before spawning any sub-tasks
   - This ensures you have full context before decomposing the research

## Process

1. **Cleanup**
  - Remove debug printlines
  - Cleanup any debug lines, code that was just used to check an assumption, etc.

2. **Assess Production Code**

  **Correctness & Logic:**
  - Trace execution paths through changed code
  - Verify error handling at all failure points
  - Check boundary conditions (empty, null, zero, negative, max values)
  - Look for off-by-one errors, race conditions, resource leaks
  - Verify thread safety if concurrent access possible
  - Check for unhandled error cases or silent failures

  **Edge Cases & Input Handling:**
  - Empty/null/undefined inputs
  - Boundary values (min, max, zero, negative)
  - Large inputs (performance implications)
  - Malformed or unexpected input types
  - Concurrent access patterns

  **Security:**
  - SQL injection, XSS, command injection vulnerabilities
  - Authentication and authorization bypasses
  - Secrets, credentials, or API keys in code
  - Input validation and sanitization
  - File path traversal risks
  - Information leakage in error messages

  **Code Quality:**
  - Adherence to language best practices and latest standards
  - Proper separation of concerns
  - Opportunities for simplification without behavior change
  - Consistency with existing codebase patterns
  - API design if public interfaces changed
  - Performance and algorithmic complexity concerns

  **Comments:**
  - Remove all unnecessary or inaccurate comments
  - Ensure comments are concise with only necessary information
  - Ensure comments say "why" something is rather than saying "what" something is or "how" it's being done
  - Ensure comments don't reference transient details that may change, like saying "there are two phases below"

3. **Assess Test Code**
  - Do tests exist for all changed production code?
  - Are tests validating behavior rather than implementation details?
  - Do tests cover edge cases identified in production code assessment?
  - Are assertions meaningful and specific (not just checking for no exceptions)?
  - Do tests prevent future regressions for feature behavior?
  - Are there missing test scenarios that production code changes require?
  - Are test names descriptive of what behavior they verify?
  - Is error message quality validated where applicable?

4. **Refactor**
  - Make ONLY refactoring changes that do not modify behavior:
    - Rename variables/functions for clarity
    - Extract repeated code into functions
    - Improve code structure and organization
    - Remove dead code
    - Fix formatting and style issues
    - Update comments per guidelines above
  - DO NOT change:
    - Control flow or execution order
    - Return values or error handling
    - API contracts or function signatures
    - Data transformations or calculations
  - Coordinate with any spawned sub-agents to avoid conflicts
  - Both main task and sub-agents can make refactoring changes within their respective scopes

5. **Report Results**
  - Output a summary to the user with 2 sections:

    **Refactoring Changes Made:**
    - List all refactoring changes made (by main task and sub-agents)
    - Group by file with specific line references where helpful

    **Issues Found (Require Behavior Changes):**
    - Document any bugs, missed edge cases, security vulnerabilities, or other issues found
    - Include file:line references for each issue
    - Prioritize by severity (critical, important, minor)
    - Provide specific recommendations for fixes

### What We're NOT Doing

- NOT removing JMT FIXME comments (distinct from commented code), like `// FIXME: (JMT) use or remove`
- NOT running `git add` more than once after changes have been made
- NOT running `git commit`
- NOT running `git stash`
- NOT deleting files
- NOT modifying behavior
