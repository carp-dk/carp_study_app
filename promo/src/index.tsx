import React from "react";
import { AbsoluteFill, Audio, Composition, interpolate, registerRoot, staticFile, useCurrentFrame } from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { FPS, HEIGHT, WIDTH } from "./theme";
import { Home, Intro, Onboarding, Outro, Statistics, Tasks } from "./scenes";

const s = (seconds: number) => Math.round(seconds * FPS);
const cross = linearTiming({ durationInFrames: s(0.5) });

// Scene lengths in seconds: the voice-over clip plus a beat, so the narration
// never runs into the next scene's crossfade. Re-measure after regenerating vo/.
const scenes: [React.FC, number][] = [
  [Intro, 4.0],
  [Onboarding, 5.95],
  [Home, 6.8],
  [Statistics, 5.2],
  [Tasks, 6.3],
  [Outro, 3.9],
];

export const total = scenes.reduce((sum, [, d]) => sum + s(d), 0) - (scenes.length - 1) * s(0.5);

const Promo: React.FC = () => {
  const frame = useCurrentFrame();
  const fadeOut = interpolate(frame, [total - s(1.5), total], [1, 0], { extrapolateLeft: "clamp" });
  return (
  <AbsoluteFill>
    {/* music bed: public/vo/music.mp3 is cyberpunk.mp3 from 0:19 */}
    <Audio src={staticFile("vo/music.mp3")} volume={0.1 * fadeOut} />
  <TransitionSeries>
    {scenes.flatMap(([Scene, d], i) => [
      <TransitionSeries.Sequence key={`s${i}`} durationInFrames={s(d)}>
        <Scene />
      </TransitionSeries.Sequence>,
      i < scenes.length - 1 && (
        <TransitionSeries.Transition key={`t${i}`} timing={cross} presentation={fade()} />
      ),
    ])}
  </TransitionSeries>
  </AbsoluteFill>
  );
};

registerRoot(() => <Composition id="Promo" component={Promo} durationInFrames={total} fps={FPS} width={WIDTH} height={HEIGHT} />);
