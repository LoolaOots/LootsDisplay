import XCTest
@testable import LootsDisplay

final class SensorManagerTests: XCTestCase {
    
    var sensorManager: SensorManager!

    override func setUp() {
        super.setUp()
        sensorManager = SensorManager()
        // Clear sessions to ensure a clean state for every test
        sensorManager.deleteAllSessions()
        
        // Give the async deletion a moment to settle
        let exp = expectation(description: "Cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
    }

    override func tearDown() {
        sensorManager = nil
        super.tearDown()
    }

    func testToggleRecording_StartsRecordingWhenAllowed() {
        // Act
        sensorManager.toggleRecording()
        
        // Assert: Wrapped in async because toggleRecording uses DispatchQueue.main.async
        let exp = expectation(description: "Wait for recording start")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sensorManager.isRecording)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testRecordingLimit_TriggersAlertAtThreeSessions() {
        // Arrange: Directly set 3 sessions
        let mockFrame = createEmptyFrame()
        let session = RecordingSession(startTime: Date(), frames: [mockFrame])
        sensorManager.sessions = [session, session, session]
        
        // Act
        sensorManager.toggleRecording()
        
        // Assert
        let exp = expectation(description: "Wait for limit check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sensorManager.isRecording, "Should not start recording when limit is reached")
            XCTAssertTrue(self.sensorManager.showLimitAlert, "Should show limit alert")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testApplyLabelToSession_UpdatesAllFrames() {
        // Arrange
        let sessionID = UUID()
        let mockFrame = createEmptyFrame()
        let session = RecordingSession(id: sessionID, startTime: Date(), frames: [mockFrame])
        sensorManager.sessions = [session]
        
        let newLabel = "Deadlift"
        
        // Act
        sensorManager.applyLabelToSession(id: sessionID, label: newLabel)
        
        // Assert
        let exp = expectation(description: "Wait for labeling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Slightly longer delay for mapping
            let updatedSession = self.sensorManager.sessions.first(where: { $0.id == sessionID })
            XCTAssertEqual(updatedSession?.frames.first?.label, newLabel)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // Helper to keep code clean
    private func createEmptyFrame() -> SensorFrame {
        return SensorFrame(
            timestamp: Date(), label: nil, pitch: 0, roll: 0, yaw: 0,
            latitude: 0, longitude: 0, pressure: 0, heading: 0, speed: 0,
            accelX: 0, accelY: 0, accelZ: 0, gForceX: 0, gForceY: 0, gForceZ: 0,
            gyroX: 0, gyroY: 0, gyroZ: 0, magX: 0, magY: 0, magZ: 0
        )
    }
}
