# Repository Guidelines

## Project Structure & Module Organization

Daily timer is a Swift 6 macOS app targeting macOS 14 and later.

- `Sources/TimerCore/`: deterministic timer state, thresholds, and scoring; keep UI dependencies out.
- `Sources/DailyTimer/`: SwiftUI views, AppKit panel interactions, preferences, and sound dispatch.
- `Tests/TimerCoreTests/` and `Tests/DailyTimerTests/`: model and application regression tests.
- `Tools/TimerAssets/`: app icon generation; `Resources/Info.plist`: bundle metadata.
- `scripts/`: testing, packaging, previews, and releases. `docs/images/` holds README renders. `Sources/ToastArt/` retains historical artwork excluded from the package targets.

## Build, Test, and Development Commands

Use Xcode 26.3 or later, or Swift 6 tools with a complete macOS 26 SDK.

- `swift build`: compile the package for development.
- `bash scripts/test.sh`: run Swift tests with the Testing macro discovery workaround when needed; prefer this over bare `swift test`.
- `bash scripts/package.sh`: build release binaries, generate the icon, ad-hoc sign, and produce the app, ZIP, and checksum in `dist/`.
- `open "dist/Daily timer.app"`: launch the packaged app.
- `bash scripts/render-previews.sh`: regenerate README images from actual views.
- `bash scripts/test-release.sh`: validate release-script behavior.

## Coding Style & Naming Conventions

Follow existing Swift style: four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` functions and properties. Match filenames to their primary responsibility. No Swift formatter or linter is configured. Keep timing logic independent of wall-clock access; inject clocks and effects at application boundaries. Avoid duplicate logic and trivial wrappers. Comment only complex, non-obvious behavior. Discuss competing implementation approaches before choosing one.

## Testing Guidelines

Use Swift Testing (`@Test`, `#expect`) with descriptive behavior-based function names in `*Tests.swift`. Test exact threshold boundaries and state transitions using explicit timestamps. Application tests should isolate `UserDefaults` and inject sound callbacks. No coverage percentage is enforced. For UI changes, also check the packaged app manually; rendered previews do not verify live focus, dragging, or translucency.

## Commit & Pull Request Guidelines

Use short imperative commit subjects, matching history: `Render app icon without requiring Metal`. Keep commits focused. PRs should describe the behavior change, relevant issues, validation performed, and screenshots for visual changes. Run applicable checks and review CI results for both architectures. Successful pushes to `main` automatically publish releases; consult `docs/releases.md` before changing release automation. Ask before committing on the user's behalf.
