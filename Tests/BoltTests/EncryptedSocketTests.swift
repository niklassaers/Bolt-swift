import Foundation
import XCTest
import SSLService
import PackStream

@testable import Bolt

fileprivate let kHostname = "localhost"
fileprivate let kPort = 7687
fileprivate let kUsername = "neo4j"
fileprivate let kPasscode = "<passcode>"

class EncryptedSocketTests: XCTestCase {
    
    var socketTests: SocketTests?

    override func setUp() {
        do {
            let configuration = defaultConfiguration()
            let socket = try EncryptedSocket(hostname: kHostname, port: kPort, configuration: configuration)
            let settings = ConnectionSettings(username: kUsername, password: kPasscode, userAgent: "BoltTests")
            self.socketTests = SocketTests(socket: socket, settings: settings)

        } catch {
            XCTFail("Cannot have exceptions during socket initialization")
        }
    }
    
    private func defaultConfiguration() -> SSLService.Configuration {
        
        let dir = "/Users/niklas/Programming/neo/swift/Bolt-swift/keys"
        #if os(Linux)
            
            let myCertFile = "\(dir)/cert.pem"
            let myKeyFile = "\(dir)/key.pem"
            
            let config =  SSLService.Configuration(withCACertificateDirectory: nil,
                                                   usingCertificateFile: myCertFile,
                                                   withKeyFile: myKeyFile,
                                                   usingSelfSignedCerts: true)
        #else // on macOS & iOS
            
            let myCertKeyFile = "\(dir)/cert.pfx"
            
            let config =  SSLService.Configuration(withChainFilePath: myCertKeyFile,
                                                   withPassword: "1234",
                                                   usingSelfSignedCerts: true)
            
        #endif
        
        return config
    }
 
    static var allTests: [(String, (EncryptedSocketTests) -> () throws -> Void)] {
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
