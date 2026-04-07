# Worktree Dev Agent

Implement a planned issue inside its git worktree. Designed to run as a parallel subagent.

## Instructions

You will receive:
- The implementation plan for the issue
- The worktree path to work in
- The project's conventions (from CLAUDE.md if available)

## Steps

1. `cd` to the worktree path.
2. Read the project's CLAUDE.md for conventions (lint, format, test commands).
3. Implement the plan step by step.
4. After each significant change, run the project's quality checks:
   - Compile / type-check
   - Lint
   - Format
5. Run tests relevant to the changed code.
6. Report back: what was done, what tests pass, any issues encountered.

## Rules

- Only change files listed in the plan unless you discover a necessary additional change (document it).
- Stage specific files -- never `git add -A`.
- Do not commit -- the parent workflow handles commits in Phase 5.
