# CI/CD Cheat Sheet

Pipeline patterns, caching, matrix builds, and deployment strategies for GitHub
Actions.

## Workflow File Structure

Workflows live in `.github/workflows/*.yml` and run on GitHub-hosted or
self-hosted runners.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test
```

### Trigger Events

```yaml
on:
  push:
    branches: [main, release/*]
    tags: ["v*"]
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  schedule:
    - cron: "0 6 * * 1" # Every Monday at 6am UTC
  workflow_dispatch: # Manual trigger
    inputs:
      environment:
        description: "Deploy target"
        required: true
        default: "staging"
        type: choice
        options: [staging, production]
  workflow_run:
    workflows: ["Build"]
    types: [completed]
  release:
    types: [published]
```

### Path Filters (Monorepo)

```yaml
on:
  push:
    paths:
      - "packages/api/**"
      - "shared/**"
    paths-ignore:
      - "docs/**"
      - "*.md"
```

### Environment Variables and Secrets

```yaml
env:
  NODE_ENV: production # Workflow-level

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      REGION: us-east-1 # Job-level
    steps:
      - name: Deploy
        env:
          API_KEY: ${{ secrets.API_KEY }} # Step-level
        run: ./deploy.sh
      - name: Use GitHub context
        run: |
          echo "Repo: ${{ github.repository }}"
          echo "SHA: ${{ github.sha }}"
          echo "Ref: ${{ github.ref_name }}"
          echo "Actor: ${{ github.actor }}"
```

## Caching

### actions/cache Basics

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: npm-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      npm-${{ runner.os }}-
```

**How keys work:** exact match on `key` first, then prefix match through
`restore-keys` in order. Cache saves only on exact-key miss.

### Language-Specific Patterns

```yaml
# Node.js (npm)
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: npm-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}

# Node.js (pnpm)
- uses: actions/cache@v4
  with:
    path: ~/.pnpm-store
    key: pnpm-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}

# Python (pip)
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: pip-${{ runner.os }}-${{ hashFiles('**/requirements*.txt') }}

# Python (uv)
- uses: actions/cache@v4
  with:
    path: ~/.cache/uv
    key: uv-${{ runner.os }}-${{ hashFiles('**/uv.lock') }}

# Go modules
- uses: actions/cache@v4
  with:
    path: |
      ~/go/pkg/mod
      ~/.cache/go-build
    key: go-${{ runner.os }}-${{ hashFiles('**/go.sum') }}

# Rust (cargo)
- uses: actions/cache@v4
  with:
    path: |
      ~/.cargo/bin
      ~/.cargo/registry/index
      ~/.cargo/registry/cache
      ~/.cargo/git/db
      target
    key: cargo-${{ runner.os }}-${{ hashFiles('**/Cargo.lock') }}
```

### Setup Actions with Built-in Caching

Many setup actions handle caching internally — prefer these over manual cache
steps.

```yaml
# Node.js
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: npm # or pnpm, yarn

# Python
- uses: actions/setup-python@v5
  with:
    python-version: "3.12"
    cache: pip # or poetry, pipenv

# Go
- uses: actions/setup-go@v5
  with:
    go-version: "1.22"
    cache: true # Caches go-build and go modules
```

### When Caching Hurts

| Problem            | Symptom                           | Fix                                       |
| ------------------ | --------------------------------- | ----------------------------------------- |
| Stale dependencies | Tests pass in CI, fail locally    | Key on lock file hash, not branch         |
| Cache poisoning    | Corrupted cache breaks all runs   | Delete cache via API or change key prefix |
| Bloated cache      | Restore slower than fresh install | Narrow `path`, cache only expensive parts |
| Cache thrashing    | Key changes every commit          | Use stable hash inputs (lock files only)  |

```bash
# Delete a cache via CLI
gh cache delete --all
gh cache list
```

## Matrix Builds

### Basic Matrix

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        node-version: [18, 20, 22]
      fail-fast: false # Don't cancel siblings on failure
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm test
```

### Include / Exclude

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
    node-version: [18, 20]
    include:
      - os: ubuntu-latest # Add a combo with extra var
        node-version: 22
        experimental: true
    exclude:
      - os: macos-latest # Remove a specific combo
        node-version: 18
```

### Dynamic Matrix

```yaml
jobs:
  generate:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: echo 'matrix=["api","web","worker"]' >> "$GITHUB_OUTPUT"

  build:
    needs: generate
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJson(needs.generate.outputs.matrix) }}
    steps:
      - run: echo "Building ${{ matrix.service }}"
```

## Reusable Workflows and Composite Actions

### Reusable Workflow (workflow_call)

Define in `.github/workflows/reusable-test.yml`:

```yaml
name: Reusable Test

on:
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: "20"
    secrets:
      npm-token:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
        env:
          NPM_TOKEN: ${{ secrets.npm-token }}
      - run: npm test
```

Call from another workflow:

```yaml
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: "22"
    secrets:
      npm-token: ${{ secrets.NPM_TOKEN }}
```

### Composite Action

Define in `.github/actions/setup-project/action.yml`:

```yaml
name: Setup Project
description: Install deps and build

inputs:
  node-version:
    description: Node.js version
    default: "20"

runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: npm
    - run: npm ci
      shell: bash
    - run: npm run build
      shell: bash
```

Use it:

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ./.github/actions/setup-project
    with:
      node-version: "22"
```

### When to Use Each

| Feature         | Reusable Workflow            | Composite Action            |
| --------------- | ---------------------------- | --------------------------- |
| Scope           | Full job(s) with runners     | Steps within a job          |
| Defined in      | `.github/workflows/`         | `action.yml` anywhere       |
| Can define jobs | Yes                          | No (steps only)             |
| Can use secrets | Yes (explicit passing)       | Yes (via inputs)            |
| Can use `if:`   | Yes (job and step level)     | Yes (step level)            |
| Best for        | Standardized CI across repos | Shared setup/teardown logic |

## Deployment Strategies

### Blue-Green

Two identical environments. Switch traffic after validation.

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to green
        run: ./deploy.sh --target green
      - name: Smoke test green
        run: ./smoke-test.sh --target green
      - name: Switch traffic to green
        run: ./switch-traffic.sh --from blue --to green
      - name: Keep blue as rollback
        run: echo "Blue available for instant rollback"
```

### Canary Release

Route a small percentage of traffic to the new version, then increase gradually.

```yaml
jobs:
  canary:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy canary (5% traffic)
        run: ./deploy.sh --canary --weight 5
      - name: Monitor error rate (10 min)
        run: ./monitor.sh --duration 600 --threshold 0.01
      - name: Promote to 50%
        run: ./deploy.sh --canary --weight 50
      - name: Monitor again
        run: ./monitor.sh --duration 600 --threshold 0.01
      - name: Full rollout
        run: ./deploy.sh --promote
```

### Environment Protection Rules

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: ./deploy.sh staging

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.com
    steps:
      - run: ./deploy.sh production
```

Configure in GitHub repo settings: required reviewers, wait timers, branch
restrictions.

### Rollback Pattern

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Save current version
        run: |
          CURRENT=$(./get-current-version.sh)
          echo "rollback_version=$CURRENT" >> "$GITHUB_ENV"
      - name: Deploy
        run: ./deploy.sh --version ${{ github.sha }}
      - name: Smoke test
        id: smoke
        run: ./smoke-test.sh
        continue-on-error: true
      - name: Rollback on failure
        if: steps.smoke.outcome == 'failure'
        run: ./deploy.sh --version ${{ env.rollback_version }}
```

## Common Patterns

### Lint, Test, Build, Deploy Pipeline

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
      - run: ./deploy.sh
```

### Conditional Steps

```yaml
steps:
  - name: Deploy to production
    if: github.ref == 'refs/heads/main'
    run: ./deploy.sh production

  - name: Deploy preview
    if: github.event_name == 'pull_request'
    run: ./deploy-preview.sh

  - name: Run only on tag
    if: startsWith(github.ref, 'refs/tags/v')
    run: ./release.sh

  - name: Skip for bot commits
    if: github.actor != 'dependabot[bot]'
    run: npm test

  - name: Run on failure only
    if: failure()
    run: ./notify-slack.sh "Build failed"
```

### Artifacts Between Jobs

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/
          retention-days: 5

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: build-output
          path: dist/
      - run: ls dist/
```

### Status Checks and Branch Protection

Configure in repo Settings > Branches > Branch protection rules:

- Require status checks to pass before merging
- Require branches to be up to date before merging
- Require specific checks by job name

```yaml
# Job names become status check names
jobs:
  ci: # Status check: "ci"
    runs-on: ubuntu-latest
    steps:
      - run: npm test
```

### Concurrency Control

```yaml
# Cancel in-progress runs for the same branch
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Never cancel production deploys
concurrency:
  group: deploy-production
  cancel-in-progress: false
```

### Job Outputs

```yaml
jobs:
  version:
    runs-on: ubuntu-latest
    outputs:
      tag: ${{ steps.get-tag.outputs.tag }}
    steps:
      - id: get-tag
        run: echo "tag=v$(date +%Y%m%d)" >> "$GITHUB_OUTPUT"

  deploy:
    needs: version
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying ${{ needs.version.outputs.tag }}"
```

## Security

### Minimal Permissions

```yaml
# Workflow-level — restrict all jobs
permissions:
  contents: read

# Job-level override
jobs:
  deploy:
    permissions:
      contents: read
      id-token: write # For OIDC
      deployments: write
```

Default `permissions: {}` grants nothing. Always start minimal and add what you
need.

### Pin Actions to SHA

```yaml
# Bad — tag can be overwritten
- uses: actions/checkout@v4

# Good — immutable commit SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

Use [StepSecurity Harden Runner](https://github.com/step-security/harden-runner)
or Dependabot to keep pinned SHAs updated.

### OIDC for Cloud Deployments

Eliminate long-lived cloud credentials by exchanging a short-lived GitHub token.

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/github-actions
      aws-region: us-east-1
      # No access key or secret key needed
```

### Secret Hygiene

```bash
# Rotate secrets
gh secret set API_KEY --body "new-value"

# List secrets (names only, not values)
gh secret list

# Environment-scoped secrets
gh secret set DB_PASSWORD --env production --body "value"
```

- Never echo secrets in logs (`add-mask` if unavoidable)
- Use environment-scoped secrets for production credentials
- Rotate on team member departure
- Prefer OIDC over stored credentials

## Debugging Pipelines

### Local Testing with act

```bash
# Install
brew install act

# Run default event (push)
act

# Run specific workflow
act -W .github/workflows/ci.yml

# Run specific job
act -j test

# List workflows without running
act -l

# Use specific runner image
act -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Pass secrets
act -s GITHUB_TOKEN="$(gh auth token)"

# Pass event payload
act pull_request -e event.json
```

### Enable Debug Logging

```yaml
# Set repository secret ACTIONS_RUNNER_DEBUG=true
# or add to workflow:
env:
  ACTIONS_RUNNER_DEBUG: true
  ACTIONS_STEP_DEBUG: true
```

```bash
# Re-run with debug logging via CLI
gh run rerun 12345 --debug
```

### SSH Debug Action

```yaml
- name: Debug via SSH
  if: failure()
  uses: mxschmitt/action-tmate@v3
  with:
    limit-access-to-actor: true # Only PR author can connect
```

### Workflow Visualization

```bash
# View run status
gh run list
gh run view 12345
gh run view 12345 --log

# Watch a run in progress
gh run watch

# View specific job log
gh run view 12345 --job 67890 --log
```

## Quick Reference

| I want to...                          | Use                                                |
| ------------------------------------- | -------------------------------------------------- |
| Run on push to main                   | `on: push: branches: [main]`                       |
| Run on PR                             | `on: pull_request:`                                |
| Run on schedule                       | `on: schedule: - cron: "0 6 * * 1"`                |
| Trigger manually                      | `on: workflow_dispatch:`                           |
| Cache npm deps                        | `actions/setup-node@v4` with `cache: npm`          |
| Run on multiple OS/versions           | `strategy: matrix:`                                |
| Share workflows across repos          | `uses: org/repo/.github/workflows/x.yml@main`      |
| Pass data between jobs                | `outputs:` + `$GITHUB_OUTPUT`                      |
| Upload build artifacts                | `actions/upload-artifact@v4`                       |
| Require approval before deploy        | `environment:` with protection rules               |
| Cancel redundant runs                 | `concurrency: group:` + `cancel-in-progress: true` |
| Run step only on main                 | `if: github.ref == 'refs/heads/main'`              |
| Run step only on failure              | `if: failure()`                                    |
| Filter by changed files               | `on: push: paths: [...]`                           |
| Pin action for security               | `uses: actions/checkout@SHA`                       |
| Deploy without long-lived credentials | OIDC with `id-token: write` permission             |
| Test workflows locally                | `act` CLI                                          |
| Debug a failed run                    | `gh run view ID --log` or `ACTIONS_RUNNER_DEBUG`   |
| Rerun a failed workflow               | `gh run rerun ID`                                  |

## See Also

- [GitHub Lesson Plan](../learn/github-lesson-plan.md) — GitHub Actions basics
- [Docker](docker.md) — Container builds in CI
- [Testing](testing.md) — Test commands for CI
- [Security Scanning](security-scanning.md) — Supply chain security in CI
- [Git](git.md) — Branch workflows
