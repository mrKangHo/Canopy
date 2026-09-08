import AppKit
import Combine
import IOKit.ps

/// Centralizes every power/lock-related observation (screen sleep, screen
/// lock, Low Power Mode, on-battery) into a single "should be paused right
/// now" signal, so WallpaperManager doesn't have to scatter NSWorkspace /
/// DistributedNotificationCenter / ProcessInfo observers across itself.
final class PowerStateMonitor: ObservableObject {
    @Published private(set) var shouldPause: Bool = false

    /// User-facing setting: pause playback while running on battery power.
    var pauseOnBattery: Bool = false {
        didSet { recompute() }
    }

    private var screenAsleep = false
    private var screenLocked = false
    private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    private var onBattery = false

    private var cancellables: [Any] = []

    init() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()

        cancellables.append(workspaceCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.screenAsleep = true; self?.recompute() })

        cancellables.append(workspaceCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.screenAsleep = false; self?.recompute() })

        cancellables.append(distributedCenter.addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"), object: nil, queue: .main
        ) { [weak self] _ in self?.screenLocked = true; self?.recompute() })

        cancellables.append(distributedCenter.addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main
        ) { [weak self] _ in self?.screenLocked = false; self?.recompute() })

        cancellables.append(NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main
        ) { _ in })

        cancellables.append(NotificationCenter.default.addObserver(
            forName: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            self?.recompute()
        })

        onBattery = Self.isOnBatteryPower()
        cancellables.append(distributedCenter.addObserver(
            forName: Notification.Name("com.apple.system.powersources.source.changed"), object: nil, queue: .main
        ) { [weak self] _ in
            self?.onBattery = Self.isOnBatteryPower()
            self?.recompute()
        })
    }

    private func recompute() {
        shouldPause = screenAsleep || screenLocked || lowPowerMode || (pauseOnBattery && onBattery)
    }

    private static func isOnBatteryPower() -> Bool {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
              let state = description[kIOPSPowerSourceStateKey] as? String
        else { return false }
        return state == kIOPSBatteryPowerValue
    }

    deinit {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()
        for token in cancellables {
            workspaceCenter.removeObserver(token)
            distributedCenter.removeObserver(token)
            NotificationCenter.default.removeObserver(token)
        }
    }
}
