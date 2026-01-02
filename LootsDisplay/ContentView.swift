import SwiftUI

struct ContentView: View {
    @StateObject var sensors = SensorManager()

    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(
                        destination: DataHistoryView(sensors: sensors),
                        isActive: $sensors.navigateToHistory
                ) { EmptyView() }
                
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
                        SensorRow(label: "Yaw", value: String(format: "%.2f°", sensors.attitude.yaw * 180 / .pi))
                        SensorRow(label: "Accel X", value: String(format: "%.3f g", sensors.acceleration.x))
                        SensorRow(label: "Accel Y", value: String(format: "%.3f g", sensors.acceleration.y))
                        SensorRow(label: "Accel Z", value: String(format: "%.3f g", sensors.acceleration.z))
                    }

                    Section(header: Text("GPS & Environment")) {
                        SensorRow(label: "Speed", value: String(format: "%.1f mph", sensors.speed * 2.237))
                        SensorRow(label: "Heading", value: String(format: "%.1f°", sensors.heading))
                        SensorRow(label: "Pressure", value: String(format: "%.2f kPa", sensors.pressure))
                        SensorRow(label: "Latitude", value: String(format: "%.6f", sensors.locationData?.coordinate.latitude ?? 0.0))
                        SensorRow(label: "Longitude", value: String(format: "%.6f", sensors.locationData?.coordinate.longitude ?? 0.0))
                    }
                    
                    Section(header: Text("Gyroscope")) {
                        SensorRow(label: "Rotation X", value: String(format: "%.1f °/s", sensors.gyroX))
                        SensorRow(label: "Rotation Y", value: String(format: "%.1f °/s", sensors.gyroY))
                        SensorRow(label: "Rotation Z", value: String(format: "%.1f °/s", sensors.gyroZ))
                    }

                    Section {
                        SensorRow(label: "Mag X", value: String(format: "%.1f µT", sensors.magX))
                        SensorRow(label: "Mag Y", value: String(format: "%.1f µT", sensors.magY))
                        SensorRow(label: "Mag Z", value: String(format: "%.1f µT", sensors.magZ))
                    } header: {
                        HStack {
                            Text("Magnetometer")
                            Spacer()
                            calibrationStatusView(accuracy: sensors.magAccuracy)
                        }
                    }
                    
                    Section(header: Text("G-Force")) {
                        SensorRow(label: "G-Force X", value: String(format: "%.2f g", sensors.gForceX))
                        SensorRow(label: "G-Force Y", value: String(format: "%.2f g", sensors.gForceY))
                        SensorRow(label: "G-Force Z", value: String(format: "%.2f g", sensors.gForceZ))
                    }
                    
                    Section {
                        NavigationLink(destination: ExperimentalFeaturesView()) {
                            HStack {
                                Text("Experimental Features")
                                    .foregroundColor(.blue) // Optional: Makes it look more like a button
                                Spacer()
                                Image(systemName: "flask")
                                    .foregroundColor(.secondary)
                            }
                        }
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
                            .disabled(sensors.sessions.isEmpty)
                            }
                            .padding()
                        }
                        .navigationTitle("Live Sensor Data")
                        .onAppear { sensors.startAllSensors() }
                        .alert("Recording Limit Reached", isPresented: $sensors.showLimitAlert) {
                            Button("OK", role: .cancel) {
                                sensors.showLimitAlert = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    sensors.navigateToHistory = true
                                }
                            }
                        } message: {
                            Text("You have reached the maximum saved recordings. Remove an existing entry to start a new session.")
                        }
            
            
        }
    }
}

@ViewBuilder
func calibrationStatusView(accuracy: Int) -> some View {
    let status: (text: String, color: Color) = {
        switch accuracy {
        case 2:  return ("Calibrated", .green)
        case 1:  return ("Low Accuracy", .yellow)
        case 0:  return ("Needs Calibration", .orange)
        default: return ("Not Ready", .red)
        }
    }()
    
    HStack(spacing: 4) {
        Circle().fill(status.color).frame(width: 6, height: 6)
        Text(status.text).font(.caption2).foregroundColor(status.color)
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
