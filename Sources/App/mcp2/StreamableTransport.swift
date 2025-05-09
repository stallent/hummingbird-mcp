//
//  StreamableTransport.swift
//  hummingbird_mcp
//
//  Created by Stephen Tallent on 5/8/25.
//

import Foundation
import Logging
import MCP

actor StreamableTransport : Transport {

    var logger: Logging.Logger
    
    let clientStream: MCPStream
    let serverStream: MCPStream
    
    init(clientStream:MCPStream, serverStream:MCPStream) {
        self.logger = Logging.Logger(label: "SSETransport")
       
        self.clientStream = clientStream
        self.serverStream = serverStream
    }
    
    func connect() async throws {}
    
    func disconnect() async {}
    
    func send(_ data: Data) async throws {
        self.clientStream.continuation.yield(data)
    }
    
    func receive() -> AsyncThrowingStream<Data, any Swift.Error> {
        return serverStream.stream
    }
}
