#!/usr/bin/env bash
# Worktree Workflow installer for Claude Code
# Usage: curl -sL https://raw.githubusercontent.com/jainsanil18/worktree-workflow/master/install.sh | bash
#    or: bash install.sh /path/to/workspace

set -e

TARGET="${1:-$(pwd)}"
REPO="https://raw.githubusercontent.com/jainsanil18/worktree-workflow/master"

echo "Installing worktree-workflow into: $TARGET"
echo ""

# Create directories
mkdir -p "$TARGET/.claude/rules"
mkdir -p "$TARGET/.claude/agents"

# Download files
echo "Downloading files..."
curl -sL "$REPO/CLAUDE.md" -o "$TARGET/CLAUDE.md"
curl -sL "$REPO/.claude/rules/00-workflow.md" -o "$TARGET/.claude/rules/00-workflow.md"
curl -sL "$REPO/.claude/rules/01-projects.md" -o "$TARGET/.claude/rules/01-projects.md"
curl -sL "$REPO/.claude/agents/issue-scout.md" -o "$TARGET/.claude/agents/issue-scout.md"
curl -sL "$REPO/.claude/agents/planner.md" -o "$TARGET/.claude/agents/planner.md"
curl -sL "$REPO/.claude/agents/worktree-dev.md" -o "$TARGET/.claude/agents/worktree-dev.md"
curl -sL "$REPO/.claude/agents/pr-pilot.md" -o "$TARGET/.claude/agents/pr-pilot.md"

echo ""
echo "Installed:"
echo "  $TARGET/CLAUDE.md"
echo "  $TARGET/.claude/rules/00-workflow.md"
echo "  $TARGET/.claude/rules/01-projects.md"
echo "  $TARGET/.claude/agents/issue-scout.md"
echo "  $TARGET/.claude/agents/planner.md"
echo "  $TARGET/.claude/agents/worktree-dev.md"
echo "  $TARGET/.claude/agents/pr-pilot.md"
echo ""
echo "Done. Open Claude Code in $TARGET and say 'fetch issues' to start."
