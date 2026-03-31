# Grafana HTTP API Reference

Base URL: `https://grafana-dev.speedscale.com`
Auth header: `Authorization: Bearer $SPEEDSCALE_GRAFANA_DEV_API_KEY`
Version: 11.1.3

## Table of Contents

- [Dashboards](#dashboards)
- [Datasources](#datasources)
- [Folders](#folders)
- [Search](#search)
- [Annotations](#annotations)
- [Alert Rules](#alert-rules)
- [Organization](#organization)

---

## Dashboards

### GET /api/dashboards/uid/:uid

Returns full dashboard with metadata.

**Response:**
```json
{
  "meta": {
    "type": "db",
    "canSave": true,
    "canEdit": true,
    "canAdmin": true,
    "slug": "my-dashboard",
    "url": "/d/abc123/my-dashboard",
    "version": 1,
    "folderId": 1,
    "folderUid": "cf77d06au1jpcf",
    "folderTitle": "default"
  },
  "dashboard": {
    "id": 3,
    "uid": "abc123",
    "title": "My Dashboard",
    "tags": [],
    "timezone": "browser",
    "schemaVersion": 16,
    "panels": [...],
    "templating": {"list": []},
    "time": {"from": "now-6h", "to": "now"}
  }
}
```

### POST /api/dashboards/db

Create or update a dashboard.

**Request body:**
```json
{
  "dashboard": {
    "id": null,
    "uid": null,
    "title": "New Dashboard",
    "tags": [],
    "timezone": "browser",
    "schemaVersion": 16,
    "panels": []
  },
  "folderId": 0,
  "folderUid": "cf77d06au1jpcf",
  "overwrite": false,
  "message": "Created via API"
}
```

- `id: null` — creates new. Set `id` + `overwrite: true` to update.
- `folderId: 0` — General folder. Use `folderUid` to target a specific folder.

**Response:**
```json
{
  "id": 6,
  "uid": "efhoj1s8l2ccgf",
  "url": "/d/efhoj1s8l2ccgf/new-dashboard",
  "status": "success",
  "version": 1,
  "slug": "new-dashboard"
}
```

### DELETE /api/dashboards/uid/:uid

**Response:**
```json
{
  "title": "New Dashboard",
  "message": "Dashboard New Dashboard deleted",
  "uid": "efhoj1s8l2ccgf"
}
```

---

## Datasources

### GET /api/datasources

Returns array of all datasources.

### GET /api/datasources/:id

Get by numeric ID.

### GET /api/datasources/uid/:uid

Get by UID.

### POST /api/datasources

Create a datasource.

### PUT /api/datasources/:id

Update a datasource.

### DELETE /api/datasources/:id

Delete a datasource.

---

## Folders

### GET /api/folders

Returns array of folders:
```json
[{"id": 1, "uid": "cf77d06au1jpcf", "title": "default"}]
```

### POST /api/folders

```json
{"title": "My Folder", "uid": "optional-uid"}
```

### PUT /api/folders/:uid

Update folder title.

### DELETE /api/folders/:uid

Delete folder and all its dashboards.

---

## Search

### GET /api/search

Query parameters:
- `query` — search string
- `type` — `dash-db` or `dash-folder`
- `tag` — filter by tag (repeat for multiple)
- `folderIds` — comma-separated folder IDs
- `limit` — max results (default 1000)

---

## Annotations

### GET /api/annotations

Query parameters: `dashboardId`, `from`, `to`, `tags`, `limit`

### POST /api/annotations

```json
{
  "dashboardId": 3,
  "text": "Deployed v2.1",
  "tags": ["deploy"],
  "time": 1234567890000
}
```

`time` is epoch milliseconds. Omit for "now".

### DELETE /api/annotations/:id

---

## Alert Rules

### GET /api/ruler/grafana/api/v1/rules

Returns all Grafana-managed alert rules grouped by namespace/folder.

### POST /api/ruler/grafana/api/v1/rules/:namespace

Create/update alert rules in a namespace.

---

## Organization

### GET /api/org

Current org info.

### GET /api/org/users

Users in current org.

---

## Panel Types

Common panel types for dashboard creation:

| Type | Description |
|------|-------------|
| `timeseries` | Time-series line/bar chart (most common) |
| `stat` | Single stat with optional sparkline |
| `gauge` | Gauge visualization |
| `table` | Tabular data |
| `barchart` | Bar chart |
| `piechart` | Pie/donut chart |
| `logs` | Log viewer panel |
| `text` | Markdown/HTML text panel |
| `alertlist` | Alert status list |

## Panel Grid Layout

Panels use `gridPos` with a 24-column grid:
```json
{
  "gridPos": {
    "h": 8,
    "w": 12,
    "x": 0,
    "y": 0
  }
}
```
- `w`: width in columns (max 24)
- `h`: height in grid units
- `x`, `y`: position from top-left
