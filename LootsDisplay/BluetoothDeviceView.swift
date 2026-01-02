//
//  BluetoothDeviceView.swift
//  LootsDisplay
//
//  Created by Nat on 1/2/26.
//
import SwiftUI
//
//struct BluetoothDeviceView: View {
//    @StateObject var bluetoothManager = BluetoothManager()
//    
//    var body: some View {
//        List(bluetoothManager.discoveredDevices) { device in
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(device.name)
//                        .font(.headline)
//                    Text(device.id.uuidString)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                Spacer()
//                Text("\(device.rssi) dBm")
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .navigationTitle("Devices")
//        .toolbar {
//            Button(bluetoothManager.isScanning ? "Stop" : "Scan") {
//                if bluetoothManager.isScanning {
//                    bluetoothManager.stopScanning()
//                } else {
//                    bluetoothManager.startScanning()
//                }
//            }
//        }
//        .onAppear {
//            bluetoothManager.startScanning()
//        }
//        .onDisappear {
//            bluetoothManager.stopScanning()
//        }
//    }
//}


struct BluetoothDeviceView: View {
    @StateObject var btManager = BluetoothManager()
    
    var body: some View {
        List {
            if btManager.discoveredDevices.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Scanning for WT901 Sensors...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(btManager.discoveredDevices, id: \.identifier) { device in
                    NavigationLink(destination: WT901LiveStreamView(manager: btManager, peripheral: device)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(device.name ?? "Unknown Device")
                                    .font(.headline)
                                Text(device.identifier.uuidString)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            // The 'name' is the reliable way to check for WitMotion
                            if let name = device.name, name.hasPrefix("WT") {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Find Sensor")
        // Start scanning when the view appears
        .onAppear {
            btManager.startScanning()
        }
        .onDisappear {
            // Optional: Stop scanning when leaving the list to save battery
            //btManager.centralManager.stopScan()
        }
    }
}
