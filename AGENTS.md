# Repository Guidelines

## Project Structure & Module Organization

This repository currently contains a minimal native SwiftUI application for a planned local-first spatial capture platform.

- `Lidar/MyApp.swift`: application entry point and root scene.
- `Lidar/ContentView.swift`: initial UI, SwiftUI preview, and playground snippet.
- `Lidar/Assets.xcassets/`: asset catalog, including the accent color.
- `Lidar.xcodeproj/`: build settings and the single `Lidar` application target. The source directory uses Xcode filesystem synchronization.
- `PRD.md`: product vision and proposed architecture. Read it before implementing capture or processing features; its proposed layers are not yet implemented.

There are currently no test targets, external dependencies, or separate framework modules.

## Build, Test, and Development Commands

Run commands from the repository root:

```sh
open Lidar.xcodeproj
xcodebuild -list -project Lidar.xcodeproj
xcodebuild -project Lidar.xcodeproj -scheme Lidar -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

These open Xcode, list available targets and schemes, and build for the simulator without signing. Use an Xcode installation with SDKs supporting the configured deployment targets; iOS currently targets 27.0. To run locally, select the `Lidar` scheme and an available simulator or device in Xcode, then press Run. Future LiDAR capture must also be validated on supported physical hardware.

## Coding Style & Naming Conventions

Match the existing Swift style: four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` functions and properties. Name Swift files after their primary type. Keep SwiftUI views focused and extract reusable components as features grow. Respect the target's default `MainActor` isolation when introducing processing work. No formatter or linter is configured; use Xcode formatting and keep changes consistent with nearby code.

## Testing Guidelines

No automated testing framework or coverage threshold is configured. Build affected platforms and inspect UI changes with previews and a simulator. When adding tests, create an appropriate test target, use Swift Testing for unit tests or XCTest for UI tests, and name files `<Feature>Tests.swift`. Document manual checks and hardware requirements in the pull request.

## Commit & Pull Request Guidelines

Git history contains only the initial `Hey Lidar` commit, so no established message convention exists. Use concise, imperative subjects describing one coherent change. Pull requests should explain the behavior changed, reference relevant issues or PRD sections, list validation performed, and include screenshots for UI changes. Keep generated build output and personal Xcode settings out of commits.
