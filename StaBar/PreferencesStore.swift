import Foundation
import Observation

@Observable
final class PreferencesStore {
    static let shared = PreferencesStore()
    
    private let defaults = UserDefaults(suiteName: "com.user.StaBar")!
    
    var showCPU: Bool {
        didSet { defaults.set(showCPU, forKey: "showCPU") }
    }
    
    var showGPU: Bool {
        didSet { defaults.set(showGPU, forKey: "showGPU") }
    }
    
    var showRAM: Bool {
        didSet { defaults.set(showRAM, forKey: "showRAM") }
    }
    
    var showDisk: Bool {
        didSet { defaults.set(showDisk, forKey: "showDisk") }
    }
    
    var showNet: Bool {
        didSet { defaults.set(showNet, forKey: "showNet") }
    }
    
    var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: "refreshInterval") }
    }
    
    var netUnit: String {
        didSet { defaults.set(netUnit, forKey: "netUnit") }
    }
    
    var launchAtLogin: Bool {
        get { LaunchAtLogin.isEnabled }
        set { LaunchAtLogin.setEnabled(newValue) }
    }
    
    init() {
        self.showCPU = defaults.bool(forKey: "showCPU", default: true)
        self.showGPU = defaults.bool(forKey: "showGPU", default: true)
        self.showRAM = defaults.bool(forKey: "showRAM", default: true)
        self.showDisk = defaults.bool(forKey: "showDisk", default: true)
        self.showNet = defaults.bool(forKey: "showNet", default: true)
        self.refreshInterval = defaults.double(forKey: "refreshInterval", default: 2.0)
        let savedUnit = defaults.string(forKey: "netUnit") ?? "Mbps"
        self.netUnit = (savedUnit == "MB/s") ? "Mbps" : savedUnit
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin", default: false)
    }
    
    func resetToDefaults() {
        showCPU = true
        showGPU = true
        showRAM = true
        showDisk = true
        showNet = true
        refreshInterval = 2.0
        netUnit = "Mbps"
        launchAtLogin = false
    }
}

extension UserDefaults {
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil { return defaultValue }
        return bool(forKey: key)
    }
    
    func double(forKey key: String, default defaultValue: Double) -> Double {
        if object(forKey: key) == nil { return defaultValue }
        return double(forKey: key)
    }
}
