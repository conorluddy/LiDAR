#if os(iOS)
import SwiftUI

struct TapeMeasureView: View {
    let cloud: PointCloud
    @State private var tool = "Distance"
    @State private var selected: [SpatialPoint] = []
    @State private var reset = UUID()

    private var requiredPoints: Int { tool == "Distance" ? 2 : 3 }

    private var result: String {
        guard selected.count == requiredPoints else { return "Tap \(requiredPoints - selected.count) more surface point(s)." }
        if tool == "Distance" {
            let distance = SpatialMeasurement.distance(selected[0].position, selected[1].position)
            return String(format: "Approximate distance: %.2f m (%.1f cm)", distance, distance * 100)
        }
        guard let tilt = SpatialMeasurement.tilt(selected[0].position, selected[1].position, selected[2].position) else {
            return "Points are too close or nearly collinear. Choose a wider triangle."
        }
        return String(format: "Approximate plane tilt: %.1f° from horizontal", tilt)
    }

    var body: some View {
        VStack(spacing: 12) {
            if cloud.isDemo { Text("Synthetic demo · no sensor data").font(.headline) }
            Picker("Measurement", selection: $tool) {
                Text("Distance").tag("Distance")
                Text("Plane tilt").tag("Plane tilt")
            }.pickerStyle(.segmented).onChange(of: tool) { _, _ in selected = [] }
            CloudSceneView(cloud: cloud, colouring: "RGB", highConfidenceOnly: false, reset: reset, selected: selected) { point in
                if selected.count == requiredPoints { selected = [] }
                selected.append(point)
            }
            .frame(minHeight: 300).clipShape(RoundedRectangle(cornerRadius: 16))
            Text(result).font(.headline).monospacedDigit().accessibilityIdentifier("measurementResult")
            Text("\(selected.count)/\(requiredPoints) points · tap near a visible point · drag to orbit · pinch to zoom")
                .font(.caption).foregroundStyle(.secondary)
            if selected.contains(where: { $0.confidence < 2 }) {
                Label("Selection includes lower-confidence depth.", systemImage: "exclamationmark.triangle").font(.caption)
            }
            Text("Measurements are approximate. Check against a physical reference. Plane tilt uses three points and assumes they belong to one flat surface; choose a wide triangle. 0° is horizontal, 90° is vertical.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Clear Points") { selected = [] }
                Button("Reset View") { reset = UUID() }
            }.buttonStyle(.bordered)
        }.padding().navigationTitle("Digital tape measure").navigationBarTitleDisplayMode(.inline)
    }
}
#endif
