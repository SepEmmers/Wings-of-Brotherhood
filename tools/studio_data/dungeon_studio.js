// GameMaker Studio-grade Dungeon & Puzzle Maker + Live Playtester for Wings of the Brotherhood
window.initDungeonStudio = function (rootEl) {
  "use strict";

  const PRESETS = window.STUDIO_DUNGEONS_BUNDLE || {};
  const SPRITES = window.STUDIO_SPRITES_BUNDLE || {};
  const STORAGE_KEY = "temeraire_custom_dungeon_v2";
  const CORNER_TYPES = new Set(["gate", "locked_door", "secret_wall", "cracked_wall", "drawbridge", "exit_portal", "trigger_zone", "color_block", "conveyor", "collapsing_floor", "rune_tile", "pressure_pad", "heat_plate", "teleporter"]);

  const PALETTE_GROUPS = [
    {
      title: "Architecture & Doors",
      items: [
        { kind: "room", label: "Chamber Room", color: "#525766", w: 320, h: 240 },
        { kind: "chasm", label: "Water Chasm", color: "#25608a", w: 128, h: 280 },
        { kind: "wall", label: "Dividing Wall", color: "#2b2a34", w: 38, h: 160 },
        { kind: "node", type: "gate", label: "Vault Gate", tex: "prop_shrine_door_shut.png", w: 38, h: 92, logicMode: "ALL" },
        { kind: "node", type: "locked_door", label: "Locked Key Door", tex: "dk_door_locked.png", w: 38, h: 92, keyType: "small" },
        { kind: "node", type: "drawbridge", label: "Drawbridge (Chasm)", tex: "prop_timber_bridge_h.png", w: 128, h: 64, logicMode: "ALL" },
        { kind: "node", type: "secret_wall", label: "Secret Wall [R]", tex: "dk_secret_wall.png", w: 38, h: 92 },
        { kind: "node", type: "cracked_wall", label: "Cracked Wall [V]", tex: "dk_cracked_wall.png", w: 38, h: 92, hitsNeeded: 3 },
        { kind: "node", type: "color_block", label: "Red Crystal Block", tex: "dk_block_red.png", w: 32, h: 32, color: "red" },
        { kind: "node", type: "color_block", label: "Blue Crystal Block", tex: "dk_block_blue.png", w: 32, h: 32, color: "blue" },
        { kind: "node", type: "exit_portal", label: "Exit Stairs Portal", tex: "prop_crypt_stairs.png", w: 68, h: 44, targetRegion: "old_heverlee" },
      ],
    },
    {
      title: "Switches, Dragon & Logic",
      items: [
        { kind: "node", type: "boulder", label: "Keystone Boulder", tex: "prop_shrine_boulder.png", w: 36, h: 36 },
        { kind: "node", type: "weight_plate", label: "Weight Plate", tex: "prop_weight_plate_up.png", w: 36, h: 30 },
        { kind: "node", type: "pressure_pad", label: "Pressure Pad", tex: "dk_pressure_pad.png", w: 32, h: 32 },
        { kind: "node", type: "heat_plate", label: "Heat Plate", tex: "dk_heat_plate.png", w: 32, h: 32, radius: 110 },
        { kind: "node", type: "crystal_switch", label: "Moon Crystal [V]", tex: "dk_crystal_switch_0.png", w: 24, h: 28 },
        { kind: "node", type: "chime_bell", label: "Chime Bell [E]", tex: "dk_chime_bell.png", w: 24, h: 32, radius: 260 },
        { kind: "node", type: "resonance_crystal", label: "Resonance Crystal", tex: "dk_resonance_crystal.png", w: 20, h: 28, holdSec: 8 },
        { kind: "node", type: "timer_switch", label: "Timer Switch [E/V]", tex: "dk_timer_switch.png", w: 24, h: 28, holdSec: 8 },
        { kind: "node", type: "serpent_vent", label: "Serpent Vent [R]", tex: "prop_shrine_serpent_vent.png", w: 36, h: 30 },
        { kind: "node", type: "ember_brazier", label: "Ember Sconce [R]", tex: "prop_shrine_sconce_off.png", w: 28, h: 38 },
        { kind: "node", type: "ember_brazier", label: "Altar Candle [R]", tex: "prop_altar_candle.png", w: 24, h: 32 },
        { kind: "node", type: "briar_barrier", label: "Dry Briar Wall [R]", tex: "prop_bramble_thicket_1.png", w: 64, h: 46 },
        { kind: "node", type: "grapple_post", label: "Rope Grapple [F]", tex: "prop_grapple_post.png", w: 24, h: 30 },
        { kind: "node", type: "lever", label: "Iron Lever [E]", tex: "prop_medieval_lever_idle.png", w: 28, h: 34, holdSec: 0 },
        { kind: "node", type: "relay", label: "Logic Relay", tex: "dk_relay.png", w: 20, h: 20, logicMode: "ALL", delaySec: 0, latch: true },
        { kind: "node", type: "trigger_zone", label: "Trigger Zone", color: "#9b59b6", w: 96, h: 96, text: "A cold draft stirs...", telepathic: true },
        { kind: "node", type: "checkpoint", label: "Checkpoint Flag", tex: "dk_checkpoint.png", w: 24, h: 32 },
      ],
    },
    {
      title: "Hazards & Floor Mechanics",
      items: [
        { kind: "node", type: "spike_trap", label: "Floor Spikes", tex: "prop_floor_spikes_down.png", w: 38, h: 38, periodic: true, periodSec: 2.4 },
        { kind: "node", type: "dart_turret", label: "Dart Turret", tex: "dk_turret.png", w: 28, h: 28, dir: "right", periodSec: 2.4 },
        { kind: "node", type: "flame_jet", label: "Flame Jet", tex: "dk_flame_jet.png", w: 28, h: 28, periodSec: 3.0 },
        { kind: "node", type: "patrol_blade", label: "Patrol Blade", tex: "dk_blade.png", w: 28, h: 28, axis: "h", rangePx: 160, speed: 95 },
        { kind: "node", type: "collapsing_floor", label: "Collapsing Floor", tex: "dk_cracked_floor.png", w: 32, h: 32, delaySec: 0.7 },
        { kind: "node", type: "conveyor", label: "Wind Conveyor", tex: "dk_conveyor_right.png", w: 96, h: 48, dir: "right", speed: 85 },
        { kind: "node", type: "teleporter", label: "Warp Teleporter", tex: "dk_teleporter.png", w: 32, h: 32, pairId: "alpha" },
      ],
    },
    {
      title: "Loot, Breakables & NPCs",
      items: [
        { kind: "node", type: "key_small", label: "Small Brass Key", tex: "dk_key_small.png", w: 16, h: 16 },
        { kind: "node", type: "key_boss", label: "Crimson Boss Key", tex: "dk_key_boss.png", w: 16, h: 16 },
        { kind: "node", type: "heart_pickup", label: "Heart Drop", tex: "icon_heart_full.png", w: 16, h: 16 },
        { kind: "node", type: "heart_container", label: "Heart Container +1", tex: "dk_heart_container.png", w: 20, h: 20 },
        { kind: "node", type: "coin", label: "Gold Florin", tex: "dk_florin.png", w: 14, h: 14, value: 5 },
        { kind: "node", type: "breakable_pot", label: "Clay Pot [V]", tex: "dk_pot.png", w: 20, h: 22 },
        { kind: "node", type: "healing_spring", label: "Healing Spring [E]", tex: "prop_spring_well.png", w: 28, h: 24, uses: 3 },
        { kind: "node", type: "treasure", label: "Reliquary Chest", tex: "prop_treasure_chest_closed.png", w: 40, h: 40, itemReward: "Meuse Reliquary Seal", bondReward: 20 },
        { kind: "node", type: "sarcophagus", label: "Stag Tomb", tex: "prop_sarcophagus_stag.png", w: 42, h: 44, crest: "stag", isTrap: false },
        { kind: "node", type: "sarcophagus", label: "Cross Tomb (Trap)", tex: "prop_sarcophagus_cross.png", w: 42, h: 44, crest: "cross", isTrap: true },
        { kind: "node", type: "plaque", label: "Riddle Plaque [E]", tex: "prop_devildragon_relief.png", w: 88, h: 68, speaker: "Carved Relief", portrait: "portrait_hatchling_stage1.png", telepathic: false, text: "Weight anchors stone; flame wakes bronze." },
        { kind: "node", type: "npc", label: "Dungeon NPC [E]", tex: "npc_city_monk_0.png", w: 24, h: 28, speaker: "Brotherhood Scout", portrait: "portrait_watchman.png", text: "Mind the patrol blades ahead!" },
      ],
    },
    {
      title: "Dungeon Dressing",
      items: [
        { kind: "node", type: "decor", label: "Stone Statue", tex: "dk_statue.png", w: 28, h: 40, solid: true },
        { kind: "node", type: "decor", label: "Ancient Bones", tex: "dk_bones.png", w: 20, h: 14, solid: false },
        { kind: "node", type: "decor", label: "Corner Cobweb", tex: "dk_cobweb.png", w: 24, h: 24, solid: false },
        { kind: "node", type: "decor", label: "Fallen Rubble", tex: "dk_rubble.png", w: 28, h: 16, solid: true },
      ],
    },
  ];

  function clone(o) { return JSON.parse(JSON.stringify(o)); }

  let dungeon = null;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) dungeon = JSON.parse(saved);
  } catch (_) {}
  if (!dungeon || !dungeon.rooms) dungeon = clone(PRESETS.zelda_dragon_trial || PRESETS.custom_studio_dungeon || { title: "New Dungeon", worldSize: { w: 1600, h: 960 }, floorStyle: "catacomb_stone", ambience: "amb_catacombs", darkness: 0, spawn: { x: 240, y: 240 }, rooms: [{ id: "r1", name: "Entry Chamber", x: 100, y: 100, w: 420, h: 340 }], chasms: [], walls: [], nodes: [], wires: [] });

  let editTool = "select"; // select | room | chasm | wall | wire | erase | stamp
  let activeStamp = null;
  let selected = null; // { kind: "room"|"chasm"|"wall"|"node"|"spawn", id }
  let leftTab = "objects"; // objects | instances
  let snapPx = 16;
  let showGrid = true;
  let clipboardItem = null;
  let wireStartNodeId = null;
  let playtestActive = false;
  const cam = { x: 0, y: 0, zoom: 0.65 };
  let undoStack = [];
  let redoStack = [];

  rootEl.innerHTML = `
    <div class="st-shell">
      <div class="st-toolbar">
        <span class="brand">Dungeon &amp; Puzzle Maker</span>
        <select id="dnPresetSel" title="Load Dungeon Preset">
          <option value="zelda_dragon_trial">Zelda &amp; Dragon Trial (Showcase)</option>
          <option value="custom_studio_dungeon">Meuse Reliquary Vault (Custom)</option>
          <option value="old_heverlee_shrine">Old Heverlee Golden Shrine</option>
          <option value="louvain_catacombs">Louvain Abbey Catacombs</option>
          <option value="blank">+ New Blank Dungeon</option>
        </select>
        <input type="text" id="dnTitleIn" value="${dungeon.title || ""}" style="width:170px;" title="Dungeon Title" />
        <select id="dnStyleSel" title="Floor Tile Style">
          <option value="catacomb_stone">Catacomb Stone</option>
          <option value="obsidian_shrine">Golden Shrine Basalt</option>
          <option value="cathedral_flag">Cathedral Flagstone</option>
          <option value="library_wood">Scriptorium Timber</option>
        </select>
        <label class="inline" title="Dungeon Darkness">Dark:<input type="range" id="dnDarkRange" min="0" max="85" value="${Math.round((dungeon.darkness || 0) * 100)}" style="width:52px;" /></label>
        <div class="sep"></div>
        <div class="btn-group" id="dnTools">
          <button data-t="select" class="active">Select</button>
          <button data-t="room">Room</button>
          <button data-t="chasm">Chasm</button>
          <button data-t="wall">Wall</button>
          <button data-t="wire" title="Drag from Trigger Node to Target">⚡ Wire</button>
          <button data-t="erase">Erase</button>
        </div>
        <select id="dnSnapSel" title="Snap Grid">
          <option value="1">Snap: Off</option>
          <option value="8">8px</option>
          <option value="16" selected>16px</option>
          <option value="32">32px</option>
        </select>
        <label class="inline"><input type="checkbox" id="dnGridChk" checked /> Grid</label>
        <div class="btn-group">
          <button id="dnUndoBtn" title="Undo (Ctrl+Z)">↶</button>
          <button id="dnRedoBtn" title="Redo (Ctrl+Y)">↷</button>
          <button id="dnDupBtn" title="Duplicate (Ctrl+D)">Dup</button>
          <button id="dnZoomOut">-</button>
          <button id="dnZoomFit">Fit</button>
          <button id="dnZoomIn">+</button>
        </div>
        <div class="sep"></div>
        <button id="dnPlayBtn" style="background:#3d5f3e;border-color:#5b8c5c;font-weight:700;">▶ Playtest (P)</button>
        <button id="dnResetPlayBtn" style="display:none;">↺ Reset</button>
        <button id="dnSaveGameBtn" class="primary" title="Save to data/custom_dungeon.json (play via Godot [F1])">Save to Game ([F1])</button>
        <button id="dnDownloadBtn">JSON</button>
        <button id="dnImportBtn">Load</button>
        <input type="file" id="dnImportFile" accept=".json" style="display:none" />
      </div>

      <div class="st-body">
        <div class="st-left">
          <div style="display:flex;border-bottom:1px solid var(--border);background:var(--panel-alt);">
            <button id="dnTabObj" class="active" style="flex:1;border-radius:0;border:none;padding:6px;font-weight:700;">Objects</button>
            <button id="dnTabInst" style="flex:1;border-radius:0;border:none;padding:6px;font-weight:700;">Instances</button>
          </div>
          <div class="scroll-area" id="dnPalette"></div>
          <div class="scroll-area" id="dnInstances" style="display:none;"></div>
        </div>

        <div class="st-center" style="display:flex;flex-direction:column;position:relative;min-width:0;">
          <canvas id="dnCanvas" style="flex:1;width:100%;height:100%;display:block;background:#0b0a0f;"></canvas>
          <div id="dnHudBar" style="position:absolute;top:10px;left:12px;background:rgba(20,18,25,0.92);border:1px solid var(--border);border-radius:5px;padding:6px 10px;font-size:11px;pointer-events:none;"></div>
          <div id="dnDlgBox" style="display:none;position:absolute;bottom:34px;left:50%;transform:translateX(-50%);width:min(560px,90%);background:#171422;border:2px solid var(--accent);border-radius:6px;padding:10px 14px;box-shadow:0 8px 30px rgba(0,0,0,0.8);">
            <div id="dnDlgSpeaker" style="font-weight:700;color:var(--accent);margin-bottom:4px;"></div>
            <div id="dnDlgText" style="font-size:13px;line-height:1.4;"></div>
            <div style="text-align:right;font-size:10px;color:var(--muted);margin-top:4px;">Press [E] or [Space] to continue</div>
          </div>
          <div class="st-statusbar">
            <div id="dnStatCursor">Cursor: 0, 0 | Zoom: 65%</div>
            <div id="dnStatMsg" style="color:var(--accent);">Ready — Drag handles to resize, Ctrl+D duplicate, P to Playtest</div>
          </div>
        </div>

        <div class="st-right">
          <div class="panel-header"><span>Properties &amp; Logic Inspector</span></div>
          <div class="inspector-box" id="dnInspector"></div>
        </div>
      </div>
    </div>
  `;

  const canvas = document.getElementById("dnCanvas");
  const ctx = canvas.getContext("2d");
  const imgCache = new Map();

  function getSpriteImg(fname) {
    if (!fname || !SPRITES[fname]) return null;
    if (!imgCache.has(fname) || imgCache.get(fname).src !== SPRITES[fname].b64) {
      const im = new Image(); im.src = SPRITES[fname].b64; imgCache.set(fname, im);
    }
    return imgCache.get(fname);
  }
  function saveLocal() { try { localStorage.setItem(STORAGE_KEY, JSON.stringify(dungeon)); } catch (_) {} }
  function pushUndo() { undoStack.push(JSON.stringify(dungeon)); if (undoStack.length > 50) undoStack.shift(); redoStack = []; }
  function doUndo() { if (!undoStack.length) return; redoStack.push(JSON.stringify(dungeon)); dungeon = JSON.parse(undoStack.pop()); selected = null; saveLocal(); renderAllSidebars(); }
  function doRedo() { if (!redoStack.length) return; undoStack.push(JSON.stringify(dungeon)); dungeon = JSON.parse(redoStack.pop()); selected = null; saveLocal(); renderAllSidebars(); }
  function setStatus(m) { document.getElementById("dnStatMsg").textContent = m; }
  function uid(prefix) { return `${prefix}_${Math.random().toString(36).slice(2, 7)}`; }
  function snap(v) { return snapPx <= 1 ? Math.round(v) : Math.round(v / snapPx) * snapPx; }
  function isCornerType(t) { return CORNER_TYPES.has(t); }
  function nodeRect(n, posOverride) {
    const p = posOverride || n;
    return isCornerType(n.type) ? { x: p.x, y: p.y, w: n.w, h: n.h } : { x: p.x - n.w * 0.5, y: p.y - n.h * 0.5, w: n.w, h: n.h };
  }
  function nodeCenter(n, posOverride) {
    const r = nodeRect(n, posOverride);
    return { x: r.x + r.w * 0.5, y: r.y + r.h * 0.5 };
  }

  function renderPalette() {
    const box = document.getElementById("dnPalette");
    box.innerHTML = "";
    for (const grp of PALETTE_GROUPS) {
      const t = document.createElement("div"); t.className = "cat-title"; t.textContent = grp.title;
      box.appendChild(t);
      const grid = document.createElement("div"); grid.className = "palette-grid";
      for (const it of grp.items) {
        const card = document.createElement("div"); card.className = "palette-item";
        let thumb = `<div class="swatch" style="background:${it.color || "#666"};"></div>`;
        if (it.tex && SPRITES[it.tex]) thumb = `<img src="${SPRITES[it.tex].b64}" />`;
        card.innerHTML = `<div class="palette-thumb">${thumb}</div><div class="palette-name">${it.label}</div><div class="palette-dim">${it.w}×${it.h}</div>`;
        card.onclick = () => {
          document.querySelectorAll("#dnPalette .palette-item").forEach(x => x.classList.remove("selected"));
          card.classList.add("selected");
          if (it.kind === "room" || it.kind === "chasm" || it.kind === "wall") { setTool(it.kind); activeStamp = null; }
          else { activeStamp = { ...it }; setTool("stamp"); }
        };
        grid.appendChild(card);
      }
      box.appendChild(grid);
    }
  }

  function renderInstances() {
    const box = document.getElementById("dnInstances");
    box.innerHTML = "";
    const addSec = (title, items, kind) => {
      const h = document.createElement("div"); h.className = "cat-title"; h.textContent = `${title} (${items.length})`;
      box.appendChild(h);
      for (const it of items) {
        const row = document.createElement("div");
        const isSel = selected && selected.kind === kind && selected.id === it.id;
        row.style.cssText = `padding:4px 7px;margin-bottom:3px;border-radius:3px;cursor:pointer;font-size:11px;display:flex;justify-content:space-between;background:${isSel ? "#383125" : "var(--panel-alt)"};border:1px solid ${isSel ? "var(--accent)" : "var(--border)"};`;
        row.innerHTML = `<span>${it.label || it.name || it.id}</span><span style="color:var(--muted);font-size:10px;">${it.type || kind}</span>`;
        row.onclick = () => {
          selected = { kind, id: it.id };
          const c = kind === "node" ? nodeCenter(it) : { x: it.x + it.w * 0.5, y: it.y + it.h * 0.5 };
          cam.x = c.x - (canvas.width / cam.zoom) * 0.5;
          cam.y = c.y - (canvas.height / cam.zoom) * 0.5;
          renderInspector(); renderInstances();
        };
        box.appendChild(row);
      }
    };
    addSec("Rooms", dungeon.rooms, "room");
    addSec("Chasms", dungeon.chasms, "chasm");
    addSec("Walls", dungeon.walls, "wall");
    addSec("Puzzle & Loot Nodes", dungeon.nodes, "node");
  }

  function renderAllSidebars() { renderInspector(); renderInstances(); updateHudBar(); }

  function setTool(t) {
    editTool = t; wireStartNodeId = null;
    document.getElementById("dnTools").querySelectorAll("button").forEach(b => b.classList.toggle("active", b.dataset.t === t));
    updateHudBar();
  }

  function updateHudBar() {
    const hud = document.getElementById("dnHudBar");
    if (playtestActive) {
      hud.innerHTML = `<b style="color:#77e088;">PLAYTEST</b> | ❤️ ${sim.hp}/${sim.maxHp} | 🗝️ ${sim.keysSmall} Boss:${sim.keysBoss} | 💰 ${sim.florins} | [WASD] Move [V] Slash [F] Push/Rope [R] Dragon [E] Act`;
    } else if (editTool === "wire") {
      hud.innerHTML = `Mode: <b>⚡ Wire Logic</b> — ${wireStartNodeId ? `Click Target Gate/Bridge/Relay/Trap (from <b>${wireStartNodeId}</b>)` : "Click Trigger Node (Pad, Lever, Bell, Crystal, Vent, Zone)"}`;
    } else if (editTool === "stamp" && activeStamp) {
      hud.innerHTML = `Stamp: <b>${activeStamp.label}</b> — Click on canvas to place (Esc to cancel)`;
    } else {
      hud.innerHTML = `<b>${editTool.toUpperCase()}</b> | Rooms: ${dungeon.rooms.length} | Nodes: ${dungeon.nodes.length} | Wires: ${dungeon.wires.length}`;
    }
  }

  function getSelectedObj() {
    if (!selected) return null;
    if (selected.kind === "spawn") return dungeon.spawn;
    return (dungeon[selected.kind + "s"] || []).find(x => x.id === selected.id) || null;
  }

  function renderInspector() {
    const box = document.getElementById("dnInspector");
    box.innerHTML = "";
    const obj = getSelectedObj();
    if (!obj) {
      box.innerHTML = `<div class="empty-hint"><p><strong>GameMaker-Style Dungeon Studio:</strong></p><p>&bull; Drag corner handles on Rooms, Chasms, Walls, Gates &amp; Conveyors to resize.</p><p>&bull; Use <b>⚡ Wire</b> to link Switches, Pads, Bells &amp; Zones to Gates, Drawbridges, Relays or Traps (<code>ALL / ANY / NOT / SEQUENCE</code>).</p><p>&bull; Press <b>P</b> to playtest live with <b>[V]</b> Knife Slash, <b>[F]</b> Rope/Push, <b>[R]</b> Dragon &amp; <b>[E]</b> Interact!</p></div>`;
      return;
    }

    const head = document.createElement("div");
    head.style.cssText = "font-weight:700;color:var(--accent);margin-bottom:8px;";
    head.textContent = `${selected.kind.toUpperCase()}: ${obj.label || obj.name || obj.id || "Player Spawn"}`;
    box.appendChild(head);

    const numRow = (lbl, val, fn) => {
      const r = document.createElement("div"); r.className = "field-row";
      r.innerHTML = `<label>${lbl}</label><input type="number" step="any" value="${Number(val || 0)}" />`;
      r.querySelector("input").onchange = e => { pushUndo(); fn(parseFloat(e.target.value) || 0); saveLocal(); renderInspector(); };
      return r;
    };
    const txtRow = (lbl, val, fn) => {
      const r = document.createElement("div"); r.className = "field-row";
      r.innerHTML = `<label>${lbl}</label><input type="text" value="${String(val || "").replace(/"/g, "&quot;")}" />`;
      r.querySelector("input").onchange = e => { pushUndo(); fn(e.target.value); saveLocal(); renderAllSidebars(); };
      return r;
    };
    const selRow = (lbl, val, opts, fn) => {
      const r = document.createElement("div"); r.className = "field-row";
      r.innerHTML = `<label>${lbl}</label><select>${opts.map(([v, t]) => `<option value="${v}">${t}</option>`).join("")}</select>`;
      const s = r.querySelector("select"); s.value = val;
      s.onchange = () => { pushUndo(); fn(s.value); saveLocal(); renderInspector(); };
      return r;
    };
    const chkRow = (lbl, val, fn) => {
      const w = document.createElement("label"); w.className = "inline"; w.style.marginBottom = "6px";
      w.innerHTML = `<input type="checkbox" ${val ? "checked" : ""} /> ${lbl}`;
      w.querySelector("input").onchange = e => { pushUndo(); fn(e.target.checked); saveLocal(); };
      return w;
    };

    const xy = document.createElement("div"); xy.className = "field-grid-2";
    xy.append(numRow("X", obj.x, v => obj.x = v), numRow("Y", obj.y, v => obj.y = v));
    if (obj.w !== undefined) xy.append(numRow("Width", obj.w, v => obj.w = Math.max(12, v)), numRow("Height", obj.h, v => obj.h = Math.max(12, v)));
    box.appendChild(xy);

    if (selected.kind === "room") box.appendChild(txtRow("Room Name", obj.name, v => obj.name = v));
    if (selected.kind === "node") {
      box.appendChild(txtRow("Node ID", obj.id, v => obj.id = v));
      box.appendChild(txtRow("Label", obj.label, v => obj.label = v));
      const t = obj.type;
      if (["gate", "drawbridge", "serpent_vent", "treasure", "relay"].includes(t)) {
        box.appendChild(selRow("Logic Gate Mode", obj.logicMode || "ALL", [["ALL", "ALL inputs (AND)"], ["ANY", "ANY input (OR)"], ["NOT", "INVERTED (NOT)"], ["SEQUENCE", "SEQUENCE (#1 → #2)"]], v => obj.logicMode = v));
      }
      if (t === "color_block") box.appendChild(selRow("Crystal Color", obj.color || "red", [["red", "Red Phase"], ["blue", "Blue Phase"]], v => { obj.color = v; obj.tex = v === "red" ? "dk_block_red.png" : "dk_block_blue.png"; }));
      if (t === "locked_door") box.appendChild(selRow("Key Required", obj.keyType || "small", [["small", "Small Brass Key"], ["boss", "Crimson Boss Key"]], v => { obj.keyType = v; obj.tex = v === "boss" ? "dk_door_boss.png" : "dk_door_locked.png"; }));
      if (["conveyor", "dart_turret"].includes(t)) box.appendChild(selRow("Direction", obj.dir || "right", [["right", "Right →"], ["left", "Left ←"], ["up", "Up ↑"], ["down", "Down ↓"]], v => { obj.dir = v; if (t === "conveyor") obj.tex = `dk_conveyor_${v}.png`; }));
      if (t === "patrol_blade") {
        box.appendChild(selRow("Patrol Axis", obj.axis || "h", [["h", "Horizontal ↔"], ["v", "Vertical ↕"]], v => obj.axis = v));
        const g = document.createElement("div"); g.className = "field-grid-2";
        g.append(numRow("Range px", obj.rangePx || 160, v => obj.rangePx = Math.max(16, v)), numRow("Speed", obj.speed || 95, v => obj.speed = Math.max(10, v)));
        box.appendChild(g);
      }
      if (["spike_trap", "dart_turret", "flame_jet"].includes(t)) box.appendChild(numRow("Cycle Sec", obj.periodSec || 2.4, v => obj.periodSec = Math.max(0.6, v)));
      if (["timer_switch", "resonance_crystal", "lever"].includes(t)) box.appendChild(numRow("Hold Sec (0=stay)", obj.holdSec || 0, v => obj.holdSec = Math.max(0, v)));
      if (["collapsing_floor", "relay"].includes(t)) box.appendChild(numRow("Delay Sec", obj.delaySec || 0.7, v => obj.delaySec = Math.max(0, v)));
      if (t === "teleporter") box.appendChild(txtRow("Warp Pair ID", obj.pairId || "alpha", v => obj.pairId = v));
      if (t === "conveyor") box.appendChild(numRow("Push Speed", obj.speed || 85, v => obj.speed = Math.max(10, v)));
      if (t === "chime_bell" || t === "heat_plate") box.appendChild(numRow("Radius px", obj.radius || 180, v => obj.radius = Math.max(32, v)));
      if (t === "sarcophagus") box.appendChild(chkRow("Is Spike Trap Tomb", !!obj.isTrap, v => obj.isTrap = v));
      if (t === "decor") {
        box.appendChild(chkRow("Solid Collider", obj.solid !== false, v => obj.solid = v));
        box.appendChild(chkRow("Emit Torch Light", !!obj.light, v => obj.light = v));
      }
      if (t === "plaque" || t === "npc" || t === "trigger_zone") {
        box.appendChild(txtRow("Speaker", obj.speaker || "", v => obj.speaker = v));
        const taWrap = document.createElement("div"); taWrap.className = "field-row";
        taWrap.innerHTML = `<label>Dialogue / Riddle Text</label><textarea rows="3" style="width:100%;background:#18161d;color:var(--text);border:1px solid var(--border);padding:5px;font-size:11px;">${obj.text || ""}</textarea>`;
        taWrap.querySelector("textarea").onchange = e => { pushUndo(); obj.text = e.target.value; saveLocal(); };
        box.appendChild(taWrap);
      }
      if (t === "treasure") {
        box.appendChild(txtRow("Item Reward", obj.itemReward || "", v => obj.itemReward = v));
        box.appendChild(numRow("Dragon Bond +", obj.bondReward || 15, v => obj.bondReward = v));
      }
      if (t === "exit_portal") box.appendChild(txtRow("Target Godot Region", obj.targetRegion || "old_heverlee", v => obj.targetRegion = v));

      const relWires = dungeon.wires.filter(w => w.from === obj.id || w.to === obj.id);
      const wTitle = document.createElement("div"); wTitle.className = "cat-title"; wTitle.textContent = `Logic Wires (${relWires.length})`;
      box.appendChild(wTitle);
      for (const w of relWires) {
        const row = document.createElement("div");
        row.style.cssText = "display:flex;align-items:center;justify-content:space-between;background:var(--panel-alt);padding:4px 6px;border-radius:3px;margin-bottom:4px;font-size:11px;";
        row.innerHTML = `<span>#${w.order || 1}: <b>${w.from}</b> → <b>${w.to}</b></span>`;
        const delW = document.createElement("button"); delW.className = "danger"; delW.style.cssText = "padding:1px 6px;font-size:10px;"; delW.textContent = "×";
        delW.onclick = () => { pushUndo(); dungeon.wires = dungeon.wires.filter(x => x.id !== w.id); saveLocal(); renderInspector(); };
        row.appendChild(delW);
        box.appendChild(row);
      }

      if (obj.tex && window.openSpriteInPixelStudio) {
        const pxBtn = document.createElement("button"); pxBtn.style.cssText = "width:100%;margin-top:6px;";
        pxBtn.textContent = `🎨 Edit ${obj.tex} in Pixel Studio`;
        pxBtn.onclick = () => window.openSpriteInPixelStudio(obj.tex);
        box.appendChild(pxBtn);
      }
    }

    if (selected.kind !== "spawn") {
      const act = document.createElement("div"); act.className = "inspector-actions";
      const dup = document.createElement("button"); dup.textContent = "Duplicate"; dup.onclick = duplicateSelected;
      const del = document.createElement("button"); del.className = "danger"; del.textContent = "Delete"; del.onclick = deleteSelected;
      act.append(dup, del);
      box.appendChild(act);
    }
  }

  function deleteSelected() {
    if (!selected || selected.kind === "spawn") return;
    pushUndo();
    if (selected.kind === "room") dungeon.rooms = dungeon.rooms.filter(r => r.id !== selected.id);
    else if (selected.kind === "chasm") dungeon.chasms = dungeon.chasms.filter(c => c.id !== selected.id);
    else if (selected.kind === "wall") dungeon.walls = dungeon.walls.filter(w => w.id !== selected.id);
    else if (selected.kind === "node") {
      dungeon.nodes = dungeon.nodes.filter(n => n.id !== selected.id);
      dungeon.wires = dungeon.wires.filter(w => w.from !== selected.id && w.to !== selected.id);
    }
    selected = null; saveLocal(); renderAllSidebars();
  }

  function duplicateSelected() {
    const obj = getSelectedObj();
    if (!obj || selected.kind === "spawn") return;
    pushUndo();
    const copy = clone(obj);
    copy.id = uid(copy.type || selected.kind);
    copy.x += 32; copy.y += 32;
    dungeon[selected.kind + "s"].push(copy);
    selected = { kind: selected.kind, id: copy.id };
    saveLocal(); renderAllSidebars();
  }

  // Live Playtest Simulator
  const keys = new Set();
  const sim = {
    px: 320, py: 730, facing: [0, -1], dx: 280, dy: 745,
    hp: 4, maxHp: 4, states: {}, pos: {}, hits: {}, hold: {}, collapse: {}, turret: {}, seqProgress: {},
    crystalPhase: 0, keysSmall: 0, keysBoss: 0, florins: 0,
    sparks: [], bolts: [], emberAnim: null, slashAnim: 0, trapT: 0, dmgCd: 0, tpCd: 0, safePos: { x: 320, y: 730 }, dlg: null,
  };

  function resetPlaytest() {
    sim.px = dungeon.spawn?.x || 320; sim.py = dungeon.spawn?.y || 730;
    sim.safePos = { x: sim.px, y: sim.py };
    sim.dx = sim.px - 26; sim.dy = sim.py + 12;
    sim.hp = 4; sim.maxHp = 4; sim.crystalPhase = 0; sim.keysSmall = 0; sim.keysBoss = 0; sim.florins = 0;
    sim.states = {}; sim.pos = {}; sim.hits = {}; sim.hold = {}; sim.collapse = {}; sim.turret = {}; sim.seqProgress = {};
    sim.sparks = []; sim.bolts = []; sim.emberAnim = null; sim.slashAnim = 0; sim.trapT = 0; sim.dmgCd = 0; sim.tpCd = 0; sim.dlg = null;
    document.getElementById("dnDlgBox").style.display = "none";
    for (const n of dungeon.nodes) { sim.pos[n.id] = { x: n.x, y: n.y }; sim.states[n.id] = false; }
    evaluateSimWires();
    updateHudBar();
  }

  function simNodePos(n) { return sim.pos[n.id] || { x: n.x, y: n.y }; }
  function isSimEnabled(targetId) {
    const inc = dungeon.wires.filter(w => w.to === targetId);
    if (!inc.length) return true;
    const tgt = dungeon.nodes.find(n => n.id === targetId);
    const mode = tgt?.logicMode || "ALL";
    const active = inc.filter(w => !!sim.states[w.from]).length;
    if (mode === "ANY") return active > 0;
    if (mode === "NOT") return active === 0;
    if (mode === "SEQUENCE") return (sim.seqProgress[targetId] || 0) >= inc.length;
    return active === inc.length;
  }
  function evaluateSimWires(triggerId) {
    if (triggerId) {
      for (const w of dungeon.wires) {
        if (w.from !== triggerId) continue;
        const tgt = dungeon.nodes.find(n => n.id === w.to);
        if (tgt?.logicMode === "SEQUENCE") {
          const ordered = dungeon.wires.filter(x => x.to === w.to).sort((a, b) => (a.order || 1) - (b.order || 1));
          const step = sim.seqProgress[w.to] || 0;
          if (step < ordered.length && ordered[step].from === triggerId) sim.seqProgress[w.to] = step + 1;
          else { sim.seqProgress[w.to] = 0; ordered.forEach(ow => sim.states[ow.from] = false); }
        }
      }
    }
    for (let pass = 0; pass < 3; pass++) {
      for (const n of dungeon.nodes) {
        if (!["gate", "drawbridge", "relay"].includes(n.type)) continue;
        const hasIn = dungeon.wires.some(w => w.to === n.id);
        const want = hasIn && isSimEnabled(n.id);
        const cur = !!sim.states[n.id];
        const nxt = (n.latch !== false && n.type !== "relay") ? (cur || want) : want;
        if (nxt !== cur) {
          sim.states[n.id] = nxt;
          if (n.type !== "relay") { const c = nodeCenter(n); spawnSimSparks(c.x, c.y, "#ffd66b", 16); }
        }
      }
    }
    updateHudBar();
  }
  function spawnSimSparks(x, y, col, count = 10) {
    for (let i = 0; i < count; i++) {
      const a = Math.random() * Math.PI * 2, s = 30 + Math.random() * 80;
      sim.sparks.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, life: 0.45, col });
    }
  }
  function simPointBlocked(x, y) {
    if (!dungeon.rooms.some(r => x >= r.x + 10 && x <= r.x + r.w - 10 && y >= r.y + 10 && y <= r.y + r.h - 10)) return true;
    const bridges = dungeon.nodes.filter(n => n.type === "drawbridge" && sim.states[n.id]);
    for (const c of dungeon.chasms) {
      if (x >= c.x - 6 && x <= c.x + c.w + 6 && y >= c.y - 6 && y <= c.y + c.h + 6) {
        if (!bridges.some(b => x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h)) return true;
      }
    }
    for (const w of dungeon.walls) if (x >= w.x - 9 && x <= w.x + w.w + 9 && y >= w.y - 9 && y <= w.y + w.h + 9) return true;
    for (const n of dungeon.nodes) {
      const r = nodeRect(n, simNodePos(n));
      const st = !!sim.states[n.id];
      if (["gate", "locked_door", "secret_wall", "cracked_wall"].includes(n.type) && !st && x >= r.x - 8 && x <= r.x + r.w + 8 && y >= r.y - 8 && y <= r.y + r.h + 8) return true;
      if (n.type === "color_block" && ((n.color || "red") === "red") === (sim.crystalPhase === 0) && x >= r.x - 7 && x <= r.x + r.w + 7 && y >= r.y - 7 && y <= r.y + r.h + 7) return true;
      if (n.type === "collapsing_floor" && st && x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h) return true;
      if (["boulder", "sarcophagus", "treasure", "decor"].includes(n.type) && (n.type !== "decor" || n.solid !== false) && Math.hypot(x - (r.x + r.w * 0.5), y - (r.y + r.h * 0.5)) < 17) return true;
      if ((n.type === "briar_barrier" || n.type === "breakable_pot") && !st && Math.abs(x - (r.x + r.w * 0.5)) < r.w * 0.5 + 4 && Math.abs(y - (r.y + r.h * 0.5)) < r.h * 0.5 + 4) return true;
    }
    return false;
  }

  function showSimDlg(speaker, text) {
    sim.dlg = { speaker, text };
    document.getElementById("dnDlgSpeaker").textContent = speaker;
    document.getElementById("dnDlgText").textContent = text;
    document.getElementById("dnDlgBox").style.display = "block";
  }

  function simActionE() {
    if (sim.dlg) { sim.dlg = null; document.getElementById("dnDlgBox").style.display = "none"; return; }
    for (const n of dungeon.nodes) {
      const c = nodeCenter(n, simNodePos(n));
      if (Math.hypot(sim.px - c.x, sim.py - c.y) > 64) continue;
      if (n.type === "lever" || n.type === "timer_switch") {
        sim.states[n.id] = n.type === "timer_switch" ? true : !sim.states[n.id];
        if (n.holdSec > 0) sim.hold[n.id] = n.holdSec;
        spawnSimSparks(c.x, c.y, "#ffd66b", 12);
        evaluateSimWires(n.id);
        return;
      }
      if (n.type === "chime_bell") {
        spawnSimSparks(c.x, c.y, "#ffd66b", 20);
        for (const o of dungeon.nodes) {
          if (o.type === "resonance_crystal" && Math.hypot(o.x - c.x, o.y - c.y) <= (n.radius || 260)) {
            sim.states[o.id] = true; sim.hold[o.id] = o.holdSec || 6;
            spawnSimSparks(o.x, o.y, "#66f2a6", 14);
            evaluateSimWires(o.id);
          }
        }
        return;
      }
      if (n.type === "healing_spring") { sim.hp = sim.maxHp; spawnSimSparks(c.x, c.y, "#74d4ff", 16); updateHudBar(); return; }
      if (n.type === "locked_door" && !sim.states[n.id]) {
        const isBoss = (n.keyType || "small") === "boss";
        if ((isBoss ? sim.keysBoss : sim.keysSmall) > 0) {
          if (isBoss) sim.keysBoss--; else sim.keysSmall--;
          sim.states[n.id] = true; spawnSimSparks(c.x, c.y, "#ffd66b", 18); evaluateSimWires(n.id);
        } else showSimDlg("Golden Hatchling", `Locked! Needs a ${isBoss ? "Crimson Boss Key" : "Small Brass Key"}.`);
        return;
      }
      if (n.type === "plaque" || n.type === "npc") { showSimDlg(n.speaker || n.label, n.text || "..."); return; }
      if (n.type === "treasure" && !sim.states[n.id]) {
        if (!isSimEnabled(n.id)) showSimDlg("Golden Hatchling", "An iron ward still binds this reliquary chest.");
        else { sim.states[n.id] = true; spawnSimSparks(c.x, c.y, "#ffd66b", 22); showSimDlg("Treasure", `Claimed ${n.itemReward || "Relic"}!`); }
        return;
      }
    }
  }

  function simActionV() {
    if (sim.dlg) return;
    sim.slashAnim = 0.2;
    const tx = sim.px + sim.facing[0] * 26, ty = sim.py + sim.facing[1] * 26;
    for (const n of dungeon.nodes) {
      const c = nodeCenter(n, simNodePos(n));
      if (Math.hypot(tx - c.x, ty - c.y) > 42) continue;
      if (n.type === "crystal_switch") {
        sim.crystalPhase = 1 - sim.crystalPhase;
        sim.states[n.id] = sim.crystalPhase === 1;
        spawnSimSparks(c.x, c.y, sim.crystalPhase ? "#ff7777" : "#77aaff", 14);
        evaluateSimWires(n.id); return;
      }
      if (n.type === "breakable_pot" && !sim.states[n.id]) {
        sim.states[n.id] = true; sim.florins += 2;
        spawnSimSparks(c.x, c.y, "#c87a52", 12); updateHudBar(); return;
      }
      if (n.type === "cracked_wall" && !sim.states[n.id]) {
        sim.hits[n.id] = (sim.hits[n.id] || 0) + 1;
        spawnSimSparks(c.x, c.y, "#b8b0a0", 10);
        if (sim.hits[n.id] >= (n.hitsNeeded || 3)) { sim.states[n.id] = true; evaluateSimWires(n.id); }
        return;
      }
      if (n.type === "timer_switch") {
        sim.states[n.id] = true; sim.hold[n.id] = n.holdSec || 8;
        spawnSimSparks(c.x, c.y, "#ffd66b", 12); evaluateSimWires(n.id); return;
      }
    }
  }

  function simActionR() {
    if (sim.dlg) return;
    for (const n of dungeon.nodes) {
      if (sim.states[n.id]) continue;
      const c = nodeCenter(n, simNodePos(n));
      if (Math.hypot(sim.px - c.x, sim.py - c.y) > 96) continue;
      if (["ember_brazier", "briar_barrier", "secret_wall"].includes(n.type)) {
        sim.dx = c.x; sim.dy = c.y + 24;
        sim.emberAnim = { x0: sim.dx, y0: sim.dy - 8, x1: c.x, y1: c.y, t: 0.35 };
        sim.states[n.id] = true; spawnSimSparks(c.x, c.y, "#ffae38", 16); evaluateSimWires(n.id); return;
      }
      if (n.type === "serpent_vent") {
        if (!isSimEnabled(n.id)) { spawnSimSparks(c.x, c.y, "#d9534f", 10); return; }
        sim.dx = c.x; sim.dy = c.y; sim.states[n.id] = true;
        spawnSimSparks(c.x, c.y, "#ffd66b", 18); evaluateSimWires(n.id); return;
      }
    }
  }

  function simActionF() {
    if (sim.dlg) return;
    for (const n of dungeon.nodes) {
      const p = simNodePos(n);
      if (n.type === "boulder" && Math.hypot(sim.px - p.x, sim.py - p.y) <= 50) {
        const dx = p.x - sim.px, dy = p.y - sim.py;
        const ax = Math.abs(dx) >= Math.abs(dy) ? [Math.sign(dx), 0] : [0, Math.sign(dy)];
        const nx = p.x + ax[0] * 42, ny = p.y + ax[1] * 42;
        if (!simPointBlocked(nx, ny)) {
          sim.pos[n.id] = { x: nx, y: ny }; spawnSimSparks(nx, ny, "#dcd0aa", 8);
          for (const pl of dungeon.nodes) {
            if (pl.type === "weight_plate" && Math.hypot(nx - pl.x, ny - pl.y) <= 28) {
              sim.pos[n.id] = { x: pl.x, y: pl.y }; sim.states[pl.id] = true;
              spawnSimSparks(pl.x, pl.y, "#ffd66b", 16); evaluateSimWires(pl.id);
            }
          }
        }
        return;
      }
      if (n.type === "sarcophagus" && !sim.states[n.id] && Math.hypot(sim.px - p.x, sim.py - p.y) <= 54) {
        sim.states[n.id] = true; sim.pos[n.id] = { x: p.x, y: p.y - 42 };
        if (n.isTrap) { sim.hp = Math.max(0, sim.hp - 1); spawnSimSparks(p.x, p.y, "#ff4b4b", 14); updateHudBar(); }
        else { spawnSimSparks(p.x, p.y, "#ffd66b", 16); evaluateSimWires(n.id); }
        return;
      }
      if (n.type === "grapple_post" && Math.hypot(sim.px - p.x, sim.py - p.y) > 48 && Math.hypot(sim.px - p.x, sim.py - p.y) <= 260) {
        const jd = Math.hypot(p.x - sim.px, p.y - sim.py);
        sim.px = p.x + ((p.x - sim.px) / jd) * 28; sim.py = p.y + ((p.y - sim.py) / jd) * 28;
        spawnSimSparks(p.x, p.y, "#ffd66b", 14); return;
      }
    }
  }

  // Canvas & Handle Geometry
  function screenToWorld(sx, sy) { return { x: sx / cam.zoom + cam.x, y: sy / cam.zoom + cam.y }; }
  function fitDungeon() {
    const W = dungeon.worldSize?.w || 1600, H = dungeon.worldSize?.h || 960;
    cam.zoom = Math.max(0.25, Math.min(1.5, Math.min((canvas.width - 60) / W, (canvas.height - 60) / H)));
    cam.x = -(canvas.width / cam.zoom - W) * 0.5;
    cam.y = -(canvas.height / cam.zoom - H) * 0.5;
  }
  function getHandles(r) {
    return [
      { id: "nw", x: r.x, y: r.y }, { id: "ne", x: r.x + r.w, y: r.y },
      { id: "se", x: r.x + r.w, y: r.y + r.h }, { id: "sw", x: r.x, y: r.y + r.h },
      { id: "e", x: r.x + r.w, y: r.y + r.h * 0.5 }, { id: "s", x: r.x + r.w * 0.5, y: r.y + r.h },
    ];
  }

  let dragMode = null, dragStart = null, dragOrig = null, resizeHandle = null, previewBox = null, mouseWorld = { x: 0, y: 0 };

  function hitTestNode(wx, wy) {
    for (let i = dungeon.nodes.length - 1; i >= 0; i--) {
      const n = dungeon.nodes[i], r = nodeRect(n);
      if (wx >= r.x - 4 && wx <= r.x + r.w + 4 && wy >= r.y - 4 && wy <= r.y + r.h + 4) return n;
    }
    return null;
  }

  canvas.addEventListener("contextmenu", e => e.preventDefault());
  canvas.addEventListener("wheel", e => {
    e.preventDefault();
    const rect = canvas.getBoundingClientRect();
    const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
    const before = screenToWorld(sx, sy);
    cam.zoom = Math.max(0.2, Math.min(2.5, cam.zoom * (e.deltaY < 0 ? 1.12 : 0.89)));
    cam.x = before.x - sx / cam.zoom; cam.y = before.y - sy / cam.zoom;
  }, { passive: false });

  canvas.addEventListener("mousedown", e => {
    const rect = canvas.getBoundingClientRect();
    const w = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
    if (e.button === 2 || e.button === 1) { dragMode = "pan"; dragStart = { x: e.clientX, y: e.clientY, cx: cam.x, cy: cam.y }; return; }
    if (playtestActive) return;

    // Check resize handles on current selection
    const curObj = getSelectedObj();
    if (editTool === "select" && curObj && curObj.w !== undefined && selected.kind !== "spawn") {
      const rr = selected.kind === "node" ? nodeRect(curObj) : curObj;
      const hh = getHandles(rr).find(h => Math.hypot(w.x - h.x, w.y - h.y) <= 9 / cam.zoom);
      if (hh) { pushUndo(); dragMode = "resize"; resizeHandle = hh.id; dragStart = w; dragOrig = { ...rr }; return; }
    }

    const hitN = hitTestNode(w.x, w.y);
    if (editTool === "erase") {
      if (hitN) { selected = { kind: "node", id: hitN.id }; deleteSelected(); return; }
      const hitW = dungeon.walls.find(x => w.x >= x.x && w.x <= x.x + x.w && w.y >= x.y && w.y <= x.y + x.h);
      if (hitW) { selected = { kind: "wall", id: hitW.id }; deleteSelected(); return; }
      const hitC = dungeon.chasms.find(x => w.x >= x.x && w.x <= x.x + x.w && w.y >= x.y && w.y <= x.y + x.h);
      if (hitC) { selected = { kind: "chasm", id: hitC.id }; deleteSelected(); return; }
      const hitR = dungeon.rooms.find(x => w.x >= x.x && w.x <= x.x + x.w && w.y >= x.y && w.y <= x.y + x.h);
      if (hitR) { selected = { kind: "room", id: hitR.id }; deleteSelected(); return; }
      return;
    }
    if (editTool === "wire") {
      if (!hitN) { wireStartNodeId = null; updateHudBar(); return; }
      if (!wireStartNodeId) { wireStartNodeId = hitN.id; dragMode = "wire"; updateHudBar(); }
      else if (wireStartNodeId !== hitN.id) {
        pushUndo();
        const ord = dungeon.wires.filter(x => x.to === hitN.id).length + 1;
        dungeon.wires.push({ id: uid("w"), from: wireStartNodeId, to: hitN.id, kind: "open", order: ord });
        saveLocal(); selected = { kind: "node", id: hitN.id }; renderAllSidebars();
        wireStartNodeId = null; updateHudBar();
      }
      return;
    }
    if (editTool === "stamp" && activeStamp) {
      pushUndo();
      const id = uid(activeStamp.type);
      const isC = isCornerType(activeStamp.type);
      const node = { ...activeStamp, id, x: snap(w.x) - (isC ? Math.round(activeStamp.w / 2) : 0), y: snap(w.y) - (isC ? Math.round(activeStamp.h / 2) : 0) };
      delete node.kind;
      dungeon.nodes.push(node);
      selected = { kind: "node", id };
      saveLocal(); renderAllSidebars(); return;
    }
    if (["room", "chasm", "wall"].includes(editTool)) {
      dragMode = "draw"; dragStart = { x: snap(w.x), y: snap(w.y) }; previewBox = { x: dragStart.x, y: dragStart.y, w: 32, h: 32 }; return;
    }

    if (dungeon.spawn && Math.hypot(w.x - dungeon.spawn.x, w.y - dungeon.spawn.y) <= 20) {
      selected = { kind: "spawn", id: "spawn" }; pushUndo(); dragMode = "move"; dragStart = w; dragOrig = { ...dungeon.spawn }; renderAllSidebars(); return;
    }
    if (hitN) { selected = { kind: "node", id: hitN.id }; pushUndo(); dragMode = "move"; dragStart = w; dragOrig = { ...hitN }; renderAllSidebars(); return; }
    for (const [k, list] of [["wall", dungeon.walls], ["chasm", dungeon.chasms], ["room", dungeon.rooms]]) {
      const hit = list.find(x => w.x >= x.x && w.x <= x.x + x.w && w.y >= x.y && w.y <= x.y + x.h);
      if (hit) { selected = { kind: k, id: hit.id }; pushUndo(); dragMode = "move"; dragStart = w; dragOrig = { ...hit }; renderAllSidebars(); return; }
    }
    selected = null; renderAllSidebars();
  });

  window.addEventListener("mousemove", e => {
    const rect = canvas.getBoundingClientRect();
    mouseWorld = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
    if (e.target === canvas) document.getElementById("dnStatCursor").textContent = `Cursor: ${Math.round(mouseWorld.x)}, ${Math.round(mouseWorld.y)} | Zoom: ${Math.round(cam.zoom * 100)}%`;
    if (dragMode === "pan") {
      cam.x = dragStart.cx - (e.clientX - dragStart.x) / cam.zoom;
      cam.y = dragStart.cy - (e.clientY - dragStart.y) / cam.zoom;
    } else if (dragMode === "move" && dragOrig) {
      const obj = getSelectedObj();
      if (obj) { obj.x = dragOrig.x + snap(mouseWorld.x - dragStart.x); obj.y = dragOrig.y + snap(mouseWorld.y - dragStart.y); }
    } else if (dragMode === "resize" && dragOrig) {
      const obj = getSelectedObj();
      if (obj) {
        const dx = snap(mouseWorld.x - dragStart.x), dy = snap(mouseWorld.y - dragStart.y);
        let nx = dragOrig.x, ny = dragOrig.y, nw = dragOrig.w, nh = dragOrig.h;
        if (resizeHandle.includes("e")) nw = Math.max(16, dragOrig.w + dx);
        if (resizeHandle.includes("s")) nh = Math.max(16, dragOrig.h + dy);
        if (resizeHandle.includes("w")) { nx = dragOrig.x + dx; nw = Math.max(16, dragOrig.w - dx); }
        if (resizeHandle.includes("n")) { ny = dragOrig.y + dy; nh = Math.max(16, dragOrig.h - dy); }
        if (selected.kind === "node" && !isCornerType(obj.type)) { obj.x = nx + nw * 0.5; obj.y = ny + nh * 0.5; }
        else { obj.x = nx; obj.y = ny; }
        obj.w = nw; obj.h = nh;
      }
    } else if (dragMode === "draw") {
      const sx2 = snap(mouseWorld.x), sy2 = snap(mouseWorld.y);
      previewBox = { x: Math.min(dragStart.x, sx2), y: Math.min(dragStart.y, sy2), w: Math.max(24, Math.abs(sx2 - dragStart.x)), h: Math.max(24, Math.abs(sy2 - dragStart.y)) };
    }
  });

  window.addEventListener("mouseup", e => {
    if (dragMode === "wire") {
      const rect = canvas.getBoundingClientRect();
      const w = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
      const hitN = hitTestNode(w.x, w.y);
      if (hitN && wireStartNodeId && hitN.id !== wireStartNodeId) {
        pushUndo();
        const ord = dungeon.wires.filter(x => x.to === hitN.id).length + 1;
        dungeon.wires.push({ id: uid("w"), from: wireStartNodeId, to: hitN.id, kind: "open", order: ord });
        saveLocal(); selected = { kind: "node", id: hitN.id }; renderAllSidebars();
        wireStartNodeId = null; updateHudBar();
      }
    } else if (dragMode === "draw" && previewBox) {
      pushUndo();
      const id = uid(editTool);
      if (editTool === "room") dungeon.rooms.push({ id, name: "New Chamber", ...previewBox });
      else if (editTool === "chasm") dungeon.chasms.push({ id, ...previewBox });
      else if (editTool === "wall") dungeon.walls.push({ id, ...previewBox });
      selected = { kind: editTool, id }; saveLocal(); renderAllSidebars();
    } else if (dragMode === "move" || dragMode === "resize") { saveLocal(); renderInspector(); }
    dragMode = null; previewBox = null; resizeHandle = null;
  });

  window.addEventListener("keydown", e => {
    if (!rootEl.classList.contains("active")) return;
    if (["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement?.tagName)) return;
    const k = e.key.toLowerCase();
    keys.add(k);
    if (k === "p") { document.getElementById("dnPlayBtn").click(); e.preventDefault(); return; }
    if (playtestActive) {
      if (k === "e") { simActionE(); e.preventDefault(); }
      else if (k === "v" || k === " ") { simActionV(); e.preventDefault(); }
      else if (k === "r") { simActionR(); e.preventDefault(); }
      else if (k === "f") { simActionF(); e.preventDefault(); }
      else if (["arrowup", "arrowdown", "arrowleft", "arrowright"].includes(k)) e.preventDefault();
    } else {
      if ((e.ctrlKey || e.metaKey) && k === "z") { e.preventDefault(); doUndo(); }
      else if ((e.ctrlKey || e.metaKey) && k === "y") { e.preventDefault(); doRedo(); }
      else if ((e.ctrlKey || e.metaKey) && k === "d") { e.preventDefault(); duplicateSelected(); }
      else if ((e.ctrlKey || e.metaKey) && k === "c") { const o = getSelectedObj(); if (o && selected.kind !== "spawn") clipboardItem = { kind: selected.kind, data: clone(o) }; }
      else if ((e.ctrlKey || e.metaKey) && k === "v" && clipboardItem) {
        pushUndo(); const copy = clone(clipboardItem.data); copy.id = uid(copy.type || clipboardItem.kind); copy.x += 24; copy.y += 24;
        dungeon[clipboardItem.kind + "s"].push(copy); selected = { kind: clipboardItem.kind, id: copy.id }; saveLocal(); renderAllSidebars();
      } else if (k === "escape") { activeStamp = null; setTool("select"); selected = null; renderAllSidebars(); }
      else if (k === "delete" || k === "backspace") deleteSelected();
    }
  });
  window.addEventListener("keyup", e => keys.delete(e.key.toLowerCase()));

  // Simulation Step & Render Loop
  let lastT = performance.now();
  function loop(now) {
    const dt = Math.min(0.05, (now - lastT) * 0.001);
    lastT = now;
    if (rootEl.classList.contains("active")) {
      const p = canvas.parentElement.getBoundingClientRect();
      const cw = Math.max(100, Math.floor(p.width)), ch = Math.max(100, Math.floor(p.height - 24));
      if (canvas.width !== cw || canvas.height !== ch) { canvas.width = cw; canvas.height = ch; }

      if (playtestActive) {
        sim.trapT += dt;
        if (sim.dmgCd > 0) sim.dmgCd -= dt;
        if (sim.tpCd > 0) sim.tpCd -= dt;
        if (sim.slashAnim > 0) sim.slashAnim -= dt;
        if (sim.emberAnim) { sim.emberAnim.t -= dt; if (sim.emberAnim.t <= 0) sim.emberAnim = null; }

        // Expire timed switches
        for (const [hid, rem] of Object.entries(sim.hold)) {
          if (rem - dt <= 0) { delete sim.hold[hid]; sim.states[hid] = false; evaluateSimWires(); }
          else sim.hold[hid] = rem - dt;
        }

        if (!sim.dlg) {
          let vx = (keys.has("d") || keys.has("arrowright") ? 1 : 0) - (keys.has("a") || keys.has("arrowleft") ? 1 : 0);
          let vy = (keys.has("s") || keys.has("arrowdown") ? 1 : 0) - (keys.has("w") || keys.has("arrowup") ? 1 : 0);
          if (vx || vy) {
            const len = Math.hypot(vx, vy); vx /= len; vy /= len; sim.facing = [vx, vy];
            const spd = 165 * (keys.has("shift") ? 1.45 : 1.0) * dt;
            if (!simPointBlocked(sim.px + vx * spd, sim.py)) sim.px += vx * spd;
            if (!simPointBlocked(sim.px, sim.py + vy * spd)) sim.py += vy * spd;
          }
          const tx = sim.px - sim.facing[0] * 26, ty = sim.py - sim.facing[1] * 26;
          sim.dx += (tx - sim.dx) * Math.min(1, dt * 6); sim.dy += (ty - sim.dy) * Math.min(1, dt * 6);
        }

        // Step live nodes
        const dirVec = { right: [1, 0], left: [-1, 0], up: [0, -1], down: [0, 1] };
        let unsafe = false;
        for (const n of dungeon.nodes) {
          const r = nodeRect(n, simNodePos(n));
          const c = { x: r.x + r.w * 0.5, y: r.y + r.h * 0.5 };
          const armed = !dungeon.wires.some(w => w.to === n.id) || !isSimEnabled(n.id);
          if (n.type === "pressure_pad") {
            const occ = (sim.px >= r.x && sim.px <= r.x + r.w && sim.py >= r.y && sim.py <= r.y + r.h) || dungeon.nodes.some(o => o.type === "boulder" && Math.hypot(simNodePos(o).x - c.x, simNodePos(o).y - c.y) < 18);
            if (occ !== !!sim.states[n.id]) { sim.states[n.id] = occ; evaluateSimWires(occ ? n.id : ""); }
          } else if (n.type === "heat_plate") {
            const hot = dungeon.nodes.some(o => o.type === "ember_brazier" && sim.states[o.id] && Math.hypot(o.x - c.x, o.y - c.y) <= (n.radius || 110));
            if (hot !== !!sim.states[n.id]) { sim.states[n.id] = hot; evaluateSimWires(hot ? n.id : ""); }
          } else if (n.type === "conveyor" && sim.px >= r.x && sim.px <= r.x + r.w && sim.py >= r.y && sim.py <= r.y + r.h) {
            const dv = dirVec[n.dir || "right"] || [1, 0];
            const nx = sim.px + dv[0] * (n.speed || 85) * dt, ny = sim.py + dv[1] * (n.speed || 85) * dt;
            if (!simPointBlocked(nx, ny)) { sim.px = nx; sim.py = ny; }
          } else if (n.type === "teleporter" && sim.tpCd <= 0 && sim.px >= r.x && sim.px <= r.x + r.w && sim.py >= r.y && sim.py <= r.y + r.h) {
            const dst = dungeon.nodes.find(o => o.type === "teleporter" && o.id !== n.id && o.pairId === n.pairId);
            if (dst) { sim.tpCd = 1.2; const dc = nodeCenter(dst); sim.px = dc.x; sim.py = dc.y + 26; spawnSimSparks(dc.x, dc.y, "#88aaff", 14); }
          } else if (n.type === "collapsing_floor" && !sim.states[n.id] && sim.px >= r.x && sim.px <= r.x + r.w && sim.py >= r.y && sim.py <= r.y + r.h) {
            unsafe = true;
            sim.collapse[n.id] = (sim.collapse[n.id] || 0) + dt;
            if (sim.collapse[n.id] >= (n.delaySec || 0.7)) {
              sim.states[n.id] = true; sim.px = sim.safePos.x; sim.py = sim.safePos.y;
              if (sim.dmgCd <= 0) { sim.hp = Math.max(0, sim.hp - 1); sim.dmgCd = 1.0; updateHudBar(); }
            }
          } else if (n.type === "patrol_blade" && armed) {
            const rng = n.rangePx || 160, spd = n.speed || 95;
            const ph = (sim.trapT * spd / rng) % 2;
            const tri = ph <= 1 ? ph : 2 - ph;
            sim.pos[n.id] = { x: n.x + ((n.axis || "h") === "h" ? rng * tri : 0), y: n.y + ((n.axis || "h") === "v" ? rng * tri : 0) };
            if (sim.dmgCd <= 0 && Math.hypot(sim.px - sim.pos[n.id].x, sim.py - sim.pos[n.id].y) <= 19) {
              sim.hp = Math.max(0, sim.hp - 1); sim.dmgCd = 1.1; spawnSimSparks(sim.px, sim.py, "#ff5555", 10); updateHudBar();
            }
          } else if (n.type === "dart_turret" && armed) {
            sim.turret[n.id] = (sim.turret[n.id] || 0) + dt;
            if (sim.turret[n.id] >= (n.periodSec || 2.4)) {
              sim.turret[n.id] = 0; const dv = dirVec[n.dir || "right"] || [1, 0];
              sim.bolts.push({ x: c.x + dv[0] * 14, y: c.y + dv[1] * 14, vx: dv[0] * 240, vy: dv[1] * 240, life: 1.8 });
            }
          } else if (n.type === "flame_jet" && armed) {
            const cyc = n.periodSec || 3.0; const on = (sim.trapT % cyc) > cyc * 0.55;
            sim.states[n.id] = on;
            if (on && sim.dmgCd <= 0 && Math.hypot(sim.px - c.x, sim.py - (c.y - 10)) <= 24) {
              sim.hp = Math.max(0, sim.hp - 1); sim.dmgCd = 1.1; spawnSimSparks(sim.px, sim.py, "#ff8833", 10); updateHudBar();
            }
          } else if (n.type === "trigger_zone" && !sim.states[n.id] && sim.px >= r.x && sim.px <= r.x + r.w && sim.py >= r.y && sim.py <= r.y + r.h) {
            sim.states[n.id] = true;
            if (n.text) showSimDlg(n.speaker || "Golden Hatchling", n.text);
            evaluateSimWires(n.id);
          } else if (["key_small", "key_boss", "heart_pickup", "heart_container", "coin"].includes(n.type) && !sim.states[n.id] && Math.hypot(sim.px - c.x, sim.py - c.y) <= 22) {
            sim.states[n.id] = true;
            if (n.type === "key_small") sim.keysSmall++;
            else if (n.type === "key_boss") sim.keysBoss++;
            else if (n.type === "coin") sim.florins += (n.value || 5);
            else if (n.type === "heart_pickup") sim.hp = Math.min(sim.maxHp, sim.hp + 1);
            else if (n.type === "heart_container") { sim.maxHp++; sim.hp = sim.maxHp; }
            spawnSimSparks(c.x, c.y, "#ffd66b", 12); updateHudBar();
          }
        }
        if (!unsafe && !simPointBlocked(sim.px, sim.py)) sim.safePos = { x: sim.px, y: sim.py };
        for (let i = sim.bolts.length - 1; i >= 0; i--) {
          const b = sim.bolts[i]; b.x += b.vx * dt; b.y += b.vy * dt; b.life -= dt;
          if (b.life <= 0) sim.bolts.splice(i, 1);
          else if (Math.hypot(b.x - sim.px, b.y - sim.py) <= 16) {
            sim.bolts.splice(i, 1); if (sim.dmgCd <= 0) { sim.hp = Math.max(0, sim.hp - 1); sim.dmgCd = 1.0; updateHudBar(); }
          }
        }
        for (let i = sim.sparks.length - 1; i >= 0; i--) {
          const s = sim.sparks[i]; s.x += s.vx * dt; s.y += s.vy * dt; s.life -= dt; if (s.life <= 0) sim.sparks.splice(i, 1);
        }
      }

      // Render Canvas
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.fillStyle = "#0a090e"; ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.save(); ctx.scale(cam.zoom, cam.zoom); ctx.translate(-cam.x, -cam.y); ctx.imageSmoothingEnabled = false;

      const W = dungeon.worldSize?.w || 1600, H = dungeon.worldSize?.h || 960;
      ctx.strokeStyle = "rgba(255,255,255,0.14)"; ctx.lineWidth = 2 / cam.zoom; ctx.strokeRect(0, 0, W, H);

      const floorCol = { catacomb_stone: "#2f2e36", obsidian_shrine: "#22222c", cathedral_flag: "#3b3c46", library_wood: "#4c3525" }[dungeon.floorStyle] || "#2f2e36";
      for (const r of dungeon.rooms) {
        ctx.fillStyle = floorCol; ctx.fillRect(r.x, r.y, r.w, r.h);
        ctx.strokeStyle = dungeon.floorStyle === "obsidian_shrine" ? "#b89038" : "#565a69"; ctx.lineWidth = 2 / cam.zoom; ctx.strokeRect(r.x, r.y, r.w, r.h);
      }
      if (showGrid && !playtestActive && snapPx >= 8) {
        const step = snapPx * 2;
        ctx.strokeStyle = "rgba(255,255,255,0.05)"; ctx.lineWidth = 1 / cam.zoom; ctx.beginPath();
        for (let gx = 0; gx <= W; gx += step) { ctx.moveTo(gx, 0); ctx.lineTo(gx, H); }
        for (let gy = 0; gy <= H; gy += step) { ctx.moveTo(0, gy); ctx.lineTo(W, gy); }
        ctx.stroke();
      }
      for (const c of dungeon.chasms) { ctx.fillStyle = "#194361"; ctx.fillRect(c.x, c.y, c.w, c.h); ctx.strokeStyle = "#488eb0"; ctx.strokeRect(c.x, c.y, c.w, c.h); }
      for (const w of dungeon.walls) { ctx.fillStyle = "#181720"; ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeStyle = "#4a4b5c"; ctx.strokeRect(w.x, w.y, w.w, w.h); }

      for (const n of dungeon.nodes) {
        const st = playtestActive && !!sim.states[n.id];
        if (playtestActive && st && ["briar_barrier", "secret_wall", "cracked_wall", "key_small", "key_boss", "heart_pickup", "heart_container", "coin"].includes(n.type)) continue;
        if (playtestActive && (n.type === "trigger_zone" || n.type === "relay")) continue;
        const r = nodeRect(n, playtestActive ? simNodePos(n) : n);
        if (n.type === "trigger_zone") {
          ctx.fillStyle = "rgba(155,89,182,0.22)"; ctx.fillRect(r.x, r.y, r.w, r.h);
          ctx.strokeStyle = "#c084e0"; ctx.strokeRect(r.x, r.y, r.w, r.h);
        } else {
          let tex = n.tex;
          if (playtestActive) {
            if (n.type === "gate" || n.type === "locked_door") tex = st ? "prop_shrine_door_open.png" : n.tex;
            else if (n.type === "color_block") { const solid = ((n.color || "red") === "red") === (sim.crystalPhase === 0); tex = (n.color === "blue") ? (solid ? "dk_block_blue.png" : "dk_block_blue_low.png") : (solid ? "dk_block_red.png" : "dk_block_red_low.png"); }
            else if (n.type === "crystal_switch") tex = sim.crystalPhase ? "dk_crystal_switch_1.png" : "dk_crystal_switch_0.png";
            else if (n.type === "pressure_pad") tex = st ? "dk_pressure_pad_down.png" : "dk_pressure_pad.png";
            else if (n.type === "heat_plate") tex = st ? "dk_heat_plate_lit.png" : "dk_heat_plate.png";
            else if (n.type === "resonance_crystal") tex = st ? "dk_resonance_crystal_lit.png" : "dk_resonance_crystal.png";
            else if (n.type === "timer_switch") tex = st ? "dk_timer_switch_on.png" : "dk_timer_switch.png";
            else if (n.type === "flame_jet") tex = st ? "dk_flame_jet_on.png" : "dk_flame_jet.png";
            else if (n.type === "collapsing_floor") tex = st ? "dk_floor_pit.png" : "dk_cracked_floor.png";
            else if (n.type === "breakable_pot") tex = st ? "dk_pot_broken.png" : "dk_pot.png";
            else if (n.type === "drawbridge" && !st) { ctx.strokeStyle = "rgba(221,168,76,0.35)"; ctx.strokeRect(r.x, r.y, r.w, r.h); continue; }
          }
          const im = getSpriteImg(tex);
          if (im && im.complete) {
            ctx.globalAlpha = ((n.type === "gate" || n.type === "locked_door") && st) ? 0.45 : 1.0;
            ctx.drawImage(im, r.x, r.y, r.w, r.h);
            ctx.globalAlpha = 1.0;
          } else { ctx.fillStyle = "#c89048"; ctx.fillRect(r.x, r.y, r.w, r.h); }
        }
        if (!playtestActive) { ctx.fillStyle = "#e8e0cf"; ctx.font = "10px sans-serif"; ctx.textAlign = "center"; ctx.fillText(n.label || n.id, r.x + r.w * 0.5, r.y - 4); }
      }

      if (!playtestActive) {
        for (const w of dungeon.wires) {
          const fn = dungeon.nodes.find(x => x.id === w.from), tn = dungeon.nodes.find(x => x.id === w.to);
          if (!fn || !tn) continue;
          const a = nodeCenter(fn), b = nodeCenter(tn);
          ctx.save(); ctx.strokeStyle = "#ffd66b"; ctx.lineWidth = 2.2 / cam.zoom; ctx.setLineDash([7, 5]);
          ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke(); ctx.restore();
          const mx = (a.x + b.x) * 0.5, my = (a.y + b.y) * 0.5;
          ctx.fillStyle = "#201c16"; ctx.beginPath(); ctx.arc(mx, my, 8, 0, Math.PI * 2); ctx.fill();
          ctx.strokeStyle = "#ffd66b"; ctx.lineWidth = 1.4 / cam.zoom; ctx.stroke();
          ctx.fillStyle = "#ffd66b"; ctx.font = "bold 9px sans-serif"; ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.fillText(`#${w.order || 1}`, mx, my);
        }
        if (wireStartNodeId) {
          const fn = dungeon.nodes.find(x => x.id === wireStartNodeId);
          if (fn) { const a = nodeCenter(fn); ctx.strokeStyle = "#8cf0a4"; ctx.lineWidth = 2 / cam.zoom; ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(mouseWorld.x, mouseWorld.y); ctx.stroke(); }
        }
        if (dungeon.spawn) {
          ctx.fillStyle = "rgba(92,184,116,0.35)"; ctx.beginPath(); ctx.arc(dungeon.spawn.x, dungeon.spawn.y, 14, 0, Math.PI * 2); ctx.fill();
          ctx.strokeStyle = "#5cb874"; ctx.lineWidth = 2 / cam.zoom; ctx.stroke();
        }
        const selObj = getSelectedObj();
        if (selObj && selected.kind !== "spawn") {
          const rr = selected.kind === "node" ? nodeRect(selObj) : selObj;
          ctx.strokeStyle = "#ffd66b"; ctx.lineWidth = 2 / cam.zoom; ctx.strokeRect(rr.x - 2, rr.y - 2, rr.w + 4, rr.h + 4);
          if (selObj.w !== undefined) for (const h of getHandles(rr)) { ctx.fillStyle = "#ffd66b"; ctx.fillRect(h.x - 4 / cam.zoom, h.y - 4 / cam.zoom, 8 / cam.zoom, 8 / cam.zoom); }
        }
        if (previewBox) { ctx.fillStyle = "rgba(221,168,76,0.22)"; ctx.fillRect(previewBox.x, previewBox.y, previewBox.w, previewBox.h); ctx.strokeStyle = "#dda84c"; ctx.strokeRect(previewBox.x, previewBox.y, previewBox.w, previewBox.h); }
      } else {
        const boyIm = getSpriteImg("boy17_down_0.png") || getSpriteImg("boy_down_0.png");
        if (boyIm && boyIm.complete) ctx.drawImage(boyIm, sim.px - 12, sim.py - 20, 24, 28);
        const drgIm = getSpriteImg("dragon_gold_s1_down_0.png");
        if (drgIm && drgIm.complete) ctx.drawImage(drgIm, sim.dx - 13, sim.dy - 14, 26, 22);
        if (sim.slashAnim > 0) { ctx.strokeStyle = "#e8f2ff"; ctx.lineWidth = 3 / cam.zoom; ctx.beginPath(); ctx.arc(sim.px + sim.facing[0] * 18, sim.py + sim.facing[1] * 18, 16, 0, Math.PI); ctx.stroke(); }
        if (sim.emberAnim) { ctx.strokeStyle = "#ffaa33"; ctx.lineWidth = 4 / cam.zoom; ctx.beginPath(); ctx.moveTo(sim.emberAnim.x0, sim.emberAnim.y0); ctx.lineTo(sim.emberAnim.x1, sim.emberAnim.y1); ctx.stroke(); }
        for (const b of sim.bolts) { ctx.fillStyle = "#f4e6b2"; ctx.beginPath(); ctx.arc(b.x, b.y, 3.5, 0, Math.PI * 2); ctx.fill(); }
        for (const s of sim.sparks) { ctx.fillStyle = s.col; ctx.globalAlpha = Math.max(0, s.life * 2); ctx.beginPath(); ctx.arc(s.x, s.y, 3, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1; }
      }
      ctx.restore();

      if ((dungeon.darkness || 0) > 0.02) {
        ctx.fillStyle = `rgba(8, 8, 16, ${Math.min(0.85, dungeon.darkness * (playtestActive ? 0.85 : 0.45))})`;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
      }
    }
    requestAnimationFrame(loop);
  }
  requestAnimationFrame(loop);

  // Toolbar & Tab Wiring
  document.getElementById("dnTabObj").onclick = () => { leftTab = "objects"; document.getElementById("dnTabObj").classList.add("active"); document.getElementById("dnTabInst").classList.remove("active"); document.getElementById("dnPalette").style.display = "block"; document.getElementById("dnInstances").style.display = "none"; };
  document.getElementById("dnTabInst").onclick = () => { leftTab = "instances"; document.getElementById("dnTabInst").classList.add("active"); document.getElementById("dnTabObj").classList.remove("active"); document.getElementById("dnPalette").style.display = "none"; document.getElementById("dnInstances").style.display = "block"; renderInstances(); };
  document.getElementById("dnTools").querySelectorAll("button").forEach(b => b.onclick = () => setTool(b.dataset.t));
  document.getElementById("dnSnapSel").onchange = e => { snapPx = parseInt(e.target.value, 10) || 1; };
  document.getElementById("dnGridChk").onchange = e => { showGrid = e.target.checked; };
  document.getElementById("dnDarkRange").oninput = e => { dungeon.darkness = (parseInt(e.target.value, 10) || 0) / 100; saveLocal(); };
  document.getElementById("dnUndoBtn").onclick = doUndo;
  document.getElementById("dnRedoBtn").onclick = doRedo;
  document.getElementById("dnDupBtn").onclick = duplicateSelected;
  document.getElementById("dnZoomOut").onclick = () => { cam.zoom = Math.max(0.2, cam.zoom / 1.2); };
  document.getElementById("dnZoomIn").onclick = () => { cam.zoom = Math.min(2.5, cam.zoom * 1.2); };
  document.getElementById("dnZoomFit").onclick = fitDungeon;

  document.getElementById("dnPresetSel").onchange = e => {
    const id = e.target.value; pushUndo();
    if (id === "blank") dungeon = { title: "Blank Studio Dungeon", worldSize: { w: 1600, h: 960 }, floorStyle: "catacomb_stone", ambience: "amb_catacombs", darkness: 0, spawn: { x: 260, y: 260 }, rooms: [{ id: "r1", name: "Room 1", x: 120, y: 120, w: 460, h: 360 }], chasms: [], walls: [], nodes: [], wires: [] };
    else if (PRESETS[id]) dungeon = clone(PRESETS[id]);
    document.getElementById("dnTitleIn").value = dungeon.title || "";
    document.getElementById("dnStyleSel").value = dungeon.floorStyle || "catacomb_stone";
    document.getElementById("dnDarkRange").value = Math.round((dungeon.darkness || 0) * 100);
    selected = null; saveLocal(); fitDungeon(); renderAllSidebars();
  };
  document.getElementById("dnTitleIn").onchange = e => { dungeon.title = e.target.value; saveLocal(); };
  document.getElementById("dnStyleSel").onchange = e => { dungeon.floorStyle = e.target.value; saveLocal(); };

  document.getElementById("dnPlayBtn").onclick = () => {
    playtestActive = !playtestActive;
    document.getElementById("dnPlayBtn").textContent = playtestActive ? "■ Stop (P)" : "▶ Playtest (P)";
    document.getElementById("dnResetPlayBtn").style.display = playtestActive ? "inline-block" : "none";
    if (playtestActive) resetPlaytest();
    else { document.getElementById("dnDlgBox").style.display = "none"; updateHudBar(); }
  };
  document.getElementById("dnResetPlayBtn").onclick = resetPlaytest;

  document.getElementById("dnSaveGameBtn").onclick = async () => {
    saveLocal();
    try {
      const resp = await fetch("/api/save_dungeon", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ dungeon }) });
      const js = await resp.json();
      setStatus(js.ok ? "Saved directly to data/custom_dungeon.json! Play via run_game.bat -> [F1] -> Studio: Custom Dungeon!" : "Save failed: " + js.error);
    } catch (_) { setStatus("Saved in browser. Run run_creator_studio.bat for direct write, or click JSON."); }
  };
  document.getElementById("dnDownloadBtn").onclick = () => { const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob([JSON.stringify(dungeon, null, 2)], { type: "application/json" })); a.download = "custom_dungeon.json"; a.click(); };
  document.getElementById("dnImportBtn").onclick = () => document.getElementById("dnImportFile").click();
  document.getElementById("dnImportFile").onchange = e => {
    const f = e.target.files[0]; if (!f) return;
    const reader = new FileReader();
    reader.onload = ev => { try { dungeon = JSON.parse(ev.target.result); saveLocal(); fitDungeon(); renderAllSidebars(); } catch (err) { alert("Invalid JSON: " + err.message); } };
    reader.readAsText(f); e.target.value = "";
  };

  window.onDungeonTabActivated = function () {
    const p = canvas.parentElement.getBoundingClientRect();
    if (p.width > 50 && p.height > 50) { canvas.width = Math.floor(p.width); canvas.height = Math.floor(p.height - 24); }
    fitDungeon();
  };
  window.openPresetInDungeonStudio = function (presetId) {
    if (window.switchCreatorTab) window.switchCreatorTab("dungeon");
    if (PRESETS[presetId]) { document.getElementById("dnPresetSel").value = presetId; document.getElementById("dnPresetSel").dispatchEvent(new Event("change")); }
  };

  document.getElementById("dnStyleSel").value = dungeon.floorStyle || "catacomb_stone";
  renderPalette(); renderAllSidebars(); fitDungeon();
};
