import { loadFont } from "@remotion/google-fonts/OpenSans";

// carp_themes_package palette + the chart colours used by the statistics cards.
export const color = {
  primary: "#006398",
  primaryDark: "#00476e",
  background: "#F2F2F7",
  red: "#EB4B62",
  ink: "#1c1c1e",
  muted: "#6e6e73",
  steps: "#82CEE9",
  activity: "#7E9146",
  distance: "#2192C9",
  sleep: "#7B5EA7",
};

export const { fontFamily } = loadFont("normal", { weights: ["400", "600", "700", "800"], subsets: ["latin"], ignoreTooManyRequestsWarning: true });

export const FPS = 30;
export const WIDTH = 1080;
export const HEIGHT = 1920;
