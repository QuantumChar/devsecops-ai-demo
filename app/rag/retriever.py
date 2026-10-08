"""
Retriever: pulls grounding context from Azure AI Search.

Security note: uses DefaultAzureCredential (managed identity in Azure,
az login locally) instead of API keys baked into source or config files.
"""
import os

from azure.identity import DefaultAzureCredential
from azure.search.documents import SearchClient

SEARCH_ENDPOINT = os.environ.get("AZURE_SEARCH_ENDPOINT", "")
SEARCH_INDEX = os.environ.get("AZURE_SEARCH_INDEX", "demo-index")


def _get_client() -> SearchClient:
    credential = DefaultAzureCredential()
    return SearchClient(endpoint=SEARCH_ENDPOINT, index_name=SEARCH_INDEX, credential=credential)


def retrieve_context(query: str, top: int = 3) -> list[str]:
    """Return the top-k matching document snippets for a query."""
    if not SEARCH_ENDPOINT:
        # Local/demo fallback so the app runs without live Azure resources.
        return [f"[demo-mode] no AZURE_SEARCH_ENDPOINT configured; echoing query: {query}"]

    client = _get_client()
    results = client.search(search_text=query, top=top)
    return [doc.get("content", "") for doc in results]
