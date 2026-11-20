"""
Local Companion HTTP Server for Wings of the Brotherhood In-Browser Creator Studio.
Serves workspace files on http://127.0.0.1:8765 and provides safe direct-write APIs:
  GET  /api/status        -> connection & workspace health
  POST /api/save_sprite   -> writes PNG directly to assets/sprites/<filename> + updates bundle
  POST /api/save_dialogue -> writes data/dialogue_overrides.json (+ optional .gd source patch)
  POST /api/save_dungeon  -> writes data/custom_dungeon.json (+ updates dungeons_bundle.js)
  POST /api/save_map_gd   -> writes generated *MapData.gd to scripts/regions/
  POST /api/rebuild       -> re-runs build_studio_bundles.py
"""

import base64
import json
import os
import re
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SPRITES_DIR = os.path.join(ROOT, "assets", "sprites")
DATA_DIR = os.path.join(ROOT, "data")
SCRIPTS_DIR = os.path.join(ROOT, "scripts")
TOOLS_DIR = os.path.join(ROOT, "tools")

sys.path.insert(0, TOOLS_DIR)
import build_studio_bundles


def safe_rel_path(base_dir, rel_name):
    clean = os.path.basename(rel_name.strip())
    if not clean or clean in (".", ".."):
        return None
    full = os.path.abspath(os.path.join(base_dir, clean))
    if not full.startswith(os.path.abspath(base_dir) + os.sep):
        return None
    return full


def _patch_gd_line(rel_file, approx_line, old_text, new_text, speaker_old, speaker_new, tele_new, is_bark=False):
    norm_rel = rel_file.replace("\\", "/")
    if not norm_rel.startswith("scripts/") or not norm_rel.endswith(".gd"):
        return False
    full = os.path.abspath(os.path.join(ROOT, norm_rel))
    if not full.startswith(os.path.abspath(SCRIPTS_DIR) + os.sep) or not os.path.isfile(full):
        return False
    if "%PLAYER%" in new_text or "%DRAGON%" in new_text or "%PLAYER%" in old_text or "%DRAGON%" in old_text:
        # Templated format lines stay preserved in GDScript and use data/dialogue_overrides.json at runtime
        return False

    with open(full, "r", encoding="utf-8") as f:
        lines = f.readlines()

    idx = max(0, min(len(lines) - 1, int(approx_line) - 1))
    search_indices = [idx] + [i for i in range(max(0, idx - 3), min(len(lines), idx + 4)) if i != idx]
    esc_old = old_text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    esc_new = new_text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    key = "bark" if is_bark else "text"
    target_pat = f'"{key}": "{esc_old}"'
    alt_pat = f'"{key}":"{esc_old}"'

    for li in search_indices:
        ln = lines[li]
        if target_pat in ln or alt_pat in ln:
            updated = ln.replace(target_pat, f'"{key}": "{esc_new}"').replace(alt_pat, f'"{key}": "{esc_new}"')
            if not is_bark and speaker_new and speaker_old and f'"speaker": "{speaker_old}"' in updated:
                esc_s_old = speaker_old.replace('"', '\\"')
                esc_s_new = speaker_new.replace('"', '\\"')
                updated = updated.replace(f'"speaker": "{esc_s_old}"', f'"speaker": "{esc_s_new}"')
            if updated != ln:
                lines[li] = updated
                with open(full, "w", encoding="utf-8") as wf:
                    wf.writelines(lines)
                return True
    return False


class StudioHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def _send_json(self, code, payload):
        raw = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def _read_json_body(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0 or length > 20 * 1024 * 1024:
            return None
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/status":
            self._send_json(200, {
                "ok": True,
                "mode": "live_workspace",
                "root": ROOT,
            })
            return
        if parsed.path == "/api/custom_dungeon":
            dpath = os.path.join(DATA_DIR, "custom_dungeon.json")
            if os.path.isfile(dpath):
                with open(dpath, "r", encoding="utf-8") as f:
                    self._send_json(200, {"ok": True, "dungeon": json.load(f)})
            else:
                self._send_json(404, {"ok": False, "error": "custom_dungeon.json not found"})
            return
        if parsed.path == "/api/dialogue_overrides":
            opath = os.path.join(DATA_DIR, "dialogue_overrides.json")
            if os.path.isfile(opath):
                with open(opath, "r", encoding="utf-8") as f:
                    self._send_json(200, {"ok": True, "data": json.load(f)})
            else:
                self._send_json(200, {"ok": True, "data": {"overrides": {}, "custom_sequences": {}}})
            return
        super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)
        try:
            body = self._read_json_body()
            if body is None:
                self._send_json(400, {"ok": False, "error": "Invalid or empty JSON payload"})
                return

            if parsed.path == "/api/save_sprite":
                fname = str(body.get("filename", "")).strip()
                if not fname.lower().endswith(".png"):
                    fname += ".png"
                if not re.match(r"^[A-Za-z0-9_\-\.]+\.png$", fname):
                    self._send_json(400, {"ok": False, "error": "Invalid filename"})
                    return
                target = safe_rel_path(SPRITES_DIR, fname)
                data_url = str(body.get("data_url", ""))
                if not target or not data_url.startswith("data:image/png;base64,"):
                    self._send_json(400, {"ok": False, "error": "Expected PNG base64 data_url"})
                    return
                png_bytes = base64.b64decode(data_url.split(",", 1)[1])
                os.makedirs(SPRITES_DIR, exist_ok=True)
                with open(target, "wb") as f:
                    f.write(png_bytes)
                build_studio_bundles.build_sprites_bundle()
                self._send_json(200, {"ok": True, "filename": fname, "bytes": len(png_bytes)})
                return

            if parsed.path == "/api/save_dialogue":
                os.makedirs(DATA_DIR, exist_ok=True)
                overrides = body.get("overrides", {})
                custom_sequences = body.get("custom_sequences", {})
                patch_source = bool(body.get("patch_source", False))
                opath = os.path.join(DATA_DIR, "dialogue_overrides.json")
                with open(opath, "w", encoding="utf-8") as f:
                    json.dump({"overrides": overrides, "custom_sequences": custom_sequences}, f, indent=2, ensure_ascii=False)

                patched_count = 0
                if patch_source and isinstance(overrides, dict):
                    for _, ov in overrides.items():
                        if isinstance(ov, dict) and ov.get("file"):
                            if _patch_gd_line(
                                ov.get("file", ""),
                                ov.get("line", 1),
                                ov.get("orig_text", ""),
                                ov.get("text", ""),
                                ov.get("orig_speaker", ""),
                                ov.get("speaker", ""),
                                ov.get("telepathic", False),
                                ov.get("kind", "dialogue") == "bark",
                            ):
                                patched_count += 1
                    if patched_count > 0:
                        build_studio_bundles.build_dialogue_bundle()

                self._send_json(200, {
                    "ok": True,
                    "override_count": len(overrides),
                    "sequence_count": len(custom_sequences),
                    "patched_gd_count": patched_count,
                })
                return

            if parsed.path == "/api/save_dungeon":
                dungeon = body.get("dungeon")
                if not isinstance(dungeon, dict):
                    self._send_json(400, {"ok": False, "error": "Missing dungeon object"})
                    return
                os.makedirs(DATA_DIR, exist_ok=True)
                dpath = os.path.join(DATA_DIR, "custom_dungeon.json")
                with open(dpath, "w", encoding="utf-8") as f:
                    json.dump(dungeon, f, indent=2, ensure_ascii=False)
                self._send_json(200, {"ok": True, "path": "data/custom_dungeon.json"})
                return

            if parsed.path == "/api/save_map_gd":
                fname = str(body.get("filename", "")).strip()
                content = str(body.get("content", ""))
                if not fname.endswith(".gd") or not re.match(r"^[A-Za-z0-9_]+\.gd$", fname):
                    self._send_json(400, {"ok": False, "error": "Invalid .gd filename"})
                    return
                reg_dir = os.path.join(SCRIPTS_DIR, "regions")
                target = safe_rel_path(reg_dir, fname)
                if not target:
                    self._send_json(400, {"ok": False, "error": "Blocked target path"})
                    return
                with open(target, "w", encoding="utf-8") as f:
                    f.write(content)
                self._send_json(200, {"ok": True, "path": f"scripts/regions/{fname}"})
                return

            if parsed.path == "/api/rebuild":
                build_studio_bundles.main()
                self._send_json(200, {"ok": True})
                return

            self._send_json(404, {"ok": False, "error": "Unknown API endpoint"})
        except Exception as exc:
            self._send_json(500, {"ok": False, "error": str(exc)})


def run_server(port=8765):
    server = ThreadingHTTPServer(("127.0.0.1", port), StudioHandler)
    print(f"Temeraire Creator Studio Server running at http://127.0.0.1:{port}/bruges_map_builder.html")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    p = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    run_server(p)
