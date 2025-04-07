//
//  SSEController.swift
//  HgAIServices
//
//  Created by Stephen Tallent on 3/19/25.
//

//
//  MainController.swift
//  HgAIServices
//
//  Created by Stephen Tallent on 2/19/25.
//

import Logging
import Hummingbird
import Foundation
import HTTPTypes
import ServiceLifecycle
import SSEKit
import MCP

struct MCPController {
    
    private let ssePath = "/sse"
    private let messagesPath = "/messages"
    
    private let mcpServerManager: McpServerManager<String>
    
    init(mcpServerManager: McpServerManager<String>) {
        self.mcpServerManager = mcpServerManager
    }
    
    var endpoints: RouteCollection<AppRequestContext> {
        let routes = RouteCollection(context: AppRequestContext.self)
        
        routes.group("mcp")
            .get("\(ssePath)", use: sse)
            .post("\(messagesPath)", use: messages)
        
        return routes
    }
    
    @Sendable func sse(request: Request, context: AppRequestContext) async throws -> Response {
        // this should trim the /sse and add /messages
        let messagesPath = request.uri.path.dropLast(ssePath.count) + messagesPath
        
        // create an event stream response
        return .init(
            status: .ok,
            headers: [.contentType: "text/event-stream"],
            body: .init { writer in
                let allocator = ByteBufferAllocator()
                
                // create server.  the stream is used for sending things back to client
                // the id is used to send back to the client to use to send subsequent requests
                // back to this specific server.
                let (stream, id, server) = mcpServerManager.subscribe()
                try await server.start()
                
                // inform the client where to send subsequent requests
                let event = ServerSentEvent(type: "endpoint", data: .init(string: "\(messagesPath)?sessionId=\(id)")).makeBuffer( allocator: allocator)
                try await writer.write(event)
                
                // Service magic
                try await withGracefulShutdownHandler {
                    
                    // If connection if closed then this function will call the `onInboundCLosed` closure
                    try await request.body.consumeWithInboundCloseHandler { requestBody in
                        for try await value in stream {
                            guard let dataString = String(data: value, encoding: .utf8) else { continue }
                            try await writer.write(
                                ServerSentEvent(data: .init(string: dataString)).makeBuffer(
                                    allocator: allocator
                                )
                            )
                        }
                    } onInboundClosed: {
                        mcpServerManager.unsubscribe(id)
                    }
                } onGracefulShutdown: {
                    mcpServerManager.unsubscribe(id)
                }

                try await writer.finish(nil)
            }
        )
    }
    
    
    @Sendable func messages(request: Request, context: AppRequestContext) async throws -> Response {
        let sessionId =  try request.uri.queryParameters.require("sessionId", as: UUID.self)
        let body = try await request.body.collect(upTo: .max)

        try await self.mcpServerManager.sendToServer(id: sessionId, message: Data(buffer: body))
        
        return Response.init(status: .accepted)
    }
    
}

