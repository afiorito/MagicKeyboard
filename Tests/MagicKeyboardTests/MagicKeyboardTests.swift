import XCTest
@testable import MagicKeyboard

final class MagicKeyboardTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MagicKeyboard().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
