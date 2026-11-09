#if os(iOS)
import SwiftUI
import SceneKit
import simd

struct PointCloudView: View {
    let cloud: PointCloud
    @State private var colouring = "RGB"
    @State private var highConfidenceOnly = false
    @State private var reset = UUID()

    var body: some View {
        VStack(spacing: 12) {
            Text(cloud.isDemo ? "Synthetic demo · no sensor data" : "Frozen depth observation").font(.headline)
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
        }.padding().navigationTitle("Freeze reality").navigationBarTitleDisplayMode(.inline)
    }
}

// SceneKit supplies a compact point renderer and inspection camera for this prototype.
// Acquisition and point data remain independent so the renderer can be replaced.
struct CloudSceneView: UIViewRepresentable {
    let cloud: PointCloud
    let colouring: String
    let highConfidenceOnly: Bool
    let reset: UUID

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = SCNScene()
        view.backgroundColor = .black
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.defaultCameraController.inertiaEnabled = false
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
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
        if context.coordinator.cloudID != cloud.id || context.coordinator.reset != reset {
            context.coordinator.cloudID = cloud.id
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

    final class Coordinator {
        var key = ""
        var cloudID: UUID?
        var reset: UUID?
    }
}
#endif
