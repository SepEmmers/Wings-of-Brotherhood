@echo off
setlocal
cd /d "%~dp0"

if not exist "tools\godot\Godot_v4.3-stable_win64.exe" (
    echo [ERROR] Godot 4.3-stable was not found at tools\godot\Godot_v4.3-stable_win64.exe.
    echo Please run setup.bat first to download and verify the engine.
    pause
    exit /b 1
)

start "" "tools\godot\Godot_v4.3-stable_win64.exe" --path "."
