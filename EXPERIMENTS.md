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

## 5. Paint the room

Choose Paint the room and Start New Scan. Walk slowly around a static scene. A world-space point cloud builds at up to three observations per second; drag to orbit and pinch to zoom while it grows. Pause/Resume Painting leaves tracking running so observations retain the same coordinate system. Inspect Scan stops capture and opens the larger viewer. Clear Scan discards retained points; if painting is active it begins filling again. Start New Scan resets tracking and all accumulated geometry.

Accumulation samples every fourth depth pixel, filters new observations by selected confidence and range, and retains one observed point per 2 cm cell (preferring higher confidence). The cap is 80,000 occupied cells. These are resource controls, not an accuracy guarantee. This is pose-based accumulation without loop closure, moving-object removal, TSDF fusion or reconstructed mesh output. Data is currently in memory only. Thermal pressure pauses painting; backgrounding stops capture. CPU point conversion and accumulation run off the main actor, with one accumulation observation in flight. Generation checks discard results invalidated by pause/clear/restart.

Synthetic Accumulation Demo merges two offset artificial observations through the same voxel grid. It validates accumulation display without making claims about live registration.

Geometry validation: `swiftc Lidar/SpatialPoint.swift Lidar/SpatialProjection.swift Lidar/VoxelGrid.swift Validation/SpatialCaptureChecks.swift -o /tmp/lidar-capture-checks && /tmp/lidar-capture-checks`.

Hardware checks: walk around a box and room corner; compare coverage from successive viewpoints; pause/move/resume; clear/restart while processing; tracking loss; confidence/range filtering; point-budget limit; background and thermal behavior. Inspect drift and RGB alignment against a static reference.

## Validation performed (2026-11-09)

- Each experiment compiled successfully for generic iOS Simulator (arm64 and x86_64).
- Final suite compiled for generic physical iOS with signing disabled.
- iPhone 18 Pro / iOS 27 simulator: inspected Surface detective layout and unsupported-depth message; exercised synthetic cloud colouring/filter/orbit/reset; dropped a ball onto the synthetic floor; selected two synthetic points and verified numbered markers, connecting line and a distance result; displayed two merged synthetic observations (12,850 retained points).
- Standalone Swift geometry checks passed for distance, plane tilt, degenerate selections, scaled intrinsics, axis conventions, world transforms, voxel deduplication, confidence replacement, negative coordinates and capacity limits.
- Live sensor quality, RGB/depth alignment, registration drift, real room collisions and sustained performance remain physical-device checks. Synthetic demos do not validate these.
