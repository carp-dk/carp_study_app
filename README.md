# CARP Studies App

The CARP Studies App is designed to run generic studies using the [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing) (CAMS) Framework, which is part of the [Copenhagen Research Platform](https://carp.dk) (CARP) from the [Department of Health Technology](https://www.healthtech.dtu.dk/) at the Technical University of Denmark.

It follows a basic Business Logic Component (BLoC) combined with a Model-View-View-Model architecture, as described in the [CARP Mobile Sensing Demo App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app).

Read more about the [CARP Studies app](https://carp.dk/carp-studies-app/) on the CARP Homepage.

## Deployment Mode

This study app can run in two basic modes - using CAWS or locally. Deployment mode is set using the environment variable `deployment-mode` file. In the Flutter environment, variables are set by specifying the `--dart-define` option in flutter run. For example;

```shell
flutter run --dart-define="deployment-mode=dev" --dart-define="debug-level=debug"
```

would run the app against the CAWS dev server with debug level set to debug. Without `deployment-mode`, a debug build (`flutter run`) runs in local mode and a release build uses production.

In VSCode, you can add a `launch.json` file to specify different deployment modes.

### Local Deployment

Local mode runs a study from files in the app, with no server and no account. It is for designing and testing a study before uploading it to CAWS. Put the files in `assets/carp/` (ignored by git, so study files never end up in this repo):

```
assets/carp/
  resources/protocol.json   the study protocol (required)
  resources/consent.json    the informed consent (optional - no file, nothing to sign)
  lang/en.json, da.json     translations for keys used in the protocol and consent (en.json is the fallback)
  messages/*.json           messages on the Home tab, one file each (optional)
```

These are the same files you upload to the CARP Portal later. Generate them with Dart rather than editing by hand - see [Configure your study](https://carp-dk.github.io/carp-docs-starlight/start/configure-your-study/).

Local mode keeps nothing between runs - edit the files and restart the app. Any sign-in works, and the study appears as the only invitation. Collected data is stored on the phone in `carp-data.db` (SQLite).

### CAWS Deployment

When using CAWS, deployment mode can be set to either `dev`, `test`, or `production`. In all of these cases, the app will try to authenticate to CAWS and download all resources - study protocol, informed consent, translations, and messages - from CAWS. These resources should be added to CAWS before use, and each participant should be added to a study and deployed before it can be downloaded to the app.

## Project layout

```
lib/
  main.dart, carp_study_app.dart   app entry, routing (go_router) and localization
  core/        AppBloc (app state), Backend (CarpBackend for CAWS, LocalBackend for local mode), sensing
  data/        local mode: LocalBackend, LocalResourceManager (reads assets/carp), LocalSettings
  services/    auth, study, consent, messages, background sensing
  view_models/ one per page
  ui/          pages, cards, tasks and widgets
assets/
  lang/        the app's own UI translations (en, da, es) - update all three when adding a key
  carp/        your local study (see above, gitignored)
  icons/, images/, instructions/   images used by the UI
test/          unit and widget tests (test/json holds the protocols used by cams_app_test)
integration_test/   end-to-end flow on a device: flutter test integration_test -d <device>
docs/          store release pipeline
```

Run `flutter test` for the unit tests and `flutter analyze` before opening a PR. Feature PRs target the `test` branch.
