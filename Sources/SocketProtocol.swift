import Foundation
import packstream_swift

public protocol SocketProtocol {

    func connect(timeout: Int) throws
    func send(bytes: [Byte]) throws
    func receive(expectedNumberOfBytes: Int32) throws -> [Byte]
    
}
