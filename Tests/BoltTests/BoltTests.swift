import XCTest
import PackStream

#if os(Linux)
    import Dispatch
#endif

@testable import Bolt

fileprivate let kHostname = "localhost"
fileprivate let kUsername = "neo4j"
fileprivate let kPasscode = "<passcode>"

class bolt_swiftTests: XCTestCase {
    
    func testConnection() throws {
        let connectionExp = expectation(description: "Login successful")

        let settings = ConnectionSettings(username: kUsername, password: kPasscode)
        let conn = try Connection(hostname: kHostname, settings: settings)
        try conn.connect { (success) in
            do {
                if success == true {
                    connectionExp.fulfill()
                    let _ = try self.createNode(connection: conn)
                }
            } catch(let error) {
                XCTFail("Did not expect any errors, but got \(error)")
            }
        }

        self.waitForExpectations(timeout: 300000) { (_) in
            print("Done")
        }

    }

    func createNode(connection conn: Connection) throws -> XCTestExpectation {

        let cypherExp = expectation(description: "Perform cypher query")

        let statement = "CREATE (n:FirstNode {name:{name}}) RETURN n"
        let parameters = Map(dictionary: [ "name": "Steven" ])
        let request = Request.run(statement: statement, parameters: parameters)
        try conn.request(request) { (success, _) in
            do {
                if success {
                    cypherExp.fulfill()
                    let _ = try self.pullResults(connection: conn)
                }
            } catch(let error) {
                XCTFail("Did not expect any errors, but got \(error)")
            }
        }

        return cypherExp
    }

    func pullResults(connection conn: Connection) throws -> XCTestExpectation {

        let pullAllExp = expectation(description: "Perform pull All")

        let request = Request.pullAll()
        print("pull all")
        try conn.request(request) { (success, responses) in
            print("got result \(success)")
            if responses.count > 0 && success == true {
                pullAllExp.fulfill()
            }
        }

        return pullAllExp
    }

    static var allTests: [(String, (bolt_swiftTests) -> () throws -> Void)] {
        return [
            ("testConnection", testConnection),
            ("testUnpackInitResponse", testUnpackInitResponse),
            ("testUnpackEmptyRequestResponse", testUnpackEmptyRequestResponse),
            ("testUnpackRequestResponseWithNode", testUnpackRequestResponseWithNode),
            ("testUnpackPullAllRequestAfterCypherRequest", testUnpackPullAllRequestAfterCypherRequest),
            ("testMichaels100k", testMichaels100k),
            ("testMichaels100kCannotFitInATransaction", testMichaels100kCannotFitInATransaction),
            ("testRubbishCypher", testRubbishCypher),
            ("testUnwind", testUnwind),
            ("testUnwindWithToNodes", testUnwindWithToNodes),
        ]
    }

    func testUnpackInitResponse() throws {
        let bytes: [Byte] = [0xb1, 0x70, 0xa1, 0x86, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x8b, 0x4e, 0x65, 0x6f, 0x34, 0x6a, 0x2f, 0x33, 0x2e, 0x31, 0x2e, 0x31]
        let response = try Response.unpack(bytes)

        // Expected: SUCCESS
        // server: Neo4j/3.1.1

        XCTAssertEqual(response.category, .success)
        XCTAssertEqual(1, response.items.count)
        guard let properties = response.items[0] as? Map else {
                XCTFail("Response metadata should be a Map")
                return
        }

        XCTAssertEqual(1, properties.dictionary.count)
        XCTAssertEqual("Neo4j/3.1.1", properties.dictionary["server"] as! String)
    }

    func testUnpackEmptyRequestResponse() throws {
        let bytes: [Byte] = [0xb1, 0x70, 0xa2, 0xd0, 0x16, 0x72, 0x65, 0x73, 0x75, 0x6c, 0x74, 0x5f, 0x61, 0x76, 0x61, 0x69, 0x6c, 0x61, 0x62, 0x6c, 0x65, 0x5f, 0x61, 0x66, 0x74, 0x65, 0x72, 0x1, 0x86, 0x66, 0x69, 0x65, 0x6c, 0x64, 0x73, 0x90]
        let response = try Response.unpack(bytes)

        XCTAssertEqual(response.category, .success)

        // Expected: SUCCESS
        // result_available_after: 1 (ms)
        // fields: [] (empty List)

        XCTAssertEqual(response.category, .success)
        XCTAssertEqual(1, response.items.count)
        guard let properties = response.items[0] as? Map,
            let fields = properties.dictionary["fields"] as? List else {
                XCTFail("Response metadata should be a Map")
                return
        }

        XCTAssertEqual(0, fields.items.count)
        XCTAssertEqual(1, properties.dictionary["result_available_after"]?.asUInt64())

    }

    func testUnpackRequestResponseWithNode() throws {
        let bytes: [Byte] = [0xb1, 0x70, 0xa2, 0xd0, 0x16, 0x72, 0x65, 0x73, 0x75, 0x6c, 0x74, 0x5f, 0x61, 0x76, 0x61, 0x69, 0x6c, 0x61, 0x62, 0x6c, 0x65, 0x5f, 0x61, 0x66, 0x74, 0x65, 0x72, 0x2, 0x86, 0x66, 0x69, 0x65, 0x6c, 0x64, 0x73, 0x91, 0x81, 0x6e]
        let response = try Response.unpack(bytes)

        // Expected: SUCCESS
        // result_available_after: 2 (ms)
        // fields: ["n"]

        XCTAssertEqual(response.category, .success)
        XCTAssertEqual(1, response.items.count)
        guard let properties = response.items[0] as? Map,
              let fields = properties.dictionary["fields"] as? List else {
            XCTFail("Response metadata should be a Map")
            return
        }

        XCTAssertEqual(1, fields.items.count)
        XCTAssertEqual("n", fields.items[0] as! String)
        XCTAssertEqual(2, properties.dictionary["result_available_after"]?.asUInt64())

    }

    func testUnpackPullAllRequestAfterCypherRequest() throws {
        let bytes: [Byte] = [0xb1, 0x71, 0x91, 0xb3, 0x4e, 0x12, 0x91, 0x89, 0x46, 0x69, 0x72, 0x73, 0x74, 0x4e, 0x6f, 0x64, 0x65, 0xa1, 0x84, 0x6e, 0x61, 0x6d, 0x65, 0x86, 0x53, 0x74, 0x65, 0x76, 0x65, 0x6e]
        let response = try Response.unpack(bytes)

        // Expected: Record with one Node (ID 18)
        // label: FirstNode
        // props: "name" = "Steven"

        XCTAssertEqual(response.category, .record)
        guard let node = response.asNode() else {
            XCTFail("Expected response to be a node")
            return
        }

        XCTAssertEqual(18, node.id)
        XCTAssertEqual(1, node.labels.count)
        XCTAssertEqual("FirstNode", node.labels[0])
        XCTAssertEqual(1, node.properties.count)
        let (propertyKey, propertyValue) = node.properties.first!
        XCTAssertEqual("name", propertyKey)
        XCTAssertEqual("Steven", propertyValue as! String)
    }

    // source: http://jexp.de/blog/2014/03/quickly-create-a-100k-neo4j-graph-data-model-with-cypher-only/
    func testMichaels100k() throws {
        let stmt1 = "WITH [\"Andres\",\"Wes\",\"Rik\",\"Mark\",\"Peter\",\"Kenny\",\"Michael\",\"Stefan\",\"Max\",\"Chris\"] AS names " +
                    "FOREACH (r IN range(0,100000) | CREATE (:User {id:r, name:names[r % size(names)]+\" \"+r}))"
        let stmt2 = "with [\"Mac\",\"iPhone\",\"Das Keyboard\",\"Kymera Wand\",\"HyperJuice Battery\",\"Peachy Printer\",\"HexaAirBot\"," +
                    "\"AR-Drone\",\"Sonic Screwdriver\",\"Zentable\",\"PowerUp\"] as names " +
                    "foreach (r in range(0,50) | create (:Product {id:r, name:names[r % size(names)]+\" \"+r}))"
        let stmt3 = "match (u:User),(p:Product) with u,p limit 500000 where rand() < 0.1 create (u)-[:OWN]->(p)"
        let stmt4 = "match (u:User),(p:Product)\n" +
                    "with u,p\n" +
                    "// increase skip value from 0 to 4M in 1M steps\n" +
                    "skip 1000000\n" +
                    "limit 5000000\n" +
                    "where rand() < 0.1\n" +
                    "with u,p\n" +
                    "limit 100000\n" +
                    "merge (u)-[:OWN]->(p);"
        let stmt5 = "create index on :User(id)"
        let stmt6 = "create index on :Product(id)"
        let stmt7 = "match (u:User {id:1})-[:OWN]->()<-[:OWN]-(other)\n" +
                    "return other.name,count(*)\n" +
                    "order by count(*) desc\n" +
                    "limit 5;"
        let stmt8 = "match (u:User {id:3})-[:OWN]->()<-[:OWN]-(other)-[:OWN]->(p) " +
                    "return p.name,count(*) " +
                    "order by count(*) desc " +
                    "limit 5;"

        try performAsLoggedIn { (conn, dispatchGroup) in

            for statement in [ stmt1, stmt2, stmt3, stmt4, stmt5, stmt6, stmt7, stmt8 ] {
                
                let request = Request.run(statement: statement, parameters: Map(dictionary: [:]))
                dispatchGroup.enter()
                try conn.request(request) { (success, responses) in
                    
                    if success == false || responses.count == 0 {
                        XCTFail("Unexpected response")
                    }
                    
                    let request = Request.pullAll()
                    do {
                        try conn.request(request) { (success, responses) in
                            if success == false || responses.count == 0 {
                                XCTFail("Unexpected response")
                            }
                            dispatchGroup.leave()
                        }
                    } catch(let error) {
                        print("Unexpected error while pulling: \(error)")
                    }
                    
                }
            }
            
        }

    }
    
    func testMichaels100kCannotFitInATransaction() throws {
        let stmt1 = "WITH [\"Andres\",\"Wes\",\"Rik\",\"Mark\",\"Peter\",\"Kenny\",\"Michael\",\"Stefan\",\"Max\",\"Chris\"] AS names " +
        "FOREACH (r IN range(0,100000) | CREATE (:User {id:r, name:names[r % size(names)]+\" \"+r}))"
        let stmt2 = "create index on :User(id)"
        
        try performAsLoggedIn { (conn, dispatchGroup) in
            do {
                for statement in [ "BEGIN", stmt1, stmt2, "ROLLBACK" ] {
                    
                    if statement == "ROLLBACK" {
                        XCTFail("Should never get here")
                    }
                    
                    let request = Request.run(statement: statement, parameters: Map(dictionary: [:]))
                    dispatchGroup.enter()
                    try conn.request(request) { (success, responses) in
                        defer {
                            dispatchGroup.leave()
                        }
                        
                        let request = Request.pullAll()
                        dispatchGroup.enter()
                        do {
                            try conn.request(request) { (success, responses) in
                                dispatchGroup.leave()
                            }
                        } catch(let error) {
                            dispatchGroup.leave()
                            print("Unexpected error while pulling: \(error)")
                        }
                    }
                }
            } catch (let error) {
                dispatchGroup.leave()

                switch error {
                case let Response.ResponseError.forbiddenDueToTransactionType(message):
                    XCTAssertEqual("Cannot perform schema updates in a transaction that has performed data updates.", message)
                default:
                    XCTFail("Expected a response error")
                }
            }
            
        }
    }
    
    func performAsLoggedIn(block: @escaping (Connection, DispatchGroup) throws -> ()) throws {

        let settings = ConnectionSettings(username: kUsername, password: kPasscode)
        let conn = try Connection(hostname: kHostname, settings: settings)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        try conn.connect { success in
            defer {
                dispatchGroup.leave()
            }

            XCTAssertTrue(success, "Must be logged in successfully")

            try block(conn, dispatchGroup)
        }
        dispatchGroup.wait()
    }

    
    func testRubbishCypher() throws {
        let stmt = "42"
        
        try performAsLoggedIn { (conn, dispatchGroup) in

            let request = Request.run(statement: stmt, parameters: Map(dictionary: [:]))
            dispatchGroup.enter()
            do {
                try conn.request(request) { (success, responses) in
                    
                    XCTFail("Unexpected response")
                    dispatchGroup.leave()
                }
            } catch {
                // Happy path
                dispatchGroup.leave()
            }
        }
    }
    
    func testUnwind() throws {
        let stmt = "UNWIND RANGE(1, 10) AS n RETURN n"

        try performAsLoggedIn { (conn, dispatchGroup) in
            
            let request = Request.run(statement: stmt, parameters: Map(dictionary: [:]))
            dispatchGroup.enter()
            try conn.request(request) { (success, responses) in
                defer {
                    dispatchGroup.leave()
                }
                
                let request = Request.pullAll()
                dispatchGroup.enter()
                try conn.request(request) { (success, responses) in
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    XCTAssertTrue(success)
                    
                    let records = responses.filter { $0.category == .record }
                    XCTAssertEqual(10, records.count)
                }
                
            }
            
        }
        
    }
    
    func testUnwindWithToNodes() throws {
        let stmt = "UNWIND RANGE(1, 10) AS n RETURN n, n * n as n_sq"
        
        try performAsLoggedIn { (conn, dispatchGroup) in
            
            let request = Request.run(statement: stmt, parameters: Map(dictionary: [:]))
            dispatchGroup.enter()
            try conn.request(request) { (success, responses) in
                defer {
                    dispatchGroup.leave()
                }
                
                XCTAssertEqual(1, responses.count)
                let fields = (responses[0].items[0] as! Map).dictionary["fields"] as! List
                XCTAssertEqual(2, fields.items.count)
                
                let request = Request.pullAll()
                dispatchGroup.enter()
                try conn.request(request) { (success, responses) in
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    XCTAssertTrue(success)
                    
                    let records = responses.filter { $0.category == .record && ($0.items[0] as! List).items.count == 2 }
                    XCTAssertEqual(10, records.count)
                }
                
            }
        }
        
    }

}

struct Node {
    
    public let id: UInt64
    public let labels: [String]
    public let properties: [String: PackProtocol]
    
}


extension Response {
    func asNode() -> Node? {
        if category != .record ||
            items.count != 1 {
            return nil
        }
        
        let list = items[0] as? List
        guard let items = list?.items,
            items.count == 1,
            
            let structure = items[0] as? Structure,
            structure.signature == Response.RecordType.node,
            structure.items.count == 3,
            
            let nodeId = structure.items.first?.asUInt64(),
            let labelList = structure.items[1] as? List,
            let labels = labelList.items as? [String],
            let propertyMap = structure.items[2] as? Map
            else {
                return nil
        }
        
        let properties = propertyMap.dictionary
        
        let node = Node(id: UInt64(nodeId), labels: labels, properties: properties)
        return node
    }
}
