# LiDAR Lab experiments

Live sensor experiments require a LiDAR-equipped iPhone or iPad and camera permission. Simulator builds validate UI and unsupported-hardware behavior only.

## 1. Surface detective

Start capture and switch between RGB, Depth and Confidence. Tap a preview patch to inspect its mean distance, spatial spread, valid samples and confidence counts. The patch follows sensor-image coordinates; previews remain sensor-portrait oriented when rotating the device. The colour-range slider affects visualization only. Compare scene depth and temporally smoothed depth with the toggle.

Try a matte wall, box, black fabric, glass and polished metal at different distances and angles. Spatial spread includes actual surface geometry; it is not temporal noise or a calibrated error estimate. Save Sample exports the selected depth stream, confidence, RGB and camera metadata locally.

Hardware checks: permission denial/recovery, start/stop/background, patch alignment, invalid pixels, confidence colours, stream toggle and sample export.

## 2. Freeze reality

Choose Freeze reality, Start, and Freeze Frame. Capture pauses while inspecting a coloured point cloud. Drag to orbit, pinch to zoom and use two fingers to pan. Switch RGB/depth/confidence colouring, filter to high confidence, and Reset View. The orange marker indicates the observation's camera pose. Only one visible layer is captured; holes and unseen backs are expected. Points outside 0.1–8 m are discarded and every second depth pixel is sampled.

Explore Synthetic Demo works without LiDAR and is explicitly labelled synthetic. This checks the renderer and controls, not sensor accuracy. SceneKit is used as a replaceable prototype renderer; it is deprecated by Apple but remains available in the target SDK.

Hardware checks: compare RGB alignment at object edges, inspect a known-size box, rotate around holes, verify confidence filtering and repeat freeze/restart/background.

## 3. Room playground

Choose Room playground and Start Room Scan. Sweep the camera over the floor and nearby furniture; the mesh overlay shows reconstructed coverage. Aim the crosshair at a scanned surface within 5 m, then Drop Ball. Balls use RealityKit gravity and collision against ARKit's reconstructed surroundings. Clear Balls removes them; the oldest ball is removed after 20. Stop/background pauses capture and physics; restarting resets the room.

Synthetic Physics Demo creates a labelled, artificial floor and camera without AR capture. It verifies rendering and ball physics on the simulator. It does not validate live mesh collisions.

Hardware checks: floor/table collisions, gaps and changing meshes, mesh toggle, tracking loss, interruption, start/stop/background, and switching experiments without competing camera sessions.

## 4. Digital tape measure

Choose Digital tape measure, Start and Freeze Frame. In the frozen cloud, select Distance (two taps) or Plane tilt (three taps). Numbered yellow markers and lines show the selected observations. A further selection starts a new measurement; Clear Points resets it. Orbit/zoom before selecting if surfaces overlap. Picking uses an 18-point screen tolerance and prefers the frontmost nearby observation; inspect marker placement carefully.

Plane tilt is a three-point estimate relative to gravity, not a fitted surface normal. It rejects baselines under 5 cm and nearly collinear selections. Confidence warnings identify selected depth below the high category. Compare measurements with a physical ruler or level; do not infer accuracy from displayed decimal places.

Geometry validation: `swiftc Lidar/SpatialMeasurement.swift Validation/SpatialMeasurementChecks.swift -o /tmp/lidar-measurement-checks && /tmp/lidar-measurement-checks`.

Hardware checks: known-size box, repeated endpoint selection, tilted board against a level, foreground/background selection, orbit and clear/reset. Synthetic Demo verifies picking and annotations without validating sensor measurements.
