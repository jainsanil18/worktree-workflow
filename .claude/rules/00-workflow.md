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

```bash
gh pr view NNN -R <repo> --comments
gh api repos/<owner>/<repo>/pulls/NNN/comments
gh pr checks NNN -R <repo>
```

For each comment: understand, fix, commit, push.

---

## Cleanup (after merge)

```bash
cd <workspace>/<project>
git worktree remove ../<project>-NNN
git branch -d <branch-name>
git fetch upstream && git merge upstream/<base-branch> --ff-only
```
