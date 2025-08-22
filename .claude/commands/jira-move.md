Automatically move my Jira tickets from "In Review" status to "Merged" status when all their associated GitLab merge requests have been merged.

Follow these steps:
1. Search for my Jira tickets in "In Review" status using minimal fields: ["key", "summary", "status"] only
2. For each ticket, get ONLY comments (not full changelog) to extract GitLab MR URLs (look for "URL: " pattern)
3. Batch check MR status using `glab` in parallel calls
4. For tickets where ALL associated MRs are merged, transition to "Merged" status (ID: 61)
5. Provide a concise summary

Context optimization requirements:
- Use TodoWrite tool to track progress
- NEVER use `expand=changelog` - too much data
- Only fetch full ticket details for tickets that have MR URLs
- Batch glab calls and use parallel execution
- Skip GitHub PRs, only process GitLab MRs
- Target repositories: speedscale/speedscale, speedscale/kraken, speedscale/dashboard

Only act on tickets assigned to me in the current sprint unless explicitly
requested otherwise.
