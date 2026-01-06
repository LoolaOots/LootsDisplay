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

    func testRecordingToggle_ChangesButtonText() throws {
        let startButton = app.buttons["START RECORDING"]
        startButton.tap()
        
        // Check if the button changes to "STOP"
        let stopButton = app.buttons["STOP RECORDING"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 2), "Button should change to STOP after tapping")
        
        // Check if the recording timer text appears
        // This looks for any static text where the label STARTS WITH "Recording Active:"
        let predicate = NSPredicate(format: "label BEGINSWITH 'Active:'")
        let activeStatus = app.staticTexts.element(matching: predicate)

        XCTAssertTrue(activeStatus.waitForExistence(timeout: 2), "The recording timer should appear.")
        XCTAssertTrue(activeStatus.exists)
        
        stopButton.tap()
        XCTAssertTrue(app.buttons["START RECORDING"].exists)
    }
}
