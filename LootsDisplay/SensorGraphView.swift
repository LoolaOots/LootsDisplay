import SwiftUI
import Charts

// Data types
enum SensorType: String, CaseIterable, Identifiable {
    case pitch = "Pitch", roll = "Roll", accel = "Acceleration", heading = "Heading", pressure = "Pressure"
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .pitch: return .blue
        case .roll: return .green
        case .accel: return .red
        case .heading: return .orange
        case .pressure: return .purple
        }
    }
}

struct SensorGraphView: View {
    let session: RecordingSession
    
    // State to track selected variables (all selected by default)
    @State private var selectedTypes: Set<SensorType> = Set(SensorType.allCases)
    
    var body: some View {
        VStack {
            List {
                Section {
                    // The Graph
                    Chart {
                        ForEach(Array(session.frames.enumerated()), id: \.offset) { index, frame in
                            if selectedTypes.contains(.pitch) {
                                LineMark(
                                    x: .value("Time", index),
                                    y: .value("Pitch", frame.pitch * 180 / .pi)
                                )
                                .foregroundStyle(by: .value("Series", "Pitch"))
                            }
                            
                            if selectedTypes.contains(.roll) {
                                LineMark(
                                    x: .value("Time", index),
                                    y: .value("Roll", frame.roll * 180 / .pi)
                                )
                                .foregroundStyle(by: .value("Series", "Roll"))
                            }
                            
                            if selectedTypes.contains(.accel) {
                                LineMark(
                                    x: .value("Time", index),
                                    y: .value("Accel", frame.accelX)
                                )
                                .foregroundStyle(by: .value("Series", "Acceleration"))
                            }
                            
                            if selectedTypes.contains(.heading) {
                                LineMark(
                                    x: .value("Time", index),
                                    y: .value("Heading", frame.heading)
                                )
                                .foregroundStyle(by: .value("Series", "Heading"))
                            }
                            
                            if selectedTypes.contains(.pressure) {
                                LineMark(
                                    x: .value("Time", index),
                                    y: .value("Pressure", frame.pressure)
                                )
                                .foregroundStyle(by: .value("Series", "Pressure"))
                            }
                        }
                    }
                    .chartForegroundStyleScale([
                        "Pitch": SensorType.pitch.color,
                        "Roll": SensorType.roll.color,
                        "Acceleration": SensorType.accel.color,
                        "Heading": SensorType.heading.color,
                        "Pressure": SensorType.pressure.color
                    ])
                    .chartLegend(.hidden)
                    .frame(height: 350)
                } header: {
                    Text("Sensor Trends")
                }
                
                //Interactive Legend
                Section(header: Text("Toggle Variables to View")) {
                    ForEach(SensorType.allCases) { type in
                        Button {
                            if selectedTypes.contains(type) {
                                selectedTypes.remove(type)
                            } else {
                                selectedTypes.insert(type)
                            }
                        } label: {
                            HStack {
                                // Indicator Circle
                                Image(systemName: selectedTypes.contains(type) ? "circle.fill" : "circle")
                                    .foregroundColor(type.color)
                                    .font(.system(size: 20))
                                
                                Text(type.rawValue)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Show units and checkmark only if active
                                if selectedTypes.contains(type) {
                                    Text(unitLabel(for: type))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle()) // Makes the empty Spacer areas clickable
                        }
                        .buttonStyle(.plain) // Prevents the whole row from turning blue/gray when tapped
                    }
                }
            }
        }
        .navigationTitle("Graph")
    }
    
    // Helper to show units in the legend
    func unitLabel(for type: SensorType) -> String {
        switch type {
        case .pitch, .roll, .heading: return "Degrees (°)"
        case .accel: return "g-force"
        case .pressure: return "kPa"
        }
    }
}
