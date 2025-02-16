from typing import Any, Optional
from valyu import Valyu, SearchResponse
from mcp.server.fastmcp import FastMCP
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    force=True
)
logger = logging.getLogger(__name__)

mcp = FastMCP("valyu-mcp")
valyu = None

async def make_valyu_request(query: str, max_num_results: int = 10, max_price: int = 10) -> Optional[SearchResponse]:
    """
    Initiates a request to the Valyu API, incorporating error handling and logging for debugging purposes.

    Parameters:
    - query (str): The search query to be sent to the Valyu API.
    - max_num_results (int, optional): The maximum number of results to be returned. Defaults to 10.
    - max_price (int, optional): The maximum price for the results. Defaults to 10.

    Returns:
    - Optional[SearchResponse]: The response received from the Valyu API or None if an error occurs.
    """
    try:
        logger.info(f"Making Valyu request - query: {query}, max_results: {max_num_results}, max_price: {max_price}")
        response = valyu.context(query=query, search_type="all", max_num_results=max_num_results, max_price=max_price)
        logger.info(f"Received Valyu response: {response}")
        return response
    except Exception as e:
        logger.error(f"Error making Valyu request: {str(e)}")
        return None
    
def format_valyu_results(data: SearchResponse) -> str:
    """
    Formats the Valyu context results for feeding back to the model as context.

    Parameters:
    - data (SearchResponse): The SearchResponse object received from the Valyu API.

    Returns:
    - str: A formatted string containing the Valyu context results.
    """
    if not data.results:
        return "No results found."

    results = []
    for i, result in enumerate(data.results, 1):
        results.append(
            f"""Title: {result.title}
Content: {result.content or result.description}
URL: {result.url}"""
        )

    formatted_output = "\n\n".join(results)
    return formatted_output


@mcp.tool()
async def valyu_context(query: str, max_num_results: int = 10) -> str:
    """
    Retrieves context using the Valyu API.
    """
    logger.info(f"Starting valyu_context tool call - query: {query}, max_results: {max_num_results}")
    
    try:
        # Ensure count is within bounds but keep it smaller for faster responses
        max_num_results = min(max(1, max_num_results), 5)  # Reduced from 20 to 5

        data = await make_valyu_request(query, max_num_results, 10)
        if not data:
            logger.error("Failed to get Valyu response")
            return f"Unable to fetch context from Valyu 🫠 Skill issue."

        formatted_results = format_valyu_results(data)
        logger.info(f"Successfully formatted {len(data.results)} results")
        return formatted_results
        
    except Exception as e:
        logger.error(f"Error in valyu_context: {str(e)}")
        return f"Error executing valyu_context: {str(e)}"

if __name__ == "__main__":
    import os

    VALYU_API_KEY = os.getenv("VALYU_API_KEY")
    if not VALYU_API_KEY:
        logger.error("Error: VALYU_API_KEY environment variable is required")
        exit(1)

    try:
        valyu = Valyu(api_key=VALYU_API_KEY)
        logger.info("Server initialized successfully with Valyu API key")

        # Initialize and run the server using stdio transport
        mcp.run(transport='stdio')
    except Exception as e:
        logger.error(f"Fatal error running MCP server: {str(e)}")
        exit(1)