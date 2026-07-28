---
name: narration-to-comic-video
description: Turn a supplied Chinese narration article into a complete high-quality comic/editorial explainer video, using the bundled Doubao mother image as the fixed recurring series character while generating other story characters as needed. Includes voiceover timing, separate humorous character dialogue, consistent recurring characters, generated cutout assets, HyperFrames motion editing, automated and visual QA, platform-ready audio/video, two cover images, and publishing copy. Use when the user provides a narration script, article, story, or spoken essay and asks Codex to make the whole video or a ready-to-publish self-media package.
---

# Narration To Comic Video

Produce the entire video, not a storyboard or prompt list. Preserve the supplied narration unless the user asks for rewriting. Treat narration and on-screen dialogue as two different storytelling tracks.

## Load supporting instructions

- Read `references/workflow.md` before starting any production.
- Read `references/scene-archetypes.md` before turning the manifest into scene files.
- Read `references/visual-qa.md` before generating the three representative scenes and before final QA.
- Read `references/parallel-production.md` before delegating scene ranges.
- Read `references/delivery.md` before packaging the result.
- Use the `hyperframes` skill for authoring/rendering and `media-use` or `imagegen` when media is required.

## Input contract

Accept:

- one narration article;
- optional voice, API credential, target loudness, style image, aspect ratio, and output folder.

Default to:

- 16:9, 1920×1080, 30 fps;
- H.264 MP4 with AAC 48 kHz audio;
- integrated loudness −20 LUFS unless the user specifies another value;
- a new project subfolder under the user-provided output folder;
- high-end editorial comic collage, unless a reference image defines another style.
- the bundled `assets/characters/doubao-mother.png` as Doubao's permanent identity anchor.

Ask only for missing material that blocks production, such as an unavailable voice credential. Do not repeatedly reconfirm ordinary implementation choices.
Do not replace Doubao with a newly invented design unless the user explicitly requests a new series character.

## Delivery contract

Keep the project root clean. It may contain only this folder plus these five deliverable files:

```text
项目名称/
├── 制作过程/
├── 文案.txt
├── 成片.mp4
├── 封面-横版4比3.jpg
├── 封面-竖版3比4.jpg
└── 发布信息.txt
```

Put every source asset, generated image, timeline, scene file, transcript, audio intermediate, render log, check report, snapshot, and draft inside `制作过程/`. Never scatter process files beside the deliverables. Do not delete `制作过程/`; the user decides whether to remove it after accepting the result.

Initialize this structure with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/scaffold_project.ps1 -ProjectRoot "ABSOLUTE_PROJECT_PATH" -ScriptPath "ABSOLUTE_SCRIPT_PATH"
```

Create scene boilerplate with `scripts/new_scene.ps1` instead of rewriting registration and safe-area code. Select the closest archetype from `references/scene-archetypes.md`, then customize its visuals.

## Core creative rules

1. Keep narration for listening. Write different, shorter on-screen dialogue for watching.
2. Make dialogue funny, emotional, and immediately understandable without names such as “老板：” or “豆包：”.
3. Point each speech-bubble tail to its speaker. Never cover a face.
4. Always use `assets/characters/doubao-mother.png` as an image reference whenever Doubao appears or a new Doubao pose is generated. Preserve her face, short dark bob, body proportions, white/silver-blue tech uniform language, and clean outlined comic rendering.
5. Use the Doubao mother image as the style reference for newly generated supporting characters and props, but do not copy her face onto them. Supporting-character identity is flexible; only reuse a previous supporting-character image when that person returns in the same story.
6. Prefer expressive cutout characters, props, editorial shapes, and purposeful motion over static full-frame illustrations.
7. Avoid PPT chrome: repeated scene numbers, kicker labels, fixed title bars, fixed footers, dense explanatory paragraphs, or decorative dots.
8. Reserve the bottom 170 px for narration subtitles.
9. Optimize for platform compression: strong silhouettes, large type, clean flat areas, no fine regular patterns.

## Production gates

### 1. Build the audio timeline

Generate narration audio, normalize to the requested loudness, transcribe with timestamps, and create a scene manifest. For a 7–8 minute narration, target roughly 35–50 scenes and 8–14 seconds per scene, adjusted to meaning rather than evenly divided.

Each manifest row must include:

- start and end time;
- narration excerpt;
- visible action;
- humorous dialogue or reaction;
- recurring characters;
- required assets;
- motion beat.

### 2. Lock style and characters

Copy the bundled Doubao mother image into `制作过程/assets/characters/doubao-mother.png` and make it the first entry in `制作过程/planning/character-whitelist.txt`. Create only the additional Doubao poses and expressions required by the script, always using that mother image as the image reference. Do not let later workers invent or substitute a new Doubao.

Create one style anchor for the whole video. Other story characters may be generated freely in the same rendering style; their exact identity does not need to persist across different videos. If a supporting character reappears within the current story, reuse its last correct image as reference.

Generate asset sheets with two or three large, separated items per image. Add a clean white or dark outline and enough empty space for reliable cropping. Inspect every crop for stray hands, limbs, backgrounds, or overlaps.

### 3. Pass the three-scene gate

Before batch production, complete only:

- the opening;
- the densest middle scene;
- the ending climax.

Create one contact sheet and inspect character consistency, crop edges, bubble direction, face occlusion, subtitle clearance, information density, and visual quality. If any representative scene fails, fix the system or template before producing the remaining scenes.

### 4. Produce scene ranges in parallel

After the three-scene gate passes, split the remaining scenes into consecutive ranges. Give each worker the same style anchor, character whitelist, timing manifest, subtitle-safe area, and file ownership rules. Each worker must create its own assets, scenes, snapshots, and contact sheet for its range.

Do not split by separate functions such as “one person draws everything” and “another person animates everything”; that creates handoff queues. Split by consecutive scene ranges so each worker finishes a complete slice.

### 5. Run layered QA

Run, in order:

1. segment contact-sheet self-check;
2. main-agent review of all segment contact sheets;
3. `scripts/visual_gate.ps1`;
4. HyperFrames lint and check;
5. three snapshots from the final scene through the full composition entry;
6. low-bitrate draft viewing;
7. final render and delivery verification.

Never treat a programmatic pass as proof that the image is visually correct.

### 6. Render safely

Before rendering, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/render_guard.ps1 -ProjectRoot "ABSOLUTE_WORK_PATH"
```

Stop and resolve any old render using the same project. Give each attempt unique log and temporary output names. Promote only a successful verified render to `成片.mp4`.

Render the upload version at 1080p/30 fps, typically CRF 20–22. Normalize audio after sound effects are mixed, not before. Verify actual integrated loudness, sample rate, resolution, duration, and file size.

### 7. Package publishing assets

Create both covers from the established style, not from an unrelated platform template. Write one title, a concise description, and exactly ten relevant topics in `发布信息.txt`.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify_delivery.ps1 -ProjectRoot "ABSOLUTE_PROJECT_PATH" -TargetLufs -20
```

Do not report completion until this passes and the final 16-frame contact sheet has been visually inspected.

## Speed target

For a 7–8 minute video with working credentials and usable references:

- audio and timing: 15–25 minutes;
- manifest, style anchor, and three representative scenes: 25–45 minutes;
- three-range parallel production: 45–90 minutes;
- integration, QA, render, covers, and publishing copy: 30–60 minutes.

Target 2–3 hours after the workflow is established. Image-generation delays or new style exploration can extend this to 3–4 hours. Do not gain speed by skipping the representative-scene gate or visual inspection.
