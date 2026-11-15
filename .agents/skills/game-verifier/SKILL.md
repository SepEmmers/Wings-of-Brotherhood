---
name: game-verifier
description: >-
  Run headless Godot 4.3 compilation, scene loading, and script validation checks
  and inspect logs to confirm zero parse or runtime startup errors after editing
  GDScript or .tscn files.
---

# Game Verifier Skill

Validates that the Godot 4.3 project compiles all GDScript files and loads
`scenes/Main.tscn` cleanly.

## Steps

1. Run Godot 4.3 headless verification with a log file:
   ```powershell
   Remove-Item "tools\godot_check.log" -ErrorAction SilentlyContinue
   $p = Start-Process -FilePath ".\tools\godot\Godot_v4.3-stable_win64.exe" -ArgumentList "--headless","--path",".","--quit-after","20","--log-file","tools\godot_check.log" -Wait -PassThru
   Get-Content "tools\godot_check.log"
   ```
2. Confirm `ExitCode` is `0` and `tools\godot_check.log` contains **zero**
   `ERROR:` or `USER SCRIPT ERROR:` lines.
3. Remove `tools\godot_check.log` after verification.

## Full Smoke Suite & Windows PowerShell Gotchas

- **Full Smoke Suite:** After region, portal, preset, UI/dialogue, or progression changes, also run:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\smoke_test.ps1
  ```
  Confirm `SMOKE_PASS` and zero errors across presets, regions, and portals.
- **Windows / PowerShell 5.1 Execution Rules:**
  - Always launch `.\tools\godot\Godot_v4.3-stable_win64.exe` via `Start-Process ... -Wait -PassThru` — never invoke `Godot_v4.3-stable_win64_console.exe` (which fails on Windows with error 193) and never run the `.exe` bare without waiting for exit.
  - Chain commands with `;` instead of `&&` in Windows PowerShell 5.1, and use `Select-String` or `python` instead of `rg`.
