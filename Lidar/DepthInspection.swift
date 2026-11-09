#if os(iOS)
import ARKit
import UIKit

nonisolated struct DepthInspection: Sendable {
    let width: Int
    let height: Int
    let depths: [Float]
    let confidence: [UInt8]

    init(_ data: ARDepthData) {
        let width = CVPixelBufferGetWidth(data.depthMap)
        let height = CVPixelBufferGetHeight(data.depthMap)
        self.width = width
        self.height = height
        CVPixelBufferLockBaseAddress(data.depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(data.depthMap, .readOnly) }
        let base = CVPixelBufferGetBaseAddress(data.depthMap)!
        depths = (0..<height).flatMap { row in
            Array(UnsafeBufferPointer(start: base.advanced(by: row * CVPixelBufferGetBytesPerRow(data.depthMap)).assumingMemoryBound(to: Float.self), count: width))
        }
        if let map = data.confidenceMap {
            CVPixelBufferLockBaseAddress(map, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(map, .readOnly) }
            let bytes = CVPixelBufferGetBaseAddress(map)!
            confidence = (0..<height).flatMap { row in
                Array(UnsafeBufferPointer(start: bytes.advanced(by: row * CVPixelBufferGetBytesPerRow(map)).assumingMemoryBound(to: UInt8.self), count: width))
            }
        } else {
            confidence = Array(repeating: 0, count: width * height)
        }
    }

    func image(confidenceOnly: Bool, limit: Float) -> UIImage? {
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        for index in depths.indices {
            let distance = depths[index]
            let valid = distance.isFinite && distance > 0
            let color: (UInt8, UInt8, UInt8)
            if !valid {
                color = (0, 0, 0)
            } else if confidenceOnly {
                color = confidence[index] == 2 ? (40, 220, 100) : confidence[index] == 1 ? (255, 210, 30) : (240, 50, 60)
            } else {
                let t = min(max(distance / limit, 0), 1)
                color = (UInt8(t * 255), UInt8((1 - abs(2 * t - 1)) * 200), UInt8((1 - t) * 255))
            }
            rgba[index * 4] = color.0
            rgba[index * 4 + 1] = color.1
            rgba[index * 4 + 2] = color.2
            rgba[index * 4 + 3] = 255
        }
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let cg = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: cg, scale: 1, orientation: .right)
    }

    // Preview is rotated clockwise from the sensor buffer, including in landscape.
    func statistics(at point: CGPoint) -> String {
        let x = min(width - 1, max(0, Int(point.y * CGFloat(width))))
        let y = min(height - 1, max(0, Int((1 - point.x) * CGFloat(height))))
        var values: [Float] = []
        var levels = [0, 0, 0]
        var count = 0
        for row in max(0, y - 4)...min(height - 1, y + 4) {
            for column in max(0, x - 4)...min(width - 1, x + 4) {
                count += 1
                let index = row * width + column
                let depth = depths[index]
                guard depth.isFinite, depth > 0 else { continue }
                values.append(depth)
                levels[min(2, Int(confidence[index]))] += 1
            }
        }
        guard !values.isEmpty else { return "No valid depth in selected patch." }
        let mean = values.reduce(0, +) / Float(values.count)
        let deviation = sqrt(values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Float(values.count))
        return String(format: "Patch mean %.2f m · spatial spread %.1f cm\nValid %d/%d · confidence low %d / medium %d / high %d", mean, deviation * 100, values.count, count, levels[0], levels[1], levels[2])
    }
}
#endif
