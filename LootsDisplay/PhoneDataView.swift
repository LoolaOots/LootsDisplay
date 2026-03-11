import SwiftUI

struct PhoneDataView: View {
    @ObservedObject var sensors: SensorManager

    var body: some View {
        Section(header: Label("Motion & Attitude", systemImage: "iphone")) {
            SensorRow(label: "Pitch", value: String(format: "%.2f°", sensors.attitude.pitch * 180 / .pi))
            SensorRow(label: "Roll", value: String(format: "%.2f°", sensors.attitude.roll * 180 / .pi))
            SensorRow(label: "Yaw", value: String(format: "%.2f°", sensors.attitude.yaw * 180 / .pi))
            SensorRow(label: "Accel X", value: String(format: "%.3f g", sensors.acceleration.x))
            SensorRow(label: "Accel Y", value: String(format: "%.3f g", sensors.acceleration.y))
            SensorRow(label: "Accel Z", value: String(format: "%.3f g", sensors.acceleration.z))
        }

        Section(header: Label("GPS & Environment", systemImage: "iphone")) {
            SensorRow(label: "Speed", value: String(format: "%.1f mph", sensors.speed * 2.237))
            SensorRow(label: "Heading", value: String(format: "%.1f°", sensors.heading))
            SensorRow(label: "Pressure", value: String(format: "%.2f kPa", sensors.pressure))
            SensorRow(label: "Latitude", value: String(format: "%.6f", sensors.locationData?.coordinate.latitude ?? 0.0))
            SensorRow(label: "Longitude", value: String(format: "%.6f", sensors.locationData?.coordinate.longitude ?? 0.0))
        }

        Section(header: Label("Gyroscope", systemImage: "iphone")) {
            SensorRow(label: "Rotation X", value: String(format: "%.1f °/s", sensors.gyroX))
            SensorRow(label: "Rotation Y", value: String(format: "%.1f °/s", sensors.gyroY))
            SensorRow(label: "Rotation Z", value: String(format: "%.1f °/s", sensors.gyroZ))
        }

        Section(header: Label("Magnetometer", systemImage: "iphone")) {
            SensorRow(label: "Mag X", value: String(format: "%.1f µT", sensors.magX))
            SensorRow(label: "Mag Y", value: String(format: "%.1f µT", sensors.magY))
            SensorRow(label: "Mag Z", value: String(format: "%.1f µT", sensors.magZ))
        }

        Section(header: Label("G-Force", systemImage: "iphone")) {
            SensorRow(label: "G-Force X", value: String(format: "%.2f g", sensors.gForceX))
            SensorRow(label: "G-Force Y", value: String(format: "%.2f g", sensors.gForceY))
            SensorRow(label: "G-Force Z", value: String(format: "%.2f g", sensors.gForceZ))
        }
    }
}
