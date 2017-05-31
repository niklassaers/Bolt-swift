import XCTest

#if !os(macOS) && !os(iOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
	testCase(BoltTests.allTests),
	testCase(UnencryptedSocketTests.allTests),
	testCase(EncryptedSocketTests.allTests),
    ]
}
#endif
