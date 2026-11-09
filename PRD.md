# Spatial Capture Platform — Product Requirements Document

**Status:** Concept / Exploration  
**Platform:** iOS, initially LiDAR-equipped iPhone Pro devices  
**Development:** Native Swift / SwiftUI  
**Philosophy:** Local-first, modular, experimental, progressively extensible

## 1. Product Vision

Build a powerful, flexible spatial capture platform that converts the physical world into useful digital information.

Initially, the application will provide accessible LiDAR-based 3D scanning, visualisation, measurement and export.

Over time, it will develop into a general-purpose spatial intelligence toolkit supporting multiple capture techniques, advanced reconstruction, machine learning, geometric analysis and specialist workflows.

The product should be valuable as a standalone scanner while functioning as a foundation for future applications.

**Core proposition:**

*Capture reality once. Extract more value from it over time.*

## 2. Strategic Objectives

1. Build a reusable native iOS sensor capture and processing framework.
2. Produce useful 3D geometry from commodity iPhone sensors.
3. Improve the quality and reliability of scans through intelligent processing.
4. Preserve sufficient source information to permit future reprocessing.
5. Support multiple scanning applications without duplicating core infrastructure.
6. Enable experimentation with Core ML and emerging spatial-computing capabilities.
7. Identify commercially attractive specialist workflows through experimentation rather than assumptions.

### Non-goals

- Competing immediately with established scanning applications on feature count.
- Building a professional surveying or metrology system.
- Implementing a custom photogrammetry engine from scratch.
- Introducing mandatory cloud processing or user accounts.
- Promising millimetre-level accuracy from consumer LiDAR.
- Committing to a single vertical before the underlying technology has been explored.

## 3. Target Users

### Initial: Makers and Technical Hobbyists

People scanning physical objects for measurement, modelling, fabrication, repair or reference.

Example: scanning a curved vehicle body panel to design a 3D-printed attachment.

### Secondary: Designers and Creators

People capturing objects, spaces, textures or environments for use in Blender, CAD software, 3D visualisation and interactive applications.

### Exploratory: Specialist Users

Potential future audiences include fitness enthusiasts, automotive hobbyists, property professionals, architects, engineers and creators working with spatial data.

These are research directions rather than committed markets.

## 4. Product Architecture

The platform will be divided into six conceptual layers.

### Layer 1 — Sensor Acquisition

A common interface for collecting information from supported device sensors.

Potential inputs:

- Rear camera RGB imagery
- LiDAR depth maps
- Depth confidence maps
- Camera intrinsics and extrinsics
- Device pose and orientation
- Accelerometer and gyroscope data
- ARKit tracking and mesh information
- Timestamps and relevant capture metadata

Different sensors may operate at different update rates.

The acquisition system must preserve timestamps and capture relationships rather than assume perfectly synchronised input.

### Layer 2 — Capture Orchestration

Responsible for managing scanning sessions and sensor availability.

Responsibilities:

- Scan lifecycle and state
- Sensor configuration
- Frame collection and sampling
- Data buffering
- Capture quality monitoring
- Device performance monitoring
- Session recording and recovery
- Live preview configuration

Support multiple capture modes through a shared interface.

### Layer 3 — Spatial Data Processing

A configurable processing pipeline transforming sensor observations into spatial representations.

Potential operations:

- Depth confidence filtering
- Outlier rejection
- Multi-frame accumulation
- Temporal filtering
- Spatial smoothing
- Coordinate transformation
- Point-cloud registration and merging
- Surface reconstruction
- Hole identification and candidate filling
- Mesh simplification
- Normal estimation
- Texture projection
- Geometric cleanup

Processing should distinguish original measurements from inferred or generated geometry.

### Layer 4 — Spatial Intelligence

Optional ML-driven capabilities built on top of the capture and reconstruction system.

Candidates:

- Scan-quality evaluation
- Missing-coverage detection
- Material or surface classification
- Object segmentation
- Scene interpretation
- Geometry feature recognition
- Adaptive processing recommendations
- Guided rescanning
- Learned depth refinement

Models should be versioned and independently replaceable.

### Layer 5 — Representation and Analysis

Expose captured spatial data in forms useful to different applications.

Representations:

- Depth maps
- Point clouds
- Polygon meshes
- Textured meshes
- Scene graphs
- Parametric objects
- Measurements and annotations
- Surface cross-sections

Analysis tools may include distance, angle, area, volume and geometric comparison.

### Layer 6 — Applications and Outputs

Provide user-facing workflows based on the shared capture and processing foundation.

Applications may include:

- General 3D scanning
- Object scanning
- Room scanning
- Surface measurement
- Fabrication reference capture
- Vehicle scanning
- Body-shape tracking
- Environmental reconstruction

Output adapters should support relevant standard formats as their respective representations mature.

## 5. Initial Product — V0

The first version should validate the technical foundation rather than attempt to deliver a complete commercial scanner.

### Capture

- Launch a live AR camera session.
- Read supported depth information.
- Visualise depth as a point cloud.
- Capture camera pose and transforms.
- Record depth confidence.
- Accumulate spatial observations over time.
- Save and reopen scanning sessions.

### Visualisation

- Real-time point-cloud rendering.
- Orbit, pan and zoom.
- Toggle colour, depth and confidence views.
- Display basic capture statistics.
- Identify potentially unreliable scan regions.

### Processing

- Basic low-confidence point rejection.
- Configurable distance limits.
- Basic noise filtering.
- Point-cloud downsampling.
- Simple multi-frame fusion.

### Measurement

- Select points in the reconstructed scene.
- Measure approximate distances.
- Display dimensions in metric units.
- Clearly communicate measurement limitations.

### Export

- Export point clouds, initially PLY.
- Export metadata and session information.
- Share files through the native iOS share sheet.

### Storage

- Local-first session persistence.
- No account required.
- No mandatory backend.
- Reopen captured data for inspection and reprocessing.

**V0 success means we can reliably capture, inspect, save, reopen and export useful spatial data.**

It does not require polished meshes, photorealistic textures or commercial-grade measurement accuracy.

## 6. Future Capture Modes

Capture modes will share common infrastructure where feasible, but may require different ARKit sessions or processing pipelines.

### Free Scan

General-purpose scanning of surfaces, objects and environments.

### Object Scan

A guided workflow for capturing an isolated object from multiple perspectives, potentially integrating RealityKit Object Capture.

### Room Scan

Integration with RoomPlan to produce semantically structured interiors.

### Surface Scan

Focus on capturing and measuring a specific physical surface.

Potentially useful for fabrication, repair and fitment.

### Precision Reference

A guided mode prioritising reliable measurements and known scale over visual appearance.

May incorporate calibration objects or manually entered reference dimensions.

### Experimental Capture

A developer-oriented mode exposing sensor streams, confidence information, diagnostic overlays and alternative processing algorithms.

## 7. Intelligent Capture Quality

A major product opportunity is helping users produce better scans before they finish capturing.

Potential feedback:

- Insufficient surface coverage
- Low depth confidence
- Excessive camera motion
- Tracking degradation
- Poor capture distance
- Reflective or otherwise problematic surfaces
- Missing viewing angles
- Conflicting measurements

Visualise capture reliability using overlays or heatmaps.

Where possible, suggest specific corrective actions.

Example: "Move closer and scan this edge again."

The objective is not simply to display sensor confidence, but to reduce the frequency of unusable scans.

## 8. Data Model and Session Format

Each capture should preserve enough information to support future improvements in reconstruction and analysis.

Conceptual entities:

**ScanSession**
- Identifier
- Capture mode
- Device and sensor capabilities
- Creation date
- Session configuration
- Processing history
- Derived representations

**CaptureFrame**
- Timestamp
- Camera intrinsics
- Camera pose
- RGB reference
- Depth reference
- Confidence reference
- Tracking state

**SpatialArtifact**
- Artifact type
- Source session
- Processing parameters
- Algorithm version
- File reference
- Units and coordinate conventions
- Quality metadata

**Measurement**
- Measurement type
- Geometry references
- Value and unit
- Confidence or uncertainty where available

Use a versioned session manifest and independently stored binary data.

Avoid repeatedly serialising large buffers into SwiftData.

## 9. Technical Approach

### Native Frameworks

- Swift / SwiftUI for application structure
- ARKit for tracking and depth acquisition
- RealityKit and/or Metal for visualisation
- RoomPlan for structured interior capture
- RealityKit Object Capture for supported photogrammetry workflows
- Core ML and Vision for future intelligence
- Core Motion where additional motion data is useful

### Internal Modules

- SensorKit (internal working name)
- CaptureEngine
- SpatialProcessing
- SpatialRendering
- SpatialStorage
- SpatialAnalysis
- ScanExport
- CaptureExperiments

Module boundaries should permit later reuse in other applications.

### Engineering Principles

- Prefer native device capabilities before custom replacements.
- Separate acquisition from processing and presentation.
- Retain source observations where practical.
- Permit deterministic offline reprocessing.
- Keep heavy processing asynchronous.
- Measure memory usage, power consumption and thermal behaviour.
- Provide clear fallbacks for unsupported device capabilities.
- Version processing algorithms and output formats.
- Benchmark improvements against repeatable reference scans.

## 10. Development Roadmap

### Phase 0 — Sensor Playground

Create a developer-focused experimental environment.

- Inspect sensor capabilities.
- Read and visualise LiDAR depth.
- Capture RGB and camera pose.
- Display confidence maps.
- Record sample frames.
- Investigate frame rates and device performance.

**Exit criterion:** Reliable access to useful, documented sensor observations.

### Phase 1 — Foundational Scanner

- Multi-frame accumulation.
- Basic point-cloud fusion.
- Save/load sessions.
- Point-cloud navigation.
- Basic measurements.
- PLY export.

**Exit criterion:** Complete local scanning workflow.

### Phase 2 — Capture Quality

- Coverage visualisation.
- Depth confidence filtering.
- Outlier detection.
- Capture guidance.
- Quality comparisons against baseline scans.
- Configurable processing presets.

**Exit criterion:** Measurable improvement in scan reliability.

### Phase 3 — Reconstruction

- Surface reconstruction.
- Mesh cleanup.
- Texture generation.
- Object isolation.
- Improved export compatibility.
- Optional photogrammetry integration.

**Exit criterion:** Useful geometry for established 3D workflows.

### Phase 4 — Specialist Tools

Explore one or more focused use cases:

- Fabrication measurement
- Room or property capture
- Automotive surface references
- Object digitisation
- Body-shape tracking
- Environmental mapping

Prioritise based on demonstrated quality and user demand.

### Phase 5 — Spatial Intelligence

- Learned scan-quality scoring.
- Intelligent rescanning.
- Surface and object recognition.
- Automated feature extraction.
- Geometry interpretation.
- New hardware and sensor integrations.

This phase can evolve continuously rather than waiting for all preceding phases to finish.

## 11. Validation Strategy

Maintain a small physical benchmark collection to test capture and reconstruction quality.

Suggested test subjects:

1. A known-size box or calibration object.
2. A curved plastic or metal vehicle component.
3. A textured household object.
4. A dark or reflective surface.
5. A small room or indoor environment.

Record known dimensions and repeat scans under controlled conditions.

Evaluate:

- Measurement error
- Surface completeness
- Repeated-scan consistency
- Capture time
- Tracking failure frequency
- Processing time
- Memory consumption
- File sizes
- User effort required to obtain a usable result

Compare reconstructed results with independently measured ground truth rather than treating the scanner output as ground truth.

## 12. Commercial Direction

Do not decide monetisation during the initial technical investigation.

Potential eventual models:

- Free scanning with paid specialist tooling.
- One-time Pro unlock.
- Paid advanced exports or processing.
- Dedicated vertical applications powered by the shared framework.
- Optional desktop companion tooling.

Prefer a sustainable, solo-maintainable product with minimal infrastructure costs.

The underlying capture and processing modules may be more strategically valuable than a generic consumer scanning application.

## 13. Risks and Constraints

**Sensor limitations:** Consumer LiDAR may produce insufficient detail for small objects or precise fitment tasks.

**Surface behaviour:** Reflective, transparent, dark and textureless surfaces may undermine depth capture or photogrammetry.

**Tracking drift:** Errors in estimated device pose may accumulate across a scan.

**Resource consumption:** Continuous capture and reconstruction may be expensive in memory, battery and thermals.

**Framework restrictions:** Apple APIs may not expose raw hardware observations or permit arbitrary combinations of capture modes.

**Data volume:** RGB and depth recording can generate large session files.

**False precision:** Measurements and reconstructed surfaces may appear more accurate than they are.

**Market saturation:** Generic scanning is established; commercial differentiation must come from workflow quality or specialist capabilities.

## 14. Open Research Questions

- What depth and confidence data can reliably be captured on the target device?
- Which capture streams can be recorded simultaneously?
- What sustained frame rates are realistic?
- How should observations be registered and fused?
- Which processing stages benefit most from custom implementations?
- When is photogrammetry preferable to depth reconstruction?
- How much can multi-frame fusion improve detail?
- Which geometry operations can execute comfortably on-device?
- How accurately can physical dimensions be recovered?
- What information must be retained for useful future reprocessing?
- What is the smallest useful commercial workflow?

## 15. Definition of Success

The project succeeds initially if it establishes a reusable spatial acquisition and processing foundation that enables rapid experimentation.

Longer term, success means delivering a scanning workflow that produces materially more useful outputs than generic capture alone.

The product should remain valuable even if the eventual commercial application is different from the one originally imagined.

---

**Guiding principle: Build the capture engine first. Allow the applications to emerge from what the engine makes possible.**
