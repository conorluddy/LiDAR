import Foundation
import simd

nonisolated struct VoxelGrid: Sendable {
    struct Key: Hashable, Sendable {
        let x: Int
        let y: Int
        let z: Int
    }

    let cellSize: Float
    let capacity: Int
    private(set) var points: [SpatialPoint] = []
    private var indices: [Key: Int] = [:]

    init(cellSize: Float = 0.02, capacity: Int = 80_000) {
        precondition(cellSize > 0 && capacity > 0)
        self.cellSize = cellSize
        self.capacity = capacity
    }

    var isFull: Bool { points.count >= capacity }

    mutating func insert(_ point: SpatialPoint) {
        guard point.position.x.isFinite, point.position.y.isFinite, point.position.z.isFinite,
              simd_length(point.position) < 10_000 else { return }
        let cell = point.position / cellSize
        let key = Key(x: Int(floor(cell.x)), y: Int(floor(cell.y)), z: Int(floor(cell.z)))
        if let index = indices[key] {
            if point.confidence > points[index].confidence { points[index] = point }
        } else if !isFull {
            indices[key] = points.count
            points.append(point)
        }
    }
}

#if os(iOS)
import ARKit
import CoreImage

extension PointCloud {
    @concurrent static func accumulate(frame: ARFrame, depth: ARDepthData, context: CIContext, grid: VoxelGrid, minimumConfidence: UInt8, maximumDistance: Float) async -> VoxelGrid {
        let observation = await capture(frame: frame, depth: depth, context: context, stride: 4)
        var result = grid
        for point in observation.points where point.confidence >= minimumConfidence && point.depth <= maximumDistance {
            result.insert(point)
        }
        return result
    }
}
#endif
