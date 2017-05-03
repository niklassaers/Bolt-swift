import Foundation
import PackStream
import Socket
import SSLService
import ShellOut

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
            createPKCS12CertIn(dir: dir)

            let config =  SSLService.Configuration(withChainFilePath: myCertKeyFile,
                                                   withPassword: "1234",
                                                   usingSelfSignedCerts: true)

        #endif

        return config
    }
    
    private static func createPKCS12CertIn(dir: String) {
        do {
            try shellOut(to: "mv newcert ~/.Trash", at: dir)
        } catch {} // Ignore error
        
        do {
            try shellOut(to: "mkdir -p newcert", at: dir)
        } catch {}
        
        do {
            try shellOut(to: [
            "echo \"DK\nEsbjerg\n\nSaers\n\n\n\n\n\n\" > params",
            
            // Source: https://developer.ibm.com/swift/2016/09/22/securing-kitura-part-1-enabling-ssltls-on-your-swift-server/
            "openssl genrsa -out key.pem 2048",
            "openssl req -new -sha256 -key key.pem -out csr.csr < params",
            "openssl req -x509 -sha256 -days 365 -key key.pem -in csr.csr -out cert.pem",
            "openssl pkcs12 -password pass:1234 -export -out cert.pfx -inkey key.pem -in cert.pem"
            ], at: "\(dir)/newcert")
    
        } catch {} // Ignore output

        do {
            try shellOut(to: "mv * ..", at: "\(dir)/newcert")
            try shellOut(to: "rmdir newcert", at: dir)
        } catch {}
    }


}

extension EncryptedSocket: SocketProtocol {

    func connect(timeout: Int) throws {
        if let sslService = try SSLService(usingConfiguration: self.configuration) {
            sslService.skipVerification = true
            socket.delegate = sslService
        }

        try socket.connect(to: hostname, port: Int32(port))

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
