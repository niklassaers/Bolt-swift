import Foundation
import PackStream
import Socket
import SSLService

class EncryptedSocket {
    
    let hostname: String
    let port: Int
    let socket: Socket
    let configuration: SSLService.Configuration
    
    fileprivate static let readBufferSize = 32768
    
    init(hostname: String, port: Int, configuration: SSLService.Configuration = EncryptedSocket.defaultConfiguration()) throws {
        self.hostname = hostname
        self.port = port
        self.configuration = configuration
        
        self.socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        self.socket.readBufferSize = EncryptedSocket.readBufferSize
    }
    
    private static func defaultConfiguration() -> SSLService.Configuration {
        
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
    
    
}

extension EncryptedSocket: SocketProtocol {
    
    func connect(timeout: Int) throws {
        try socket.connect(to: hostname, port: Int32(port))
        
        if let sslService = try SSLService(usingConfiguration: self.configuration) {
            sslService.skipVerification = true
            socket.delegate = sslService
            try sslService.initialize(asServer: false)
        } else {
            print("Failed to set up SSL connection, falling back to unencrypted")
        }
    }
    
    func send(bytes: [Byte]) throws {
        let data = Data(bytes: bytes)
        try socket.write(from: data)
    }
    
    func receive(expectedNumberOfBytes: Int32) throws -> [Byte] {
        var data = Data(capacity: EncryptedSocket.readBufferSize)
        let numberOfBytes = try socket.read(into: &data)
        
        let bytes = [Byte] (data)
        if(numberOfBytes != bytes.count) {
            print("Expected bytes read doesn't match actual bytes got")
        }
        
        return bytes
    }
    
}
