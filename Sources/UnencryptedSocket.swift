import Foundation
import PackStream
import Socket

public class UnencryptedSocket {

    let hostname: String
    let port: Int
    let socket: Socket

    fileprivate static let readBufferSize = 32768

    public init(hostname: String, port: Int) throws {
        self.hostname = hostname
        self.port = port

        self.socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        self.socket.readBufferSize = UnencryptedSocket.readBufferSize
    }


}

extension UnencryptedSocket: SocketProtocol {

    public func connect(timeout: Int) throws {
        try socket.connect(to: hostname, port: Int32(port))
    }

    public func disconnect() {
        socket.close()
    }

    public func send(bytes: [Byte]) throws {
        let data = Data(bytes: bytes)
        try socket.write(from: data)
    }

    public func receive(expectedNumberOfBytes: Int32) throws -> [Byte] {
        
        var data = Data(capacity: UnencryptedSocket.readBufferSize)
        var numberOfBytes = try socket.read(into: &data)
        
        var bytes = [Byte] (data)
        
        while numberOfBytes != 0 && numberOfBytes % 8192 == 0 {
            usleep(10000)
            data = Data(capacity: UnencryptedSocket.readBufferSize)
            numberOfBytes = try socket.read(into: &data)
            bytes.append(contentsOf: data)
        }
        
        return bytes
    }
}
