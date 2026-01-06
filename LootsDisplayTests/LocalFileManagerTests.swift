//
//  LocalFileManagerTests.swift
//  LootsDisplay
//
//  Created by Nat on 1/5/26.
//


import XCTest
@testable import LootsDisplay

final class LocalFileManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure the folder exists and is empty before each test
        LocalFileManager.setupFolder()
        clearAllStoredFiles()
    }

    override func tearDown() {
        // Clean up after the test finishes
        clearAllStoredFiles()
        super.tearDown()
    }

    // MARK: - Tests

    func testSaveAndLoadSession_WorkCorrectly() {
        // Arrange
        let sessionID = UUID()
        let session = RecordingSession(id: sessionID, startTime: Date(), frames: [])
        
        // Act
        LocalFileManager.saveSession(session)
        let loadedSessions = LocalFileManager.loadSessions()
        
        // Assert
        XCTAssertEqual(loadedSessions.count, 1)
        XCTAssertEqual(loadedSessions.first?.id, sessionID)
    }

    func testDeleteSession_RemovesFileFromDisk() {
        // Arrange
        let session = RecordingSession(id: UUID(), startTime: Date(), frames: [])
        LocalFileManager.saveSession(session)
        XCTAssertEqual(LocalFileManager.loadSessions().count, 1)
        
        // Act
        LocalFileManager.deleteSession(id: session.id)
        let finalSessions = LocalFileManager.loadSessions()
        
        // Assert
        XCTAssertTrue(finalSessions.isEmpty, "Session should have been deleted from disk.")
    }

    func testLoadSessions_IsSortedByDate() {
        // Arrange: Create an old session and a new session
        let oldDate = Date().addingTimeInterval(-1000)
        let newDate = Date()
        
        let oldSession = RecordingSession(id: UUID(), startTime: oldDate, frames: [])
        let newSession = RecordingSession(id: UUID(), startTime: newDate, frames: [])
        
        LocalFileManager.saveSession(oldSession)
        LocalFileManager.saveSession(newSession)
        
        // Act
        let sessions = LocalFileManager.loadSessions()
        
        // Assert: loadSessions should return newest first (.sorted(by: { $0.startTime > $1.startTime }))
        XCTAssertEqual(sessions.first?.id, newSession.id)
        XCTAssertEqual(sessions.last?.id, oldSession.id)
    }

    // MARK: - Helpers
    
    private func clearAllStoredFiles() {
        let sessions = LocalFileManager.loadSessions()
        for session in sessions {
            LocalFileManager.deleteSession(id: session.id)
        }
    }
}