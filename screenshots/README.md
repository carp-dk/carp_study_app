# Screenshots

Reference captures from a real device, kept as source material for the promo
video, design review and release notes.

**Not the store listing images.** Those are designed marketing assets in
`android/fastlane/metadata/android/en-GB/images/`, which fastlane uploads to
Google Play on every release - putting raw captures there would overwrite the
live listing.

## Contents

`consent_01` ... `consent_17` walk the onboarding flow in order: the consent
carousel (who runs the test, what data is collected, and one slide per data
type), the full consent form, signature, and confirmation.

The rest are the main screens: `login`, `home`, `connections`,
`study_details`, `survey`, `flanker_game`.

## Capturing more

Over USB with [pymobiledevice3](https://github.com/doronz88/pymobiledevice3).
iOS 17+ needs a tunnel running as root in a separate terminal:

```sh
sudo ~/.local/pipx/venvs/pymobiledevice3/bin/pymobiledevice3 remote tunneld
```

Then, per shot:

```sh
pymobiledevice3 developer dvt screenshot screenshots/<name>.png
sips -Z 1170 screenshots/<name>.png   # keeps files ~100 KB instead of ~1.6 MB
```
