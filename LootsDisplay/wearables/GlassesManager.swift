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

    func connect() async {
        do {
            // 1. Configure SDK — must happen AFTER mock is enabled (if in DEBUG mock flow).
            //    alreadyConfigured is fine on retry.
            do { try MWDATCore.Wearables.configure() }
            catch MWDATCore.WearablesError.alreadyConfigured { }

            #if DEBUG
            // 2. Pair mock device NOW, after configure — the SDK must be initialised first.
            //    pairMockRaybanMeta() only sets isMockDevicePaired; the real SDK call is here.
            if isMockDeviceKitEnabled && isMockDevicePaired
                && MWDATMockDevice.MockDeviceKit.shared.pairedDevices.isEmpty {
                _ = MWDATMockDevice.MockDeviceKit.shared.pairRaybanMeta()
            }
            #endif

            // 3. Always call startRegistration — this populates Wearables.shared.devices.
            //    Mock with initiallyRegistered=true throws alreadyRegistered, which is fine.
            do {
                try await MWDATCore.Wearables.shared.startRegistration()
            } catch MWDATCore.RegistrationError.alreadyRegistered { }

            // 4. Create and start session.
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
        do { try MWDATCore.Wearables.configure() }
        catch MWDATCore.WearablesError.alreadyConfigured { }
        catch { print("GlassesManager: configure failed: \(error)"); return false }

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
    @Published private(set) var isMockDeviceKitEnabled = false
    // Tracks user intent only — actual SDK pairRaybanMeta() is called in connect() after configure().
    @Published private(set) var isMockDevicePaired = false

    func enableMockDeviceKit() {
        MWDATMockDevice.MockDeviceKit.shared.enable()
        isMockDeviceKitEnabled = true
    }

    @discardableResult
    func pairMockRaybanMeta() -> Bool {
        guard !isMockDevicePaired else { return false }
        // Actual SDK pairRaybanMeta() is deferred to connect() which runs after configure().
        // The SDK requires configure() to be called before pairRaybanMeta().
        isMockDevicePaired = true
        return true
    }
    #endif
}
