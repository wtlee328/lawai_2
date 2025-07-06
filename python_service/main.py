import ssl
ssl._create_default_https_context = ssl._create_unverified_context

from fastapi import FastAPI, WebSocket, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
# Removed keyword_refinement_workflow import - legacy search functionality
from law_case_search import LawCaseSearchService
import logging
import asyncio
from logging.handlers import QueueHandler
import queue
import os
from typing import Optional



# --- Logging Configuration ---
log_queue = queue.Queue()

# Get the root logger and add our queue handler to it
root_logger = logging.getLogger()
root_logger.addHandler(QueueHandler(log_queue))
root_logger.setLevel(logging.INFO)

# Get a logger for this module
logger = logging.getLogger(__name__)
# --- End of Logging Configuration ---

# Create an instance of the FastAPI class
app = FastAPI()

# --- CORS Configuration ---
# Get allowed origins from environment variable or use defaults
allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# --- End of CORS Configuration ---

# WebSocket endpoint for real-time logging
@app.websocket("/ws/log")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        try:
            log_record = log_queue.get_nowait()
            await websocket.send_text(log_record.getMessage())
        except queue.Empty:
            await asyncio.sleep(0.1)
        except Exception:
            break

# Define a root endpoint
@app.get("/")
def read_root():
    return {"message": "Lawai 2.0 Python Service is running!"}



# Legacy /search endpoint removed - use /new-search instead

# Define the new search endpoint
@app.post("/new-search")
async def new_search_endpoint(request: dict):
    """New search endpoint that uses knowledge base search."""
    query = request.get("query")
    search_methods = request.get("search_methods", ["hybrid"])
    filters = request.get("filters", {})
    limit = request.get("limit", 10)
    
    if not query:
        return {"success": False, "error": "Query not provided"}
    
    logger.info(f"Received new search request with query: {query}, methods: {search_methods}")
    
    try:
        # Initialize the search service
        search_service = LawCaseSearchService()
        
        # Perform the search
        result = await asyncio.to_thread(
            search_service.search, 
            query, 
            search_methods, 
            filters, 
            limit
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Error in new search: {e}", exc_info=True)
        return {
            "success": False, 
            "error": str(e),
            "query": query,
            "search_methods": search_methods
        }



if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
