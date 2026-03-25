#!/usr/bin/env bash
# Creates a handoff file with pre-populated frontmatter.
# Usage: init-handoff.sh <description>
# Output: filepath to the created file (use this to append content)
set -euo pipefail

DESC="${1:?Usage: init-handoff.sh <description>}"

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
ISO_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

FILEPATH="thoughts/handoffs/${TIMESTAMP}_${DESC}.md"
mkdir -p thoughts/handoffs

# Git info (graceful fallback for non-repo contexts)
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "n/a")
BRANCH=$(git branch --show-current 2>/dev/null || echo "n/a")
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")

# Write frontmatter
{
  echo "---"
  echo "date: ${ISO_DATE}"
  echo "git_commit: ${GIT_COMMIT}"
  echo "branch: ${BRANCH}"
  echo "repository: ${REPO}"
  echo "summary: "
  echo "---"
  echo ""
} > "$FILEPATH"

echo "$FILEPATH"
