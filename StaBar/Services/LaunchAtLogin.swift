import Foundation
import ServiceManagement

/// Manages launch at login status using SMAppService (macOS 13+)
enum LaunchAtLogin {
    
    /// Check if launch at login is enabled
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    /// Enable or disable launch at login
    static func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status == .enabled {
                        return // Already enabled
                    }
                    try SMAppService.mainApp.register()
                } else {
                    if SMAppService.mainApp.status != .enabled {
                        return // Already disabled
                    }
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("LaunchAtLogin error: \(error.localizedDescription)")
            }
        }
    }
}
