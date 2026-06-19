from pydantic import BaseModel
from typing import Optional, List


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = "default"
    top_k: Optional[int] = 3  # number of RAG chunks to retrieve


class SourceDocument(BaseModel):
    content: str
    source: str
    score: Optional[float] = None


class ChatResponse(BaseModel):
    answer: str
    sources: List[SourceDocument] = []
    session_id: str


class IngestRequest(BaseModel):
    force_reload: Optional[bool] = False


class IngestResponse(BaseModel):
    status: str
    files_processed: int
    chunks_stored: int


class HealthResponse(BaseModel):
    status: str
    ollama_connected: bool
    vector_db_ready: bool
    model: str
