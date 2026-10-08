# DevSecOps AI Demo — RAG Chatbot on Azure

A reusable, revisitable demo for showing customers a **full DevSecOps
lifecycle** applied to a real AI application: a Retrieval-Augmented
Generation (RAG) chatbot using **Azure OpenAI** + **Azure AI Search**,
deployed to **Azure App Service** via **GitHub Actions**.

> 👉 Start here when prepping for a customer call: [`docs/devsecops-narrative.md`](docs/devsecops-narrative.md)
> 👉 Architecture & identity model: [`docs/architecture.md`](docs/architecture.md)
> 👉 What every pipeline stage does and why: [`docs/pipeline-stages.md`](docs/pipeline-stages.md)

## Repo layout

```
app/              FastAPI RAG chatbot (main.py, rag/retriever.py, rag/generator.py)
infra/            Bicep IaC — App Service, Azure OpenAI, AI Search, Log Analytics, RBAC
.github/
  workflows/
    ci.yml              lint, tests, SAST (Bandit + CodeQL), dependency review, IaC scan, container scan
    cd.yml              bicep what-if/deploy, app deploy, OWASP ZAP DAST scan
    security-scan.yml   scheduled CodeQL + secret-scanning audit
  dependabot.yml         automated dependency PRs (pip, Docker, GitHub Actions)
docs/             Demo narrative, architecture, and pipeline-stage reference
```

## DevSecOps gates included

SAST (Bandit, CodeQL) · Dependency review (GitHub) · Dependabot ·
IaC scanning (Checkov) · Container image scanning (Trivy) ·
Secret-scanning audit (gitleaks) · Infra preview (`what-if`) ·
DAST (OWASP ZAP baseline) — see [`docs/pipeline-stages.md`](docs/pipeline-stages.md)
for the full table.

## Run locally (no Azure resources required — demo mode)

```powershell
cd app
pip install -r requirements.txt -r requirements-dev.txt
pytest -v
uvicorn main:app --reload
# POST http://localhost:8000/chat  {"question": "What is DevSecOps?"}
```

Without `AZURE_OPENAI_ENDPOINT` / `AZURE_SEARCH_ENDPOINT` set, the app
runs in a safe "demo mode" that echoes input instead of calling Azure —
useful for showing the pipeline without live resources.

## One-time setup to enable the CD pipeline

1. Create a resource group: `az group create -n rg-devsecops-demo -l eastus2`
2. Create an Entra ID app registration with **federated credentials**
   for GitHub OIDC (no client secret needed):
   ```powershell
   az ad app create --display-name devsecops-ai-demo-gh
   # then configure federated credential for repo:quantumchar/devsecops-ai-demo:ref:refs/heads/main
   ```
3. Grant that app's service principal **Contributor** on the resource
   group.
4. In the GitHub repo, set:
   - **Secrets**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
   - **Variables**: `AZURE_RESOURCE_GROUP`, `AZURE_WEBAPP_NAME`
5. Push to `main` — CI runs, then CD provisions infra and deploys.

## Revisiting this for a new customer demo

- Re-run `cd.yml` manually (`workflow_dispatch`) to get a fresh green run.
- Open a small PR live to show the CI gates firing in real time.
- Walk the GitHub **Security** tab for aggregated findings.
