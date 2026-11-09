import simd

nonisolated enum SpatialProjection {
    static func worldPoint(pixel: SIMD2<Float>, depth: Float, intrinsics: simd_float3x3, imageSize: SIMD2<Float>, depthSize: SIMD2<Float>, cameraTransform: simd_float4x4) -> SIMD3<Float> {
        let scale = depthSize / imageSize
        let local = SIMD4<Float>((pixel.x - intrinsics[2][0] * scale.x) * depth / (intrinsics[0][0] * scale.x), -(pixel.y - intrinsics[2][1] * scale.y) * depth / (intrinsics[1][1] * scale.y), -depth, 1)
        let world = cameraTransform * local
        return SIMD3(world.x, world.y, world.z)
    }
}
