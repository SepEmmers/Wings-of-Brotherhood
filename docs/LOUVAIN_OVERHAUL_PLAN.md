# Louvain Historic Rebuild Plan — *Wings of the Brotherhood*

> **Core Shift:** Replace the barren `2400x1800` cobblestone grid in `LouvainCityRegion` with a dense, lively, historically grounded **15th-century circular walled city of Louvain (~2100x2100)** (`"De Kuip"` ring wall), emphasizing atmospheric medieval town life, companion stealth/puzzles (85%), standalone local stories, and only 1–2 tight Catchpole thresholds.

---

## 1. Historical Geography & Urban Plan (`~2100x2100`)

1. **Circular Outer Ring Wall (*Tweede Stadsomwalling*) & Radial Gates:**
   - Octagonal/circular fortified curtain wall enclosing the core city (`center ~(1050, 1050)`, `radius ~935px`), studded with rounded stone watch-towers (`sint-donatus`-style masonry bastions) and green earthen moat/rampart slopes outside:
     - **West Gate — *Brusselsepoort*:** Entry from Brabant Fens (`louvain_west_fens`).
     - **South Gate — *Naamsepoort*:** Heavily guarded portcullis exit south toward Old Heverlee Woods (`louvain_south_heverlee`).
     - **North Gate — *Mechelsepoort*** & **East Gate — *Tiensepoort***: Landmark radial gatehouses completing the medieval radial road cross (`Brusselsestraat`, `Mechelsestraat`, `Naamsestraat`, `Tiensestraat`).
2. **Branching River Dijle & *Vismarkt* Inner Harbor (Western Inner Arc):**
   - Natural Dijle channel curving behind *Brusselsepoort* past **Vismarkt Quay** (moored wooden river barges carrying fish & wine casks, brick embankment walls, quayside hoist, herring baskets, market tables), splitting around the **Dyers' & Herbalist Island** (dye-vats, hanging linen racks, medicinal herb plot, **Childhood Hunters' Tavern**) before exiting south.
3. **Central *Grote Markt* Civic & Scholarly Heart:**
   - **North Square — *Sint-Pieterskerk* & The Unfinished Triple Towers:** Monumental Brabant stone church featuring the famously truncated, flat-topped western facade covered in timber scaffolding, masonry hoists, and wooden shoring against marsh-peat subsidence, with the dark **Chapter Scriptorium Vault** behind its northeast cloister garden.
   - **South Square — *Het Stadhuis* (Town Hall):** Intricate sandstone Brabant Gothic Town Hall (inspired by Master Mason *Mathieu de Layens*, 1439+) with ornate corner pinnacles, statue niches, crimson canopy awnings, and civic announcement board.
   - **South-West Artery — *De Lakenhalle* (Grand Cloth Hall & 1425 University):** Massive vaulted stone hall marrying bustling ground-floor **Flemish cloth inspectors & wool bales** with upper-level **1425 University lecture galleries**, gown-clad scholars, and chained oak bookcases.
4. **Warm Brabant Palette (No Winter Ice Tiles):**
   - Replace the current icy blue `tile_frost_slate.png` checkerboard with warm buff sandstone flags around *Grote Markt* & *Lakenhalle*, amber-ochre street cobbles, rose-brick quays at *Vismarkt*, shady lime trees, flower planters, striped market awnings, laundry lines, warm corner lanterns, and ~15–20 animated citizens going about guild work.

---

## 2. Gameplay Identity (85% Stealth/Exploration + Side Stories + 1–2 Sharp Skirmishes)

- **Purely Local Side Stories (No Forced Plot Connection):**
  1. ***The Tower Race Against Brussels* (*Sint-Pieterskerk* Scaffold):** Master Mason **Matthijs** frets over peat subsidence beneath his truncated westwork while boasting against Brussels' spires. Help him brace scaffolding hoists (`[F]` knot rigging) and send your small dragonet (`[R]`) into a tight beam crack to drop a mason's plumb-line.
  2. ***Cloths & Lecturers* (*De Lakenhalle* / 1425 University):** Recover misplaced chained lecture folios across *Vismarkt* wine stalls and alleys while mediating noisy philosophers and frustrated wool weavers—witnessing authentic medieval town-and-gown humor.
  3. ***Vismarkt* Wine-Barge & Bell-Foundry:** Help **Deaf Bell-Founder Pieter** hoist alluvial Dijle clay into his glowing bronze foundry mold (`[F]` pulley), earning tuned **Bronze Resonance Chimes** while barge haulers gossip about guild rivalries.
- **Plot Beat & Climax (85% Stealth -> 1–2 Focused Thresholds):**
  - Visit **Aleidis** & **One-Eyed Martijn** inside the **Childhood Hunters' Tavern** to uncover your parents' burned guild seals.
  - Use **Cloak-Sling `[X]`**, hay carts, alley cloth racks, *Vismarkt* river barges, chimes `[1]`, and smoke `[2]` to sneak past **sparse, readable Catchpole patrols** into **Sint-Pieterskerk's Cloister Drain (`[R]`)** and light the dark Scriptorium sconces (`[R]`) to read the Old Heverlee Decree & Clara's Namur Warrant.
  - Conclude with **one crisp, fair Threshold Skirmish** at the Chapter Gate (where segment `[F]` Bowline snares, Shield-Yanks, and knife counters shine) followed by shattering *Naamsepoort* south toward Old Heverlee.

---

## 3. Strict Vertical Slice Build Order (Quality Over Speed)

1. **Slice 1 *(Completed)*:** Historic research + GL rendered visual screenshot harness (`VisualAuditRunner.gd` + `tools/capture_audit.ps1`) + specialist skills + fixed Brabant portcullis visibility (`brabant_sluice.png`).
2. **Slice 2 (Art & Architecture Kit Pass — Next):** Generate and visually inspect bespoke sprites for `Stadhuis`, `Sint-Pieterskerk` unfinished facade & scaffolding, `Lakenhalle`, circular ring gatehouses/towers, `Vismarkt` wine-barge, and medieval scholar/mason/merchant NPCs via `.agents/skills/pixel-art-generator`.
3. **Slice 3 (Circular Town & Living Streets):** Rebuild `LouvainCityMapData.gd` + `LouvainCityDraw.gd` cleanly under `< 500` lines each with full circular walls, warm sandstone floor, Dijle inner harbor, packed market stalls, trees, and animated citizens; inspect full multi-district PNG screenshots (`West Gate`, `Vismarkt`, `Grote Markt`, `Lakenhalle`, `St. Peter's Scaffold`, `South Naamsepoort`) via `read_file`.
4. **Slice 4 (Side Stories, Stealth Flow & Threshold Skirmish):** Wire quests, stealth cover paths, concise 2-line Zelda dialogue beats (`environmental-storytelling`), checkpoint sync, smoke checks, `ForestMapPanel.gd`/`bruges_map_builder.html` sync, and final multi-state PNG audit before playtest handoff.
