import SwiftUI

/// Individual metric column displayed in the menu bar status item
struct MetricColumn: View {
    let label: String
    let value: String
    /// Fixed width so the status item never resizes while the numbers change.
    var width: CGFloat? = nil

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.7))
            Text(value)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(width: width)
    }
}

/// HStack of per-metric VStack columns for the menu bar status item
struct StatusBarContentView: View {
    var viewModel: MetricsViewModel

    /// Menu bar items are right aligned, so any width change shifts every icon
    /// to the left of it. Sizing each column for its worst case ("100%", "999+")
    /// keeps the status item perfectly still while the metrics update.
    private enum ColumnWidth {
        /// Fits "cpu" (label) and "100%" (value)
        static let percent: CGFloat = 22
        /// Fits "↑999+" / "↓999+"
        static let network: CGFloat = 30
    }

    var body: some View {
        let prefs = PreferencesStore.shared
        HStack(spacing: 6) {
            if prefs.showCPU {
                MetricColumn(label: "cpu", value: "\(Int(viewModel.cpuUsage))%", width: ColumnWidth.percent)
            }
            if prefs.showGPU {
                // The column stays in place even when GPU stats are missing,
                // otherwise the whole status item would jump in width.
                let gpu = viewModel.gpuUsage.map { "\(Int($0))%" } ?? "—"
                MetricColumn(label: "gpu", value: gpu, width: ColumnWidth.percent)
            }
            if prefs.showRAM {
                MetricColumn(label: "ram", value: "\(Int(viewModel.ramUsage))%", width: ColumnWidth.percent)
            }
            if prefs.showDisk {
                MetricColumn(label: "dsk", value: "\(Int(viewModel.diskUsage))%", width: ColumnWidth.percent)
            }
            if prefs.showNet {
                let upStr = viewModel.formatSpeed(viewModel.netUpload, unit: prefs.netUnit)
                let downStr = viewModel.formatSpeed(viewModel.netDownload, unit: prefs.netUnit)
                MetricColumn(label: "↑\(upStr)", value: "↓\(downStr)", width: ColumnWidth.network)
            }
        }
        .frame(height: 22)
    }
}
