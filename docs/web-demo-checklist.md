# Threshold Deep — Web Demo Checklist

*Written 2026-07-21. The plan for getting a playable browser demo onto
itch.io and linked from The Gentle Machine (the-second-gaze, GitHub
Pages). Paused for now — polish first — but the path is scouted and the
gotchas are recorded so this is a follow-a-recipe step later, not a
research step.*

## The plan in one line

Export a Godot **Web** build → upload the zip to **itch.io** (tick the
SharedArrayBuffer box) → link to that itch page from the portfolio's
games page. The portfolio repo never holds the build.

**Why itch and not GitHub Pages directly:** Godot 4 web builds need
COOP/COEP response headers (for SharedArrayBuffer/threads). itch.io sets
them with a checkbox; GitHub Pages can't set headers at all, so
self-hosting there needs a service-worker shim or a threads-disabled
build. itch sidesteps the whole problem, and the portfolio page just
links out.

## What's already in our favour

- [x] A **Web export preset already exists** in `export_presets.cfg`.
- [x] **Physics is built-in Jolt** (no `addons/`), so there's **no
  GDExtension web-export blocker** — the usual Godot-on-web killer isn't
  in play here.
- [x] Small project (28 scripts / 43 scenes) — fast to export, small
  wasm.

## Blockers to clear before the build looks/runs right

### 1. Renderer: Forward+ → Compatibility (visual check needed)

The web only runs the **Compatibility** renderer; our project is
**Forward+**. Set a web-only override so the editor/F5 stays Forward+:

- [ ] In Project Settings → Rendering → Renderer, add a **web override**
  = `gl_compatibility` (writes `rendering/renderer/rendering_method.web`
  to `project.godot`; the Windows default stays Forward+).
- [ ] **Eyeball the lighting.** Threshold Deep's whole mood is the
  torch-lit dark. Compatibility handles lights differently — the
  interiors may read brighter/flatter, and the intentional darkness is a
  pillar. Export a test build and look before shipping. If it's washed
  out, tune ambient/torch **per-renderer** rather than globally so the
  desktop look is untouched.

### 2. Audio size: 58 MB of WAV — DONE 2026-07-29

The SFX were 53 MB of uncompressed `.wav` — a brutal browser download.
**Converted to `.ogg` and the wavs removed:**

- [x] Convert SFX `.wav` → `.ogg` — all **111** files via ffmpeg
  (`-c:a libvorbis -q:a 5`), installed with `winget install Gyan.FFmpeg`.
  Result: **53.1 MB → 3.1 MB (~17×)**.
- [x] Update every code reference — swapped `.wav` → `.ogg` across 17
  `scripts/`, 10 `scenes/` (path-only ext_resources, no uid remap needed),
  and the `index.html` gallery. Verified 0 `.wav` refs and no stale wav
  UIDs remain.
- [x] Deleted the 111 `.wav` + `.import` sidecars (53.1 MB freed). Masters
  preserved in Jessop's Desktop `threshold-deep-assets-backup` + git.
- [x] Music is `.mp3` (6.6 MB) — left as-is.

*The one step that touched code + assets. Done as its own task with a
full `.wav` grep afterward (came back clean).*

## Export steps (Godot editor)

- [ ] Project → Export → confirm the **Web** preset; install web export
  templates if prompted.
- [ ] Export Project to a folder **outside the repo** (e.g. a
  `build/web/` you keep gitignored, or a scratch dir) — the game build
  does not belong in git alongside source.
- [ ] The export **generates its own `index.html`** (the game loader)
  plus `.js`, `.wasm`, `.pck`. This is NOT our hand-written
  `index.html` — that one is the sprite/sound gallery (a dev tool). They
  never collide because the build lands in a separate folder.
- [ ] Zip the entire build folder (loader `index.html` must be at the
  zip root).

### Smoke-test the export locally (must be over HTTP, not file://)

**Double-clicking `index.html` fails** with "NetworkError when attempting
to fetch resource" — browsers block the `fetch()` Godot uses to load its
`.wasm`/`.pck` over `file://`. Serve the folder over HTTP instead. The
preset is **single-threaded** (`variant/thread_support=false`), so no
special COOP/COEP headers are needed — any static server works:

- Open a terminal *in the export folder* (File Explorer address bar →
  type `powershell` → Enter), then run **`npx serve`** (Node) or
  **`python -m http.server 8000`** (Python).
- Open the printed `http://localhost:...` URL.

(The editor's "Run in Browser" already does this over localhost — which
is why the preview works and the double-click doesn't.)

## itch.io upload

- [ ] New project → Kind: **HTML**.
- [ ] Upload the zip → tick **"This file will be played in the
  browser."**
- [ ] Tick **SharedArrayBuffer support** (this is the COOP/COEP fix —
  don't skip it, the build won't run without it).
- [ ] Set the embed viewport to the game's aspect; enable fullscreen.
- [ ] Set the page to **Draft/Restricted** first, test the playable in
  an incognito window, then flip to Public when it runs clean.
- [ ] Click-to-start is expected — browsers gate pointer-lock and audio
  behind a user gesture; Godot's loader handles it. Verify mouse capture
  (Esc toggle) and audio both come alive after the first click.

## Portfolio link (the-second-gaze, GitHub Pages)

- [ ] On The Gentle Machine's games page, add a card/link to the itch
  page (or an itch iframe embed if you want it inline).
- [ ] Nothing else in the portfolio repo changes — no build files, no
  header config, no renderer concerns. It's just a link.

## The `index.html` → `bestiary.html` rename — only if self-hosting

Not needed for the itch path. This only matters if we ever host the
build at a repo root, where the generated loader `index.html` would
clash with the gallery. If that day comes:

- [ ] Rename gallery `index.html` → `bestiary.html`; update any links
  that point at it (the `bestiary-qr.png` in `docs/` likely encodes a
  URL — regenerate the QR if the path changes).

## Pre-ship polish gate (content, not plumbing)

The plumbing above is solved. What actually decides "is it demo-ready"
is content/feel, which is the hands-on call:

- [ ] A run has a satisfying arc to a real ending (victory at 3-3).
- [ ] No obvious soft-locks or generator dead-ends in a dozen test runs.
- [ ] First-60-seconds reads well to someone who's never seen it (the
  Reddit/stranger test — no one to explain controls).
- [ ] Controls surfaced somewhere in-game (move/dash/attack, Esc, R is
  debug-only — consider hiding R for the public build).

## Feedback loop (the actual goal)

Link over lure: a browser link beats dragging people to the desk. Once
the itch demo is up, that's the artifact to drop into Reddit / share for
feedback.
