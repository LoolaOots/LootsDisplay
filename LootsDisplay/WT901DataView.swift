import SwiftUI
import CoreBluetooth

struct WT901DataView: View {
    @ObservedObject var manager: BluetoothManager
    var peripheral: CBPeripheral

    var body: some View {
        Section(header: Label("section.acceleration", systemImage: "sensor")) {
            SensorRow(label: "sensor.x", value: String(format: "%.3f g", manager.accX))
            SensorRow(label: "sensor.y", value: String(format: "%.3f g", manager.accY))
            SensorRow(label: "sensor.z", value: String(format: "%.3f g", manager.accZ))
        }

        Section(header: Label("group.gyroscope", systemImage: "sensor")) {
            SensorRow(label: "sensor.x", value: String(format: "%.2f °/s", manager.asX))
            SensorRow(label: "sensor.y", value: String(format: "%.2f °/s", manager.asY))
            SensorRow(label: "sensor.z", value: String(format: "%.2f °/s", manager.asZ))
        }

        Section(header: Label("section.attitude", systemImage: "sensor")) {
            SensorRow(label: "sensor.roll",  value: String(format: "%.2f°", manager.angleX))
            SensorRow(label: "sensor.pitch", value: String(format: "%.2f°", manager.angleY))
            SensorRow(label: "sensor.yaw",   value: String(format: "%.2f°", manager.angleZ))
        }

        .navigationTitle(peripheral.name ?? String(localized: "sensor.streaming_data"))
        .onAppear {
            manager.connect(to: peripheral)
        }
    }
}
