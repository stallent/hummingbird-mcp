//
//  McServer.swift
//  HgAIServices
//
//  Created by Stephen Tallent on 3/22/25.
//
import MCP
import Logging
import Foundation

actor MCPServer {
    
    let server: Server
    let transport: SSETransport

    init(sendToClientContinuation:AsyncStream<Data>.Continuation) {
        
        
        self.server = Server(name: "The Swifties",
                             version: "1.0",
                             capabilities: Server.Capabilities(logging: nil,
                                                               prompts: nil,
                                                               resources: .init(listChanged: false),
                                                               tools: .init(listChanged: false)))
        
        self.transport = SSETransport(sendToClientContinuation: sendToClientContinuation)
        
    }
    
    func start() async throws {
        await self.server.withMethodHandler(ListTools.self) { context in
            
            let tool1Schema: [String: Value] = ["properties":
                                                    ["param1": ["description": "An example parameter",
                                                                "type": "string"]],
                                                "$schema": "http://json-schema.org/draft-07/schema#",
                                                "additionalProperties": false,
                                                "required": ["param1"],
                                                "type": "object"]
            
            let myTool1 = Tool(name: "MyTool1",
                              description: "Something something, tool, something something",
                              inputSchema: .object(tool1Schema))
            
            
            return ListTools.Result(tools: [myTool1])
        }
    
        
        await self.server.withMethodHandler(CallTool.self) { context in
            
            switch context.name {
                case "MyTool1":
                    return CallTool.Result(content: [.text("Tool 1 called with: \(String(describing: context.arguments))")])
                default:
                    throw MCPError.methodNotFound(context.name)
            }
            
        }
    
        await self.server.withMethodHandler(ListResources.self) { context in
            return ListResources.Result(resources: [Resource(name: "MyResource1",
                                                             uri: "cool://resource/bro")])
        }
        
        await self.server.withMethodHandler(ReadResource.self) { context in
            
            switch context.uri {
                case "cool://resource/bro":
                    return ReadResource.Result(contents: [Resource.Content.text("hey", uri: "cool://resource/bro" )])
                
                default:
                    // no clue if this is an approprate error to throw... but YOLO
                    throw MCPError.invalidRequest(context.uri)
            }
        }
        
        try await self.server.start(transport: self.transport)
    }
    
    func sendIntoServer(message:Data) async throws {
        try await self.transport.sendToServer(message)
    }
}



actor SSETransport : Transport {
    
    var logger: Logging.Logger
    
    private var sendToClientContinuation:AsyncStream<Data>.Continuation
    
    private let messageStream: AsyncThrowingStream<Data, Swift.Error>
    private let messageContinuation: AsyncThrowingStream<Data, Swift.Error>.Continuation
    
    init(sendToClientContinuation:AsyncStream<Data>.Continuation) {
        
        self.sendToClientContinuation = sendToClientContinuation
        
        // Create message stream
        var continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation!
        self.messageStream = AsyncThrowingStream { continuation = $0 }
        self.messageContinuation = continuation
        
        self.logger = Logging.Logger(label: "SSETransport")
    }
    
    // These are not needed for a hummingbird implementation
    func connect() async throws {}
    func disconnect() async {}
    
    // in this context this needs to get piped out back to the client
    func send(_ message: Data) async throws {
        self.sendToClientContinuation.yield(message)
    }
    
    func sendToServer(_ message: Data) async throws {
        self.messageContinuation.yield(message)
    }
    
    func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await message in messageStream {
                        continuation.yield(message)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}
