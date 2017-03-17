import Foundation
import PackStream

public struct Request {

    let command: Command
    let items: [PackProtocol]

    public enum Command: Byte {
        case initialize = 0x01
        case ack_failure = 0x0e
        case reset = 0x0f
        case run = 0x10
        case discard_all = 0x2f
        case pull_all = 0x3f
    }

    enum RequestErrors: Error {
        case unchunkError
    }

    static let kMaxChunkSize = 65535

    private init(command: Command, items: [PackProtocol]) {
        self.command = command
        self.items = items
    }

    public static func initialize(settings: ConnectionSettings) -> Request {

        let agent = settings.userAgent

        let authMap = Map(dictionary: ["scheme": "basic",
                                       "principal": settings.username,
                                       "credentials": settings.password])

        return Request(command: .initialize, items: [agent, authMap])
    }

    public static func ackFailure() -> Request {
        return Request(command: .ack_failure, items: [])
    }

    public static func reset() -> Request {
        return Request(command: .reset, items: [])
    }

    public static func run(statement: String, parameters: Map) -> Request {
        return Request(command: .run, items: [statement, parameters])
    }

    public static func discardAll() -> Request {
        return Request(command: .discard_all, items: [])
    }

    public static func pullAll() -> Request {
        return Request(command: .pull_all, items: [])
    }

    public func chunk() throws -> [[Byte]] {

        do {
            let bytes = try self.pack()
            var chunks = [[Byte]]()
            let numChunks = ((bytes.count + 2) / Request.kMaxChunkSize) + 1
            for i in 0 ..< numChunks {

                let start = i * (Request.kMaxChunkSize - 2)
                var end = i == (numChunks - 1) ?
                    start + (Request.kMaxChunkSize - 4) :
                    start + (Request.kMaxChunkSize - 2) - 1
                if end >= bytes.count {
                    end = bytes.count - 1
                }

                let count = UInt16(end - start + 1)
                let countBytes = try count.pack()

                if i == (numChunks - 1) {
                    chunks.append(countBytes + bytes[start...end] + [ 0x00, 0x00 ])
                } else {
                    chunks.append(countBytes + bytes[start...end])
                }
            }

            return chunks

        } catch(let error) {
            throw error
        }
    }

    private func pack() throws -> [Byte] {
        let s = Structure(signature: command.rawValue, items: items)
        do {
            return try s.pack()
        } catch(let error) {
            throw error
        }
    }

    public static func unchunk(chunks: [[Byte]]) throws -> Request {

        throw RequestErrors.unchunkError
    }

}
