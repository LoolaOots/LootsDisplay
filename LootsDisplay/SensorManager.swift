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


struct SensorFrame: Codable {
    let timestamp: Date
    let pitch: Double
    let roll: Double
    let accelX: Double
    let latitude: Double
    let longitude: Double
    let pressure: Double
}

struct RecordingSession: Identifiable, Codable {
    var id = UUID()
    let startTime: Date
    let frames: [SensorFrame]
    
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
        
    @Published var sessions: [RecordingSession] = []
    
    @Published var showLimitAlert = false // For the "Max Reached" popup
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    @Published var navigateToHistory = false //navigates to datahistoryview if recording limit is reached
    
    
    private var recordingTimer: Timer?
    private var secondsTimer: Timer? // Timer for the UI counter
    
    override init() {
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
                if self.sessions.count >= 3 {
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
        
        // Save the finished recording as a session
        if !recordedData.isEmpty {
            let newSession = RecordingSession(startTime: Date().addingTimeInterval(-Double(secondsElapsed)), frames: recordedData)
            LocalFileManager.saveSession(newSession)
            self.sessions = LocalFileManager.loadSessions()
        }
        
        recordingTimer = nil
        secondsTimer = nil
        saveDataToDisk() //DELETE OR CHANGE LATER
    }

    private func saveDataToDisk() {
        print("Stopped! Captured \(recordedData.count) samples.")
        // Here you could convert recordedData to a JSON or CSV file
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
    
    func exportSession(_ session: RecordingSession) {
        guard let url = URL(string: "https://d338dd53d6ef.ngrok.app/400-route") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(session.frames)
            request.httpBody = jsonData
            URLSession.shared.dataTask(with: request) { data, response, error in
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse?.statusCode ?? 0
                let newTitle = (statusCode == 200) ? "Export Successful" : "Export Failed"
                DispatchQueue.main.async {
                    self.showAlert = false
                    
                    self.alertTitle = newTitle
                    self.showAlert = true
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.alertTitle = "Export Failed"
                self.showAlert = true
            }
        }
    }
}

