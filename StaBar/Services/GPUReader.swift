import Foundation
import IOKit

/// Reads GPU usage metrics via IOAccelerator
/// Returns nil if GPU stats are unavailable (graceful degradation)
final class GPUReader {
    
    /// Reads GPU utilization percentage
    /// - Returns: GPU usage as percentage (0.0-100.0) or nil if unavailable
    func read() -> Double? {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            
            // Get properties dictionary
            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let properties = props?.takeRetainedValue() as? [String: Any] else {
                continue
            }
            
            // Look for PerformanceStatistics
            if let perfStats = properties["PerformanceStatistics"] as? [String: Any] {
                // Try different possible keys for GPU utilization
                if let utilization = perfStats["Device Utilization %"] as? Int {
                    return Double(utilization)
                }
                if let utilization = perfStats["GPU Activity(%)"] as? Int {
                    return Double(utilization)
                }
                if let utilization = perfStats["GPU Core Utilization"] as? Int {
                    return Double(utilization)
                }
                // Try NSNumber variants
                if let utilization = perfStats["Device Utilization %"] as? NSNumber {
                    return utilization.doubleValue
                }
            }
        }
        
        return nil  // GPU stats not available
    }
}
