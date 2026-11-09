import SwiftUI
#if os(iOS)
import UIKit

struct ContentView: View {
    @StateObject private var capture = CaptureController()
    @State private var experiment = "Surface detective"
    @Environment(\.scenePhase) private var phase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Experiment", selection: $experiment) {
                        Text("Surface detective").tag("Surface detective")
                        Text("Freeze reality").tag("Freeze reality")
                    }
                    .pickerStyle(.menu)
                    Text(experiment).font(.title2.bold())
                    if experiment == "Freeze reality" {
                        Text("Freeze one depth observation, then explore it in 3D.").font(.subheadline)
                        Button("Freeze Frame") { capture.freeze() }.disabled(!capture.running).buttonStyle(.borderedProminent)
                        NavigationLink("Explore Synthetic Demo") { PointCloudView(cloud: .demo) }
                    }
                    Text("Explore distance and confidence. Tap the preview to inspect a surface patch.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Picker("View", selection: $capture.mode) {
                        ForEach(["RGB", "Depth", "Confidence"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                    preview
                    Text(capture.mode == "Confidence" ? "Black: invalid · Red: low · Yellow: medium · Green: high" : "Depth: black is invalid · blue is near · red reaches the range limit")
                        .font(.caption).foregroundStyle(.secondary)
                    Toggle("Temporally smoothed depth", isOn: $capture.smoothed)
                    HStack {
                        Text("Depth colour range")
                        Slider(value: $capture.range, in: 1...8, step: 0.5)
                        Text("\(capture.range, specifier: "%.1f") m").monospacedDigit()
                    }.font(.caption)
                    Text(capture.patchStatistics).font(.callout).monospacedDigit().frame(maxWidth: .infinity, alignment: .leading)
                    Text("Spatial spread describes variation across this patch, including its shape. Confidence is a sensor category, not an accuracy guarantee.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(capture.status).font(.caption).monospacedDigit()
                    HStack {
                        Button(capture.running ? "Stop" : "Start") { capture.running ? capture.stop() : capture.start() }
                        Button("Save Sample") { capture.save() }.disabled(!capture.running || capture.saving)
                        if !capture.files.isEmpty { ShareLink(items: capture.files) { Text("Share Sample") } }
                    }.buttonStyle(.bordered)
                    if capture.denied {
                        Button("Open Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
                    }
                }.padding()
            }
            .navigationTitle("LiDAR Lab")
            .sheet(item: $capture.frozenCloud) { cloud in
                NavigationStack {
                    PointCloudView(cloud: cloud)
                        .toolbar { Button("Done") { capture.frozenCloud = nil } }
                }
            }
            .onChange(of: phase) { _, value in if value != .active { capture.stop() } }
            .onChange(of: capture.smoothed) { _, _ in capture.resetInspection() }
        }
    }

    private var preview: some View {
        Group {
            if let image = capture.image {
                let ratio = image.size.width / image.size.height
                GeometryReader { geometry in
                    Image(uiImage: image).resizable().interpolation(.none)
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "plus.circle").font(.title).foregroundStyle(.white)
                                .position(x: capture.patch.x * geometry.size.width, y: capture.patch.y * geometry.size.height)
                        }
                        .contentShape(Rectangle())
                        .gesture(SpatialTapGesture().onEnded { value in
                            capture.patch = CGPoint(x: value.location.x / geometry.size.width, y: value.location.y / geometry.size.height)
                            capture.refreshInspection()
                        })
                }.aspectRatio(ratio, contentMode: .fit)
            } else {
                ContentUnavailableView("Sensor Playground", systemImage: "viewfinder", description: Text(capture.status))
                    .frame(minHeight: 240)
            }
        }
        .background(.black.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Sensor preview. Tap a surface to inspect its depth.")
    }
}
#else
struct ContentView: View {
    var body: some View { Text("LiDAR sensor capture requires an iPhone or iPad.") }
}
#endif
