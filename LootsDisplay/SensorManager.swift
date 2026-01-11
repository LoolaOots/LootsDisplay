////
////  SensorManager.swift
////  LootsDisplay
////
////  Created by Nat on 12/28/25.
////

import Foundation
import CoreMotion
import CoreLocation
import Combine
import UIKit

struct SensorFrame: Codable {
    let timestamp: Date
    var label: String?
    
    let pitch: Double
    let roll: Double
    let yaw: Double
    
    let latitude: Double
    let longitude: Double
    let pressure: Double
    let heading: Double
    let speed: Double
    // User Acceleration
    let accelX: Double
    let accelY: Double
    let accelZ: Double
    // Total G-Force (Total Accel)
    let gForceX: Double
    let gForceY: Double
    let gForceZ: Double
    // Gyroscope (Rotation Rate)
    let gyroX: Double
    let gyroY: Double
    let gyroZ: Double
    // Magnetometer (Calibrated Magnetic Field)
    let magX: Double
    let magY: Double
    let magZ: Double
    
    // WIT Motion Sensor Data
    let witAccX: Double?
    let witAccY: Double?
    let witAccZ: Double?
    let witRoll: Double?
    let witPitch: Double?
    let witYaw: Double?
    
    mutating func updateLabel(_ newLabel: String) {
        self.label = newLabel
    }
}

struct RecordingSession: Identifiable, Codable {
    var id = UUID()
    let startTime: Date
    var frames: [SensorFrame]
    
    var title: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: startTime)
    }
}

class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let locationManager = CLLocationManager()
    private let limitKey = "user_recording_limit"
    
    // UI State
    @Published var acceleration = (x: 0.0, y: 0.0, z: 0.0)
    @Published var attitude = (pitch: 0.0, roll: 0.0, yaw: 0.0)
    @Published var altitude: Double = 0.0
    @Published var pressure: Double = 0.0
    @Published var locationData: CLLocation?
    @Published var heading: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var gForceX: Double = 0.0
    @Published var gForceY: Double = 0.0
    @Published var gForceZ: Double = 0.0
    @Published var gyroX: Double = 0.0
    @Published var gyroY: Double = 0.0
    @Published var gyroZ: Double = 0.0
    @Published var magX: Double = 0.0
    @Published var magY: Double = 0.0
    @Published var magZ: Double = 0.0
    @Published var magAccuracy: Int = -1
    
    // Recording State
    @Published var isRecording = false
    @Published var recordedData: [SensorFrame] = []
    @Published var secondsElapsed = 0 // Track the recording duration
    //Persistent data via UserDefaults
    @Published var recordingLimit: Int {
        didSet {
            UserDefaults.standard.set(recordingLimit, forKey: limitKey) //get user set recording duration or use default
        }
    }
    
    //Recording
    @Published var sessions: [RecordingSession] = []
    
    //Maximum recordings
    @Published var showLimitAlert = false // For the "Max Reached" popup
    @Published var navigateToHistory = false //navigates to datahistoryview if recording limit is reached
    private var recordedHistoryLimit = 10
    
    private var recordingTimer: Timer?
    private var secondsTimer: Timer? // Timer for the UI counter
    
    override init() {
        let savedLimit = UserDefaults.standard.integer(forKey: limitKey)
        self.recordingLimit = savedLimit > 0 ? savedLimit : 45
        super.init()
        LocalFileManager.setupFolder()
        self.sessions = LocalFileManager.loadSessions()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    // Toggle Recording
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            DispatchQueue.main.async {
                if self.sessions.count >= self.recordedHistoryLimit {
                    self.showLimitAlert = true
                } else {
                    self.startRecording()
                }
            }
        }
    }

    private func startRecording() {
        recordedData.removeAll()
        secondsElapsed = 0
        isRecording = true
            
        //dynamic limit set by the slider
        recordingTimer = Timer.scheduledTimer(withTimeInterval: Double(recordingLimit), repeats: false) { _ in
            self.stopRecording()
        }
            
        secondsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.secondsElapsed < self.recordingLimit {
                self.secondsElapsed += 1
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        secondsTimer?.invalidate()
        
        // Save the finished recording as a session
        if !recordedData.isEmpty {
            let newSession = RecordingSession(startTime: Date().addingTimeInterval(-Double(secondsElapsed)), frames: recordedData)
            LocalFileManager.saveSession(newSession)
            self.sessions = LocalFileManager.loadSessions()
        }
        
        recordingTimer = nil
        secondsTimer = nil
        print("Stopped! Captured \(recordedData.count) samples.")
    }
    
    func deleteSession(at offsets: IndexSet) {
        offsets.forEach { index in
            let session = sessions[index]
            LocalFileManager.deleteSession(id: session.id)
        }
        self.sessions = LocalFileManager.loadSessions() // Refresh list
        DispatchQueue.main.async {
            self.recordedData = []
            self.secondsElapsed = 0
        }
    }
    
    func deleteAllSessions() {
        sessions.forEach { session in
            LocalFileManager.deleteSession(id: session.id)
        }
        DispatchQueue.main.async {
            self.sessions = LocalFileManager.loadSessions()
            self.recordedData = []
            self.secondsElapsed = 0
        }
    }

    func startAllSensors(with btManager: BluetoothManager) {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { data, _ in
                guard let motion = data else { return }
                let toDegrees = 180.0 / .pi
                
                //Live view
                self.acceleration = (motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z)
                self.attitude = (motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw)
                self.gyroX = motion.rotationRate.x * toDegrees
                self.gyroY = motion.rotationRate.y * toDegrees
                self.gyroZ = motion.rotationRate.z * toDegrees
                self.magX = motion.magneticField.field.x
                self.magY = motion.magneticField.field.y
                self.magZ = motion.magneticField.field.z
                self.magAccuracy = Int(motion.magneticField.accuracy.rawValue)
                self.gForceX = motion.userAcceleration.x + motion.gravity.x
                self.gForceY = motion.userAcceleration.y + motion.gravity.y
                self.gForceZ = motion.userAcceleration.z + motion.gravity.z
                //self.speed = self.locationManager.location?.speed ?? 0.0
                let rawSpeed = self.locationManager.location?.speed ?? 0.0
                self.speed = max(0.0, rawSpeed)
                
                // Capture data
                if self.isRecording {
                    let totalX = motion.userAcceleration.x + motion.gravity.x
                    let totalY = motion.userAcceleration.y + motion.gravity.y
                    let totalZ = motion.userAcceleration.z + motion.gravity.z
                    let currentSpeed = self.locationManager.location?.speed ?? 0.0
                    let frame = SensorFrame(
                        timestamp: Date(),
                        label: nil,
                        pitch: motion.attitude.pitch,
                        roll: motion.attitude.roll,
                        yaw: motion.attitude.yaw,
                        latitude: self.locationData?.coordinate.latitude ?? 0,
                        longitude: self.locationData?.coordinate.longitude ?? 0,
                        pressure: self.pressure,
                        heading: self.heading,
                        speed: currentSpeed > 0 ? currentSpeed : 0,
                        accelX: motion.userAcceleration.x,
                        accelY: motion.userAcceleration.y,
                        accelZ: motion.userAcceleration.z,
                        gForceX: totalX,
                        gForceY: totalY,
                        gForceZ: totalZ,
                        gyroX: motion.rotationRate.x * toDegrees,
                        gyroY: motion.rotationRate.y * toDegrees,
                        gyroZ: motion.rotationRate.z * toDegrees,
                        magX: motion.magneticField.field.x,
                        magY: motion.magneticField.field.y,
                        magZ: motion.magneticField.field.z,
                        //WIT Sensor Data
                        witAccX: btManager.isConnected ? Double(btManager.accX) : nil,
                        witAccY: btManager.isConnected ? Double(btManager.accY) : nil,
                        witAccZ: btManager.isConnected ? Double(btManager.accZ) : nil,
                        witRoll: btManager.isConnected ? Double(btManager.angleX) : nil,
                        witPitch: btManager.isConnected ? Double(btManager.angleY) : nil,
                        witYaw: btManager.isConnected ? Double(btManager.angleZ) : nil
                    )
                    self.recordedData.append(frame)
                }
            }
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { data, _ in
                guard let alt = data else { return }
                self.pressure = alt.pressure.doubleValue
            }
        }

        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.locationData = locations.last
        self.speed = max(0, location.speed)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading.magneticHeading
    }
    
    ///Add Label
    func applyLabelToSession(id: UUID, label: String) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            // Create a copy of the session
            var updatedSession = sessions[index]
            
            // Use 'indices' to modify the frames directly in place
            for i in updatedSession.frames.indices {
                updatedSession.frames[i].updateLabel(label)
            }
            
            LabelManager.shared.saveLabelToHistory(label)
            
            DispatchQueue.main.async {
                self.sessions[index] = updatedSession
                LocalFileManager.saveSession(updatedSession)
            }
        }
    }
}

