import SwiftUI

struct ContentView: View {
    @StateObject var sensors = SensorManager()
    @StateObject var btManager = BluetoothManager()
    @State private var isDurationExpanded = false
    @State private var isDelayExpanded = false
    
    //subscription
    @State private var showPaywall = false
    @ObservedObject var store = SubscriptionManager.shared
        
    let delayOptions = [0, 3, 5, 10]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    NavigationLink(
                        destination: DataHistoryView(sensors: sensors),
                        isActive: $sensors.navigateToHistory
                    ) { EmptyView() }
                    
                    //Recording settings
                    List {
                        Section(header: Text("Recording Controls")) {
                            //Recording status
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
                            
                            //Recording limit button
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
                                        .bold()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                        .rotationEffect(.degrees(isDurationExpanded ? 90 : 0))
                                }
                            }
                            .disabled(sensors.isRecording)
                            
                            //Recording duration slider when expanded
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
                            
                            //Recording delay button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isDelayExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Label("Delay", systemImage: "hourglass")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(sensors.recordingDelay)s").bold()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                        .rotationEffect(.degrees(isDelayExpanded ? 90 : 0))
                                }
                            }
                            .disabled(sensors.isRecording)
                            
                            //Recording delay selection when expanded
                            if isDelayExpanded && !sensors.isRecording {
                                HStack(spacing: 0) {
                                    ForEach(delayOptions, id: \.self) { option in
                                        Button(action: {
                                            sensors.recordingDelay = option
                                        }) {
                                            Text("\(option)s")
                                                .font(.body)
                                                .fontWeight(sensors.recordingDelay == option ? .bold : .regular)
                                                .foregroundColor(sensors.recordingDelay == option ? .blue : .secondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 4)
                                .transition(.opacity)
                            }
                        }
                        
                        //Live view data
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
                        
                        Section(header: Text("Magnetometer")) {
                            SensorRow(label: "Mag X", value: String(format: "%.1f µT", sensors.magX))
                            SensorRow(label: "Mag Y", value: String(format: "%.1f µT", sensors.magY))
                            SensorRow(label: "Mag Z", value: String(format: "%.1f µT", sensors.magZ))
                        }
                        
                        Section(header: Text("G-Force")) {
                            SensorRow(label: "G-Force X", value: String(format: "%.2f g", sensors.gForceX))
                            SensorRow(label: "G-Force Y", value: String(format: "%.2f g", sensors.gForceY))
                            SensorRow(label: "G-Force Z", value: String(format: "%.2f g", sensors.gForceZ))
                        }
                        
                        //witmotion sensor data and paywall
                        if store.isProUnlocked {
                            NavigationLink(destination: BluetoothDeviceView(btManager: btManager)) {
                                HStack {
                                    Text("Find WitMotion Sensor")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "sensor")
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Text("Find WitMotion Sensor")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .sheet(isPresented: $showPaywall) {
                                PaywallView()
                            }
                        }
                    }
                    
                    //Bottom buttons
                    VStack(spacing: 12) {
                        //Start/Stop button
                        Button(action: { handleStartStop() }) {
                            Text(buttonText)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor)
                                .cornerRadius(10)
                        }
                        
                        //Recorded data button
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
                
                //Recording delay overlay
                if sensors.isCountingDown {
                    ZStack {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        
                        //countdown text
                        VStack(spacing: 20) {
                            Text("\(sensors.countdownRemaining)")
                                .font(.system(size: 120, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .transition(.scale)
                        }
                        .opacity(0.7)
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
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

    private func handleStartStop() {
        if sensors.isRecording || sensors.isCountingDown {
            sensors.stopRecording()
            sensors.isCountingDown = false
        } else {
            if sensors.sessions.count >= sensors.recordedHistoryLimit {
                sensors.showLimitAlert = true
            } else {
                if sensors.recordingDelay > 0 {
                    startCountdown()
                } else {
                    sensors.toggleRecording()
                }
            }
        }
    }

    private func startCountdown() {
        sensors.isCountingDown = true
        sensors.countdownRemaining = sensors.recordingDelay
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if sensors.countdownRemaining > 1 {
                sensors.countdownRemaining -= 1
            } else {
                timer.invalidate()
                sensors.isCountingDown = false
                sensors.toggleRecording()
            }
        }
    }

    private var buttonText: String {
        return sensors.isRecording ? "STOP RECORDING" : "START RECORDING"
    }

    private var buttonColor: Color {
        if sensors.isCountingDown {
            return .gray
        } else if sensors.isRecording {
            return .red
        } else {
            return .blue
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
            Text(value).bold().monospacedDigit().accessibilityIdentifier("\(label)_Value")
            
        }
    }
}
