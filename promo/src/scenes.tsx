import React from "react";
import { AbsoluteFill, Audio, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Backdrop, Clip, Layout, LiveDot, Logo, Phone, PhoneIn, Pill, Screenshot, Title, Voice, phoneWidthFor } from "./ui";
import { color, fontFamily } from "./theme";

// Title band is 520 px tall; the phone area is the remaining 1400 px, minus margins.
const PHONE_AREA = 1920 - 520;
const HERO = phoneWidthFor(PHONE_AREA - 140); // one phone, breathing room top and bottom

/* 1 ─ Intro: logo, claim */
export const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 14, stiffness: 80 } });
  return (
    <AbsoluteFill>
      <Voice name="01_intro" />
      <Backdrop dark />
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 70 }}>
        <div style={{ transform: `scale(${interpolate(s, [0, 1], [0.7, 1])})`, opacity: s, background: "#fff", padding: "48px 72px", borderRadius: 48, boxShadow: "0 40px 100px rgba(0,0,0,0.3)" }}>
          <Logo width={560} />
        </div>
        <Title light delay={12} size={78} text="Don't know how to run a research study?" sub="Meet CARP Studies. Phone sensors, wearables, surveys and cognitive tests, in one app." />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

/* 2 ─ Onboarding: 3D carousel through the consent screens, swipes getting exponentially faster */
const ONBOARDING = ["consent_01_who_runs.png", "consent_03_what_data.png", "consent_04_location.png", "consent_06_nearby_devices.png", "consent_07_microphone.png", "consent_08_camera.png", "consent_10_health_data.png", "consent_13_summary_intro.png"];

/** Swipe i starts at [start] s and lasts [dur] s: holds 1.5 s, 1 s, 0.6 s ... getting exponentially faster. */
const SWIPES = (() => {
  let at = 0.6;
  return Array.from({ length: ONBOARDING.length - 1 }, (_, i) => {
    const hold = Math.max(1.5 * 0.65 ** i, 0.15);
    const dur = Math.max(0.25 * 0.8 ** i, 0.12);
    const start = at + hold;
    at = start + dur;
    return { start, dur };
  });
})();

/** Continuous carousel position at [t] seconds. */
const carouselPos = (t: number) => {
  for (let i = 0; i < SWIPES.length; i++) {
    const { start, dur } = SWIPES[i];
    if (t < start) return i;
    if (t < start + dur) return i + (t - start) / dur;
  }
  return SWIPES.length;
};

export const Onboarding: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pos = carouselPos(frame / fps);
  const n = ONBOARDING.length;
  const step = 360 / n;
  const w = 560;
  const bezel = w * 0.03;
  const phoneH = (w * 2532) / 1170 + bezel * 2;
  const r = (n * (w + 100)) / (2 * Math.PI);
  const enter = spring({ frame: frame - 4, fps, config: { damping: 18, stiffness: 90 } });
  return (
    <Layout title={<Title text="Onboarding that explains everything" sub="The purpose of the study, why data is collected, and the permissions needed - requested automatically." size={70} />}>
      <Voice name="02_onboarding" />
      {SWIPES.map(({ start }, i) => (
        <Sequence key={i} from={Math.round(start * fps)}>
          <Audio src={staticFile("vo/swipe.mp3")} volume={0.2} />
        </Sequence>
      ))}
      {/* ring of phones; the ring turns so screen [pos] faces the camera */}
      <div style={{ position: "relative", width: 1080, height: PHONE_AREA, perspective: 2400, perspectiveOrigin: "50% 40%", opacity: enter, transform: `translateY(${(1 - enter) * 200}px)` }}>
        <div style={{ position: "absolute", left: 540, top: (PHONE_AREA - phoneH) / 2, transformStyle: "preserve-3d", transform: `translateZ(${-r}px) rotateY(${-pos * step}deg)` }}>
          {ONBOARDING.map((src, i) => {
            const rel = (((i - pos) % n) + n) % n;
            const back = Math.min(rel, n - rel) / (n / 2); // 0 = front, 1 = behind
            return (
              <div key={src} style={{ position: "absolute", left: -(w + bezel * 2) / 2, top: 0, transform: `rotateY(${i * step}deg) translateZ(${r}px)`, opacity: 1 - back * 0.75, backfaceVisibility: "hidden" }}>
                <Phone width={w} depth={24}>
                  <Screenshot src={src} />
                </Phone>
              </div>
            );
          })}
        </div>
        {/* ground shadow under the front phone */}
        <div style={{ position: "absolute", left: 540 - 330, width: 660, top: (PHONE_AREA + phoneH) / 2 + 30, height: 90, borderRadius: "50%", background: "radial-gradient(ellipse at center, rgba(0,0,0,0.32) 0%, rgba(0,0,0,0) 70%)" }} />
      </div>
    </Layout>
  );
};

/* 3 ─ Home + connections: connect a service or device, then data records itself */
export const Home: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logos = ["polar.svg", "movesense.svg", "apple_health.png", "health_connect.png"];
  const w = phoneWidthFor(1920 - 700 - 160);
  return (
    <Layout
      titleHeight={700}
      title={
        <>
          <Title text="Connect once, data records itself" sub="Anonymous or invited, GDPR compliant. Data goes straight to a secure database." size={66} />
          <div style={{ display: "flex", gap: 28, marginTop: 10 }}>
            {logos.map((logo, i) => {
              const s = spring({ frame: frame - 14 - i * 4, fps, config: { damping: 12, stiffness: 100 } });
              return (
                <div key={logo} style={{ width: 130, height: 130, borderRadius: 40, padding: 20, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 20px 50px rgba(0,0,0,0.12)", transform: `scale(${s}) translateY(${(1 - s) * 40}px)`, opacity: s }}>
                  <Img src={staticFile(`logos/${logo}`)} style={{ width: "100%", height: "100%", objectFit: "contain" }} />
                </div>
              );
            })}
          </div>
        </>
      }
    >
      <Voice name="03_home" />
      <div style={{ display: "flex", gap: 40, alignItems: "center" }}>
        <PhoneIn width={w} delay={6}>
          <Screenshot src="home.png" />
        </PhoneIn>
        <PhoneIn width={w} delay={14}>
          <Clip from={46.2} />
        </PhoneIn>
      </div>
    </Layout>
  );
};

/* 4 ─ Statistics: the live demo footage, with feature callouts sliding in */
const Callout: React.FC<{ label: string; value: string; tint: string; at: number; side: "left" | "right"; y: number }> = ({ label, value, tint, at, side, y }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - at, fps, config: { damping: 15, stiffness: 100 } });
  return (
    <div
      style={{
        position: "absolute",
        top: y,
        [side]: 24,
        fontFamily,
        background: "#fff",
        borderRadius: 28,
        padding: "22px 30px",
        boxShadow: "0 24px 60px rgba(0,0,0,0.18)",
        [side === "left" ? "borderRight" : "borderLeft"]: `8px solid ${tint}`,
        transform: `translateX(${(1 - s) * 200 * (side === "left" ? -1 : 1)}px)`,
        opacity: s,
        minWidth: 210,
      }}
    >
      <div style={{ fontSize: 26, color: color.muted, fontWeight: 600, textTransform: "uppercase", letterSpacing: 1.5 }}>{label}</div>
      <div style={{ fontSize: 52, fontWeight: 800, color: tint, letterSpacing: -1, marginTop: 2 }}>{value}</div>
    </div>
  );
};

export const Statistics: React.FC = () => {
  const { fps } = useVideoConfig();
  return (
    <Layout
      dark
      title={
        <>
          <Pill tint={color.red} delay={4}>
            <LiveDot /> LIVE DATA
          </Pill>
          <Title light text="Collected in the background" sub="Heart rate, steps, activity, mobility - and many more." size={68} />
        </>
      }
    >
      <Voice name="04_statistics" />
      <PhoneIn width={HERO} delay={4}>
        {/* scrolls from the heart rate card down through steps, activity and sleep */}
        <Clip from={12.5} rate={1.5} />
      </PhoneIn>
      <Callout label="Heart rate" value="64 bpm" tint={color.red} at={0.7 * fps} side="left" y={720 - 520} />
      <Callout label="Steps" value="67 893" tint={color.distance} at={1.1 * fps} side="right" y={1000 - 520} />
      <Callout label="Activity" value="2530 min" tint={color.activity} at={1.5 * fps} side="left" y={1280 - 520} />
    </Layout>
  );
};

/* 5 ─ Tasks: survey + cognitive test screenshots side by side */
export const Tasks: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const w = phoneWidthFor(PHONE_AREA - 400);
  return (
    <Layout title={<Title text="Surveys, cognitive tests and more" sub="Audio, video, questionnaires - scheduled by you, with reminders." size={70} />}>
      <Voice name="05_tasks" />
      <div style={{ display: "flex", gap: 40, alignItems: "flex-start" }}>
        {["survey.png", "flanker_game.png"].map((src, i) => {
          const s = spring({ frame: frame - 8 - i * 8, fps, config: { damping: 16, stiffness: 90 } });
          return (
            <div key={src} style={{ transform: `translateY(${(1 - s) * 260}px) rotate(${(i === 0 ? -1 : 1) * 4 * s}deg)`, opacity: s, marginTop: i === 0 ? 0 : 120 }}>
              <Phone width={w}>
                <Screenshot src={src} />
              </Phone>
            </div>
          );
        })}
      </div>
    </Layout>
  );
};

/* 6 ─ Outro: logo mark lands, the CARP wordmark slides out from behind it */
export const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const mark = spring({ frame: frame - 4, fps, config: { damping: 14, stiffness: 80 } });
  const word = spring({ frame: frame - 22, fps, config: { damping: 18, stiffness: 70 } });
  const markW = 300;
  const h = markW * (1400 / 2647);
  const wordW = markW * (4788 / 2647);
  const gap = 40;
  const reveal = word * (wordW + gap); // card grows rightwards as the word slides out from behind the mark
  return (
    <AbsoluteFill>
      <Voice name="06_outro" />
      <Backdrop dark />
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 80 }}>
        <div style={{ position: "relative", height: h, width: markW + reveal, padding: "40px 56px", boxSizing: "content-box", background: "#fff", borderRadius: 48, boxShadow: "0 40px 100px rgba(0,0,0,0.3)", opacity: mark, transform: `scale(${interpolate(mark, [0, 1], [0.6, 1])})`, overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 56 + markW, top: 0, right: 0, height: "100%", overflow: "hidden" }}>
            <Img src={staticFile("assets/logo_word.png")} style={{ position: "absolute", left: gap - (1 - word) * (wordW + gap), top: 40, width: wordW }} />
          </div>
          <Img src={staticFile("assets/logo_mark.png")} style={{ position: "absolute", left: 56, top: 40, width: markW }} />
        </div>
        <Title light delay={40} size={72} text="For more information, check carp.dk" />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
