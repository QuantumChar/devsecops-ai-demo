# Architecture

## What this demo is

A minimal **RAG (Retrieval-Augmented Generation) chatbot**:
`FastAPI app → Azure AI Search (retrieval) → Azure OpenAI (generation)`,
deployed to **Azure App Service** via **GitHub Actions**.

The app itself is intentionally simple — the point of this repo is the
**DevSecOps pipeline wrapped around it**, since that's reusable across any
AI app you build for customers.

```
Customer question
      │
      ▼
 FastAPI /chat  ──►  Azure AI Search  (retrieve grounding context)
      │                      │
      │◄─────────────────────┘
      ▼
 Azure OpenAI (gpt-4o-mini)  (generate grounded answer)
      │
      ▼
 Answer + cited sources back to customer
```

## Identity & secrets model

- The App Service uses a **system-assigned managed identity**.
- `disableLocalAuth: true` on both Azure OpenAI and Azure AI Search —
  **no API keys exist at all**, only Entra ID (RBAC) auth.
- GitHub Actions authenticates to Azure via **OIDC federated credentials**
  (`azure/login@v2` with `id-token: write`) — no long-lived cloud secrets
  stored in GitHub.

## Resources provisioned (infra/main.bicep)

| Resource | Purpose | Security notes |
|---|---|---|
| App Service Plan + Web App | Hosts the FastAPI app | HTTPS-only, TLS 1.2 min, FTP disabled, system-assigned identity |
| Azure OpenAI | LLM generation | Local auth disabled, RBAC-only |
| Azure AI Search | Vector/keyword retrieval | Local auth disabled, RBAC-only |
| Log Analytics | Centralized logs/metrics | Diagnostic settings wired from Web App |

## Why this is a good AI Apps SE demo

It mirrors the real objections customers raise about shipping AI apps:
*"How do we scan for prompt-injection-adjacent code issues, keep secrets
out of the pipeline, catch vulnerable dependencies, and prove the running
app was actually tested before it reached production?"* — this repo
answers each of those concretely, in a pipeline you can show running live.
