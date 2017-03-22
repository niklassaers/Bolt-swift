import Foundation
import XCTest
import PackStream

@testable import Bolt

fileprivate let kHostname = "localhost"
fileprivate let kPort = 7687
fileprivate let kUsername = "neo4j"
fileprivate let kPasscode = "<passcode>"

class UnencryptedSocketTests: XCTestCase {
    
    var socketTests: SocketTests?
    
    override func setUp() {
        do {
            let socket = try UnencryptedSocket(hostname: kHostname, port: kPort)
            let settings = ConnectionSettings(username: kUsername, password: kPasscode, userAgent: "BoltTests")
            
            self.socketTests = SocketTests(socket: socket, settings: settings)
            
        } catch {
            XCTFail("Cannot have exceptions during socket initialization")
        }
    }
    
    static var allTests: [(String, (UnencryptedSocketTests) -> () throws -> Void)] {
        return [
            ("testMichaels100k", testMichaels100k),
            ("testMichaels100kCannotFitInATransaction", testMichaels100kCannotFitInATransaction),
            ("testRubbishCypher", testRubbishCypher),
            ("testUnwind", testUnwind),
            ("testUnwindWithToNodes", testUnwindWithToNodes),
        ]
    }
    
    func testMichaels100k() throws {
        XCTAssertNotNil(socketTests)
        try socketTests?.templateMichaels100k()
    }
    
    func testMichaels100kCannotFitInATransaction() throws {
        XCTAssertNotNil(socketTests)
        try socketTests?.templateMichaels100kCannotFitInATransaction()
    }
    
    func testRubbishCypher() throws {
        XCTAssertNotNil(socketTests)
        try socketTests?.templateRubbishCypher()
    }
    
    func testUnwind() throws {
        XCTAssertNotNil(socketTests)
        try socketTests?.templateUnwind()
    }
    
    func testUnwindWithToNodes() throws {
        XCTAssertNotNil(socketTests)
        try socketTests?.templateUnwindWithToNodes()
    }
    
}

