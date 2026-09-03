import React from "react";
import { AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, getStaticFiles, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { color, fontFamily } from "./theme";

/** iPhone-shaped bezel around a 1170x2532 screen (the raw capture aspect). */
export const Phone: React.FC<{
  children: React.ReactNode;
  width?: number;
  style?: React.CSSProperties;
  /** Body thickness in px for 3D scenes: stacks slabs behind the phone and drops the flat shadow. */
  depth?: number;
}> = ({ children, width = 720, style, depth = 0 }) => {
  const height = (width * 2532) / 1170;
  const bezel = width * 0.03;
  const slab = { position: "absolute" as const, inset: 0, borderRadius: width * 0.16, background: "#2a2a2c" };
  return (
    <div
      style={{
        width: width + bezel * 2,
        height: height + bezel * 2,
        borderRadius: width * 0.16,
        background: "#111",
        padding: bezel,
        boxShadow: depth ? "0 0 0 2px #3a3a3c inset" : "0 60px 120px rgba(0,0,0,0.35), 0 0 0 2px #3a3a3c inset",
        position: "relative",
        transformStyle: depth ? "preserve-3d" : undefined,
        ...style,
      }}
    >
      {depth > 0 && Array.from({ length: Math.ceil(depth / 3) }, (_, k) => <div key={k} style={{ ...slab, transform: `translateZ(${-(k + 1) * 3}px)` }} />)}
      <div style={{ width, height, borderRadius: width * 0.13, overflow: "hidden", background: "#fff", position: "relative" }}>
        {children}
        {/* dynamic island */}
        <div
          style={{
            position: "absolute",
            top: width * 0.03,
            left: "50%",
            transform: "translateX(-50%)",
            width: width * 0.3,
            height: width * 0.085,
            borderRadius: 999,
            background: "#000",
          }}
        />
      </div>
    </div>
  );
};

export const Screenshot: React.FC<{ src: string; style?: React.CSSProperties }> = ({ src, style }) => (
  <Img src={staticFile(`screenshots/${src}`)} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block", ...style }} />
);

/** A segment of the raw app recording. [from] in seconds of the source. */
export const Clip: React.FC<{ from: number; rate?: number }> = ({ from, rate = 1 }) => {
  const { fps } = useVideoConfig();
  return <OffthreadVideo src={staticFile("app.mp4")} startFrom={Math.round(from * fps)} playbackRate={rate} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />;
};

/** Phone sliding up into place and settling. */
export const PhoneIn: React.FC<{ children: React.ReactNode; width?: number; delay?: number; y?: number }> = ({ children, width, delay = 0, y = 0 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 18, stiffness: 90, mass: 1.1 } });
  return (
    <div style={{ transform: `translateY(${interpolate(s, [0, 1], [220, y])}px) scale(${interpolate(s, [0, 1], [0.92, 1])})`, opacity: s }}>
      <Phone width={width}>{children}</Phone>
    </div>
  );
};

/** Headline + subline, each word rising in with a stagger. */
export const Title: React.FC<{ text: string; sub?: string; delay?: number; size?: number; light?: boolean; align?: "left" | "center" }> = ({
  text,
  sub,
  delay = 0,
  size = 84,
  light = false,
  align = "center",
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const ink = light ? "#fff" : color.ink;
  const muted = light ? "rgba(255,255,255,0.78)" : color.muted;
  const words = text.split(" ");
  return (
    <div style={{ fontFamily, textAlign: align, padding: "0 80px" }}>
      <div style={{ fontSize: size, fontWeight: 800, lineHeight: 1.08, letterSpacing: -2, color: ink, display: "flex", flexWrap: "wrap", justifyContent: align === "center" ? "center" : "flex-start", gap: "0 0.28em" }}>
        {words.map((w, i) => {
          const s = spring({ frame: frame - delay - i * 3, fps, config: { damping: 16, stiffness: 120 } });
          return (
            <span key={i} style={{ display: "inline-block", transform: `translateY(${(1 - s) * 40}px)`, opacity: s }}>
              {w}
            </span>
          );
        })}
      </div>
      {sub && (
        <div
          style={{
            marginTop: 22,
            fontSize: size * 0.42,
            fontWeight: 400,
            color: muted,
            lineHeight: 1.35,
            opacity: spring({ frame: frame - delay - words.length * 3 - 4, fps, config: { damping: 20 } }),
          }}
        >
          {sub}
        </div>
      )}
    </div>
  );
};

/** Brand logo (wordmark from assets/carp_logo.png). */
export const Logo: React.FC<{ width?: number; style?: React.CSSProperties }> = ({ width = 420, style }) => (
  <Img src={staticFile("assets/carp_logo.png")} style={{ width, ...style }} />
);

/** Soft blue gradient background with a slowly drifting highlight. */
export const Backdrop: React.FC<{ dark?: boolean }> = ({ dark = false }) => {
  const frame = useCurrentFrame();
  const drift = Math.sin(frame / 90) * 6;
  return (
    <AbsoluteFill
      style={{
        background: dark
          ? `radial-gradient(120% 80% at ${50 + drift}% 20%, ${color.primary} 0%, ${color.primaryDark} 55%, #002a42 100%)`
          : `radial-gradient(120% 80% at ${50 + drift}% 0%, #ffffff 0%, ${color.background} 60%, #e4e7ef 100%)`,
      }}
    />
  );
};

/** A small pill label, e.g. above a phone. */
export const Pill: React.FC<{ children: React.ReactNode; delay?: number; tint?: string }> = ({ children, delay = 0, tint = color.primary }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 14 } });
  return (
    <div
      style={{
        fontFamily,
        display: "inline-flex",
        alignItems: "center",
        gap: 14,
        padding: "16px 34px",
        borderRadius: 999,
        background: tint,
        color: "#fff",
        fontSize: 34,
        fontWeight: 700,
        transform: `scale(${s})`,
        opacity: s,
        boxShadow: "0 10px 30px rgba(0,0,0,0.15)",
      }}
    >
      {children}
    </div>
  );
};

/** Pulsing "live" dot for the statistics scene. */
export const LiveDot: React.FC = () => {
  const frame = useCurrentFrame();
  const pulse = 0.6 + 0.4 * Math.abs(Math.sin(frame / 8));
  return <span style={{ width: 18, height: 18, borderRadius: 999, background: "#fff", display: "inline-block", opacity: pulse, boxShadow: `0 0 0 ${6 * pulse}px rgba(255,255,255,0.3)` }} />;
};

/** Fixed page grid: a title band on top, the rest for the phone - so nothing
 * hangs off the bottom. Phone width is derived from the space left. */
export const Layout: React.FC<{ title: React.ReactNode; children: React.ReactNode; dark?: boolean; titleHeight?: number }> = ({ title, children, dark, titleHeight = 520 }) => (
  <AbsoluteFill>
    <Backdrop dark={dark} />
    <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: titleHeight, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "flex-end", gap: 28, paddingBottom: 40 }}>{title}</div>
    <div style={{ position: "absolute", top: titleHeight, left: 0, right: 0, bottom: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>{children}</div>
  </AbsoluteFill>
);

/** Phone width that fits a phone (with bezel) into [height] px. */
export const phoneWidthFor = (height: number) => Math.floor(height / ((2532 / 1170) + 0.06));

/** Voice-over for a scene: plays public/vo/<name>.mp3 if it has been generated
 * (see vo/transcripts.md), silent otherwise so the video renders without it. */
export const Voice: React.FC<{ name: string; delay?: number }> = ({ name, delay = 0.4 }) => {
  const { fps } = useVideoConfig();
  const file = `vo/${name}.mp3`;
  if (!getStaticFiles().some((f) => f.name === file)) return null;
  return (
    <Sequence from={Math.round(delay * fps)}>
      <Audio src={staticFile(file)} volume={1.6} />
    </Sequence>
  );
};
