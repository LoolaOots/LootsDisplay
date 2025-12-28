////
////  SensorManager.swift
////  LootsDisplay
////
////  Created by Nat on 12/28/25.
////

//
//import Foundation
//import CoreMotion
//import CoreLocation
//import Combine
//
//class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private let motionManager = CMMotionManager()
//    private let altimeter = CMAltimeter()
//    private let locationManager = CLLocationManager()
//    
//    // Motion Data
//    @Published var acceleration = (x: 0.0, y: 0.0, z: 0.0)
//    @Published var attitude = (pitch: 0.0, roll: 0.0, yaw: 0.0)
//    
//    // Environment & GPS
//    @Published var altitude: Double = 0.0
//    @Published var pressure: Double = 0.0
//    @Published var locationData: CLLocation?
//    @Published var heading: Double = 0.0
//
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.requestWhenInUseAuthorization()
//    }
//
//    func startAllSensors() {
//        // 1. Device Motion (Gyro + Accel + Attitude)
//        if motionManager.isDeviceMotionAvailable {
//            motionManager.deviceMotionUpdateInterval = 0.1
//            motionManager.startDeviceMotionUpdates(to: .main) { data, _ in
//                guard let motion = data else { return }
//                self.acceleration = (motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z)
//                self.attitude = (motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw)
//            }
//        }
//
//        // 2. Altimeter (Pressure & Relative Altitude)
//        if CMAltimeter.isRelativeAltitudeAvailable() {
//            altimeter.startRelativeAltitudeUpdates(to: .main) { data, _ in
//                guard let alt = data else { return }
//                self.altitude = alt.relativeAltitude.doubleValue
//                self.pressure = alt.pressure.doubleValue // in kilopascals
//            }
//        }
//
//        // 3. Location & Heading
//        locationManager.startUpdatingLocation()
//        locationManager.startUpdatingHeading()
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        self.locationData = locations.last
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        self.heading = newHeading.magneticHeading
//    }
//}
import Foundation
import CoreMotion
import CoreLocation
import Combine

// Structure to hold one "frame" of data
struct SensorFrame: Codable {
    let timestamp: Date
    let pitch: Double
    let roll: Double
    let accelX: Double
    let latitude: Double
    let longitude: Double
    let pressure: Double
}

class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let locationManager = CLLocationManager()
    
    // UI State
    @Published var acceleration = (x: 0.0, y: 0.0, z: 0.0)
    @Published var attitude = (pitch: 0.0, roll: 0.0, yaw: 0.0)
    @Published var altitude: Double = 0.0
    @Published var pressure: Double = 0.0
    @Published var locationData: CLLocation?
    @Published var heading: Double = 0.0
    
    // Recording State
    @Published var isRecording = false
    @Published var recordedData: [SensorFrame] = []
    @Published var secondsElapsed = 0 // Track the recording duration
        
    private var recordingTimer: Timer?
    private var secondsTimer: Timer? // Timer for the UI counter
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    // Toggle Recording
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        recordedData.removeAll()
        secondsElapsed = 0
        isRecording = true
            
        // Timer for the 45-second limit
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: false) { _ in
            self.stopRecording()
        }
            
        // Timer to update the UI counter every second
        secondsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.secondsElapsed < 45 {
                self.secondsElapsed += 1
            }
        }
    }

    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        secondsTimer?.invalidate()
        recordingTimer = nil
        secondsTimer = nil
        saveDataToDisk()
    }

    private func saveDataToDisk() {
        print("Stopped! Captured \(recordedData.count) samples.")
        // Here you could convert recordedData to a JSON or CSV file
    }

    func startAllSensors() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { data, _ in
                guard let motion = data else { return }
                self.acceleration = (motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z)
                self.attitude = (motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw)
                
                // Capture data if recording is active
                if self.isRecording {
                    let frame = SensorFrame(
                        timestamp: Date(),
                        pitch: motion.attitude.pitch,
                        roll: motion.attitude.roll,
                        accelX: motion.userAcceleration.x,
                        latitude: self.locationData?.coordinate.latitude ?? 0,
                        longitude: self.locationData?.coordinate.longitude ?? 0,
                        pressure: self.pressure
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
        self.locationData = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading.magneticHeading
    }
}
