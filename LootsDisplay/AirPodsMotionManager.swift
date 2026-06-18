import Foundation
import CoreMotion

class AirPodsMotionManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    private let headphoneMotionManager = CMHeadphoneMotionManager()

    @Published var isConnected: Bool = false

    //Attitude
    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0
    @Published var yaw: Double = 0.0

    //User Acceleration
    @Published var accelX: Double = 0.0
    @Published var accelY: Double = 0.0
    @Published var accelZ: Double = 0.0

    //Gravity
    @Published var gravityX: Double = 0.0
    @Published var gravityY: Double = 0.0
    @Published var gravityZ: Double = 0.0

    //Gyroscope
    @Published var gyroX: Double = 0.0
    @Published var gyroY: Double = 0.0
    @Published var gyroZ: Double = 0.0

    var isAvailable: Bool { headphoneMotionManager.isDeviceMotionAvailable }

    override init() {
        super.init()
        headphoneMotionManager.delegate = self
    }

    func startUpdates() {
        guard headphoneMotionManager.isDeviceMotionAvailable else { return }
        headphoneMotionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let motion = data else { return }
            let toDegrees = 180.0 / .pi

            self.roll = motion.attitude.roll
            self.pitch = motion.attitude.pitch
            self.yaw = motion.attitude.yaw

            self.accelX = motion.userAcceleration.x
            self.accelY = motion.userAcceleration.y
            self.accelZ = motion.userAcceleration.z

            self.gravityX = motion.gravity.x
            self.gravityY = motion.gravity.y
            self.gravityZ = motion.gravity.z

            self.gyroX = motion.rotationRate.x * toDegrees
            self.gyroY = motion.rotationRate.y * toDegrees
            self.gyroZ = motion.rotationRate.z * toDegrees
        }
    }

    func stopUpdates() {
        headphoneMotionManager.stopDeviceMotionUpdates()
        isConnected = false
    }

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
}
