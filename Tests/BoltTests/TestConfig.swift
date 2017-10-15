import Foundation
import Bolt

struct TestConfig {
    let username: String
    let password: String
    let hostname: String
    let port: Int
    let temporarySSLKeyPath: String
    let hostUsesSelfSignedCertificate: Bool
    let sslConfig: SSLConfiguration

    init(pathToFile: String) {

        do {
            let filePathURL = URL(fileURLWithPath: pathToFile)
            let jsonData = try Data(contentsOf: filePathURL)
            let jsonConfig = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any]

            self.username = jsonConfig?["username"] as? String ?? "neo4j"
            self.password = jsonConfig?["password"] as? String ?? "neo4j"
            self.hostname = jsonConfig?["hostname"] as? String ?? "localhost"
            self.port     = jsonConfig?["port"] as? Int ?? 7687
            self.hostUsesSelfSignedCertificate = jsonConfig?["hostUsesSelfSignedCertificate"] as? Bool ?? true
            self.temporarySSLKeyPath = jsonConfig?["temporarySSLKeyPath"] as? String ?? "/tmp/boltTestKeys"
            self.sslConfig = SSLConfiguration(json: jsonConfig?["certificateProperties"] as? [String:Any] ?? [:])

        } catch {

            self.username = "neo4j"
            self.password = "neo4j"
            self.hostname = "localhost"
            self.port     = 7687
            self.hostUsesSelfSignedCertificate = true
            self.temporarySSLKeyPath = "/tmp/boltTestKeys"
            self.sslConfig = SSLConfiguration(json: [:])


            print("Config load failed: \(error)\nUsing default config values")
        }
    }

    static func loadConfig() -> TestConfig {

        let testPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path

        let filePath = "\(testPath)/BoltSwiftTestConfig.json"

        return TestConfig(pathToFile: filePath)
    }

}
