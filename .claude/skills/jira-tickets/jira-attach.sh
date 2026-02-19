#!/usr/bin/env bash
set -e

# Upload file attachments to a Jira ticket.
# Uses the OAuth token from acli's macOS keychain entry and the cloud ID
# from ~/.config/acli/jira_config.yaml.
#
# Usage: jira-attach.sh SPD-1234 file1.java file2.yaml ...

if [ $# -lt 2 ]; then
  echo "Usage: $(basename "$0") <TICKET-KEY> <FILE> [FILE...]" >&2
  exit 1
fi

TICKET_KEY="$1"
shift

CLOUD_ID=$(grep 'cloud_id:' ~/.config/acli/jira_config.yaml | head -1 | awk '{print $2}')
if [ -z "$CLOUD_ID" ]; then
  echo "ERROR: could not read cloud_id from ~/.config/acli/jira_config.yaml - are you logged in?" >&2
  exit 1
fi

ACCESS_TOKEN=$(
  security find-generic-password -s "acli" -w \
    | sed 's/^go-keyring-base64://' \
    | base64 -d \
    | gzip -d 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])"
)
if [ -z "$ACCESS_TOKEN" ]; then
  echo "ERROR: could not extract OAuth token from keychain" >&2
  echo "Make sure you are logged in: acli jira auth login" >&2
  exit 1
fi

API="https://api.atlassian.com/ex/jira/$CLOUD_ID/rest/api/3/issue/$TICKET_KEY/attachments"

for filepath in "$@"; do
  if [ ! -f "$filepath" ]; then
    echo "SKIP  $filepath (not found)" >&2
    continue
  fi
  filename=$(basename "$filepath")

  HTTP_CODE=$(curl -s -o /tmp/jira-attach-response.json -w "%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-Atlassian-Token: no-check" \
    -F "file=@$filepath" \
    "$API")

  if [ "$HTTP_CODE" = "200" ]; then
    att_id=$(python3 -c "import sys,json; print(json.loads(open('/tmp/jira-attach-response.json').read())[0]['id'])" 2>/dev/null || echo "?")
    echo "✓ $filename → $TICKET_KEY (attachment id=$att_id)"
  else
    echo "✗ $filename → HTTP $HTTP_CODE" >&2
    cat /tmp/jira-attach-response.json >&2
    echo >&2
  fi
done

rm -f /tmp/jira-attach-response.json
