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
  *Still unset as of 2026-08-08 — `project.godot` has no
  `rendering_method` line. This is now only about EDITOR PREVIEW: the web
  export runs Compatibility whether or not the override exists, which is
  why the builds below worked without it. Setting it just lets you see
  what the browser sees without exporting.*
- [x] **Eyeball the lighting — DONE 2026-08-08, by testing rather than
  by checkbox.** Several browser runs plus one full export served over
  Node. The torch-lit dark survives Compatibility; no washing out, no
  per-renderer tuning needed. Audio, pointer lock and the first-click
  gesture all confirmed live, including the UI click on the descend
  plate (the one sound the browser could legitimately have swallowed).

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

- [ ] **Sweep stale UIDs first.** Godot loads fine with them — it falls back
  to the text path and warns in tan rather than red — but an exported build
  resolves through a baked UID cache, and a stale pointer is not something to
  discover on itch.

  **Cause:** the `.import` sidecar carries a texture's identity, not the PNG.
  Overwrite art in place and the UID survives; DELETE and re-add (or lose the
  `.import`) and Godot mints a new one while the `.tres`/`.tscn` still points
  at the old. Exporting straight onto the existing filename avoids it — but
  art sessions get fast and loose, so run the check regardless of intent
  rather than trusting the discipline.

  **Symptom:** `invalid UID: uid://… - using text path instead: res://…`,
  one per drifted file. Eight of these appeared 2026-08-12 after the dry tile
  set was redrawn — every one in `assets/tiles/dry/`.

  Reports and repairs every `.tscn`/`.tres` in the project:

  ```bash
  node -e "
  const fs=require('fs');
  function walk(d){return fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>{
    const p=d+'/'+e.name;
    if(e.isDirectory()) return e.name==='.godot'?[]:walk(p);
    return /\.(tscn|tres)$/.test(e.name)?[p]:[];});}
  let n=0;
  for(const f of walk('.').map(x=>x.replace(/^\.\//,''))){
    let s=fs.readFileSync(f,'utf8'),c=false;
    s=s.replace(/(\[ext_resource[^\]]*?uid=\")(uid:\/\/[^\"]+)(\"[^\]]*?path=\"res:\/\/)([^\"]+)(\")/g,
      (all,a,uid,b,p,z)=>{const i=p+'.import';
        if(!fs.existsSync(i)) return all;
        const r=(fs.readFileSync(i,'utf8').match(/uid=\"(uid:\/\/[^\"]+)\"/)||[])[1];
        if(!r||r===uid) return all; c=true; n++; return a+r+b+p+z;});
    if(c){fs.writeFileSync(f,s);console.log('fixed '+f);}
  }
  console.log(n+' stale uid(s) corrected');
  "
  ```

  Safe to run any time — it only rewrites UIDs that disagree with their own
  `.import`, and never touches paths.
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

> **Run and passed, 2026-08-08.** Full export served over Node and played
> in-browser. Two things that bit on the way and are worth knowing before
> the next one: **`python -m http.server` does not work on this machine** —
> `python` resolves to the Windows Store stub, which just prints "Python was
> not found." Use `npx serve` (real Node lives at `C:\Program Files\nodejs`).
> And the preset's `export_path` is `../../Godot/exports/index.html`, i.e.
> `d:\Godot\exports\` — a folder that did not exist, which Godot will not
> always create for you.

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

## Capture session — the soft-lock runs ARE the trailer runs

*Added 2026-08-12. The dozen verification runs and the footage hunt are the
same session: the itch page needs art at launch either way, and the best shots
in this game cannot be staged.*

**Rules for the session, decided before recording starts:**

- [ ] **Record continuously**, one long file per session, all twelve runs.
  Two hours costs nothing on disk. Trying to hit record when something good
  begins is exactly how the good thing gets missed.
- [ ] **Do not tune while recording.** This session is capture plus a
  soft-lock watch. Anything noticed goes on a list for AFTER the upload —
  bug-hunting, shot-hunting and art-fixing at once means all three done badly.
- [ ] **Exit condition: twelve runs, then cut with whatever exists.** Missing
  shots become a deliberate second session, not a reason to keep playing.
  "I need better footage" is the same polish loop as the tiles wearing a
  different hat, and it is much easier to justify because it feels like
  shipping work.

### Can't be staged — must be caught live

- [ ] **The secret-room reveal.** Random, x-1 floors only, needs the pale
  plank spotted and broken. The slab grinds aside over 4 s with the positional
  grind — it is the game's best single reveal and it has been happening
  unrecorded for weeks.
- [ ] **The 3-3 floor drop and amalgam assembly.** Arena floor caving,
  corpses tumbling into the chamber, three elemental amalgams rising in
  sequence. The biggest spectacle in the game, and it EXISTS ONLY at the end
  of a winning run. If twelve runs produce no 3-3 clear, film it deliberately
  rather than counting the session a failure.
- [ ] **A posted necromancer turning around** — its back to you at a bench,
  then the startle. The whole point of stations, and it needs the coven to
  land in a room that got a prop.
- [ ] **Mush fusion into a mega**, or a slime split re-merging. The ecology
  reads instantly on film and needs two bodies to meet on their own.
- [ ] **The boomerang return dragging something toward you** — the only pull
  in a game made of shoves.

### Stageable — film these in `main.tscn`, no luck required

*It is already a trailer studio: no enemies, controlled lighting, the camera
goes exactly where wanted. Anything here that shows up in a fight is a bonus,
not the plan.*

- [ ] **Cage bar-shadows sweeping the floor** as the torch moves past. The
  strongest single image the boxed props produce.
- [ ] **Walking a full circle around a table** — the per-face torchlight that
  makes flat sprites read as solid.
- [ ] **A caged specimen breathing**, and noticing you through the bars.
- [ ] Tables, tall cage and small cage together for a composition shot.

### Also worth having

- [ ] The victory report (all three effigies, full item row) — the screenshot
  most likely to end up on the itch page.
- [ ] A death report with a good killer portrait.
- [ ] Title screen with the planted sword in torchlight.
- [ ] One clean corridor walk showing height fog and an open shaft.

## Pre-ship polish gate (content, not plumbing)

The plumbing above is solved. What actually decides "is it demo-ready"
is content/feel, which is the hands-on call:

- [ ] A run has a satisfying arc to a real ending (victory at 3-3).
- [ ] No obvious soft-locks or generator dead-ends in a dozen test runs.
- [ ] First-60-seconds reads well to someone who's never seen it (the
  Reddit/stranger test — no one to explain controls).
- [x] Controls surfaced somewhere in-game — **DONE 2026-08-08.** The pause
  menu (Esc) carries the list: move / dash / look / attack / shove / pause,
  keyboard column and mouse column. **R is deliberately omitted** per this
  entry's own note; it stays a debug key and is listed nowhere a player
  reads. Right-click/shove IS listed — the off-hand torch is the mechanic
  nobody finds unaided.

## Feedback loop (the actual goal)

Link over lure: a browser link beats dragging people to the desk. Once
the itch demo is up, that's the artifact to drop into Reddit / share for
feedback.
