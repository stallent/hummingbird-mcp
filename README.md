# hummingbird_mcp

Very basic example of an MCP server using 

- [https://github.com/hummingbird-project/hummingbird](url)
- [https://github.com/modelcontextprotocol/swift-sdk](url)
- [https://github.com/orlandos-nl/SSEKit](url)

# Caveats...

This is not a suggested implementation or design. Purely just the bare minimum to illustrate it working. 
Look at MCPServer.start() function to see how to configure what the server supports.

IMPORTANT! This won't compile on linux yet until an active PR on https://github.com/modelcontextprotocol/swift-sdk is merged.
If that gets delayed for some reason you can just fork swift-sdk and comment out the built in transports since neither is needed
in this use case

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

