//
//  CSVManagerTests.swift
//  LootsDisplay
//
//  Created by Nat on 1/5/26.
//


import XCTest
@testable import LootsDisplay

final class CSVManagerTests: XCTestCase {

    func testGenerateCSVString_HeaderIsCorrect() {
        // Arrange
        let session = createMockSession(frameCount: 0)
        
        // Act
        let csvString = CSVManager.generateCSVString(for: session)
        let lines = csvString.components(separatedBy: .newlines)
        
        // Assert
        let expectedHeader = "Timestamp,Label,Pitch,Roll,Yaw,Latitude,Longitude,Pressure,Heading,Speed,AccelX,AccelY,AccelZ,GForceX,GForceY,GForceZ,GyroX,GyroY,GyroZ,MagX,MagY,MagZ"
        XCTAssertEqual(lines.first, expectedHeader, "CSV Header does not match specification.")
    }

    func testGenerateCSVString_ContainsFrameData() {
        // Arrange
        let testLabel = "BenchPress"
        let session = createMockSession(frameCount: 1, label: testLabel)
        
        // Act
        let csvString = CSVManager.generateCSVString(for: session)
        let lines = csvString.components(separatedBy: .newlines)
        
        // Assert
        XCTAssertEqual(lines.count, 3) // Header + 1 Data Row + Trailing Newline
        XCTAssertTrue(lines[1].contains(testLabel), "The CSV row should contain the frame label.")
    }
    
    func testGenerateCSVString_HandlesNilLabel() {
        // Arrange
        let session = createMockSession(frameCount: 1, label: nil)
        
        // Act
        let csvString = CSVManager.generateCSVString(for: session)
        let lines = csvString.components(separatedBy: .newlines)
        let columns = lines[1].components(separatedBy: ",")
        
        // Assert
        // Column index 1 is the 'Label' column
        XCTAssertEqual(columns[1], "", "Nil labels should be represented as empty strings in CSV.")
    }
    
    func testRecordingSession_TitleFormatMatchesStartTime() {
        // Arrange
        let calendar = Calendar.current
        let components = DateComponents(year: 2026, month: 1, day: 5, hour: 10, minute: 30, second: 0)
        let testDate = calendar.date(from: components)!
        
        let session = RecordingSession(id: UUID(), startTime: testDate, frames: [])
        
        // Act
        let title = session.title
        
        // Assert
        // This checks if the title contains the expected date parts
        // (exact format depends on the test runner's locale, but usually contains 1/5/26)
        XCTAssertTrue(title.contains("1/5/26"), "Title should contain the short date string.")
        XCTAssertTrue(title.contains("10:30"), "Title should contain the time string.")
    }
    
    func testFileName_ConvertsSpacesToUnderscores() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 14, minute: 0, second: 0))!
        
        let session = createMockSession(frameCount: 1, label: "Squat Set 1")
        let sessionWithFixedTime = RecordingSession(id: session.id, startTime: testDate, frames: session.frames)
        
        let generatedName = CSVManager.fileName(for: sessionWithFixedTime)
        
        // Assert
        // Expected: Squat_Set_1_2026-01-05_140000_xxxx.csv
        XCTAssertTrue(generatedName.contains("Squat_Set_1"), "Spaces should be replaced by underscores.")
        XCTAssertTrue(generatedName.contains("2026-01-05_140000"), "Date format in filename is incorrect.")
        XCTAssertTrue(generatedName.hasSuffix(".csv"), "Filename should have .csv extension.")
    }

    func testFileName_UsesDefaultWhenNoLabelExists() {
        let session = createMockSession(frameCount: 1, label: nil)
        
        let generatedName = CSVManager.fileName(for: session)
        
        XCTAssertTrue(generatedName.starts(with: "SensorLog"), "Should use 'SensorLog' if no label is found.")
    }

    
    private func createMockSession(frameCount: Int, label: String? = nil) -> RecordingSession {
        var frames: [SensorFrame] = []
        for _ in 0..<frameCount {
            frames.append(SensorFrame(
                timestamp: Date(),
                label: label,
                pitch: 1.0, roll: 2.0, yaw: 3.0,
                latitude: 0.0, longitude: 0.0,
                pressure: 101.3, heading: 0.0, speed: 0.0,
                accelX: 0.1, accelY: 0.2, accelZ: 0.3,
                gForceX: 1.0, gForceY: 0.0, gForceZ: 0.0,
                gyroX: 0.0, gyroY: 0.0, gyroZ: 0.0,
                magX: 0.0, magY: 0.0, magZ: 0.0
            ))
        }
        
        return RecordingSession(
            id: UUID(),
            startTime: Date(),
            frames: frames,
        )
    }
}
