// Pixel Art & Modular Kit Studio for Wings of the Brotherhood
window.initPixelStudio = function (rootEl) {
  "use strict";

  const PAL = window.STUDIO_PALETTE || [];
  const RAMPS = window.STUDIO_RAMPS || [];
  const BUNDLE = window.STUDIO_SPRITES_BUNDLE || {};

  let curName = "boy_down_0.png";
  let curW = 24;
  let curH = 28;
  let pixels = new Uint8ClampedArray(curW * curH * 4);
  let zoom = 16;
  let tool = "pencil"; // pencil | eraser | fill | line | rect | picker | shade
  let activeRgba = [252, 208, 92, 255]; // Y2 Gold default
  let mirrorX = false;
  let mirrorY = false;
  let showGrid = true;
  let showTileGrid = false;
  let showOnion = false;
  let backdrop = "checker"; // checker | dark | grass | cobble | water
  let shadeDir = 1; // +1 lighten, -1 darken

  let undoStack = [];
  let redoStack = [];
  let previewFrames = [];
  let animPlaying = true;
  let animFps = 5;
  let animTick = 0;
  let animFrameIdx = 0;

  // Build HTML UI
  rootEl.innerHTML = `
    <div class="st-shell">
      <div class="st-toolbar">
        <span class="brand">Pixel Art &amp; Kit Studio</span>
        <label class="inline">File: <input type="text" id="pxFileName" value="${curName}" style="width:170px;" /></label>
        <button id="pxNewBtn">+ New Sprite</button>
        <select id="pxTplSelect" title="Modular Kit Templates">
          <option value="">Kit Template...</option>
          <option value="carry_16">Carry Prop (16x16)</option>
          <option value="npc_24x28">Character / NPC (24x28)</option>
          <option value="portrait_48">Portrait w/ Brass Frame (48x48)</option>
          <option value="dungeon_36">Dungeon Prop (36x36)</option>
          <option value="tile_32">World Tile (32x32)</option>
        </select>
        <div class="sep"></div>
        <div class="btn-group" id="pxTools">
          <button data-tool="pencil" class="active" title="Pencil (B)">Pencil</button>
          <button data-tool="eraser" title="Eraser (E)">Eraser</button>
          <button data-tool="fill" title="Bucket Fill (G)">Fill</button>
          <button data-tool="line" title="Line (L)">Line</button>
          <button data-tool="rect" title="Rectangle (U)">Rect</button>
          <button data-tool="picker" title="Eyedropper (I)">Pick</button>
          <button data-tool="shade" title="PAL Ramp Shade (S)">Shade</button>
        </div>
        <button id="pxShadeDirBtn" title="Toggle Lighten / Darken for Shade Brush">+Light</button>
        <div class="sep"></div>
        <label class="inline"><input type="checkbox" id="pxMirX" /> Mir-X</label>
        <label class="inline"><input type="checkbox" id="pxMirY" /> Mir-Y</label>
        <label class="inline"><input type="checkbox" id="pxGridChk" checked /> Grid</label>
        <label class="inline"><input type="checkbox" id="pxTileChk" /> 16px</label>
        <label class="inline"><input type="checkbox" id="pxOnionChk" /> Onion</label>
        <select id="pxBgSel" title="Canvas Backdrop">
          <option value="checker">Checker</option>
          <option value="dark">Void Night</option>
          <option value="grass">Meadow Grass</option>
          <option value="cobble">Bruges Cobble</option>
          <option value="water">Zwin Water</option>
        </select>
        <div class="sep"></div>
        <button id="pxOutlineBtn" title="Wrap sprite in 1px Warm Ink Outline (#1b171d)">1px Outline</button>
        <button id="pxShadowBtn" title="Add semi-transparent elliptical drop shadow at bottom">Drop Shadow</button>
        <button id="pxFlipHBtn" title="Flip Horizontal">Flip H</button>
        <button id="pxFlipVBtn" title="Flip Vertical">Flip V</button>
        <button id="pxRotBtn" title="Rotate 90 deg">Rot 90°</button>
        <div class="sep"></div>
        <button id="pxUndoBtn" title="Undo (Ctrl+Z)">Undo</button>
        <button id="pxRedoBtn" title="Redo (Ctrl+Y)">Redo</button>
        <button id="pxSaveGameBtn" class="primary" title="Write PNG directly to assets/sprites/">Save to Game</button>
        <button id="pxDownloadBtn">Download .png</button>
        <button id="pxImportBtn">Import .png</button>
        <input type="file" id="pxImportFile" accept="image/png" style="display:none" />
        <button id="pxPyExportBtn">Python PAL</button>
      </div>

      <div class="st-body">
        <div class="st-left">
          <div class="panel-header"><span>Sprite Library (${Object.keys(BUNDLE).length})</span></div>
          <div style="padding:6px 8px;display:flex;flex-direction:column;gap:5px;border-bottom:1px solid var(--border);">
            <input type="text" id="pxSearch" placeholder="Search 832 sprites..." />
            <select id="pxCatSel"><option value="ALL">All Categories</option></select>
          </div>
          <div class="scroll-area" id="pxLibGrid"></div>
        </div>

        <div class="st-center" style="display:flex;flex-direction:column;min-width:0;">
          <div id="pxCanvasHost" style="flex:1;overflow:auto;display:flex;align-items:center;justify-content:center;background:#100f14;position:relative;padding:24px;">
            <canvas id="pxEditCanvas" style="image-rendering:pixelated;box-shadow:0 8px 32px rgba(0,0,0,0.75);cursor:crosshair;"></canvas>
          </div>
          <div class="st-statusbar">
            <div>
              Sprite: <b id="pxStatInfo">24×28</b> |
              Pixel: <b id="pxStatCursor">-</b> |
              Zoom: <b id="pxStatZoom">16×</b>
              <button id="pxZoomOut" style="padding:1px 6px;margin-left:6px;">-</button>
              <button id="pxZoomIn" style="padding:1px 6px;">+</button>
            </div>
            <div id="pxStatMsg" style="color:var(--accent);">Ready — Left-click draw, Right-click erase/pick</div>
          </div>
        </div>

        <div class="st-right">
          <div class="panel-header">
            <span>32-Color Flemish Palette</span>
            <input type="color" id="pxCustomColor" value="#fcd05c" title="Custom RGB Color" style="width:28px;height:20px;padding:0;border:1px solid var(--border);" />
          </div>
          <div style="padding:6px 8px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px;">
            <div id="pxActiveSwatch" style="width:26px;height:26px;border-radius:4px;border:2px solid #fff;"></div>
            <div style="font-size:11px;">
              <div id="pxActiveName" style="font-weight:700;color:var(--accent);">Y2 — Bright Gold</div>
              <div id="pxActiveHex" style="color:var(--muted);">#fcd05c</div>
            </div>
          </div>
          <div class="scroll-area" id="pxPalContainer" style="max-height:310px;border-bottom:1px solid var(--border);"></div>

          <div class="panel-header">
            <span>Live Animation Preview</span>
            <button id="pxAnimToggle" style="padding:1px 6px;font-size:10px;">Pause</button>
          </div>
          <div style="padding:8px;display:flex;flex-direction:column;gap:6px;">
            <div style="display:flex;align-items:center;justify-content:space-around;background:#141318;border:1px solid var(--border);border-radius:4px;padding:8px;">
              <canvas id="pxPrev1x" width="48" height="48" style="image-rendering:pixelated;"></canvas>
              <canvas id="pxPrev2x" width="96" height="96" style="image-rendering:pixelated;"></canvas>
            </div>
            <label class="inline" style="justify-content:space-between;">
              <span>FPS: <b id="pxFpsLbl">5</b></span>
              <input type="range" id="pxFpsRange" min="1" max="15" value="5" style="width:140px;" />
            </label>
            <div id="pxFrameStrip" style="display:flex;gap:4px;flex-wrap:wrap;"></div>
          </div>
        </div>
      </div>
    </div>
  `;

  // Populate Categories
  const cats = Array.from(new Set(Object.values(BUNDLE).map(s => s.cat || "Other"))).sort();
  const catSel = document.getElementById("pxCatSel");
  for (const c of cats) {
    const opt = document.createElement("option");
    opt.value = c;
    opt.textContent = c;
    catSel.appendChild(opt);
  }

  function findPalMatch(r, g, b, a) {
    if (a < 16) return { key: ".", hex: "transparent" };
    let best = null;
    let bestDist = Infinity;
    for (const p of PAL) {
      const dr = p.rgba[0] - r, dg = p.rgba[1] - g, db = p.rgba[2] - b;
      const d = dr * dr + dg * dg + db * db;
      if (d < bestDist) { bestDist = d; best = p; }
    }
    return best && bestDist <= 12 ? best : { key: "CUSTOM", hex: `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}` };
  }

  function setStatus(msg) {
    const el = document.getElementById("pxStatMsg");
    if (el) el.textContent = msg;
  }

  function setActiveColor(rgba, label) {
    activeRgba = [...rgba];
    const hex = `#${rgba[0].toString(16).padStart(2, "0")}${rgba[1].toString(16).padStart(2, "0")}${rgba[2].toString(16).padStart(2, "0")}`;
    document.getElementById("pxActiveSwatch").style.background = hex;
    document.getElementById("pxCustomColor").value = hex;
    const match = findPalMatch(rgba[0], rgba[1], rgba[2], 255);
    document.getElementById("pxActiveName").textContent = label || (match.key !== "CUSTOM" ? `${match.key} (${match.group || "PAL"})` : "Custom RGB");
    document.getElementById("pxActiveHex").textContent = hex;
    document.querySelectorAll(".px-swatch").forEach(s => s.classList.toggle("selected", s.dataset.hex === hex));
  }

  function renderPalette() {
    const host = document.getElementById("pxPalContainer");
    host.innerHTML = "";
    const byKey = new Map(PAL.map(p => [p.key, p]));
    for (const r of RAMPS) {
      const title = document.createElement("div");
      title.style.cssText = "font-size:10px;color:var(--muted);margin:5px 0 2px;font-weight:700;text-transform:uppercase;";
      title.textContent = r.name;
      host.appendChild(title);
      const row = document.createElement("div");
      row.style.cssText = "display:flex;flex-wrap:wrap;gap:3px;";
      for (const k of r.keys) {
        const p = byKey.get(k);
        if (!p) continue;
        const sw = document.createElement("button");
        sw.className = "px-swatch";
        sw.dataset.hex = p.hex;
        sw.title = `${p.key} (${p.hex})`;
        sw.style.cssText = `width:20px;height:20px;padding:0;border-radius:3px;background:${p.hex};border:1px solid rgba(255,255,255,0.28);`;
        sw.onclick = () => setActiveColor(p.rgba, `${p.key} (${r.name})`);
        row.appendChild(sw);
      }
      host.appendChild(row);
    }
    setActiveColor(activeRgba);
  }

  function pushUndo() {
    undoStack.push({ w: curW, h: curH, data: new Uint8ClampedArray(pixels) });
    if (undoStack.length > 50) undoStack.shift();
    redoStack = [];
  }

  function undo() {
    if (!undoStack.length) return;
    redoStack.push({ w: curW, h: curH, data: new Uint8ClampedArray(pixels) });
    const prev = undoStack.pop();
    curW = prev.w; curH = prev.h; pixels = prev.data;
    drawEditorCanvas();
  }

  function redo() {
    if (!redoStack.length) return;
    undoStack.push({ w: curW, h: curH, data: new Uint8ClampedArray(pixels) });
    const nxt = redoStack.pop();
    curW = nxt.w; curH = nxt.h; pixels = nxt.data;
    drawEditorCanvas();
  }

  function loadSprite(fname) {
    const rec = BUNDLE[fname];
    if (!rec) return;
    curName = fname;
    document.getElementById("pxFileName").value = fname;
    const img = new Image();
    img.onload = () => {
      curW = img.width || rec.w || 24;
      curH = img.height || rec.h || 28;
      const tmp = document.createElement("canvas");
      tmp.width = curW; tmp.height = curH;
      const tctx = tmp.getContext("2d");
      tctx.drawImage(img, 0, 0);
      pixels = new Uint8ClampedArray(tctx.getImageData(0, 0, curW, curH).data);
      undoStack = []; redoStack = [];
      zoom = Math.max(4, Math.min(24, Math.floor(420 / Math.max(curW, curH))));
      discoverAnimationFrames(fname);
      drawEditorCanvas();
      renderLibrary();
      setStatus(`Loaded ${fname} (${curW}×${curH})`);
    };
    img.src = rec.b64;
  }

  function createBlankSprite(w, h, templateId = "") {
    pushUndo();
    curW = Math.max(4, Math.min(256, w));
    curH = Math.max(4, Math.min(256, h));
    pixels = new Uint8ClampedArray(curW * curH * 4);
    const setPx = (x, y, r, g, b, a = 255) => {
      if (x < 0 || y < 0 || x >= curW || y >= curH) return;
      const idx = (y * curW + x) * 4;
      pixels[idx] = r; pixels[idx + 1] = g; pixels[idx + 2] = b; pixels[idx + 3] = a;
    };
    if (templateId === "portrait_48") {
      curName = "portrait_custom.png";
      for (let x = 0; x < 48; x++) for (let y = 0; y < 48; y++) {
        if (x === 0 || y === 0 || x === 47 || y === 47) setPx(x, y, 27, 23, 29);
        else if (x === 1 || y === 1 || x === 46 || y === 46) setPx(x, y, 226, 152, 48);
        else if (x === 2 || y === 2 || x === 45 || y === 45) setPx(x, y, 178, 104, 28);
        else setPx(x, y, 32, 30, 42);
      }
    } else if (templateId === "npc_24x28") {
      curName = "npc_custom_0.png";
      for (let y = 23; y <= 26; y++) for (let x = 7; x <= 16; x++) {
        if ((x - 11.5) ** 2 / 25 + (y - 24.5) ** 2 / 4 <= 1) setPx(x, y, 14, 12, 18, 90);
      }
    } else if (templateId === "carry_16") {
      curName = "prop_custom_carry.png";
    } else if (templateId === "dungeon_36") {
      curName = "prop_custom_dungeon.png";
    } else if (templateId === "tile_32") {
      curName = "tile_custom.png";
      for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) setPx(x, y, 68, 63, 67);
    }
    document.getElementById("pxFileName").value = curName;
    zoom = Math.max(4, Math.min(24, Math.floor(420 / Math.max(curW, curH))));
    previewFrames = [{ name: curName, b64: bufferToDataUrl() }];
    drawEditorCanvas();
  }

  function discoverAnimationFrames(fname) {
    previewFrames = [];
    const baseBlink = fname.replace(/(_blink)?\.png$/, "");
    if (BUNDLE[baseBlink + ".png"] && BUNDLE[baseBlink + "_blink.png"]) {
      previewFrames = [
        { name: baseBlink + ".png", b64: BUNDLE[baseBlink + ".png"].b64 },
        { name: baseBlink + ".png", b64: BUNDLE[baseBlink + ".png"].b64 },
        { name: baseBlink + ".png", b64: BUNDLE[baseBlink + ".png"].b64 },
        { name: baseBlink + "_blink.png", b64: BUNDLE[baseBlink + "_blink.png"].b64 },
      ];
    } else {
      const m = fname.match(/^(.*)_(\d+)\.png$/);
      if (m) {
        const stem = m[1];
        for (let i = 0; i <= 4; i++) {
          const cand = `${stem}_${i}.png`;
          if (BUNDLE[cand]) previewFrames.push({ name: cand, b64: BUNDLE[cand].b64 });
        }
      }
    }
    if (!previewFrames.length) previewFrames = [{ name: fname, b64: BUNDLE[fname]?.b64 || bufferToDataUrl() }];
    const strip = document.getElementById("pxFrameStrip");
    strip.innerHTML = "";
    const uniq = Array.from(new Map(previewFrames.map(f => [f.name, f])).values());
    for (const fr of uniq) {
      const btn = document.createElement("button");
      btn.style.cssText = "padding:2px 5px;font-size:10px;";
      btn.textContent = fr.name.replace(".png", "");
      if (fr.name === curName) btn.classList.add("active");
      btn.onclick = () => loadSprite(fr.name);
      strip.appendChild(btn);
    }
  }

  function bufferToDataUrl() {
    const tmp = document.createElement("canvas");
    tmp.width = curW; tmp.height = curH;
    const tctx = tmp.getContext("2d");
    tctx.putImageData(new ImageData(pixels, curW, curH), 0, 0);
    return tmp.toDataURL("image/png");
  }

  function renderLibrary() {
    const q = (document.getElementById("pxSearch").value || "").toLowerCase().trim();
    const cat = document.getElementById("pxCatSel").value;
    const grid = document.getElementById("pxLibGrid");
    grid.innerHTML = "";
    const names = Object.keys(BUNDLE).filter(fn => {
      if (cat !== "ALL" && BUNDLE[fn].cat !== cat) return false;
      if (q && !fn.toLowerCase().includes(q)) return false;
      return true;
    });
    const listWrap = document.createElement("div");
    listWrap.style.cssText = "display:grid;grid-template-columns:1fr 1fr;gap:5px;";
    const maxShow = 120;
    for (const fn of names.slice(0, maxShow)) {
      const rec = BUNDLE[fn];
      const card = document.createElement("div");
      card.className = "palette-item" + (fn === curName ? " selected" : "");
      card.innerHTML = `<div class="palette-thumb"><img src="${rec.b64}" /></div><div class="palette-name" style="font-size:10px;word-break:break-all;">${fn.replace(".png", "")}</div><div class="palette-dim">${rec.w}×${rec.h}</div>`;
      card.onclick = () => loadSprite(fn);
      listWrap.appendChild(card);
    }
    grid.appendChild(listWrap);
    if (names.length > maxShow) {
      const note = document.createElement("div");
      note.style.cssText = "padding:8px;text-align:center;color:var(--muted);font-size:11px;";
      note.textContent = `Showing ${maxShow} of ${names.length} matches — narrow search to filter.`;
      grid.appendChild(note);
    }
  }

  const editCanvas = document.getElementById("pxEditCanvas");
  const ectx = editCanvas.getContext("2d");
  let previewOverlay = null; // array of {x, y, rgba} for line/rect drag
  let onionImg = null;

  function drawEditorCanvas() {
    const cw = curW * zoom;
    const ch = curH * zoom;
    if (editCanvas.width !== cw || editCanvas.height !== ch) {
      editCanvas.width = cw;
      editCanvas.height = ch;
    }
    document.getElementById("pxStatInfo").textContent = `${curW}×${curH}`;
    document.getElementById("pxStatZoom").textContent = `${zoom}×`;

    // Backdrop
    if (backdrop === "checker") {
      const sq = Math.max(4, Math.floor(zoom / 2));
      for (let y = 0; y < ch; y += sq) for (let x = 0; x < cw; x += sq) {
        ectx.fillStyle = ((Math.floor(x / sq) + Math.floor(y / sq)) % 2 === 0) ? "#23212a" : "#1a1820";
        ectx.fillRect(x, y, sq, sq);
      }
    } else {
      const bgMap = { dark: "#0e0c12", grass: "#385a31", cobble: "#423e46", water: "#1e445e" };
      ectx.fillStyle = bgMap[backdrop] || "#1a1820";
      ectx.fillRect(0, 0, cw, ch);
    }

    // Onion skin (adjacent frame)
    if (showOnion && previewFrames.length > 1) {
      const other = previewFrames.find(f => f.name !== curName) || previewFrames[0];
      if (other && (!onionImg || onionImg._src !== other.b64)) {
        onionImg = new Image();
        onionImg._src = other.b64;
        onionImg.src = other.b64;
      }
      if (onionImg && onionImg.complete) {
        ectx.save();
        ectx.globalAlpha = 0.28;
        ectx.imageSmoothingEnabled = false;
        ectx.drawImage(onionImg, 0, 0, cw, ch);
        ectx.restore();
      }
    }

    // Draw pixels
    const tmp = document.createElement("canvas");
    tmp.width = curW; tmp.height = curH;
    tmp.getContext("2d").putImageData(new ImageData(pixels, curW, curH), 0, 0);
    ectx.imageSmoothingEnabled = false;
    ectx.drawImage(tmp, 0, 0, cw, ch);

    // Line/Rect preview
    if (previewOverlay) {
      for (const p of previewOverlay) {
        ectx.fillStyle = `rgba(${p.rgba[0]},${p.rgba[1]},${p.rgba[2]},0.75)`;
        ectx.fillRect(p.x * zoom, p.y * zoom, zoom, zoom);
      }
    }

    // Symmetry guides
    if (mirrorX) {
      ectx.strokeStyle = "rgba(221,168,76,0.65)";
      ectx.lineWidth = 2;
      ectx.beginPath(); ectx.moveTo(cw * 0.5, 0); ectx.lineTo(cw * 0.5, ch); ectx.stroke();
    }
    if (mirrorY) {
      ectx.strokeStyle = "rgba(140,180,245,0.65)";
      ectx.lineWidth = 2;
      ectx.beginPath(); ectx.moveTo(0, ch * 0.5); ectx.lineTo(cw, ch * 0.5); ectx.stroke();
    }

    // Grids
    if (showGrid && zoom >= 5) {
      ectx.strokeStyle = "rgba(255,255,255,0.08)";
      ectx.lineWidth = 1;
      ectx.beginPath();
      for (let x = 1; x < curW; x++) { ectx.moveTo(x * zoom + 0.5, 0); ectx.lineTo(x * zoom + 0.5, ch); }
      for (let y = 1; y < curH; y++) { ectx.moveTo(0, y * zoom + 0.5); ectx.lineTo(cw, y * zoom + 0.5); }
      ectx.stroke();
    }
    if (showTileGrid) {
      ectx.strokeStyle = "rgba(252,208,92,0.32)";
      ectx.lineWidth = 1;
      ectx.beginPath();
      for (let x = 8; x < curW; x += 8) { ectx.moveTo(x * zoom + 0.5, 0); ectx.lineTo(x * zoom + 0.5, ch); }
      for (let y = 8; y < curH; y += 8) { ectx.moveTo(0, y * zoom + 0.5); ectx.lineTo(cw, y * zoom + 0.5); }
      ectx.stroke();
    }
  }

  function getPx(x, y) {
    if (x < 0 || y < 0 || x >= curW || y >= curH) return [0, 0, 0, 0];
    const i = (y * curW + x) * 4;
    return [pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3]];
  }

  function putPxRaw(x, y, rgba) {
    if (x < 0 || y < 0 || x >= curW || y >= curH) return;
    const i = (y * curW + x) * 4;
    pixels[i] = rgba[0]; pixels[i + 1] = rgba[1]; pixels[i + 2] = rgba[2]; pixels[i + 3] = rgba[3];
  }

  function putPxSym(x, y, rgba) {
    putPxRaw(x, y, rgba);
    if (mirrorX) putPxRaw(curW - 1 - x, y, rgba);
    if (mirrorY) putPxRaw(x, curH - 1 - y, rgba);
    if (mirrorX && mirrorY) putPxRaw(curW - 1 - x, curH - 1 - y, rgba);
  }

  function applyShadeBrush(x, y) {
    const cur = getPx(x, y);
    if (cur[3] < 16) return;
    const match = findPalMatch(cur[0], cur[1], cur[2], cur[3]);
    if (match.key !== "CUSTOM") {
      for (const r of RAMPS) {
        const idx = r.keys.indexOf(match.key);
        if (idx !== -1) {
          const nextIdx = Math.max(0, Math.min(r.keys.length - 1, idx + shadeDir));
          const p = PAL.find(x => x.key === r.keys[nextIdx]);
          if (p) { putPxRaw(x, y, p.rgba); return; }
        }
      }
    }
    const d = shadeDir * 18;
    putPxRaw(x, y, [Math.max(0, Math.min(255, cur[0] + d)), Math.max(0, Math.min(255, cur[1] + d)), Math.max(0, Math.min(255, cur[2] + d)), cur[3]]);
  }

  function floodFill(sx, sy, fillRgba) {
    const tgt = getPx(sx, sy);
    if (tgt[0] === fillRgba[0] && tgt[1] === fillRgba[1] && tgt[2] === fillRgba[2] && tgt[3] === fillRgba[3]) return;
    const stack = [[sx, sy]];
    const seen = new Uint8Array(curW * curH);
    while (stack.length) {
      const [cx, cy] = stack.pop();
      if (cx < 0 || cy < 0 || cx >= curW || cy >= curH) continue;
      const si = cy * curW + cx;
      if (seen[si]) continue;
      const p = getPx(cx, cy);
      if (p[0] !== tgt[0] || p[1] !== tgt[1] || p[2] !== tgt[2] || p[3] !== tgt[3]) continue;
      seen[si] = 1;
      putPxRaw(cx, cy, fillRgba);
      stack.push([cx + 1, cy], [cx - 1, cy], [cx, cy + 1], [cx, cy - 1]);
    }
  }

  function bresenham(x0, y0, x1, y1) {
    const pts = [];
    let dx = Math.abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    let dy = -Math.abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    let err = dx + dy;
    while (true) {
      pts.push([x0, y0]);
      if (x0 === x1 && y0 === y1) break;
      const e2 = 2 * err;
      if (e2 >= dy) { err += dy; x0 += sx; }
      if (e2 <= dx) { err += dx; y0 += sy; }
    }
    return pts;
  }

  // Pointer Painting
  let painting = false;
  let paintBtn = 0;
  let startPt = null;
  let lastPt = null;

  function clientToPx(ev) {
    const r = editCanvas.getBoundingClientRect();
    return [Math.floor((ev.clientX - r.left) / zoom), Math.floor((ev.clientY - r.top) / zoom)];
  }

  editCanvas.addEventListener("contextmenu", e => e.preventDefault());
  editCanvas.addEventListener("mousedown", e => {
    const [px, py] = clientToPx(e);
    if (px < 0 || py < 0 || px >= curW || py >= curH) return;
    paintBtn = e.button;
    if (e.button === 2 && e.altKey) {
      const c = getPx(px, py);
      if (c[3] > 0) setActiveColor(c);
      return;
    }
    if (tool === "picker" && e.button === 0) {
      const c = getPx(px, py);
      if (c[3] > 0) setActiveColor(c);
      return;
    }
    pushUndo();
    painting = true;
    startPt = [px, py];
    lastPt = [px, py];
    const rgba = (e.button === 2 || tool === "eraser") ? [0, 0, 0, 0] : activeRgba;
    if (tool === "fill") {
      floodFill(px, py, rgba);
      painting = false;
      drawEditorCanvas();
    } else if (tool === "shade" && e.button === 0) {
      applyShadeBrush(px, py);
      drawEditorCanvas();
    } else if (tool === "line" || tool === "rect") {
      previewOverlay = [{ x: px, y: py, rgba }];
      drawEditorCanvas();
    } else {
      putPxSym(px, py, rgba);
      drawEditorCanvas();
    }
  });

  window.addEventListener("mousemove", e => {
    if (e.target === editCanvas) {
      const [px, py] = clientToPx(e);
      if (px >= 0 && py >= 0 && px < curW && py < curH) {
        const c = getPx(px, py);
        const m = findPalMatch(c[0], c[1], c[2], c[3]);
        document.getElementById("pxStatCursor").textContent = `${px},${py} (${m.key})`;
      }
    }
    if (!painting) return;
    const [px, py] = clientToPx(e);
    const rgba = (paintBtn === 2 || tool === "eraser") ? [0, 0, 0, 0] : activeRgba;
    if (tool === "line") {
      previewOverlay = bresenham(startPt[0], startPt[1], px, py).map(([x, y]) => ({ x, y, rgba }));
      drawEditorCanvas();
    } else if (tool === "rect") {
      const x0 = Math.min(startPt[0], px), x1 = Math.max(startPt[0], px);
      const y0 = Math.min(startPt[1], py), y1 = Math.max(startPt[1], py);
      previewOverlay = [];
      for (let x = x0; x <= x1; x++) { previewOverlay.push({ x, y: y0, rgba }); previewOverlay.push({ x, y: y1, rgba }); }
      for (let y = y0 + 1; y < y1; y++) { previewOverlay.push({ x: x0, y, rgba }); previewOverlay.push({ x: x1, y, rgba }); }
      drawEditorCanvas();
    } else if (tool === "shade" && paintBtn === 0) {
      applyShadeBrush(px, py);
      drawEditorCanvas();
    } else {
      for (const [lx, ly] of bresenham(lastPt[0], lastPt[1], px, py)) putPxSym(lx, ly, rgba);
      lastPt = [px, py];
      drawEditorCanvas();
    }
  });

  window.addEventListener("mouseup", () => {
    if (!painting) return;
    painting = false;
    if (previewOverlay) {
      for (const p of previewOverlay) putPxSym(p.x, p.y, p.rgba);
      previewOverlay = null;
      drawEditorCanvas();
    }
  });

  // Transform helpers
  document.getElementById("pxOutlineBtn").onclick = () => {
    pushUndo();
    const copy = new Uint8ClampedArray(pixels);
    const isSolid = (x, y) => x >= 0 && y >= 0 && x < curW && y < curH && copy[(y * curW + x) * 4 + 3] > 20;
    for (let y = 0; y < curH; y++) for (let x = 0; x < curW; x++) {
      if (!isSolid(x, y) && (isSolid(x - 1, y) || isSolid(x + 1, y) || isSolid(x, y - 1) || isSolid(x, y + 1))) {
        putPxRaw(x, y, [27, 23, 29, 255]); // Warm Ink K
      }
    }
    drawEditorCanvas();
    setStatus("Added 1px Warm Ink (#1b171d) outline.");
  };

  document.getElementById("pxShadowBtn").onclick = () => {
    pushUndo();
    const rx = Math.max(4, curW * 0.34);
    const cy = curH - 3;
    for (let y = Math.max(0, curH - 5); y < curH; y++) for (let x = 0; x < curW; x++) {
      const i = (y * curW + x) * 4;
      if (pixels[i + 3] < 10 && ((x - curW * 0.5) / rx) ** 2 + ((y - cy) / 2.2) ** 2 <= 1) {
        putPxRaw(x, y, [14, 12, 18, 92]);
      }
    }
    drawEditorCanvas();
    setStatus("Added elliptical drop shadow.");
  };

  document.getElementById("pxFlipHBtn").onclick = () => {
    pushUndo();
    const out = new Uint8ClampedArray(pixels.length);
    for (let y = 0; y < curH; y++) for (let x = 0; x < curW; x++) {
      const si = (y * curW + (curW - 1 - x)) * 4;
      const di = (y * curW + x) * 4;
      out[di] = pixels[si]; out[di + 1] = pixels[si + 1]; out[di + 2] = pixels[si + 2]; out[di + 3] = pixels[si + 3];
    }
    pixels = out; drawEditorCanvas();
  };

  document.getElementById("pxFlipVBtn").onclick = () => {
    pushUndo();
    const out = new Uint8ClampedArray(pixels.length);
    for (let y = 0; y < curH; y++) for (let x = 0; x < curW; x++) {
      const si = ((curH - 1 - y) * curW + x) * 4;
      const di = (y * curW + x) * 4;
      out[di] = pixels[si]; out[di + 1] = pixels[si + 1]; out[di + 2] = pixels[si + 2]; out[di + 3] = pixels[si + 3];
    }
    pixels = out; drawEditorCanvas();
  };

  document.getElementById("pxRotBtn").onclick = () => {
    pushUndo();
    const nw = curH, nh = curW;
    const out = new Uint8ClampedArray(nw * nh * 4);
    for (let y = 0; y < curH; y++) for (let x = 0; x < curW; x++) {
      const nx = curH - 1 - y, ny = x;
      const si = (y * curW + x) * 4;
      const di = (ny * nw + nx) * 4;
      out[di] = pixels[si]; out[di + 1] = pixels[si + 1]; out[di + 2] = pixels[si + 2]; out[di + 3] = pixels[si + 3];
    }
    curW = nw; curH = nh; pixels = out; drawEditorCanvas();
  };

  // UI Wiring
  document.getElementById("pxTools").querySelectorAll("button").forEach(btn => {
    btn.onclick = () => {
      tool = btn.dataset.tool;
      document.getElementById("pxTools").querySelectorAll("button").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
    };
  });
  document.getElementById("pxShadeDirBtn").onclick = () => {
    shadeDir = -shadeDir;
    document.getElementById("pxShadeDirBtn").textContent = shadeDir > 0 ? "+Light" : "-Dark";
  };
  document.getElementById("pxMirX").onchange = e => { mirrorX = e.target.checked; drawEditorCanvas(); };
  document.getElementById("pxMirY").onchange = e => { mirrorY = e.target.checked; drawEditorCanvas(); };
  document.getElementById("pxGridChk").onchange = e => { showGrid = e.target.checked; drawEditorCanvas(); };
  document.getElementById("pxTileChk").onchange = e => { showTileGrid = e.target.checked; drawEditorCanvas(); };
  document.getElementById("pxOnionChk").onchange = e => { showOnion = e.target.checked; drawEditorCanvas(); };
  document.getElementById("pxBgSel").onchange = e => { backdrop = e.target.value; drawEditorCanvas(); };
  document.getElementById("pxCustomColor").oninput = e => {
    const h = e.target.value;
    setActiveColor([parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16), 255], "Custom RGB");
  };
  document.getElementById("pxZoomOut").onclick = () => { zoom = Math.max(2, zoom - 2); drawEditorCanvas(); };
  document.getElementById("pxZoomIn").onclick = () => { zoom = Math.min(32, zoom + 2); drawEditorCanvas(); };
  document.getElementById("pxUndoBtn").onclick = undo;
  document.getElementById("pxRedoBtn").onclick = redo;
  document.getElementById("pxSearch").oninput = renderLibrary;
  document.getElementById("pxCatSel").onchange = renderLibrary;

  document.getElementById("pxNewBtn").onclick = () => {
    const dim = prompt("Enter dimensions WxH (e.g. 16x16, 24x28, 32x32, 48x48):", "32x32");
    if (!dim) return;
    const parts = dim.toLowerCase().split(/[x×, ]+/);
    const w = parseInt(parts[0], 10) || 32, h = parseInt(parts[1] || parts[0], 10) || 32;
    curName = `custom_${w}x${h}.png`;
    createBlankSprite(w, h);
  };
  document.getElementById("pxTplSelect").onchange = e => {
    const v = e.target.value;
    if (!v) return;
    if (v === "carry_16") createBlankSprite(16, 16, v);
    else if (v === "npc_24x28") createBlankSprite(24, 28, v);
    else if (v === "portrait_48") createBlankSprite(48, 48, v);
    else if (v === "dungeon_36") createBlankSprite(36, 36, v);
    else if (v === "tile_32") createBlankSprite(32, 32, v);
    e.target.value = "";
  };

  document.getElementById("pxSaveGameBtn").onclick = async () => {
    const fname = (document.getElementById("pxFileName").value || curName).trim();
    const clean = fname.endsWith(".png") ? fname : fname + ".png";
    const data_url = bufferToDataUrl();
    BUNDLE[clean] = { w: curW, h: curH, cat: BUNDLE[clean]?.cat || "Props & World", b64: data_url };
    curName = clean;
    if (window.notifySpriteUpdated) window.notifySpriteUpdated(clean, data_url);
    try {
      const resp = await fetch("/api/save_sprite", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ filename: clean, data_url }),
      });
      const js = await resp.json();
      if (js.ok) setStatus(`Saved ${clean} directly to assets/sprites/ (${js.bytes} bytes)!`);
      else setStatus(`Save failed: ${js.error}`);
    } catch (_) {
      setStatus(`Updated in studio memory! Run run_creator_studio.bat for direct disk write, or click Download .png.`);
    }
    renderLibrary();
  };

  document.getElementById("pxDownloadBtn").onclick = () => {
    const fname = (document.getElementById("pxFileName").value || curName).trim();
    const a = document.createElement("a");
    a.href = bufferToDataUrl();
    a.download = fname.endsWith(".png") ? fname : fname + ".png";
    a.click();
    setStatus(`Downloaded ${a.download}`);
  };

  document.getElementById("pxImportBtn").onclick = () => document.getElementById("pxImportFile").click();
  document.getElementById("pxImportFile").onchange = e => {
    const f = e.target.files[0];
    if (!f) return;
    const reader = new FileReader();
    reader.onload = ev => {
      const fname = f.name;
      BUNDLE[fname] = { w: 32, h: 32, cat: "Props & World", b64: ev.target.result };
      loadSprite(fname);
    };
    reader.readAsDataURL(f);
    e.target.value = "";
  };

  document.getElementById("pxPyExportBtn").onclick = async () => {
    const rows = [];
    for (let y = 0; y < curH; y++) {
      const rKeys = [];
      for (let x = 0; x < curW; x++) {
        const c = getPx(x, y);
        rKeys.push(findPalMatch(c[0], c[1], c[2], c[3]).key);
      }
      rows.push(`    ${JSON.stringify(rKeys)},`);
    }
    const code = `c = PixelCanvas(${curW}, ${curH})\ngrid = [\n${rows.join("\n")}\n]\nfor y, row in enumerate(grid):\n    for x, k in enumerate(row):\n        if k != ".": c.px(x, y, k)\nc.save("${curName}")`;
    try { await navigator.clipboard.writeText(code); setStatus("Copied Python PixelCanvas PAL code to clipboard!"); }
    catch (_) { prompt("Copy Python PixelCanvas code:", code); }
  };

  // Animation preview loop
  document.getElementById("pxFpsRange").oninput = e => {
    animFps = parseInt(e.target.value, 10) || 5;
    document.getElementById("pxFpsLbl").textContent = animFps;
  };
  document.getElementById("pxAnimToggle").onclick = () => {
    animPlaying = !animPlaying;
    document.getElementById("pxAnimToggle").textContent = animPlaying ? "Pause" : "Play";
  };

  const prevImgCache = new Map();
  let lastTs = performance.now();
  function animLoop(now) {
    const dt = (now - lastTs) * 0.001;
    lastTs = now;
    if (animPlaying && previewFrames.length > 0) {
      animTick += dt;
      if (animTick >= 1 / Math.max(1, animFps)) {
        animTick = 0;
        animFrameIdx = (animFrameIdx + 1) % previewFrames.length;
      }
    }
    const p1 = document.getElementById("pxPrev1x");
    const p2 = document.getElementById("pxPrev2x");
    if (p1 && p2 && rootEl.classList.contains("active")) {
      const fr = previewFrames[animFrameIdx % Math.max(1, previewFrames.length)];
      let srcCanvas = null;
      if (!fr || fr.name === curName) {
        const tc = document.createElement("canvas");
        tc.width = curW; tc.height = curH;
        tc.getContext("2d").putImageData(new ImageData(pixels, curW, curH), 0, 0);
        srcCanvas = tc;
      } else {
        if (!prevImgCache.has(fr.b64)) {
          const im = new Image();
          im.src = fr.b64;
          prevImgCache.set(fr.b64, im);
        }
        const im = prevImgCache.get(fr.b64);
        if (im.complete) srcCanvas = im;
      }
      for (const [cv, sc] of [[p1, 1], [p2, 2]]) {
        const g = cv.getContext("2d");
        g.clearRect(0, 0, cv.width, cv.height);
        g.imageSmoothingEnabled = false;
        if (srcCanvas) {
          const dw = curW * sc, dh = curH * sc;
          g.drawImage(srcCanvas, Math.floor((cv.width - dw) / 2), Math.floor((cv.height - dh) / 2), dw, dh);
        }
      }
    }
    requestAnimationFrame(animLoop);
  }
  requestAnimationFrame(animLoop);

  window.openSpriteInPixelStudio = function (fname) {
    if (window.switchCreatorTab) window.switchCreatorTab("pixel");
    if (BUNDLE[fname]) loadSprite(fname);
    else {
      document.getElementById("pxFileName").value = fname;
      setStatus(`Sprite '${fname}' not in bundle yet — paint or choose template & Save.`);
    }
  };

  window.addEventListener("keydown", e => {
    if (!rootEl.classList.contains("active")) return;
    if (["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement?.tagName)) return;
    const k = e.key.toLowerCase();
    if ((e.ctrlKey || e.metaKey) && k === "z") { e.preventDefault(); undo(); return; }
    if ((e.ctrlKey || e.metaKey) && k === "y") { e.preventDefault(); redo(); return; }
    const keyToolMap = { b: "pencil", e: "eraser", g: "fill", l: "line", u: "rect", i: "picker", s: "shade" };
    if (keyToolMap[k]) {
      tool = keyToolMap[k];
      document.getElementById("pxTools").querySelectorAll("button").forEach(b => b.classList.toggle("active", b.dataset.tool === tool));
    }
  });

  renderPalette();
  renderLibrary();
  if (BUNDLE[curName]) loadSprite(curName);
  else createBlankSprite(24, 28, "npc_24x28");
};
