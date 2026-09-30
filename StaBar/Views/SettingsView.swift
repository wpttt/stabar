import SwiftUI

/// Compact settings panel shown when the status item is clicked.
/// Uses the same visual language as the hover detail panel: a slim header,
/// small section titles, one compact control per row and no scrolling.
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.45)

            VStack(spacing: 0) {
                section("Metrics") { metricChips }
                section("Refresh") { refreshRow }
                section("Network") { networkRow }
                section("Hover Details") { hoverRow }
                section("System") { systemRow }
            }
            .padding(.vertical, 2)

            Divider().opacity(0.45)
            footer
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("StaBar Settings")
                .font(.system(size: 12, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, HoverDetailView.contentInset)
        .padding(.top, 10)
        .padding(.bottom, 9)
    }

    // MARK: - Sections
    private var metricChips: some View {
        // Each chip takes an equal share of the row so the five of them always
        // fit exactly between the panel's side margins — an overflowing row
        // would widen the whole stack and push this section out of alignment.
        HStack(spacing: 4) {
            chip("CPU", "cpu", MetricPalette.Tint.cpu, isOn: preferences.showCPU) {
                preferences.showCPU = !preferences.showCPU
            }
            chip("GPU", "gamecontroller", MetricPalette.Tint.gpu, isOn: preferences.showGPU) {
                preferences.showGPU = !preferences.showGPU
            }
            chip("RAM", "memorychip", MetricPalette.Tint.ram, isOn: preferences.showRAM) {
                preferences.showRAM = !preferences.showRAM
            }
            chip("Disk", "internaldrive", MetricPalette.Tint.disk, isOn: preferences.showDisk) {
                preferences.showDisk = !preferences.showDisk
            }
            chip("Net", "arrow.up.arrow.down", MetricPalette.Tint.net, isOn: preferences.showNet) {
                preferences.showNet = !preferences.showNet
            }
        }
    }

    private func chip(_ title: String, _ icon: String, _ tint: Color, isOn: Bool, action: @escaping () -> Void) -> some View {
        MetricChip(title: title, icon: icon, tint: tint, isOn: isOn, action: action)
            .frame(maxWidth: .infinity)
    }

    private var refreshRow: some View {
        settingRow(label: "Interval") {
            Picker("Interval", selection: $preferences.refreshInterval) {
                Text("1s").tag(1.0)
                Text("2s").tag(2.0)
                Text("5s").tag(5.0)
                Text("10s").tag(10.0)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: 132)
        }
    }

    private var networkRow: some View {
        settingRow(label: "Unit") {
            Picker("Unit", selection: $preferences.netUnit) {
                Text("Mbps").tag("Mbps")
                Text("Kbps").tag("Kbps")
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: 132)
        }
    }

    private var hoverRow: some View {
        settingRow(label: "Details") {
            HStack(spacing: 8) {
                Toggle("Details", isOn: $preferences.hoverDetailEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Text("Delay")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)

                Picker("Delay", selection: $preferences.hoverDelay) {
                    Text("1s").tag(1.0)
                    Text("2s").tag(2.0)
                    Text("3s").tag(3.0)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 84)
                .disabled(!preferences.hoverDetailEnabled)
            }
        }
    }

    private var systemRow: some View {
        settingRow(label: "Launch at Login") {
            Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                preferences.resetToDefaults()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .labelStyle(.titleAndIcon)
            }
            .controlSize(.small)
            .buttonStyle(.bordered)
            .focusEffectDisabled()

            Spacer()

            Button("Quit StaBar") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.red)
        }
        .padding(.horizontal, HoverDetailView.contentInset)
        .padding(.vertical, 9)
    }

    // MARK: - Layout Helpers
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, HoverDetailView.contentInset)
        .padding(.top, 8)
    }

    private func settingRow<Accessory: View>(
        label: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
            Spacer(minLength: 6)
            accessory()
        }
        .frame(height: 22)
    }
}

// MARK: - Metric Chip
/// Pill button used to toggle a single metric on the menu bar.
private struct MetricChip: View {
    let title: String
    let icon: String
    let tint: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8.5, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isOn ? tint : MetricPalette.inactive)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isOn ? tint.opacity(0.26) : Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isOn ? tint.opacity(0.18) : Color.primary.opacity(0.07), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Keep the chip looking like a chip: without this, clicking it gives it
        // keyboard focus and AppKit draws a blue focus ring around it.
        .focusEffectDisabled()
        .help("Show \(title) in the menu bar")
    }
}

#Preview {
    SettingsView(preferences: PreferencesStore.shared)
        .frame(width: HoverDetailView.panelWidth)
        .background { PanelBackground() }
        .padding(.vertical, 4)
}
