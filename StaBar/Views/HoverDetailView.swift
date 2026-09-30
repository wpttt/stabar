import SwiftUI

// MARK: - Detail Row Model
/// Load level of a metric. One hue per row keeps the panel calm: the icon,
/// the percentage and the bar all share it.
private enum LoadLevel {
    case normal
    case busy
    case hot

    var color: Color {
        switch self {
        case .normal: return MetricPalette.Status.normal
        case .busy: return MetricPalette.Status.busy
        case .hot: return MetricPalette.Status.hot
        }
    }
}

/// A single metric rendered as one row inside the hover detail panel.
private struct DetailRow: Identifiable {
    let key: String
    let icon: String
    let title: String
    let value: String
    /// Secondary caption rendered in grey, e.g. "27.3/32 GB".
    let detail: String?
    let level: LoadLevel
    let isMuted: Bool
    let progress: Double?

    var id: String { key }
}

// MARK: - Hover Detail View
/// Drop-down panel shown while the pointer rests on the status item.
/// Same visual language as the settings popover, but one metric per row,
/// larger type than the menu bar and fully expanded values.
struct HoverDetailView: View {
    /// Shared with the settings popover so both panels line up.
    static let panelWidth: CGFloat = 290
    /// Horizontal breathing room between the panel edge and its content.
    static let contentInset: CGFloat = 15

    private let viewModel = MetricsViewModel.shared
    private let preferences = PreferencesStore.shared

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.45)
            metricList
            Divider().opacity(0.45)
            footer
        }
        .frame(width: Self.panelWidth)
        .background { PanelBackground() }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("System Status")
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Circle()
                .fill(MetricPalette.indicator)
                .frame(width: 5, height: 5)
                .opacity(isPulsing ? 0.35 : 1)
            Text("Live · \(refreshLabel)")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Self.contentInset)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    // MARK: - Metric Rows
    private var metricList: some View {
        // No separators between metrics — the usage bars already give each row
        // its own rhythm, and hairline dividers only add visual noise.
        VStack(spacing: 0) {
            ForEach(buildRows()) { row in
                DetailMetricRow(row: row)
            }
        }
    }

    private func buildRows() -> [DetailRow] {
        var rows: [DetailRow] = []
        let prefs = preferences
        let vm = viewModel

        if prefs.showCPU {
            rows.append(
                DetailRow(
                    key: "cpu",
                    icon: "cpu",
                    title: "CPU",
                    value: "\(Int(vm.cpuUsage))%",
                    detail: nil,
                    level: loadLevel(vm.cpuUsage),
                    isMuted: false,
                    progress: vm.cpuUsage / 100
                )
            )
        }

        if prefs.showGPU {
            if let gpu = vm.gpuUsage {
                rows.append(
                    DetailRow(
                        key: "gpu",
                        icon: "gamecontroller",
                        title: "GPU",
                        value: "\(Int(gpu))%",
                        detail: nil,
                        level: loadLevel(gpu),
                        isMuted: false,
                        progress: gpu / 100
                    )
                )
            } else {
                rows.append(
                    DetailRow(
                        key: "gpu",
                        icon: "gamecontroller",
                        title: "GPU",
                        value: "N/A",
                        detail: nil,
                        level: .normal,
                        isMuted: true,
                        progress: nil
                    )
                )
            }
        }

        if prefs.showRAM {
            rows.append(
                DetailRow(
                    key: "ram",
                    icon: "memorychip",
                    title: "RAM",
                    value: "\(Int(vm.ramUsage))%",
                    detail: vm.formatCapacity(used: vm.ramUsed, total: vm.ramTotal, binary: true),
                    level: loadLevel(vm.ramUsage),
                    isMuted: false,
                    progress: vm.ramUsage / 100
                )
            )
        }

        if prefs.showDisk {
            rows.append(
                DetailRow(
                    key: "disk",
                    icon: "internaldrive",
                    title: "Disk",
                    value: "\(Int(vm.diskUsage))%",
                    detail: vm.formatCapacity(used: vm.diskUsed, total: vm.diskTotal),
                    level: loadLevel(vm.diskUsage),
                    isMuted: false,
                    progress: vm.diskUsage / 100
                )
            )
        }

        if prefs.showNet {
            let unit = prefs.netUnit
            let down = vm.formatSpeed(vm.netDownload, unit: unit)
            let up = vm.formatSpeed(vm.netUpload, unit: unit)
            let idle = (down == "—" && up == "—")
            rows.append(
                DetailRow(
                    key: "net",
                    icon: "arrow.up.arrow.down",
                    title: "Network",
                    value: idle ? "Idle" : "↓\(down) ↑\(up) \(unit)",
                    detail: nil,
                    level: .normal,
                    isMuted: idle,
                    progress: nil
                )
            )
        }

        return rows
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
            Text("Up \(viewModel.formatUptime())")
            Spacer()
            Text("Click for settings")
        }
        .font(.system(size: 9.5))
        .foregroundStyle(.secondary)
        .padding(.horizontal, Self.contentInset)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers
    private var refreshLabel: String {
        let interval = preferences.refreshInterval
        return interval < 1 ? "\(Int(interval * 1000))ms" : "\(Int(interval))s"
    }

    /// Load level behind the small status dot.
    private func loadLevel(_ value: Double) -> LoadLevel {
        switch value {
        case ..<60: return .normal
        case ..<85: return .busy
        default: return .hot
        }
    }
}

// MARK: - Metric Row
private struct DetailMetricRow: View {
    let row: DetailRow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Neutral badge: the icon carries the row's single status hue,
                // which keeps the panel from stacking five different colours.
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(0.10))
                    Image(systemName: row.icon)
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(row.isMuted ? AnyShapeStyle(.secondary) : AnyShapeStyle(row.level.color))
                }
                .frame(width: 20, height: 20)

                Text(row.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .leading)

                Spacer(minLength: 6)

                Text(row.value)
                    .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(row.isMuted ? AnyShapeStyle(.secondary) : AnyShapeStyle(row.level.color))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)

                if let detail = row.detail {
                    Text(detail)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            bar
                .frame(height: 2)
        }
        .padding(.horizontal, HoverDetailView.contentInset)
        .padding(.vertical, 6)
    }

    /// Usage bar under each percentage metric — same hue as the value.
    @ViewBuilder
    private var bar: some View {
        if let progress = row.progress {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.10))
                    Capsule()
                        .fill(row.level.color.opacity(0.75))
                        .frame(width: barWidth(total: geometry.size.width, progress: progress))
                }
            }
        } else {
            // Keep rows the same height when a metric has no bar.
            Capsule()
                .fill(Color.clear)
        }
    }

    private func barWidth(total: CGFloat, progress: Double) -> CGFloat {
        let clamped = min(max(progress, 0), 1)
        return max(3, total * CGFloat(clamped))
    }
}

#Preview {
    HoverDetailView()
        .background { PanelBackground() }
        .padding(.vertical, 4)
}
