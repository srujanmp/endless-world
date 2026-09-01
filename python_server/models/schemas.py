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

class EvaluateRequest(BaseModel):
    question_title: str
    question_desc: str
    expected_output: str
    user_code: str
