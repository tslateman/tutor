# Git Lesson Plan

A progressive curriculum to master git through hands-on practice.

## Lesson 1: First Commit

**Goal:** Understand the basic commit workflow.

### Concepts

Git tracks changes to files. The workflow is:

1. Make changes to files
2. Stage changes (select what to commit)
3. Commit (save a snapshot with a message)

### Exercises

1. **Initialize a repository**

   ```bash
   mkdir learn-git && cd learn-git
   git init
   git status          # See the empty repo
   ```

2. **Create and stage a file**

   ```bash
   echo "# My Project" > README.md
   git status          # Untracked file
   git add README.md
   git status          # Staged for commit
   ```

3. **Make your first commit**

   ```bash
   git commit -m "Add README"
   git log             # See your commit
   ```

4. **Modify and commit again**

   ```bash
   echo "This is a demo." >> README.md
   git diff            # See changes
   git add README.md
   git commit -m "Add description to README"
   git log --oneline   # Compact history
   ```

### Checkpoint

You can init, add, commit, and view history. Run `git log --oneline` and see 2
commits.

---

## Lesson 2: Branching

**Goal:** Work on features without affecting main.

### Concepts

Branches are independent lines of development. `main` is the default branch.
Create branches for features, merge when done.

```text
main:    A---B---C
              \
feature:       D---E
```

### Exercises

1. **Create and switch branches**

   ```bash
   git branch              # List branches
   git branch feature      # Create branch
   git switch feature      # Switch to it
   # Or combined:
   git switch -c feature2  # Create and switch
   ```

2. **Make commits on a branch**

   ```bash
   git switch -c add-license
   echo "MIT License" > LICENSE
   git add LICENSE
   git commit -m "Add MIT license"
   git log --oneline       # See commit on branch
   ```

3. **Compare branches**

   ```bash
   git switch main
   ls                      # No LICENSE file
   git log --oneline --all --graph  # Visualize branches
   ```

4. **Delete a branch**

   ```bash
   git branch -d add-license  # Fails: not merged
   git branch -D add-license  # Force delete
   ```

### Checkpoint

Create a branch, commit to it, switch back to main. The commit only exists on
your branch.

---

## Lesson 3: Merging

**Goal:** Combine branch work back into main.

### Concepts

Merge brings changes from one branch into another. Fast-forward merges move the
pointer. Three-way merges create a merge commit.

### Exercises

1. **Fast-forward merge**

   ```bash
   git switch -c docs
   echo "## Usage" >> README.md
   git add README.md
   git commit -m "Add usage section"

   git switch main
   git merge docs          # Fast-forward
   git log --oneline       # Linear history
   ```

2. **Three-way merge**

   ```bash
   # Create diverging branches
   git switch -c feature-a
   echo "Feature A" > a.txt
   git add a.txt && git commit -m "Add feature A"

   git switch main
   git switch -c feature-b
   echo "Feature B" > b.txt
   git add b.txt && git commit -m "Add feature B"

   git switch main
   git merge feature-a     # Fast-forward
   git merge feature-b     # Creates merge commit
   git log --oneline --graph
   ```

3. **Handle a merge conflict**

   ```bash
   git switch -c conflict-demo
   echo "Line from branch" >> README.md
   git add README.md && git commit -m "Branch change"

   git switch main
   echo "Line from main" >> README.md
   git add README.md && git commit -m "Main change"

   git merge conflict-demo
   # CONFLICT! Edit README.md to resolve
   # Remove <<<<<<<, =======, >>>>>>> markers
   git add README.md
   git commit -m "Resolve merge conflict"
   ```

### Checkpoint

Merge two branches. Resolve at least one conflict manually.

---

## Lesson 4: Remote Repositories

**Goal:** Push and pull from GitHub/GitLab.

### Concepts

Remotes are copies of your repo on a server. `origin` is the conventional name
for your primary remote. Push sends commits; pull fetches and merges.

### Exercises

1. **Clone an existing repo**

   ```bash
   git clone https://github.com/octocat/Hello-World.git
   cd Hello-World
   git remote -v           # See origin
   ```

2. **Add a remote to existing repo**

   ```bash
   cd ~/learn-git
   # Create a repo on GitHub first, then:
   git remote add origin git@github.com:YOU/learn-git.git
   git remote -v
   ```

3. **Push your work**

   ```bash
   git push -u origin main  # -u sets upstream
   git push                 # Future pushes are simple
   ```

4. **Pull changes**

   ```bash
   # After someone else pushes:
   git fetch                # Download without merging
   git status               # See "behind by N commits"
   git pull                 # Fetch and merge
   ```

5. **Track remote branches**

   ```bash
   git branch -r            # List remote branches
   git switch -c feature origin/feature  # Track remote
   ```

### Checkpoint

Clone a repo. Push a new branch. Pull changes from origin.

---

## Lesson 5: Rewriting History

**Goal:** Clean up commits before sharing.

### Concepts

Local commits can be modified. Published commits should not be rewritten (breaks
collaborators). Use rebase and amend for unpushed work.

### Exercises

1. **Amend the last commit**

   ```bash
   # Forgot a file:
   git add forgotten-file.txt
   git commit --amend --no-edit

   # Fix the message:
   git commit --amend -m "Better message"
   ```

2. **Interactive rebase**

   ```bash
   # Reword, squash, or reorder last 3 commits
   git rebase -i HEAD~3

   # In editor:
   # pick   abc123 First commit
   # squash def456 Fixup commit     <- squash into previous
   # reword ghi789 Bad message      <- edit this message
   ```

3. **Rebase onto main**

   ```bash
   git switch feature
   git rebase main          # Replay feature on top of main
   # Resolve conflicts if needed
   git rebase --continue
   ```

4. **Abort a rebase**

   ```bash
   # If it goes wrong:
   git rebase --abort
   ```

### Checkpoint

Squash 3 commits into 1. Rebase a feature branch onto updated main.

---

## Lesson 6: Undoing Things

**Goal:** Recover from mistakes.

### Concepts

| Situation               | Command                     |
| ----------------------- | --------------------------- |
| Unstage a file          | `git restore --staged file` |
| Discard local changes   | `git restore file`          |
| Undo last commit (keep) | `git reset --soft HEAD~1`   |
| Undo last commit (lose) | `git reset --hard HEAD~1`   |
| Revert a pushed commit  | `git revert <sha>`          |
| Find lost commits       | `git reflog`                |

### Exercises

1. **Unstage and restore**

   ```bash
   echo "mistake" >> README.md
   git add README.md
   git restore --staged README.md   # Unstage
   git restore README.md            # Discard changes
   ```

2. **Reset commits**

   ```bash
   # Make a bad commit
   echo "oops" > oops.txt
   git add oops.txt && git commit -m "Oops"

   git reset --soft HEAD~1   # Undo commit, keep staged
   git status                # oops.txt still staged
   git reset HEAD oops.txt   # Unstage
   rm oops.txt
   ```

3. **Revert a pushed commit**

   ```bash
   git revert HEAD           # Creates a new commit undoing HEAD
   git log --oneline         # See revert commit
   ```

4. **Recover with reflog**

   ```bash
   git reflog                # History of HEAD movements
   git reset --hard abc123   # Go back to any state
   ```

### Checkpoint

Accidentally reset --hard, then recover using reflog.

---

## Lesson 7: Stash and Cherry-Pick

**Goal:** Flexible workflows for real situations.

### Exercises

1. **Stash work in progress**

   ```bash
   # Working on something, need to switch branches
   echo "wip" >> README.md
   git stash                 # Save and clean
   git switch other-branch
   # Do work...
   git switch main
   git stash pop             # Restore WIP
   ```

2. **Manage multiple stashes**

   ```bash
   git stash list
   git stash save "description"
   git stash apply stash@{1}   # Apply without removing
   git stash drop stash@{0}    # Remove from list
   ```

3. **Cherry-pick a commit**

   ```bash
   # Grab one commit from another branch
   git log other-branch --oneline
   git cherry-pick abc123
   ```

4. **Find bug with bisect**

   ```bash
   git bisect start
   git bisect bad              # Current is broken
   git bisect good v1.0        # This version worked
   # Git checks out middle commit
   # Test it, then:
   git bisect good   # or bad
   # Repeat until git finds the culprit
   git bisect reset
   ```

### Checkpoint

Stash changes, switch branches, pop the stash. Cherry-pick one commit.

---

## Lesson 8: Workflows

**Goal:** Understand team collaboration patterns.

### Concepts

| Workflow       | Description                                   |
| -------------- | --------------------------------------------- |
| Feature branch | Branch per feature, merge to main             |
| GitHub Flow    | Branch, PR, review, merge                     |
| Trunk-based    | Short-lived branches, frequent integration    |
| Gitflow        | develop/release/hotfix branches (heavyweight) |

### Exercises

1. **Feature branch workflow**

   ```bash
   git switch -c feature/add-search
   # Work...
   git push -u origin feature/add-search
   # Open PR on GitHub
   # After review, merge and delete branch
   ```

2. **Keep branch updated**

   ```bash
   git switch feature/add-search
   git fetch origin
   git rebase origin/main    # Or merge
   git push --force-with-lease  # Safe force push
   ```

3. **Clean up merged branches**

   ```bash
   git branch --merged main | grep -v main | xargs git branch -d
   git fetch --prune         # Remove stale remote refs
   ```

### Checkpoint

Complete a full cycle: branch → commits → push → PR → merge → delete branch.

---

## Practice Projects

### Project 1: Solo Workflow

Create a repo. Make 10 commits across 3 branches. Practice rebasing one branch
onto another. Squash related commits. Push to GitHub.

### Project 2: Collaboration Simulation

Clone your own repo to a second directory (simulating a collaborator). Make
conflicting changes in both. Push from one, pull and resolve in the other.

### Project 3: Archaeology

Clone a large open-source project. Use `git log`, `git blame`, and `git bisect`
to understand how a feature was implemented.

---

## Command Reference

| Stage     | Must Know                                   |
| --------- | ------------------------------------------- |
| Beginner  | `init` `add` `commit` `status` `log` `diff` |
| Branching | `branch` `switch` `merge` `rebase`          |
| Remote    | `clone` `remote` `push` `pull` `fetch`      |
| Undoing   | `restore` `reset` `revert` `reflog`         |
| Power     | `stash` `cherry-pick` `bisect` `rebase -i`  |

## See Also

- [Git Cheatsheet](../how/git.md) — Quick command reference
- [Problem Solving](../why/problem-solving.md) — Debugging git issues
