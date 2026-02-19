#!/usr/bin/env bash
# Initialize .specs/ directory structure in the current repository.
# Run from the repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONVENTIONS_TEMPLATE="$SKILL_DIR/assets/conventions-template.md"
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

# Create directory structure
mkdir -p "$SPECS_DIR/domains"
mkdir -p "$SPECS_DIR/tasks/features"
mkdir -p "$SPECS_DIR/tasks/bugs"

# Copy conventions template if CONVENTIONS.md doesn't exist yet
if [ ! -f "$SPECS_DIR/CONVENTIONS.md" ]; then
    if [ -f "$CONVENTIONS_TEMPLATE" ]; then
        cp "$CONVENTIONS_TEMPLATE" "$SPECS_DIR/CONVENTIONS.md"
        echo "Created $SPECS_DIR/CONVENTIONS.md from template"
    else
        echo "Warning: Conventions template not found at $CONVENTIONS_TEMPLATE"
        echo "Creating minimal CONVENTIONS.md"
        echo "# Spec Conventions" > "$SPECS_DIR/CONVENTIONS.md"
        echo "" >> "$SPECS_DIR/CONVENTIONS.md"
        echo "TODO: Define your team's spec conventions here." >> "$SPECS_DIR/CONVENTIONS.md"
    fi
else
    echo "CONVENTIONS.md already exists, skipping"
fi

# Copy agents template if AGENTS.md doesn't exist yet
if [ ! -f "$SPECS_DIR/AGENTS.md" ]; then
    if [ -f "$AGENTS_TEMPLATE" ]; then
        cp "$AGENTS_TEMPLATE" "$SPECS_DIR/AGENTS.md"
        echo "Created $SPECS_DIR/AGENTS.md from template"
    else
        echo "Warning: Agents template not found at $AGENTS_TEMPLATE"
        echo "Creating minimal AGENTS.md"
        echo "# Spec Implementation Guide" > "$SPECS_DIR/AGENTS.md"
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
echo "  ├── CONVENTIONS.md"
echo "  ├── domains/"
echo "  └── tasks/"
echo "      ├── features/"
echo "      └── bugs/"
echo ""
echo "Next: Review and customize .specs/CONVENTIONS.md for your project."
