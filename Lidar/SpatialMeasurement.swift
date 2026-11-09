import Foundation
import simd

/// Pure geometry shared by the inspector and standalone validation executable.
enum SpatialMeasurement {
    nonisolated static func distance(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_distance(a, b)
    }

    /// Angle to a horizontal plane in ARKit's gravity-aligned world coordinates.
    /// Reject very short baselines and nearly collinear selections.
    nonisolated static func tilt(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> Float? {
        let ab = b - a
        let ac = c - a
        guard simd_length(ab) >= 0.05, simd_length(ac) >= 0.05,
              simd_distance(b, c) >= 0.05 else { return nil }
        let normal = simd_cross(ab, ac)
        guard simd_length(normal) / (simd_length(ab) * simd_length(ac)) > 0.1 else { return nil }
        return acos(min(1, abs(simd_normalize(normal).y))) * 180 / .pi
    }
}
