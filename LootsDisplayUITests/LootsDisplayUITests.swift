import XCTest

final class LootsDisplayUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testInitialState_IsReadyToRecord() throws {
        // Verify the recording status header exists
        let statusText = app.staticTexts["Ready"]
        XCTAssertTrue(statusText.exists, "The initial status should be 'Ready to Record'")
        
        // Verify the Start Button exists
        let startButton = app.buttons["START RECORDING"]
        XCTAssertTrue(startButton.exists)
    }
}
