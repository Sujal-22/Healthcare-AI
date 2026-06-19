from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import SentenceTransformerEmbeddings
from langchain.schema import Document
from typing import List, Tuple
from app.config import get_settings

settings = get_settings()

# Singleton embedding model (load once)
_embeddings = None
_vector_store = None


def get_embeddings() -> SentenceTransformerEmbeddings:
    global _embeddings
    if _embeddings is None:
        print(f"[Embedder] Loading embedding model: {settings.embedding_model}")
        _embeddings = SentenceTransformerEmbeddings(model_name=settings.embedding_model)
    return _embeddings


def get_vector_store() -> Chroma:
    global _vector_store
    if _vector_store is None:
        _vector_store = Chroma(
            collection_name=settings.chroma_collection,
            embedding_function=get_embeddings(),
            persist_directory=settings.chroma_db_path,
        )
    return _vector_store


def chunk_documents(documents: List[Document]) -> List[Document]:
    """Split documents into smaller chunks for better retrieval."""
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        separators=["\n\n", "\n", ".", ",", " "],
    )
    chunks = splitter.split_documents(documents)
    print(f"[Embedder] {len(documents)} docs → {len(chunks)} chunks")
    return chunks


def ingest_documents(documents: List[Document], force_reload: bool = False) -> Tuple[int, int]:
    """
    Chunk + embed + store documents in ChromaDB.
    Returns (files_processed, chunks_stored).
    """
    store = get_vector_store()

    if force_reload:
        print("[Embedder] Force reload — clearing existing collection")
        store.delete_collection()
        # Reinit after delete
        global _vector_store
        _vector_store = None
        store = get_vector_store()

    chunks = chunk_documents(documents)
    store.add_documents(chunks)
    print(f"[Embedder] Stored {len(chunks)} chunks in ChromaDB")
    return len(documents), len(chunks)


def is_collection_populated() -> bool:
    """Check if ChromaDB already has data."""
    try:
        store = get_vector_store()
        count = store._collection.count()
        return count > 0
    except Exception:
        return False
