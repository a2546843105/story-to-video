import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const args = process.argv.slice(2);
const input = args[0];
const output = args[1];

function valueAfter(flag, fallback) {
  const index = args.indexOf(flag);
  return index >= 0 && args[index + 1] ? args[index + 1] : fallback;
}

if (!input || !output) {
  console.error(
    "Usage: node encode-platform.mjs <input.mp4> <output.mp4> [--crf 21] [--maxrate 5M]",
  );
  process.exit(2);
}

if (!fs.existsSync(input)) {
  console.error(`Input not found: ${input}`);
  process.exit(2);
}

const crf = valueAfter("--crf", "21");
const maxrate = valueAfter("--maxrate", "5M");
const bufsize = valueAfter("--bufsize", "10M");
const audioBitrate = valueAfter("--audio-bitrate", "160k");

fs.mkdirSync(path.dirname(path.resolve(output)), { recursive: true });

const ffmpegArgs = [
  "-hide_banner",
  "-loglevel",
  "warning",
  "-y",
  "-i",
  input,
  "-map",
  "0:v:0",
  "-map",
  "0:a:0?",
  "-c:v",
  "libx264",
  "-preset",
  "slow",
  "-crf",
  crf,
  "-maxrate",
  maxrate,
  "-bufsize",
  bufsize,
  "-profile:v",
  "high",
  "-level",
  "4.1",
  "-pix_fmt",
  "yuv420p",
  "-r",
  "30",
  "-g",
  "60",
  "-keyint_min",
  "60",
  "-sc_threshold",
  "0",
  "-color_primaries",
  "bt709",
  "-color_trc",
  "bt709",
  "-colorspace",
  "bt709",
  "-c:a",
  "aac",
  "-b:a",
  audioBitrate,
  "-ar",
  "48000",
  "-movflags",
  "+faststart",
  output,
];

const result = spawnSync("ffmpeg", ffmpegArgs, { stdio: "inherit" });
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);

const stat = fs.statSync(output);
if (stat.size === 0) {
  console.error("Encoding produced an empty file");
  process.exit(1);
}

console.log(
  JSON.stringify({
    output: path.resolve(output),
    bytes: stat.size,
    crf,
    maxrate,
    bufsize,
    audioBitrate,
  }),
);
