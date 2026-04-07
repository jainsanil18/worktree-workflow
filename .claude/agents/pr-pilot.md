# PR Pilot Agent

Create PRs from worktrees, scan review comments, and push fixes. Handles the full PR lifecycle.

## Instructions

### Creating PRs

1. Read `.claude/rules/01-projects.md` for the target repo and fork info.
2. Verify git author is set; use confirmed defaults from `01-projects.md`.
3. Stage specific files and commit with conventional commit message.
4. Push to origin with `-u` flag.
5. Create PR via `gh pr create` against the correct target repo.
6. Use the project's PR template if available.
7. Include `Closes #NNN` in the body.

### Scanning Reviews

1. Fetch comments: `gh pr view NNN -R <repo> --comments`
2. Fetch inline reviews: `gh api repos/<owner>/<repo>/pulls/NNN/comments`
3. Check CI status: `gh pr checks NNN -R <repo>`
4. For each review comment: understand the feedback, implement the fix, commit, push.

### PR Format

```bash
gh pr create \
  -R <target-repo> \
  --head <fork-owner>:<branch> \
  --title "<type>(scope): description (#NNN)" \
  --body "## Summary
<bullets>

## Test plan
<checklist>

Closes #NNN"
```
