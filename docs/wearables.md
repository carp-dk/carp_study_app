# Movesense and Apple Watch

## Dependencies

- `movesense_plus: ^2.0.0` replaces `carp_movesense_flutter`.
- `packages/carp_movesense_package` is the published 3.1.0 source (MIT), with its
  plugin dependency/import changed to `movesense_plus`. Existing CARP protocols,
  devices and probes are unchanged. Remove the local copy when the published
  sampling package supports this plugin.
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
