# Voice-over transcripts

One file per scene, dropped into `public/vo/<name>.mp3` - the scene picks it
up automatically (`<Voice name="…">` in `src/scenes.tsx`), and renders silent
if the file is missing.

Target ~2.5 words/second at a calm pace. Each line is written to finish about
half a second before its scene ends. Scene lengths are in `src/index.tsx`.

ElevenLabs settings that suit this: a neutral, warm narrator (e.g. "Rachel" or
"George"), stability ~0.55, similarity ~0.75, speed 1.0. Same voice for all seven.

| file | scene | length |
|---|---|---|
| `01_intro.mp3` | Intro | 4.8 s |
| `02_onboarding.mp3` | Onboarding | 5.2 s |
| `03_home.mp3` | Home + connections | 6.8 s |
| `04_statistics.mp3` | Statistics | 5.6 s |
| `05_tasks.mp3` | Tasks | 5 s |
| `06_outro.mp3` | Outro | 4.6 s |

---

## 01_intro
> Don't know how to run a research study? Meet CARP Studies.

## 02_onboarding
> Onboarding explains why data is collected, the purpose, and asks for permissions.

## 03_home
> Anonymous or invited, GDPR compliant. Connect once - data flows to a secure database.

## 04_statistics
> Heart rate, steps, activity and many more are collected in the background,

## 05_tasks
> and you can also run surveys, cognitive tests, audio and video tasks, on your own schedule.

## 06_outro
> For more information, check carp dot dk.

---

## Music

A quiet bed underneath helps the cuts. Drop a royalty-free track at
`public/vo/music.mp3` and add to `src/index.tsx` inside the composition:

```tsx
<Audio src={staticFile("vo/music.mp3")} volume={0.12} />
```

## Store limits

- **App Store previews:** 15-30 s, max 30 fps, audio optional. Portrait for
  6.9"/6.7"/6.1" iPhones is **886×1920** - our 1080×1920 is scaled at upload,
  or render at that size with `--width 886`. Current total is 30.5 s - trim
  `Statistics` from 9 to 8.5 s in `src/index.tsx` to land under 30.
- **Google Play:** a YouTube link, no hard limit; 30 s-2 min recommended,
  landscape preferred but portrait is accepted.
