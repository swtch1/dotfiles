---
name: jira-move
description: Automatically move my Jira tickets from "In Review" status to "Merged" status when all their associated GitLab merge requests have been merged.
disable-model-invocation: true
---

Automatically move my Jira tickets from "In Review" status to "Merged" status when all their associated GitLab merge requests have been merged.

Follow these steps:
1. Get cloud ID using `mcp__jira__getAccessibleAtlassianResources`
2. Search for my Jira tickets in "In Review" status using `mcp__jira__searchJiraIssuesUsingJql` with JQL: `assignee = currentUser() AND status = "In Review" AND sprint in openSprints()` and minimal fields: ["key", "summary", "status"]
3. For each ticket, use `mcp__jira__getJiraIssue` with fields: ["key", "summary", "comment"] to extract GitLab MR URLs from comments (look for "URL: " pattern in comment body content)
4. Extract MR numbers and repository paths from GitLab URLs (format: https://gitlab.com/{org}/{repo}/-/merge_requests/{number})
5. Check MR status in parallel using `glab mr view {number} --repo {org}/{repo}` and parse the "state:" line for "merged", "open", or "closed"
6. For tickets where ALL associated MRs have state "merged", transition to "Merged" status using `mcp__jira__transitionJiraIssue` with transition ID: 61
7. Provide a concise summary showing which tickets were transitioned and which were skipped (with reasons)

Technical notes:
- Use Jira MCP tools (`mcp__jira__*`), not CLI commands
- glab requires --repo flag when not in a git repository
- glab output format: "state:\tmerged" (tab-separated)
- Batch all independent operations in parallel (MCP calls, glab calls)
