import Foundation
import packstream_swift

public struct Node {

    public let id: UInt64
    public let labels: [String]
    public let properties: [String: PackProtocol]

}
