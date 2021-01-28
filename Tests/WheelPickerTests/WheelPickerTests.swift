import XCTest
@testable import WheelPicker

final class WheelPickerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WheelPicker().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
