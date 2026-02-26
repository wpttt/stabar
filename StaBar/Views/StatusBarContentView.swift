import SwiftUI

/// Individual metric column displayed in the menu bar status item
struct MetricColumn: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.7))
            Text(value)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}

/// HStack of per-metric VStack columns for the menu bar status item
struct StatusBarContentView: View {
    var viewModel: MetricsViewModel

    var body: some View {
        let prefs = PreferencesStore.shared
        HStack(spacing: 6) {
            if prefs.showCPU {
                MetricColumn(label: "cpu", value: "\(Int(viewModel.cpuUsage))%")
            }
            if prefs.showGPU, let gpu = viewModel.gpuUsage {
                MetricColumn(label: "gpu", value: "\(Int(gpu))%")
            }
            if prefs.showRAM {
                MetricColumn(label: "ram", value: "\(Int(viewModel.ramUsage))%")
            }
            if prefs.showDisk {
                MetricColumn(label: "dsk", value: "\(Int(viewModel.diskUsage))%")
            }
            if prefs.showNet {
                let upStr = viewModel.formatSpeed(viewModel.netUpload, unit: prefs.netUnit)
                let downStr = viewModel.formatSpeed(viewModel.netDownload, unit: prefs.netUnit)
                MetricColumn(label: "↑\(upStr)", value: "↓\(downStr)")
            }
        }
        .frame(height: 22)
    }
}
