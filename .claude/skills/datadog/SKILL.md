---
name: datadog
description: This skill should be used when the user needs to query Datadog logs or other monitoring resources. Use this skill for searching logs, filtering by service/time/status, or when the user mentions Datadog, log searching, or needs to find specific log entries.
---

# Datadog

## Overview

This skill provides command-line access to Datadog monitoring resources, starting with log search functionality. It enables querying Datadog logs via API without requiring manual curl commands or web UI access. Credentials are securely read from environment variables.

## Quick Start

**Discover available services:**

```bash
# List services from last 12 hours
scripts/list_services.py

# List services from last 24 hours
scripts/list_services.py --hours 24
```

**Search Datadog logs:**

```bash
# Basic search (last 15 minutes)
scripts/search_logs.py "service:api-gateway error"

# Search with time range
scripts/search_logs.py "status:error" --from 1h

# Search specific service
scripts/search_logs.py "service:api-gateway \"unknown report ID\""

# JSON output for scripting
scripts/search_logs.py "error" --json
```

## Searching Logs

The `scripts/search_logs.py` script provides comprehensive log search functionality.

### Basic Usage

```bash
scripts/search_logs.py QUERY [OPTIONS]
```

**Required:**
- `QUERY` - Datadog query string using their query syntax (see Query Syntax section below or `references/query_syntax.md` for details)

**Options:**
- `--from, -f TIME` - Start time (e.g., `15m`, `2h`, `1d`, `now-1h`, or ISO timestamp). Default: `now-15m`
- `--to, -t TIME` - End time (e.g., `now` or ISO timestamp). Default: `now`
- `--limit, -l N` - Maximum number of logs to return. Default: `50`
- `--json` - Output formatted JSON response
- `--raw` - Output compact JSON (one line)

### Common Query Patterns

**Search by service (using --service flag):**
```bash
scripts/search_logs.py --service api-gateway
scripts/search_logs.py -s api-gateway "error"
```

**Search by status level:**
```bash
scripts/search_logs.py "status:error"
scripts/search_logs.py -s web-server "-status:info"
```

**Search for specific text:**
```bash
scripts/search_logs.py "connection timeout"
scripts/search_logs.py -s api-gateway "unknown report ID"
```

**Time ranges:**
```bash
# Last hour
scripts/search_logs.py "error" --from 1h

# Last 4 hours, limit to 100 results
scripts/search_logs.py -s api-gateway --from 4h --limit 100
```

### Output Formats

**Pretty (default)** - Human-readable format with timestamps, service, status, message, and attributes:
```bash
scripts/search_logs.py "service:api-gateway error"
```

**JSON** - Formatted JSON for analysis:
```bash
scripts/search_logs.py "error" --json
```

**Raw** - Compact JSON for piping:
```bash
scripts/search_logs.py "error" --raw | jq '.data[].attributes.message'
```

## Query Syntax

Datadog log queries use a field-based syntax. See `references/query_syntax.md` for comprehensive documentation including operators, wildcards, numeric comparisons, and examples.

## Configuration

The script reads Datadog API credentials from environment variables.

**Required Environment Variables:**

```bash
export DATADOG_API_KEY=YOUR_API_KEY
export DATADOG_APP_KEY=YOUR_APP_KEY
```

**Optional Environment Variable:**

```bash
export DATADOG_API_HOST=https://api.datadoghq.com  # defaults to datadoghq.com
```

**Security:** Credentials are never exposed in the skill scripts - they are read at runtime from environment variables.

**Setup:**
1. Get API keys from https://app.datadoghq.com/account/settings#api
2. Set environment variables: `DATADOG_API_KEY` and `DATADOG_APP_KEY`
3. Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to persist across sessions

## Workflow

When a user asks to search Datadog logs:

1. **Identify query requirements:**
   - What service? (`service:NAME`)
   - What time range? (use `--from` flag)
   - What search terms or filters?

2. **Construct the query:**
   - Use field syntax for structured data: `service:api-gateway status:error`
   - Use quoted strings for exact phrases: `"unknown report ID"`
   - Combine with AND/OR operators as needed

3. **Execute the search:**
   ```bash
   scripts/search_logs.py "QUERY" --from TIME --limit N
   ```

4. **Parse the results:**
   - Pretty format shows key fields (timestamp, service, status, message)
   - Use `--json` if further processing is needed
   - Check message content and attributes for relevant information

5. **Refine if needed:**
   - Adjust time range if no results found
   - Add or remove filters to narrow/broaden search
   - Increase `--limit` if expecting many results

## Example Usage

```bash
# Find recent errors in a service
scripts/search_logs.py -s api-gateway "error" --from 1h

# Search for specific text across all services
scripts/search_logs.py "connection refused" --from 30m

# Get raw JSON for further processing
scripts/search_logs.py -s dashboard "status:error" --json | jq '.data[].attributes.message'
```

## Resources

### scripts/
- `search_logs.py` - Search Datadog logs via API with flexible query syntax and output formats
- `list_services.py` - List unique service names from recent logs to discover available services

### references/
- `query_syntax.md` - Comprehensive Datadog log query syntax reference with examples and field documentation
