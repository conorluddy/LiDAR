#if os(iOS)
import SwiftUI
import SceneKit
import simd

struct PointCloudView: View {
    let cloud: PointCloud
    var title = "Freeze reality"
    @State private var colouring = "RGB"
    @State private var highConfidenceOnly = false
    @State private var reset = UUID()

    var body: some View {
        VStack(spacing: 12) {
            Text(cloud.isDemo ? "Synthetic demo · no sensor data" : title == "Accumulated scan" ? "Accumulated depth observations" : "Frozen depth observation").font(.headline)
            Picker("Point colour", selection: $colouring) {
                ForEach(["RGB", "Depth", "Confidence"], id: \.self) { Text($0) }
            }.pickerStyle(.segmented)
            CloudSceneView(cloud: cloud, colouring: colouring, highConfidenceOnly: highConfidenceOnly, reset: reset)
                .frame(minHeight: 300).clipShape(RoundedRectangle(cornerRadius: 16))
            Toggle("High-confidence points only", isOn: $highConfidenceOnly)
            Text("\(cloud.points.count.formatted()) captured points · drag to orbit · pinch to zoom · two fingers to pan")
                .font(.caption).foregroundStyle(.secondary)
            Text("The orange marker is the capture camera. Gaps reveal surfaces this observation could not see.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Reset View") { reset = UUID() }.buttonStyle(.bordered)
        }.padding().navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

// SceneKit supplies a compact point renderer and inspection camera for this prototype.
// Acquisition and point data remain independent so the renderer can be replaced.
struct CloudSceneView: UIViewRepresentable {
    let cloud: PointCloud
    let colouring: String
    let highConfidenceOnly: Bool
    let reset: UUID
    var cameraIdentity: UUID? = nil
    var selected: [SpatialPoint] = []
    var onSelect: ((SpatialPoint) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = SCNScene()
        view.backgroundColor = .black
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.defaultCameraController.inertiaEnabled = false
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.selectPoint(_:))))
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.onSelect = onSelect
        if onSelect != nil { context.coordinator.points = cloud.points.filter { !highConfidenceOnly || $0.confidence == 2 } }
        updateMeasurements(in: view)
        let key = "\(cloud.id)-\(colouring)-\(highConfidenceOnly)"
        if context.coordinator.key != key {
            context.coordinator.key = key
            view.scene?.rootNode.childNode(withName: "points", recursively: false)?.removeFromParentNode()
            let points = cloud.points.filter { !highConfidenceOnly || $0.confidence == 2 }
            let vertices = points.map { SCNVector3($0.position.x, $0.position.y, $0.position.z) }
            let colors: [SIMD4<Float>] = points.map { point in
                let color: SIMD3<Float>
                if colouring == "Confidence" {
                    color = point.confidence == 2 ? SIMD3(0.15, 0.9, 0.4) : point.confidence == 1 ? SIMD3(1, 0.8, 0.1) : SIMD3(1, 0.15, 0.2)
                } else if colouring == "Depth" {
                    let t = min(point.depth / 5, 1)
                    color = SIMD3(t, 1 - abs(2 * t - 1), 1 - t)
                } else {
                    color = point.color
                }
                return SIMD4(color.x, color.y, color.z, 1)
            }
            let colorData = colors.withUnsafeBytes { Data($0) }
            let colorSource = SCNGeometrySource(data: colorData, semantic: .color, vectorCount: colors.count, usesFloatComponents: true, componentsPerVector: 4, bytesPerComponent: 4, dataOffset: 0, dataStride: MemoryLayout<SIMD4<Float>>.stride)
            let indices = points.indices.map { UInt32($0) }
            let element = SCNGeometryElement(indices: indices, primitiveType: .point)
            element.pointSize = 4
            element.minimumPointScreenSpaceRadius = 1.5
            element.maximumPointScreenSpaceRadius = 5
            let geometry = SCNGeometry(sources: [SCNGeometrySource(vertices: vertices), colorSource], elements: [element])
            geometry.firstMaterial = SCNMaterial()
            geometry.firstMaterial?.lightingModel = .constant
            let node = SCNNode(geometry: geometry)
            node.name = "points"
            view.scene?.rootNode.addChildNode(node)
        }
        if context.coordinator.cloudID != (cameraIdentity ?? cloud.id) || context.coordinator.reset != reset {
            context.coordinator.cloudID = cameraIdentity ?? cloud.id
            context.coordinator.reset = reset
            view.scene?.rootNode.childNode(withName: "captureCamera", recursively: false)?.removeFromParentNode()
            let marker = SCNNode(geometry: SCNPyramid(width: 0.12, height: 0.16, length: 0.12))
            marker.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
            marker.simdTransform = cloud.cameraTransform
            marker.name = "captureCamera"
            view.scene?.rootNode.addChildNode(marker)
            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.zNear = 0.01
            camera.camera?.zFar = 100
            // Sensor axes are landscape; orient the initial view to the portrait preview.
            camera.simdTransform = cloud.cameraTransform * simd_float4x4(simd_quatf(angle: -.pi / 2, axis: SIMD3(0, 0, 1)))
            view.scene?.rootNode.childNode(withName: "inspectionCamera", recursively: false)?.removeFromParentNode()
            camera.name = "inspectionCamera"
            view.scene?.rootNode.addChildNode(camera)
            view.pointOfView = camera
            let centre = cloud.points.isEmpty ? SIMD3<Float>(0, 0, -1) : cloud.points.reduce(SIMD3<Float>.zero) { $0 + $1.position } / Float(cloud.points.count)
            view.defaultCameraController.target = SCNVector3(centre.x, centre.y, centre.z)
            view.defaultCameraController.clearRoll()
        }
    }

    private func updateMeasurements(in view: SCNView) {
        view.scene?.rootNode.childNode(withName: "measurements", recursively: false)?.removeFromParentNode()
        guard !selected.isEmpty else { return }
        let root = SCNNode()
        root.name = "measurements"
        for (index, point) in selected.enumerated() {
            let marker = SCNNode(geometry: SCNSphere(radius: 0.018))
            marker.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
            marker.geometry?.firstMaterial?.lightingModel = .constant
            marker.simdPosition = point.position
            root.addChildNode(marker)
            let text = SCNText(string: "\(index + 1)", extrusionDepth: 0)
            text.font = .systemFont(ofSize: 1)
            text.firstMaterial?.diffuse.contents = UIColor.white
            let label = SCNNode(geometry: text)
            label.scale = SCNVector3(0.035, 0.035, 0.035)
            label.simdPosition = point.position + SIMD3(0.025, 0.025, 0)
            label.constraints = [SCNBillboardConstraint()]
            root.addChildNode(label)
        }
        if selected.count >= 2 {
            for index in 1..<selected.count {
                let a = selected[index - 1].position
                let b = selected[index].position
                let delta = b - a
                let length = simd_length(delta)
                guard length > 0.0001 else { continue }
                let line = SCNNode(geometry: SCNCylinder(radius: 0.005, height: CGFloat(length)))
                line.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
                line.geometry?.firstMaterial?.lightingModel = .constant
                line.simdPosition = (a + b) / 2
                line.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: delta / length)
                root.addChildNode(line)
            }
        }
        view.scene?.rootNode.addChildNode(root)
    }

    final class Coordinator: NSObject {
        var points: [SpatialPoint] = []
        var onSelect: ((SpatialPoint) -> Void)?

        @objc func selectPoint(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView, let onSelect else { return }
            let tap = gesture.location(in: view)
            var candidates: [(point: SpatialPoint, distance: Float, depth: Float)] = []
            for point in points {
                let screen = view.projectPoint(SCNVector3(point.position.x, point.position.y, point.position.z))
                guard screen.z > 0, screen.z < 1 else { continue }
                let distance = hypot(screen.x - Float(tap.x), screen.y - Float(tap.y))
                if distance <= 18 { candidates.append((point, distance, screen.z)) }
            }
            guard let nearestDistance = candidates.map(\.distance).min() else { return }
            // Prefer the frontmost observation among points with similar screen proximity.
            if let hit = candidates.filter({ $0.distance <= nearestDistance + 3 }).min(by: { $0.depth < $1.depth }) {
                onSelect(hit.point)
            }
        }

        var key = ""
        var cloudID: UUID?
        var reset: UUID?
    }
}
#endif
