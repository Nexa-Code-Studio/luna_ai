from fastmcp import FastMCP

from app.tools.status import get_system_status

mcp = FastMCP("Luna-AI-MCP")

# Register MCP tool
mcp.tool()(get_system_status)

if __name__ == "__main__":
    mcp.run(transport="sse", host="0.0.0.0", port=8001)
