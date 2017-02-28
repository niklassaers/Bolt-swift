import Foundation
import packstream_swift

class SwiftSocketConnection: NSObject {

    private let hostname: String
    private let port: Int32
    private let settings: ConnectionSettings

    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var client: TCPClient

    init(hostname: String = "127.0.0.1", port: Int32 = 7687, settings: ConnectionSettings = ConnectionSettings()) {

        self.hostname = hostname
        self.port = port
        self.settings = settings
        self.client = TCPClient(address: hostname, port: port)

        super.init()
    }

    func connect(completion: (_ success: Bool) -> Void) throws {
        switch client.connect(timeout: 10) {
        case .success:
            try initBolt()
            try initialize()
            completion(true)
        case .failure(let error):
            throw error
        }
    }

    private func initBolt() throws {
        switch client.send(data: Data(bytes: [0x60, 0x60, 0xB0, 0x17, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])) {
        case .success:
            if let response = client.read(4) {
                do {
                    let version = try UInt32.unpack(response[0..<response.count])
                    if version == 1 {
                        // success
                    } else {
                        throw ConnectionError.unknownVersion
                    }
                } catch (let error) {
                    throw error
                }
            }
        case .failure(let error):
            throw error
        }
    }

    private func initialize() throws {
        let message = Request.initialize(settings: settings)
        do {
            let chunks = try message.chunk()
            for chunk in chunks {
                let response = client.send(data: chunk)
                switch(response) {
                case .failure(let error):
                    throw error
                default:
                    continue
                }
            }
        } catch(let error) {
            throw error
        }

        print("Authentication successfully sent")
        if let responseData = client.read(1024) { //TODO: Ensure I get all chunks back
            print("Got \(responseData.count) bytes")
            do {
                let unchunkedData = try Response.unchunk(responseData)
                let response = try Response.unpack(unchunkedData)
                print(response)
            }
        } else {
            throw ConnectionError.authenticationError
        }
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
            let response = client.send(data: chunk)
            switch(response) {
            case .failure(let error):
                throw error
            default:
                continue
            }
        }

    }

    func request(_ request: Request, completionHandler: (Bool, Response?) -> Void) throws {

        try chunkAndSend(request: request)

        print("Request successfully sent")

        if let responseData = client.read(1024) { //TODO: Ensure I get all chunks back
            print("Got \(responseData.count) bytes")
            do {
                let unchunkedData = try Response.unchunk(responseData)
                let response = try Response.unpack(unchunkedData)
                print(response)
                completionHandler(true, response)
            }
        } else {
            throw ConnectionError.requestError
        }
    }

}
