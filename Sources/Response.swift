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
        case ignored = 0x7E
        case failure = 0x7F
    }

    public struct RecordType {
        static let node: Byte = 0x4E
        static let relationship: Byte = 0x52
        static let path: Byte = 0x50
        static let unboundRelationship: Byte = 0x72
    }

    enum ResponseError: Error {
        case tooFewBytes
        case invalidResponseType
    }

    public func asNode() -> Node? {
        if category != .record ||
           items.count != 1 {
            return nil
        }

        let list = items[0] as? List
        guard let items = list?.items,
              items.count == 1,

              let structure = items[0] as? Structure,
              structure.signature == Response.RecordType.node,
              structure.items.count == 3,

              let nodeId = structure.items.first?.asUInt64(),
              let labelList = structure.items[1] as? List,
              let labels = labelList.items as? [String],
              let propertyMap = structure.items[2] as? Map
              else {
                return nil
        }

        let properties = propertyMap.dictionary

        let node = Node(id: UInt64(nodeId), labels: labels, properties: properties)
        return node
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
            let size = Int(try UInt16.unpack(sizeBytes))

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
            let s = try Structure.unpack(bytes[0..<bytes.count])
            if let category = Category(rawValue: s.signature) {
                let response = Response(category: category, items: s.items)
                print(response)
                return response
            } else {
                throw ResponseError.invalidResponseType
            }
        }

        return Response()
    }

}
