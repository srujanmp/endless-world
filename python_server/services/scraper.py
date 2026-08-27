import requests
from bs4 import BeautifulSoup
from ddgs import DDGS

def search_and_scrape(topic: str) -> tuple[str, str]:
    """
    Searches DuckDuckGo for the topic, gets the first HTML link, 
    and scrapes/cleans its content.
    Returns a tuple of (target_url, cleaned_text).
    """
    query = f"{topic} tutorial or explanation"
    target_url = None
    
    # 1. Search using DuckDuckGo
    with DDGS() as ddgs:
        results = ddgs.text(query, max_results=10)
        
    if not results:
        raise Exception("No results found from DuckDuckGo search.")

    for result in results:
        link = result.get("href", "")
        # Skip PDF and DOC files
        if not link or link.lower().endswith((".pdf", ".doc", ".docx")):
            continue
            
        try:
            # 2. Scrape the URL
            page_res = requests.get(link, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}, timeout=5)
            page_res.raise_for_status()
            
            # 3. Clean the HTML using BeautifulSoup
            soup = BeautifulSoup(page_res.text, "html.parser")
            for tag in ["script", "style", "nav", "footer", "iframe"]:
                for el in soup.find_all(tag):
                    el.decompose()
                    
            text = soup.get_text(separator=" ", strip=True)
            cleaned_text = " ".join(text.split())
            
            if len(cleaned_text) > 200: # Ensure we got actual text
                return link, cleaned_text
        except Exception as e:
            print(f"Skipping {link} due to error: {e}")
            continue

    raise Exception("Failed to scrape any suitable HTML results from search.")
