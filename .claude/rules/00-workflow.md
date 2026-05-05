# Issue-Driven Worktree Workflow

Standard development cycle. Follow these phases in order.

## State Persistence

At every phase transition, update the workflow state in Claude's auto-memory system. Track: project, issue number/title, current phase, plan approval status, branch name, worktree path, PR URL, dependencies, and last-updated date.

At session start: check for in-progress work. If active entries exist, inform the user and offer to resume.

---

## Phase 0: ONBOARDING (first session only)

Run this ONCE when `.claude/rules/01-projects.md` has no entries under `## Projects`.

### Step 1: Scan workspace for git repos

```bash
# Find all git repos in the workspace root (1 level deep)
for dir in */; do
  if [ -d "$dir/.git" ]; then
    echo "$dir"
    (cd "$dir" && git remote -v)
  fi
done
```

### Step 2: Detect project details

For each repo found:
1. **Remotes**: List `origin` and `upstream` URLs
2. **Fork detection**: If both `origin` and `upstream` exist, it's a fork. `origin` is the user's fork, `upstream` is the canonical repo.
3. **Stack detection**: Check for `Cargo.toml` (Rust), `package.json` (Node/JS/TS), `pyproject.toml` / `requirements.txt` (Python), `go.mod` (Go), `pom.xml` (Java), etc.
4. **Existing CLAUDE.md**: Note if the project has its own `CLAUDE.md`
5. **PR template**: Check for `.github/PULL_REQUEST_TEMPLATE.md`

### Step 3: Present and confirm

Show the user a table of discovered projects:

```
| Project | Origin | Upstream | Stack | Has CLAUDE.md |
|---------|--------|----------|-------|---------------|
| myapp   | me/myapp | org/myapp | Rust + TS | Yes |
| lib     | me/lib   | (none)   | Python | No |
```

Ask the user to confirm or correct.

### Step 4: Git author

Check git config:
```bash
git config user.name
git config user.email
```

If empty, ask the user. Persist the confirmed values.

### Step 5: Base branches

For each project, ask:
> "Which branch should I branch from for <project>? (e.g., `main`, `develop`, `master`)"

### Step 6: Persist

Write all confirmed values to `.claude/rules/01-projects.md`. Future sessions read from there and skip onboarding.

### When to re-onboard

Only re-run if:
- User explicitly asks to re-scan projects
- A new project directory appears that isn't in the registry
- User says to change author or base branch

---

## Phase 1: SCOUT -- Fetch & Triage Issues

### Pre-flight: Verify remotes

Before fetching issues, check the project has the expected remotes:

```bash
cd <workspace>/<project>
git remote -v | grep upstream  # or origin if no upstream
```

If missing, ask the user for the URL. Never guess.

### Fetch issues

```bash
# From upstream if it exists, otherwise from origin
gh issue list -R <target-repo> --state open --limit 30

# Read a specific issue
gh issue view NNN -R <repo> --comments
```

Present issues in a table. Ask the user which to tackle.

---

## Phase 2: PLAN -- Design Implementation (REQUIRES APPROVAL)

For each selected issue:

### Step 1: Deep investigation

1. Read the issue body and all comments
2. Read the project's CLAUDE.md and relevant source files
3. Trace affected code paths end-to-end
4. Identify root cause (bugs) or integration points (features)

### Step 2: Build the plan

```
### Issue #NNN -- <title>

**Root cause / Problem**
<2-4 sentences with specific code references (file:line)>

**Approach**
<Numbered steps with file and function references>

**Files to change**
| File | What changes | Why |

**Risks & trade-offs**
**Testing strategy**
**Scope**: small / medium / large
```

### Step 3: Conflict detection (when 2+ issues selected)

Build a file overlap matrix. Classify each pair as:
- **Independent**: zero overlap -> parallel worktrees
- **Coinciding**: shared files or logical dependency -> sequential

### Step 4: STOP and get approval

Present the plan and **wait**. Do not advance until the user approves.

---

## Phase 3: WORKTREE -- Create Isolated Branches

### Step 1: Sync with upstream/origin

```bash
cd <workspace>/<project>
git fetch upstream   # or origin
git checkout <base-branch>
git merge upstream/<base-branch> --ff-only
```

If fast-forward fails, ask the user how to resolve.

### Step 2: Create the worktree

```bash
git worktree add ../<project>-NNN <base-branch> -b <branch-name>
```

**Branch naming**:
- Bug: `fix/NNN-short-slug`
- Feature: `feat/NNN-short-slug`
- Refactor: `refactor/NNN-short-slug`

**Worktree directory**: `<workspace>/<project>-NNN`

### Step 3: Install dependencies if needed

- Rust: `cargo check`
- Node: `npm install` / `yarn install`
- Python: `pip install -e .`

---

## Phase 4: IMPLEMENT -- Code the Solution

### Parallel execution (independent issues)

Use the Agent tool to spin up parallel subagents -- one per worktree.

### Sequential execution (coinciding issues)

Implement one at a time in dependency order.

### Quality gates

Before an issue is done:
- [ ] Code compiles / type-checks
- [ ] Lint passes
- [ ] Tests pass
- [ ] Changes scoped to the issue only

---

## Phase 5: PR -- Commit & Open Pull Request

### Step 1: Verify git author

```bash
git config user.name
git config user.email
```

If not set, use the values from Phase 0.

### Step 2: Commit

```bash
git add <specific-files>   # NEVER git add -A
git commit -m "<type>(scope): description (#NNN)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 3: Push and open PR

```bash
git push -u origin <branch-name>

gh pr create \
  -R <target-repo> \
  --head <fork-owner>:<branch-name> \
  --title "<type>(scope): description (#NNN)" \
  --body "..."
```

Use the project's PR template if one exists. Include `Closes #NNN`.

---

## Phase 6: REVIEW -- Resolve PR Feedback

**The job is NOT finished when the PR opens.** A PR is only complete when **both** of the following are true:

1. **CI is green** -- every required check on the PR has status `success` (or is explicitly waived by a maintainer in the thread).
2. **All reviewer comments are resolved** -- every actionable comment from a human reviewer or bot (CodeRabbit, Codecov, etc.) has either been addressed by a follow-up commit OR explicitly acknowledged + replied to with reasoning if intentionally deferred.

Until both conditions hold, the issue stays in `phase: 6-REVIEW`. Do not mark `DONE`, do not start cleanup, do not move on to a new issue's Phase 4 in the same project area.

### Step 1: Initial scan (run immediately after opening the PR)

```bash
# Top-level + review summaries
gh pr view NNN -R <repo> --comments

# Inline review comments (file:line annotations)
gh api repos/<owner>/<repo>/pulls/NNN/comments

# CI status
gh pr checks NNN -R <repo>
```

Record a snapshot in workflow state: count of unresolved comments, list of failing/pending checks.

### Step 2: Continuous re-scan until both gates close

After every push to the branch (and at session start if the entry is in `phase: 6-REVIEW`), re-run all three commands above. CI re-runs on each push, and reviewer comments arrive asynchronously.

For sustained monitoring of a long-running run, prefer a one-shot wait command over polling in chat:

```bash
gh pr checks NNN -R <repo> --watch    # blocks until all checks reach a terminal state
```

When that exits, re-read the comments -- reviewers often arrive after CI signals.

### Step 3: Address every signal

| Signal | Action |
|---|---|
| **CI check failed** | Read the failure log (`gh run view <run-id> --log-failed -R <repo>`), reproduce locally if possible, fix in worktree, commit, push. Do NOT bypass with `--no-verify` unless the failure is unrelated to your changes AND the user has authorised it. |
| **CI check pending too long** | Don't escalate prematurely. If a check has been pending >30 min and others have completed, surface to the user before assuming it's broken. |
| **Reviewer comment -- actionable** | Fix in the worktree. Commit message should reference the feedback. Push. Reply on the thread once the fix lands. |
| **Reviewer comment -- bot (CodeRabbit / Codecov)** | Treat as actionable unless clearly false-positive. If false-positive, reply on the thread with a one-line reason. |
| **Reviewer comment -- request to defer** | Reply on the thread acknowledging, link a follow-up issue/TODO if you're filing one, and persist the deferred item under "Deferred follow-ups". |
| **Approval received** | Note that the PR is approved and awaiting merge. The job stays in `6-REVIEW` until the PR is actually merged or closed. |

### Step 4: Closing the loop

The PR exits `6-REVIEW` when **all** of the following hold:

- All required CI checks are `success`.
- Every reviewer comment thread is resolved (closed by a maintainer, or your reply has been acknowledged, or you've filed a follow-up and noted it as deferred).
- The PR is either **merged** (transition to Cleanup) or **closed** as withdrawn / duplicate (note the reason and skip Cleanup).

Update workflow state after each scan -- current CI status, count of open vs resolved comments, last-scan timestamp. When both gates close, transition to `DONE` (if merged) or `CLOSED` (if withdrawn).

### Anti-patterns

- Opening the PR and stopping. Phase 5 is not the finish line -- Phase 6 is.
- Pushing fix commits without re-scanning CI on the new commits. Each push starts a new check run; assume nothing.
- Marking `DONE` because "the PR was opened" or "I pushed the review fixes". `DONE` requires merge.
- Treating bot comments (CodeRabbit, Codecov) as ignorable noise. They are part of the review surface; respond to each one.
- Reusing the worktree for unrelated work while the PR is still in `6-REVIEW`. Keep the worktree clean for review-feedback iteration until the PR is closed.

---

## Cleanup (after merge)

```bash
cd <workspace>/<project>
git worktree remove ../<project>-NNN
git branch -d <branch-name>
git fetch upstream && git merge upstream/<base-branch> --ff-only
```
