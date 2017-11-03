import Foundation

public struct ConnectionSettings {
    let username: String
    let password: String
    let userAgent: String

    public init(username: String = "neo4j", password: String = "neo4j", userAgent: String = "Bolt-Swift/0.9.5") {

        self.username = username
        self.password = password
        self.userAgent = userAgent
    }

}
