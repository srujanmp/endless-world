import logging
import time
import requests
from bs4 import BeautifulSoup
from ddgs import DDGS
import urllib3

# Suppress the InsecureRequestWarning since we intentionally disable SSL verify
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

logger = logging.getLogger("EndlessWorlds.Scraper")


def search_and_scrape(topic: str) -> tuple[str, str]:
    """
    Searches DuckDuckGo for the topic, gets the first HTML link,
    and scrapes/cleans its content.
    Returns a tuple of (target_url, cleaned_text).
    """
    query = f"{topic} tutorial or explanation"
    logger.info("Searching DuckDuckGo — query: \"%s\"", query)
    start = time.time()

    # 1. Search using DuckDuckGo (SSL verify disabled for proxy/AV compat)
    with DDGS(verify=False) as ddgs:
        results = ddgs.text(query, max_results=10)

    search_time = time.time() - start

    if not results:
        logger.warning("No results returned from DuckDuckGo (took %.2fs)", search_time)
        raise Exception("No results found from DuckDuckGo search.")

    logger.info("DuckDuckGo returned %d results in %.2f seconds", len(results), search_time)

    for i, result in enumerate(results, 1):
        link = result.get("href", "")
        title = result.get("title", "No title")

        # Skip PDF and DOC files
        if not link or link.lower().endswith((".pdf", ".doc", ".docx")):
            logger.info("  [%d/%d] Skipped (non-HTML file): %s", i, len(results), link)
            continue

        logger.info("  [%d/%d] Attempting to scrape: %s", i, len(results), link)
        logger.info("         Title: %s", title)

        try:
            # 2. Scrape the URL (SSL verify disabled for proxy/AV compat)
            scrape_start = time.time()
            page_res = requests.get(
                link,
                headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"},
                timeout=5,
                verify=False,
            )
            page_res.raise_for_status()
            scrape_time = time.time() - scrape_start
            logger.info("         Fetched in %.2fs — HTTP %d — %d bytes",
                        scrape_time, page_res.status_code, len(page_res.content))

            # 3. Clean the HTML using BeautifulSoup
            soup = BeautifulSoup(page_res.text, "html.parser")
            for tag in ["script", "style", "nav", "footer", "iframe"]:
                for el in soup.find_all(tag):
                    el.decompose()

            text = soup.get_text(separator=" ", strip=True)
            cleaned_text = " ".join(text.split())

            if len(cleaned_text) > 200:
                total_time = time.time() - start
                logger.info("         ✔ Cleaned text: %d characters (usable)", len(cleaned_text))
                logger.info("Scrape succeeded — total time: %.2f seconds", total_time)
                return link, cleaned_text
            else:
                logger.info("         ✗ Cleaned text too short (%d chars), skipping", len(cleaned_text))

        except requests.exceptions.Timeout:
            logger.warning("         ✗ Request timed out after 5 seconds")
            continue
        except requests.exceptions.HTTPError as e:
            logger.warning("         ✗ HTTP error: %s", str(e))
            continue
        except Exception as e:
            logger.warning("         ✗ Unexpected error: %s", str(e))
            continue

    total_time = time.time() - start
    logger.error("All %d search results failed after %.2f seconds", len(results), total_time)
    raise Exception("Failed to scrape any suitable HTML results from search.")
