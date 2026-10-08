# DevSecOps Narrative — Talking Points for Customer Demos

Use this as your script/cheat-sheet when you revisit this demo before a
customer call. Each point maps to something you can click on live.

## Opening framing (30 seconds)

> "Most customers building AI apps ask the same question once they move
> past the prototype: *how do we ship this safely and keep shipping it
> safely?* This repo is a small RAG chatbot — the app isn't the point.
> The point is everything wrapped around it: a DevSecOps pipeline with
> security gates at every stage, from the first line of code to the
> running production app."

## Key messages by audience

- **Security team**: "No secrets exist in this system at all — not in
  code, not in CI, not in App Service settings. Azure OpenAI and AI
  Search both have local (key-based) auth disabled; everything is Entra
  ID + RBAC, including how GitHub Actions authenticates to Azure (OIDC,
  no stored cloud credentials)."
- **Platform/DevOps team**: "Every gate — SAST, dependency review, IaC
  scanning, container scanning, DAST — runs as a normal GitHub Actions
  check. Nothing proprietary; your existing GitHub Advanced Security
  entitlement lights most of this up already."
- **App/AI team**: "The security tooling doesn't slow down iteration —
  CodeQL and dependency review run in parallel with tests, and the
  riskier gates (Trivy, ZAP) are soft-fail in this demo so you can see
  findings without blocking velocity, then you decide per-project what
  should hard-fail."
- **Leadership**: "This is auditable: every deployment has a visible
  what-if preview, every security finding lands in one GitHub Security
  tab, and Dependabot keeps dependencies current without manual effort."

## Things to click on, in order

1. `docs/architecture.md` — identity/secrets model diagram.
2. `app/rag/generator.py` / `retriever.py` — point at
   `DefaultAzureCredential`, zero API keys.
3. A PR with checks running — CI gates visible inline.
4. GitHub **Security** tab — CodeQL + Dependency alerts aggregated.
5. Actions tab → a completed `cd.yml` run — what-if diff, deploy,
   then the ZAP scan step/log.
6. `infra/main.bicep` — `disableLocalAuth: true`, RBAC role assignments.

## Likely objections & responses

- *"Doesn't all this scanning slow us down?"* → Most gates run in
  parallel (~2–3 min total); only dependency review hard-blocks merges,
  and only on high/critical findings.
- *"What if we use Azure DevOps instead of GitHub Actions?"* → Same gate
  concepts (SAST/DAST/IaC/dependency/container scanning) map directly to
  Azure DevOps pipeline tasks or Defender for DevOps.
- *"How do we extend this to multi-agent / Foundry agents?"* → Same
  pattern: managed identity + RBAC to Foundry resources, same pipeline
  gates, swap the app layer only.
