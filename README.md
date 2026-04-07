# Worktree Workflow for Claude Code

A reusable, issue-driven git worktree workflow for multi-project workspaces. Drop this into any workspace directory and Claude Code will auto-discover your projects and guide you through a structured development cycle.

## What it does

Six-phase development cycle:

```
1. SCOUT    -- fetch & triage GitHub issues
2. PLAN     -- design implementation (approval gate)
3. WORKTREE -- create isolated git worktrees
4. IMPLEMENT -- code the solution (parallel when possible)
5. PR       -- commit, push, open pull request
6. REVIEW   -- scan PR comments, resolve feedback
```

## Setup

1. **Copy into your workspace root:**

```bash
cd /path/to/your/workspace  # contains multiple git repos as subdirectories
git clone <this-repo> .claude-workflow
cp -r .claude-workflow/CLAUDE.md .
cp -r .claude-workflow/.claude .
rm -rf .claude-workflow
```

Or just copy the files manually:
```
your-workspace/
  CLAUDE.md                    <-- copy this
  .claude/
    rules/
      00-workflow.md           <-- copy this
      01-projects.md           <-- copy this (empty template)
    agents/
      issue-scout.md           <-- copy this
      planner.md               <-- copy this
      worktree-dev.md          <-- copy this
      pr-pilot.md              <-- copy this
  project-a/                   <-- your existing repos
  project-b/
  project-c/
```

2. **Start Claude Code** in your workspace root.

3. **Say anything** like "fetch issues" or "what's open" -- Claude will detect it's the first run, scan your repos, and walk you through onboarding.

## How onboarding works

On the first session, Claude will:

1. Scan for git repos in the workspace (1 level deep)
2. Detect remotes (origin, upstream) to identify forks
3. Detect tech stack (Rust, Node, Python, Go, etc.)
4. Ask you to confirm the project list
5. Read your `git config` for author identity
6. Ask for default base branches (main, develop, etc.)
7. Save everything to `.claude/rules/01-projects.md`

After onboarding, everything works automatically. Re-onboard anytime by clearing the projects file.

## Usage

Just talk naturally:

- **"fetch issues for myapp"** -- scouts open issues
- **"let's work on #42"** -- plans the implementation, waits for your approval
- **"fix it"** -- creates worktree, implements, runs checks
- **"raise PR"** -- commits, pushes, opens PR against upstream
- **"check PR comments"** -- scans review feedback and pushes fixes

Multiple issues? Claude detects file overlaps and runs independent issues in parallel worktrees.

## Requirements

- [Claude Code](https://claude.ai/code) CLI or IDE extension
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated
- Git with worktree support (any modern version)

## Customization

- **Add project-specific rules**: Each project can have its own `CLAUDE.md` with build commands, conventions, etc.
- **Modify agents**: Edit files in `.claude/agents/` to change behavior.
- **Add phases**: Extend `00-workflow.md` with custom phases (e.g., deploy, release).

## License

MIT
