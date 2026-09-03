// Generate the voice-over clips from vo/transcripts.md with ElevenLabs.
//   ELEVENLABS_API_KEY=... bun vo/generate.ts [voiceId]
// Writes public/vo/<scene>.mp3 - skips clips that already exist.
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";

const key = process.env.ELEVENLABS_API_KEY;
if (!key) throw new Error("ELEVENLABS_API_KEY not set");

// "George" - warm, neutral British narrator. Override with argv[2].
const voiceId = process.argv[2] ?? "JBFqnCBsd6RMkjVDRZzb";

const md = readFileSync(new URL("./transcripts.md", import.meta.url), "utf8");
const lines = [...md.matchAll(/^## (\d\d_\w+)\n> (.+)$/gm)].map(([, name, text]) => [name, text.trim()] as const);
if (lines.length === 0) throw new Error("no '## name' + '> text' pairs in transcripts.md");

mkdirSync("public/vo", { recursive: true });

for (const [name, text] of lines) {
  const out = `public/vo/${name}.mp3`;
  if (existsSync(out)) {
    console.log(`skip ${out}`);
    continue;
  }
  const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`, {
    method: "POST",
    headers: { "xi-api-key": key, "Content-Type": "application/json" },
    body: JSON.stringify({
      text,
      model_id: "eleven_multilingual_v2",
      voice_settings: { stability: 0.55, similarity_boost: 0.75, style: 0.2, use_speaker_boost: true },
    }),
  });
  if (!res.ok) throw new Error(`${name}: ${res.status} ${await res.text()}`);
  writeFileSync(out, Buffer.from(await res.arrayBuffer()));
  console.log(`wrote ${out}  "${text}"`);
}
