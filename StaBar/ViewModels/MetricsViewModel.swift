import Foundation
import Observation

/// Observable view model that collects metrics from all readers and binds them to UI
@Observable
final class MetricsViewModel {
    static let shared = MetricsViewModel()
    
    // MARK: - Published Metrics
    var cpuUsage: Double = 0
    var gpuUsage: Double? = nil
    var ramUsage: Double = 0
    var diskUsage: Double = 0
    var netUpload: Double = 0
    var netDownload: Double = 0

    var menuBarText: String {
        let prefs = PreferencesStore.shared
        var parts: [String] = []

        if prefs.showCPU {
            parts.append("C \(Int(cpuUsage))%")
        }
        if prefs.showGPU, let gpu = gpuUsage {
            parts.append("G \(Int(gpu))%")
        }
        if prefs.showRAM {
            parts.append("R \(Int(ramUsage))%")
        }
        if prefs.showDisk {
            parts.append("D \(Int(diskUsage))%")
        }
        if prefs.showNet {
            let upStr = formatMenuBarSpeed(netUpload, unit: prefs.netUnit)
            let downStr = formatMenuBarSpeed(netDownload, unit: prefs.netUnit)
            parts.append("↑\(upStr)↓\(downStr)")
        }

        return parts.isEmpty ? "StaBar" : parts.joined(separator: "  ")
    }

    private func formatMenuBarSpeed(_ bytesPerSec: Double, unit: String) -> String {
        let value: Double
        if unit == "MB/s" {
            value = bytesPerSec / 1_048_576
        } else {
            value = bytesPerSec / 125_000
        }
        if value < 0.1 { return "—" }
        if value < 10 { return String(format: "%.1f", value) }
        return String(format: "%.0f", value)
    }

    // MARK: - Private Properties
    private let cpuReader = CPUReader()
    private let gpuReader = GPUReader()
    private let ramReader = RAMReader()
    private let diskReader = DiskReader()
    private let netReader = NetReader()
    
    private var timer: Timer?
    private var intervalCheckTimer: Timer?
    
    // MARK: - Init
    init() {
        setupTimerObservation()
        // Initial collection
        collectMetrics()
    }
    
    deinit {
        timer?.invalidate()
        intervalCheckTimer?.invalidate()
    }
    
    // MARK: - Timer Management
    private func setupTimerObservation() {
        // Watch for refreshInterval changes and reschedule timer
        var lastInterval = PreferencesStore.shared.refreshInterval
        
        // Use a periodic check for interval changes
        intervalCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentInterval = PreferencesStore.shared.refreshInterval
            if currentInterval != lastInterval {
                lastInterval = currentInterval
                self.rescheduleTimer()
            }
        }
        
        rescheduleTimer()
    }
    
    private func rescheduleTimer() {
        timer?.invalidate()
        
        let interval = PreferencesStore.shared.refreshInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
    }
    
    // MARK: - Metric Collection
    func collectMetrics() {
        // Dispatch to background queue for collection
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var cpuValue: Double = 0
            var gpuValue: Double? = nil
            var ramValue: Double = 0
            var diskValue: Double = 0
            var netUploadValue: Double = 0
            var netDownloadValue: Double = 0
            
            // Collect CPU
            do {
                cpuValue = try self.cpuReader.read()
            } catch {
                cpuValue = 0
            }
            
            // Collect GPU
            gpuValue = self.gpuReader.read()
            
            // Collect RAM
            do {
                ramValue = try self.ramReader.read()
            } catch {
                ramValue = 0
            }
            
            // Collect Disk
            do {
                diskValue = try self.diskReader.read()
            } catch {
                diskValue = 0
            }
            
            // Collect Network
            do {
                let netMetric = try self.netReader.read()
                netUploadValue = netMetric.upload
                netDownloadValue = netMetric.download
            } catch {
                netUploadValue = 0
                netDownloadValue = 0
            }
            
            // Update on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.cpuUsage = cpuValue
                self.gpuUsage = gpuValue
                self.ramUsage = ramValue
                self.diskUsage = diskValue
                self.netUpload = netUploadValue
                self.netDownload = netDownloadValue
            }
        }
    }
}
