//
//  Server+Configure.swift
//  hummingbird_mcp
//
//  Created by Stephen Tallent on 5/7/25.
//
import MCP

extension Server {
    
    static func configured() async -> Server {
        
        let server = Server(name: "The Swifties",
                            version: "1.0",
                            capabilities: Server.Capabilities(logging: Server.Capabilities.Logging(),
                                                              prompts: .init(listChanged: true),
                                                              resources: .init(listChanged: true),
                                                              tools: .init(listChanged: true)),
                            configuration: .strict)
        
        
        await server.withMethodHandler(ListTools.self) { id, params  in
            
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
    
        
        await server.withMethodHandler(CallTool.self) { id, params in
            
            switch params.name {
                case "MyTool1":
                
                    try await Task.sleep(for: .seconds(3))
                    try await server.notify(GenericNotification.message(.init(level: "info", data: "mydata")), requestId: id)
                
                    try await Task.sleep(for: .seconds(3))
                    try await server.notify(GenericNotification.message(.init(level: "info", data: "mydata2")), requestId: id)
                
                    try await Task.sleep(for: .seconds(3))
                
                    return CallTool.Result(content: [.text("Tool 1 called with: \(String(describing: params.arguments))")])
                default:
                    throw MCPError.methodNotFound(params.name)
            }
            
        }
    
        await server.withMethodHandler(ListResources.self) { id, params in
            return ListResources.Result(resources: [Resource(name: "MyResource1",
                                                             uri: "cool://resource/bro")])
        }
        
        await server.withMethodHandler(ReadResource.self) { id, params in
            
            switch params.uri {
                case "cool://resource/bro":
                    return ReadResource.Result(contents: [Resource.Content.text("hey", uri: "cool://resource/bro" )])
                
                default:
                    // no clue if this is an approprate error to throw... but YOLO
                    throw MCPError.invalidRequest(params.uri)
            }
        }
        
        return server
        
    }
    
}
