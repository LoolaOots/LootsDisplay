import SwiftUI
import Charts

enum SensorType: String, CaseIterable, Identifiable {
    case pitch = "Pitch", roll = "Roll", yaw = "Yaw", heading = "Heading"
    case accelX = "Accel X", accelY = "Accel Y", accelZ = "Accel Z"
    case gForceX = "G-Force X", gForceY = "G-Force Y", gForceZ = "G-Force Z"
    case gyroX = "Gyro X", gyroY = "Gyro Y", gyroZ = "Gyro Z"
    case magX = "Mag X", magY = "Mag Y", magZ = "Mag Z"
    case speed = "Speed", pressure = "Pressure"
    
    //Sensor Data
    case witAccX = "WIT Accel X", witAccY = "WIT Accel Y", witAccZ = "WIT Accel Z"
    case witRoll = "WIT Roll", witPitch = "WIT Pitch", witYaw = "WIT Yaw"
    case witAsX = "WIT AsX", witAsY = "WIT AsY", witAsZ = "WIT AsZ"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        //Motion & Attitude (Primary Blues/Purples)
        case .pitch: return .yellow
        case .roll: return .purple
        case .yaw: return .cyan
        
        //Acceleration (Vibrant RGB)
        case .accelX: return .red
        case .accelY: return .green
        case .accelZ: return .blue
        
        //GPS & Environment (Earth Tones)
        case .speed: return .orange
        case .heading: return Color(red: 0.6, green: 0.5, blue: 0.0)
        case .pressure: return .gray
        
        //Gyroscope (Muted RGB / Neon)
        case .gyroX: return .pink
        case .gyroY: return .mint
        case .gyroZ: return .teal
        
        //Magnetometer (Deep/Dark Tones)
        case .magX: return Color(red: 0.5, green: 0, blue: 0)
        case .magY: return Color(red: 0, green: 0.4, blue: 0)
        case .magZ: return Color(red: 0, green: 0, blue: 0.5)
        
        //G-Force (Indigo/High Contrast)
        case .gForceX: return .indigo
        case .gForceY: return .brown
        case .gForceZ: return .black
            
        //Sensor Data
        case .witAccX: return Color.red.opacity(0.5)
        case .witAccY: return Color.green.opacity(0.5)
        case .witAccZ: return Color.blue.opacity(0.5)
        case .witRoll: return Color.purple.opacity(0.5)
        case .witPitch: return Color.yellow.opacity(0.5)
        case .witYaw: return Color.cyan.opacity(0.5)
        case .witAsX: return Color.pink.opacity(0.5)
        case .witAsY: return Color.mint.opacity(0.5)
        case .witAsZ: return Color.teal.opacity(0.5)
        }
    }
}

struct SensorGraphView: View {
    let session: RecordingSession
    @State private var selectedTypes: Set<SensorType> = Set(SensorType.allCases)
    
    var body: some View {
        VStack {
            List {
                //Session Info
                Section {
                    HStack(alignment: .center, spacing: 10) {
                        //Date/Time Title
                        Text(session.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let tag = sessionTag {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 8))
                                Text(tag.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.blue))
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                Section {
                    Chart {
                        ForEach(Array(session.frames.enumerated()), id: \.offset) { index, frame in
                            //Attitude
                            if selectedTypes.contains(.pitch) {
                                LineMark(x: .value("Time", index), y: .value("Pitch", frame.pitch * 180 / .pi))
                                    .foregroundStyle(by: .value("Series", "Pitch"))
                            }
                            if selectedTypes.contains(.roll) {
                                LineMark(x: .value("Time", index), y: .value("Roll", frame.roll * 180 / .pi))
                                    .foregroundStyle(by: .value("Series", "Roll"))
                            }
                            if selectedTypes.contains(.heading) {
                                LineMark(x: .value("Time", index), y: .value("Heading", frame.heading))
                                    .foregroundStyle(by: .value("Series", "Heading"))
                            }
                            if selectedTypes.contains(.yaw) {
                                LineMark(x: .value("Time", index), y: .value("Yaw", frame.yaw * 180 / .pi))
                                    .foregroundStyle(by: .value("Series", "Yaw"))
                            }
                                    
                            //Gyroscope
                            if selectedTypes.contains(.gyroX) {
                                LineMark(x: .value("Time", index), y: .value("Gyro X", frame.gyroX))
                                    .foregroundStyle(by: .value("Series", "Gyro X"))
                            }
                            if selectedTypes.contains(.gyroY) {
                                LineMark(x: .value("Time", index), y: .value("Gyro Y", frame.gyroY))
                                    .foregroundStyle(by: .value("Series", "Gyro Y"))
                            }
                            if selectedTypes.contains(.gyroZ) {
                                LineMark(x: .value("Time", index), y: .value("Gyro Z", frame.gyroZ))
                                    .foregroundStyle(by: .value("Series", "Gyro Z"))
                            }
                            
                            //Magnetometer
                            if selectedTypes.contains(.magX) {
                                LineMark(x: .value("Time", index), y: .value("Mag X", frame.magX))
                                    .foregroundStyle(by: .value("Series", "Mag X"))
                            }
                            if selectedTypes.contains(.magY) {
                                LineMark(x: .value("Time", index), y: .value("Mag Y", frame.magY))
                                    .foregroundStyle(by: .value("Series", "Mag Y"))
                            }
                            if selectedTypes.contains(.magZ) {
                                LineMark(x: .value("Time", index), y: .value("Mag Z", frame.magZ))
                                    .foregroundStyle(by: .value("Series", "Mag Z"))
                            }
                            
                            //User Acceleration
                            if selectedTypes.contains(.accelX) {
                                LineMark(x: .value("Time", index), y: .value("Accel X", frame.accelX))
                                    .foregroundStyle(by: .value("Series", "Accel X"))
                            }
                            if selectedTypes.contains(.accelY) {
                                LineMark(x: .value("Time", index), y: .value("Accel Y", frame.accelY))
                                    .foregroundStyle(by: .value("Series", "Accel Y"))
                            }
                            if selectedTypes.contains(.accelZ) {
                                LineMark(x: .value("Time", index), y: .value("Accel Z", frame.accelZ))
                                    .foregroundStyle(by: .value("Series", "Accel Z"))
                            }
                            
                            //G-Force
                            if selectedTypes.contains(.gForceX) {
                                LineMark(x: .value("Time", index), y: .value("G-Force X", frame.gForceX))
                                    .foregroundStyle(by: .value("Series", "G-Force X"))
                            }
                            if selectedTypes.contains(.gForceY) {
                                LineMark(x: .value("Time", index), y: .value("G-Force Y", frame.gForceY))
                                    .foregroundStyle(by: .value("Series", "G-Force Y"))
                            }
                            if selectedTypes.contains(.gForceZ) {
                                LineMark(x: .value("Time", index), y: .value("G-Force Z", frame.gForceZ))
                                    .foregroundStyle(by: .value("Series", "G-Force Z"))
                            }
                            
                            //Environment
                            if selectedTypes.contains(.speed) {
                                LineMark(x: .value("Time", index), y: .value("Speed", frame.speed * 2.237))
                                    .foregroundStyle(by: .value("Series", "Speed"))
                            }
                            if selectedTypes.contains(.pressure) {
                                LineMark(x: .value("Time", index), y: .value("Pressure", frame.pressure))
                                    .foregroundStyle(by: .value("Series", "Pressure"))
                            }
                            
                            //Sensor
                            if selectedTypes.contains(.witAccX), let val = frame.witAccX {
                                LineMark(x: .value("Time", index), y: .value("WIT Accel X", val))
                                    .foregroundStyle(by: .value("Series", "WIT Accel X"))
                            }
                            if selectedTypes.contains(.witAccY), let val = frame.witAccY {
                                LineMark(x: .value("Time", index), y: .value("WIT Accel Y", val))
                                    .foregroundStyle(by: .value("Series", "WIT Accel Y"))
                            }
                            if selectedTypes.contains(.witAccZ), let val = frame.witAccZ {
                                LineMark(x: .value("Time", index), y: .value("WIT Accel Z", val))
                                    .foregroundStyle(by: .value("Series", "WIT Accel Z"))
                            }
                            if selectedTypes.contains(.witRoll), let val = frame.witRoll {
                                LineMark(x: .value("Time", index), y: .value("WIT Roll", val))
                                    .foregroundStyle(by: .value("Series", "WIT Roll"))
                            }
                            if selectedTypes.contains(.witPitch), let val = frame.witPitch {
                                LineMark(x: .value("Time", index), y: .value("WIT Pitch", val))
                                    .foregroundStyle(by: .value("Series", "WIT Pitch"))
                            }
                            if selectedTypes.contains(.witYaw), let val = frame.witYaw {
                                LineMark(x: .value("Time", index), y: .value("WIT Yaw", val))
                                    .foregroundStyle(by: .value("Series", "WIT Yaw"))
                            }
                            if selectedTypes.contains(.witAsX), let val = frame.witAsX {
                                LineMark(x: .value("Time", index), y: .value("WIT AsX", val))
                                    .foregroundStyle(by: .value("Series", "WIT AsX"))
                            }
                            if selectedTypes.contains(.witAsY), let val = frame.witAsY {
                                LineMark(x: .value("Time", index), y: .value("WIT AsY", val))
                                    .foregroundStyle(by: .value("Series", "WIT AsY"))
                            }
                            if selectedTypes.contains(.witAsZ), let val = frame.witAsZ {
                                LineMark(x: .value("Time", index), y: .value("WIT AsZ", val))
                                    .foregroundStyle(by: .value("Series", "WIT AsZ"))
                            }
                        }
                    }
                    .chartForegroundStyleScale(domain: SensorType.allCases.map { $0.rawValue },
                                             range: SensorType.allCases.map { $0.color })
                    .chartLegend(.hidden)
                    .frame(height: 350)
                } header: {
                    Text("Sensor Trends")
                }
                
                Section(header: Text("Toggle Variables to View")) {
                    
                    sensorToggleGroup(title: "Motion & Attitude", types: [.pitch, .roll, .yaw, .accelX, .accelY, .accelZ])
                    
                    sensorToggleGroup(title: "GPS & Environment", types: [.speed, .heading, .pressure])
                    
                    sensorToggleGroup(title: "Gyroscope", types: [.gyroX, .gyroY, .gyroZ])
                    
                    sensorToggleGroup(title: "Magnetometer", types: [.magX, .magY, .magZ])
                    
                    sensorToggleGroup(title: "G-Force", types: [.gForceX, .gForceY, .gForceZ])
                    
                    //Sensor Data
                    let sensorConnected = session.frames.first?.witAccX != nil || session.frames.first?.witYaw != nil
                    if sensorConnected {
                        sensorToggleGroup(title: "WitMotion Sensor",
                                          types: [.witAccX, .witAccY, .witAccZ, .witRoll, .witPitch, .witYaw, .witAsX, .witAsY, .witAsZ])
                    }
                    
                }
            }
        }
        .navigationTitle("Graph")
    }
    
    func unitLabel(for type: SensorType) -> String {
        switch type {
        case .pitch, .roll, .yaw, .heading: return "°"
        case .accelX, .accelY, .accelZ: return "g"
        case .gForceX, .gForceY, .gForceZ: return "G"
        case .gyroX, .gyroY, .gyroZ: return "°/s"
        case .magX, .magY, .magZ: return "µT"
        case .speed: return "mph"
        case .pressure: return "kPa"
        case .witAccX, .witAccY, .witAccZ: return "g"
        case .witRoll, .witPitch, .witYaw: return "°"
        case .witAsX, .witAsY, .witAsZ: return "°/s"
        default: return ""
        }
    }
    
    private var sessionTag: String? {
        session.frames.first(where: { $0.label != nil && !$0.label!.isEmpty })?.label
    }
    
    @ViewBuilder
    func sensorToggleGroup(title: String, types: [SensorType]) -> some View {
        let selectedCount = types.filter { selectedTypes.contains($0) }.count
        let allSelected = selectedCount == types.count
        let isMixed = selectedCount > 0 && selectedCount < types.count
        
        Section {
            DisclosureGroup {
                ForEach(types) { type in
                    Button {
                        if selectedTypes.contains(type) {
                            selectedTypes.remove(type)
                        } else {
                            selectedTypes.insert(type)
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedTypes.contains(type) ? "circle.fill" : "circle")
                                .foregroundColor(type.color)
                                .font(.system(size: 16))
                            
                            Text(type.rawValue)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
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
                        .padding(.leading, 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(DefaultButtonStyle())
                }
            } label: {
                HStack(spacing: 12) {
                    Button {
                        if allSelected {
                            types.forEach { selectedTypes.remove($0) }
                        } else {
                            types.forEach { selectedTypes.insert($0) }
                        }
                    } label: {
                        Image(systemName: allSelected ? "checkmark.circle.fill" : (isMixed ? "minus.circle.fill" : "circle"))
                            .foregroundColor(allSelected || isMixed ? .blue : .secondary)
                            .font(.system(size: 22))
                    }
                    .buttonStyle(DefaultButtonStyle())
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
}
