# MacFans — Design Spec

Date: 2026-09-10
Status: Draft, awaiting review

## 1. Goal

A native macOS app that shows live sensor temperatures and fan speeds, and lets the user control fan RPM safely.
Three control modes: **Auto** (system control, the default), **Constant** (fixed RPM per fan), and **Custom** (user-defined rules that react to sensor temperatures).
It must feel like a first-class Mac app: native SwiftUI, menu bar presence, respects system appearance, no clutter.

## 2. Verified platform facts (probed on this machine, M5 Max, macOS 26.6)

- SMC is reachable unprivileged through the `AppleSMC` IOKit user client (selector 2, the classic `SMCKeyData` struct).
  Reads work without root.
- Fans: `FNum` = 2. Per fan `F<n>Ac` (actual RPM, `flt`), `F<n>Tg` (target), `F<n>Mn` / `F<n>Mx` (min/max RPM, 1350–5349 and 1350–5777 here), `F<n>md` (mode, `ui8`, 0 = auto, 1 = forced).
- Temperatures: ~90 SMC keys of type `flt` under `T*` (`TB0T` battery, `TH0x` NAND, `TPD*`, `TRD*`, `TD*`, `TN*`, `TCMb`, ...).
  Names must come from a curated map; unknown keys are still shown, labelled by key.
- IOHID temperature services (usage page `0xff00`, usage 5) also work but on M5 are mostly duplicated `PMU tdie*` entries with garbage `tdev*` values, so SMC keys are the primary source.
- SMC **writes** fail unprivileged with `kIOReturnNotPrivileged` (0xe00002c1).
  Fan control therefore needs a root helper.
- Toolchain: Xcode 26.6 installed but the license is not accepted, so `xcodebuild` is blocked until `sudo xcodebuild -license accept` is run.
  Command Line Tools (Swift 6.3) work today for SwiftPM builds.
  No code-signing identity is present; the app will be ad-hoc signed.

## 3. Architecture

Four units, each with one job and a narrow interface.

```
┌──────────────────────────────┐        XPC (Mach service)        ┌───────────────────────┐
│ MacFans.app (SwiftUI, user)  │ ───────────────────────────────▶ │ MacFansHelper (root)  │
│  • reads SMC directly        │   setFan(index, rpm) / setAuto   │  • SMC writes only    │
│  • runs the rule engine      │   heartbeat()                    │  • clamps to min/max  │
│  • UI + persistence          │                                  │  • watchdog → auto    │
└──────────────┬───────────────┘                                  └───────────┬───────────┘
               │ uses                                                          │ uses
        ┌──────▼───────┐                                                ┌──────▼───────┐
        │ MacFansCore  │  (pure Swift: models, rule engine, sensor map) │   SMCKit     │
        └──────────────┘                                                └──────────────┘
```

### 3.1 SMCKit (Swift package target)

- Opens `AppleSMC`, enumerates keys, reads values, writes values.
- Decodes SMC types (`flt`, `sp78`, `fpe2`, `ui8`, `ui16`, `ui32`) into Swift values.
  Decoding is pure and unit-tested.
- Exposes typed accessors: `fanCount()`, `fan(index) -> FanReading`, `temperatureKeys() -> [SMCKey: Double]`, `setFanMode`, `setFanTarget`.
- Both the app (reads) and the helper (writes) link it.

### 3.2 MacFansCore (Swift package target, no UI, no IOKit)

- **Models**: `Sensor` (key, display name, group: CPU / GPU / Memory / Storage / Battery / Other), `Fan` (index, name, min, max, actual, target, mode), `Profile`, `Rule`, `FanSpeed`.
- **SensorCatalog**: curated key → (name, group) map for Apple Silicon, with user overrides on top.
  Unknown keys get a fallback name from the key and land in Other.
  Keys with obviously invalid values (< -50 °C or > 150 °C) are filtered.
- **RuleEngine**: pure function `evaluate(profile, readings, previousState) -> (FanCommands, newState)`.
  Deterministic and fully unit-tested.
- **ProfileStore**: JSON encode/decode of profiles and settings.

### 3.3 MacFans.app

- SwiftUI, Swift 6 strict concurrency, minimum macOS 15.
- `MenuBarExtra` with a compact live readout plus a full main window.
- `SensorPoller` actor samples SMC every 2 s (configurable) and publishes readings plus a rolling history (last 30 min, in memory only).
- `FanController` observable: holds the active mode, feeds readings to `RuleEngine`, sends commands to the helper via XPC, and sends a heartbeat every poll.
- On quit, sleep, or switching to Auto it explicitly restores every fan to auto.

### 3.4 MacFansHelper (root launchd daemon)

- Registered with `SMAppService.daemon(plistName:)` and embedded in `Contents/Library/LaunchDaemons`.
  The user approves it once in System Settings › Login Items.
- XPC interface, three calls: `setFan(index:rpm:)`, `setAuto(index:)`, `heartbeat()`.
- Verifies the connecting process code signature matches the app's (same Team/identifier; ad-hoc for local builds).
- Clamps requested RPM to the hardware `Mn`/`Mx` it reads itself; never trusts the client's bounds.
- **Watchdog**: if no heartbeat for 10 s while any fan is forced, it restores all fans to auto.
  This covers app crashes and force-quits.
- Restores auto on its own shutdown.

## 4. Control modes and rules

### 4.1 Modes

| Mode | Behaviour |
|------|-----------|
| Auto | Every fan `md = 0`. Helper is idle. Default and safe state. |
| Constant | User picks a fixed RPM (or %) per fan with a slider between hardware min and max. |
| Custom | The active profile's rules decide per fan. Fans with no active rule fall back to Auto. |

### 4.2 Rule model

A **Profile** is a named, ordered list of **Rules**. One profile is active at a time.

A **Rule** has:

- **Trigger**: a sensor, or a sensor group with an aggregate (`max` or `average`), e.g. "max of CPU".
- **Turn on above**: threshold in °C.
- **Turn off below**: lower threshold in °C (hysteresis, must be < on-threshold; default on − 5).
- **Fans**: one or more fans, or all.
- **Speed**: fixed RPM, percentage of the fan's range, or "max".
- **Enabled** toggle.

Semantics:

- A rule becomes active when its trigger reading ≥ on-threshold and stays active until the reading ≤ off-threshold.
- For each fan the engine takes the **highest** speed among active rules targeting it.
- A fan with no active rule returns to Auto.
- The engine also applies a minimum dwell of 5 s before lowering a fan's speed to avoid oscillation.

This is the model the user asked for ("which sensor > what degrees → which fans → until which degrees") kept to one concept; fan curves are not in v1.

### 4.3 Built-in profiles

Shipped as read-only templates the user can duplicate: **Quiet** (kick in late), **Balanced**, **Cool** (kick in early, strong).
All use CPU-max / GPU-max triggers so they work without the user knowing SMC keys.

### 4.4 Safety

- All writes pass through the helper's clamp; the UI also clamps.
- Auto is restored on quit, sleep, helper watchdog timeout, and when the user switches profiles.
- A persistent banner shows whenever any fan is under manual control.
- Any sensor above 100 °C shows a warning colour in all views regardless of mode.

## 5. UI

Native macOS look, SF Symbols, system colours, light/dark, reduced motion respected.

- **Menu bar item**: icon plus configurable text (hottest sensor °C, a chosen sensor, or fan RPM).
  Click opens a popover: temperatures of key groups, both fans with RPM and mode, a mode picker (Auto / Constant / Custom + profile), a "Full blast for 5 min" button, and "Open MacFans".
- **Main window** with a sidebar:
  - **Overview**: hero cards for CPU / GPU / hottest sensor, fan gauges with RPM and target, mode segmented control, 30-minute Swift Charts sparkline of temps and RPM.
  - **Fans**: one card per fan with a gauge, min/max, live target, Constant-mode slider.
  - **Sensors**: grouped table with name, key, °C, sparkline, favourite toggle, inline rename; search field; option to show raw/unknown keys.
  - **Profiles**: list of profiles; editor with rule rows (sensor picker, on/off thresholds, fans, speed) and a live "would this rule be active now?" indicator.
  - **Settings**: poll interval, temperature unit (°C/°F), launch at login, menu bar readout, start in mode, helper status with install/repair button.

## 6. Persistence

- Profiles, sensor overrides, and settings: JSON under `~/Library/Application Support/MacFans/`.
- Small UI prefs (window, unit): `UserDefaults`.
- History is in memory only.

## 7. Error handling

- SMC unavailable (VM, unsupported Mac): app runs in read-only "unsupported" state with a clear message.
- Helper not installed or denied: fan controls are disabled with an inline explanation and an install button that calls `SMAppService.register` and, if needed, opens Login Items.
- XPC failure mid-control: app shows a banner and reverts UI to Auto; the helper watchdog covers the hardware side.
- Any sensor read returning an out-of-range value is dropped for that sample, not shown as a spike.

## 8. Project layout and tooling

```
MacFans/
  project.yml                 # XcodeGen → MacFans.xcodeproj
  Packages/MacFansKit/        # SwiftPM: SMCKit, MacFansCore (+ tests)
  App/                        # MacFans.app sources, assets, entitlements
  Helper/                     # MacFansHelper sources + launchd plist
  scripts/build.sh            # xcodebuild wrapper, ad-hoc sign, run
  docs/superpowers/specs/     # this spec
```

- Xcode project generated by XcodeGen (already installed) so the project file is not hand-maintained.
- `xcodebuild` needs the Xcode license accepted once.
- Unit tests: SMC decoding, sensor catalog, rule engine (activation, hysteresis, max-wins, dwell, fallback to auto), profile JSON round-trip.
- Manual E2E: install helper, verify each mode changes real RPM, verify watchdog by killing the app while in Constant mode.

## 9. Out of scope for v1

- Intel Macs beyond best-effort raw keys.
- Fan curves (multi-point temp→RPM), scheduling, notifications.
- Auto-update, notarised distribution, localisation.
- Reading sensors that require root.

## 10. Open items needing Jasper

1. Run `sudo xcodebuild -license accept` so the project can be built with `xcodebuild`.
2. Confirm minimum macOS 15 and Apple Silicon-first is acceptable.
3. Confirm the rule model in §4.2 (threshold rules with hysteresis, no curves in v1).

## 11. Implementation notes (2026-09-11)

The shipped code follows this design with a few renamed units.
`SensorPoller` became `ThermalMonitor` (backed by the `SMCReader` actor), `ProfileStore` became `ConfigurationStore`, and the per-tick decision logic lives in `ControlPlanner` on top of `RuleEngine`.
The persistent manual-control banner from §4.4 was replaced by the mode status line on the Overview and the mode picker in the toolbar, which the user preferred.
The Overview was simplified to two cards after user feedback; charts moved to a History tab.
