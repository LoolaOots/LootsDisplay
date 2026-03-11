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
                                    ), in: 1...Double(store.isProUnlocked ? 180 : 60), step: 1.0) //pro members get 180s, free users get 60s
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
                        
                        //witmotion sensor data
                        //paywall
                        if store.isProUnlocked {
                            Section(header: Text("External Sensor")) {
                                if btManager.isConnected {
                                    HStack {
                                        Image(systemName: "sensor.fill")
                                            .foregroundColor(.green)
                                        Text("Connected: \(btManager.connectedPeripheral?.name ?? "Unknown WT901")")
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    Button(role: .destructive) {
                                        btManager.disconnect()
                                    } label: {
                                        Text("Disconnect Sensor")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else {
                                    NavigationLink(destination: BluetoothDeviceView(btManager: btManager)) {
                                        HStack {
                                            Text("Find WitMotion Sensor")
                                                .foregroundColor(.blue)
                                            Spacer()
                                            Image(systemName: "sensor")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }

                            if btManager.isConnected {
                                WT901DataView(manager: btManager, peripheral: btManager.connectedPeripheral!)
                            }
                            
                        } else {
                            Section(header: Text("External Sensor")) {
                                Button {
                                    showPaywall = true
                                } label: {
                                    HStack {
                                        Text("Find WitMotion Sensor")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        PremiumBadge()
                                    }
                                }
                                .sheet(isPresented: $showPaywall) {
                                    PaywallView()
                                }
                            }
                        }
                        
                        //phone live view data
                        PhoneDataView(sensors: sensors)
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
