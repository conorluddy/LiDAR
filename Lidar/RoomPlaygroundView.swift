#if os(iOS)
import SwiftUI
import ARKit
import RealityKit
import AVFoundation
import Combine

struct RoomPlaygroundView: View {
    @StateObject private var room = RoomPlaygroundController()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        VStack(spacing: 16) {
            Text("Scan the floor and furniture, aim at a scanned surface, then drop a ball.")
                .font(.subheadline).foregroundStyle(.secondary)
            RoomARView(controller: room)
                .overlay { Image(systemName: "plus").foregroundStyle(.white).allowsHitTesting(false) }
                .frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 16))
            if room.demo { Text("Synthetic physics demo · no room capture").font(.headline) }
            Text(room.status).font(.caption).monospacedDigit()
            Toggle("Show reconstructed mesh", isOn: $room.showMesh)
                .onChange(of: room.showMesh) { _, _ in room.updateMeshVisibility() }
                .disabled(room.demo)
            HStack {
                Button(room.running ? "Stop" : "Start Room Scan") { room.running ? room.stop() : room.start() }
                Button("Drop Ball") { room.dropBall() }.disabled(!room.running)
            }.buttonStyle(.bordered)
            HStack {
                Button("Clear Balls") { room.clearBalls() }
                Button("Synthetic Physics Demo") { room.startDemo() }
            }.buttonStyle(.bordered)
            if room.denied {
                Button("Open Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            }
            Text("Move slowly to build coverage. Mesh geometry updates during capture, so collisions may shift or have gaps. Up to 20 balls are retained.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .onDisappear { room.stop() }
        .onChange(of: phase) { _, value in if value != .active { room.stop() } }
    }
}

struct RoomARView: UIViewRepresentable {
    let controller: RoomPlaygroundController
    func makeUIView(context: Context) -> ARView { controller.view }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

@MainActor
final class RoomPlaygroundController: NSObject, ObservableObject, ARSessionDelegate {
    let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
    @Published var status = "Start a LiDAR room scan, or try the synthetic physics demo."
    @Published var running = false
    @Published var demo = false
    @Published var showMesh = true
    @Published var denied = false
    private var requested = false
    private var requestGeneration = UUID()
    private var balls: [AnchorEntity] = []
    private var meshIDs: Set<UUID> = []
    private var lastStats = 0.0

    func start() {
        guard !running, !requested else { return }
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            status = "Room reconstruction requires a LiDAR-equipped iPhone or iPad. Try the synthetic demo here."
            return
        }
        requested = true
        let token = requestGeneration
        AVCaptureDevice.requestAccess(for: .video) { allowed in
            Task { @MainActor in
                guard self.requested, self.requestGeneration == token else { return }
                self.requested = false
                guard allowed else { self.denied = true; self.status = "Camera access is required. Enable it in Settings."; return }
                self.denied = false
                self.resetScene()
                self.demo = false
                self.view.cameraMode = .ar
                self.view.session.delegate = self
                self.view.session.delegateQueue = .main
                self.view.environment.sceneUnderstanding.options = [.physics, .collision, .occlusion]
                self.updateMeshVisibility()
                let config = ARWorldTrackingConfiguration()
                config.sceneReconstruction = .mesh
                config.planeDetection = [.horizontal, .vertical]
                self.view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
                self.running = true
                self.status = "Move slowly to reconstruct nearby surfaces."
            }
        }
    }

    func stop() {
        requested = false
        requestGeneration = UUID()
        view.session.pause()
        for anchor in balls {
            for case let ball as ModelEntity in anchor.children { ball.physicsBody?.mode = .static }
        }
        running = false
        status = "Stopped. Restart to begin a fresh room, or try the synthetic demo."
    }

    private func resetScene() {
        view.session.pause()
        view.scene.anchors.removeAll()
        balls.removeAll()
        meshIDs.removeAll()
        lastStats = 0
    }

    func updateMeshVisibility() {
        view.debugOptions = showMesh && !demo ? [.showSceneUnderstanding] : []
    }

    func startDemo() {
        requested = false
        requestGeneration = UUID()
        resetScene()
        demo = true
        running = true
        view.cameraMode = .nonAR
        view.environment.sceneUnderstanding.options = []
        updateMeshVisibility()
        let anchor = AnchorEntity(world: .zero)
        let floor = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(2.5, 0.08, 2.5)), materials: [SimpleMaterial(color: .darkGray, isMetallic: false)])
        floor.position = SIMD3(0, -0.2, -1)
        floor.generateCollisionShapes(recursive: false)
        floor.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .generate(friction: 0.6, restitution: 0.65), mode: .static)
        anchor.addChild(floor)
        let camera = PerspectiveCamera()
        camera.look(at: SIMD3(0, 0, -1), from: SIMD3(0, 1.3, 1.8), relativeTo: nil)
        anchor.addChild(camera)
        view.scene.addAnchor(anchor)
        status = "Synthetic floor ready. Drop a ball to test gravity and collisions."
    }

    func dropBall() {
        guard running else { return }
        let position: SIMD3<Float>
        if demo {
            position = SIMD3(Float(balls.count % 3 - 1) * 0.18, 0.65, -1)
        } else {
            guard !meshIDs.isEmpty, let frame = view.session.currentFrame,
                  case .normal = frame.camera.trackingState else {
                status = "Wait for normal tracking and scan a surface first."
                return
            }
            let transform = view.cameraTransform
            let forward = -SIMD3(transform.matrix.columns.2.x, transform.matrix.columns.2.y, transform.matrix.columns.2.z)
            guard let hit = view.scene.raycast(origin: transform.translation, direction: forward, length: 5, query: .nearest, mask: .sceneUnderstanding).first else {
                status = "Aim the crosshair at a scanned surface within 5 m."
                return
            }
            position = hit.position + hit.normal * 0.1 + SIMD3(0, 0.25, 0)
        }
        if balls.count >= 20 { view.scene.removeAnchor(balls.removeFirst()) }
        let ball = ModelEntity(mesh: .generateSphere(radius: 0.06), materials: [SimpleMaterial(color: .systemOrange, isMetallic: true)])
        ball.generateCollisionShapes(recursive: false)
        ball.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .generate(friction: 0.5, restitution: 0.75), mode: .dynamic)
        let anchor = AnchorEntity(world: position)
        anchor.addChild(ball)
        view.scene.addAnchor(anchor)
        balls.append(anchor)
        status = "\(demo ? "Synthetic demo" : "Room scan") · \(balls.count) balls"
    }

    func clearBalls() {
        balls.forEach { view.scene.removeAnchor($0) }
        balls.removeAll()
        status = demo ? "Synthetic floor ready. Drop a ball to test gravity and collisions." : "Balls cleared. Aim at a scanned surface to drop another."
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors where anchor is ARMeshAnchor { meshIDs.insert(anchor.identifier) }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors { meshIDs.remove(anchor.identifier) }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard running, !demo, frame.timestamp - lastStats > 0.5 else { return }
        lastStats = frame.timestamp
        status = "\(meshIDs.count) mesh chunks · \(balls.count) balls · tracking: \(frame.camera.trackingState)"
    }

    func session(_ session: ARSession, didFailWithError error: Error) { stop(); status = error.localizedDescription }
    func sessionWasInterrupted(_ session: ARSession) { stop(); status = "Session interrupted. Restart when ready." }
}
#endif
