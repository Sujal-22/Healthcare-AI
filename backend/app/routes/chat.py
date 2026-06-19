from fastapi import APIRouter, HTTPException
from app.models.schemas import (
    ChatRequest, ChatResponse, SourceDocument,
    IngestRequest, IngestResponse,
    HealthResponse,
)
from app.rag.retriever import query_rag, check_ollama_connection
from app.rag.embedder import ingest_documents, get_vector_store, is_collection_populated
from app.rag.loader import load_all_documents
from app.config import get_settings

router = APIRouter()
settings = get_settings()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Check if Ollama + ChromaDB are ready."""
    ollama_ok = check_ollama_connection()
    db_ready = is_collection_populated()
    return HealthResponse(
        status="ok" if ollama_ok else "degraded",
        ollama_connected=ollama_ok,
        vector_db_ready=db_ready,
        model=settings.ollama_model,
    )


@router.post("/ingest", response_model=IngestResponse)
async def ingest_data(request: IngestRequest):
    """Load TXT/CSV from data/ dir and store in ChromaDB."""
    try:
        documents = load_all_documents()
        if not documents:
            raise HTTPException(status_code=400, detail="No TXT/CSV files found in data/ directory")

        files_processed, chunks_stored = ingest_documents(
            documents, force_reload=request.force_reload
        )
        return IngestResponse(
            status="success",
            files_processed=files_processed,
            chunks_stored=chunks_stored,
        )
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ingest failed: {str(e)}")


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Main chat endpoint — RAG query to Ollama."""
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    if not is_collection_populated():
        raise HTTPException(
            status_code=503,
            detail="Vector DB is empty. Call POST /ingest first to load health data.",
        )

    try:
        result = query_rag(question=request.message, top_k=request.top_k)
        sources = [SourceDocument(**s) for s in result["sources"]]
        return ChatResponse(
            answer=result["answer"],
            sources=sources,
            session_id=request.session_id,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat failed: {str(e)}")
