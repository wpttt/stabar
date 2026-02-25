import Foundation
import Darwin

/// Network throughput reader using BSD network APIs
/// Tracks upload/download bytes per second across all active interfaces (excluding loopback)
public final class NetReader: MetricReader {
    public typealias Output = NetworkMetric
    
    // MARK: - Previous State
    private var previousUpload: UInt64 = 0
    private var previousDownload: UInt64 = 0
    private var previousTimestamp: Date?
    
    // MARK: - Read Method
    public func read() throws -> NetworkMetric {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            throw MetricError.readFailed("getifaddrs() failed")
        }
        defer { freeifaddrs(ifaddr) }
        
        var totalUpload: UInt64 = 0
        var totalDownload: UInt64 = 0
        
        var current = ifaddr
        while current != nil {
            defer { current = current!.pointee.ifa_next }
            
            let interface = current!.pointee
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback interface
            if name == "lo0" { continue }
            
            // Check if this is a network statistics entry (AF_LINK)
            guard let addr = interface.ifa_addr else { continue }
            guard addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            
            // Get network interface statistics
            guard let data = interface.ifa_data else { continue }
            let ifData = data.assumingMemoryBound(to: if_data.self).pointee
            
            // Accumulate bytes from all interfaces
            totalUpload += UInt64(ifData.ifi_obytes)
            totalDownload += UInt64(ifData.ifi_ibytes)
        }
        
        let currentTimestamp = Date()
        
        // Calculate speed (bytes per second)
        var uploadSpeed: Double = 0
        var downloadSpeed: Double = 0
        
        if let prevTimestamp = previousTimestamp {
            let deltaTime = currentTimestamp.timeIntervalSince(prevTimestamp)
            
            // Prevent division by zero and handle counter resets
            if deltaTime > 0 && totalUpload >= previousUpload && totalDownload >= previousDownload {
                let uploadDelta = totalUpload - previousUpload
                let downloadDelta = totalDownload - previousDownload
                
                uploadSpeed = Double(uploadDelta) / deltaTime
                downloadSpeed = Double(downloadDelta) / deltaTime
            }
        }
        
        // Update previous state
        previousUpload = totalUpload
        previousDownload = totalDownload
        previousTimestamp = currentTimestamp
        
        return NetworkMetric(
            upload: uploadSpeed,
            download: downloadSpeed,
            timestamp: currentTimestamp
        )
    }
}
