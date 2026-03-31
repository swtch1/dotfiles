# Eval 2: Create Dashboard — With Skill

## Task
Create a dashboard called "Error Rate Monitor" with a timeseries panel showing error counts from ClickHouse, put it in the default folder. Verify it exists, then delete it.

## Steps & API Responses

### 1. Orient — Health Check & Folder Lookup

**Health:**
```json
{"commit": "da5a557b6e1c3b33a5f2a4af73949e4d", "database": "ok", "version": "11.1.3"}
```

**Folders:**
```json
[{"id": 1, "uid": "cf77d06au1jpcf", "title": "default"}]
```

Default folder UID: `cf77d06au1jpcf`

### 2. Create Dashboard

Wrote dashboard JSON with:
- Title: "Error Rate Monitor"
- Panel type: `timeseries`, title "Error Counts"
- Datasource: ClickHouse (`PDEE91DDB90597936`)
- Query: `SELECT $__timeInterval(Timestamp) as time, count() as error_count FROM otel_logs WHERE $__timeFilter(Timestamp) AND SeverityText = 'ERROR' GROUP BY time ORDER BY time`
- Folder: `cf77d06au1jpcf` (default)

**Response:**
```json
{
  "folderUid": "cf77d06au1jpcf",
  "id": 7,
  "slug": "error-rate-monitor",
  "status": "success",
  "uid": "bfholahjshs00f",
  "url": "/d/bfholahjshs00f/error-rate-monitor",
  "version": 1
}
```

### 3. Verify Dashboard Exists

Fetched via `dashboard get bfholahjshs00f`. Confirmed:
- Title: "Error Rate Monitor"
- Folder: "default" (`cf77d06au1jpcf`)
- Panel: timeseries, "Error Counts", querying ClickHouse for error-level logs
- Version: 1

**Response (abbreviated meta):**
```json
{
  "meta": {
    "slug": "error-rate-monitor",
    "folderId": 1,
    "folderUid": "cf77d06au1jpcf",
    "folderTitle": "default",
    "version": 1
  },
  "dashboard": {
    "title": "Error Rate Monitor",
    "uid": "bfholahjshs00f",
    "panels": [
      {
        "type": "timeseries",
        "title": "Error Counts",
        "datasource": {"type": "grafana-clickhouse-datasource", "uid": "PDEE91DDB90597936"},
        "targets": [{"rawSql": "SELECT $__timeInterval(Timestamp) as time, count() as error_count FROM otel_logs WHERE $__timeFilter(Timestamp) AND SeverityText = 'ERROR' GROUP BY time ORDER BY time"}]
      }
    ]
  }
}
```

### 4. Delete Dashboard

**Response:**
```json
{
  "message": "Dashboard Error Rate Monitor deleted",
  "title": "Error Rate Monitor",
  "uid": "bfholahjshs00f"
}
```

### 5. Confirm Deletion

Attempted `dashboard get bfholahjshs00f` — received HTTP 404: "Dashboard not found". Confirmed deleted.

## Script Used
`scripts/grafana_api.py` from the grafana skill — commands: `health`, `folders`, `dashboard create`, `dashboard get`, `dashboard delete`.

## Notes
- Minor bug in `grafana_api.py`: the `search --query` command doesn't URL-encode spaces, causing `InvalidURL` on queries with spaces (Python 3.14's stricter URL validation). Not blocking for this eval since we verified via direct UID fetch.
- Total API calls: 5 (health, folders, create, get, delete) + 1 confirmation get (404).
