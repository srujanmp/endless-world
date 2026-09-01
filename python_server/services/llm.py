import logging
import os
import json
import time
from groq import Groq
from typing import List
import httpx

logger = logging.getLogger("EndlessWorlds.LLM")

GROQ_API_KEY = os.getenv("GROQ_API_KEY")

# Disable SSL verify to work around proxy/AV HTTPS interception
_http_client = httpx.Client(verify=False)

if GROQ_API_KEY:
    groq_client = Groq(api_key=GROQ_API_KEY, http_client=_http_client)
    logger.info("Groq client initialised — API key loaded (model: openai/gpt-oss-120b)")
else:
    groq_client = None
    logger.warning("Groq client NOT initialised — GROQ_API_KEY is missing from environment")

# ─── Context limits ──────────────────────────────────────────────────────────
# Capping context avoids sending huge scraped pages to the LLM, which burns
# tokens and dramatically slows down response time.
MAX_CONTEXT_CHARS = 4000


def _trim_context(docs: List[str], max_chars: int = MAX_CONTEXT_CHARS) -> str:
    """Join retrieved docs into a single context string, capped at max_chars."""
    joined = "\n---\n".join(docs)
    if len(joined) > max_chars:
        logger.info("  Context trimmed: %d → %d characters (limit: %d)",
                    len(joined), max_chars, max_chars)
        return joined[:max_chars]
    return joined


def generate_rag_reply(prompt: str, retrieved_docs: List[str]) -> str:
    """Generates a reply for a RAG prompt using retrieved document chunks."""
    if not groq_client:
        logger.error("Cannot generate RAG reply — Groq client is not configured")
        raise Exception("GROQ_API_KEY not configured")

    context = _trim_context(retrieved_docs)
    logger.info("Building RAG prompt — %d context chunks, %d context chars",
                len(retrieved_docs), len(context))

    system_prompt = f"""Use the following context to answer the user's question or respond to the prompt.
If you don't know the answer based on the context, say so, but you can use your general knowledge if helpful.

Context:
{context}

User Prompt: {prompt}
"""

    start = time.time()
    logger.info("Sending request to Groq LLM (model: openai/gpt-oss-120b, temp: 0.7)...")

    completion = groq_client.chat.completions.create(
        model="openai/gpt-oss-120b",
        messages=[{"role": "user", "content": system_prompt}],
        temperature=0.7
    )

    elapsed = time.time() - start
    reply = completion.choices[0].message.content
    usage = getattr(completion, "usage", None)

    logger.info("LLM response received in %.2f seconds", elapsed)
    logger.info("  ├─ Reply length : %d characters", len(reply))
    if usage:
        logger.info("  ├─ Tokens (in)  : %s", getattr(usage, "prompt_tokens", "N/A"))
        logger.info("  └─ Tokens (out) : %s", getattr(usage, "completion_tokens", "N/A"))

    return reply


def generate_riddle_json(topic: str, difficulty: str, retrieved_docs: List[str]) -> dict:
    """Generates a riddle JSON payload using the given context and topic."""
    if not groq_client:
        logger.error("Cannot generate riddle — Groq client is not configured")
        raise Exception("GROQ_API_KEY not configured")

    context = _trim_context(retrieved_docs)
    source_context = f"SOURCE MATERIAL:\n{context}" if context else "No source material. Use internal knowledge."
    web_data_condition = "Base it on the SOURCE MATERIAL provided." if context else ""
    source_type = "web" if context else "internal_knowledge"

    logger.info("Building riddle prompt — Topic: \"%s\" | Difficulty: \"%s\" | Source: %s",
                topic, difficulty, source_type)
    logger.info("  Context: %d chunks, %d characters", len(retrieved_docs), len(context))

    prompt = f"""
    SYSTEM: You are a technical question creator. You must follow the Task exactly as written.
    CRITICAL: The "solution" MUST be exactly one of the items in the "options" array.
    {source_context}

    TASK:
    1. Create a question about "{topic}". {web_data_condition}
    2. The "solution" MUST be a single word.
    3. Generate 4 "options" for the user to choose from.
    4. CRITICAL: The "solution" MUST be exactly one of the items in the "options" array.
    5. Difficulty: {difficulty}.
    6. Provide 4 hints exactly.
    7. Topic is given by user so dont make answer as topic itself
    8. insert a new line if the question is longer than 10 words
    9. keep question length less than 50 words
    10. keep the output logically correct
    11. if the topic is not academic related then question should be a riddle
    
    OUTPUT STRICT JSON:
    {{
      "riddle": "string",
      "options": ["opt1", "opt2", "opt3", "opt4"],
      "solution": "string",
      "hints": ["hint1", "hint2", "hint3", "hint4"],
      "fact_reference": "Short sentence explaining the fact used",
      "source": "{source_type}"
    }}
    """

    start = time.time()
    logger.info("Sending riddle request to Groq LLM (model: openai/gpt-oss-120b, temp: 0.5)...")

    completion = groq_client.chat.completions.create(
        model="openai/gpt-oss-120b",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.5,
        response_format={"type": "json_object"}
    )

    elapsed = time.time() - start
    content = completion.choices[0].message.content
    usage = getattr(completion, "usage", None)

    logger.info("LLM response received in %.2f seconds", elapsed)
    if usage:
        logger.info("  ├─ Tokens (in)  : %s", getattr(usage, "prompt_tokens", "N/A"))
        logger.info("  └─ Tokens (out) : %s", getattr(usage, "completion_tokens", "N/A"))

    try:
        result = json.loads(content)
        logger.info("JSON parsed successfully — riddle is ready")
        return result
    except json.JSONDecodeError as e:
        logger.error("Failed to parse LLM response as JSON: %s", str(e))
        logger.error("  Raw response: %s", content[:200])
        raise Exception(f"LLM returned invalid JSON: {str(e)}")

def evaluate_code(question_title: str, question_desc: str, expected_output: str, user_code: str) -> dict:
    if not groq_client:
        logger.error("Cannot evaluate code — Groq client is not configured")
        raise Exception("GROQ_API_KEY not configured")

    prompt = f"""You are a code evaluator for a game. 
Question Title: {question_title}
Question Description: {question_desc}
Expected Output/Behavior: {expected_output}

User Code:
{user_code}

Evaluate the user's code. Does it correctly solve the problem described?
Return a JSON object with exactly two keys:
- "passed": boolean (true if the code logically solves the problem, false otherwise)
- "feedback": string (a short, encouraging 1-2 sentence message explaining what is right or wrong, simulating compiler output).

Output ONLY valid JSON.
"""
    logger.info("Sending code evaluation request to LLM...")
    response = groq_client.chat.completions.create(
        messages=[{"role": "user", "content": prompt}],
        model="openai/gpt-oss-120b",
        temperature=0.0,
        response_format={"type": "json_object"}
    )
    result = response.choices[0].message.content
    try:
        return json.loads(result)
    except Exception as e:
        logger.error("Failed to parse LLM evaluation JSON: %s", str(e))
        return {"passed": False, "feedback": "Evaluation error: " + str(e)}
