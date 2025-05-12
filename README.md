# hummingbird_mcp

Very basic example of an MCP server using 

- [https://github.com/hummingbird-project/hummingbird](url)
- [https://github.com/modelcontextprotocol/swift-sdk](url)
- [https://github.com/orlandos-nl/SSEKit](url)

Current code is purely for working out streaming server support.


## Running...

Run like you would any hummingbird app

``` 
swift run HummingbirdMCP
```

run the standard MCP Inspector
 
```
npx @modelcontextprotocol/inspector
```

Set transport type to SSE and connect to:
http://127.0.0.1:8080/mcp/streamer

