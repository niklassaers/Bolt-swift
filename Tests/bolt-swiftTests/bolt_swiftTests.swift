import XCTest
@testable import bolt_swift

class bolt_swiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(bolt_swift().text, "Hello, World!")
    }


    static var allTests : [(String, (bolt_swiftTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
