## 4.1.1

- small visual fixes

## 4.1.0

- Now supporting anonymous user authentication

## 4.0.1

- Minor improvements

## 4.0.0

- Total redesign of the app
- Upgrading Java 1.8 to 17
- Upgrading Kotlin 1.8 to 17
- Removing esense package
- In app updates for iOS and Android
- Fastfile now writes -test suffix for test branch
- Fastfile now caches gradle and is faster
- Adding UI feedback for background autocompleting tasks


## 3.5.2

- fix of #425 for audio task
- upgrade to CAMS 1.12.6
- temp fix of #427

## 3.5.1

- new media for App Store
- supporting iOS version 13.0 now
- minor changes

## 3.5.0

- upgraded flutter version from 3.24.5 to 3.29.1 (latest stable)
- upgraded gradle from 7.x to 8.13 (latest version)
- upgraded compileSdkVersion from 34 to flutter.compileSdkVersion (35 - latest version)
- updated package versions
- updated github actions and ios scripts to use flutter stable instead of 3.24.5
- removed unnecessary google permissions
- removed depricated function calls and code warnings
- changed location dialog button text from 'Allow' to 'Continue' to comply with App Store feedback

## 3.4.1

- Flutter stable branch was no longer stable and therefore github actions were failing. Reverted back to older version of flutter inside the scripts.

## 3.4.0

- Fixing ios marketing name
- Providing link (by making PermissionsRationaleActivity) for Google Health Connect Privacy Policy
- Fixing issue for ios only running on test mode locally due to override of dart_defines

## 3.3.2

- Changing Marketing Version value from $(FLUTTER_BUILD_NUMBER) to $(FLUTTER_BUILD_NAME) for ios.

## 3.3.1

- Updating version code
- Providing changelog file for fastlane to give to Google Play

## 3.3.0

- Fixing movesense connectivity exception that crashed the app on release mode by adding proguards rules that prevent the movesense package from getting obfuscated

## 3.2.1

- Fix Bug: App crashes when a notification is fired on app start-up #378
- Fix Bug: App can't start when Computerome server is not available #379
- Fix Exception thrown when app starts without internet connection #368

## 3.1.0

- Fix of login exception in webservice with non nullable name field
- Fix of vanishing tasks in research package

## 3.0.0

- Changes of camelCase to snake_case in the research package make the app backwards incompatible.
- Fix of bluetooth connection dialog for android.
- Fix of local deployment mode.

## 2.2.3

- Fixing login issue with going back to invitations list page
- Updating changelog.md and pubspec.yaml
- Bumping version code to 35
- Fixing build error on ios - tests failing
- Fix of bug in uploading surveys (issue [#342](https://github.com/carp-dk/carp_studies_app/issues/342))

## 2.2.2

- Upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.11
- Cleanup in pubspec.yaml
- Upload of informed consent as a input data type
- Saving participant data on the phone across app restart

## 2.2.1

- Created github action script to create a release on pushing a tag on master.
- Update permissions on Android, fix bug on informed consent upload.
- Fixed gradle warnings
- Bumping version to 2.2.0
- On android, check if user has Google Health Connect installed dialog.

## 2.1.0

- fix of switching studies in the study app
- refactor of view model
- improvements to translations (especially the Danish ones)
- upgrade to fixes in the underlying CAMS (related to #283)
- improvement to API docs
- upgrade and refactor of connectivity_plus
- Aligning iOS "marketing version" with Flutter pubspec version
- upgrade to latest CAMS packages
- upgrade to carp_backend 1.7.1
- Delete gitignored files
- Bumping version to 2.1.0

## 2.0.0

- Update to latest version of Carp Mobile Sensing (1.5.0)
- Add support for connecting to Movesense devices, collecting HR data, visualizing HR data collected
- Removed support for Apple HealthKit (temporily, due to conflict with Movesense integration)
- Support for running app in local deployment mode in order to debug a protocol before uploading it to CAWS
- Improve connection process with Bluetooth devices
- Update URLs to point to new servers
- Various bug fixes:
  - properly request permissions for `flutter_local_notifications`
  - fix some overflows, bugs, colors in UI
  - fix "Local environment" task duplication
  - fix crash related to theme
  - fix logging out/leave study dialogs appearing twice and not working.
- redesigned camera preview
- improve subtitles for task list

- changed namespace from `com.cachet.carp_studies_app` to `dk.carp.studies_app` and applicationId from `com.cachet.carp_study_app` to `dk.cachet.carp_study_app`.
- Added screenshots and string translations in Danish and English.
- Added script to see commit messages as 'What To Test' in testflight.
- Added internet connectivity checks to see if user has WiFi or Mobile Data enabled and show warning otherwise. Checks are done when logging in or logging out.
- Added Bluetooth checks to see if user has bluetooth on, show dialog otherwise.
- Migrate to new `CarpAuthService`.

## 1.4.0

- added support for collection of health data from Apple Health or Google Health Connect
- fixed a number of issues related to;
  - on-boarding flow
  - user authentication
  - using the Polar device

## 1.2.0

- fixed a bunch of issues in the app stemming from 1.1 and 1.0.

## 0.23.0

- track iOS version numbering.
- this version adds a heart rate visualization with a Polar device and created a continuous integration pipeline for iOS deployment.
- fixed some visual issues in the devices page.

## 0.40.0

- upgrade to `carp_mobile_sensing` v 0.40.0

## 0.32.1

- server-side messaging

## 0.32.0

- upgrade to `carp_mobile_sensing` v. 0.32.x
- fix of
  - <https://trello.com/c/qFZxo4Ws/110-sensing-is-not-started-on-app-restart>
  - <https://trello.com/c/eu99YxlD/108-too-much-text-in-location-pop-up-no-translation-to-danish>
  - <https://trello.com/c/8DWHufIU/105-translation-of-notifications>
- **note** that the app needs to be deleted and re-installed, if language is changed (need to download the study protocol instead of using the cached one)

## 0.21.0

- upgrade to `carp_mobile_sensing` v. 0.22.x
- support for downloading study protocol, informed consent, and localization from CARP

## 0.20.0

- upgrade to `carp_mobile_sensing` v. 0.20.x

## 0.1.0

- basic architecture
- basic UX
- support for simple sensing
- support for simple survey
