//
//  WT901LiveStreamView.swift
//  LootsDisplay
//
//  Created by Nat on 1/2/26.
//
import SwiftUI
import CoreBluetooth


struct WT901LiveStreamView: View {
    @ObservedObject var manager: BluetoothManager
    var peripheral: CBPeripheral
    
    var body: some View {
        List {
            Section("Acceleration (G)") {
                LabeledContent("X Axis", value: String(format: "%.3f", manager.accX))
                LabeledContent("Y Axis", value: String(format: "%.3f", manager.accY))
                LabeledContent("Z Axis", value: String(format: "%.3f", manager.accZ))
            }
            
            Section("Orientation (Degrees)") {
                LabeledContent("Roll", value: String(format: "%.2f°", manager.angleX))
                LabeledContent("Pitch", value: String(format: "%.2f°", manager.angleY))
                LabeledContent("Yaw", value: String(format: "%.2f°", manager.angleZ))
            }
        }
        .navigationTitle("Live Stream")
        .onAppear { manager.connect(to: peripheral) }
    }
}
