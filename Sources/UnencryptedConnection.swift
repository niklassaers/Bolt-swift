import Foundation
import Security
import packstream_swift
import TLS
import SocksCore

class UnencryptedConnection: NSObject {
    
    static let handshake: [Byte] = [0x60, 0x60, 0xB0, 0x17]
    
    private let hostname: String
    private let port: Int
    private let settings: ConnectionSettings?
    
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    init(hostname: String = "127.0.0.1", port: Int = 7687, settings: ConnectionSettings? = nil) {

        self.hostname = hostname
        self.port = port
        self.settings = settings
        
        super.init()
        
        Stream.getStreamsToHost(withName: hostname, port: port, inputStream: &self.inputStream, outputStream: &self.outputStream)
        
        
        if let inputStream = inputStream,
            let outputStream = outputStream {
            inputStream.delegate = self
            outputStream.delegate = self
            
            inputStream.schedule (in: .main, forMode: RunLoopMode.defaultRunLoopMode)
            outputStream.schedule(in: .main, forMode: RunLoopMode.defaultRunLoopMode)
            
            inputStream.open()
            outputStream.open()
            
            let bytesWritten = outputStream.write(UnsafePointer(UnencryptedConnection.handshake), maxLength: UnencryptedConnection.handshake.count)
            print("Wrote \(bytesWritten) bytes")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {

                let bytes: [Byte] = [ 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
                let bytesWritten = outputStream.write(UnsafePointer(bytes), maxLength: bytes.count)
                print("Wrote \(bytesWritten) bytes more")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                    self.read()
                    self.close()
                }
            }
        }
    }
    
    func request(_ request: Request, completionHandler: (Response) -> ()) {
        
    }
    
    fileprivate func read() -> String {
        var buffer = [UInt8](repeating: 0, count: 1024)
        var output: String = ""
        while (self.inputStream!.hasBytesAvailable){
            let bytesRead: Int = inputStream!.read(&buffer, maxLength: buffer.count)
            if bytesRead >= 0 {
                output += NSString(bytes: UnsafePointer(buffer), length: bytesRead, encoding: String.Encoding.utf8.rawValue)! as String
            }
        }
        
        print("Read: '\(output)' (\(buffer.count) bytes)")
        //self.dataReadCallback!(dataReceived: output)
        return output
    }
    
    func close() {
        
        guard let inputStream = inputStream, let outputStream = outputStream else { return }
        
        inputStream.remove( from: .main, forMode: RunLoopMode.defaultRunLoopMode)
        outputStream.remove(from: .main, forMode: RunLoopMode.defaultRunLoopMode)
        
        inputStream.close()
        outputStream.close()
        
        self.inputStream = nil
        self.outputStream = nil
    }
    
}

extension UnencryptedConnection: StreamDelegate {
    func stream(aStream: Stream, handleEvent eventCode: Stream.Event) {
        
        if eventCode == .hasBytesAvailable {
            self.read()
        }
    }
}
