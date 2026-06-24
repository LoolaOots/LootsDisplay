//
//  VideoFileWriterTests.swift
//  LootsDisplay
//

import XCTest
import AVFoundation
import CoreMedia
@testable import LootsDisplay

final class VideoFileWriterTests: XCTestCase {

    func testAppendFramesThenFinish_ProducesNonEmptyVideoFile() async {
        // Arrange
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        let writer = VideoFileWriter(outputURL: outputURL)

        // Act: feed 3 synthetic frames, 1/24s apart
        for i in 0..<3 {
            let time = CMTime(value: Int64(i), timescale: 24)
            guard let sampleBuffer = Self.makeSampleBuffer(presentationTime: time) else {
                XCTFail("Failed to create synthetic sample buffer")
                return
            }
            writer.append(sampleBuffer)
        }
        let resultURL = await writer.finish()

        // Assert
        XCTAssertNotNil(resultURL)
        guard let resultURL else { return }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        let attributes = try? FileManager.default.attributesOfItem(atPath: resultURL.path)
        let fileSize = attributes?[.size] as? Int ?? 0
        XCTAssertGreaterThan(fileSize, 0, "Output .mov file should not be empty.")

        try? FileManager.default.removeItem(at: resultURL)
    }

    func testFinishWithNoFrames_ReturnsNil() async {
        // Arrange
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        let writer = VideoFileWriter(outputURL: outputURL)

        // Act
        let resultURL = await writer.finish()

        // Assert
        XCTAssertNil(resultURL, "Finishing without any appended frames should yield no file.")
    }

    // MARK: - Helpers

    private static func makeSampleBuffer(presentationTime: CMTime) -> CMSampleBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, 64, 64,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pixelBuffer else { return nil }

        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard let formatDescription else { return nil }

        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 24),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        let createStatus = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        guard createStatus == noErr else { return nil }
        return sampleBuffer
    }
}
