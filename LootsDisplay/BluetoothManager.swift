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
    private var seenPeripheralIDs = Set<UUID>() //prevent duplicates

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        seenPeripheralIDs.removeAll()
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

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi: NSNumber) {
        if let name = peripheral.name, name.contains("WT901") {
            DispatchQueue.main.async {
                if !self.discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                    self.discoveredDevices.append(peripheral)
                }
            }
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
