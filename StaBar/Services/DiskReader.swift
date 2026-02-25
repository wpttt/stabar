import Foundation
import Darwin

// MARK: - Disk Reader
/// Reads disk usage metrics for the boot volume
public class DiskReader: MetricReader {
    public typealias Output = Double
    
    /// Reads boot volume disk usage percentage
    /// - Returns: Disk usage as a percentage (0.0-100.0)
    /// - Throws: MetricError if unable to read disk stats
    public func read() throws -> Double {
        var stats = statfs()
        
        // Get filesystem stats for root (boot volume)
        guard statfs("/", &stats) == 0 else {
            throw MetricError.readFailed("Failed to get filesystem stats")
        }
        
        // Calculate usage percentage
        let blockSize = UInt64(stats.f_bsize)
        let totalBlocks = UInt64(stats.f_blocks)
        let availableBlocks = UInt64(stats.f_bavail)
        
        let totalBytes = totalBlocks * blockSize
        let availableBytes = availableBlocks * blockSize
        let usedBytes = totalBytes - availableBytes
        
        let usagePercentage = (Double(usedBytes) / Double(totalBytes)) * 100.0
        
        // Clamp to 0-100 range to handle edge cases
        return min(100.0, max(0.0, usagePercentage))
    }
}
