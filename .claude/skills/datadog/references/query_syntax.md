# Datadog Log Query Syntax Reference

## Basic Syntax

Datadog log queries support a simple search syntax with fields, operators, and text search.

## Field Queries

Search specific fields using `field:value` syntax:

```
service:api-gateway
status:error
host:i-0dc1e6a9910e06c68
env:production
```

## Text Search

Search for text in the message field:

```
"unknown report ID"
"connection timeout"
error
```

Use quotes for exact phrase matching.

## Combining Queries

Use AND/OR operators (implicit AND):

```
service:api-gateway error
service:api-gateway AND status:error
service:api-gateway OR service:web-server
```

## Wildcards

Use `*` for wildcard matching:

```
service:api-*
host:prod-*
*.example.com
```

## Common Fields

- `service:` - Service name
- `host:` - Host name
- `status:` - Log level (info, warn, error, debug)
- `env:` - Environment (production, staging, dev)
- `source:` - Log source
- `@http.status_code:` - HTTP status code (prefix with @)
- `@error.kind:` - Error type
- `@duration:` - Request duration

## Numeric Comparisons

For numeric fields, use comparison operators:

```
@http.status_code:>=400
@duration:>1000
@http.status_code:[400 TO 499]
```

## Time Ranges

Time ranges are specified via command-line flags, not in the query:

```bash
# Last 15 minutes (default)
search_logs.py "service:api-gateway"

# Last hour
search_logs.py "service:api-gateway" --from 1h

# Last 4 hours
search_logs.py "service:api-gateway" --from 4h

# Specific time range
search_logs.py "error" --from "2026-02-10T18:00:00Z" --to "2026-02-10T19:00:00Z"
```

## Negation

Exclude results with `-`:

```
service:api-gateway -status:info
-host:test-*
```

## Examples

```
# Find errors in api-gateway service
service:api-gateway status:error

# Find specific error message
service:api-gateway "connection refused"

# Find all 5xx errors
@http.status_code:>=500

# Find logs excluding info level
service:api-gateway -status:info

# Find logs from production with errors
env:production AND status:error

# Find logs with specific request ID
"47dea5de-761b-4073-8f7d-830933031b12"
```

## Full-Text Search

Without specifying a field, Datadog searches across all text fields including message, host, service, and custom attributes.

## Case Sensitivity

- Field names are case-sensitive
- Field values are generally case-insensitive
- Text search is case-insensitive by default
