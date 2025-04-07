import Foundation
import ServiceLifecycle


actor McpServerManager<String: Sendable>: Service {
    
    struct ServerReference {
        let id: ServerID
        let continuation: AsyncStream<Data>.Continuation
        let server: MCPServer
    }
    
    typealias ServerID = UUID
    
    enum SubscriptionCommand {
        case add(ServerID, AsyncStream<Data>.Continuation, MCPServer)
        case remove(ServerID)
    }
    
    nonisolated let (subStream, subSource) = AsyncStream<SubscriptionCommand>.makeStream()
    private var servers: [ServerID: ServerReference] = [:]
    
    init() {
        self.servers = [:]
    }


    func publishToServer(id:String, value: Data) async {
        for server in self.servers.values {
            server.continuation.yield(value)
        }
    }
    
    /// Call to Server
    func sendToServer(id: UUID, message:Data) async throws {
        guard let ref = servers[id] else { return }
        
        try await ref.server.sendIntoServer(message: message)
    }
    
    ///  Subscribe to service
    /// - Returns: AsyncStream of values, and subscription identifier
    nonisolated func subscribe() -> (AsyncStream<Data>, ServerID, MCPServer) {
        let id = ServerID()
        let (stream, source) = AsyncStream<Data>.makeStream()
        let server = MCPServer(sendToClientContinuation: source)
        subSource.yield(.add(id, source, server))
        return (stream, id, server)
    }

    ///  Unsubscribe from service
    /// - Parameter id: Subscription identifier
    nonisolated func unsubscribe(_ id: ServerID) {
        subSource.yield(.remove(id))
    }

    /// Service run function
    func run() async throws {
        try await withGracefulShutdownHandler {
            for try await command in self.subStream {
                switch command {
                    case .add(let id, let source, let mcServer):
                        self._addSubsciber(id, source: source, mcpServer: mcServer)
                    case .remove(let id):
                        self._removeSubsciber(id)
                }
            }
        } onGracefulShutdown: {
            self.subSource.finish()
        }
    }

    private func _addSubsciber(_ id: ServerID, source: AsyncStream<Data>.Continuation, mcpServer:MCPServer) {
        self.servers[id] = ServerReference(id: id, continuation: source, server: mcpServer)
    }

    private func _removeSubsciber(_ id: ServerID) {
        self.servers[id]?.continuation.finish()
        self.servers[id] = nil
    }
}
