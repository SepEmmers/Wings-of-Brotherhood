# Pixel Art & Visual Polish Rules

## 1. Filtering & Scaling
- Project `default_texture_filter` MUST remain `0` (Nearest).
- Any dynamically loaded `Sprite2D` or `TextureRect` displaying pixel art MUST set `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`.
- Tile dimensions: `16x16` base world tiles rendered at integer scale (`2x` = `32x32` screen-space base unit) for crisp Zelda-like top-down proportions.

## 2. Cohesive 32-Color Medieval Flemish & Dragon Palette
- **Outlines & Shadows:** `#1b171d` (Warm Ink), `#2b242c` (Deep Slate), `#0e0c12` (Void Night)
- **Canal Water:** `#19384d` (Deep Zwin), `#24516b` (Mid Canal), `#3a738f` (Ripple Highlight), `#7cb3c4` (Foam Crest)
- **Cobblestone & Stone:** `#383436`, `#4f4a4b`, `#6b6463`, `#8c8480`
- **Flemish Brick & Roofs:** `#522723`, `#75382e`, `#994d3b`, `#6e472b`
- **Timber & Wharf Planks:** `#362114`, `#573620`, `#784d2e`, `#9c6940`
- **Foliage & Ropewalk Hemp:** `#293d23`, `#3f592e`, `#5c7a3b`, `#b89454`, `#d9b875`
- **Skin & Cloth:** `#d9ab89`, `#b88263`, `#38576b` (Boy Tunic), `#8c3b42` (Clara Dress), `#871d24` (Inquisitor Crimson)
- **Lantern Glow & Gold:** `#e89c31`, `#ffd66b`, `#f5e8b8`
- **Black-Scaled Dragon:** `#12141c` (Obsidian Outline), `#1d2230` (Primary Scale), `#2e374d` (Rim Highlight), `#c79c42` (Amber Eye)

## 3. Top-Down Perspective Rules (3/4 Zelda View)
- Buildings show both **front facade** (doors, shuttered windows, stepped Flemish gables) and **pitched roof**, allowing characters to walk right up to doors cleanly.
- Every character and movable prop casts a semi-transparent dark-blue/ink shadow (`Color(0.05, 0.05, 0.08, 0.35)`) beneath its feet.
- Flying dragons render at higher `z_index` with a scaled shadow projected downward based on altitude layer.

## 4. Placeholder-First Rule (`docs/SPRITE_TRACKER.md`)
- Whenever a gameplay or narrative feature introduces a **new visual asset**, first check if a **Modular Kit** already handles it (`kit_buildings.py` for city houses/shops, `kit_npcs.py` for townsfolk/crew, `kit_boy_carry.py` + `PlayerBoy.CARRY_PROPS` for carryables using a single `16x16` prop texture).
- Otherwise generate a **simple-box placeholder** (crisp `1px` outlined rectangles at exact target dimensions) inside `.agents/skills/pixel-art-generator/scripts/sprite_placeholders.py` and add `- [ ]` to `docs/SPRITE_TRACKER.md` instead of authoring bespoke pixel art inline.
- When the **Sprite-Making Agent** replaces a placeholder with finished 32-palette pixel art (or modular kit recipes) and flips its row to `- [x]` in `docs/SPRITE_TRACKER.md`, `sprite_placeholders.py` preserves that finished file cleanly on future generator runs.

## 5. Modular Sprite Composition Standard (Cities, Crowds & Carryables)
- **City Buildings (`kit_buildings.py`):** Build districts from reusable `16px` bay blocks (`3..10` bays wide), swappable wall/roof presets, gables, doors, windows, and awnings via compact recipes rather than per-house hand coding.
- **NPCs (`kit_npcs.py`):** Compose crowds and named townsfolk from modular body/outfit, skin, face/beard, hair, hat, and prop layers with automatic `_0`/`_1` idle frames grounded on row 24.
- **Protagonist Carrying (`kit_boy_carry.py` + `PlayerBoy.gd`):** Reuse empty-hands `"overhead"` (`boy_carry_hands_*`) and `"cradle"` (`boy_cradle_hands_*`) animations combined with runtime `carry_prop_sprite` overlays (`CARRY_PROPS` / `set_carry_prop(...)`) instead of full-body per-item sprites.
