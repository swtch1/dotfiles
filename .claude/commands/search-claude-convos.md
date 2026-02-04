---
description: Search through Claude CLI conversation transcripts to find specific content.
---

# Search Claude Conversations

Find past conversations by searching through your Claude CLI session transcripts.

## Workflow

### Extract Search Terms

The user will provide a description of what they're looking for. Extract key technical terms, concepts, and actions:

**Natural language examples:**
- "Find where we discussed database migration strategy" → ["database", "migration", "strategy"]
- "The conversation about React component optimization" → ["React", "component", "optimization"]
- "Where we identified API endpoints without error handling" → ["API", "endpoint", "error handling", "without"]
- "When we debugged the authentication timeout issue" → ["debug", "authentication", "timeout"]

**Guidelines:**
- Extract nouns (especially technical terms, file names, component names)
- Include action verbs that indicate the work done ("identified", "fixed", "added")
- Look for negations ("without", "missing", "lack")
- If the user provides specific file paths or session IDs, note those
- If the user mentions dates/timeframes ("last week", "yesterday", "January"), use file modification times to filter before content search
- If the description is too vague (like "that thing we did"), ask for more details

### Run Initial Broad Search

Search for sessions containing ANY of the key terms (OR search):

```bash
# Find all session files (excluding subagents)
session_files=$(find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -type f)

# Search for any key term
for term in "${search_terms[@]}"; do
  echo "$session_files" | xargs grep -l -i "$term" 2>/dev/null
done | sort -u
```

**Search locations:**
- Session transcripts: `~/.claude/projects/*/*.jsonl`
- Exclude subagent directories: `*/subagents/*`

**Efficiency note:** Use `grep -l` first to find candidate files, then use `jq` only on those files.

**If user provided a date/timeframe:**
Use file modification times to filter first:
```bash
# Last week: files modified in last 7 days
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -7

# Specific date range
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -newermt "2026-01-01" ! -newermt "2026-01-31"
```

### Narrow to Top Candidates

If the initial search returns many results (>10 sessions), narrow down by:

**A. Multi-term matching** - Find sessions with MULTIPLE key terms:
```bash
# Count how many different search terms appear in each file
# Rank files by term count
```

**B. Recency** - Prioritize recent sessions:
```bash
# Use modification times to sort results
ls -lt <candidate-files> | head -20
```

**C. Project patterns** - If the user mentioned a project, filter by path:
- Extract project name from user query and match against directory names
- Example: "backend API" → look in directories containing "backend", "api", "server"
- Example: "mobile app" → look in directories containing "mobile", "app", "ios", "android"

### Examine Top Candidates

For the top 3-5 candidate sessions, extract relevant context:

```bash
# For each candidate file, extract messages in chronological order:
jq -r 'select(.type == "user" or .type == "assistant") |
  {ts: .timestamp, role: .type, text: (.message.content[]?.text? // "")}' \
  ~/.claude/projects/<path>/<session-id>.jsonl | \
  jq -sc 'sort_by(.ts) | .[]'
```

**Note:** The `-s` flag (slurp) loads all messages to sort by timestamp. This is acceptable for individual session files which are reasonably sized.

Look for:
- Initial user request (first few messages)
- Key findings or results (assistant messages mentioning search terms)
- Timestamps to confirm it's the right timeframe

### Search Command History (Optional)

If the user mentions running a command or if transcript search yields no results, also search command history:

```bash
# Search command history for matching terms
jq -r 'select(.display | test("search_term"; "i")) |
  {date: .timestamp, project: .project, cmd: .display}' \
  ~/.claude/history.jsonl | \
  jq -s 'sort_by(.date) | reverse | .[] |
  "Date: \(.date)\nProject: \(.project)\nCommand: \(.cmd)\n---"'
```

This can help find:
- Commands the user ran during that session
- The project context where work was done
- Alternative search terms to try

### Present Results

Show the most relevant session(s) with:

```
=== SESSION FOUND ===

**Session ID**: <session-id>
**Project**: /path/to/project
**Date**: YYYY-MM-DD HH:MM UTC
**Location**: ~/.claude/projects/<path>/<session-id>.jsonl

### Key Excerpts:
<Show 2-3 relevant snippets from the conversation>

### Initial Request:
<First user message>

### Key Findings:
<Important assistant responses>

---

To view full conversation:
jq -r 'select(.type == "user" or .type == "assistant") | .message.content[]?.text? // ""' ~/.claude/projects/<path>/<session-id>.jsonl | less
```

If multiple relevant sessions found, show them in chronological order (most recent first) with brief summaries of each.

### Handle Edge Cases

**Too many results (>20 sessions):**
Ask the user for more specifics:
- "I found many sessions discussing [topic]. Can you remember roughly when this was or any other details?"
- Suggest timeframes: "Was this in the last week? Last month?"
- Ask for related context: "What feature or bug were you working on at the time?"

**No results:**
- Try broader/related terms (e.g., "authentication" → "auth", "login", "session")
- Try variations in casing (e.g., "API" vs "api", "React" vs "react")
- Ask if they remember any other details (project, approximate date, related work)

**Multiple promising sessions:**
- Show summaries of each with dates
- Ask which one they want to see in detail

## Technical Details

**JSONL Structure:**
Each line in a session file is a JSON object:
```json
{
  "type": "user" | "assistant",
  "timestamp": "2026-01-30T18:05:02.862Z",
  "message": {
    "content": [
      {"type": "text", "text": "..."}
    ]
  }
}
```

**Search Tips:**
- Case-insensitive by default: `grep -i`
- Use partial matches: "migrat" matches "migrate", "migration", "migrating"
- Combine terms with regex: `grep -E "database.*schema|schema.*database"`
- JSONL files can be large - use streaming with `jq` not loading entire files

**File Path Format:**
- Sessions: `~/.claude/projects/-<escaped-project-path>/<uuid>.jsonl`
- Subagents (skip these): `~/.claude/projects/-<path>/subagents/*.jsonl`
- History: `~/.claude/history.jsonl`

## Examples

**User provides natural language:**
```
User: "Find the conversation where we optimized the database queries"
→ Extract: ["optimiz", "database", "quer"]
→ Search for files with these terms
→ Present the most recent relevant session
```

**User mentions specific context:**
```
User: "The discussion about adding Redis caching to the API endpoints"
→ Extract: ["Redis", "cach", "API", "endpoint"]
→ Search for sessions with multiple matching terms
→ Show top 2-3 candidates sorted by date
```

**User is very specific:**
```
User: "Show me session a1b2c3d4-e5f6-7890-abcd-ef1234567890"
→ Directly read that session file
→ Present summary with excerpts
```

**User is vague:**
```
User: "That thing we worked on last week"
→ Ask: "Can you provide more details? What topic or feature were you working on?"
```

**User remembers context:**
```
User: "When we debugged why the React components were re-rendering unnecessarily"
→ Extract: ["debug", "React", "component", "re-render", "unnecessar"]
→ Search for these terms
→ Find session discussing React performance
```

**User provides timeframe:**
```
User: "Find the database migration conversation from last week"
→ Extract: ["database", "migration"]
→ Filter files modified in last 7 days using find -mtime -7
→ Search filtered files for terms
→ Present matching sessions
```
