import SwiftUI

/// Settings panel view displayed in the menu bar popover
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore
    
    var body: some View {
        Form {
            // Display toggles section
            Section("Display") {
                Toggle("Show CPU", isOn: $preferences.showCPU)
                Toggle("Show GPU", isOn: $preferences.showGPU)
                Toggle("Show RAM", isOn: $preferences.showRAM)
                Toggle("Show Disk", isOn: $preferences.showDisk)
                Toggle("Show Network", isOn: $preferences.showNet)
            }
            
            // Refresh interval section
            Section("Refresh") {
                Picker("Interval", selection: $preferences.refreshInterval) {
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                }
                .pickerStyle(.menu)
            }
            
            // Network unit section
            Section("Network Unit") {
                Picker("Unit", selection: $preferences.netUnit) {
                    Text("Mbps").tag("Mbps")
                    Text("Kbps").tag("Kbps")
                }
                .pickerStyle(.segmented)
            }
            
            // System section
            Section("System") {
                Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
            }
            
            // Actions section
            Section {
                Button("Quit StaBar") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .frame(width: 260)
    }
}

#Preview {
    SettingsView(preferences: PreferencesStore.shared)
}
