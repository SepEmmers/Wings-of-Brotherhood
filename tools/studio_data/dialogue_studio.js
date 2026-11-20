// Dialogue, Barks & Lore Studio for Wings of the Brotherhood
window.initDialogueStudio = function (rootEl) {
  "use strict";

  const BASE_ENTRIES = (window.STUDIO_DIALOGUE_BUNDLE || []).map(e => ({ ...e }));
  const PORTRAITS = window.STUDIO_PORTRAITS || [];
  const SPRITES = window.STUDIO_SPRITES_BUNDLE || {};
  const REGIONS = window.STUDIO_DIALOGUE_REGIONS || [];
  const SPEAKERS = window.STUDIO_SPEAKERS || [];

  const STORAGE_KEY = "temeraire_dialogue_overrides_v1";
  let overrides = {}; // id -> { orig_speaker, orig_text, speaker, portrait, telepathic, text, file, line, kind }
  let customSequences = {}; // seqId -> [ { id, speaker, portrait, telepathic, text } ]
  let entries = [...BASE_ENTRIES];
  let activeId = entries[0]?.id || "";
  let muteBlips = false;

  // Preview typewriter animation state
  let prevCharCount = 0;
  let prevLastBlipChar = 0;
  let prevTime = 0;
  let prevBounceT = 0;
  let audioCtx = null;

  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed.overrides) overrides = parsed.overrides;
      if (parsed.customSequences) customSequences = parsed.customSequences;
    }
  } catch (_) {}

  function persistLocal() {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify({ overrides, customSequences })); } catch (_) {}
  }

  function mergeOverridesIntoEntries() {
    const customList = [];
    for (const [seqId, arr] of Object.entries(customSequences)) {
      if (Array.isArray(arr)) {
        arr.forEach((line, idx) => customList.push({ ...line, id: line.id || `${seqId}:${idx}`, kind: "custom", region: `Custom Sequence: ${seqId}`, file: "data/dialogue_overrides.json", line: idx + 1 }));
      }
    }
    entries = [...customList, ...BASE_ENTRIES];
  }
  mergeOverridesIntoEntries();

  function getLiveEntry(base) {
    if (!base) return null;
    const ov = overrides[base.id];
    if (!ov) return base;
    return { ...base, speaker: ov.speaker ?? base.speaker, portrait: ov.portrait ?? base.portrait, telepathic: ov.telepathic !== undefined ? ov.telepathic : base.telepathic, text: ov.text ?? base.text };
  }

  function playBlip(isDragon) {
    if (muteBlips) return;
    try {
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = isDragon ? "sine" : "triangle";
      osc.frequency.value = isDragon ? 440 + Math.random() * 80 : 260 + Math.random() * 60;
      gain.gain.setValueAtTime(0.035, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.045);
      osc.connect(gain); gain.connect(audioCtx.destination);
      osc.start(); osc.stop(audioCtx.currentTime + 0.05);
    } catch (_) {}
  }

  rootEl.innerHTML = `
    <div class="st-shell">
      <div class="st-toolbar">
        <span class="brand">Dialogue, Barks &amp; Lore Studio</span>
        <button id="dgNewBtn">+ New Dialogue Line</button>
        <button id="dgReplayBtn">▶ Replay Typewriter</button>
        <label class="inline"><input type="checkbox" id="dgMuteChk" /> Mute Voice Blips</label>
        <div class="sep"></div>
        <label class="inline" title="Also update literal lines directly inside scripts/regions/*.gd">
          <input type="checkbox" id="dgPatchSrcChk" /> Patch .gd Source Files
        </label>
        <button id="dgSaveGameBtn" class="primary">Save Dialogue to Game</button>
        <button id="dgDownloadBtn">Download JSON</button>
        <button id="dgImportBtn">Load JSON</button>
        <input type="file" id="dgImportFile" accept=".json" style="display:none" />
        <button id="dgCopyGdBtn">Copy GDScript</button>
      </div>

      <div class="st-body">
        <div class="st-left" style="width:320px;">
          <div class="panel-header"><span>All Game Dialogue (${entries.length})</span></div>
          <div style="padding:7px 8px;display:flex;flex-direction:column;gap:5px;border-bottom:1px solid var(--border);">
            <input type="text" id="dgSearch" placeholder="Search text, speaker, file..." />
            <select id="dgRegionSel"><option value="ALL">All Regions &amp; Catalogs</option></select>
            <select id="dgSpeakerSel"><option value="ALL">All Speakers</option></select>
            <div style="display:flex;gap:10px;">
              <label class="inline"><input type="checkbox" id="dgTeleOnly" /> Mind-Voice</label>
              <label class="inline"><input type="checkbox" id="dgModOnly" /> Modified Only</label>
            </div>
          </div>
          <div class="scroll-area" id="dgList" style="padding:4px;"></div>
        </div>

        <div class="st-center" style="display:flex;flex-direction:column;min-width:0;background:#121116;">
          <div style="padding:12px 16px;background:#0e0d12;border-bottom:1px solid var(--border);display:flex;flex-direction:column;align-items:center;gap:6px;">
            <div style="font-size:10px;color:var(--muted);letter-spacing:0.6px;text-transform:uppercase;">Live Godot DialogueBox Preview</div>
            <canvas id="dgPreviewCanvas" width="700" height="168" style="max-width:100%;border-radius:4px;"></canvas>
          </div>

          <div class="scroll-area" style="flex:1;padding:14px 18px;">
            <div id="dgEditorMeta" style="font-size:11px;color:var(--muted);margin-bottom:8px;"></div>
            <div class="field-grid-2">
              <div class="field-row">
                <label>Speaker Name</label>
                <div style="display:flex;gap:4px;">
                  <input type="text" id="dgSpeakerIn" style="flex:1;" />
                  <button id="dgTokDragon" title="Insert %DRAGON% token" style="padding:2px 6px;font-size:10px;">%DRAGON%</button>
                </div>
              </div>
              <div class="field-row">
                <label>Presentation Style</label>
                <div style="display:flex;align-items:center;gap:12px;height:28px;">
                  <label class="inline"><input type="checkbox" id="dgTeleChk" /> ✦ Mind-Voice Telepathy</label>
                  <button id="dgRevertBtn" class="danger" style="padding:2px 8px;font-size:11px;">Revert Line</button>
                </div>
              </div>
            </div>

            <div class="field-row">
              <div style="display:flex;justify-content:space-between;align-items:center;">
                <label>Spoken / Telepathic / Lore Text</label>
                <div style="display:flex;gap:6px;align-items:center;">
                  <button id="dgTokPlayer" style="padding:1px 6px;font-size:10px;">Insert %PLAYER%</button>
                  <span id="dgCharStat" style="font-size:11px;color:var(--muted);">0 chars</span>
                </div>
              </div>
              <textarea id="dgTextIn" rows="4" style="width:100%;background:#18161d;color:var(--text);border:1px solid var(--border);border-radius:4px;padding:8px;font-family:inherit;font-size:13px;line-height:1.45;resize:vertical;"></textarea>
              <div id="dgLinterWarn" style="display:none;margin-top:4px;padding:5px 8px;background:rgba(217,83,79,0.16);border:1px solid var(--danger);border-radius:4px;color:#ffb4b0;font-size:11px;"></div>
            </div>

            <div class="field-row" style="margin-top:10px;">
              <label>48×48 Character Portrait Picker (<b id="dgPortraitLbl" style="color:var(--accent);"></b>)</label>
              <div id="dgPortraitGrid" style="display:flex;flex-wrap:wrap;gap:6px;padding:8px;background:#18161d;border:1px solid var(--border);border-radius:4px;max-height:185px;overflow-y:auto;"></div>
            </div>
          </div>

          <div class="st-statusbar">
            <div id="dgStatMsg" style="color:var(--accent);">Ready — Edit any line and click Save Dialogue to Game</div>
            <div>Tokens: <b>%PLAYER%</b>, <b>%DRAGON%</b> resolve dynamically in Godot</div>
          </div>
        </div>

        <div class="st-right" style="width:270px;">
          <div class="panel-header"><span>Edited Lines (<span id="dgModCount">0</span>)</span></div>
          <div class="scroll-area" id="dgModList"></div>
        </div>
      </div>
    </div>
  `;

  // Fill filters
  const regSel = document.getElementById("dgRegionSel");
  for (const r of REGIONS) { const o = document.createElement("option"); o.value = r; o.textContent = r; regSel.appendChild(o); }
  const spkSel = document.getElementById("dgSpeakerSel");
  for (const s of SPEAKERS) { const o = document.createElement("option"); o.value = s; o.textContent = s; spkSel.appendChild(o); }

  function setStatus(m) { document.getElementById("dgStatMsg").textContent = m; }

  function renderPortraitPicker(selectedPort) {
    const grid = document.getElementById("dgPortraitGrid");
    grid.innerHTML = "";
    document.getElementById("dgPortraitLbl").textContent = selectedPort || "none";
    for (const p of PORTRAITS) {
      if (p.endsWith("_blink.png")) continue;
      const rec = SPRITES[p];
      if (!rec) continue;
      const btn = document.createElement("button");
      btn.title = p;
      btn.style.cssText = `padding:3px;display:flex;flex-direction:column;align-items:center;gap:2px;width:60px;background:${p === selectedPort ? "#383125" : "#1f1d24"};border-color:${p === selectedPort ? "var(--accent)" : "var(--border)"};`;
      btn.innerHTML = `<img src="${rec.b64}" width="40" height="40" style="image-rendering:pixelated;" /><span style="font-size:9px;color:var(--muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;width:54px;">${p.replace("portrait_", "").replace(".png", "")}</span>`;
      btn.onclick = () => {
        updateActiveOverride({ portrait: p });
        renderPortraitPicker(p);
      };
      grid.appendChild(btn);
    }
  }

  function checkLint(txt) {
    const warnEl = document.getElementById("dgLinterWarn");
    const bad = txt.match(/\[(F|V|C|M|E|R|X|Space|Shift|Tab|Esc)\]/gi);
    if (bad) {
      warnEl.style.display = "block";
      warnEl.textContent = `Style Guideline Warning: Avoid explicit key spoilers (${bad.join(", ")}) inside spoken dialogue — convey physical cues naturally instead.`;
    } else {
      warnEl.style.display = "none";
    }
  }

  function renderList() {
    const q = (document.getElementById("dgSearch").value || "").toLowerCase().trim();
    const reg = document.getElementById("dgRegionSel").value;
    const spk = document.getElementById("dgSpeakerSel").value;
    const teleOnly = document.getElementById("dgTeleOnly").checked;
    const modOnly = document.getElementById("dgModOnly").checked;
    const host = document.getElementById("dgList");
    host.innerHTML = "";

    const filtered = entries.filter(raw => {
      const e = getLiveEntry(raw);
      if (reg !== "ALL" && raw.region !== reg) return false;
      if (spk !== "ALL" && e.speaker !== spk) return false;
      if (teleOnly && !e.telepathic) return false;
      if (modOnly && !overrides[raw.id]) return false;
      if (q && !(e.text.toLowerCase().includes(q) || e.speaker.toLowerCase().includes(q) || raw.file.toLowerCase().includes(q))) return false;
      return true;
    });

    for (const raw of filtered.slice(0, 220)) {
      const e = getLiveEntry(raw);
      const isMod = !!overrides[raw.id];
      const row = document.createElement("div");
      row.style.cssText = `padding:6px 8px;margin-bottom:4px;border-radius:4px;cursor:pointer;border:1px solid ${raw.id === activeId ? "var(--accent)" : "var(--border)"};background:${raw.id === activeId ? "#352e22" : "var(--panel-alt)"};`;
      const badge = e.telepathic ? `<span style="color:#b79eff;">✦</span> ` : (raw.kind === "bark" ? `<span style="color:#8cb4f5;">[Bark]</span> ` : (raw.kind === "item" ? `<span style="color:#5cb874;">[Item]</span> ` : ""));
      const modDot = isMod ? `<span style="color:var(--accent);font-weight:700;">● </span>` : "";
      row.innerHTML = `
        <div style="display:flex;justify-content:space-between;font-size:11px;font-weight:700;">
          <span>${modDot}${badge}${e.speaker}</span>
          <span style="color:var(--muted);font-weight:400;font-size:10px;">L${raw.line}</span>
        </div>
        <div style="font-size:11px;color:#cfc9bd;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-top:2px;">${e.text}</div>
        <div style="font-size:9px;color:var(--muted);margin-top:2px;">${raw.region}</div>
      `;
      row.onclick = () => selectEntry(raw.id);
      host.appendChild(row);
    }
    if (filtered.length > 220) {
      const note = document.createElement("div");
      note.style.cssText = "padding:8px;text-align:center;color:var(--muted);font-size:11px;";
      note.textContent = `Showing 220 of ${filtered.length} entries — refine search to narrow.`;
      host.appendChild(note);
    }
  }

  function renderModSummary() {
    const keys = Object.keys(overrides);
    document.getElementById("dgModCount").textContent = keys.length;
    const list = document.getElementById("dgModList");
    list.innerHTML = "";
    if (!keys.length) {
      list.innerHTML = `<div class="empty-hint">No dialogue overrides yet. Select any line on the left to rewrite text, swap portraits, or toggle Mind-Voice telepathy.</div>`;
      return;
    }
    for (const id of keys) {
      const ov = overrides[id];
      const card = document.createElement("div");
      card.style.cssText = "padding:6px;margin-bottom:5px;border:1px solid var(--border);border-radius:4px;background:var(--panel-alt);cursor:pointer;";
      card.innerHTML = `<div style="font-weight:700;color:var(--accent);font-size:11px;">${ov.speaker}</div><div style="font-size:11px;color:var(--text);margin-top:2px;">${(ov.text || "").slice(0, 80)}${(ov.text || "").length > 80 ? "…" : ""}</div>`;
      card.onclick = () => selectEntry(id);
      list.appendChild(card);
    }
  }

  function selectEntry(id) {
    activeId = id;
    const raw = entries.find(x => x.id === id);
    if (!raw) return;
    const e = getLiveEntry(raw);
    document.getElementById("dgEditorMeta").innerHTML = `File: <span class="hint-pill">${raw.file}:${raw.line}</span> &nbsp;|&nbsp; Category: <b>${raw.region}</b> (${raw.kind})`;
    document.getElementById("dgSpeakerIn").value = e.speaker;
    document.getElementById("dgTeleChk").checked = !!e.telepathic;
    document.getElementById("dgTextIn").value = e.text;
    document.getElementById("dgCharStat").textContent = `${e.text.length} chars (~${Math.max(1, Math.ceil(e.text.length / 58))} lines)`;
    checkLint(e.text);
    renderPortraitPicker(e.portrait);
    prevCharCount = 0; prevLastBlipChar = 0; prevBounceT = 0.28;
    renderList();
  }

  function updateActiveOverride(patch) {
    const raw = entries.find(x => x.id === activeId);
    if (!raw) return;
    const cur = getLiveEntry(raw);
    const next = { ...cur, ...patch };
    if (next.speaker === raw.speaker && next.portrait === raw.portrait && !!next.telepathic === !!raw.telepathic && next.text === raw.text && raw.kind !== "custom") {
      delete overrides[raw.id];
    } else {
      overrides[raw.id] = {
        orig_speaker: raw.speaker,
        orig_text: raw.text,
        speaker: next.speaker,
        portrait: next.portrait,
        telepathic: !!next.telepathic,
        text: next.text,
        file: raw.file,
        line: raw.line,
        kind: raw.kind,
      };
      if (raw.kind === "custom") Object.assign(raw, next);
    }
    persistLocal();
    renderModSummary();
    renderList();
  }

  // Wire Editor Fields
  document.getElementById("dgSpeakerIn").oninput = e => updateActiveOverride({ speaker: e.target.value });
  document.getElementById("dgTeleChk").onchange = e => {
    prevCharCount = 0; prevBounceT = 0.28;
    updateActiveOverride({ telepathic: e.target.checked });
  };
  document.getElementById("dgTextIn").oninput = e => {
    const txt = e.target.value;
    document.getElementById("dgCharStat").textContent = `${txt.length} chars (~${Math.max(1, Math.ceil(txt.length / 58))} lines)`;
    checkLint(txt);
    prevCharCount = txt.length;
    updateActiveOverride({ text: txt });
  };
  document.getElementById("dgTokDragon").onclick = () => {
    const inp = document.getElementById("dgSpeakerIn");
    inp.value = "%DRAGON%";
    updateActiveOverride({ speaker: "%DRAGON%", telepathic: true, portrait: "portrait_hatchling_stage1.png" });
    document.getElementById("dgTeleChk").checked = true;
    renderPortraitPicker("portrait_hatchling_stage1.png");
  };
  document.getElementById("dgTokPlayer").onclick = () => {
    const ta = document.getElementById("dgTextIn");
    const start = ta.selectionStart || ta.value.length;
    ta.value = ta.value.slice(0, start) + "%PLAYER%" + ta.value.slice(ta.selectionEnd || start);
    ta.dispatchEvent(new Event("input"));
  };
  document.getElementById("dgRevertBtn").onclick = () => {
    delete overrides[activeId];
    persistLocal();
    selectEntry(activeId);
    renderModSummary();
    setStatus("Reverted line back to GDScript original.");
  };

  document.getElementById("dgNewBtn").onclick = () => {
    const seqName = prompt("Custom Dialogue Sequence ID (e.g. custom_npc_intro):", "custom_intro");
    if (!seqName) return;
    if (!customSequences[seqName]) customSequences[seqName] = [];
    const idx = customSequences[seqName].length;
    const item = { id: `${seqName}:${idx}`, speaker: "Captain Anna", portrait: "portrait_anna.png", telepathic: false, text: "New dialogue line written in the Creator Studio." };
    customSequences[seqName].push(item);
    mergeOverridesIntoEntries();
    overrides[item.id] = { ...item, orig_speaker: item.speaker, orig_text: item.text, file: "data/dialogue_overrides.json", line: idx + 1, kind: "custom" };
    persistLocal();
    renderList();
    renderModSummary();
    selectEntry(item.id);
    setStatus(`Added custom line to sequence '${seqName}'.`);
  };

  document.getElementById("dgReplayBtn").onclick = () => { prevCharCount = 0; prevLastBlipChar = 0; prevBounceT = 0.28; };
  document.getElementById("dgMuteChk").onchange = e => { muteBlips = e.target.checked; };
  document.getElementById("dgSearch").oninput = renderList;
  document.getElementById("dgRegionSel").onchange = renderList;
  document.getElementById("dgSpeakerSel").onchange = renderList;
  document.getElementById("dgTeleOnly").onchange = renderList;
  document.getElementById("dgModOnly").onchange = renderList;

  // Save / Export
  document.getElementById("dgSaveGameBtn").onclick = async () => {
    const patchSource = document.getElementById("dgPatchSrcChk").checked;
    try {
      const resp = await fetch("/api/save_dialogue", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ overrides, custom_sequences: customSequences, patch_source: patchSource }),
      });
      const js = await resp.json();
      if (js.ok) setStatus(`Saved ${js.override_count} override(s) to data/dialogue_overrides.json (patched ${js.patched_gd_count} .gd lines)!`);
      else setStatus(`Save failed: ${js.error}`);
    } catch (_) {
      setStatus("Saved in browser storage. Run run_creator_studio.bat for direct disk write, or click Download JSON.");
    }
  };

  document.getElementById("dgDownloadBtn").onclick = () => {
    const blob = new Blob([JSON.stringify({ overrides, custom_sequences: customSequences }, null, 2)], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "dialogue_overrides.json";
    a.click();
  };

  document.getElementById("dgImportBtn").onclick = () => document.getElementById("dgImportFile").click();
  document.getElementById("dgImportFile").onchange = e => {
    const f = e.target.files[0]; if (!f) return;
    const reader = new FileReader();
    reader.onload = ev => {
      try {
        const parsed = JSON.parse(ev.target.result);
        overrides = parsed.overrides || {};
        customSequences = parsed.custom_sequences || {};
        mergeOverridesIntoEntries();
        persistLocal();
        renderList(); renderModSummary(); selectEntry(activeId);
        setStatus("Imported dialogue_overrides.json.");
      } catch (err) { setStatus("Invalid JSON: " + err.message); }
    };
    reader.readAsText(f);
    e.target.value = "";
  };

  document.getElementById("dgCopyGdBtn").onclick = async () => {
    const e = getLiveEntry(entries.find(x => x.id === activeId));
    if (!e) return;
    const safeSpk = e.speaker.replace(/%DRAGON%/g, "GameState.gold_dragon_name").replace(/%PLAYER%/g, "GameState.player_name");
    const spkCode = safeSpk.startsWith("GameState.") ? safeSpk : `"${e.speaker.replace(/"/g, '\\"')}"`;
    const txtCode = `"${e.text.replace(/"/g, '\\"').replace(/\n/g, "\\n")}"`;
    const snippet = `ui.show_dialogue([\n\t{"speaker": ${spkCode}, "portrait": "${e.portrait}", "telepathic": ${e.telepathic ? "true" : "false"}, "text": ${txtCode}},\n])`;
    try { await navigator.clipboard.writeText(snippet); setStatus("Copied GDScript show_dialogue([...]) snippet!"); }
    catch (_) { prompt("Copy GDScript:", snippet); }
  };

  // Live Godot DialogueBox Canvas Preview Loop
  const pCanvas = document.getElementById("dgPreviewCanvas");
  const pCtx = pCanvas.getContext("2d");
  const portImgCache = new Map();
  function getPortImg(fname) {
    if (!fname || !SPRITES[fname]) return null;
    if (!portImgCache.has(fname) || portImgCache.get(fname).src !== SPRITES[fname].b64) {
      const im = new Image();
      im.src = SPRITES[fname].b64;
      portImgCache.set(fname, im);
    }
    return portImgCache.get(fname);
  }

  let lastT = performance.now();
  function drawPreviewLoop(now) {
    const dt = Math.min(0.1, (now - lastT) * 0.001);
    lastT = now;
    if (rootEl.classList.contains("active")) {
      prevTime += dt;
      if (prevBounceT > 0) prevBounceT = Math.max(0, prevBounceT - dt);
      const raw = entries.find(x => x.id === activeId);
      const e = getLiveEntry(raw) || { speaker: "Speaker", portrait: "portrait_boy_neutral.png", telepathic: false, text: "" };
      const fullTxt = e.text.replace(/%PLAYER%/g, "Bram").replace(/%DRAGON%/g, "Aurelius");
      const spkDisplay = e.speaker.replace(/%PLAYER%/g, "Bram").replace(/%DRAGON%/g, "Aurelius");

      if (prevCharCount < fullTxt.length) {
        prevCharCount = Math.min(fullTxt.length, prevCharCount + dt * 44);
        const curInt = Math.floor(prevCharCount);
        if (curInt > prevLastBlipChar && curInt % (e.telepathic ? 5 : 3) === 0) {
          prevLastBlipChar = curInt;
          playBlip(!!e.telepathic);
        }
      }

      const W = pCanvas.width, H = pCanvas.height;
      pCtx.clearRect(0, 0, W, H);

      // Frame backdrop
      pCtx.fillStyle = e.telepathic ? "#17142e" : "#16131c";
      pCtx.fillRect(4, 4, W - 8, H - 8);
      if (e.telepathic) {
        // Mind-Voice dream mist & drifting golden/pearl motes
        const g = 0.5 + 0.5 * Math.sin(prevTime * 2.5);
        pCtx.strokeStyle = `rgba(242, 204, 108, ${0.72 + 0.25 * g})`;
        pCtx.lineWidth = 2.5;
        pCtx.strokeRect(4, 4, W - 8, H - 8);
        for (let i = 0; i < 12; i++) {
          const life = (prevTime * 0.16 + i * 0.19) % 1;
          const mx = 40 + ((i * 57) % (W - 60)) + Math.sin(prevTime * 1.4 + i) * 8;
          const my = H - 14 - life * (H - 36);
          const ma = Math.sin(life * Math.PI) * 0.85;
          pCtx.fillStyle = i % 2 === 0 ? `rgba(255, 232, 138, ${ma})` : `rgba(206, 198, 255, ${ma})`;
          pCtx.beginPath(); pCtx.arc(mx, my, i % 3 === 0 ? 1.8 : 1.2, 0, Math.PI * 2); pCtx.fill();
        }
      } else {
        pCtx.strokeStyle = "#c29446";
        pCtx.lineWidth = 2.5;
        pCtx.strokeRect(4, 4, W - 8, H - 8);
        pCtx.strokeStyle = "rgba(188,148,72,0.22)";
        pCtx.lineWidth = 1;
        pCtx.strokeRect(8, 8, W - 16, H - 16);
      }

      // Portrait slot (88x88 crisp nearest-neighbor, periodic blink)
      const px = 22, py = 40, psz = 88;
      pCtx.fillStyle = e.telepathic ? "#1d1938" : "#110f16";
      pCtx.fillRect(px, py, psz, psz);
      pCtx.strokeStyle = e.telepathic ? "#ebd074" : "#b88a42";
      pCtx.lineWidth = 2;
      pCtx.strokeRect(px, py, psz, psz);

      const blinkActive = (prevTime % 3.6) < 0.14;
      const blinkName = (e.portrait || "").replace(".png", "_blink.png");
      const im = (blinkActive && SPRITES[blinkName]) ? getPortImg(blinkName) : getPortImg(e.portrait);
      if (im && im.complete) {
        pCtx.imageSmoothingEnabled = false;
        const bounce = prevBounceT > 0 ? -Math.sin((1 - prevBounceT / 0.28) * Math.PI) * 4 : (e.telepathic ? Math.sin(prevTime * 3.6) * 0.8 : 0);
        pCtx.drawImage(im, px + 4, py + 4 + bounce, psz - 8, psz - 8);
      }

      // Speaker header & rule
      const tx = 130;
      pCtx.fillStyle = e.telepathic ? "#fae08c" : "#f4d076";
      pCtx.font = "bold 16px sans-serif";
      pCtx.fillText(e.telepathic ? `${spkDisplay}  ✦  Mind-Voice` : spkDisplay, tx, 38);
      pCtx.fillStyle = "rgba(194,158,86,0.45)";
      pCtx.fillRect(tx, 46, W - tx - 24, 1);

      // Word-wrapped typewriter text
      const visStr = fullTxt.slice(0, Math.floor(prevCharCount));
      pCtx.fillStyle = "#efeae0";
      pCtx.font = "15px sans-serif";
      const words = visStr.split(/\s+/);
      let lineStr = "", ly = 68;
      const maxW = W - tx - 28;
      for (const w of words) {
        const test = lineStr ? lineStr + " " + w : w;
        if (pCtx.measureText(test).width > maxW) {
          pCtx.fillText(lineStr, tx, ly);
          lineStr = w;
          ly += 21;
        } else lineStr = test;
      }
      if (lineStr) pCtx.fillText(lineStr, tx, ly);

      if (Math.floor(prevCharCount) >= fullTxt.length) {
        pCtx.fillStyle = "rgba(196,186,164,0.85)";
        pCtx.font = "11px sans-serif";
        pCtx.textAlign = "right";
        pCtx.fillText("[E / Space] Continue", W - 22, H - 18);
        pCtx.textAlign = "left";
      }
    }
    requestAnimationFrame(drawPreviewLoop);
  }
  requestAnimationFrame(drawPreviewLoop);

  window.openDialogueInStudio = function (query) {
    if (window.switchCreatorTab) window.switchCreatorTab("dialogue");
    document.getElementById("dgSearch").value = query || "";
    renderList();
    const first = entries.find(raw => {
      const e = getLiveEntry(raw);
      return !query || e.speaker.toLowerCase().includes(query.toLowerCase()) || e.text.toLowerCase().includes(query.toLowerCase());
    });
    if (first) selectEntry(first.id);
  };

  renderList();
  renderModSummary();
  if (activeId) selectEntry(activeId);
};
