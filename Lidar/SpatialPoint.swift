import Foundation
import simd
#if os(iOS)
import ARKit
import CoreImage
import UIKit
#endif

nonisolated struct SpatialPoint: Sendable {
    let position: SIMD3<Float>
    let color: SIMD3<Float>
    let confidence: UInt8
    let depth: Float
}

nonisolated struct PointCloud: Identifiable, Sendable {
    let id = UUID()
    let points: [SpatialPoint]
    let cameraTransform: simd_float4x4
    let isDemo: Bool

    #if os(iOS)
    @concurrent static func capture(frame: ARFrame, depth: ARDepthData, context: CIContext, stride step: Int = 2) async -> PointCloud {
        let sample = DepthInspection(depth)
        let image = CIImage(cvPixelBuffer: frame.capturedImage)
        let scaleX = CGFloat(sample.width) / image.extent.width
        let scaleY = CGFloat(sample.height) / image.extent.height
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        var pixels = [UInt8](repeating: 0, count: sample.width * sample.height * 4)
        context.render(scaled, toBitmap: &pixels, rowBytes: sample.width * 4, bounds: CGRect(x: 0, y: 0, width: sample.width, height: sample.height), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        let resolution = frame.camera.imageResolution
        let k = frame.camera.intrinsics
        var points: [SpatialPoint] = []
        for y in stride(from: 0, to: sample.height, by: step) {
            for x in stride(from: 0, to: sample.width, by: step) {
                let i = y * sample.width + x
                let z = sample.depths[i]
                guard z.isFinite, z > 0.1, z <= 8 else { continue }
                // Image coordinates have y down and z forward; ARKit camera has y up and z back.
                let world = SpatialProjection.worldPoint(pixel: SIMD2(Float(x), Float(y)), depth: z, intrinsics: k, imageSize: SIMD2(Float(resolution.width), Float(resolution.height)), depthSize: SIMD2(Float(sample.width), Float(sample.height)), cameraTransform: frame.camera.transform)
                points.append(SpatialPoint(position: world, color: SIMD3(Float(pixels[i * 4]), Float(pixels[i * 4 + 1]), Float(pixels[i * 4 + 2])) / 255, confidence: sample.confidence[i], depth: z))
            }
        }
        return PointCloud(points: points, cameraTransform: frame.camera.transform, isDemo: false)
    }

    #endif

    static var demo: PointCloud {
        var points: [SpatialPoint] = []
        for y in -35...35 {
            for x in -45...45 {
                let px = Float(x) / 40
                let py = Float(y) / 40
                let z: Float = -2 + 0.25 * cos(px * 3) * cos(py * 3)
                points.append(SpatialPoint(position: SIMD3(px, py, z), color: SIMD3(Float(x + 45) / 90, Float(y + 35) / 70, 0.8), confidence: abs(x) > 35 ? 0 : 2, depth: -z))
            }
        }
        return PointCloud(points: points, cameraTransform: matrix_identity_float4x4, isDemo: true)
    }
}
