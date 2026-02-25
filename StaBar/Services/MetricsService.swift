import Foundation

// MARK: - Metric Type Enumeration
enum MetricType: String, CaseIterable {
    case cpu
    case gpu
    case ram
    case disk
    case net
}

// MARK: - Metric Value
/// Result of reading a metric
struct MetricValue {
    let type: MetricType
    let value: Double      // Percentage (0-100) or speed (bytes/sec for net)
    let unit: String       // "%", "MB/s", "Mbps"
    let timestamp: Date
}

// MARK: - Network Metric
/// Network specific metric with upload AND download speeds
struct NetworkMetric {
    let upload: Double     // bytes per second
    let download: Double   // bytes per second
    let timestamp: Date
}

// MARK: - Metric Error
/// Errors that can occur during metric collection
enum MetricError: Error {
    case notAvailable
    case readFailed(String)
    case permissionDenied
}

// MARK: - Metric Reader Protocol
/// Protocol for metric readers
protocol MetricReader {
    associatedtype Output
    func read() throws -> Output
}

// MARK: - Metrics Service Protocol
/// Main service protocol for metric collection
protocol MetricsServiceProtocol {
    func readCPU() -> Double?
    func readGPU() -> Double?
    func readRAM() -> Double?
    func readDisk() -> Double?
    func readNetwork() -> NetworkMetric?
}
