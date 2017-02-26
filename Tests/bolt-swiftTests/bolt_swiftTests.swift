import XCTest
import packstream_swift

@testable import bolt_swift

class bolt_swiftTests: XCTestCase {
    func testConnection() throws {
        let connectionExp = expectation(description: "Login successful")
        let cypherExp = expectation(description: "Perform cypher query")
        
        let settings = ConnectionSettings(username: "neo4j", password: "<passcode>", userAgent: "Bah")
        let conn = SwiftSocketConnection(hostname: "localhost", settings: settings)
        try conn.connect() { (success) in
            if success == true {
                connectionExp.fulfill()
                let statement = "CREATE (n:FirstNode {name:{name}})" // RETURN n
                let parameters = Map(dictionary: [ "name": "Steven" ])
                let request = Message.run(statement: statement, parameters: parameters)
                do {
                    try conn.request(request) { success in
                        if success {
                            cypherExp.fulfill()
                        }
                    }
                } catch {
                    // poop
                }
                
            }
        }
        
        self.waitForExpectations(timeout: 300000) { (error) in
            print("Done")
        }
    }


    static var allTests : [(String, (bolt_swiftTests) -> () throws -> Void)] {
        return [
            ("testExample", testConnection),
        ]
    }
    
    func testUnpackStructure() throws {
        let bytes: [Byte] = [0xb1, 0x70, 0xa1, 0x86, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x8b, 0x4e, 0x65, 0x6f, 0x34, 0x6a, 0x2f, 0x33, 0x2e, 0x31, 0x2e, 0x31]
        let response = try Response.unpack(bytes)
    }
    
    func testUnpackResponse() throws {
        let bytes: [Byte] = [0xb1, 0x70, 0xa2, 0xd0, 0x16, 0x72, 0x65, 0x73, 0x75, 0x6c, 0x74, 0x5f, 0x61, 0x76, 0x61, 0x69, 0x6c, 0x61, 0x62, 0x6c, 0x65, 0x5f, 0x61, 0x66, 0x74, 0x65, 0x72, 0x1, 0x86, 0x66, 0x69, 0x65, 0x6c, 0x64, 0x73, 0x90]
        let response = try Response.unpack(bytes)
        
        // Expected:
        // result_available_after: 1 (ms)
        // fields: [] (empty List)
    }
}
