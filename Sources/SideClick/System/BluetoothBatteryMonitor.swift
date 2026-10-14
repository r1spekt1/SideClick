import CoreBluetooth
import MouseCore
import os

// File-level, so the nonisolated CoreBluetooth delegate methods can use them.
private let batteryService = CBUUID(string: BluetoothBattery.serviceUUID)
private let batteryLevel = CBUUID(string: BluetoothBattery.levelUUID)

/// Reads the battery of a connected Bluetooth Low Energy mouse through the standard Battery
/// Service and follows its notifications, so there is no polling. Only peripherals named like a connected
/// Bluetooth mouse are used, never headphones or keyboards. CoreBluetooth is started only once
/// such a mouse appears, so people without one never see the Bluetooth permission prompt.
@MainActor
final class BluetoothBatteryMonitor: NSObject {
    /// Called whenever `status` or `isDenied` may have changed.
    var onChange: (() -> Void)?
    private(set) var status: BatteryStatus?
    var isDenied: Bool { [.denied, .restricted].contains(CBCentralManager.authorization) }

    private let log = Logger(subsystem: "com.r1spekt1.SideClick", category: "battery")
    private var central: CBCentralManager?
    private var mouseNames: Set<String> = []
    private var peripheral: CBPeripheral?
    private var isRetryScheduled = false

    /// Call with the names of the connected Bluetooth mice whenever that list changes.
    func update(mouseNames names: [String]) {
        mouseNames = Set(names.filter { !$0.isEmpty })
        if let peripheral, !mouseNames.contains(peripheral.name ?? "") { drop(peripheral) }
        guard !mouseNames.isEmpty else { return }
        if let central {
            connectToMouse(central)
        } else {
            // Shows the permission prompt the first time.
            central = CBCentralManager(delegate: self, queue: .main)
        }
    }

    private func connectToMouse(_ central: CBCentralManager) {
        guard central.state == .poweredOn, peripheral == nil else { return }
        let match = central.retrieveConnectedPeripherals(withServices: [batteryService])
            .first { mouseNames.contains($0.name ?? "") }
        guard let match else {
            scheduleRetry()
            return
        }
        peripheral = match
        match.delegate = self
        central.connect(match)
    }

    /// Releases only this app's link; the system keeps the mouse connected.
    private func drop(_ peripheral: CBPeripheral) {
        central?.cancelPeripheralConnection(peripheral)
        self.peripheral = nil
        publish(nil)
    }

    private func lost(_ lostPeripheral: CBPeripheral) {
        guard lostPeripheral === peripheral else { return }
        peripheral = nil
        publish(nil)
        scheduleRetry()
    }

    /// Looks again later while a Bluetooth mouse is still connected: CoreBluetooth can list the
    /// peripheral only after the HID device appears, and this app's own link can drop while the
    /// system keeps the mouse connected. Neither changes the HID list, so nothing else would retry.
    private func scheduleRetry() {
        guard !isRetryScheduled, !mouseNames.isEmpty else { return }
        isRetryScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                isRetryScheduled = false
                if let central { connectToMouse(central) }
            }
        }
    }

    private func publish(_ newStatus: BatteryStatus?) {
        guard newStatus != status else { return }
        status = newStatus
        onChange?()
    }
}

extension BluetoothBatteryMonitor: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated {
            if central.state == .poweredOn {
                connectToMouse(central)
            } else {
                peripheral = nil
                publish(nil)
            }
            onChange?()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([batteryService])
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                                    error: Error?) {
        MainActor.assumeIsolated { lost(peripheral) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                                    error: Error?) {
        MainActor.assumeIsolated { lost(peripheral) }
    }
}

extension BluetoothBatteryMonitor: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid == batteryService {
            peripheral.discoverCharacteristics([batteryLevel], for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                                error: Error?) {
        for characteristic in service.characteristics ?? [] where characteristic.uuid == batteryLevel {
            peripheral.readValue(for: characteristic)
            if characteristic.properties.contains(.notify) { peripheral.setNotifyValue(true, for: characteristic) }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                                error: Error?) {
        let value = characteristic.value.map { [UInt8]($0) } ?? []
        let failure = error?.localizedDescription
        MainActor.assumeIsolated {
            guard peripheral === self.peripheral else { return }
            // A failed read carries no new level, so the shown one stays.
            if let failure {
                log.error("Reading the Bluetooth battery level failed: \(failure, privacy: .public)")
                return
            }
            let battery = BluetoothBattery.status(fromLevel: value)
            if battery == nil {
                log.error("Unrecognized Bluetooth battery level: \(value, privacy: .public)")
            }
            publish(battery)
        }
    }
}
