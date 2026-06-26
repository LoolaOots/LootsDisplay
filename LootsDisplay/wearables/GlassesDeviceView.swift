import SwiftUI

struct GlassesDeviceView: View {
    @ObservedObject var glassesManager: GlassesManager
    @ObservedObject var btManager: BluetoothManager
    @State private var isConnecting = false

    var body: some View {
        List {
            #if DEBUG
            Section(header: Text("Mock Device Kit")) {
                if glassesManager.isMockDeviceKitEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Mock Device Kit enabled")
                    }
                    if glassesManager.isMockDevicePaired {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                            Text("Ray-Ban Meta paired")
                        }
                    } else {
                        Button("Pair Mock Ray-Ban Meta") {
                            glassesManager.pairMockRaybanMeta()
                        }
                    }
                } else {
                    Button("Enable Mock Device Kit") {
                        glassesManager.enableMockDeviceKit()
                    }
                }
            }
            #endif

            Section(header: Text("Glasses Connection")) {
                HStack {
                    Image(systemName: glassesManager.isConnected ? "eyeglasses" : "eyeglasses.slash")
                        .foregroundColor(glassesManager.isConnected ? .green : .secondary)
                    if glassesManager.isConnected {
                        Text("Connected")
                            .fontWeight(.medium)
                    } else {
                        Text("Not connected")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if isConnecting {
                        ProgressView()
                    }
                }

                if glassesManager.isConnected {
                    HStack {
                        Image(systemName: glassesManager.cameraPermissionGranted ? "camera.fill" : "camera")
                            .foregroundColor(glassesManager.cameraPermissionGranted ? .green : .secondary)
                        Text(glassesManager.cameraPermissionGranted ? "Camera access granted" : "Camera access needed")
                            .foregroundColor(glassesManager.cameraPermissionGranted ? .primary : .secondary)
                        Spacer()
                    }
                }

                if !glassesManager.isConnected {
                    Button("Connect Glasses") {
                        Task {
                            isConnecting = true
                            await glassesManager.connect()
                            isConnecting = false
                        }
                    }
                    .disabled(isConnecting)
                }
            }
        }
        .navigationTitle("Meta Glasses")
        .onAppear {
            btManager.requestBluetoothAccess()
        }
    }
}
