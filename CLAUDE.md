# Worktree Workflow

Multi-project workspace with an issue-driven git worktree workflow. Each subdirectory can be an independent git repo.

---

## First Run: Onboarding

On the **very first session** (when `.claude/rules/01-projects.md` has no entries under `## Projects`), run the onboarding flow automatically:

1. **Scan workspace** for git repos (directories containing `.git/`)
2. **Detect remotes** for each repo (`origin`, `upstream`, others)
3. **Detect stack** (check for `Cargo.toml`, `package.json`, `pyproject.toml`, `go.mod`, etc.)
4. **Present findings** to the user as a table and ask for confirmation
5. **Read git config** (`git config user.name`, `git config user.email`) and ask user which identity to use
6. **Ask default base branch** for each project (e.g., `main`, `develop`, `master`)
7. **Persist** everything to `.claude/rules/01-projects.md`

After onboarding, the workflow is ready. Re-onboarding can be triggered by clearing the `## Projects` section.

---

## MANDATORY: Auto-engage Workflow

When the user's message matches ANY of these intents, **immediately follow the phased workflow** in `.claude/rules/00-workflow.md`:

| User says something like... | Start at phase |
|---|---|
| "fetch issues", "list issues", "what's open", "scan issues", "show me bugs" | **Phase 1: SCOUT** |
| "plan this", "plan #NNN", "let's work on #NNN", "pick issues" | **Phase 2: PLAN** |
| "create worktree", "set up branches", "start working on these" | **Phase 3: WORKTREE** |
| "implement", "code it", "build it", "fix it" | **Phase 4: IMPLEMENT** |
| "raise PR", "open PR", "submit", "push" | **Phase 5: PR** |
| "check comments", "review feedback", "scan PR", "resolve reviews" | **Phase 6: REVIEW** |

**Each phase gates the next** -- if a prerequisite phase hasn't been done yet, run it first.

**Phase 2 is an approval gate** -- ALWAYS present the full implementation plan and **wait for the user to approve** before creating worktrees or writing code.

**Conflict detection is not optional** -- when 2+ issues are selected, ALWAYS run the file overlap analysis from Phase 2 before creating worktrees.

---

## Rules

- **One worktree per issue** -- never mix unrelated issues in a single branch.
- **Branch naming**: `fix/NNN-slug` for bugs, `feat/NNN-slug` for features, `refactor/NNN-slug` for cleanup.
- **Worktree directory naming**: `<project>-NNN` at the workspace root.
- **Read the project's CLAUDE.md** before touching any code in that project.
- **Stage specific files** -- never `git add -A` or `git add .`.
- **Parallel worktrees** -- issues with no file/module overlap should be worked in separate worktrees simultaneously.
- **Coinciding issues** -- if two issues touch the same files, they MUST be executed sequentially.

---

## Agents

| Agent | Purpose |
|-------|---------|
| **issue-scout** | Fetch, filter, and triage GitHub issues for a project |
| **planner** | Design implementation plan for a specific issue |
| **worktree-dev** | Implement a planned issue inside its git worktree |
| **pr-pilot** | Create PRs, scan review comments, push fixes |
