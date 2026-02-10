# Security Scanning Cheat Sheet

Verify open source repos and dependencies before use.

## Quick Start

```bash
# Before cloning: check project health
scorecard --repo=github.com/owner/project

# Before installing: check for malicious packages
guarddog pypi scan requests
guarddog npm scan lodash

# After cloning: comprehensive scan
trivy repo .
```

## Project Health (OpenSSF Scorecard)

Scores repos 0-10 on 16 security checks.

```bash
# Install
brew install scorecard
# or: go install github.com/ossf/scorecard/v5/cmd/scorecard@latest

# Scan public repo
scorecard --repo=github.com/owner/project

# Scan with GitHub token (higher rate limits)
export GITHUB_AUTH_TOKEN=ghp_xxx
scorecard --repo=github.com/owner/project

# JSON output for CI
scorecard --repo=github.com/owner/project --format=json

# Check specific checks only
scorecard --repo=github.com/owner/project --checks=Maintained,Vulnerabilities
```

### What Scorecard Checks

| Check                  | What It Evaluates                    |
| ---------------------- | ------------------------------------ |
| Maintained             | Recent commits, issue response       |
| Vulnerabilities        | Known CVEs in dependencies           |
| Branch-Protection      | PR reviews, signed commits required  |
| Code-Review            | Changes reviewed before merge        |
| CI-Tests               | Tests run on PRs                     |
| SAST                   | Static analysis in pipeline          |
| Signed-Releases        | Cryptographic signatures on releases |
| Pinned-Dependencies    | Exact versions, not ranges           |
| Security-Policy        | SECURITY.md exists                   |
| Fuzzing                | Participates in OSS-Fuzz             |
| Token-Permissions      | Minimal GitHub Actions permissions   |
| Dependency-Update-Tool | Dependabot, Renovate configured      |
| Binary-Artifacts       | No compiled binaries in repo         |
| Contributors           | Multiple orgs contributing           |
| CII-Best-Practices     | Core Infrastructure Initiative badge |
| Packaging              | Published to package registry        |

## Malicious Package Detection

### GuardDog

Detects typosquatting, obfuscation, data exfiltration.

```bash
# Install
pip install guarddog

# Scan before installing
guarddog pypi scan requests
guarddog npm scan lodash
guarddog go scan github.com/gin-gonic/gin

# Scan local package
guarddog pypi verify ./my-package-1.0.0.tar.gz
guarddog npm verify ./package.tgz

# Scan requirements file
guarddog pypi verify requirements.txt

# Output as JSON
guarddog pypi scan requests --output-format=json
```

### What GuardDog Detects

| Category        | Examples                                           |
| --------------- | -------------------------------------------------- |
| Code Execution  | `exec(base64.decode(...))`, hidden eval            |
| Exfiltration    | Sending env vars, credentials to remote server     |
| Obfuscation     | Base64-encoded payloads, steganography             |
| Typosquatting   | `reqeusts`, `lodasj` (misspelled popular packages) |
| Install Hooks   | Malicious code in setup.py, postinstall            |
| Suspicious Meta | Empty description, single file, bundled binaries   |

### Socket

Behavioral analysis with maintainer reputation tracking.

```bash
# Install CLI
npm install -g @socketsecurity/cli

# Wrap package managers (scans on install)
alias npm="socket npm"
alias pip="socket pip"

# Scan directory
socket scan .

# Check specific package
socket npm info lodash
```

## Vulnerability Scanning

### Trivy (All-in-One)

Scans repos, containers, IaC, and secrets.

```bash
# Install
brew install trivy

# Scan repository
trivy repo .
trivy repo https://github.com/owner/project

# Scan filesystem
trivy fs .

# Scan container image
trivy image python:3.11
trivy image myapp:latest

# Scan IaC (Terraform, CloudFormation, Kubernetes)
trivy config .

# Scan for secrets
trivy fs --scanners secret .

# Filter by severity
trivy repo . --severity HIGH,CRITICAL

# Ignore unfixed vulnerabilities
trivy repo . --ignore-unfixed

# Output formats
trivy repo . --format json --output results.json
trivy repo . --format table    # default
trivy repo . --format sarif    # for GitHub Security tab
```

### OSV-Scanner

Google-backed, uses call analysis for fewer false positives.

```bash
# Install
go install github.com/google/osv-scanner/cmd/osv-scanner@latest

# Scan directory
osv-scanner -r .

# Scan lockfile
osv-scanner --lockfile=package-lock.json
osv-scanner --lockfile=poetry.lock
osv-scanner --lockfile=go.sum

# Scan SBOM
osv-scanner --sbom=sbom.json

# Call analysis (only reachable vulns)
osv-scanner --experimental-call-analysis -r .

# Output formats
osv-scanner -r . --format json
osv-scanner -r . --format markdown
```

### SafeDep Vet

Reachability analysis—flags only vulns your code actually calls.

```bash
# Install
brew install safedep/tap/vet

# Scan with policy
vet scan -D .

# Generate SBOM
vet scan -D . --report-sbom=sbom.json

# Filter by reachability
vet scan -D . --filter-reachable
```

### Language-Specific

```bash
# Go: govulncheck (official, call-path aware)
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Python: pip-audit
pip install pip-audit
pip-audit
pip-audit -r requirements.txt

# Node: npm audit
npm audit
npm audit --json
npm audit fix           # auto-fix where possible

# Ruby: bundler-audit
gem install bundler-audit
bundle-audit check --update
```

## Secrets Detection

### Gitleaks

Fast scanning with 700+ regex patterns.

```bash
# Install
brew install gitleaks

# Scan current directory
gitleaks detect

# Scan git history
gitleaks detect --source=. --log-opts="--all"

# Scan specific commits
gitleaks detect --log-opts="HEAD~10..HEAD"

# Pre-commit hook
gitleaks protect --staged

# Baseline (ignore existing secrets)
gitleaks detect --baseline-path=.gitleaks-baseline.json

# Custom config
gitleaks detect --config=.gitleaks.toml
```

### Common Patterns Detected

- AWS access keys and secrets
- GitHub/GitLab tokens
- Stripe, Slack, Twilio API keys
- Database connection strings
- Private keys (RSA, SSH, PGP)
- Generic high-entropy strings

## SBOM Generation

```bash
# Syft (Anchore)
brew install syft
syft . -o spdx-json > sbom.spdx.json
syft . -o cyclonedx-json > sbom.cdx.json

# Trivy
trivy sbom . --format cyclonedx > sbom.cdx.json

# CycloneDX tools
pip install cyclonedx-bom
cyclonedx-py requirements > sbom.xml

npm install -g @cyclonedx/cyclonedx-npm
cyclonedx-npm --output-file sbom.json
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]

jobs:
  scorecard:
    runs-on: ubuntu-latest
    steps:
      - uses: ossf/scorecard-action@v2
        with:
          results_file: scorecard.sarif
      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: scorecard.sarif

  trivy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: HIGH,CRITICAL
          exit-code: 1

  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/python-security/guarddog
    rev: v1.3.0
    hooks:
      - id: guarddog
```

## Workflow: Evaluating a New Dependency

```bash
# 1. Check project health
scorecard --repo=github.com/owner/project

# 2. Check for malicious patterns
guarddog pypi scan package-name

# 3. Check known vulnerabilities
osv-scanner --lockfile=requirements.txt

# 4. Review if scores are concerning
#    - Scorecard < 5: investigate further
#    - GuardDog warnings: read the flagged code
#    - Any CRITICAL CVEs: check if patched version exists
```

## Quick Reference

| Task                      | Command                           |
| ------------------------- | --------------------------------- |
| Project health score      | `scorecard --repo=github.com/o/p` |
| Detect malicious package  | `guarddog pypi scan pkg`          |
| Scan repo for vulns       | `trivy repo .`                    |
| Scan container            | `trivy image name:tag`            |
| Scan for secrets          | `gitleaks detect`                 |
| Go vulnerabilities        | `govulncheck ./...`               |
| Python vulnerabilities    | `pip-audit`                       |
| Node vulnerabilities      | `npm audit`                       |
| Generate SBOM             | `syft . -o cyclonedx-json`        |
| Lockfile vulns (any lang) | `osv-scanner --lockfile=lockfile` |

## Tool Comparison

| Tool        | Strength                             | Best For                      |
| ----------- | ------------------------------------ | ----------------------------- |
| Scorecard   | Project health metrics               | Evaluating before adoption    |
| GuardDog    | Malicious code detection             | Catching supply chain attacks |
| Trivy       | Broad coverage (vulns, secrets, IaC) | CI/CD scanning                |
| OSV-Scanner | Call analysis, low false positives   | Prioritizing real risks       |
| Vet         | Reachability-aware                   | Reducing noise                |
| Gitleaks    | Fast secrets scanning                | Pre-commit, history scanning  |
| Socket      | Behavioral analysis                  | npm/PyPI deep analysis        |

## See Also

- [Cryptography](cryptography.md) — Hashing, encryption, and TLS commands
- [Cryptography Lesson Plan](../learn/cryptography-lesson-plan.md) — Key
  management and common mistakes

## Resources

- [OpenSSF Scorecard](https://scorecard.dev/)
- [GuardDog](https://github.com/DataDog/guarddog)
- [Trivy](https://trivy.dev/)
- [OSV-Scanner](https://github.com/google/osv-scanner)
- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [Socket](https://socket.dev/)
- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)
