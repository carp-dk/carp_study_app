# Promo video

30 s portrait (1080×1920) promo, built with [Remotion](https://remotion.dev)
from `../screenshots` and `../assets` (symlinked into `public/`).

```sh
bun install
ffmpeg -i "../screenshots/raw video of app.mov" -an -c:v libx264 -crf 20 -pix_fmt yuv420p public/app.mp4
ELEVENLABS_API_KEY=... bun run vo   # voice-over -> public/vo/*.mp3 (lines in vo/transcripts.md)
bun run studio    # live preview / scrub
bun run render    # -> out/promo.mp4
```

`public/vo/music.mp3` is a 32 s excerpt of the music bed (not committed):
`ffmpeg -ss 19 -t 32 -i cyberpunk.mp3 public/vo/music.mp3`.

Scenes are in `src/scenes.tsx`, order and durations in `src/index.tsx`.
The statistics scene uses the raw recording of the app running with
`--dart-define=demo=true` (see `lib/services/demo_data_service.dart`).
