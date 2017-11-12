import Foundation
import PackStream

public protocol SocketProtocol {

    func connect(timeout: Int) throws
    func send(bytes: [Byte]) throws
    func receive(expectedNumberOfBytes: Int32) throws -> [Byte]
    func disconnect()
}
