import logging
import time
from fastapi import FastAPI, HTTPException
from dotenv import load_dotenv

# ─── Logging Setup ───────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s │ %(levelname)-8s │ %(name)-18s │ %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("EndlessWorlds")

# Load env variables before importing services that use them
load_dotenv(dotenv_path="../.env")
logger.info("Environment variables loaded from .env")

from models.schemas import ScrapeRequest, RAGRequest, RiddleRequest
from services.scraper import search_and_scrape
from services.vectordb import chunk_text, store_in_vectordb, retrieve_docs, reset_index
from services.llm import generate_rag_reply, generate_riddle_json

app = FastAPI(title="Endless Worlds RAG API")
logger.info("FastAPI application initialised — Endless Worlds RAG API")


@app.post("/api/scrape")
async def scrape_and_store(req: ScrapeRequest):
    """
    Scrapes the Web: Searches DuckDuckGo for the topic, cleans the HTML,
    chunks the text, and stores the embeddings temporarily in a Vector DB.
    """
    logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    logger.info("POST /api/scrape — Topic: \"%s\"", req.topic)
    start = time.time()

    try:
        logger.info("Step 0/3 — Clearing previous context from Vector DB...")
        reset_index()

        logger.info("Step 1/3 — Searching DuckDuckGo and scraping top result...")
        target_url, cleaned_text = search_and_scrape(req.topic)
        logger.info("  ✔ Scraped URL: %s", target_url)
        logger.info("  ✔ Cleaned text length: %d characters", len(cleaned_text))

        logger.info("Step 2/3 — Splitting text into chunks (size=500, overlap=50)...")
        chunks = chunk_text(cleaned_text, chunk_size=500, overlap=50)
        logger.info("  ✔ Created %d chunks", len(chunks))

        logger.info("Step 3/3 — Embedding chunks and storing in Vector DB...")
        store_in_vectordb(chunks)
        logger.info("  ✔ Chunks stored in FAISS index")

        elapsed = time.time() - start
        logger.info("Scrape pipeline completed in %.2f seconds", elapsed)
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        return {"status": "success", "url": target_url, "chunks_stored": len(chunks)}

    except Exception as e:
        elapsed = time.time() - start
        logger.error("Scrape pipeline FAILED after %.2f seconds — %s", elapsed, str(e))
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/rag")
async def rag_query(req: RAGRequest):
    """
    Retrieval-Augmented Generation (RAG): Takes a prompt, retrieves relevant
    documents from the Vector DB, and generates a reply using the LLM.
    """
    logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    logger.info("POST /api/rag — Prompt: \"%s\"", req.prompt[:80])
    start = time.time()

    try:
        query = req.topic if req.topic else req.prompt
        logger.info("Step 1/2 — Retrieving relevant documents (top_k=5)...")
        retrieved_docs = retrieve_docs(query, top_k=5)
        logger.info("  ✔ Retrieved %d document chunks", len(retrieved_docs))

        logger.info("Step 2/2 — Generating RAG reply via LLM...")
        reply = generate_rag_reply(req.prompt, retrieved_docs)
        logger.info("  ✔ LLM reply received (%d characters)", len(reply))

        elapsed = time.time() - start
        logger.info("RAG query completed in %.2f seconds", elapsed)
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        return {"reply": reply}

    except Exception as e:
        elapsed = time.time() - start
        logger.error("RAG query FAILED after %.2f seconds — %s", elapsed, str(e))
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/generate_riddle")
async def generate_riddle(req: RiddleRequest):
    """
    Generates a Riddle: Retrieves context from Vector DB (assuming /api/scrape
    was called prior), and commands the LLM to generate a formatted JSON
    riddle with options and hints.
    """
    logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    logger.info("POST /api/generate_riddle — Topic: \"%s\" | Difficulty: \"%s\"", req.topic, req.difficulty)
    start = time.time()

    try:
        logger.info("Step 1/2 — Retrieving context from Vector DB (top_k=5)...")
        retrieved_docs = retrieve_docs(req.topic, top_k=5)
        logger.info("  ✔ Retrieved %d context chunks", len(retrieved_docs))

        logger.info("Step 2/2 — Generating riddle via LLM...")
        result_json = generate_riddle_json(req.topic, req.difficulty, retrieved_docs)
        logger.info("  ✔ Riddle generated successfully")
        logger.info("  ├─ Question : %s", result_json.get("riddle", "N/A")[:100])
        logger.info("  ├─ Answer   : %s", result_json.get("solution", "N/A"))
        logger.info("  ├─ Options  : %s", result_json.get("options", []))
        logger.info("  └─ Source   : %s", result_json.get("source", "unknown"))

        elapsed = time.time() - start
        logger.info("Riddle generation completed in %.2f seconds", elapsed)
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        return result_json

    except Exception as e:
        elapsed = time.time() - start
        logger.error("Riddle generation FAILED after %.2f seconds — %s", elapsed, str(e))
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        raise HTTPException(status_code=500, detail=f"Failed to generate riddle: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Uvicorn server on http://0.0.0.0:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
