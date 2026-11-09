#if os(iOS)
import SwiftUI

struct PaintRoomView: View {
    @ObservedObject var capture: CaptureController
    @State private var colouring = "RGB"
    @State private var reset = UUID()
    @State private var demo: PointCloud?

    var body: some View {
        VStack(spacing: 16) {
            Text("Walk slowly around a static scene. Each observation adds surfaces to a shared 3D cloud.")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Button("Start New Scan") { demo = nil; capture.newScan() }
                Button(capture.painting ? "Pause Painting" : "Resume Painting") { capture.togglePainting() }
                    .disabled(!capture.running)
            }.buttonStyle(.bordered)
            if let cloud = demo ?? capture.scanCloud {
                if cloud.isDemo { Text("Synthetic accumulation demo · no sensor data").font(.headline) }
                Picker("Point colour", selection: $colouring) {
                    ForEach(["RGB", "Depth", "Confidence"], id: \.self) { Text($0) }
                }.pickerStyle(.segmented)
                CloudSceneView(cloud: cloud, colouring: colouring, highConfidenceOnly: false, reset: reset, cameraIdentity: capture.scanViewID)
                    .frame(height: 320).clipShape(RoundedRectangle(cornerRadius: 16))
                Text("\(cloud.points.count.formatted()) retained points").font(.caption).monospacedDigit()
                Button("Reset View") { reset = UUID() }
            } else {
                ContentUnavailableView("Paint the room", systemImage: "cube.transparent", description: Text("Start a scan to build a point cloud as you move."))
                    .frame(minHeight: 220)
            }
            Text(capture.scanMessage).font(.callout).monospacedDigit()
            Picker("Minimum confidence for new points", selection: $capture.minimumConfidence) {
                Text("All").tag(0)
                Text("Medium+").tag(1)
                Text("High").tag(2)
            }.pickerStyle(.segmented)
            HStack {
                Text("Capture distance")
                Slider(value: $capture.maximumDistance, in: 1...8, step: 0.5)
                Text("\(capture.maximumDistance, specifier: "%.1f") m").monospacedDigit()
            }.font(.caption)
            Text("Filters apply to new observations. Clear the scan to compare settings. Tracking stays active when painting is paused.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Inspect Scan") { capture.inspectScan() }.disabled(capture.scanCloud?.points.isEmpty != false || demo != nil)
                Button("Clear Scan") { demo = nil; capture.clearScan() }
            }.buttonStyle(.bordered)
            Button("Synthetic Accumulation Demo") {
                capture.stop()
                capture.clearScan()
                var grid = VoxelGrid()
                let observation = PointCloud.demo
                for point in observation.points { grid.insert(point) }
                for point in observation.points {
                    grid.insert(SpatialPoint(position: point.position + SIMD3(0.5, 0, -0.3), color: point.color, confidence: point.confidence, depth: point.depth))
                }
                demo = PointCloud(points: grid.points, cameraTransform: observation.cameraTransform, isDemo: true)
            }
            Text(capture.status).font(.caption)
            Button("Stop Capture") { capture.stop() }.disabled(!capture.running).buttonStyle(.bordered)
            Text("2 cm cells limit duplicate points; they do not imply 2 cm accuracy. This prototype uses ARKit poses without drift correction or surface reconstruction. Scan points are kept in memory and cleared on a new scan.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
#endif
