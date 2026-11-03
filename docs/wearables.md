# Movesense and Apple Watch

## Dependencies

- `carp_movesense_package` 4.0.0 (git ref, until published) runs on `movesense_plus` 2.x,
  replacing the discontinued `carp_movesense_flutter`. Existing CARP protocols, devices
  and probes are unchanged.
- `carp_aware_package: ^1.1.0` supplies Apple Watch sampling over WatchConnectivity.
- Minimum iOS 16, watchOS 10, Dart 3.12.2. Swift Package Manager is enabled.

## Apple Watch setup and upload

The study protocol must include an `AppleWatchDevice` and tasks targeting it with
`AppleWatchSamplingPackage` measures. See `test/flow/fixtures/test_study/protocol.json`.
The watch appears under Connections only on iOS; it does not use the BLE scanner.

Pair the watch in Apple's Watch app, install the CARP companion, connect from
CARP, then open the watch app, load the phone's study settings and tap Start.
The watch does not start sampling before receiving study settings. Permissions
for watch sensors are requested on the watch.

Watch records become CARP measurements and use the study's existing data endpoint
and upload policy. Do not configure `awareServerUrl` for CARP-only upload. The
watch's transfer-complete status is **not** confirmation of server upload.
Local deployment writes locally; it does not upload to CARP.

## Known upstream limitations — validate before research deployment

`carp_aware_package` 1.1.0 checks pairing immediately after activating WCSession;
the first connection can incorrectly report no paired watch. Retry once activation
has completed. Its record pipeline is not durable end-to-end: a broadcast stream
can drop records before probes listen, native buffers are bounded, and disconnect
clears the receiving handler. The documented record-ID deduplication is not
implemented in its probe stream. Do not treat this integration as lossless.

For pilot protocols, set `deleteAfterTransfer: false` to retain a recovery copy
on the watch, and `saveToLocalAwareDatabase: true` for a phone-side copy. Neither
setting automatically replays missing records into CARP; watch storage must be
monitored. Reliable replay/acknowledgement needs an upstream package fix.

Before release, test with a real iPhone, Apple Watch and Movesense: first pairing,
permissions denied, background collection, phone offline, reconnection, retained
records, and records arriving in the configured CARP backend. Host tests and
simulator builds cannot verify Bluetooth or watch-to-server delivery.

## Checks

```sh
flutter test
flutter analyze
flutter build apk --debug
```

Flutter 3.47.6's simulator build command fails to read settings for this watch
companion scheme. This equivalent unsigned native build succeeds:

```sh
flutter build ios --config-only --debug --no-codesign
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/wearables-ios CODE_SIGNING_ALLOWED=NO build
```

Run config-only immediately before xcodebuild: `flutter pub get` regenerates the
SPM wrapper with Flutter's default iOS minimum, while config-only raises it to
this project's iOS 16 minimum.

## Local watch smoke test

`assets/carp/resources/protocol.json` is intentionally git-ignored: it can contain
study-specific credentials. The local copy has an optional Apple Watch with all
nine measures, 10 Hz motion, one-minute incremental transfers, audio analysis
for 60 seconds followed by 180 seconds rest, and microphone background runtime.
For recovery, it keeps watch records and saves a second copy in the phone's AWARE
database. These copies are not an automatic retry mechanism; monitor storage.
Raw audio recording is disabled in the companion app.

1. Build/install the iPhone app in local mode (`flutter run
   --dart-define=deployment-mode=local`) and install its watch companion.
2. Start a fresh local study so the edited protocol is loaded. Under Connections,
   connect Apple Watch. If the initial pairing check fails, retry after activation.
3. Open CARP on the watch, tap **Reload settings**, then **Start**, and grant the
   requested watch permissions. Wear the watch for heart rate and move your wrist.
4. Keep CARP open on the phone. After a minute, or using **Send data to phone**
   on the watch, tap the connected Apple Watch card on the phone.
5. The **Written to SQLite - Apple Watch** sheet should show increasing
   `dk.carp.watch.aware.*` counts and the latest measurement (refreshes every two
   seconds). A connected badge alone is not proof of data reception.

Local mode checks watch-to-phone storage, **not backend upload**. The package's
known delivery limitations above still apply. Some sensors may not produce
records until their permissions and environmental conditions are satisfied.

Validate your actual local protocol without committing it:

```sh
flutter test test/apple_watch_protocol_test.dart \
  --dart-define=WATCH_PROTOCOL=assets/carp/resources/protocol.json
```
