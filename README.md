# hummingbird_mcp

Very basic example of an MCP server using 

- [https://github.com/hummingbird-project/hummingbird](url)
- [https://github.com/modelcontextprotocol/swift-sdk](url)
- [https://github.com/orlandos-nl/SSEKit](url)


note: currently using a fork of `modelcontextprotocol/swift-sdk` that adds needed code to support this. Will update as it makes its way back into main repo

## Running...

Run the example app as you would any hummingbird app

``` 
swift run ExampleMCPApp
```

run the standard MCP Inspector
 
```
npx @modelcontextprotocol/inspector
```

Set transport type to Streamable HTTP and connect to:
http://127.0.0.1:8080/mcp/streamer


Usage:

```swift
    router.addRoutes(
        StreamableMCPController(path:"mcp/streamer",
                                stateful: true,
                                jsonResponses: false) {
                                    return await Server.configured()
                                }.endpoints
    )
```

The closure is how a server instance is created.
