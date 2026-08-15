# FastMCP Server

AI tool/context interface providing MCP-compliant tools and resources for LLM agents to invoke.

## Connecting an MCP Client

An MCP client (such as Claude Desktop, Cursor, or an LLM agent system) can connect to this FastMCP server via SSE or stdio transport:

```json
{
  "mcpServers": {
    "luna-mcp": {
      "command": "python",
      "args": ["-m", "app.main"]
    }
  }
}
```
