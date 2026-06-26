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
    @Published private(set) var cameraPermissionGranted = false

    private var session: MWDATCore.DeviceSession?
    private var stream: MWDATCamera.Stream?
    private var frameListenerToken: (any MWDATCore.AnyListenerToken)?
    private var streamErrorToken: (any MWDATCore.AnyListenerToken)?
    private var videoFileWriter: VideoFileWriter?

    func connect() async {
        do {
            // 1. Configure (mock intercepts this if enabled).
            do { try MWDATCore.Wearables.configure() }
            catch MWDATCore.WearablesError.alreadyConfigured { }

            // 2. Pair mock device after configure, then simulate it being worn and powered on.
            //    The SDK requires powerOn() + don() + unfold() before a session is eligible.
            #if DEBUG
            if isMockDeviceKitEnabled && isMockDevicePaired {
                let glasses: any MWDATMockDevice.MockDisplaylessGlasses
                if MWDATMockDevice.MockDeviceKit.shared.pairedDevices.isEmpty {
                    glasses = MWDATMockDevice.MockDeviceKit.shared.pairRaybanMeta()
                } else {
                    glasses = MWDATMockDevice.MockDeviceKit.shared.pairedDevices[0] as! any MWDATMockDevice.MockDisplaylessGlasses
                }
                glasses.powerOn()
                glasses.unfold()
                glasses.don()
                // Give the mock camera a synthetic feed so video capture produces
                // actual frames — without this, startVideoCapture() records nothing.
                await glasses.services.camera.setCameraFeed(cameraFacing: .front)
            }
            #endif

            // 3. Run startRegistration — this kicks off device registration.
            //    With initiallyRegistered=false (our mock config) the mock handles it
            //    without Meta AI. Catch alreadyRegistered as a safety net.
            do {
                try await MWDATCore.Wearables.shared.startRegistration()
            } catch MWDATCore.RegistrationError.alreadyRegistered { }

            // 4. Device registration/connection propagates asynchronously — the device
            //    is NOT in Wearables.shared.devices the instant startRegistration() returns.
            //    Wait for it to appear before creating a session, else start() throws
            //    noEligibleDevice (no device in a connected link state yet).
            let device = await waitForDevice(timeout: 8.0)

            let selector: any MWDATCore.DeviceSelector
            if let device {
                selector = MWDATCore.SpecificDeviceSelector(device: device)
            } else {
                selector = MWDATCore.AutoDeviceSelector(wearables: MWDATCore.Wearables.shared)
            }

            // 5. Create the session and start it, retrying while the link settles into
            //    a connected/eligible state.
            let newSession = try MWDATCore.Wearables.shared.createSession(deviceSelector: selector)
            try await startSessionWithRetry(newSession, attempts: 10, delay: 0.5)
            session = newSession
            isConnected = true

            // 6. Now that a device is connected, request camera access on the glasses.
            //    Doing this here (rather than at record time) means the prompt appears
            //    right after pairing, and PermissionError.noDevice can't occur.
            await ensureCameraPermission()
        } catch {
            print("GlassesManager: connect failed: \(error)")
            isConnected = false
        }
    }

    /// Requests camera permission on the connected glasses, if not already granted.
    /// Must be called only after a device session is connected, else the SDK throws
    /// PermissionError.noDevice.
    private func ensureCameraPermission() async {
        do {
            let status = try await MWDATCore.Wearables.shared.checkPermissionStatus(.camera)
            if status == .granted {
                cameraPermissionGranted = true
                return
            }
            let requested = try await MWDATCore.Wearables.shared.requestPermission(.camera)
            cameraPermissionGranted = (requested == .granted)
        } catch {
            print("GlassesManager: camera permission request failed: \(error)")
            cameraPermissionGranted = false
        }
    }

    /// Waits until a device appears in `Wearables.shared.devices`, returning the first
    /// one. Returns nil if none appears within `timeout` seconds.
    private func waitForDevice(timeout: TimeInterval) async -> MWDATCore.DeviceIdentifier? {
        if let existing = MWDATCore.Wearables.shared.devices.first { return existing }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let device = MWDATCore.Wearables.shared.devices.first { return device }
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        }
        return MWDATCore.Wearables.shared.devices.first
    }

    /// Starts the session, retrying while the device link settles into an eligible
    /// (connected) state. Rethrows the last error if all attempts fail.
    private func startSessionWithRetry(_ session: MWDATCore.DeviceSession, attempts: Int, delay: TimeInterval) async throws {
        var lastError: Error?
        for _ in 1...attempts {
            do {
                try session.start()
                return
            } catch MWDATCore.DeviceSessionError.noEligibleDevice {
                lastError = MWDATCore.DeviceSessionError.noEligibleDevice
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        if let lastError { throw lastError }
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
        // Surface any stream-level errors (decode failures, permission, hinges, thermal).
        streamErrorToken = newStream.errorPublisher.listen { error in
            print("GlassesManager: stream error: \(error)")
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
        if let token = streamErrorToken {
            await token.cancel()
        }
        frameListenerToken = nil
        streamErrorToken = nil
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

