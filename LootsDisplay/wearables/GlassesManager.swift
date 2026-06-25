import Foundation
import AVFoundation
import CoreMedia
import MWDATCore
import MWDATCamera
#if DEBUG
import MWDATMockDevice
#endif

@MainActor
final class GlassesManager: NSObject, ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var isRecording = false

    private var session: MWDATCore.DeviceSession?
    private var stream: MWDATCamera.Stream?
    private var frameListenerToken: (any MWDATCore.AnyListenerToken)?
    private var videoFileWriter: VideoFileWriter?

    /// Must be called once, before any other GlassesManager method (e.g. from LootsDisplayApp at launch).
    func configureSDK() {
        do {
            try MWDATCore.Wearables.configure()
        } catch {
            print("GlassesManager: configure failed: \(error)")
        }
    }

    func connect() async {
        do {
            if MWDATCore.Wearables.shared.registrationState != .registered {
                try await MWDATCore.Wearables.shared.startRegistration()
            }
            let selector = MWDATCore.AutoDeviceSelector(wearables: MWDATCore.Wearables.shared)
            let newSession = try MWDATCore.Wearables.shared.createSession(deviceSelector: selector)
            try newSession.start()
            session = newSession
            isConnected = true
        } catch {
            print("GlassesManager: connect failed: \(error)")
            isConnected = false
        }
    }

    func requestCameraPermission() async -> Bool {
        do {
            let status = try await MWDATCore.Wearables.shared.requestPermission(.camera)
            return status == .granted
        } catch {
            print("GlassesManager: camera permission request failed: \(error)")
            return false
        }
    }

    func startVideoCapture() {
        guard let session else { return }
        guard let newStream = try? session.addStream(
            config: MWDATCamera.StreamConfiguration(videoCodec: .raw, resolution: .medium, frameRate: 24)
        ) else {
            print("GlassesManager: failed to add camera stream")
            return
        }

        stream = newStream
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        let writer = VideoFileWriter(outputURL: outputURL)
        videoFileWriter = writer

        frameListenerToken = newStream.videoFramePublisher.listen { [weak writer] frame in
            writer?.append(frame.sampleBuffer)
        }

        Task { await newStream.start() }
        isRecording = true
    }

    func stopVideoCapture() async -> URL? {
        guard let stream else { return nil }
        await stream.stop()
        if let token = frameListenerToken {
            await token.cancel()
        }
        frameListenerToken = nil
        self.stream = nil
        isRecording = false

        guard let writer = videoFileWriter else { return nil }
        videoFileWriter = nil
        return await writer.finish()
    }

    #if DEBUG
    var isMockDeviceKitEnabled: Bool {
        MWDATMockDevice.MockDeviceKit.shared.isEnabled
    }

    func enableMockDeviceKit() {
        MWDATMockDevice.MockDeviceKit.shared.enable()
    }

    @discardableResult
    func pairMockRaybanMeta() -> Bool {
        guard MWDATMockDevice.MockDeviceKit.shared.pairedDevices.isEmpty else { return false }
        _ = MWDATMockDevice.MockDeviceKit.shared.pairRaybanMeta()
        return true
    }
    #endif
}
