"""
FastAPI entrypoint for the RAG chatbot demo app.

Demonstrates basic secure-by-default app patterns:
- Pydantic input validation (defends against malformed/oversized payloads)
- No secrets in code; all config comes from environment variables that are
  populated from Azure App Service app settings / Key Vault references
- A /health endpoint for platform liveness/readiness probes
"""
import logging

from fastapi import FastAPI
from pydantic import BaseModel, Field

from rag.generator import generate_answer
from rag.retriever import retrieve_context

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("devsecops-ai-demo")

app = FastAPI(title="DevSecOps AI Demo - RAG Chatbot", version="1.0.0")


class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)


class ChatResponse(BaseModel):
    answer: str
    sources: list[str]


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    logger.info("Received chat request (length=%d chars)", len(request.question))
    context = retrieve_context(request.question)
    answer = generate_answer(request.question, context)
    return ChatResponse(answer=answer, sources=context)
