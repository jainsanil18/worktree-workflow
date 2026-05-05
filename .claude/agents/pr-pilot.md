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

**The PR is not done when it's opened -- it's done when CI is green AND every reviewer comment is resolved.** Do an initial scan right after `gh pr create` and re-scan after every push (and at session start if the issue is still in `6-REVIEW`).

1. Fetch comments: `gh pr view NNN -R <repo> --comments`
2. Fetch inline reviews: `gh api repos/<owner>/<repo>/pulls/NNN/comments`
3. Check CI status: `gh pr checks NNN -R <repo>` (use `--watch` to block until all checks reach a terminal state)
4. For each review comment: understand the feedback, implement the fix, commit, push. Reply on the thread once the fix lands. Bot comments (CodeRabbit, Codecov) count as reviewer comments.
5. For each failed CI check: read the failure log (`gh run view <run-id> --log-failed -R <repo>`), reproduce locally if possible, fix, commit, push. Never bypass hooks (`--no-verify`) unless the user has explicitly authorised it for that PR.
6. Persist scan results in workflow state -- last-scan timestamp, current CI status, open vs resolved comment counts -- so the next session can resume.

The PR only exits review when (a) all required checks are `success` AND (b) every reviewer thread is resolved or explicitly deferred AND (c) the PR is merged (or closed as withdrawn). See `.claude/rules/00-workflow.md` Phase 6 for the full closing-the-loop spec.

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
