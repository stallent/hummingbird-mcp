//
//  MCPServerManager.swift
//  hummingbird_mcp
//
//  Created by Stephen Tallent on 5/7/25.
//

import Foundation
import ServiceLifecycle
import MCP

typealias DataStream = AsyncThrowingStream<Data, any Swift.Error>
typealias MCPStream = (stream: DataStream,  continuation: DataStream.Continuation)



actor ServerManager<String: Sendable>: Service {
    
    struct ServerReference {
        let id: ServerID
        let clientStream: MCPStream
        let serverStream: MCPStream
        let server: Server
    }
    
    typealias ServerID = UUID
    
    enum SubscriptionCommand {
        case add(ServerReference)
        case remove(ServerID)
    }
    
    // ------------------------------------
    
    nonisolated private let (subStream, subSource) = AsyncStream<SubscriptionCommand>.makeStream()
    private var servers: [ServerID: ServerReference] = [:]
    

    /// Call to Server
    func sendToServer(id: UUID, message:Data) async throws {
        //guard let ref = servers[id] else { return }
        
       // try await ref.server.sendIntoServer(message: message)
    }
    
    ///  Subscribe to service
    /// - Returns: AsyncStream of values, and subscription identifier
    nonisolated func subscribe() async throws -> ServerReference {
        
        let clientStream:MCPStream = DataStream.makeStream()
        let serverStream:MCPStream = DataStream.makeStream()
        
        let transport = StreamableTransport(clientStream: clientStream,
                                            serverStream: serverStream)
        
        let server:Server = try await Server.configured()
        try await server.start(transport: transport)
        
        let ref = ServerReference(id: ServerID(), clientStream: clientStream, serverStream: serverStream, server: server)
        
        subSource.yield(.add(ref))
        return ref
    }

    ///  Unsubscribe from service
    /// - Parameter id: Subscription identifier
    func unsubscribe(_ id: ServerID) {
        subSource.yield(.remove(id))
    }

    /// Service run function
    func run() async throws {
        try await withGracefulShutdownHandler {
            for try await command in self.subStream {
                switch command {
                    case .add(let ref):
                        self._addSubsciber(ref)
                    case .remove(let id):
                        self._removeSubsciber(id)
                }
            }
        } onGracefulShutdown: {
            self.subSource.finish()
        }
    }

    private func _addSubsciber(_ ref:ServerReference) {
        print("PANTS addSub")
        self.servers[ref.id] = ref
    }

    private func _removeSubsciber(_ id: ServerID) {
        self.servers[id]?.clientStream.continuation.finish()
        self.servers[id]?.serverStream.continuation.finish()
        self.servers[id] = nil
    }
}
