import Foundation
import simd

@main
struct SpatialCaptureChecks {
    static func main() {
        let k = simd_float3x3(SIMD3(1000, 0, 0), SIMD3(0, 1000, 0), SIMD3(960, 720, 1))
        func project(_ pixel: SIMD2<Float>, transform: simd_float4x4 = matrix_identity_float4x4) -> SIMD3<Float> {
            SpatialProjection.worldPoint(pixel: pixel, depth: 2, intrinsics: k, imageSize: SIMD2(1920, 1440), depthSize: SIMD2(256, 192), cameraTransform: transform)
        }
        precondition(simd_distance(project(SIMD2(128, 96)), SIMD3(0, 0, -2)) < 0.0001)
        precondition(project(SIMD2(140, 110)).x > 0 && project(SIMD2(140, 110)).y < 0)
        var pose = matrix_identity_float4x4
        pose.columns.3 = SIMD4(1, 2, 3, 1)
        precondition(simd_distance(project(SIMD2(128, 96), transform: pose), SIMD3(1, 2, 1)) < 0.0001)
        func point(_ x: Float, confidence: UInt8 = 1) -> SpatialPoint {
            SpatialPoint(position: SIMD3(x, 0, -2), color: SIMD3(1, 0, 0), confidence: confidence, depth: 2)
        }
        var grid = VoxelGrid(cellSize: 0.02, capacity: 3)
        grid.insert(point(0.001))
        grid.insert(point(0.002, confidence: 2))
        precondition(grid.points.count == 1 && grid.points[0].confidence == 2)
        grid.insert(point(0.003, confidence: 0))
        precondition(grid.points[0].confidence == 2)
        grid.insert(point(-0.001))
        precondition(grid.points.count == 2, "Negative coordinates must floor into a separate cell")
        grid.insert(point(0.021))
        grid.insert(point(0.041))
        precondition(grid.isFull && grid.points.count == 3)
        grid.insert(point(.nan))
        precondition(grid.points.count == 3)
        print("PASS: scaled camera intrinsics, camera axes, world pose, voxel deduplication, confidence replacement, negative cells, capacity, invalid input")
    }
}
