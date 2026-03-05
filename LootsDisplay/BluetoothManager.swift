//import Foundation
//import CoreBluetooth
//
//class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
//    // Bluetooth State
//    private var centralManager: CBCentralManager!
//    var connectedPeripheral: CBPeripheral?
//    
//    // UUIDs from your reference code
//    private let serviceUUID = CBUUID(string: "ffe5")
//    private let dataCharUUID = CBUUID(string: "ffe4")
//    private let writeCharUUID = CBUUID(string: "ffe9")
//    
//    // Published Sensor Data
//    @Published var accX: Float = 0.0
//    @Published var accY: Float = 0.0
//    @Published var accZ: Float = 0.0
//    @Published var angleX: Float = 0.0
//    @Published var angleY: Float = 0.0
//    @Published var angleZ: Float = 0.0
//    @Published var discoveredDevices: [CBPeripheral] = []
//    
//    var isConnected: Bool {
//            connectedPeripheral != nil && connectedPeripheral?.state == .connected
//    }
//    
//    override init() {
//        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//    }
//    
//    func startScanning() {
//        guard centralManager.state == .poweredOn else { return }
//        discoveredDevices.removeAll()
//        // 1. Change serviceUUIDs to nil to see everything
//        centralManager.scanForPeripherals(withServices: nil, options: nil)
//    }
//    
//    func stopScanning() {
//        print("BluetoothManager: Stopping Scan...")
//        centralManager?.stopScan()
//        // Optional: Clear the list so it's fresh for next time
//        self.discoveredDevices.removeAll()
//        print("BluetoothManager: Scanning Stopped")
//    }
//
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
//        // 2. Filter by name here instead of the hardware filter
//        if let name = peripheral.name, name.contains("WT901") {
//            if !discoveredDevices.contains(peripheral) {
//                DispatchQueue.main.async {
//                    self.discoveredDevices.append(peripheral)
//                }
//            }
//        }
//    }
//    
//    func connect(to peripheral: CBPeripheral) {
//        connectedPeripheral = peripheral
//        connectedPeripheral?.delegate = self
//        centralManager.connect(peripheral, options: nil)
//    }
//    
//    func disconnect() {
//        if let peripheral = connectedPeripheral {
//            centralManager?.cancelPeripheralConnection(peripheral)
//            // Note: Setting connectedPeripheral = nil usually happens
//            // in the didDisconnectPeripheral delegate method
//        }
//    }
//    
//    // MARK: - CBCentralManagerDelegate
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        if central.state == .poweredOn { startScanning() }
//    }
//    
////    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
////        if !discoveredDevices.contains(peripheral) {
////            discoveredDevices.append(peripheral)
////        }
////    }
////    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        print("Connected to \(peripheral.name ?? "device")")
//        // Discover ALL services (passing nil) to see what's actually there
//        peripheral.discoverServices(nil)
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//        for service in services {
//            print("Discovered Service: \(service.uuid)")
//            // Discover ALL characteristics for each service
//            peripheral.discoverCharacteristics(nil, for: service)
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        guard let characteristics = service.characteristics else { return }
//        
//        for characteristic in characteristics {
//            // This will show you every available ID
//            print("Checking Characteristic: \(characteristic.uuid.uuidString)")
//            
//            if characteristic.uuid.uuidString.lowercased().contains("ffe4") {
//                print("MATCH FOUND! Enabling notifications...")
//                peripheral.setNotifyValue(true, for: characteristic)
//            }
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
////        guard let data = characteristic.value else { return }
////        parseWitMotionData(data)
//        if let data = characteristic.value {
//                //print("Received \(data.count) bytes of data") // If this prints, connection is good!
//                parseWitMotionData(data)
//            }
//    }
//    
//    private func parseWitMotionData(_ data: Data) {
//        let allBytes = [UInt8](data)
//        
//        // Loop through the data in chunks of 20 bytes
//        for i in stride(from: 0, to: allBytes.count, by: 20) {
//            let endIndex = i + 20
//            if endIndex <= allBytes.count {
//                let chunk = Array(allBytes[i..<endIndex])
//                processChunk(chunk)
//            }
//        }
//    }
//
//    private func processChunk(_ bytes: [UInt8]) {
//        // Standard WitMotion Protocol:
//        // Byte 0: 0x55 (Header)
//        // Byte 1: Type (0x61 for Data)
//        guard bytes.count >= 20 else { return }
//        
//        // Helper to convert 2 bytes to Int16
//        func extractInt16(at index: Int) -> Int16 {
//            let low = UInt16(bytes[index])
//            let high = UInt16(bytes[index + 1])
//            return Int16(bitPattern: (high << 8) | low)
//        }
//
//        DispatchQueue.main.async {
//            // Based on WT901BLE68 standard mapping:
//            // Acceleration: Bytes 2, 4, 6
//            self.accX = Float(extractInt16(at: 2)) / 32768.0 * 16.0
//            self.accY = Float(extractInt16(at: 4)) / 32768.0 * 16.0
//            self.accZ = Float(extractInt16(at: 6)) / 32768.0 * 16.0
//            
//            // Angle: Bytes 14, 16, 18
//            self.angleX = Float(extractInt16(at: 14)) / 32768.0 * 180.0
//            self.angleY = Float(extractInt16(at: 16)) / 32768.0 * 180.0
//            self.angleZ = Float(extractInt16(at: 18)) / 32768.0 * 180.0
//        }
//    }
//}


import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    @Published var connectedPeripheral: CBPeripheral?


    //WitMotion Sensor Data
    @Published var accX: Float = 0.0
    @Published var accY: Float = 0.0
    @Published var accZ: Float = 0.0

    @Published var asX: Float = 0.0
    @Published var asY: Float = 0.0
    @Published var asZ: Float = 0.0

    @Published var angleX: Float = 0.0
    @Published var angleY: Float = 0.0
    @Published var angleZ: Float = 0.0

    @Published var discoveredDevices: [CBPeripheral] = []

    var isConnected: Bool { connectedPeripheral?.state == .connected }

    private var receiveBuffer = Data()
    private let packetLength = 20

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScanning() {
        centralManager?.stopScan()
        discoveredDevices.removeAll()
    }

    func connect(to peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        guard let p = connectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(p)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn { startScanning() }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi: NSNumber) {
        if let name = peripheral.name, name.contains("WT901") {
            if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                DispatchQueue.main.async { self.discoveredDevices.append(peripheral) }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "device")")
        receiveBuffer.removeAll()
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        if peripheral == connectedPeripheral {
            connectedPeripheral = nil
            receiveBuffer.removeAll()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach {
            print("Discovered Service: \($0.uuid)")
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        service.characteristics?.forEach { char in
            print("Checking Characteristic: \(char.uuid.uuidString)")
            if char.uuid.uuidString.lowercased().contains("ffe4") {
                print("Notifications enabled on FFE4")
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value else { return }
        receiveBuffer.append(data)
        drainBuffer()
    }

    private func drainBuffer() {
        while true {
            guard let headerOffset = receiveBuffer.firstIndex(of: 0x55) else {
                receiveBuffer.removeAll()
                return
            }
            if headerOffset > receiveBuffer.startIndex {
                receiveBuffer.removeSubrange(receiveBuffer.startIndex ..< headerOffset)
            }
            guard receiveBuffer.count >= packetLength else { return }
            let packetBytes = Array(receiveBuffer.prefix(packetLength))
            receiveBuffer.removeFirst(packetLength)
            processPacket(packetBytes)
        }
    }

    //  0x61 Packet
    //    bytes  2- 3  AccX   Int16 LE  → ÷32768 × 16 g
    //    bytes  4- 5  AccY
    //    bytes  6- 7  AccZ
    //    bytes  8- 9  AsX    Int16 LE  → ÷32768 × 2000 °/s
    //    bytes 10-11  AsY
    //    bytes 12-13  AsZ
    //    bytes 14-15  AngleX Int16 LE  → ÷32768 × 180 °
    //    bytes 16-17  AngleY
    //    bytes 18-19  AngleZ
    private func processPacket(_ p: [UInt8]) {
        guard p.count == packetLength, p[0] == 0x55, p[1] == 0x61 else { return }

        func i16(_ lo: Int) -> Int16 {
            Int16(bitPattern: UInt16(p[lo]) | (UInt16(p[lo + 1]) << 8))
        }

        DispatchQueue.main.async {
            self.accX   = Float(i16(2))  / 32768 * 16
            self.accY   = Float(i16(4))  / 32768 * 16
            self.accZ   = Float(i16(6))  / 32768 * 16
            self.asX    = Float(i16(8))  / 32768 * 2000
            self.asY    = Float(i16(10)) / 32768 * 2000
            self.asZ    = Float(i16(12)) / 32768 * 2000
            self.angleX = Float(i16(14)) / 32768 * 180
            self.angleY = Float(i16(16)) / 32768 * 180
            self.angleZ = Float(i16(18)) / 32768 * 180
        }
    }
}
