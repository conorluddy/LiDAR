#if os(iOS)
import SwiftUI
import Combine
import ARKit
import AVFoundation
import CoreImage
import UIKit
import simd

@MainActor final class CaptureController: NSObject, ObservableObject, ARSessionDelegate {
    @Published var mode = "RGB"
    @Published var smoothed = false
    @Published var range = 5.0
    @Published var patch = CGPoint(x: 0.5, y: 0.5)
    @Published var patchStatistics = "Start capture to inspect a patch."
    private var inspection: DepthInspection?
    private var startRequested = false

    func resetInspection() {
        inspection = nil
        patchStatistics = "Waiting for the selected depth stream."
    }

    func refreshInspection() {
        patchStatistics = inspection?.statistics(at: patch) ?? "No depth available."
    }
    @Published var image: UIImage?
    @Published var status = "Tap Start to inspect LiDAR sensors."
    @Published var running = false
    @Published var denied = false
    @Published var saving = false
    @Published var files: [URL] = []
    @Published var frozenCloud: PointCloud?

    @Published var freezing = false
    @Published var painting = false
    @Published var scanCloud: PointCloud?
    @Published var scanFrames = 0
    @Published var scanMessage = "Start a new scan to accumulate surfaces."
    @Published var minimumConfidence = 2
    @Published var maximumDistance = 5.0
    private(set) var scanViewID = UUID()
    private var grid = VoxelGrid()
    private var generation = UUID()
    private var processing = false
    private var lastAccumulation = 0.0
    private var firstCameraTransform: simd_float4x4?

    func freeze() {
        guard running, !freezing, let frame = session.currentFrame,
              let depth = (smoothed ? frame.smoothedSceneDepth : frame.sceneDepth) else {
            status = "Start capture and wait for depth before freezing."
            return
        }
        stop()
        freezing = true
        let token = generation
        Task {
            let cloud = await PointCloud.capture(frame: frame, depth: depth, context: context)
            guard generation == token else { return }
            freezing = false
            frozenCloud = cloud
            status = "Frozen observation ready. Restart capture for another view."
        }
    }

    func clearScan() {
        generation = UUID()
        grid = VoxelGrid()
        scanCloud = nil
        scanFrames = 0
        firstCameraTransform = nil
        scanViewID = UUID()
        scanMessage = "Scan cleared."
    }

    func newScan() {
        stop()
        clearScan()
        start(paint: true)
    }

    func togglePainting() {
        guard running, !grid.isFull else { return }
        painting.toggle()
        // Discard an in-flight observation on pause, retaining the current coordinate system.
        generation = UUID()
        scanMessage = painting ? "Painting surfaces…" : "Accumulation paused; tracking remains active."
    }

    func inspectScan() {
        guard let cloud = scanCloud else { return }
        stop()
        frozenCloud = cloud
    }

    private func accumulate(_ frame: ARFrame) {
        guard painting, !processing, frame.timestamp - lastAccumulation >= 1.0 / 3 else { return }
        guard case .normal = frame.camera.trackingState else {
            scanMessage = "Accumulation paused: wait for normal tracking."
            return
        }
        guard ProcessInfo.processInfo.thermalState != .serious,
              ProcessInfo.processInfo.thermalState != .critical else {
            painting = false
            scanMessage = "Accumulation paused to cool the device. Resume when it has cooled."
            return
        }
        guard let depth = (smoothed ? frame.smoothedSceneDepth : frame.sceneDepth) else { return }
        lastAccumulation = frame.timestamp
        processing = true
        let token = generation
        let inputGrid = grid
        let confidence = UInt8(minimumConfidence)
        let distance = Float(maximumDistance)
        let transform = frame.camera.transform
        Task {
            let output = await PointCloud.accumulate(frame: frame, depth: depth, context: context, grid: inputGrid, minimumConfidence: confidence, maximumDistance: distance)
            processing = false
            guard generation == token else { return }
            grid = output
            if firstCameraTransform == nil { firstCameraTransform = transform }
            scanFrames += 1
            scanCloud = PointCloud(points: output.points, cameraTransform: firstCameraTransform ?? transform, isDemo: false)
            if output.isFull {
                painting = false
                scanMessage = "80,000-point budget reached. Inspect this scan or start a new one."
            } else {
                scanMessage = "\(output.points.count.formatted()) occupied cells · \(scanFrames) observations · 2 cm cells"
            }
        }
    }

    private let session = ARSession()
    private let context = CIContext()
    private var lastPreview = 0.0
    private var lastStats = 0.0
    private var cameraCount = 0
    private var depthCount = 0
    func start(paint: Bool = false) {
        guard !running, !startRequested, !freezing else { return }
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else { status = "Scene depth requires a LiDAR-equipped iPhone or iPad. Simulator capture is unavailable."; return }
        startRequested = true
        let requestGeneration = generation
        AVCaptureDevice.requestAccess(for: .video) { allowed in
            Task { @MainActor in
                guard self.startRequested, self.generation == requestGeneration else { return }
                self.startRequested = false
                guard allowed else { self.denied = true; self.status = "Camera access is required."; return }
                self.denied = false
                let configuration = ARWorldTrackingConfiguration()
                configuration.frameSemantics = .sceneDepth
                if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                    configuration.frameSemantics.insert(.smoothedSceneDepth)
                }
                self.lastPreview = 0
                self.image = nil
                self.resetInspection()
                self.session.delegate = self
                self.session.delegateQueue = .main
                self.lastStats = 0; self.cameraCount = 0; self.depthCount = 0
                self.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                self.running = true
                self.painting = paint
                self.lastAccumulation = 0
            }
        }
    }
    func stop() {
        startRequested = false
        session.pause()
        running = false
        painting = false
        freezing = false
        generation = UUID()
        status = "Stopped. Tap Start to restart."
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard running else { return }
        accumulate(frame)
        cameraCount += 1
        if frame.sceneDepth != nil { depthCount += 1 }
        if lastStats == 0 { lastStats = frame.timestamp }
        if frame.timestamp - lastStats >= 0.5 {
            let elapsed = frame.timestamp - lastStats
            status = String(format: "Camera %.1f / depth %.1f fps\n", Double(cameraCount)/elapsed, Double(depthCount)/elapsed) + "Tracking: \(frame.camera.trackingState)\nThermal: \(ProcessInfo.processInfo.thermalState.rawValue)"
            cameraCount = 0; depthCount = 0; lastStats = frame.timestamp
        }
        guard frame.timestamp - lastPreview >= 1 / 15 else { return }
        lastPreview = frame.timestamp
        let selectedDepth = smoothed ? frame.smoothedSceneDepth : frame.sceneDepth
        if let selectedDepth {
            inspection = DepthInspection(selectedDepth)
            refreshInspection()
        } else {
            resetInspection()
        }
        if mode == "RGB" {
            let ci = CIImage(cvPixelBuffer: frame.capturedImage)
            if let cg = context.createCGImage(ci, from: ci.extent) {
                image = UIImage(cgImage: cg, scale: 1, orientation: .right)
            }
        } else {
            image = inspection?.image(confidenceOnly: mode == "Confidence", limit: Float(range))
        }
    }
    func session(_ session: ARSession, didFailWithError error: Error) { stop(); status = error.localizedDescription }
    func sessionWasInterrupted(_ session: ARSession) { stop(); status = "Session interrupted. Tap Start when ready." }
    func save() {
        guard let frame = session.currentFrame, let depth = (smoothed ? frame.smoothedSceneDepth : frame.sceneDepth), let confidence = depth.confidenceMap else { status = "Waiting for a depth frame."; return }
        saving = true
        defer { saving = false }
        do {
            let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            func writeBuffer(_ buffer: CVPixelBuffer, bytes: Int, name: String) throws {
                CVPixelBufferLockBaseAddress(buffer, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
                var data = Data()
                for row in 0..<CVPixelBufferGetHeight(buffer) {
                    data.append(CVPixelBufferGetBaseAddress(buffer)!.advanced(by: row * CVPixelBufferGetBytesPerRow(buffer)).assumingMemoryBound(to: UInt8.self), count: CVPixelBufferGetWidth(buffer) * bytes)
                }
                try data.write(to: folder.appendingPathComponent(name))
            }
            try writeBuffer(depth.depthMap, bytes: 4, name: "depth.f32")
            try writeBuffer(confidence, bytes: 1, name: "confidence.u8")
            let rgb = CIImage(cvPixelBuffer: frame.capturedImage)
            if let cg = context.createCGImage(rgb, from: rgb.extent) { try UIImage(cgImage: cg).pngData()?.write(to: folder.appendingPathComponent("rgb.png")) }
            let metadata: [String: Any] = ["version": 1, "depthStream": smoothed ? "smoothedSceneDepth" : "sceneDepth", "rgbWidth": CVPixelBufferGetWidth(frame.capturedImage), "rgbHeight": CVPixelBufferGetHeight(frame.capturedImage), "timestamp": frame.timestamp, "depthWidth": CVPixelBufferGetWidth(depth.depthMap), "depthHeight": CVPixelBufferGetHeight(depth.depthMap), "units": "metres", "matrixOrdering": "column-major", "cameraTransform": (0..<4).flatMap { column in (0..<4).map { frame.camera.transform[column][$0] } }, "intrinsics": (0..<3).flatMap { column in (0..<3).map { frame.camera.intrinsics[column][$0] } }]
            try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted).write(to: folder.appendingPathComponent("metadata.json"))
            files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            status = "Sample saved. Use Share Sample to inspect files."
        } catch { status = "Save failed: \(error.localizedDescription)" }
    }
}
#endif
