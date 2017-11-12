import Foundation
import PackStream
import Socket

class UnencryptedSocket {

    let hostname: String
    let port: Int
    let socket: Socket

    fileprivate static let readBufferSize = 32768

    init(hostname: String, port: Int) throws {
        self.hostname = hostname
        self.port = port

        self.socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        self.socket.readBufferSize = UnencryptedSocket.readBufferSize
    }


}

extension UnencryptedSocket: SocketProtocol {

    func connect(timeout: Int) throws {
        try socket.connect(to: hostname, port: Int32(port))
    }

    func disconnect() {
        socket.close()
    }

    func send(bytes: [Byte]) throws {
        let data = Data(bytes: bytes)
        try socket.write(from: data)
    }

    func receive(expectedNumberOfBytes: Int32) throws -> [Byte] {
        var data = Data(capacity: UnencryptedSocket.readBufferSize)
        let numberOfBytes = try socket.read(into: &data)

        let bytes = [Byte] (data)
        if(numberOfBytes != bytes.count) {
            print("Expected bytes read doesn't match actual bytes got")
        }

        return bytes
    }

}
