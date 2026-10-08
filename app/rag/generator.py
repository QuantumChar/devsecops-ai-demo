"""
Generator: calls Azure OpenAI to produce a grounded answer from retrieved context.

Security note: uses Microsoft Entra ID (DefaultAzureCredential) token auth
against Azure OpenAI rather than a static API key, so no secret ever lives
in source control, CI variables, or the running container's environment.
"""
import os

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI

AOAI_ENDPOINT = os.environ.get("AZURE_OPENAI_ENDPOINT", "")
AOAI_DEPLOYMENT = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini")
API_VERSION = "2024-08-01-preview"

SYSTEM_PROMPT = (
    "You are a helpful assistant. Answer ONLY using the provided context. "
    "If the answer isn't in the context, say you don't know."
)


def _get_client() -> AzureOpenAI:
    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default"
    )
    return AzureOpenAI(
        azure_endpoint=AOAI_ENDPOINT,
        azure_ad_token_provider=token_provider,
        api_version=API_VERSION,
    )


def generate_answer(question: str, context_snippets: list[str]) -> str:
    if not AOAI_ENDPOINT:
        # Local/demo fallback so the app runs without live Azure resources.
        joined = " | ".join(context_snippets)
        return f"[demo-mode] no AZURE_OPENAI_ENDPOINT configured. Context: {joined}"

    client = _get_client()
    context = "\n---\n".join(context_snippets)
    response = client.chat.completions.create(
        model=AOAI_DEPLOYMENT,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {question}"},
        ],
        temperature=0.2,
        max_tokens=500,
    )
    return response.choices[0].message.content or ""
