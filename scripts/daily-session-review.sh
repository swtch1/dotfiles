#!/usr/bin/env bash
# Daily session review — runs via launchd at 1700 Eastern
# Exports today's opencode sessions and asks opencode to review them.

set -euo pipefail

OPENCODE="/Users/josh/.opencode/bin/opencode"
REVIEW_DIR="$HOME/doc/daily-reviews"
TODAY=$(date +%Y-%m-%d)
REVIEW_FILE="$REVIEW_DIR/$TODAY.md"
TMPDIR_WORK=$(mktemp -d)

trap 'rm -rf "$TMPDIR_WORK"' EXIT

mkdir -p "$REVIEW_DIR"

# Get today's sessions.
# Today's sessions show only a time (no date separator "·"), older ones show "· M/D/YYYY".
SESSION_IDS=$($OPENCODE session list 2>/dev/null \
  | grep -v '·' \
  | grep -oE 'ses_[A-Za-z0-9]+' \
  || true)

if [ -z "$SESSION_IDS" ]; then
  echo "# Daily Review — $TODAY" > "$REVIEW_FILE"
  echo "" >> "$REVIEW_FILE"
  echo "No sessions found for today." >> "$REVIEW_FILE"
  exit 0
fi

SESSION_COUNT=$(echo "$SESSION_IDS" | wc -l | tr -d ' ')

# Export each session to a separate file
EXPORT_FILES=""
for SID in $SESSION_IDS; do
  EXPORT_FILE="$TMPDIR_WORK/${SID}.json"
  $OPENCODE export "$SID" > "$EXPORT_FILE" 2>/dev/null || true
  if [ -s "$EXPORT_FILE" ]; then
    EXPORT_FILES="$EXPORT_FILES $EXPORT_FILE"
  fi
done

if [ -z "$EXPORT_FILES" ]; then
  echo "# Daily Review — $TODAY" > "$REVIEW_FILE"
  echo "" >> "$REVIEW_FILE"
  echo "Found $SESSION_COUNT sessions but failed to export any." >> "$REVIEW_FILE"
  exit 1
fi

# Build file attachment flags
FILE_FLAGS=""
for F in $EXPORT_FILES; do
  FILE_FLAGS="$FILE_FLAGS -f $F"
done

# Run opencode to review the sessions
PROMPT="You are reviewing my opencode sessions from today ($TODAY). I've attached the exported session data as JSON files.

Please produce a daily review in markdown with these sections:

## Sessions Overview
A table listing each session: title, approximate duration/message count, and primary topic.

## What I Worked On
A narrative summary of the day's work — themes, projects, goals pursued. Group related sessions.

## Key Decisions & Outcomes
Important decisions made, problems solved, or artifacts produced.

## Areas for Improvement
Be honest and specific. Look for:
- Patterns of inefficiency (repeated debugging cycles, going in circles)
- Tasks that could have been approached differently
- Knowledge gaps that slowed me down
- Sessions where I gave up or pivoted without resolution

## Tomorrow's Suggestions
Based on today's work, what should I prioritize or revisit tomorrow?

Write the output as clean markdown. Be direct — no fluff."

# shellcheck disable=SC2086
$OPENCODE run \
  --title "Daily Review: $TODAY" \
  $FILE_FLAGS \
  -- "$PROMPT" > "$REVIEW_FILE" 2>/dev/null

echo "Review written to $REVIEW_FILE"
