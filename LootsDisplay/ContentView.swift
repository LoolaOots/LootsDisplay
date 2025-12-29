//
//
//import SwiftUI
//
//struct ContentView: View {
//    @StateObject var sensors = SensorManager()
//
//    var body: some View {
//        NavigationView {
//            List {
//                Section(header: Text("Motion & Attitude")) {
//                    SensorRow(label: "Pitch", value: String(format: "%.2f°", sensors.attitude.pitch * 180 / .pi))
//                    SensorRow(label: "Roll", value: String(format: "%.2f°", sensors.attitude.roll * 180 / .pi))
//                    SensorRow(label: "User Accel X", value: String(format: "%.2f g", sensors.acceleration.x))
//                }
//
//                Section(header: Text("GPS & Environment")) {
//                    SensorRow(label: "Latitude", value: "\(sensors.locationData?.coordinate.latitude ?? 0.0)")
//                    SensorRow(label: "Longitude", value: "\(sensors.locationData?.coordinate.longitude ?? 0.0)")
//                    SensorRow(label: "Heading", value: String(format: "%.1f°", sensors.heading))
//                    SensorRow(label: "Pressure", value: String(format: "%.2f kPa", sensors.pressure))
//                }
//            }
//            .navigationTitle("Live Sensor Data")
//            .onAppear {
//                sensors.startAllSensors()
//            }
//        }
//    }
//}
//
//struct SensorRow: View {
//    let label: String
//    let value: String
//    
//    var body: some View {
//        HStack {
//            Text(label).foregroundColor(.secondary)
//            Spacer()
//            Text(value).bold().monospacedDigit()
//        }
//    }
//}

import SwiftUI

struct ContentView: View {
    @StateObject var sensors = SensorManager()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Recording Status")) {
                        HStack {
                            Circle()
                                .fill(sensors.isRecording ? Color.red : Color.gray)
                                .frame(width: 10, height: 10)
                            
                            // Dynamic text showing the time recorded
                            if sensors.isRecording {
                                Text("Recording Active: \(sensors.secondsElapsed)s / 45s")
                                    .bold()
                                    .foregroundColor(.red)
                            } else {
                                Text("Ready to Record (Max 45s)")
                            }
                            
                            Spacer()
                            
                            if !sensors.isRecording && !sensors.recordedData.isEmpty {
                                Text("\(sensors.recordedData.count) frames")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Section(header: Text("Motion & Attitude")) {
                        SensorRow(label: "Pitch", value: String(format: "%.2f°", sensors.attitude.pitch * 180 / .pi))
                        SensorRow(label: "Roll", value: String(format: "%.2f°", sensors.attitude.roll * 180 / .pi))
                        SensorRow(label: "User Accel X", value: String(format: "%.2f g", sensors.acceleration.x))
                    }

                    Section(header: Text("GPS & Environment")) {
                        SensorRow(label: "Latitude", value: "\(sensors.locationData?.coordinate.latitude ?? 0.0)")
                        SensorRow(label: "Longitude", value: "\(sensors.locationData?.coordinate.longitude ?? 0.0)")
                        SensorRow(label: "Heading", value: String(format: "%.1f°", sensors.heading))
                        SensorRow(label: "Pressure", value: String(format: "%.2f kPa", sensors.pressure))
                    }
                }
                VStack(spacing: 12) {
                    // Start/Stop Button
                    Button(action: { sensors.toggleRecording() }) {
                        Text(sensors.isRecording ? "STOP RECORDING" : "START RECORDING")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(sensors.isRecording ? Color.red : Color.blue)
                            .cornerRadius(10)
                        }

                        // View Recorded Data Button
                        NavigationLink(destination: DataHistoryView(sensors: sensors)) {
                            Text("VIEW RECORDED DATA")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(sensors.sessions.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                            }
                            .disabled(sensors.sessions.isEmpty) // Grayed out and unusable if empty
                            }
                            .padding()
                        }
                        .navigationTitle("Live Sensor Data")
                        .onAppear { sensors.startAllSensors() }
        }
    }
}

struct SensorRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold().monospacedDigit()
        }
    }
}
