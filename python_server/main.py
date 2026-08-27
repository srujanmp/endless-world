from fastapi import FastAPI, HTTPException
from dotenv import load_dotenv

# Load env variables before importing services that use them
load_dotenv(dotenv_path="../.env")

from models.schemas import ScrapeRequest, RAGRequest, RiddleRequest
from services.scraper import search_and_scrape
from services.vectordb import chunk_text, store_in_vectordb, retrieve_docs
from services.llm import generate_rag_reply, generate_riddle_json

app = FastAPI(title="Endless Worlds RAG API")

@app.post("/api/scrape")
async def scrape_and_store(req: ScrapeRequest):
    """
    Scrapes the Web: Searches DuckDuckGo for the topic, cleans the HTML, 
    chunks the text, and stores the embeddings temporarily in a Vector DB.
    """
    try:
        target_url, cleaned_text = search_and_scrape(req.topic)
        chunks = chunk_text(cleaned_text, chunk_size=500, overlap=50)
        store_in_vectordb(chunks)
        return {"status": "success", "url": target_url, "chunks_stored": len(chunks)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/rag")
async def rag_query(req: RAGRequest):
    """
    Retrieval-Augmented Generation (RAG): Takes a prompt, retrieves relevant 
    documents from the Vector DB, and generates a reply using the LLM.
    """
    try:
        query = req.topic if req.topic else req.prompt
        retrieved_docs = retrieve_docs(query, top_k=5)
        reply = generate_rag_reply(req.prompt, retrieved_docs)
        return {"reply": reply}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/generate_riddle")
async def generate_riddle(req: RiddleRequest):
    """
    Generates a Riddle: Retrieves context from Vector DB (assuming /api/scrape 
    was called prior), and commands the LLM to generate a formatted JSON 
    riddle with options and hints.
    """
    try:
        # 2. Retrieve relevant context
        retrieved_docs = retrieve_docs(req.topic, top_k=5)
        
        # 3. Generate Riddle using LLM
        result_json = generate_riddle_json(req.topic, req.difficulty, retrieved_docs)
        return result_json
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate riddle: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
