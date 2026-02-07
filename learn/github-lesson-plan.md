# GitHub Lesson Plan

A progressive curriculum to master GitHub through hands-on practice.

## Lesson 1: Repository Basics

**Goal:** Create and configure repositories.

### Concepts

GitHub hosts git repositories and adds collaboration features: issues, pull
requests, actions, and more.

### Exercises

1. **Create a repository**

   ```bash
   # On github.com: New repository
   # Or with gh CLI:
   gh repo create my-project --public --clone
   cd my-project
   ```

2. **Clone and configure**

   ```bash
   git clone https://github.com/you/repo.git
   cd repo

   # Or with SSH (recommended)
   git clone git@github.com:you/repo.git

   # Set up gh CLI
   gh auth login
   gh auth status
   ```

3. **Repository settings**

   ```bash
   # View repo info
   gh repo view

   # Edit settings
   gh repo edit --description "My awesome project"
   gh repo edit --visibility private
   gh repo edit --enable-issues=false
   ```

4. **Add essential files**

   ```bash
   # README.md - project overview
   # LICENSE - usage terms (MIT, Apache, etc.)
   # .gitignore - files to exclude
   # CONTRIBUTING.md - how to contribute

   gh repo view --web  # Open in browser
   ```

### Checkpoint

Create a repo with README, LICENSE, and .gitignore. Clone it locally.

---

## Lesson 2: Issues

**Goal:** Track work with issues.

### Concepts

Issues track bugs, features, and tasks. They're the unit of work on GitHub.

### Exercises

1. **Create issues**

   ```bash
   # Create issue
   gh issue create --title "Add user authentication" \
     --body "Implement login/logout functionality"

   # With labels
   gh issue create --title "Fix navbar bug" \
     --label "bug" --label "priority:high"

   # Assign to yourself
   gh issue create --title "Update docs" --assignee @me
   ```

2. **List and view issues**

   ```bash
   gh issue list
   gh issue list --state open
   gh issue list --label "bug"
   gh issue list --assignee @me

   gh issue view 123
   gh issue view 123 --web  # Open in browser
   ```

3. **Update issues**

   ```bash
   # Add comment
   gh issue comment 123 --body "Working on this now"

   # Close issue
   gh issue close 123

   # Reopen
   gh issue reopen 123

   # Edit
   gh issue edit 123 --add-label "in-progress"
   gh issue edit 123 --add-assignee @me
   ```

4. **Link issues to code**

   ```bash
   # Reference in commit message
   git commit -m "Add login form (refs #123)"

   # Close via commit
   git commit -m "Implement auth (fixes #123)"

   # Keywords: fixes, closes, resolves
   ```

### Checkpoint

Create 3 issues with different labels. Close one via a commit message.

---

## Lesson 3: Pull Requests

**Goal:** Propose and review changes.

### Concepts

Pull requests (PRs) propose merging one branch into another. They enable code
review, discussion, and CI checks before merging.

### Exercises

1. **Create a PR**

   ```bash
   # Create branch and make changes
   git switch -c feature/add-search
   # ... make changes ...
   git add . && git commit -m "Add search functionality"
   git push -u origin feature/add-search

   # Create PR
   gh pr create --title "Add search" \
     --body "Implements search feature. Fixes #45"

   # Or interactively
   gh pr create --fill  # Uses commit messages
   ```

2. **List and view PRs**

   ```bash
   gh pr list
   gh pr list --state all
   gh pr list --author @me

   gh pr view 42
   gh pr view 42 --web
   gh pr diff 42
   ```

3. **Review PRs**

   ```bash
   # Check out PR locally
   gh pr checkout 42

   # Add review
   gh pr review 42 --approve
   gh pr review 42 --request-changes --body "Please fix X"
   gh pr review 42 --comment --body "Looks good overall"

   # Comment on specific line
   gh pr comment 42 --body "Consider using Y here"
   ```

4. **Merge and cleanup**

   ```bash
   # Merge PR
   gh pr merge 42
   gh pr merge 42 --squash   # Squash commits
   gh pr merge 42 --rebase   # Rebase commits
   gh pr merge 42 --delete-branch  # Delete after merge

   # Close without merging
   gh pr close 42
   ```

### Checkpoint

Create a feature branch, open a PR, and merge it with squash.

---

## Lesson 4: GitHub Actions Basics

**Goal:** Automate workflows with CI/CD.

### Concepts

Actions run automated workflows triggered by events (push, PR, schedule).
Workflows are YAML files in `.github/workflows/`.

### Exercises

1. **Create a basic workflow**

   ```yaml
   # .github/workflows/ci.yml
   name: CI

   on:
     push:
       branches: [main]
     pull_request:

   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4

         - name: Run tests
           run: npm test
   ```

2. **View workflow runs**

   ```bash
   gh run list
   gh run view 12345
   gh run view 12345 --log
   gh run watch  # Live view of in-progress run
   ```

3. **Trigger and manage runs**

   ```bash
   # Re-run failed jobs
   gh run rerun 12345

   # Cancel run
   gh run cancel 12345

   # Download artifacts
   gh run download 12345
   ```

4. **Common patterns**

   ```yaml
   # Matrix builds
   jobs:
     test:
       strategy:
         matrix:
           node: [18, 20, 22]
           os: [ubuntu-latest, macos-latest]
       runs-on: ${{ matrix.os }}
       steps:
         - uses: actions/setup-node@v4
           with:
             node-version: ${{ matrix.node }}

   # Conditional steps
   - name: Deploy
     if: github.ref == 'refs/heads/main'
     run: ./deploy.sh
   ```

### Checkpoint

Create a workflow that runs tests on every PR and push to main.

---

## Lesson 5: Advanced Actions

**Goal:** Build sophisticated CI/CD pipelines.

### Exercises

1. **Caching dependencies**

   ```yaml
   - uses: actions/cache@v4
     with:
       path: ~/.npm
       key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
       restore-keys: |
         ${{ runner.os }}-node-
   ```

2. **Secrets and environment variables**

   ```yaml
   jobs:
     deploy:
       runs-on: ubuntu-latest
       env:
         NODE_ENV: production
       steps:
         - name: Deploy
           env:
             API_KEY: ${{ secrets.API_KEY }}
           run: ./deploy.sh
   ```

   ```bash
   # Manage secrets
   gh secret set API_KEY
   gh secret list
   ```

3. **Job dependencies**

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - run: npm run build

     test:
       needs: build
       runs-on: ubuntu-latest
       steps:
         - run: npm test

     deploy:
       needs: [build, test]
       if: github.ref == 'refs/heads/main'
       runs-on: ubuntu-latest
       steps:
         - run: ./deploy.sh
   ```

4. **Reusable workflows**

   ```yaml
   # .github/workflows/reusable.yml
   on:
     workflow_call:
       inputs:
         environment:
           required: true
           type: string

   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - run: echo "Deploying to ${{ inputs.environment }}"

   # Calling workflow
   jobs:
     call-deploy:
       uses: ./.github/workflows/reusable.yml
       with:
         environment: production
   ```

### Checkpoint

Create a workflow with build, test, and deploy jobs. Add caching for
dependencies.

---

## Lesson 6: Collaboration Features

**Goal:** Use GitHub's collaboration tools effectively.

### Exercises

1. **Code owners**

   ```text
   # .github/CODEOWNERS
   # Default owners
   * @team-leads

   # Specific paths
   /docs/ @docs-team
   *.js @frontend-team
   /api/ @backend-team @security-team
   ```

2. **Branch protection**

   ```bash
   # Via gh CLI (limited)
   gh api repos/{owner}/{repo}/branches/main/protection \
     --method PUT \
     --field required_status_checks='{"strict":true,"contexts":["test"]}' \
     --field enforce_admins=true \
     --field required_pull_request_reviews='{"required_approving_review_count":1}'
   ```

   Key settings:
   - Require PR reviews before merging
   - Require status checks to pass
   - Require branches to be up to date
   - Include administrators

3. **Templates**

   ```markdown
   ## <!-- .github/ISSUE_TEMPLATE/bug_report.md -->

   name: Bug Report about: Report a bug labels: bug

   ---

   ## Description

   ## Steps to Reproduce

   1.
   2.
   3.

   ## Expected Behavior

   ## Actual Behavior
   ```

   ```markdown
   <!-- .github/PULL_REQUEST_TEMPLATE.md -->

   ## Summary

   ## Changes

   ## Testing

   ## Checklist

   - [ ] Tests added
   - [ ] Documentation updated
   ```

4. **Discussions and wikis**

   ```bash
   # Enable discussions
   gh repo edit --enable-discussions

   # Discussions are for:
   # - Q&A
   # - Ideas and feature requests
   # - Show and tell
   # - General conversation
   ```

### Checkpoint

Add CODEOWNERS, issue template, and PR template to a repository.

---

## Lesson 7: Releases and Packages

**Goal:** Publish releases and packages.

### Exercises

1. **Create releases**

   ```bash
   # Create a tag
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0

   # Create release from tag
   gh release create v1.0.0 --title "v1.0.0" \
     --notes "First stable release"

   # With auto-generated notes
   gh release create v1.1.0 --generate-notes

   # Upload assets
   gh release create v1.0.0 ./dist/app.zip ./dist/app.tar.gz
   ```

2. **List and manage releases**

   ```bash
   gh release list
   gh release view v1.0.0
   gh release download v1.0.0

   # Edit release
   gh release edit v1.0.0 --draft=false

   # Delete release
   gh release delete v1.0.0
   ```

3. **Automate releases**

   ```yaml
   # .github/workflows/release.yml
   on:
     push:
       tags:
         - "v*"

   jobs:
     release:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4

         - name: Build
           run: npm run build

         - name: Create Release
           uses: softprops/action-gh-release@v1
           with:
             files: dist/*
             generate_release_notes: true
   ```

4. **GitHub Packages**

   ```yaml
   # Publish npm package
   - uses: actions/setup-node@v4
     with:
       registry-url: "https://npm.pkg.github.com"

   - run: npm publish
     env:
       NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

### Checkpoint

Create a release with auto-generated notes and uploaded assets.

---

## Lesson 8: GitHub API and Automation

**Goal:** Automate GitHub with the API.

### Exercises

1. **Using gh api**

   ```bash
   # Get repo info
   gh api repos/{owner}/{repo}

   # List PRs
   gh api repos/{owner}/{repo}/pulls

   # Create issue
   gh api repos/{owner}/{repo}/issues \
     --method POST \
     --field title="New issue" \
     --field body="Description"

   # GraphQL
   gh api graphql -f query='
     query {
       viewer {
         login
         repositories(first: 10) {
           nodes { name }
         }
       }
     }
   '
   ```

2. **Webhooks**

   ```bash
   # List webhooks
   gh api repos/{owner}/{repo}/hooks

   # Create webhook
   gh api repos/{owner}/{repo}/hooks \
     --method POST \
     --field name="web" \
     --field config='{"url":"https://example.com/webhook","content_type":"json"}' \
     --field events='["push","pull_request"]'
   ```

3. **GitHub Apps and tokens**

   ```yaml
   # Using GITHUB_TOKEN in Actions
   - name: Create issue
     uses: actions/github-script@v7
     with:
       script: |
         await github.rest.issues.create({
           owner: context.repo.owner,
           repo: context.repo.repo,
           title: 'Automated issue',
           body: 'Created by workflow'
         })
   ```

4. **Automation scripts**

   ```bash
   #!/bin/bash
   # Close stale issues

   gh issue list --label "stale" --json number --jq '.[].number' | \
     while read -r num; do
       gh issue close "$num" --comment "Closing stale issue"
     done
   ```

   ```bash
   # Bulk label PRs
   gh pr list --json number --jq '.[].number' | \
     while read -r num; do
       gh pr edit "$num" --add-label "needs-review"
     done
   ```

### Checkpoint

Write a script that lists all open PRs older than 7 days and adds a "stale"
label.

---

## Practice Projects

### Project 1: Open Source Ready

Prepare a repository for open source:

- README with badges
- Contributing guidelines
- Issue and PR templates
- CI workflow with tests and linting
- Branch protection rules

### Project 2: Release Automation

Set up automated releases:

- Semantic versioning
- Changelog generation
- Build artifacts
- Publish to GitHub Packages

### Project 3: Team Workflow

Configure a team repository:

- CODEOWNERS for different areas
- Required reviewers
- Status checks
- Automated labeling

---

## Command Reference

| Task           | Command                    |
| -------------- | -------------------------- |
| Create repo    | `gh repo create`           |
| Clone repo     | `gh repo clone owner/repo` |
| Create issue   | `gh issue create`          |
| Create PR      | `gh pr create`             |
| Merge PR       | `gh pr merge`              |
| View runs      | `gh run list`              |
| Create release | `gh release create`        |
| API call       | `gh api <endpoint>`        |

## See Also

- [Git Lesson Plan](git-lesson-plan.md) — Git fundamentals
- [Git Cheatsheet](../how/git.md) — Quick command reference
