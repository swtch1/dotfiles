#!/usr/bin/env bash
# Initialize .specs/ directory structure in the current repository.
# Run from the repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
AGENTS_TEMPLATE="$SKILL_DIR/assets/agents-template.md"

# Determine repo root (prefer git root, fallback to cwd)
if git rev-parse --show-toplevel &>/dev/null; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
else
    REPO_ROOT="$(pwd)"
    echo "Warning: Not in a git repository. Using current directory: $REPO_ROOT"
fi

SPECS_DIR="$REPO_ROOT/.specs"

if [ -d "$SPECS_DIR" ]; then
    echo ".specs/ already exists at $SPECS_DIR"
    echo "Checking for missing subdirectories..."
fi

# Create directory structure (domain docs live in per-directory AGENTS.md files, not here)
mkdir -p "$SPECS_DIR/features"
mkdir -p "$SPECS_DIR/bugs"

# Copy agents template if AGENTS.md doesn't exist yet
if [ ! -f "$SPECS_DIR/AGENTS.md" ]; then
    if [ -f "$AGENTS_TEMPLATE" ]; then
        cp "$AGENTS_TEMPLATE" "$SPECS_DIR/AGENTS.md"
        echo "Created $SPECS_DIR/AGENTS.md from template"
    else
        echo "Warning: Agents template not found at $AGENTS_TEMPLATE"
        echo "Creating minimal AGENTS.md"
        echo "# Spec System" > "$SPECS_DIR/AGENTS.md"
        echo "" >> "$SPECS_DIR/AGENTS.md"
        echo "TODO: Define your agent workflow for specs here." >> "$SPECS_DIR/AGENTS.md"
    fi
else
    echo "AGENTS.md already exists, skipping"
fi

# .specs/ should be committed, not ignored.

echo ""
echo "Initialized .specs/ at $SPECS_DIR"
echo ""
echo "Structure:"
echo "  .specs/"
echo "  ├── AGENTS.md"
echo "  ├── features/"
echo "  └── bugs/"
echo ""
echo "Next steps:"
echo "  1. Review .specs/AGENTS.md and add project-specific guidance"
echo "  2. If using Cursor, create .cursor/rules/*.mdc files to auto-load"
echo "     per-directory AGENTS.md files"
