import SwiftUI

/// Compact metrics display for the menu bar popover header
/// Format: C 42% G 15% R 68% D 95% ↑1.2 ↓3.4
struct CompactStatusView: View {
    let preferences: PreferencesStore
    
    // Metric values (placeholder - will be bound in Task 14)
    var cpuUsage: Double = 0
    var gpuUsage: Double? = nil
    var ramUsage: Double = 0
    var diskUsage: Double = 0
    var netUpload: Double = 0
    var netDownload: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            if preferences.showCPU {
                MetricLabel(prefix: "C", value: cpuUsage)
            }
            if preferences.showGPU {
                MetricLabel(prefix: "G", value: gpuUsage)
            }
            if preferences.showRAM {
                MetricLabel(prefix: "R", value: ramUsage)
            }
            if preferences.showDisk {
                MetricLabel(prefix: "D", value: diskUsage)
            }
            if preferences.showNet {
                NetworkLabel(upload: netUpload, download: netDownload)
            }
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
    }
}

/// Individual metric label (e.g., "C 42%")
private struct MetricLabel: View {
    let prefix: String
    let value: Double?
    
    var body: some View {
        HStack(spacing: 2) {
            Text(prefix)
                .foregroundStyle(.secondary)
            Text(formattedValue)
        }
    }
    
    private var formattedValue: String {
        guard let value = value else { return "—%" }
        return String(format: "%.0f%%", value)
    }
}

/// Network throughput label (e.g., "↑1.2 ↓3.4")
private struct NetworkLabel: View {
    let upload: Double
    let download: Double
    
    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 1) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .semibold))
                Text(formatSpeed(upload))
            }
            HStack(spacing: 1) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .semibold))
                Text(formatSpeed(download))
            }
        }
        .foregroundStyle(.secondary)
    }
    
    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let mbps = bytesPerSec / 125000 // Convert to Mbps
        if mbps < 0.1 {
            return "—"
        } else if mbps < 10 {
            return String(format: "%.1f", mbps)
        } else {
            return String(format: "%.0f", mbps)
        }
    }
}

#Preview {
    CompactStatusView(
        preferences: PreferencesStore.shared,
        cpuUsage: 42,
        gpuUsage: 15,
        ramUsage: 68,
        diskUsage: 95,
        netUpload: 150000,
        netDownload: 425000
    )
    .padding()
}
