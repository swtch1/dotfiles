---
name: gitlab-ci
description: "Manage GitLab CI/CD pipelines and jobs via the `glab` CLI. This skill should be used when the user mentions a GitLab pipeline, CI/CD job, job logs, pipeline retry, or any GitLab CI operations. Trigger on patterns like pipeline URLs (gitlab.com/.../pipelines/ID), job URLs (gitlab.com/.../jobs/ID), or keywords like 'pipeline', 'CI/CD', 'GitLab CI', 'job logs', 'retry job', 'rerun pipeline'."
---

# GitLab CI/CD via `glab` CLI

Use `glab` to manage GitLab CI/CD. Run `glab help ci` for full subcommand list.

## URL Parsing

Extract project path and ID from GitLab URLs:
- `https://gitlab.com/group/project/-/pipelines/12345` → `-R group/project`, pipeline `12345`
- `https://gitlab.com/group/sub/project/-/jobs/67890` → `-R group/sub/project`, job `67890`

The `-R` flag also accepts full URLs directly: `-R https://gitlab.com/group/project`

## Quick Reference

```bash
glab ci get --pipeline-id <ID> -R <PROJECT>        # Pipeline details
glab ci get --pipeline-id <ID> -R <PROJECT> -o json # JSON output
glab ci list -R <PROJECT> -F json                   # List pipelines (JSON)
glab ci list -R <PROJECT> --status=failed           # Filter by status
glab ci trace <JOB_ID> -R <PROJECT>                 # Job logs (works for finished jobs too)
glab ci retry <JOB_ID> -R <PROJECT>                 # Retry -> creates NEW job with new ID
glab ci trigger <JOB_ID> -R <PROJECT>               # Trigger manual job
glab ci cancel job <JOB_ID> -R <PROJECT>            # Cancel job
glab ci cancel pipeline <PID> -R <PROJECT>          # Cancel pipeline
glab ci run -b <BRANCH> -R <PROJECT>                # Run new pipeline
glab ci run --mr -R <PROJECT>                       # Run MR pipeline (can't use --variables)
```

For status, lint, artifacts, schedules, delete: run `glab help ci` or `glab help schedule`.

## Listing Jobs in a Pipeline (API Required)

No built-in subcommand exists. Use the API with URL-encoded project path (`/` → `%2F`):

```bash
glab api projects/group%2Fproject/pipelines/<PIPELINE_ID>/jobs
```

## Direct API Access

`glab api` handles auth automatically. URL-encode project paths (`/` → `%2F`).

```bash
glab api projects/group%2Fproject/pipelines/<ID>               # GET (default)
glab api projects/group%2Fproject/jobs/<JID>/trace             # Job log via API
glab api projects/group%2Fproject/pipelines/<ID>/retry -X POST # Retry all failed
glab api projects/group%2Fproject/jobs/<JID>/play -X POST      # Play manual job
```

## Gotchas

1. **`glab ci view` is a TUI** — Do NOT use. Use `glab ci get` + `glab api` instead.
2. **Retry creates a NEW job** — Old job ID keeps its original status.
3. **JSON flag inconsistency** — `ci get` uses `-o json`, `ci list` uses `-F json`.
4. **Job logs have ANSI codes** — Strip with `sed 's/\x1b\[[0-9;]*m//g'` if needed.
5. **`--mr` + `--variables` incompatible** — Use `--input` for CI inputs on MR pipelines.
