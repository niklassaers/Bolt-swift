import Foundation
import XCTest
import PackStream

@testable import Bolt

class SocketTests {
    var settings: ConnectionSettings
    var socket: SocketProtocol
    
    init(socket: SocketProtocol, settings: ConnectionSettings) {
        self.socket = socket
        self.settings = settings
    }
}

extension SocketTests {
    
    // source: http://jexp.de/blog/2014/03/quickly-create-a-100k-neo4j-graph-data-model-with-cypher-only/
    func templateMichaels100k() throws {
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
    
    func templateMichaels100kCannotFitInATransaction() throws {
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
        
        let conn = Connection(socket: socket, settings: settings)
        
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
    
    
    func templateRubbishCypher() throws {
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
    
    func templateUnwind() throws {
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
    
    func templateUnwindWithToNodes() throws {
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
