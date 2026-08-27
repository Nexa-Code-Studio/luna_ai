import os
from fastmcp import FastMCP

from app.tools.status import get_system_status

mcp = FastMCP("Luna-AI-MCP")

# Register MCP tool
mcp.tool()(get_system_status)

if __name__ == "__main__":
    mcp_port = int(os.environ.get("MCP_PORT", 8889))
    mcp.run(transport="sse", host="0.0.0.0", port=mcp_port)
