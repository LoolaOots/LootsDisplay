import Foundation
import AVFoundation
import CoreMedia

/// Writes a stream of CMSampleBuffers (video frames backed by CVPixelBuffer) to a .mov file.
/// Pure AVFoundation — has no dependency on any glasses/camera SDK, so it can be exercised
/// in unit tests with synthetic sample buffers.
final class VideoFileWriter {
    private let outputURL: URL
    private var assetWriter: AVAssetWriter?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var writerSessionStarted = false
    private var didAppendAnyFrame = false

    init(outputURL: URL) {
        self.outputURL = outputURL
    }

    func append(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if assetWriter == nil {
            setUpAssetWriter(matching: pixelBuffer)
        }
        guard let assetWriter, let pixelBufferAdaptor else { return }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if !writerSessionStarted {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: presentationTime)
            writerSessionStarted = true
        }
        guard pixelBufferAdaptor.assetWriterInput.isReadyForMoreMediaData else { return }
        if pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
            didAppendAnyFrame = true
        }
    }

    func finish() async -> URL? {
        guard let assetWriter, didAppendAnyFrame else { return nil }
        pixelBufferAdaptor?.assetWriterInput.markAsFinished()
        await withCheckedContinuation { continuation in
            assetWriter.finishWriting {
                continuation.resume()
            }
        }
        return assetWriter.status == .completed ? outputURL : nil
    }

    private func setUpAssetWriter(matching pixelBuffer: CVPixelBuffer) {
        try? FileManager.default.removeItem(at: outputURL)
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else { return }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        input.expectsMediaDataInRealTime = true

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )

        writer.add(input)
        assetWriter = writer
        pixelBufferAdaptor = adaptor
    }
}
