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

    func testAttachVideo_MovesFileAndReturnsFileNameMatchingSessionId() {
        // Arrange
        let session = RecordingSession(id: UUID(), startTime: Date(), frames: [])
        LocalFileManager.saveSession(session)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        try? "fake video bytes".data(using: .utf8)?.write(to: tempURL)

        // Act
        let fileName = LocalFileManager.attachVideo(from: tempURL, toSessionId: session.id)

        // Assert
        XCTAssertNotNil(fileName)
        XCTAssertEqual(fileName, "\(session.id).mov")
        XCTAssertNotNil(LocalFileManager.videoURL(for: session.id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path), "Source temp file should have been moved, not copied.")
    }

    func testDeleteSession_AlsoRemovesAttachedVideo() {
        // Arrange
        let session = RecordingSession(id: UUID(), startTime: Date(), frames: [])
        LocalFileManager.saveSession(session)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        try? "fake video bytes".data(using: .utf8)?.write(to: tempURL)
        _ = LocalFileManager.attachVideo(from: tempURL, toSessionId: session.id)
        XCTAssertNotNil(LocalFileManager.videoURL(for: session.id))

        // Act
        LocalFileManager.deleteSession(id: session.id)

        // Assert
        XCTAssertNil(LocalFileManager.videoURL(for: session.id), "Video file should be deleted alongside the session JSON.")
    }

    // MARK: - Helpers
    
    private func clearAllStoredFiles() {
        let sessions = LocalFileManager.loadSessions()
        for session in sessions {
            LocalFileManager.deleteSession(id: session.id)
        }
    }
}