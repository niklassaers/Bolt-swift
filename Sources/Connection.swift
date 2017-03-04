import Foundation
import packstream_swift

public class Connection: NSObject {

    private let hostname: String
    private let port: Int
    private let settings: ConnectionSettings

    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var socket: SocketProtocol
    public var currentTransactionBookmark: String?

    public init(hostname: String = "localhost", port: Int = 7687, settings: ConnectionSettings = ConnectionSettings()) throws {

        self.hostname = hostname
        self.port = port
        self.settings = settings
        self.socket = try UnencryptedSocket(hostname: hostname, port: port)

        super.init()
    }

    public func connect(completion: (_ success: Bool) -> Void) throws {
        try socket.connect(timeout: 10)
        try initBolt()
        try initialize()
        completion(true)
    }

    private func initBolt() throws {
        try socket.send(bytes: [0x60, 0x60, 0xB0, 0x17, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let response = try socket.receive(expectedNumberOfBytes: 4)
        let version = try UInt32.unpack(response[0..<response.count])
        if version == 1 {
            // success
        } else {
            throw ConnectionError.unknownVersion
        }
    }

    private func initialize() throws {
        let message = Request.initialize(settings: settings)
        let chunks = try message.chunk()
        for chunk in chunks {
            try socket.send(bytes: chunk)
        }

        let responseData = try socket.receive(expectedNumberOfBytes: 1024) //TODO: Ensure I get all chunks back
        let unchunkedData = try Response.unchunk(responseData)
        let response = try Response.unpack(unchunkedData)

        // TODO: throw ConnectionError.authenticationError on error
    }

    public enum ConnectionError: Error {
        case unknownVersion
        case authenticationError
        case requestError
    }

    enum CommandResponse: Byte {
        case success = 0x70
        case record = 0x71
        case ignored = 0x7e
        case failure = 0x7f
    }
    
    private func chunkAndSend(request: Request) throws {

        let chunks = try request.chunk()

        for chunk in chunks {
            let response = try socket.send(bytes: chunk)
            // TODO: Use response
        }

    }
    
    private func parseMeta(_ meta: [PackProtocol]) {
        for item in meta {
            if let map = item as? Map {
                for (key, value) in map.dictionary {
                    switch key {
                    case "bookmark":
                        self.currentTransactionBookmark = value as? String
                    case "stats":
                        break
                    case "result_available_after":
                        break
                    case "result_consumed_after":
                        break
                    case "type":
                        break
                    case "fields":
                        break
                    default:
                        print("Couldn't parse metadata \(key)")
                    }
                }
            }
        }
    }

    public func request(_ request: Request, completionHandler: (Bool, Response?) throws -> Void) throws {

        try chunkAndSend(request: request)

        let responseData = try socket.receive(expectedNumberOfBytes: 1024) //TODO: Ensure I get all chunks back
        let unchunkedData = try Response.unchunk(responseData)
        let response = try Response.unpack(unchunkedData)
        if let error = response.asError() {
            throw error
        }
        
        if response.category != .record {
            parseMeta(response.items)
        }
        
        try completionHandler(response.category != .failure, response)
    }

}
