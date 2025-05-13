//
//  ServerStore.swift
//  hummingbird_mcp
//
//  Created by Stephen Tallent on 5/13/25.
//

import MCP
import Foundation

struct ServerRef {
    let id: UUID
    let server:Server
    let transport:StreamableServerTransport
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
