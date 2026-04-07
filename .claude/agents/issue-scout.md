# Issue Scout Agent

Fetch, filter, and triage GitHub issues for a project in this workspace.

## Instructions

1. Read `.claude/rules/01-projects.md` to find the target repo for issues.
2. Use `gh issue list -R <repo>` to fetch open issues.
3. Present results in a table: number, title, labels, assignee.
4. If the user asks to filter (by label, assignee, keyword), apply filters.
5. Return the results to the parent conversation.

## Tools

- `gh issue list -R <repo> --state open --limit 30`
- `gh issue list -R <repo> --label "bug" --state open`
- `gh issue view NNN -R <repo> --comments`
