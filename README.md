# hummingbird_mcp

Very basic example of an MCP server using 

- [https://github.com/hummingbird-project/hummingbird](url)
- [https://github.com/modelcontextprotocol/swift-sdk](url)
- [https://github.com/orlandos-nl/SSEKit](url)

# Caveats...

This is not a suggested implementation or design. Purely just the bare minimum to illustrate it working. 
Look at MCPServer.start() function to see how to configure what the server supports.

## Running...

Run like you would any hummingbird app

``` 
run HummingbirdMCP
```

run the standard MCP Inspector
 
```
npx @modelcontextprotocol/inspector
```

Set transport type to SSE and connect to:
http://127.0.0.1:8080/mcp/sse 

