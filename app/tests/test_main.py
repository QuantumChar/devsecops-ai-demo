import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_chat_demo_mode():
    response = client.post("/chat", json={"question": "What is DevSecOps?"})
    assert response.status_code == 200
    body = response.json()
    assert "answer" in body
    assert "sources" in body


def test_chat_rejects_empty_question():
    response = client.post("/chat", json={"question": ""})
    assert response.status_code == 422


def test_chat_rejects_oversized_question():
    response = client.post("/chat", json={"question": "a" * 2001})
    assert response.status_code == 422
