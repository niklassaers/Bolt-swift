import Foundation
import PackStream
import Socket
import SSLService

public class EncryptedSocket {

    let hostname: String
    let port: Int
    let socket: Socket
    let configuration: SSLService.Configuration

    fileprivate static let readBufferSize = 32768

    public init(hostname: String, port: Int, configuration: SSLService.Configuration) throws {
        self.hostname = hostname
        self.port = port
        self.configuration = configuration

        self.socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        self.socket.readBufferSize = EncryptedSocket.readBufferSize
    }

    public static func defaultConfiguration(sslConfig: SSLConfiguration, allowHostToBeSelfSigned: Bool) -> SSLService.Configuration {

        let configuration = SSLService.Configuration(withCipherSuite: nil)
        return configuration
    }
}

extension EncryptedSocket: SocketProtocol {

    public func connect(timeout: Int) throws {
        if let sslService = try SSLService(usingConfiguration: self.configuration) {
            sslService.skipVerification = true
            socket.delegate = sslService

            sslService.verifyCallback = { _ in

                return (true, nil)
            }
        }

        if socket.isConnected == false {
            usleep(10000) // This sleep is anoying, but else SSL may not complete correctly!
            try socket.connect(to: hostname, port: Int32(port))
        } else {
            print("Socket was already connected")
        }
    }

    public func disconnect() {
        socket.close()
    }

    public func send(bytes: [Byte]) throws {
        let data = Data(bytes: bytes)
        try socket.write(from: data)
    }

    public func receive(expectedNumberOfBytes: Int32) throws -> [Byte] {
        var data = Data(capacity: EncryptedSocket.readBufferSize)
        let numberOfBytes = try socket.read(into: &data)

        let bytes = [Byte] (data)
        if(numberOfBytes != bytes.count) {
            print("Expected bytes read doesn't match actual bytes got")
        }

        return bytes
    }
}
