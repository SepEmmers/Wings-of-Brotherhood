---
name: maintainability-audit
description: >-
  Audit workspace architecture, file sizes, GDScript compilation, asset-manifest
  sync, doc drift, and multi-agent lane boundaries for Wings of the
  Brotherhood, and keep docs/ARCHITECTURE.md current.
---

# Maintainability Audit Skill

Run this audit whenever asked to check project maintainability, enforce
standards, plan/execute modular refactors, or prevent context loss across
parallel agents.

## Steps

1. **Snapshot Workspace & Active Edits:**
   - Check file line/byte counts and recent modification timestamps across
     `scripts/`, `scenes/`, `docs/`, and `.agents/` to identify oversized
     files (`> 500` warning, `> 800` split required) and detect any files actively
     modified by sibling agents (`Main game develop`, `Narrative improvements`,
     `Assets and animations`).
   - Check whether `.git` is initialized (`git status -s`).

2. **Verify Godot 4.3 Compilation & Startup (`game-verifier`):**
   ```powershell
   Remove-Item "tools\godot_check.log" -ErrorAction SilentlyContinue
   $p = Start-Process -FilePath ".\tools\godot\Godot_v4.3-stable_win64.exe" -ArgumentList @("--headless","--verbose","--path",".","--quit-after","20","--log-file","tools\godot_check.log") -Wait -PassThru -NoNewWindow
   Get-Content "tools\godot_check.log"
   Remove-Item "tools\godot_check.log" -ErrorAction SilentlyContinue
   ```
   Confirm `ExitCode` is `0` and there are zero `ERROR:`, `USER SCRIPT ERROR:`, `SCRIPT ERROR:`, or ObjectDB leak warnings.

3. **Audit Asset & Manifest Sync:**
   - Check that every `.png` string literal referenced in `scripts/` exists in `assets/sprites/` (`PixelAssets.gd` auto-loads all `.png` files in `assets/sprites/` via `DirAccess`).
   - Compare `.wav` files in `assets/audio/` against `AMBIENCE_FILES` and `SFX_FILES` in `scripts/SoundManager.gd`.

4. **Audit Architecture & Doc Sync:**
   - Check every `scripts/regions/*Region.gd` extends `RegionBase.gd`, is routed
     in `scripts/Main.gd` (`load_region`), appears in the `[F1]` Playtest Jump
     Menu (`scripts/data/PlaytestPresets.gd`), and is listed in `docs/ARCHITECTURE.md` and
     `docs/GAME_DESIGN_DOCUMENT.md`.
   - Check `GameState.QuestStep` and `InputMap` usages match `scripts/GameState.gd`.

5. **Enforce Safe Coordination:**
   - Never refactor files that sibling agents are actively editing mid-turn
     without coordinating first; report blockers/compile errors immediately with
     exact file paths and line numbers, and keep `docs/ARCHITECTURE.md` up to date.
