@echo off
cd /d "%~dp0"
echo Starting Wings of the Brotherhood Creator Studio Server on http://127.0.0.1:8765 ...
python tools\build_studio_bundles.py
start "" "http://127.0.0.1:8765/bruges_map_builder.html"
python tools\creator_server.py 8765
pause
