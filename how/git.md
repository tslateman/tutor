# Git Cheat Sheet

## Configuration

```bash
# Set identity
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Set default branch name
git config --global init.defaultBranch main

# Set default editor
git config --global core.editor "nvim"

# Enable color
git config --global color.ui auto

# Set aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all"

# View config
git config --list
git config --global --list
git config user.name
```

## Creating Repositories

```bash
# Initialize new repo
git init
git init my-project

# Clone existing repo
git clone https://github.com/user/repo.git
git clone git@github.com:user/repo.git
git clone https://github.com/user/repo.git my-folder
git clone --depth 1 https://...  # Shallow clone (latest commit only)
git clone --branch dev https://... # Clone specific branch
```

## Basic Workflow

### Staging & Committing

```bash
# Check status
git status
git status -s              # Short format

# Stage files
git add file.txt           # Single file
git add file1.txt file2.txt
git add *.js               # By pattern
git add src/               # Directory
git add .                  # All changes in current dir
git add -A                 # All changes in repo
git add -p                 # Interactive staging (hunks)

# Unstage files
git reset file.txt         # Unstage, keep changes
git restore --staged file.txt  # Same (Git 2.23+)

# Discard changes
git checkout -- file.txt   # Old way
git restore file.txt       # Git 2.23+

# Commit
git commit -m "Message"
git commit                 # Opens editor
git commit -am "Message"   # Stage tracked + commit
git commit --amend         # Modify last commit
git commit --amend --no-edit  # Amend without changing message
git commit --allow-empty -m "Empty commit"
```

### Viewing Changes

```bash
# Differences
git diff                   # Unstaged changes
git diff --staged          # Staged changes
git diff HEAD              # All uncommitted changes
git diff branch1..branch2  # Between branches
git diff commit1..commit2  # Between commits
git diff HEAD~3..HEAD      # Last 3 commits
git diff --stat            # Summary only
git diff --name-only       # File names only

# Log
git log
git log --oneline          # Compact
git log --oneline -10      # Last 10 commits
git log --graph            # ASCII graph
git log --all              # All branches
git log --oneline --graph --all  # Combined
git log -p                 # With diffs
git log --stat             # With file stats
git log --author="Name"    # By author
git log --since="2024-01-01"
git log --until="2024-12-31"
git log --grep="bug"       # Search commit messages
git log -- file.txt        # History of specific file
git log -S "searchterm"    # Commits changing string
git log branch1..branch2   # Commits in branch2 not in branch1

# Show specific commit
git show abc123
git show HEAD
git show HEAD~2            # 2 commits ago
git show HEAD:file.txt     # File at commit

# Blame (who changed what)
git blame file.txt
git blame -L 10,20 file.txt  # Lines 10-20
```

## Branches

### Basic Operations

```bash
# List branches
git branch                 # Local
git branch -r              # Remote
git branch -a              # All
git branch -v              # With last commit
git branch --merged        # Merged into current
git branch --no-merged     # Not merged

# Create branch
git branch feature         # Create only
git checkout -b feature    # Create and switch
git switch -c feature      # Git 2.23+

# Switch branches
git checkout main
git switch main            # Git 2.23+

# Rename branch
git branch -m old-name new-name
git branch -m new-name     # Rename current

# Delete branch
git branch -d feature      # Safe delete (must be merged)
git branch -D feature      # Force delete

# Set upstream
git branch -u origin/main
git branch --set-upstream-to=origin/main
```

### Merging

```bash
# Merge branch into current
git merge feature

# Merge with commit message
git merge feature -m "Merge feature branch"

# Merge without fast-forward (always create commit)
git merge --no-ff feature

# Squash merge (combine all commits)
git merge --squash feature
git commit -m "Squashed feature"

# Abort merge
git merge --abort
```

### Rebasing

```bash
# Rebase current branch onto main
git rebase main

# Interactive rebase (edit, squash, reorder commits)
git rebase -i HEAD~5       # Last 5 commits
git rebase -i main         # Since branching from main

# Continue/abort rebase
git rebase --continue
git rebase --abort
git rebase --skip          # Skip current commit

# Rebase options in interactive mode:
# pick   = use commit
# reword = use commit, edit message
# edit   = use commit, stop for amending
# squash = meld into previous commit
# fixup  = like squash, discard message
# drop   = remove commit
```

### Cherry-pick

```bash
# Apply specific commit to current branch
git cherry-pick abc123
git cherry-pick abc123 def456  # Multiple
git cherry-pick abc123..def456 # Range
git cherry-pick --no-commit abc123  # Stage only

# Abort/continue
git cherry-pick --abort
git cherry-pick --continue
```

## Remote Repositories

### Managing Remotes

```bash
# List remotes
git remote
git remote -v              # With URLs

# Add remote
git remote add origin https://github.com/user/repo.git
git remote add upstream https://github.com/original/repo.git

# Remove remote
git remote remove origin

# Rename remote
git remote rename origin upstream

# Change URL
git remote set-url origin https://new-url.git

# Show remote info
git remote show origin
```

### Fetching & Pulling

```bash
# Fetch (download without merging)
git fetch                  # From default remote
git fetch origin           # From specific remote
git fetch --all            # From all remotes
git fetch --prune          # Remove deleted remote branches

# Pull (fetch + merge)
git pull
git pull origin main
git pull --rebase          # Fetch + rebase instead of merge
git pull --rebase origin main
```

### Pushing

```bash
# Push
git push
git push origin main
git push -u origin main    # Set upstream and push
git push --all             # All branches
git push --tags            # All tags

# Force push (use with caution!)
git push --force           # Overwrite remote
git push --force-with-lease  # Safer: fails if remote changed

# Delete remote branch
git push origin --delete feature
git push origin :feature   # Older syntax
```

## Stashing

```bash
# Stash changes
git stash                  # Stash tracked files
git stash -u               # Include untracked
git stash -a               # Include ignored
git stash push -m "message"
git stash push file.txt    # Specific file

# List stashes
git stash list

# Apply stash
git stash apply            # Most recent, keep in stash
git stash apply stash@{2}  # Specific stash
git stash pop              # Apply and remove
git stash pop stash@{2}

# View stash contents
git stash show             # Summary
git stash show -p          # Full diff
git stash show stash@{1}

# Delete stash
git stash drop             # Most recent
git stash drop stash@{2}   # Specific
git stash clear            # All stashes

# Create branch from stash
git stash branch new-branch stash@{0}
```

## Undoing Changes

### Uncommitted Changes

```bash
# Discard changes in working directory
git checkout -- file.txt   # Old way
git restore file.txt       # Git 2.23+
git restore .              # All files

# Unstage files
git reset HEAD file.txt    # Old way
git restore --staged file.txt  # Git 2.23+

# Discard all uncommitted changes
git reset --hard HEAD
git checkout .
```

### Committed Changes

```bash
# Undo last commit, keep changes staged
git reset --soft HEAD~1

# Undo last commit, keep changes unstaged
git reset HEAD~1
git reset --mixed HEAD~1   # Same

# Undo last commit, discard changes
git reset --hard HEAD~1

# Undo specific commit (creates new commit)
git revert abc123
git revert HEAD            # Revert last commit
git revert HEAD~3..HEAD    # Revert range

# Undo merge commit
git revert -m 1 merge-commit-hash
```

### Recovering

```bash
# Find lost commits
git reflog
git reflog show feature    # Specific branch

# Recover deleted branch
git checkout -b recovered abc123  # Use hash from reflog

# Recover deleted commit
git cherry-pick abc123     # From reflog
```

## Tags

```bash
# List tags
git tag
git tag -l "v1.*"          # Pattern match

# Create tag
git tag v1.0.0             # Lightweight
git tag -a v1.0.0 -m "Release v1.0.0"  # Annotated
git tag -a v1.0.0 abc123   # Tag specific commit

# Show tag
git show v1.0.0

# Push tags
git push origin v1.0.0     # Single tag
git push origin --tags     # All tags

# Delete tag
git tag -d v1.0.0          # Local
git push origin --delete v1.0.0  # Remote

# Checkout tag
git checkout v1.0.0        # Detached HEAD
git checkout -b release-1.0 v1.0.0  # New branch
```

## Advanced Operations

### Worktrees

```bash
# Add worktree (work on multiple branches simultaneously)
git worktree add ../project-feature feature
git worktree add -b new-branch ../project-new main

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../project-feature
git worktree prune         # Clean up stale worktrees
```

### Bisect (Find Bug-Introducing Commit)

```bash
git bisect start
git bisect bad             # Current commit is bad
git bisect good v1.0.0     # Known good commit
# Git checks out middle commit, test it, then:
git bisect good            # or
git bisect bad
# Repeat until found
git bisect reset           # Return to original state

# Automated bisect
git bisect start HEAD v1.0.0
git bisect run ./test.sh   # Script returns 0=good, 1=bad
```

### Submodules

```bash
# Add submodule
git submodule add https://github.com/user/lib.git libs/lib

# Clone repo with submodules
git clone --recurse-submodules https://...
# Or after cloning:
git submodule update --init --recursive

# Update submodules
git submodule update --remote

# Remove submodule
git submodule deinit libs/lib
git rm libs/lib
rm -rf .git/modules/libs/lib
```

### Clean

```bash
# Remove untracked files
git clean -n               # Dry run (show what would be deleted)
git clean -f               # Force delete
git clean -fd              # Include directories
git clean -fx              # Include ignored files
git clean -fdx             # Everything untracked
```

## Useful Aliases

Add to `~/.gitconfig`:

```ini
[alias]
    # Status
    st = status -s

    # Logging
    lg = log --oneline --graph --all --decorate
    ll = log --oneline -15
    last = log -1 HEAD --stat

    # Branches
    br = branch
    co = checkout
    sw = switch

    # Commits
    ci = commit
    ca = commit --amend
    can = commit --amend --no-edit

    # Diff
    df = diff
    dfs = diff --staged

    # Undo
    unstage = reset HEAD --
    undo = reset --soft HEAD~1

    # Stash
    sl = stash list
    sp = stash pop
    ss = stash push -m

    # Find
    find = log --all --full-history --
    search = log -S

    # Aliases
    aliases = config --get-regexp alias
```

## Common Workflows

### Feature Branch

```bash
git checkout main
git pull
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "Add feature"
git push -u origin feature/my-feature
# Create PR, after merge:
git checkout main
git pull
git branch -d feature/my-feature
```

### Sync Fork with Upstream

```bash
git remote add upstream https://github.com/original/repo.git
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

### Squash Commits Before PR

```bash
git rebase -i main
# Mark commits as 'squash' or 'fixup'
# Edit combined commit message
git push --force-with-lease
```

### Fix Detached HEAD

```bash
# If you made commits in detached HEAD:
git branch temp-branch     # Save commits
git checkout main
git merge temp-branch
git branch -d temp-branch
```

## Quick Reference

| Task             | Command                   |
| ---------------- | ------------------------- |
| Initialize repo  | `git init`                |
| Clone repo       | `git clone <url>`         |
| Check status     | `git status`              |
| Stage all        | `git add .`               |
| Commit           | `git commit -m "msg"`     |
| Push             | `git push`                |
| Pull             | `git pull`                |
| Create branch    | `git checkout -b name`    |
| Switch branch    | `git checkout name`       |
| Merge branch     | `git merge name`          |
| View log         | `git log --oneline`       |
| View diff        | `git diff`                |
| Stash changes    | `git stash`               |
| Apply stash      | `git stash pop`           |
| Undo last commit | `git reset --soft HEAD~1` |
| Discard changes  | `git restore file`        |
