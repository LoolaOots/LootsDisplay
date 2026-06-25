import SwiftUI

struct GlassesDeviceView: View {
    @ObservedObject var glassesManager: GlassesManager
    @State private var isConnecting = false
    @State private var permissionDenied = false

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
                    Button("Pair Mock Ray-Ban Meta") {
                        glassesManager.pairMockRaybanMeta()
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

                if !glassesManager.isConnected {
                    Button("Connect Glasses") {
                        Task {
                            isConnecting = true
                            let granted = await glassesManager.requestCameraPermission()
                            if granted {
                                await glassesManager.connect()
                            } else {
                                permissionDenied = true
                            }
                            isConnecting = false
                        }
                    }
                    .disabled(isConnecting)
                }
            }
        }
        .navigationTitle("Meta Glasses")
        .alert("Camera Permission Needed", isPresented: $permissionDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("LootsDisplay needs camera access on your glasses to record video.")
        }
    }
}
