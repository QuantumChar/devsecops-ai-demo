# Pipeline Stages — What Each Gate Does and Why

| # | Stage | Workflow | Tool | Gate type | What it catches |
|---|-------|----------|------|-----------|------------------|
| 1 | Lint & unit test | `ci.yml` | ruff, pytest | Quality | Style issues, broken logic before merge |
| 2 | SAST (Python) | `ci.yml` | Bandit | Security | Hardcoded secrets, unsafe `eval`, weak crypto, injection patterns |
| 3 | SAST (deep/semantic) | `ci.yml` | CodeQL | Security | Data-flow vulnerabilities (SQL/command injection, SSRF, etc.) |
| 4 | Dependency review | `ci.yml` (PRs only) | GitHub Dependency Review | Security | Blocks PRs introducing known-vulnerable or newly-licensed dependencies |
| 5 | IaC scan | `ci.yml` | Checkov | Security | Misconfigured Bicep (public access, missing encryption, weak TLS) |
| 6 | Container build + scan | `ci.yml` | Trivy | Security | CVEs in the base image and installed packages |
| 7 | Infra deploy (preview) | `cd.yml` | `az deployment ... --what-if` | Safety | Shows exactly what will change before it changes |
| 8 | Infra deploy (apply) | `cd.yml` | Bicep via OIDC | — | Provisions/updates Azure resources with least-privilege RBAC |
| 9 | App deploy | `cd.yml` | `azure/webapps-deploy` | — | Ships code to App Service |
| 10 | DAST | `cd.yml` | OWASP ZAP Baseline | Security | Scans the *running* app for live vulnerabilities (headers, XSS, etc.) |
| 11 | Scheduled re-scan | `security-scan.yml` | CodeQL, gitleaks | Security | Weekly drift detection + secret-scanning audit even with no new commits |
| 12 | Dependency bot | `dependabot.yml` | Dependabot | Security | Automated PRs for pip, Docker base image, and GitHub Actions updates |

## Demo flow suggestion (for a customer walkthrough)

1. **Show the code** — point out no API keys anywhere (`retriever.py`,
   `generator.py`, `main.bicep`) — everything is Entra ID/RBAC.
2. **Open a PR** with a small change → watch CI run: lint, tests, Bandit,
   CodeQL, dependency review, Checkov, Trivy — all visible as checks on
   the PR.
3. **Merge to main** → CD triggers: `what-if` preview, infra deploy, app
   deploy, then a live ZAP scan against the just-deployed URL.
4. **Open the Security tab** on GitHub to show the aggregated
   CodeQL/dependency alerts in one place.
5. **Talk to the gates**: which ones hard-fail (dependency review) vs.
   soft-fail/report-only (Trivy, ZAP) in this demo, and why you'd flip
   that switch for production (`exit-code`, `fail_action` params).
