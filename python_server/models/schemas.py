from pydantic import BaseModel
from typing import Optional

class ScrapeRequest(BaseModel):
    topic: str

class RAGRequest(BaseModel):
    prompt: str
    topic: Optional[str] = None

class RiddleRequest(BaseModel):
    topic: str
    difficulty: str
