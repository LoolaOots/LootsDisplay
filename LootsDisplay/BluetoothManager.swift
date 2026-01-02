import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // Bluetooth State
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    // UUIDs from your reference code
    private let serviceUUID = CBUUID(string: "ffe5")
    private let dataCharUUID = CBUUID(string: "ffe4")
    private let writeCharUUID = CBUUID(string: "ffe9")
    
    // Published Sensor Data
    @Published var accX: Float = 0.0
    @Published var accY: Float = 0.0
    @Published var accZ: Float = 0.0
    @Published var angleX: Float = 0.0
    @Published var angleY: Float = 0.0
    @Published var angleZ: Float = 0.0
    @Published var discoveredDevices: [CBPeripheral] = []
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        // 1. Change serviceUUIDs to nil to see everything
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        // 2. Filter by name here instead of the hardware filter
        if let name = peripheral.name, name.contains("WT901") {
            if !discoveredDevices.contains(peripheral) {
                DispatchQueue.main.async {
                    self.discoveredDevices.append(peripheral)
                }
            }
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn { startScanning() }
    }
    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
//        if !discoveredDevices.contains(peripheral) {
//            discoveredDevices.append(peripheral)
//        }
//    }
//    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "device")")
        // Discover ALL services (passing nil) to see what's actually there
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered Service: \(service.uuid)")
            // Discover ALL characteristics for each service
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            // This will show you every available ID
            print("Checking Characteristic: \(characteristic.uuid.uuidString)")
            
            if characteristic.uuid.uuidString.lowercased().contains("ffe4") {
                print("MATCH FOUND! Enabling notifications...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        guard let data = characteristic.value else { return }
//        parseWitMotionData(data)
        if let data = characteristic.value {
                //print("Received \(data.count) bytes of data") // If this prints, connection is good!
                parseWitMotionData(data)
            }
    }
    
    private func parseWitMotionData(_ data: Data) {
        let allBytes = [UInt8](data)
        
        // Loop through the data in chunks of 20 bytes
        for i in stride(from: 0, to: allBytes.count, by: 20) {
            let endIndex = i + 20
            if endIndex <= allBytes.count {
                let chunk = Array(allBytes[i..<endIndex])
                processChunk(chunk)
            }
        }
    }

    private func processChunk(_ bytes: [UInt8]) {
        // Standard WitMotion Protocol:
        // Byte 0: 0x55 (Header)
        // Byte 1: Type (0x61 for Data)
        guard bytes.count >= 20 else { return }
        
        // Helper to convert 2 bytes to Int16
        func extractInt16(at index: Int) -> Int16 {
            let low = UInt16(bytes[index])
            let high = UInt16(bytes[index + 1])
            return Int16(bitPattern: (high << 8) | low)
        }

        DispatchQueue.main.async {
            // Based on WT901BLE68 standard mapping:
            // Acceleration: Bytes 2, 4, 6
            self.accX = Float(extractInt16(at: 2)) / 32768.0 * 16.0
            self.accY = Float(extractInt16(at: 4)) / 32768.0 * 16.0
            self.accZ = Float(extractInt16(at: 6)) / 32768.0 * 16.0
            
            // Angle: Bytes 14, 16, 18
            self.angleX = Float(extractInt16(at: 14)) / 32768.0 * 180.0
            self.angleY = Float(extractInt16(at: 16)) / 32768.0 * 180.0
            self.angleZ = Float(extractInt16(at: 18)) / 32768.0 * 180.0
        }
    }
}
//import Foundation
//import CoreBluetooth
//
//struct PeripheralDevice: Identifiable {
//    let id: UUID
//    let name: String
//    let rssi: Int
//}
//
//class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
//    @Published var discoveredDevices: [PeripheralDevice] = []
//    @Published var isScanning = false
//    
//    private var centralManager: CBCentralManager!
//    
//    override init() {
//        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//    }
//    
//    func startScanning() {
//        guard centralManager.state == .poweredOn else { return }
//        isScanning = true
//        discoveredDevices.removeAll()
//        centralManager.scanForPeripherals(withServices: nil, options: nil)
//    }
//    
//    func stopScanning() {
//        isScanning = false
//        centralManager.stopScan()
//    }
//    
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        if central.state == .poweredOn {
//            // Ready to scan
//        } else {
//            isScanning = false
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
//        let name = peripheral.name ?? "Unknown Device"
//        if !discoveredDevices.contains(where: { $0.id == peripheral.identifier }) {
//            let device = PeripheralDevice(id: peripheral.identifier, name: name, rssi: rssi.intValue)
//            discoveredDevices.append(device)
//        }
//    }
//}
