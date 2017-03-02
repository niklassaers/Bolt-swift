import Foundation
import packstream_swift

class Connection: NSObject {

    private let hostname: String
    private let port: Int
    private let settings: ConnectionSettings

    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var socket: SocketProtocol

    init(hostname: String = "127.0.0.1", port: Int = 7687, settings: ConnectionSettings = ConnectionSettings()) throws {

        self.hostname = hostname
        self.port = port
        self.settings = settings
        self.socket = try UnencryptedSocket(hostname: hostname, port: port)

        super.init()
    }

    func connect(completion: (_ success: Bool) -> Void) throws {
        do {
            try socket.connect(timeout: 10)
            try initBolt()
        } catch(let error) {
            print(error)
        }
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

        print("Authentication successfully sent")
        let responseData = try socket.receive(expectedNumberOfBytes: 1024) //TODO: Ensure I get all chunks back
        print("Got \(responseData.count) bytes")
        let unchunkedData = try Response.unchunk(responseData)
        let response = try Response.unpack(unchunkedData)
        print(response)
        // TODO: throw ConnectionError.authenticationError on error
    }

    enum ConnectionError: Error {
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

    func request(_ request: Request, completionHandler: (Bool, Response?) -> Void) throws {

        try chunkAndSend(request: request)

        print("Request successfully sent")

        let responseData = try socket.receive(expectedNumberOfBytes: 1024) //TODO: Ensure I get all chunks back
        print("Got \(responseData.count) bytes")
        let unchunkedData = try Response.unchunk(responseData)
        let response = try Response.unpack(unchunkedData)
        print(response)
        completionHandler(true, response)
    }

}
