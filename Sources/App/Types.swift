//
//  Types.swift
//  hummingbird_mcp
//
//  Created by Stephen Tallent on 5/13/25.
//
import MCP
 
struct GenericNotification: MCP.Notification, Sendable {
    static var name: String { "notifications/message" }
    public struct Parameters: Hashable, Codable, Sendable {
            let level:String
            let data:String
        }
}


//func startNotifiers() async {
//    do {
//        let timer = AsyncTimerSequence(interval: .seconds(5), clock: ContinuousClock())
//
//        for await tick in timer {
//            for ref in servers.values {
//                if await ref.transport.isGetConnected() {
//                    try await ref.server.notify(GenericNotification.message(.init(level: "info", data: "world \(tick)")))
//                }
//
//            }
//        }
//    } catch {
//
//    }
//}


