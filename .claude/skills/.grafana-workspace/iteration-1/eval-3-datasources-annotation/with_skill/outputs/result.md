# Eval 3: Datasources + Annotation — Results

## 1. Datasources

**Command:** `scripts/grafana_api.py datasources`

One datasource configured:

| Name | Type | UID | Default DB | Protocol | Port |
|------|------|-----|-----------|----------|------|
| ClickHouse | grafana-clickhouse-datasource | PDEE91DDB90597936 | default | native | 9000 |

OTel logs enabled: table `otel_logs`, context column `ServiceName`.

**Full response:**

```json
[
  {
    "id": 1,
    "uid": "PDEE91DDB90597936",
    "orgId": 1,
    "name": "ClickHouse",
    "type": "grafana-clickhouse-datasource",
    "access": "proxy",
    "jsonData": {
      "defaultDatabase": "default",
      "host": "clickhouse",
      "port": 9000,
      "protocol": "native",
      "username": "grafana",
      "logs": {
        "defaultDatabase": "default",
        "defaultTable": "otel_logs",
        "otelEnabled": true,
        "otelVersion": "latest",
        "contextColumns": ["ServiceName"]
      }
    },
    "readOnly": true
  }
]
```

## 2. Find api-gateway Dashboard

**Command:** `scripts/grafana_api.py search --query "api-gateway" --type dash-db`

Found dashboard:

| Field | Value |
|-------|-------|
| id | 3 |
| uid | de9ejzuiksn40f |
| title | api-gateway |
| folder | default (cf77d06au1jpcf) |

## 3. Create Annotation

**Command:** `scripts/grafana_api.py annotation create --dashboard-id 3 --text "Deployed v3.0" --tags "deploy,api-gateway"`

**Response:**

```json
{
  "id": 1,
  "message": "Annotation added"
}
```

## 4. Confirm Annotation

**Command:** `scripts/grafana_api.py annotations --dashboard-id 3 --tags "deploy,api-gateway"`

**Response:**

```json
[
  {
    "id": 1,
    "alertId": 0,
    "dashboardId": 3,
    "dashboardUID": "de9ejzuiksn40f",
    "panelId": 0,
    "created": 1774965138662,
    "updated": 1774965138662,
    "time": 1774965138662,
    "timeEnd": 1774965138662,
    "text": "Deployed v3.0",
    "tags": ["deploy", "api-gateway"],
    "login": "sa-1-josh-llm",
    "email": "sa-1-josh-llm"
  }
]
```

## Summary

All operations succeeded using `scripts/grafana_api.py`:

1. Listed datasources -- single ClickHouse datasource (UID `PDEE91DDB90597936`)
2. Found `api-gateway` dashboard (id=3, uid=`de9ejzuiksn40f`)
3. Created annotation "Deployed v3.0" with tags `deploy` and `api-gateway` on dashboard id 3
4. Confirmed annotation exists with matching text, tags, and dashboard binding
