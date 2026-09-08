import Foundation
import ServiceManagement

/// Wraps SMAppService (macOS 13+) — the sandbox-friendly replacement for the
/// legacy SMLoginItemSetEnabled, no separate helper-app target needed.
final class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
