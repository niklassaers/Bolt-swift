import Foundation
import PackStream
import Socket
import SSLService

public class EncryptedSocket {

    let hostname: String
    let port: Int
    let socket: Socket
    let configuration: SSLService.Configuration

    fileprivate static let readBufferSize = 65536

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
            let timeout = UInt(max(0, timeout))
            try socket.connect(to: hostname, port: Int32(port), timeout: timeout)
        } else {
            print("Socket was already connected")
        }
    }

    public func disconnect() {
        socket.close()
    }

    private func checkAndPossiblyReconnectSocket () throws {

        let (readables, writables) = try Socket.checkStatus(for: [socket])
        if socket.isConnected == false || readables.count + writables.count < 1 {
            print("Reconnecting")
            // reconnect
            disconnect()
            try connect(timeout: 5)
        }

    }

    public func send(bytes: [Byte]) throws {

        try checkAndPossiblyReconnectSocket()

        let data = Data(bytes: bytes)
        try socket.write(from: data)
    }

    public func receive(expectedNumberOfBytes: Int32) throws -> [Byte] {
        try checkAndPossiblyReconnectSocket()

        var data = Data(capacity: EncryptedSocket.readBufferSize)
        var numberOfBytes = try socket.read(into: &data)

        var bytes = [Byte] (data)
        
        while numberOfBytes != 0 && numberOfBytes % 8192 == 0 {
            usleep(10000)
            data = Data(capacity: EncryptedSocket.readBufferSize)
            numberOfBytes = try socket.read(into: &data)
            bytes.append(contentsOf: data)
        }
        
        return bytes
    }
}
