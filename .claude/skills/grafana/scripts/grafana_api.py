#!/usr/bin/env python3
"""Grafana HTTP API helper. Wraps common operations against grafana-dev.speedscale.com.

Usage:
    grafana_api.py <command> [options]

Commands:
    health                          Check Grafana health / version
    search [--query Q] [--type TYPE] [--tag TAG] [--folder-uid UID]
                                    Search dashboards and folders
    dashboard get <uid>             Get dashboard by UID
    dashboard create <json-file>    Create/update dashboard from JSON file
    dashboard delete <uid>          Delete dashboard by UID
    datasources                     List all datasources
    datasource get <id-or-uid>      Get datasource by ID or UID
    folders                         List all folders
    folder create <title> [--uid UID]
                                    Create a folder
    folder delete <uid>             Delete folder by UID
    annotations [--dashboard-uid UID] [--from TS] [--to TS] [--tags T1,T2]
                                    List annotations
    annotation create --dashboard-uid UID --text TEXT [--tags T1,T2] [--time TS]
                                    Create annotation
    annotation delete <id>          Delete annotation
    alert-rules                     List alert rules
    raw <METHOD> <path> [json-body] Raw API call (e.g. raw GET /api/org)

Environment:
    SPEEDSCALE_GRAFANA_DEV_API_KEY  Required. Grafana service account token.
    GRAFANA_URL                     Optional. Defaults to https://grafana-dev.speedscale.com
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


BASE_URL = os.environ.get("GRAFANA_URL", "https://grafana-dev.speedscale.com")
API_KEY = os.environ.get("SPEEDSCALE_GRAFANA_DEV_API_KEY")


def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def api(method, path, body=None):
    """Make an authenticated Grafana API request. Returns parsed JSON."""
    if not API_KEY:
        die("SPEEDSCALE_GRAFANA_DEV_API_KEY is not set")

    url = f"{BASE_URL}{path}" if path.startswith("/") else f"{BASE_URL}/{path}"
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {API_KEY}")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")

    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        body_text = e.read().decode() if e.fp else ""
        try:
            err = json.loads(body_text)
            die(f"HTTP {e.code}: {err.get('message', body_text)}")
        except json.JSONDecodeError:
            die(f"HTTP {e.code}: {body_text}")


def pp(obj):
    """Pretty-print JSON to stdout."""
    print(json.dumps(obj, indent=2))


# ---------- commands ----------

def cmd_health(_args):
    pp(api("GET", "/api/health"))


def cmd_search(args):
    params = []
    if args.query:
        params.append(("query", args.query))
    if args.type:
        params.append(("type", args.type))
    if args.tag:
        for t in args.tag:
            params.append(("tag", t))
    if args.folder_uid is not None:
        params.append(("folderUIDs", args.folder_uid))
    qs = urllib.parse.urlencode(params)
    path = f"/api/search?{qs}" if qs else "/api/search"
    pp(api("GET", path))


def cmd_dashboard_get(args):
    pp(api("GET", f"/api/dashboards/uid/{args.uid}"))


def cmd_dashboard_create(args):
    with open(args.json_file) as f:
        payload = json.load(f)
    # If the file is a raw dashboard object (has "panels" key), wrap it
    if "dashboard" not in payload:
        payload = {"dashboard": payload, "overwrite": False}
    # Ensure null id for new dashboards
    if payload["dashboard"].get("id") is None:
        payload["dashboard"]["id"] = None
    pp(api("POST", "/api/dashboards/db", payload))


def cmd_dashboard_delete(args):
    pp(api("DELETE", f"/api/dashboards/uid/{args.uid}"))


def cmd_datasources(_args):
    pp(api("GET", "/api/datasources"))


def cmd_datasource_get(args):
    identifier = args.id_or_uid
    # If it looks numeric, use id endpoint; otherwise uid
    if identifier.isdigit():
        pp(api("GET", f"/api/datasources/{identifier}"))
    else:
        pp(api("GET", f"/api/datasources/uid/{identifier}"))


def cmd_folders(_args):
    pp(api("GET", "/api/folders"))


def cmd_folder_create(args):
    body = {"title": args.title}
    if args.uid:
        body["uid"] = args.uid
    pp(api("POST", "/api/folders", body))


def cmd_folder_delete(args):
    pp(api("DELETE", f"/api/folders/{args.uid}"))


def cmd_annotations(args):
    params = []
    if args.dashboard_uid:
        params.append(f"dashboardUID={args.dashboard_uid}")
    if getattr(args, "from", None):
        params.append(f"from={getattr(args, 'from')}")
    if args.to:
        params.append(f"to={args.to}")
    if args.tags:
        for t in args.tags.split(","):
            params.append(f"tags={t.strip()}")
    qs = "&".join(params)
    path = f"/api/annotations?{qs}" if qs else "/api/annotations"
    pp(api("GET", path))


def cmd_annotation_create(args):
    body = {"dashboardUID": args.dashboard_uid, "text": args.text}
    if args.tags:
        body["tags"] = [t.strip() for t in args.tags.split(",")]
    if args.time:
        body["time"] = int(args.time)
    pp(api("POST", "/api/annotations", body))


def cmd_annotation_delete(args):
    pp(api("DELETE", f"/api/annotations/{args.id}"))


def cmd_alert_rules(_args):
    pp(api("GET", "/api/ruler/grafana/api/v1/rules"))


def cmd_raw(args):
    body = None
    if args.json_body:
        body = json.loads(args.json_body)
    pp(api(args.method.upper(), args.path, body))


# ---------- arg parser ----------

def build_parser():
    p = argparse.ArgumentParser(description="Grafana API CLI")
    sub = p.add_subparsers(dest="command")

    sub.add_parser("health")

    s = sub.add_parser("search")
    s.add_argument("--query", "-q")
    s.add_argument("--type", choices=["dash-db", "dash-folder"])
    s.add_argument("--tag", action="append")
    s.add_argument("--folder-uid")

    # dashboard sub-commands
    ds = sub.add_parser("dashboard")
    dss = ds.add_subparsers(dest="dashboard_cmd")
    dg = dss.add_parser("get")
    dg.add_argument("uid")
    dc = dss.add_parser("create")
    dc.add_argument("json_file")
    dd = dss.add_parser("delete")
    dd.add_argument("uid")

    sub.add_parser("datasources")

    dsg = sub.add_parser("datasource")
    dsgs = dsg.add_subparsers(dest="datasource_cmd")
    dsget = dsgs.add_parser("get")
    dsget.add_argument("id_or_uid")

    sub.add_parser("folders")

    fc = sub.add_parser("folder")
    fcs = fc.add_subparsers(dest="folder_cmd")
    fcr = fcs.add_parser("create")
    fcr.add_argument("title")
    fcr.add_argument("--uid")
    fcd = fcs.add_parser("delete")
    fcd.add_argument("uid")

    ann = sub.add_parser("annotations")
    ann.add_argument("--dashboard-uid")
    ann.add_argument("--from")
    ann.add_argument("--to")
    ann.add_argument("--tags")

    anc = sub.add_parser("annotation")
    ancs = anc.add_subparsers(dest="annotation_cmd")
    ancr = ancs.add_parser("create")
    ancr.add_argument("--dashboard-uid", required=True)
    ancr.add_argument("--text", required=True)
    ancr.add_argument("--tags")
    ancr.add_argument("--time")
    ancd = ancs.add_parser("delete")
    ancd.add_argument("id")

    sub.add_parser("alert-rules")

    r = sub.add_parser("raw")
    r.add_argument("method")
    r.add_argument("path")
    r.add_argument("json_body", nargs="?")

    return p


def main():
    parser = build_parser()
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    dispatch = {
        "health": cmd_health,
        "search": cmd_search,
        "datasources": cmd_datasources,
        "datasource": lambda a: cmd_datasource_get(a) if a.datasource_cmd == "get" else die("usage: datasource get <id-or-uid>"),
        "folders": cmd_folders,
        "annotations": cmd_annotations,
        "alert-rules": cmd_alert_rules,
        "raw": cmd_raw,
    }

    if args.command == "dashboard":
        if args.dashboard_cmd == "get":
            cmd_dashboard_get(args)
        elif args.dashboard_cmd == "create":
            cmd_dashboard_create(args)
        elif args.dashboard_cmd == "delete":
            cmd_dashboard_delete(args)
        else:
            die("usage: dashboard {get|create|delete}")
    elif args.command == "folder":
        if args.folder_cmd == "create":
            cmd_folder_create(args)
        elif args.folder_cmd == "delete":
            cmd_folder_delete(args)
        else:
            die("usage: folder {create|delete}")
    elif args.command == "annotation":
        if args.annotation_cmd == "create":
            cmd_annotation_create(args)
        elif args.annotation_cmd == "delete":
            cmd_annotation_delete(args)
        else:
            die("usage: annotation {create|delete}")
    elif args.command in dispatch:
        dispatch[args.command](args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
