---
name: grafana
description: "Interact with Grafana dashboards, datasources, alerts, annotations, and folders via the Grafana HTTP API. Use this skill whenever the user mentions Grafana, wants to create or modify dashboards, check what dashboards exist, look at datasource configuration, add annotations, manage alert rules, search Grafana, or do anything involving their Grafana instance. Also trigger when the user references grafana-dev.speedscale.com, dashboard panels, or monitoring visualizations."
---

# Grafana

Interact with the Grafana instance at `grafana-dev.speedscale.com` (v11.1.3) using its HTTP API. The instance has a ClickHouse datasource and dashboards organized in a `default` folder.

## Authentication

All API calls require the `$SPEEDSCALE_GRAFANA_DEV_API_KEY` environment variable. Never hardcode or log the key. The bundled script reads it automatically.

## Quick Start

The `scripts/grafana_api.py` script wraps all common operations. Run it from this skill's directory.

```bash
# Check connectivity
scripts/grafana_api.py health

# List all dashboards
scripts/grafana_api.py search --type dash-db

# Get a specific dashboard
scripts/grafana_api.py dashboard get <uid>

# List datasources
scripts/grafana_api.py datasources

# List folders
scripts/grafana_api.py folders
```

## Dashboards

### Listing and searching

```bash
# All dashboards
scripts/grafana_api.py search --type dash-db

# Search by name
scripts/grafana_api.py search --query "api-gateway"

# Filter by tag
scripts/grafana_api.py search --tag production

# Filter by folder
scripts/grafana_api.py search --folder-id 1
```

### Getting a dashboard

```bash
scripts/grafana_api.py dashboard get <uid>
```

Returns full dashboard JSON including `meta` (permissions, version, folder info) and `dashboard` (panels, templating, time range, etc.).

### Creating / updating a dashboard

Write a dashboard JSON file, then:

```bash
scripts/grafana_api.py dashboard create /path/to/dashboard.json
```

The JSON file can be either:
- A **wrapped payload** with `dashboard` and optional `folderId`/`folderUid`/`overwrite` keys
- A **raw dashboard object** (with `panels`, `title`, etc.) — the script wraps it automatically

**Minimal dashboard example** (save to a temp file):

```json
{
  "dashboard": {
    "id": null,
    "uid": null,
    "title": "My New Dashboard",
    "tags": ["auto-generated"],
    "timezone": "browser",
    "schemaVersion": 16,
    "panels": [
      {
        "id": 1,
        "type": "timeseries",
        "title": "Request Rate",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "datasource": {"type": "grafana-clickhouse-datasource", "uid": "PDEE91DDB90597936"},
        "targets": [
          {
            "datasource": {"type": "grafana-clickhouse-datasource", "uid": "PDEE91DDB90597936"},
            "rawSql": "SELECT $__timeInterval(Timestamp) as time, count() as count FROM otel_logs WHERE $__timeFilter(Timestamp) GROUP BY time ORDER BY time",
            "format": 1
          }
        ]
      }
    ]
  },
  "folderUid": "cf77d06au1jpcf",
  "overwrite": false
}
```

To **update** an existing dashboard, fetch it first, modify the `dashboard` object, keep the same `uid`, set `overwrite: true`, and bump the `version`.

### Deleting a dashboard

```bash
scripts/grafana_api.py dashboard delete <uid>
```

## Datasources

The instance currently has one datasource:

| Name | Type | UID | Default DB | Protocol |
|------|------|-----|-----------|----------|
| ClickHouse | grafana-clickhouse-datasource | PDEE91DDB90597936 | default | native (port 9000) |

OTel-compatible: logs in `otel_logs` table, context column `ServiceName`.

```bash
# List all
scripts/grafana_api.py datasources

# Get one by UID
scripts/grafana_api.py datasource get PDEE91DDB90597936
```

When creating panels that query ClickHouse, use this datasource reference:
```json
{"type": "grafana-clickhouse-datasource", "uid": "PDEE91DDB90597936"}
```

## Folders

```bash
# List
scripts/grafana_api.py folders

# Create
scripts/grafana_api.py folder create "My Folder"
scripts/grafana_api.py folder create "My Folder" --uid my-folder-uid

# Delete
scripts/grafana_api.py folder delete <uid>
```

## Annotations

```bash
# List annotations
scripts/grafana_api.py annotations
scripts/grafana_api.py annotations --dashboard-id 3 --tags deploy

# Create
scripts/grafana_api.py annotation create --dashboard-id 3 --text "Deployed v2.1" --tags "deploy,production"

# Delete
scripts/grafana_api.py annotation delete <id>
```

## Alert Rules

```bash
scripts/grafana_api.py alert-rules
```

## Raw API Calls

For anything not covered by the named commands, use `raw`:

```bash
# GET
scripts/grafana_api.py raw GET /api/org

# POST with JSON body
scripts/grafana_api.py raw POST /api/folders '{"title": "test"}'

# DELETE
scripts/grafana_api.py raw DELETE /api/dashboards/uid/abc123
```

## Workflow

When the user asks you to do something with Grafana:

1. **Orient** — run `search --type dash-db` and `folders` to see what exists
2. **Inspect** — `dashboard get <uid>` to understand an existing dashboard's structure
3. **Act** — create, modify, or delete as requested
4. **Verify** — confirm the action succeeded (fetch the resource back, or check the search results)

For dashboard creation, write the JSON to a temp file, call `dashboard create`, then clean up. Always verify the response shows `"status": "success"`.

## Resources

### scripts/
- `grafana_api.py` — CLI wrapper for all Grafana HTTP API operations

### references/
- `api_reference.md` — Detailed Grafana API endpoint reference with request/response schemas
