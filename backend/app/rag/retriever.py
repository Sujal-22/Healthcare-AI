from langchain_ollama import OllamaLLM
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from app.config import get_settings
from app.rag.embedder import get_vector_store
from typing import Dict, Any

settings = get_settings()

# Singleton LLM
_llm = None

HEALTH_PROMPT = PromptTemplate(
    input_variables=["context", "question"],
    template="""You are a helpful and knowledgeable healthcare assistant. 
Use ONLY the context below to answer the question. 
If the answer is not in the context, say "I don't have enough information on that topic."
Do NOT make up medical advice. Always recommend consulting a doctor for serious concerns.

Context:
{context}

Question: {question}

Answer:""",
)


def get_llm() -> OllamaLLM:
    global _llm
    if _llm is None:
        print(f"[Retriever] Connecting to Ollama: {settings.ollama_model}")
        _llm = OllamaLLM(
            base_url=settings.ollama_base_url,
            model=settings.ollama_model,
            temperature=0.2,  # low temp = more factual for healthcare
        )
    return _llm


def query_rag(question: str, top_k: int = 3) -> Dict[str, Any]:
    """
    Run RAG query:
    1. Embed question
    2. Retrieve top_k chunks from ChromaDB
    3. Pass context + question to Ollama
    4. Return answer + source docs
    """
    store = get_vector_store()
    retriever = store.as_retriever(search_kwargs={"k": top_k})

    qa_chain = RetrievalQA.from_chain_type(
        llm=get_llm(),
        chain_type="stuff",
        retriever=retriever,
        chain_type_kwargs={"prompt": HEALTH_PROMPT},
        return_source_documents=True,
    )

    result = qa_chain.invoke({"query": question})

    # Extract source docs metadata
    sources = []
    for doc in result.get("source_documents", []):
        sources.append(
            {
                "content": doc.page_content[:300],  # trim for response size
                "source": doc.metadata.get("source", "unknown"),
                "score": None,
            }
        )

    return {
        "answer": result["result"],
        "sources": sources,
    }


def check_ollama_connection() -> bool:
    """Ping Ollama to verify it's running."""
    import httpx
    try:
        resp = httpx.get(f"{settings.ollama_base_url}/api/tags", timeout=3.0)
        return resp.status_code == 200
    except Exception:
        return False
