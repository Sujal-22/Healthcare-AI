import os
import pandas as pd
from pathlib import Path
from typing import List
from langchain.schema import Document
from app.config import get_settings

settings = get_settings()


def load_txt_file(filepath: str) -> List[Document]:
    """Load a .txt file as LangChain Documents."""
    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read()
    filename = Path(filepath).name
    return [Document(page_content=text, metadata={"source": filename, "type": "txt"})]


def load_csv_file(filepath: str) -> List[Document]:
    """Load a .csv file — each row becomes a Document."""
    df = pd.read_csv(filepath)
    filename = Path(filepath).name
    documents = []

    for idx, row in df.iterrows():
        # Combine all columns into a single text block
        content = "\n".join([f"{col}: {val}" for col, val in row.items() if pd.notna(val)])
        documents.append(
            Document(
                page_content=content,
                metadata={"source": filename, "row": idx, "type": "csv"},
            )
        )
    return documents


def load_all_documents() -> List[Document]:
    """Scan data/ dir and load all TXT + CSV files."""
    data_dir = Path(settings.data_dir)
    if not data_dir.exists():
        raise FileNotFoundError(f"Data directory not found: {data_dir}")

    all_docs: List[Document] = []
    file_count = 0

    for filepath in data_dir.iterdir():
        suffix = filepath.suffix.lower()
        if suffix == ".txt":
            docs = load_txt_file(str(filepath))
            all_docs.extend(docs)
            file_count += 1
            print(f"[Loader] Loaded TXT: {filepath.name} ({len(docs)} doc)")
        elif suffix == ".csv":
            docs = load_csv_file(str(filepath))
            all_docs.extend(docs)
            file_count += 1
            print(f"[Loader] Loaded CSV: {filepath.name} ({len(docs)} rows)")
        else:
            print(f"[Loader] Skipped: {filepath.name} (unsupported type)")

    print(f"[Loader] Total: {file_count} files → {len(all_docs)} documents")
    return all_docs
