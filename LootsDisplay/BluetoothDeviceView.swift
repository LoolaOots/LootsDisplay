import SwiftUI

struct BluetoothDeviceView: View {
    @ObservedObject var btManager: BluetoothManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            if btManager.discoveredDevices.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("bt.scanning")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(btManager.discoveredDevices, id: \.identifier) { device in
                    Button {
                        btManager.connect(to: device)
                        btManager.stopScanning()
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(device.name ?? String(localized: "bt.unknown_device"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(device.identifier.uuidString)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let name = device.name, name.hasPrefix("WT") {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("nav.find_sensor")
        .onAppear {
            btManager.requestBluetoothAccess()
            btManager.startScanning()
        }
        .onDisappear {
            btManager.stopScanning()
        }
    }
}
