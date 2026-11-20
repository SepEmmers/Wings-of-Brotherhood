# Wings of the Brotherhood

A 2D top-down Zelda-like action-adventure dragon RPG set across Medieval Flanders, Brabant, and the Meuse Borderlands (built on **Godot 4.3**, GL Compatibility).

---

## Quick Start (Windows)

After cloning the repository:

1. **Run `setup.bat`** (double-click or run from a terminal):
   - Checks that your clone and runtime assets (`assets/sprites/`, `assets/hd2d/`, `assets/audio/`, `assets/shaders/`) are intact.
   - Downloads the official **Godot 4.3-stable** (`win64`) binary into `tools/godot/` if missing and verifies its SHA-512 checksum.
   - Runs a quick headless startup check to confirm all scripts and scenes load cleanly.
2. **Run `run_game.bat`** to launch **Wings of the Brotherhood**.

Optional `setup.bat` flags:
- `-Force` — Re-download and reinstall Godot 4.3-stable into `tools/godot/`.
- `-SkipVerify` — Skip the headless startup check after installing Godot.
- `-NoPause` — Never wait for Enter at exit.

---

## Controls Overview

All keybindings can be inspected and rebound in **Settings -> Controls & Keys**:

- **Move:** `WASD` / Arrow Keys (`Shift` to Sprint / Wing-Boost)
- **Interact / Advance Dialogue:** `E` / `Space` / `Enter`
- **Knife / Attack:** `V` or Left-Click
- **Cast Rope Knot:** `F` or Right-Click (`Q` to switch knot, `K` for knot practice board)
- **Dodge-Roll:** `C`
- **Dragon Companion (Book II+):** `R` (Assist / Command), `X` (Posture: Assist / Stay / Cloak-Sling)
- **Menus & Map:** `I` (Character & Bag), `Tab` / `J` (Diary & Lore), `M` (World Map), `Esc` (Pause)
- **Chapter / Scene Jump (Playtest):** `F1` or `` ` ``
- **HD-2D Diorama Regions:** `H` (toggle 2D / HD-2D), `O` (Vista / Reset), RMB/MMB drag or Arrows (orbit camera), Mouse Wheel (zoom)

---

## Optional Development & Verification Tools

- **Automated Smoke Test Suite** (41 presets across 16 regions):
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\smoke_test.ps1
  ```
- **In-Browser Creator Studio** (requires Python 3):
  Run `run_creator_studio.bat` to open `http://127.0.0.1:8765/bruges_map_builder.html`.
