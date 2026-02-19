#!/usr/bin/env python3
"""
Search Datadog logs via API.
Reads credentials from environment variables.
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error


def read_credentials() -> tuple[str, str, str]:
    """Read Datadog credentials from environment variables"""
    api_key = os.environ.get("DATADOG_API_KEY")
    app_key = os.environ.get("DATADOG_APP_KEY")
    api_host = os.environ.get("DATADOG_API_HOST", "https://api.datadoghq.com")

    if not api_key or not app_key:
        print(f"Error: Missing required environment variables", file=sys.stderr)
        print("Set environment variables:", file=sys.stderr)
        print("  export DATADOG_API_KEY=YOUR_API_KEY", file=sys.stderr)
        print("  export DATADOG_APP_KEY=YOUR_APP_KEY", file=sys.stderr)
        print("  export DATADOG_API_HOST=https://api.datadoghq.com  # optional", file=sys.stderr)
        sys.exit(1)

    return api_key, app_key, api_host


def parse_time_range(time_str: str) -> str:
    """Convert relative time like '10m', '2h', '1d' to 'now-{time}' format"""
    if time_str.startswith("now"):
        return time_str

    # If it's just a number+unit, convert to now-{time}
    if len(time_str) >= 2 and time_str[-1] in ['m', 'h', 'd'] and time_str[:-1].isdigit():
        return f"now-{time_str}"

    # Otherwise assume it's an absolute timestamp
    return time_str


def search_logs(
    query: str,
    from_time: str = "now-15m",
    to_time: str = "now",
    limit: int = 50,
    output_format: str = "pretty"
) -> None:
    """Search Datadog logs"""
    api_key, app_key, api_host = read_credentials()

    # Parse time ranges
    from_time = parse_time_range(from_time)
    to_time = parse_time_range(to_time)

    # Build request
    url = f"{api_host}/api/v2/logs/events/search"

    payload = {
        "filter": {
            "query": query,
            "from": from_time,
            "to": to_time
        },
        "page": {
            "limit": limit
        },
        "sort": "-timestamp"  # Newest first
    }

    headers = {
        "DD-API-KEY": api_key,
        "DD-APPLICATION-KEY": app_key,
        "Content-Type": "application/json"
    }

    # Make request
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode('utf-8'),
        headers=headers,
        method='POST'
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.loads(response.read().decode('utf-8'))

            if output_format == "json":
                print(json.dumps(result, indent=2))
            elif output_format == "raw":
                print(json.dumps(result))
            else:  # pretty
                print_pretty_logs(result, limit)

    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f"HTTP Error {e.code}: {e.reason}", file=sys.stderr)
        print(error_body, file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"URL Error: {e.reason}", file=sys.stderr)
        sys.exit(1)


def print_pretty_logs(result: dict, limit: int) -> None:
    """Print logs in a human-readable format"""
    data = result.get("data", [])

    if not data:
        print("No logs found matching query")
        return

    # Check if results were truncated
    meta = result.get("meta", {})
    page_info = meta.get("page", {})
    after_cursor = page_info.get("after")

    print(f"Found {len(data)} log(s):\n")

    if after_cursor and len(data) == limit:
        print(f"Note: Results limited to {limit}. More results available. Use --limit to fetch more.\n")

    for i, log in enumerate(data, 1):
        attrs = log.get("attributes", {})

        timestamp = attrs.get("timestamp", "")
        service = attrs.get("service", "unknown")
        status = attrs.get("status", "")
        message = attrs.get("message", "")
        host = attrs.get("host", "")

        print(f"{'='*80}")
        print(f"Log {i}/{len(data)}")
        print(f"{'='*80}")
        print(f"Timestamp: {timestamp}")
        print(f"Service:   {service}")
        print(f"Status:    {status}")
        print(f"Host:      {host}")
        print(f"Message:   {message}")

        # Print other interesting attributes
        log_attrs = attrs.get("attributes", {})
        if log_attrs:
            print(f"\nAttributes:")
            for key, value in log_attrs.items():
                if key not in ['service', 'host', 'message', 'status', 'timestamp']:
                    print(f"  {key}: {value}")

        print()


def main():
    parser = argparse.ArgumentParser(
        description="Search Datadog logs",
        epilog="""
Examples:
  %(prog)s "service:api-gateway error"
  %(prog)s "status:error" --from 1h --limit 100
  %(prog)s "unknown report ID" --from "2026-02-10T18:00:00Z" --to "2026-02-10T19:00:00Z"
  %(prog)s "service:my-app" --json
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "query",
        nargs='?',
        default="",
        help="Datadog query string (e.g., 'error', 'connection timeout')"
    )
    parser.add_argument(
        "--service", "-s",
        help="Service name (prepends 'service:NAME' to query)"
    )
    parser.add_argument(
        "--from", "-f",
        dest="from_time",
        default="now-15m",
        help="Start time (e.g., '15m', '2h', '1d', 'now-1h', or ISO timestamp). Default: now-15m"
    )
    parser.add_argument(
        "--to", "-t",
        dest="to_time",
        default="now",
        help="End time (e.g., 'now', or ISO timestamp). Default: now"
    )
    parser.add_argument(
        "--limit", "-l",
        type=int,
        default=50,
        help="Maximum number of logs to return. Default: 50"
    )
    parser.add_argument(
        "--json",
        action="store_const",
        const="json",
        dest="output_format",
        default="pretty",
        help="Output raw JSON response"
    )
    parser.add_argument(
        "--raw",
        action="store_const",
        const="raw",
        dest="output_format",
        help="Output compact JSON (one line)"
    )

    args = parser.parse_args()

    # Build query with optional service prefix
    query = args.query
    if args.service:
        service_filter = f"service:{args.service}"
        query = f"{service_filter} {query}".strip()

    if not query:
        parser.error("Must provide either query or --service")

    search_logs(
        query=query,
        from_time=args.from_time,
        to_time=args.to_time,
        limit=args.limit,
        output_format=args.output_format
    )


if __name__ == "__main__":
    main()
