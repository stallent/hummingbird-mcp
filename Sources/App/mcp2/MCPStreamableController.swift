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

extension HTTPField.Name {
    public static var mcpSessionId: Self { HTTPField.Name("Mcp-Session-Id")! }
}

struct MCPStreamableController {
    
    private let mcp = "/streamer"
    
    private let idActor:ServerIDsActor = ServerIDsActor()
    
    init() {}
    
    var endpoints: RouteCollection<AppRequestContext> {
        let routes = RouteCollection(context: AppRequestContext.self)
        
        routes.group("mcp")
            .get("\(mcp)", use: mcpGet)
            .post("\(mcp)", use: mcpPost)
        
        return routes
    }
    
    @Sendable func mcpGet(request: Request, context: AppRequestContext) async throws -> Response {
        return .init(status: .ok)
    }
    
    @Sendable func mcpPost(request: Request, context: AppRequestContext) async throws -> Response {
        guard let accepts = request.headers[HTTPField.Name.accept] else { return .init(status: .notAcceptable)}
        guard accepts.contains("application/json") && accepts.contains("text/event-stream") else { return .init(status: .notAcceptable)}
        
        let body = try await request.body.collect(upTo: .max)
        
                
        let serverRef:ServerRef
        if let ref = await self.idActor.ref(request.headers[.mcpSessionId]) {
            serverRef = ref
        } else {
            serverRef = .init(id: UUID(), server: await Server.configured())
            await self.idActor.addRef(serverRef)
        }
        

        let transport = StreamableTransport(clientStream: DataStream.makeStream(),
                                            serverStream: DataStream.makeStream())
        try await serverRef.server.start(transport: transport)
        
            
        return .init(
            status: .ok,
            headers: [.contentType: "text/event-stream",
                      .mcpSessionId: serverRef.id.uuidString],
            body: .init { writer in
                let allocator = ByteBufferAllocator()
                
                
                // send the message into the server
                transport.serverStream.continuation.yield(Data(buffer: body))

                // get the response
                let result = try await transport.clientStream.stream.first(where: { _ in true })
                
                try await request.body.consumeWithInboundCloseHandler { requestBody in

                    if let r = result, let s = String(data: r, encoding: .utf8) {
                        try await writer.write(
                            ServerSentEvent(data: .init(string: s)).makeBuffer(
                                allocator: allocator
                            )
                        )
                    }
                } onInboundClosed: {}

                await serverRef.server.stop()
                
                try await writer.finish(nil)
            }
        )
        
    }
    
}


struct ServerRef {
    let id: UUID
    let server:Server
}

actor ServerIDsActor {
    var servers:[UUID:ServerRef] = [:]
    
    func addRef(_ ref: ServerRef) {
        servers[ref.id] = ref
    }
    
    func removeRef(_ ref: ServerRef) async throws {
        await ref.server.stop()
        servers[ref.id] = nil
    }
    
    func ref(_ serverID: UUID) -> ServerRef? {
        return servers[serverID]
    }
    
    func ref(_ sessionID: String?) -> ServerRef? {
        guard let serverID = UUID(uuidString: sessionID ?? "") else { return nil }
        
        return servers[serverID]
    }
}
