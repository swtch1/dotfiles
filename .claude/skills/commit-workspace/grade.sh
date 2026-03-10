#!/usr/bin/env bash
# Grade commit skill eval runs programmatically
# Outputs JSON grading results per run
set -euo pipefail

WS="/Users/josh/.claude/skills/commit-workspace/iteration-1"

grade_run() {
  local eval_name="$1" config="$2"
  local dir="$WS/$eval_name/$config"
  local repo="$dir/repo"
  local msgs="$dir/outputs/commit-messages.txt"
  local stat="$dir/outputs/git-log-stat.txt"
  local status_after="$dir/outputs/git-status-after.txt"

  echo "=== $eval_name / $config ==="

  # Count new commits (exclude "initial" commits)
  local new_commits
  new_commits=$(grep -cv "^initial" "$msgs" 2>/dev/null || echo 0)
  echo "  New commits: $new_commits"

  case "$eval_name" in
    multi-domain-changes)
      # A1: More than 1 commit
      if [ "$new_commits" -gt 1 ]; then echo "  [PASS] A1: More than 1 commit ($new_commits)"; else echo "  [FAIL] A1: Only $new_commits commit(s)"; fi

      # A2: Auth files grouped? Check if middleware.go and config.go are in same commit
      local auth_commit config_commit handler_commit
      auth_commit=$(git -C "$repo" log --format='%H' -- pkg/auth/middleware.go | head -1)
      config_commit=$(git -C "$repo" log --format='%H' -- pkg/config/config.go | head -1)
      handler_commit=$(git -C "$repo" log --format='%H' -- pkg/api/handler.go | head -1)
      if [ "$auth_commit" = "$config_commit" ] || [ "$auth_commit" = "$handler_commit" ]; then
        echo "  [PASS] A2: Auth files grouped (auth=$auth_commit config=$config_commit handler=$handler_commit)"
      else
        echo "  [FAIL] A2: Auth files NOT grouped (auth=$auth_commit config=$config_commit handler=$handler_commit)"
      fi

      # A3: Logging fix separate from auth
      local log_commit
      log_commit=$(git -C "$repo" log --format='%H' -- pkg/logging/logger.go | head -1)
      if [ "$log_commit" != "$auth_commit" ] && [ "$log_commit" != "$config_commit" ]; then
        echo "  [PASS] A3: Logging fix is separate commit"
      else
        echo "  [FAIL] A3: Logging fix in same commit as auth"
      fi

      # A4: No forbidden terms
      if grep -qi -E "anthropic|claude|ai assistant" "$msgs"; then
        echo "  [FAIL] A4: Forbidden terms found in commit messages"
      else
        echo "  [PASS] A4: No forbidden terms"
      fi

      # A5: Descriptive messages (check for generic terms)
      if grep -qi -E "^(update files|changes|misc|various)$" "$msgs"; then
        echo "  [FAIL] A5: Generic commit message detected"
      else
        echo "  [PASS] A5: Commit messages are descriptive"
      fi

      # A6: All files committed
      local remaining
      remaining=$(git -C "$repo" status --short 2>/dev/null | grep -v "^??" | wc -l | tr -d ' ')
      if [ "$remaining" -eq 0 ]; then echo "  [PASS] A6: All files committed"; else echo "  [FAIL] A6: $remaining files remain uncommitted"; fi
      ;;

    thoughts-exclusion)
      # A1: No thoughts/ in commits
      if git -C "$repo" log --all --name-only --format='' | grep -q "^thoughts/"; then
        echo "  [FAIL] A1: thoughts/ files found in commits"
      else
        echo "  [PASS] A1: No thoughts/ files in commits"
      fi

      # A2: src/api.go committed
      if git -C "$repo" log --name-only --format='' HEAD~1..HEAD | grep -q "src/api.go"; then
        echo "  [PASS] A2: src/api.go committed"
      else
        echo "  [FAIL] A2: src/api.go NOT committed"
      fi

      # A3: src/api_test.go committed
      if git -C "$repo" log --name-only --format='' HEAD~1..HEAD | grep -q "src/api_test.go"; then
        echo "  [PASS] A3: src/api_test.go committed"
      else
        echo "  [FAIL] A3: src/api_test.go NOT committed"
      fi

      # A4: thoughts/ remains untracked
      if [ -f "$status_after" ] && grep -q "thoughts/" "$status_after"; then
        echo "  [PASS] A4: thoughts/ remains untracked"
      else
        echo "  [FAIL] A4: thoughts/ status unclear"
      fi

      # A5: No forbidden terms
      if grep -qi -E "anthropic|claude|ai assistant" "$msgs"; then
        echo "  [FAIL] A5: Forbidden terms found"
      else
        echo "  [PASS] A5: No forbidden terms"
      fi
      ;;

    single-logical-change)
      # A1: Exactly 1 new commit
      if [ "$new_commits" -eq 1 ]; then echo "  [PASS] A1: Exactly 1 commit"; else echo "  [FAIL] A1: $new_commits commits (expected 1)"; fi

      # A2: All 3 files in the commit
      local files_in_commit
      files_in_commit=$(git -C "$repo" log --name-only --format='' HEAD~1..HEAD | sort)
      local has_routes has_service has_test
      has_routes=$(echo "$files_in_commit" | grep -c "routes.go" || true)
      has_service=$(echo "$files_in_commit" | grep -c "service.go" || true)
      has_test=$(echo "$files_in_commit" | grep -c "service_test.go" || true)
      if [ "$has_routes" -ge 1 ] && [ "$has_service" -ge 1 ] && [ "$has_test" -ge 1 ]; then
        echo "  [PASS] A2: All 3 files in commit"
      else
        echo "  [FAIL] A2: Missing files (routes=$has_routes service=$has_service test=$has_test)"
      fi

      # A3: Message mentions rename
      if grep -qi -E "rename|fetch|getuser" "$msgs"; then
        echo "  [PASS] A3: Commit message mentions rename"
      else
        echo "  [FAIL] A3: No rename reference in message"
      fi

      # A4: No forbidden terms
      if grep -qi -E "anthropic|claude|ai assistant" "$msgs"; then
        echo "  [FAIL] A4: Forbidden terms found"
      else
        echo "  [PASS] A4: No forbidden terms"
      fi
      ;;
  esac
  echo ""
}

# Grade all 6 runs
for eval_name in multi-domain-changes thoughts-exclusion single-logical-change; do
  for config in with_skill without_skill; do
    grade_run "$eval_name" "$config"
  done
done
