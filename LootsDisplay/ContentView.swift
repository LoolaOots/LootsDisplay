import SwiftUI

struct ContentView: View {
    @StateObject var sensors = SensorManager()
    @StateObject var btManager = BluetoothManager()
    @State private var isDurationExpanded = false

    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(
                        destination: DataHistoryView(sensors: sensors),
                        isActive: $sensors.navigateToHistory
                ) { EmptyView() }
                
                List {
                    Section(header: Text("Recording Controls")) {
                        // Recording Status
                        HStack {
                            Circle()
                                .fill(sensors.isRecording ? Color.red : Color.gray)
                                .frame(width: 10, height: 10)
                            
                            if sensors.isRecording {
                                Text("Active: \(sensors.secondsElapsed)s / \(sensors.recordingLimit)s")
                                    .bold()
                                    .foregroundColor(.red)
                            } else {
                                Text("Ready")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if !sensors.isRecording && !sensors.recordedData.isEmpty {
                                Text("\(sensors.recordedData.count) frames")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        // Expandable Duration slider
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isDurationExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Label("Limit", systemImage: "timer")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(sensors.recordingLimit)s")
                                    //.foregroundColor(.blue)
                                    .bold()
                                Image(systemName: "chevron.right")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(isDurationExpanded ? 90 : 0))
                            }
                        }
                        .disabled(sensors.isRecording)

                        // Recording duration slider (Hidden when collapsed)
                        if isDurationExpanded && !sensors.isRecording {
                            VStack(spacing: 15) {
                                Slider(value: Binding(
                                    get: { Double(sensors.recordingLimit) },
                                    set: { sensors.recordingLimit = Int($0) }
                                ), in: 1...60, step: 1.0)
                                .accentColor(.blue)
                                .scaleEffect(0.95)
                                
                                Text("\(sensors.recordingLimit) Seconds")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
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
                    
                    
                    //Sensor Data
                    
                    Section {
                        if btManager.isConnected {
                            HStack {
                                Image(systemName: "sensor.fill")
                                    .foregroundColor(.green)
                                Text("Connected: \(btManager.connectedPeripheral?.name ?? "Unknown WT901")")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        } else {
                            NavigationLink(destination: BluetoothDeviceView(btManager: btManager)) {
                                HStack {
                                    Text("Find Sensors")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "sensor")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if btManager.isConnected {
                            Section {
                                Button(role: .destructive) {
                                    btManager.disconnect()
                                } label: {
                                    Text("Disconnect Sensor")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        
                    } header: {
                        Text("External Sensor")
                    }
                    
                    if btManager.isConnected {
                        Section(header: Text("WIT Motion: Acceleration (G)")) {
                            SensorRow(label: "WIT Accel X", value: String(format: "%.3f", btManager.accX))
                            SensorRow(label: "WIT Accel Y", value: String(format: "%.3f", btManager.accY))
                            SensorRow(label: "WIT Accel Z", value: String(format: "%.3f", btManager.accZ))
                        }
                        
                        Section(header: Text("WIT Motion: Orientation")) {
                            SensorRow(label: "WIT Roll", value: String(format: "%.2f°", btManager.angleX))
                            SensorRow(label: "WIT Pitch", value: String(format: "%.2f°", btManager.angleY))
                            SensorRow(label: "WIT Yaw", value: String(format: "%.2f°", btManager.angleZ))
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
                        .onAppear { sensors.startAllSensors(with: btManager) }
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
            Text(value).bold().monospacedDigit().accessibilityIdentifier("\(label)_Value")
            
        }
    }
}
