import Foundation
import packstream_swift

public struct Response {
    
    public let category: Category
    public let items: [PackProtocol]
    
    private init(category: Category = .empty, items: [PackProtocol] = []) {
        self.category = category
        self.items = items
    }

    public enum Category: Byte {
        case empty = 0x00
        case success = 0x70
        case record = 0x71
        case ignored = 0x7e
        case failure = 0x7f
    }
    
    enum ResponseError: Error {
        case tooFewBytes
        case invalidResponseType
    }
    
    public static func unchunk(_ bytes: [Byte]) throws -> [Byte] {
        
        if bytes.count < 2 {
            throw ResponseError.tooFewBytes
        }
        
        var chunks = [[Byte]]()
        var hasMoreChunks = true
        var pos = 0
        
        while hasMoreChunks == true {

            let sizeBytes = bytes[pos ..< (pos+2)]
            pos += 2
            let size = Int(try UInt16.unpack(Array(sizeBytes)))
            
            if size == 0 {
                hasMoreChunks = false
            } else {
                
                let chunk = bytes[pos..<(pos+size)]
                pos += size
                chunks.append(Array(chunk))
            }
        }
        
        return chunks.reduce([Byte](), { (result, chunk) -> [Byte] in
            return result + chunk
        })
    }
    
    public static func unpack(_ bytes: [Byte]) throws -> Response {
        
        let marker = Packer.Representations.typeFrom(representation: bytes[0])
        switch(marker) {
        case .null:
            break
        case .bool:
            break
        case .int8small:
            break
        case .int8:
            break
        case .int16:
            break
        case .int32:
            break
        case .int64:
            break
        case .float:
            break
        case .string:
            break
        case .list:
            break
        case .map:
            break
        case .structure:
            let s = try Structure.unpack(bytes)
            if let category = Category(rawValue: s.signature) {
                return Response(category: category, items: s.items)
            } else {
                throw ResponseError.invalidResponseType
            }
        }
        
        return Response()
    }
    
}
