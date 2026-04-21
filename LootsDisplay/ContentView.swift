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
                        Section(header: Text("section.recording_controls")) {
                            //Recording status
                            HStack {
                                Circle()
                                    .fill(sensors.isRecording ? Color.red : Color.gray)
                                    .frame(width: 10, height: 10)

                                if sensors.isRecording {
                                    Text(String(format: String(localized: "status.active"), sensors.secondsElapsed, sensors.recordingLimit))
                                        .bold()
                                        .foregroundColor(.red)
                                } else {
                                    Text("status.ready")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if !sensors.isRecording && !sensors.recordedData.isEmpty {
                                    Text(String(format: String(localized: "status.frames"), sensors.recordedData.count))
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
                                    Label("label.limit", systemImage: "timer")
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

                                    Text(String(format: String(localized: "label.seconds"), sensors.recordingLimit))
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
                                    Label("label.delay", systemImage: "hourglass")
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
                            Section(header: Text("section.external_sensor")) {
                                if btManager.isConnected {
                                    HStack {
                                        Image(systemName: "sensor.fill")
                                            .foregroundColor(.green)
                                        Text(String(format: String(localized: "sensor.connected"), btManager.connectedPeripheral?.name ?? String(localized: "sensor.unknown_wt901")))
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    Button(role: .destructive) {
                                        btManager.disconnect()
                                    } label: {
                                        Text("btn.disconnect_sensor")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else {
                                    NavigationLink(destination: BluetoothDeviceView(btManager: btManager)) {
                                        HStack {
                                            Text("btn.find_witmotion_sensor")
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
                            Section(header: Text("section.external_sensor")) {
                                Button {
                                    showPaywall = true
                                } label: {
                                    HStack {
                                        Text("btn.find_witmotion_sensor")
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
                            Text("btn.view_recorded_data")
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
            .navigationTitle("nav.live_sensor_data")
            .onAppear { sensors.startAllSensors(with: btManager) }
            .alert("alert.recording_limit.title", isPresented: $sensors.showLimitAlert) {
                Button("btn.ok", role: .cancel) {
                    sensors.showLimitAlert = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        sensors.navigateToHistory = true
                    }
                }
            } message: {
                Text("alert.recording_limit.message")
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
        return sensors.isRecording ? String(localized: "btn.stop_recording") : String(localized: "btn.start_recording")
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
            Text(LocalizedStringKey(label)).foregroundColor(.secondary)
            Spacer()
            Text(value).bold().monospacedDigit().accessibilityIdentifier("\(label)_Value")
        }
    }
}
