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
