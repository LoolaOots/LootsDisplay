//
//  WT901DataView.swift
//  LootsDisplay
//
//  Created by Nat on 1/2/26.
//


import SwiftUI
import CoreBluetooth

struct WT901DataView: View {
    @ObservedObject var manager: BluetoothManager
    var peripheral: CBPeripheral
    
    var body: some View {
        List {
            Section("Live Sensor Stream") {
                SensorRow(label: "Acceleration X", value: String(format: "%.2f g", manager.accX))
                SensorRow(label: "Acceleration Y", value: String(format: "%.2f g", manager.accY))
                SensorRow(label: "Acceleration Z", value: String(format: "%.2f g", manager.accZ))
            }

            Section("Attitude (Euler)") {
                SensorRow(label: "Roll", value: String(format: "%.1f°", manager.angleX))
                SensorRow(label: "Pitch", value: String(format: "%.1f°", manager.angleY))
                SensorRow(label: "Yaw", value: String(format: "%.1f°", manager.angleZ))
            }
        }
        .navigationTitle(peripheral.name ?? "Streaming")
        .onAppear {
            manager.connect(to: peripheral)
        }
    }
}
