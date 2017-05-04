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

    init(hostname: String, port: Int, configuration: SSLService.Configuration) throws {
        self.hostname = hostname
        self.port = port
        self.configuration = configuration

        self.socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        self.socket.readBufferSize = EncryptedSocket.readBufferSize
    }

    public static func defaultConfiguration(sslConfig: SSLConfiguration, allowHostToBeSelfSigned: Bool) -> SSLService.Configuration {
        
        let dir = sslConfig.temporarySSLKeyPath
        #if os(Linux)
            
            let myCertFile = "\(dir)/\(sslConfig.certificatePEMFilename)"
            let myKeyFile = "\(dir)/\(sslConfig.keyFileName)"
            
            let config =  SSLService.Configuration(withCACertificateDirectory: nil,
                                                   usingCertificateFile: myCertFile,
                                                   withKeyFile: true,
                                                   usingSelfSignedCerts: allowHostToBeSelfSigned)
        #else // on macOS & iOS
            
            let myCertKeyFile = "\(dir)/\(sslConfig.certificatePKCS12FileName)"
            createPKCS12CertWith(sslConfig: sslConfig)
            
            let config =  SSLService.Configuration(withChainFilePath: myCertKeyFile,
                                                   withPassword: sslConfig.certificatePKCS12Password,
                                                   usingSelfSignedCerts: true,
                                                   clientAllowsSelfSignedCertificates: allowHostToBeSelfSigned)
            
        #endif
        
        return config
    }
    
    private static func createPKCS12CertWith(sslConfig: SSLConfiguration) {
        
        let dir = URL(string: sslConfig.temporarySSLKeyPath)!.deletingLastPathComponent().absoluteString
        let subdir = URL(string: sslConfig.temporarySSLKeyPath)!.lastPathComponent
        
        do {
            try shellOut(to: "mv \(subdir) ~/.Trash", at: dir)
        } catch {} // Ignore error
        
        do {
            try shellOut(to: "mkdir -p \(subdir)", at: dir)
        } catch {}
        
        let gen = sslConfig.generator
        do {
            try shellOut(to: [
            "echo \"\(gen.countryName)\n\(gen.stateOrProvinceName)\n\(gen.localityName)\n\(gen.organizationName)\n\(gen.orgUnitName)\n\(gen.commonName)\n\(gen.emailAddress)\n\n\(gen.companyName)\n\" > params",
            
            // Source: https://developer.ibm.com/swift/2016/09/22/securing-kitura-part-1-enabling-ssltls-on-your-swift-server/
            "openssl genrsa -out \(sslConfig.keyFileName) 2048",
            "openssl req -new -sha256 -key \(sslConfig.keyFileName) -out \(gen.signingRequestFileName) < params",
            "openssl req -x509 -sha256 -days 365 -key \(sslConfig.keyFileName) -in \(gen.signingRequestFileName) -out \(sslConfig.certificatePEMFilename)",
            "openssl pkcs12 -password pass:\(sslConfig.certificatePKCS12Password) -export -out \(sslConfig.certificatePKCS12FileName) -inkey \(sslConfig.keyFileName) -in \(sslConfig.certificatePEMFilename)"
            ], at: "\(dir)/\(subdir)")
    
        } catch {} // Ignore output
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
