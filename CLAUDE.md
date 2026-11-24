# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

OBD Live is a SwiftUI iPhone app (iOS 16+) that turns a Freematics ONE+ OBD-II logger into a live dashboard and diagnostics tool over Bluetooth LE. It's built from the *OBD Live* prototype designed in Claude Design. The logger must run the telelogger firmware from `karolciejka/freematics`, branch `obd-live-ble` (`firmware_v5/telelogger`), which adds the `PIDS` and `RAW` BLE commands the app relies on.

## Commands

```sh
# Core logic tests (parsing, framing, poll plan, simulator). No Xcode needed; runs on macOS or Linux with a Swift toolchain.
cd OBDCore && swift test
cd OBDCore && swift test --filter ParsingTests/testFreezeFrame   # one test (classes: ParsingTests, ProtocolTests, FormatTests, SimulatorTests, PollPlanTests)

# App build, as CI does it (no signing needed for the simulator)
xcodebuild build -project OBDLive.xcodeproj -target OBDLive -configuration Debug \
  -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO

# After adding, removing or renaming any .swift file in OBDLive/ or OBDCore/Sources/OBDCore/, or a font:
python3 scripts/gen-xcodeproj.py .
```

`project.pbxproj` is generated, with deterministic object IDs. Don't hand-edit it; change `scripts/gen-xcodeproj.py` (build settings, bundle id `com.karolciejka.obdlive`) and regenerate. The generator picks up every `.swift` file in `OBDLive/` and `OBDCore/Sources/OBDCore/`, and every `.ttf` in `OBDLive/Resources/Fonts/`.

CI (`.github/workflows/`): `build.yml` runs `swift test` and the simulator build on every push and PR, and fails on build errors (warnings are annotated). `screenshots.yml` (manual) runs the app in the simulator on demo data and force-pushes `docs/screenshots/*.png` to the `ci-screenshots` branch; the README embeds those images. `testflight.yml` (manual) archives and uploads with an App Store Connect API key from repo secrets.

Bluetooth doesn't work in the Simulator. Use demo mode ("Use demo data") there.

## Architecture

**Two layers, one module.** `OBDCore/` is a Foundation-only Swift package (channel table, OBD-II reply parsing, BLE command framing, `PollPlan`, trouble-code descriptions, `DemoSimulator`). The app target does **not** import it as a package: the Xcode project compiles the `OBDCore` sources straight into the app target. So OBDCore types stay `internal` (no `public`), the app has no `import OBDCore`, and tests use `@testable import OBDCore`. Keep OBDCore free of SwiftUI/CoreBluetooth so it keeps building and testing on Linux.

**Transport.** `OBDLive/FreematicsLink.swift` is the CoreBluetooth central. The logger exposes service `0xABF0` (advertised as `FreematicsPlus`). Plain-text commands go to `0xFFE1`, and each reply is one `\r`-terminated line notified on `0xFFE2`. Commands are queued and sent one at a time, and every callback runs on the main queue. Per-command timeouts live in `FreematicsBLE.timeout(for:)` (code reads and clears can take the ECU ~12 s).

**State.** `OBDLive/AppModel.swift` is the single `ObservableObject` for every screen, injected via `.environmentObject`. Key flows:
- *Connect → handshake → discover → poll.* Handshake sends `ATE0`, `UPTIME`, `BATT`, `VIN`, `RAW0100`. Discovery reads supported-PID bitmaps (`RAW0100/0120/0140`) and probes whether the car answers combined multi-PID requests (`RAW010C0D`). `PollPlan` then decides how to chunk polling: combined `RAW01…` requests, or `PIDS…` one-at-a-time. PIDs the car doesn't answer are skipped.
- *Link generations.* `linkGeneration` is bumped on every connect/reconnect, and every async completion checks `gen == self.linkGeneration` before touching state. Keep this guard in any new BLE callback, or stale replies from a dropped link will corrupt state.
- *Job queue.* `enqueue` puts on-demand BLE work (codes, freeze frame, clear) into `jobs`, which the poll loop runs between read cycles, so those requests never race polling for the single command channel.
- *Reconnect.* When the link drops while on the app screen, the model reconnects by itself ("Reconnecting…"). A drop on the connect screen resets with an error.
- *Demo mode.* A main-runloop `Timer` at `DemoSimulator.tick` drives `DemoSimulator`, which produces readings and fake CAN frames for the Parked / Driving modes.

**Theming / skins.** Four skins (Simple, Racing, Power, Retro) are defined in `OBDLive/Theme.swift`. `Palette` mirrors the design's CSS custom properties (comments name the `--skin-*` variable each field maps to). `DS` is a static, global "current skin" accessor. `RootView` calls `DS.use(skin)` and applies `.id(skin)` so the whole view tree is rebuilt on a skin change. Views read `DS.*` tokens directly rather than taking a palette parameter. Skin-specific hero gauges live in `TypeRGauge.swift` (Racing), `PowerGauge.swift` (Power) and `RetroGauge.swift` (Retro), and `LiveView` switches on `DS.skin`. All skins are dark (`.preferredColorScheme(.dark)`).

**Settings.** The design's Tweaks panel is the iOS Settings app (`OBDLive/Resources/Settings.bundle/Root.plist`). Keys are in `SettingsKey` (`skin`, `rpmStyle`, `units`, `demoMode`, `combinedRequests`), read via `UserDefaults` / `@AppStorage`. Defaults are registered in `SettingsKey.registerDefaults()`. A new setting needs both the plist entry and the default.

**Launch arguments** (used by `screenshots.yml`, handy for local simulator runs): `-autoDemo YES` opens demo mode immediately, `-startTab live|graph|codes|can` picks the landing tab, and any settings key can be overridden the same way (`-skin Retro -demoMode Driving -rpmStyle Ring`).

## Real-car behaviour worth knowing before changing logic

- Ignition off: the logger answers `N/A`. Engine values show "—", battery stays live and the header shows "No ECU".
- Gear isn't an OBD PID. It's estimated from the rpm/speed ratio.
- Only freeze frame 0 exists, so only the code that triggered it shows freeze-frame values.
- On a real logger the CAN tab shows the relayed OBD TX/RX traffic. Broadcast frames appear only in demo mode.
- The `PortPhoto` asset is empty by default, and the connect screen shows a striped placeholder.

## Requirements docs

`docs/requirements/` holds the PRD, user stories (split into `Done/` and `ToDo/`, grouped A to E) and one Gherkin `.feature` file per story under `BDD Tests/` (ToDo stories are tagged `@wip`). These are specs only; nothing executes the `.feature` files. When a story is implemented, move it from `ToDo/` to `Done/` and drop the `@wip` tag.
