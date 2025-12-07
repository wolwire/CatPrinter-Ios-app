import CoreBluetooth
import Foundation

/// PrinterManager: encodes commands (ported from Python cmds.py) and handles BLE communication
final class PrinterManager: NSObject, ObservableObject {
  // MARK: - UUIDs
  private let possibleServiceUUIDs = [CBUUID(string: "AE30"), CBUUID(string: "AF30")]
  private let txCharacteristicUUID = CBUUID(string: "AE01")
  private let rxCharacteristicUUID = CBUUID(string: "AE02")

  private var central: CBCentralManager!
  private var targetPeripheral: CBPeripheral?
  private var txCharacteristic: CBCharacteristic?
  private var rxCharacteristic: CBCharacteristic?

  private var connectContinuation: CheckedContinuation<Void, Error>?
  private var sendContinuation: CheckedContinuation<Void, Error>?

  // Published state for UI
  @Published var discoveredPrinters: [DiscoveredPrinter] = []
  @Published var isConnected: Bool = false
  @Published var connectedPrinterName: String? = nil

  // ADDED: expose connected peripheral id and scanning state for UI
  @Published var connectedPeripheralID: UUID? = nil
  @Published var isScanning: Bool = false
  @Published var connectedPrinter: DiscoveredPrinter? = nil

  struct DiscoveredPrinter: Identifiable {
    let id: UUID
    let name: String
    let advSummary: String?
    let peripheral: CBPeripheral
  }

  // Whether a UI-initiated scan is active / requested. Used to start scanning once Bluetooth is powered on.
  private var scanningRequested: Bool = false

  override init() {
    super.init()
    central = CBCentralManager(delegate: self, queue: nil)
  }

  enum PrinterError: Error {
    case bluetoothUnavailable
    case notFound
    case notConnected
    case missingCharacteristic
    case timeout
  }

  // MARK: - Command encoding (partial port of cmds.py)
  private func bs(_ lst: [Int]) -> [UInt8] {
    return lst.map { UInt8(Int32(bitPattern: UInt32($0 & 0xff))) }
  }

  private let PRINT_WIDTH = 384

  private let CHECKSUM_TABLE: [Int] = {
    return [
      0, 7, 14, 9, 28, 27, 18, 21, 56, 63, 54, 49, 36, 35, 42, 45, 112, 119, 126, 121,
      108, 107, 98, 101, 72, 79, 70, 65, 84, 83, 90, 93, -32, -25, -18, -23, -4, -5,
      -14, -11, -40, -33, -42, -47, -60, -61, -54, -51, -112, -105, -98, -103, -116,
      -117, -126, -123, -88, -81, -90, -95, -76, -77, -70, -67, -57, -64, -55, -50,
      -37, -36, -43, -46, -1, -8, -15, -10, -29, -28, -19, -22, -73, -80, -71, -66,
      -85, -84, -91, -94, -113, -120, -127, -122, -109, -108, -99, -102, 39, 32, 41,
      46, 59, 60, 53, 50, 31, 24, 17, 22, 3, 4, 13, 10, 87, 80, 89, 94, 75, 76, 69, 66,
      111, 104, 97, 102, 115, 116, 125, 122, -119, -114, -121, -128, -107, -110, -101,
      -100, -79, -74, -65, -72, -83, -86, -93, -92, -7, -2, -9, -16, -27, -30, -21, -20,
      -63, -58, -49, -56, -35, -38, -45, -44, 105, 110, 103, 96, 117, 114, 123, 124, 81,
      86, 95, 88, 77, 74, 67, 68, 25, 30, 23, 16, 5, 2, 11, 12, 33, 38, 47, 40, 61, 58,
      51, 52, 78, 73, 64, 71, 82, 85, 92, 91, 118, 113, 120, 127, 106, 109, 100, 99, 62,
      57, 48, 55, 34, 37, 44, 43, 6, 1, 8, 15, 26, 29, 20, 19, -82, -87, -96, -89, -78,
      -75, -68, -69, -106, -111, -104, -97, -118, -115, -124, -125, -34, -39, -48, -41,
      -62, -59, -52, -53, -26, -31, -24, -17, -6, -3, -12, -13,
    ]
  }()

  private func chkSum(_ arr: [UInt8], _ i: Int, _ i2: Int) -> UInt8 {
    var b2 = 0
    for i3 in i..<(i + i2) {
      let v = Int(Int8(bitPattern: arr[i3]))
      b2 = CHECKSUM_TABLE[(b2 ^ v) & 0xff]
    }
    return UInt8((b2 & 0xff))
  }

  private func cmdFeedPaper(_ howMuch: Int) -> [UInt8] {
    var arr = bs([81, 120, -67, 0, 1, 0, howMuch & 0xff, 0, 0xff])
    arr[7] = chkSum(arr, 6, 1)
    return arr
  }

  private func cmdSetEnergy(_ val: Int) -> [UInt8] {
    var arr = bs([81, 120, -81, 0, 2, 0, (val >> 8) & 0xff, val & 0xff, 0, 0xff])
    arr[8] = chkSum(arr, 6, 2)
    return arr
  }

  private func cmdApplyEnergy() -> [UInt8] {
    var arr = bs([81, 120, -66, 0, 1, 0, 1, 0, 0xff])
    arr[7] = chkSum(arr, 6, 1)
    return arr
  }

  private func encodeRunLengthRepetition(_ n0: Int, _ val: Int) -> [UInt8] {
    var n = n0
    var res: [UInt8] = []
    while n > 0x7f {
      res.append(UInt8(0x7f | (val << 7)))
      n -= 0x7f
    }
    if n > 0 {
      res.append(UInt8((val << 7) | n))
    }
    return res
  }

  private func runLengthEncode(_ imgRow: [Bool]) -> [UInt8] {
    var res: [UInt8] = []
    var count = 0
    var lastVal = -1
    for val in imgRow {
      let v = val ? 1 : 0
      if v == lastVal {
        count += 1
      } else {
        res += encodeRunLengthRepetition(count, lastVal)
        count = 1
      }
      lastVal = v
    }
    if count > 0 {
      res += encodeRunLengthRepetition(count, lastVal)
    }
    return res
  }

  private func byteEncode(_ imgRow: [Bool]) -> [UInt8] {
    var res: [UInt8] = []
    let len = imgRow.count
    var i = 0
    while i < len {
      var b: UInt8 = 0
      for bitIndex in 0..<8 {
        if i + bitIndex < len {
          if imgRow[i + bitIndex] { b |= UInt8(1 << bitIndex) }
        }
      }
      res.append(b)
      i += 8
    }
    return res
  }

  private func cmdPrintRow(_ imgRow: [Bool]) -> [UInt8] {
    var encodedImg = runLengthEncode(imgRow)
    if encodedImg.count > PRINT_WIDTH / 8 {
      encodedImg = byteEncode(imgRow)
      var bArr: [UInt8] = [81, 120, UInt8(bitPattern: Int8(-94)), 0, UInt8(encodedImg.count), 0]
      bArr += encodedImg
      bArr += [0, 0xff]
      bArr[bArr.count - 2] = chkSum(bArr, 6, encodedImg.count)
      return bArr
    }
    var bArr: [UInt8] = [81, 120, UInt8(bitPattern: Int8(-65)), 0, UInt8(encodedImg.count), 0]
    bArr += encodedImg
    bArr += [0, 0xff]
    bArr[bArr.count - 2] = chkSum(bArr, 6, encodedImg.count)
    return bArr
  }

  func cmdsPrintImage(img: [[Bool]], energy: Int = 0xffff) throws -> Data {
    // Build header constants
    let CMD_GET_DEV_STATE = bs([81, 120, -93, 0, 1, 0, 0, 0, -1])
    let CMD_SET_QUALITY_200_DPI = bs([81, 120, -92, 0, 1, 0, 50, -98, -1])
    let CMD_LATTICE_START = bs([
      81, 120, -90, 0, 11, 0, -86, 85, 23, 56, 68, 95, 95, 95, 68, 56, 44, -95, -1,
    ])
    let CMD_LATTICE_END = bs([81, 120, -90, 0, 11, 0, -86, 85, 23, 0, 0, 0, 0, 0, 0, 0, 23, 17, -1])
    let CMD_SET_PAPER = bs([81, 120, -95, 0, 2, 0, 48, 0, -7, -1])

    var data: [UInt8] = []
    data += CMD_GET_DEV_STATE
    data += CMD_SET_QUALITY_200_DPI
    data += cmdSetEnergy(energy)
    data += cmdApplyEnergy()
    data += CMD_LATTICE_START
    for row in img {
      data += cmdPrintRow(row)
    }
    data += cmdFeedPaper(10)
    data += CMD_SET_PAPER
    data += CMD_LATTICE_END
    data += CMD_GET_DEV_STATE

    return Data(data)
  }

  // MARK: - BLE sending
  func send(data: Data) async throws {
    guard central.state == .poweredOn else { throw PrinterError.bluetoothUnavailable }
    guard let tx = txCharacteristic, let peripheral = targetPeripheral else {
      throw PrinterError.missingCharacteristic
    }

    // Write in chunks (simple implementation). iOS will handle MTU; practical safe chunk is ~180 bytes.
    let chunkSize = 180
    var offset = 0
    while offset < data.count {
      let end = min(data.count, offset + chunkSize)
      let chunk = data.subdata(in: offset..<end)
      peripheral.writeValue(chunk, for: tx, type: .withoutResponse)
      // small delay
      try await Task.sleep(nanoseconds: 20_000_000)  // 20ms
      offset = end
    }

    // Wait for printer-ready notification (sendContinuation will be resumed in didUpdateValueFor)
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      self.sendContinuation = continuation
      // Timeout after 30s
      Task {
        try await Task.sleep(nanoseconds: 30 * 1_000_000_000)
        if let cont = self.sendContinuation {
          cont.resume(throwing: PrinterError.timeout)
          self.sendContinuation = nil
        }
      }
    }
  }

  // MARK: - Scan / Connect helpers for UI
  func startScan() {
    // Clear existing list
    discoveredPrinters = []
    scanningRequested = true

    // Mark scanning state
    DispatchQueue.main.async {
      self.isScanning = true
    }

    // Only start scan if Bluetooth is ON
    if central.state == .poweredOn {
      central.scanForPeripherals(
        withServices: nil,
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
      )

      // ❗ Stop after 20 seconds
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
        self?.stopScan()
      }
    }
  }

  func stopScan() {
    scanningRequested = false
    central.stopScan()
    DispatchQueue.main.async {
      self.isScanning = false
    }
  }

    func connectToPeripheral(p: DiscoveredPrinter) async throws {
    guard central.state == .poweredOn else { throw PrinterError.bluetoothUnavailable }
    // Stop scanning while connecting
    scanningRequested = false
    central.stopScan()
    DispatchQueue.main.async {
      self.isScanning = false
    }

    var peripheral = p.peripheral
    targetPeripheral = peripheral
    peripheral.delegate = self

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      self.connectContinuation = continuation
      central.connect(peripheral, options: nil)
    }

    // Mark connected
    DispatchQueue.main.async {
      self.isConnected = true
      self.connectedPrinterName = peripheral.name ?? peripheral.identifier.uuidString
      self.connectedPeripheralID = peripheral.identifier  // <--- ADDED
      self.isScanning = false
      self.connectedPrinter = p
    }
  }

  // Provide a clean disconnect API for UI
  func disconnect() {
    if let p = targetPeripheral {
      central.cancelPeripheralConnection(p)
    } else if let id = connectedPeripheralID {
      // if targetPeripheral is nil but we have an id, try to find it in discovered list and disconnect
      if let found = discoveredPrinters.first(where: { $0.id == id }) {
        central.cancelPeripheralConnection(found.peripheral)
      }
    }

    // Clear local state immediately; centralManager(_:didDisconnectPeripheral:error:) will confirm
    DispatchQueue.main.async {
      self.isConnected = false
      self.connectedPrinterName = nil
      self.connectedPeripheralID = nil
      self.connectedPrinter = nil
    }
  }
}

// MARK: - CBCentralManagerDelegate & CBPeripheralDelegate
extension PrinterManager: CBCentralManagerDelegate, CBPeripheralDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
      print("🔵 Bluetooth powered on")
      if scanningRequested {
        // Start scanning for any peripherals; some printers don't advertise the service UUIDs
        central.scanForPeripherals(
          withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
      }
    case .poweredOff:
      print("⚪️ Bluetooth powered off")
      // Clear discovered and connected state when Bluetooth turns off
      DispatchQueue.main.async {
        self.discoveredPrinters = []
        self.isConnected = false
        self.connectedPeripheralID = nil
        self.connectedPrinterName = nil
        self.isScanning = false
      }
    default:
      print("Bluetooth state changed: \(central.state.rawValue)")
    }
  }

  func centralManager(
    _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any], rssi RSSI: NSNumber
  ) {
    // Extract names
    let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
    let name = peripheral.name ?? advName ?? peripheral.identifier.uuidString

    // Only accept PD01 devices (case-insensitive)
    if !name.lowercased().hasPrefix("pd01") {
      return
    }

    // Create minimal summary (optional, used in UI)
    var advSummary: String? = nil
    if let advName = advName {
      advSummary = "name:\(advName)"
    }

    // Add to discovered printers if not already added
    DispatchQueue.main.async {
      if !self.discoveredPrinters.contains(where: { $0.id == peripheral.identifier }) {
        self.discoveredPrinters.append(
          DiscoveredPrinter(
            id: peripheral.identifier,
            name: name,
            advSummary: advSummary,
            peripheral: peripheral
          )
        )
      }
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    // Save the peripheral reference (already set in connectToPeripheral), and discover services.
    targetPeripheral = peripheral
    peripheral.discoverServices(possibleServiceUUIDs)
  }

  func centralManager(
    _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?
  ) {
    print(
      "Disconnected from peripheral \(peripheral.identifier) error=\(String(describing: error))")
    DispatchQueue.main.async {
      // Clear connected state
      if self.connectedPeripheralID == peripheral.identifier {
        self.isConnected = false
        self.connectedPeripheralID = nil
        self.connectedPrinterName = nil
      }
      // keep discovered list intact (optional)
    }
    // Clear saved peripheral reference if it matches
    if targetPeripheral?.identifier == peripheral.identifier {
      targetPeripheral = nil
      txCharacteristic = nil
      rxCharacteristic = nil
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard error == nil else {
      connectContinuation?.resume(throwing: error!)
      return
    }
    guard let services = peripheral.services else {
      connectContinuation?.resume(throwing: PrinterError.notFound)
      return
    }
    for s in services {
      peripheral.discoverCharacteristics([txCharacteristicUUID, rxCharacteristicUUID], for: s)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
  ) {
    guard error == nil else {
      connectContinuation?.resume(throwing: error!)
      return
    }
    guard let chars = service.characteristics else { return }
    for c in chars {
      if c.uuid == txCharacteristicUUID { txCharacteristic = c }
      if c.uuid == rxCharacteristicUUID {
        rxCharacteristic = c
        peripheral.setNotifyValue(true, for: c)
      }
    }
    // If we have both, resume connect continuation
    if txCharacteristic != nil && rxCharacteristic != nil {
      connectContinuation?.resume(returning: ())
      connectContinuation = nil
      // proceed to send if needed (not implemented fully here)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?
  ) {
    // Check for printer ready notification; the exact bytes expected are: 0x51 0x78 0xae 0x01 0x01 0x00 0x00 0x00 0xff
    if let data = characteristic.value {
      let ready: [UInt8] = [0x51, 0x78, 0xae, 0x01, 0x01, 0x00, 0x00, 0x00, 0xff]
      if data.count == ready.count && [UInt8](data) == ready {
        // printer ready; could resume a continuation
        sendContinuation?.resume(returning: ())
        sendContinuation = nil
      }
    }
  }
}
