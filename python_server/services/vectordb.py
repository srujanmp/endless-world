import faiss
import numpy as np
from typing import List
from sentence_transformers import SentenceTransformer

# Initialize embeddings and vector DB
print("Loading embedding model...")
try:
    embedder = SentenceTransformer('all-MiniLM-L6-v2')
except Exception as e:
    print(f"Failed to load sentence transformer: {e}")
    embedder = None
    
VECTOR_DIMENSION = 384
index = faiss.IndexFlatL2(VECTOR_DIMENSION)
stored_chunks = []

def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    """Splits a long text into smaller chunks with overlap."""
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

def store_in_vectordb(chunks: List[str]):
    """Embeds text chunks and stores them in the FAISS index."""
    global index, stored_chunks
    if not chunks or not embedder:
        return
    embeddings = embedder.encode(chunks)
    index.add(np.array(embeddings, dtype=np.float32))
    stored_chunks.extend(chunks)

def retrieve_docs(query: str, top_k: int = 3) -> List[str]:
    """Retrieves the most similar chunks from the FAISS index for a given query."""
    if index.ntotal == 0 or not embedder:
        return []
    query_vector = embedder.encode([query])
    distances, indices = index.search(np.array(query_vector, dtype=np.float32), top_k)
    results = []
    for idx in indices[0]:
        if idx != -1 and idx < len(stored_chunks):
            results.append(stored_chunks[idx])
    return results
