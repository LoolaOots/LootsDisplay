import SwiftUI

struct AirPodsDataView: View {
    @ObservedObject var manager: AirPodsMotionManager

    var body: some View {
        Section(header: Label {
            Text("section.attitude")
        } icon: {
            Image(systemName: "airpodspro").foregroundColor(.accentColor)
        }) {
            SensorRow(label: "sensor.roll", value: String(format: "%.2f°", manager.roll * 180 / .pi))
            SensorRow(label: "sensor.pitch", value: String(format: "%.2f°", manager.pitch * 180 / .pi))
            SensorRow(label: "sensor.yaw", value: String(format: "%.2f°", manager.yaw * 180 / .pi))
        }

        Section(header: Label {
            Text("group.motion_attitude")
        } icon: {
            Image(systemName: "airpodspro").foregroundColor(.accentColor)
        }) {
            SensorRow(label: "sensor.accel_x", value: String(format: "%.3f g", manager.accelX))
            SensorRow(label: "sensor.accel_y", value: String(format: "%.3f g", manager.accelY))
            SensorRow(label: "sensor.accel_z", value: String(format: "%.3f g", manager.accelZ))
        }

        Section(header: Label {
            Text("group.gforce")
        } icon: {
            Image(systemName: "airpodspro").foregroundColor(.accentColor)
        }) {
            SensorRow(label: "sensor.gforce_x", value: String(format: "%.2f g", manager.gravityX))
            SensorRow(label: "sensor.gforce_y", value: String(format: "%.2f g", manager.gravityY))
            SensorRow(label: "sensor.gforce_z", value: String(format: "%.2f g", manager.gravityZ))
        }

        Section(header: Label {
            Text("group.gyroscope")
        } icon: {
            Image(systemName: "airpodspro").foregroundColor(.accentColor)
        }) {
            SensorRow(label: "sensor.x", value: String(format: "%.1f °/s", manager.gyroX))
            SensorRow(label: "sensor.y", value: String(format: "%.1f °/s", manager.gyroY))
            SensorRow(label: "sensor.z", value: String(format: "%.1f °/s", manager.gyroZ))
        }
    }
}
