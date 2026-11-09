# LiDAR Lab experiments

Live sensor experiments require a LiDAR-equipped iPhone or iPad and camera permission. Simulator builds validate UI and unsupported-hardware behavior only.

## 1. Surface detective

Start capture and switch between RGB, Depth and Confidence. Tap a preview patch to inspect its mean distance, spatial spread, valid samples and confidence counts. The patch follows sensor-image coordinates; previews remain sensor-portrait oriented when rotating the device. The colour-range slider affects visualization only. Compare scene depth and temporally smoothed depth with the toggle.

Try a matte wall, box, black fabric, glass and polished metal at different distances and angles. Spatial spread includes actual surface geometry; it is not temporal noise or a calibrated error estimate. Save Sample exports the selected depth stream, confidence, RGB and camera metadata locally.

Hardware checks: permission denial/recovery, start/stop/background, patch alignment, invalid pixels, confidence colours, stream toggle and sample export.
