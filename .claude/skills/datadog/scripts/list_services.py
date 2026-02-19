#!/usr/bin/env python3
"""
List unique service names from Datadog logs.
Helps discover what services are available for querying.
"""

import argparse
import sys

# Import search_logs directly
from search_logs import search_logs as _search_logs, read_credentials
import json
import io
from contextlib import redirect_stdout


def list_services(hours: int = 12, limit: int = 1000) -> None:
    """List unique service names from recent logs"""

    # Capture output from search_logs
    output_buffer = io.StringIO()

    try:
        # Call search_logs directly with raw output
        with redirect_stdout(output_buffer):
            _search_logs(
                query="source:*",
                from_time=f"{hours}h",
                to_time="now",
                limit=limit,
                output_format="raw"
            )

        # Parse JSON response
        output = output_buffer.getvalue()
        data = json.loads(output)
        logs = data.get("data", [])

        # Extract unique service names
        services = set()
        for log in logs:
            service = log.get("attributes", {}).get("service")
            if service:
                services.add(service)

        # Print sorted list
        if services:
            print(f"Found {len(services)} unique service(s) in the last {hours} hour(s):\n")
            for service in sorted(services):
                print(f"  - {service}")
        else:
            print("No services found")

    except json.JSONDecodeError as e:
        print(f"Error parsing JSON response: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="List unique service names from Datadog logs",
        epilog="""
Examples:
  %(prog)s                    # List services from last 12 hours
  %(prog)s --hours 24         # List services from last 24 hours
  %(prog)s --hours 6 --limit 500  # List from 6 hours, max 500 logs
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--hours",
        type=int,
        default=12,
        help="Number of hours to look back. Default: 12"
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=1000,
        help="Maximum number of logs to fetch. Default: 1000"
    )

    args = parser.parse_args()

    list_services(hours=args.hours, limit=args.limit)


if __name__ == "__main__":
    main()
