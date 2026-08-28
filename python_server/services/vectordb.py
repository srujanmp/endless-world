import logging
import time
import faiss
import numpy as np
import os
import ssl
from typing import List

# Disable SSL verify globally for model downloads (proxy/AV compat)
os.environ["CURL_CA_BUNDLE"] = ""
os.environ["REQUESTS_CA_BUNDLE"] = ""
ssl._create_default_https_context = ssl._create_unverified_context

logger = logging.getLogger("EndlessWorlds.VectorDB")

from sentence_transformers import SentenceTransformer

# ─── Initialise Embedding Model ──────────────────────────────────────────────
logger.info("Loading embedding model: all-MiniLM-L6-v2...")
_load_start = time.time()
try:
    embedder = SentenceTransformer('all-MiniLM-L6-v2')
    _load_time = time.time() - _load_start
    logger.info("Embedding model loaded successfully in %.2f seconds", _load_time)
except Exception as e:
    _load_time = time.time() - _load_start
    logger.error("Failed to load embedding model after %.2f seconds — %s", _load_time, str(e))
    embedder = None

# ─── Initialise FAISS Index ──────────────────────────────────────────────────
VECTOR_DIMENSION = 384
index = faiss.IndexFlatL2(VECTOR_DIMENSION)
stored_chunks = []
logger.info("FAISS index initialised — dimension: %d, metric: L2", VECTOR_DIMENSION)


def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    """Splits a long text into smaller chunks with overlap."""
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        chunks.append(text[start:end])
        start += chunk_size - overlap

    logger.info("Text chunked — input: %d chars → %d chunks (size=%d, overlap=%d)",
                len(text), len(chunks), chunk_size, overlap)
    return chunks


def store_in_vectordb(chunks: List[str]):
    """Embeds text chunks and stores them in the FAISS index."""
    global index, stored_chunks

    if not chunks:
        logger.warning("No chunks to store — skipping")
        return
    if not embedder:
        logger.error("Embedder not available — cannot store chunks")
        return

    logger.info("Embedding %d chunks...", len(chunks))
    start = time.time()
    embeddings = embedder.encode(chunks)
    embed_time = time.time() - start
    logger.info("  ✔ Embedding completed in %.2f seconds", embed_time)

    index.add(np.array(embeddings, dtype=np.float32))
    stored_chunks.extend(chunks)
    logger.info("  ✔ Stored in FAISS — index now contains %d vectors total", index.ntotal)


def retrieve_docs(query: str, top_k: int = 3) -> List[str]:
    """Retrieves the most similar chunks from the FAISS index for a given query."""
    if index.ntotal == 0:
        logger.info("Retrieval skipped — FAISS index is empty")
        return []
    if not embedder:
        logger.error("Retrieval skipped — embedder not available")
        return []

    logger.info("Retrieving top-%d documents for query: \"%s\"", top_k, query[:60])
    start = time.time()

    query_vector = embedder.encode([query])
    distances, indices = index.search(np.array(query_vector, dtype=np.float32), top_k)

    results = []
    for idx in indices[0]:
        if idx != -1 and idx < len(stored_chunks):
            results.append(stored_chunks[idx])

    elapsed = time.time() - start
    logger.info("  ✔ Retrieved %d/%d documents in %.4f seconds", len(results), top_k, elapsed)

    if results:
        for i, doc in enumerate(results, 1):
            logger.info("  [%d] %.80s...", i, doc.replace("\n", " "))

    return results
