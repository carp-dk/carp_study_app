# CAMS 2.x Migration Plan

Migrating `carp_study_app` from the CARP Mobile Sensing **1.x** line to the
**2.x** line (API level 2.0.0).

> **Status:** strategy / analysis only. This document contains **no code
> changes** — it is the agreed plan to execute in a follow-up branch.

---

## 1. Why

We are one major version behind on the entire CARP stack. `carp_mobile_sensing`
(CAMS) is the foundation of the CARP Flutter ecosystem, so when it released
**2.0.0 / 2.1.x**, every satellite package (`carp_core`, the sampling packages,
and the CAWS backends) was bumped a major version in lockstep to "API level
2.0.0". Staying on 1.x means we no longer get fixes, and new study protocols
authored against the 2.x server tooling may not deploy cleanly.

The 2.x release brings two headline features and a runtime-model change:

1. **Multiple studies** can be added to one client manager.
2. **Persistent runtime state** — sampling resumes across app restart.
3. **Simplified configuration** — only the *client* is configured now, not the
   per-study *controller*; and the executor state machine moved from
   `started/stopped` to `resumed/paused`.

Sources: `carp_mobile_sensing` CHANGELOG 2.1.1, `carp_core` 2.0.0,
`carp_webservices` 4.0.0, `carp_backend` 2.0.0, and the GitHub milestone
[2.0.0](https://github.com/carp-dk/carp.sensing-flutter/milestone/3?closed=1).

---

## 2. Version delta

Target versions are the latest published 2.x line (verified against pub.dev and
the local `~/Work/carp.sensing-flutter` checkout @ `ec21c82d`).

| Package | Current (`pubspec.yaml`) | Target | Bump |
|---|---|---|---|
| `carp_serializable` | `^2.0.0` | `^2.0.1` | minor |
| `carp_core` | `^1.9.0` | `^2.1.2` | **major** |
| `carp_mobile_sensing` | `^1.13.0` | `^2.1.1` | **major** |
| `carp_context_package` | `^1.10.0` | `^2.0.0` | **major** |
| `carp_connectivity_package` | `^1.7.0` | `^2.0.0` | **major** |
| `carp_survey_package` | `^1.8.2` | `^2.0.0` | **major** |
| `carp_audio_package` | `^1.10.0` | `^2.0.0` | **major** |
| `carp_polar_package` | `^1.6.1` | `^2.0.0` | **major** |
| `carp_health_package` | `^3.2.0` | `^4.0.0` | **major** |
| `carp_movesense_package` | `^1.7.2` | `^2.0.0` | **major** |
| `carp_webservices` | `^3.8.0` | `^4.0.0` | **major** |
| `carp_backend` | `^1.9.2` | `^2.0.0` | **major** |
| `carp_themes_package` | `^0.0.5` | `^0.0.5` | none |
| `cognition_package` | `^1.6.1` | `^1.7.0` | minor (optional) |
| `research_package` | `^2.2.0` | `^2.2.0` | none |

Notes:
- Every satellite sampling package 2.0.0 is a pure "upgrade to CARP Core / CAMS
  API level 2.0.0" recompile — no app-facing API of its own changed beyond what
  CAMS core introduces.
- `carp_health_package` 4.0.0 is **only** the API-level bump; the disruptive
  `health` plugin v12 work already landed in 3.x, which this app is already on.
- 2.x requires a newer Dart/Flutter SDK (pub lists Dart 3.10 for 2.1.x). The
  repo currently pins Flutter `3.44.0` (see `chore(fvm)` commit) — confirm
  `pub get` resolves cleanly under the pinned toolchain; bump the
  `environment:` constraint in `pubspec.yaml` if the resolver demands it.

---

## 3. What actually breaks for us

The migration surface is **small and well-contained**. Only ~12 files in `lib/`
and `test/` touch CARP APIs, and the auth/backend layer
(`lib/data/carp_backend.dart`, `CarpAuthService`, `CarpParticipationService`)
is **API-stable** at our call sites — `authenticate()`,
`authenticateWithMagicLink()`, `authenticated`, `logout()`,
`getActiveParticipationInvitations()`, and the participation-reference consent
methods `getInformedConsentByRole()` / `setInformedConsent()` all still exist in
4.0. The real churn is in the **CAMS runtime layer** (`Sensing` and the BLoC).

### 3.1 Breaking-change reference (1.x → 2.x)

Verified against the local 2.x source:

| # | 1.x API (what we use) | 2.x replacement | Source |
|---|---|---|---|
| 1 | `SmartphoneDeploymentController` (class) | **`SmartphoneStudyController`** (renamed) | `runtime/study_controller.dart:19` |
| 2 | `clientManager.getStudyRuntime(deploymentId)` | **`getStudyController(SmartphoneStudy study)`** — renamed **and** now takes the `SmartphoneStudy` object, not a String id | `runtime/client_manager.dart:98` |
| 3 | `controller.tryDeployment(useCached: true)` | **removed from controller** → `clientManager.tryDeployment(studyDeploymentId, deviceRoleName)` returns `StudyStatus` | `carp_core/.../client_manager.dart:178` |
| 4 | `controller.configure()` | **removed** — configuration is automatic when the study is added to the client | `runtime/study_controller.dart` (no `configure`) |
| 5 | `controller.start()` | **`controller.resume()`** | `study_controller.dart:536` |
| 6 | `controller.stop()` | **`controller.pause()`** | `study_controller.dart:539` |
| 7 | `ExecutorState.started` | **`ExecutorState.Resumed`** (enum values are now PascalCase: `Created, Initialized, Resumed, Paused, PausedButShouldBeResumed, Disposed, Undefined`) | `runtime/executors/executors.dart` |
| 8 | `clientManager.removeStudy(deploymentId)` | **`removeStudy(studyDeploymentId, deviceRoleName)`** — now requires the role name too | `runtime/client_manager.dart:305` |
| 9 | `controller.samplingSize` | **removed** — derive the total locally | `study_controller.dart` (no `samplingSize`) |
| 10 | `carp_backend` `InformedConsentManager` setter | methods renamed to "Consent Document": `setConsentDocument()` / `getConsentDocument()` / `deleteConsentDocument()` | `carp_backend/.../informed_consent_manager.dart` |

**Stable (no change needed)** at our call sites: `SmartPhoneClientManager.configure(...)`,
`addStudy(SmartphoneStudy)` → `SmartphoneStudy`, `deviceController` and its
`devices` / `connectedDevices` / `smartphoneDeviceManager`, `controller.measurements`,
`controller.executor.probes` / `addMeasurement` / `addError`, `SmartphoneDeployment`
(`tasks`, `measures`, `connectedDevices`, `expectedParticipantData`, `deployed`),
all measure data types (`Measurement`, `Activity`, `StepCount`, `Mobility`,
`PolarHR`, `MovesenseHR`), `AppTaskController`, `SmartphoneStudy`,
`StudyDeploymentStatus`, `CarpUser`, and the whole `lib/data/carp_backend.dart`
auth flow.

---

## 4. File-by-file change list

### 4.1 `pubspec.yaml`
Bump all rows in §2. Run `flutter pub get`; if it fails, bump `environment.sdk`
to whatever 2.x requires and re-pin via FVM.

### 4.2 `lib/blocs/sensing.dart` (core of the migration)
- Change the field/getters `SmartphoneDeploymentController? _controller` →
  `SmartphoneStudyController?` (lines ~24, ~39, ~42, ~51).
- `isRunning` (line 56): `ExecutorState.started` → `ExecutorState.Resumed`.
- `addStudy()` (lines 137–142) — restructure to the 2.x flow:
  ```dart
  _study = await SmartPhoneClientManager().addStudy(bloc.study!);
  // tryDeployment moved to the client manager and needs the role name
  final status = await SmartPhoneClientManager()
      .tryDeployment(_study!.studyDeploymentId, _study!.deviceRoleName);
  _controller = SmartPhoneClientManager().getStudyController(_study!);
  translateStudyProtocol();
  // NO controller.configure() — gone in 2.x
  // ...measurement debug listener unchanged...
  return status;
  ```
  This folds the old `tryDeployment()` helper into `addStudy()` (or keep the
  helper but move the client-level `tryDeployment` call and drop `configure()`).
- `removeStudy()` (line ~181): pass two args —
  `removeStudy(study!.studyDeploymentId, study!.deviceRoleName)`. The old
  `TypeError`-swallow comment about the unsafe `as SmartphoneDeploymentController`
  cast in `getStudyRuntime` can be revisited; verify whether 2.x's
  `getStudyController` still throws when the study was never added (it returns
  nullable now — likely the `try/catch` can become a null check).

### 4.3 `lib/blocs/app_bloc.dart`
- `start()` (line 463): `Sensing().controller?.start()` → `...resume()`.
- `stop()` (line 467): `Sensing().controller?.stop()` → `...pause()`.
- No other change — `deployment`, `executor.probes`, `executor.addMeasurement`,
  `executor.addError`, `dispose()`, participation/consent calls are all stable.

### 4.4 `lib/view_models/view_model.dart` & `lib/view_models/data_visualization_page_model.dart`
- Replace `SmartphoneDeploymentController` with `SmartphoneStudyController` in
  the `_controller` field, getter, and `init(...)` parameter type.

### 4.5 `lib/view_models/cards/measurements_data_model.dart`
- `samplingSize` getter (lines 14–15): the controller no longer exposes it.
  Derive locally, as the existing commented-out line already intends:
  ```dart
  int get samplingSize =>
      _samplingTable.values.fold(0, (sum, n) => sum + n);
  ```

### 4.6 `lib/main.dart`
- No API change expected: `CarpMobileSensing.ensureInitialized()`,
  `CognitionPackage.ensureInitialized()`, `CarpDataManager.ensureInitialized()`
  all persist. Verify at compile time only.

### 4.7 Other card view models (activity, heart_rate, mobility, steps, study_progress)
- No source change expected — they consume `controller?.measurements` and data
  types that are unchanged. They only need the rename to compile transitively
  (the `controller` type flows from `ViewModel`).

### 4.8 Tests — `test/cams_app_test.dart`, `test/heart_rate_data_model_test.dart` (+ `.mocks.dart`)
- `heart_rate_data_model_test.dart` mocks `SmartphoneDeploymentController` →
  retype the mock to `SmartphoneStudyController` and **regenerate** mocks:
  `dart run build_runner build --delete-conflicting-outputs`.
- `cams_app_test.dart`: verify `SmartphoneStudyProtocol.fromJson` and the
  `ensureInitialized()` / `SamplingPackageRegistry().register(...)` calls still
  compile (expected: yes).

---

## 5. Execution strategy

Do this on a dedicated branch off `test` (e.g. `chore/cams-2.x-upgrade`),
**separate from this planning branch**:

1. **Bump `pubspec.yaml`** (§2) and `flutter pub get`. Resolve SDK/version
   conflicts first — nothing else compiles until the graph resolves. Use the
   local path-overrides block (already scaffolded and commented in `pubspec.yaml`)
   pointing at `~/Work/carp.sensing-flutter` if a transitive pin blocks pub.
2. **Mechanical renames** — `SmartphoneDeploymentController` →
   `SmartphoneStudyController` across `lib/` and `test/`. This clears most of the
   compiler errors and reveals the real call-site work.
3. **Fix the runtime lifecycle** in `sensing.dart` (§4.2): the
   `addStudy`/`tryDeployment`/`getStudyController` reshuffle and drop of
   `configure()`. This is the only non-mechanical edit.
4. **Fix start/stop → resume/pause** in `app_bloc.dart`, `ExecutorState.Resumed`
   in `sensing.dart`, two-arg `removeStudy`, and `samplingSize` local fold.
5. **Regenerate mocks** and fix tests.
6. `flutter analyze` until clean, then `flutter test`.
7. **Manual smoke test** in both deployment modes (see §6).
8. Open PR to `test`.

Keep the diff scoped to API adaptation — do **not** opportunistically adopt the
new multi-study / persistent-state features in this PR. The app's
single-study singleton (`Sensing`) maps cleanly onto the 2.x single-study path;
multi-study is a future enhancement, not a migration requirement.

---

## 6. Risks & things to verify during implementation

- **Persistent runtime state (new default).** 2.x persists sampling state and
  resumes across restart. Our `Sensing` singleton assumes a fresh deploy per
  launch and re-runs `tryDeployment(useCached: true)`-style logic. Verify the
  `leaveStudy` / `removeStudy` path fully clears persisted state so a user who
  leaves and rejoins doesn't resume a stale deployment. This is the highest-risk
  behavioral change.
- **`getStudyController` nullability.** It now returns `SmartphoneStudyController?`.
  Audit the `_controller = ...!`/`controller!` force-unwraps in `sensing.dart`
  and `app_bloc.dart` for the cold-start / cancelled-consent race the existing
  `removeStudy` comment already guards against.
- **`tryDeployment` return + ordering.** Confirm `getStudyController(_study!)`
  returns a non-null controller immediately after `addStudy` (it is created
  inside `addStudy` at `client_manager.dart:243`) and that calling the
  client-level `tryDeployment` before vs. after fetching the controller does not
  change deployment status semantics.
- **`carp_health_package` 4.0 permissions.** Re-run the Health Connect (Android)
  and HealthKit (iOS) permission flow end-to-end; health plugin majors are the
  usual source of silent runtime breakage even when the API compiles.
- **SDK/Flutter pin.** 2.1.x advertises Dart 3.10. Confirm against the pinned
  `3.44.0` FVM toolchain; a forced SDK bump ripples into CI
  (`.github`, fastlane, build numbers).
- **`carp_backend` consent rename.** Our `lib/data/carp_backend.dart` wraps the
  *participation-reference* consent methods (stable), not the
  `InformedConsentManager` interface, so item #10 likely needs **no** app change
  — but grep for any direct `InformedConsentManager` setter use to be sure.

---

## 7. Rollback

All changes are confined to `pubspec.yaml`, `pubspec.lock`, the ~12 source files
above, and regenerated `.mocks.dart`. Rollback = revert the upgrade PR; no data
migration or server-side change is involved. Because 2.x introduces persistent
sampling state on-device, instruct internal testers to **reinstall** the app
when moving between a 1.x build and a 2.x build to avoid reading state written
by the other major version.
