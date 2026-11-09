import Foundation
import simd

@main
struct SpatialMeasurementChecks {
    static func main() {
        func near(_ actual: Float, _ expected: Float, _ name: String) {
            precondition(abs(actual - expected) < 0.001, "\(name): got \(actual), expected \(expected)")
        }
        let origin = SIMD3<Float>.zero
        near(SpatialMeasurement.distance(origin, SIMD3(3, 4, 0)), 5, "3-4-5 distance")
        near(SpatialMeasurement.distance(SIMD3(-2, 1, -3), SIMD3(-2, 1, -3)), 0, "identical endpoints")
        near(SpatialMeasurement.tilt(origin, SIMD3(1, 0, 0), SIMD3(0, 0, 1))!, 0, "horizontal plane")
        near(SpatialMeasurement.tilt(origin, SIMD3(1, 0, 0), SIMD3(0, 1, 0))!, 90, "vertical plane")
        near(SpatialMeasurement.tilt(origin, SIMD3(1, 0, 0), SIMD3(0, 1, 1))!, 45, "sloped plane")
        near(SpatialMeasurement.tilt(origin, SIMD3(0, 1, 1), SIMD3(1, 0, 0))!, 45, "reversed normal")
        precondition(SpatialMeasurement.tilt(origin, SIMD3(1, 0, 0), SIMD3(2, 0, 0)) == nil)
        precondition(SpatialMeasurement.tilt(origin, SIMD3(0.01, 0, 0), SIMD3(0, 0, 1)) == nil)
        print("PASS: distance, horizontal/vertical/sloped planes, reversed normals, collinear and short-baseline rejection")
    }
}
