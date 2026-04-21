import SwiftUI

struct PhoneDataView: View {
    @ObservedObject var sensors: SensorManager

    var body: some View {
        Section(header: Label("group.motion_attitude", systemImage: "iphone")) {
            SensorRow(label: "sensor.pitch", value: String(format: "%.2f°", sensors.attitude.pitch * 180 / .pi))
            SensorRow(label: "sensor.roll", value: String(format: "%.2f°", sensors.attitude.roll * 180 / .pi))
            SensorRow(label: "sensor.yaw", value: String(format: "%.2f°", sensors.attitude.yaw * 180 / .pi))
            SensorRow(label: "sensor.accel_x", value: String(format: "%.3f g", sensors.acceleration.x))
            SensorRow(label: "sensor.accel_y", value: String(format: "%.3f g", sensors.acceleration.y))
            SensorRow(label: "sensor.accel_z", value: String(format: "%.3f g", sensors.acceleration.z))
        }

        Section(header: Label("group.gps_environment", systemImage: "iphone")) {
            SensorRow(label: "sensor.speed", value: String(format: "%.1f mph", sensors.speed * 2.237))
            SensorRow(label: "sensor.heading", value: String(format: "%.1f°", sensors.heading))
            SensorRow(label: "sensor.pressure", value: String(format: "%.2f kPa", sensors.pressure))
            SensorRow(label: "sensor.latitude", value: String(format: "%.6f", sensors.locationData?.coordinate.latitude ?? 0.0))
            SensorRow(label: "sensor.longitude", value: String(format: "%.6f", sensors.locationData?.coordinate.longitude ?? 0.0))
        }

        Section(header: Label("group.gyroscope", systemImage: "iphone")) {
            SensorRow(label: "sensor.rotation_x", value: String(format: "%.1f °/s", sensors.gyroX))
            SensorRow(label: "sensor.rotation_y", value: String(format: "%.1f °/s", sensors.gyroY))
            SensorRow(label: "sensor.rotation_z", value: String(format: "%.1f °/s", sensors.gyroZ))
        }

        Section(header: Label("group.magnetometer", systemImage: "iphone")) {
            SensorRow(label: "sensor.mag_x", value: String(format: "%.1f µT", sensors.magX))
            SensorRow(label: "sensor.mag_y", value: String(format: "%.1f µT", sensors.magY))
            SensorRow(label: "sensor.mag_z", value: String(format: "%.1f µT", sensors.magZ))
        }

        Section(header: Label("group.gforce", systemImage: "iphone")) {
            SensorRow(label: "sensor.gforce_x", value: String(format: "%.2f g", sensors.gForceX))
            SensorRow(label: "sensor.gforce_y", value: String(format: "%.2f g", sensors.gForceY))
            SensorRow(label: "sensor.gforce_z", value: String(format: "%.2f g", sensors.gForceZ))
        }
    }
}
