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
            // 1. Configure (mock intercepts this if enabled).
            do { try MWDATCore.Wearables.configure() }
            catch MWDATCore.WearablesError.alreadyConfigured { }

            // 2. Pair mock device after configure (SDK must be initialised first).
            #if DEBUG
            if isMockDeviceKitEnabled && isMockDevicePaired
                && MWDATMockDevice.MockDeviceKit.shared.pairedDevices.isEmpty {
                _ = MWDATMockDevice.MockDeviceKit.shared.pairRaybanMeta()
                print("GlassesManager: mock device paired, pairedDevices=\(MWDATMockDevice.MockDeviceKit.shared.pairedDevices.count)")
            }
            #endif

            // 3. Run startRegistration — this populates Wearables.shared.devices.
            //    With initiallyRegistered=false (our mock config) the mock handles it
            //    without Meta AI. Catch alreadyRegistered as a safety net.
            do {
                try await MWDATCore.Wearables.shared.startRegistration()
                print("GlassesManager: registration succeeded, devices=\(MWDATCore.Wearables.shared.devices)")
            } catch MWDATCore.RegistrationError.alreadyRegistered {
                print("GlassesManager: already registered, devices=\(MWDATCore.Wearables.shared.devices)")
            }

            // 4. Build device selector. For mock: fall back to the paired device ID
            //    directly if Wearables.shared.devices is still empty (timing safety net).
            let selector: any MWDATCore.DeviceSelector
            #if DEBUG
            if isMockDeviceKitEnabled,
               MWDATCore.Wearables.shared.devices.isEmpty,
               let mockDevice = MWDATMockDevice.MockDeviceKit.shared.pairedDevices.first {
                print("GlassesManager: devices empty — using SpecificDeviceSelector for \(mockDevice.deviceIdentifier)")
                selector = MWDATCore.SpecificDeviceSelector(device: mockDevice.deviceIdentifier)
            } else {
                selector = MWDATCore.AutoDeviceSelector(wearables: MWDATCore.Wearables.shared)
            }
            #else
            selector = MWDATCore.AutoDeviceSelector(wearables: MWDATCore.Wearables.shared)
            #endif

            print("GlassesManager: creating session, activeDevice=\(String(describing: selector.activeDevice))")
            let newSession = try MWDATCore.Wearables.shared.createSession(deviceSelector: selector)
            try newSession.start()
            session = newSession
            isConnected = true
        } catch {
            print("GlassesManager: connect failed: \(error)")
            isConnected = false
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
    // Tracks user intent only — actual SDK pairRaybanMeta() runs in connect() after configure().
    @Published private(set) var isMockDevicePaired = false

    func enableMockDeviceKit() {
        // initiallyRegistered=false lets startRegistration() actually run (mock-intercepted),
        // which is what populates Wearables.shared.devices. With true, it's pre-set as
        // registered and startRegistration() is skipped, leaving devices empty.
        MWDATMockDevice.MockDeviceKit.shared.enable(
            config: MWDATMockDevice.MockDeviceKitConfig(initiallyRegistered: false)
        )
        isMockDeviceKitEnabled = true
    }

    @discardableResult
    func pairMockRaybanMeta() -> Bool {
        guard !isMockDevicePaired else { return false }
        // Actual SDK pairRaybanMeta() is deferred to connect() after configure().
        isMockDevicePaired = true
        return true
    }
    #endif
}

