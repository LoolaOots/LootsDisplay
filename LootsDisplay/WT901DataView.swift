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
        Section("Acceleration") {
            SensorRow(label: "X", value: String(format: "%.3f g", manager.accX))
            SensorRow(label: "Y", value: String(format: "%.3f g", manager.accY))
            SensorRow(label: "Z", value: String(format: "%.3f g", manager.accZ))
        }

        Section("Gyroscope") {
            SensorRow(label: "X", value: String(format: "%.2f °/s", manager.asX))
            SensorRow(label: "Y", value: String(format: "%.2f °/s", manager.asY))
            SensorRow(label: "Z", value: String(format: "%.2f °/s", manager.asZ))
        }

        Section("Attitude") {
            SensorRow(label: "Roll",  value: String(format: "%.2f°", manager.angleX))
            SensorRow(label: "Pitch", value: String(format: "%.2f°", manager.angleY))
            SensorRow(label: "Yaw",   value: String(format: "%.2f°", manager.angleZ))
        }
        
        .navigationTitle(peripheral.name ?? "Streaming Sensor Data")
        .onAppear {
            manager.connect(to: peripheral)
        }
    }
}
