import Foundation
import PackStream

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
        public static let node: Byte = 0x4E
        public static let relationship: Byte = 0x52
        public static let path: Byte = 0x50
        public static let unboundRelationship: Byte = 0x72
    }

    public enum ResponseError: Error {
        case tooFewBytes
        case invalidResponseType
        case syntaxError(message: String)
        case indexNotFound(message: String)
        case forbiddenDueToTransactionType(message: String)
        case constraintVerificationFailed(message: String)
        case requestInvalid(message: String)
    }

    public func asError() -> Error? {
        if category != .failure {
            return nil
        }

        for item in items {
            if let map = item as? Map,
                let message = map.dictionary["message"] as? String,
                let code = map.dictionary["code"] as? String {

                switch code {
                case "Neo.ClientError.Statement.SyntaxError":
                    return ResponseError.syntaxError(message: message)
                case "Neo.ClientError.Schema.IndexNotFound":
                    return ResponseError.indexNotFound(message: message)
                case "Neo.ClientError.Transaction.ForbiddenDueToTransactionType":
                    return ResponseError.forbiddenDueToTransactionType(message: message)
                case "Neo.ClientError.Statement.ConstraintVerificationFailed":
                    return ResponseError.constraintVerificationFailed(message: message)
                case "Neo.ClientError.Request.Invalid":
                    return ResponseError.requestInvalid(message: message)

                default:
                    print("Response error with \(code) unknown, thus ignored")
                }

            }
        }

        return nil
    }

    public static func unchunk(_ bytes: [Byte]) throws -> [[Byte]] {
        var pos = 0
        var responses = [[Byte]]()

        while pos < bytes.count {
            let (responseBytes, endPos) = try unchunk(bytes[pos..<bytes.count], fromPos: pos)
            responses.append(responseBytes)
            pos = endPos
        }

        return responses
    }

    private static func unchunk(_ bytes: ArraySlice<Byte>, fromPos: Int = 0) throws -> ([Byte], Int) {

        if bytes.count < 2 {
            throw ResponseError.tooFewBytes
        }

        var chunks = [[Byte]]()
        var hasMoreChunks = true
        var pos = fromPos

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

        let unchunkedResponseBytes = chunks.reduce([Byte](), { (result, chunk) -> [Byte] in
            return result + chunk
        })

        return (unchunkedResponseBytes, pos)
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
                return response
            } else {
                throw ResponseError.invalidResponseType
            }
        }

        return Response()
    }

}
