# Wings of the Brotherhood — World Topology & Gate Reference

> **Purpose:** Authoritative spatial map and **1:1 bidirectional gate registry** for all interconnected regions, interiors, and aerial routes. Consult and update this file whenever adding a region, shifting a gate coordinate, or extending the overworld.

---

## 1. Macro Geography (ASCII World Layout)

All connected Flemish coast regions sit in strict compass alignment: walking out through Gate $X$ from Region $A$ into Region $B$ places you just outside Gate $X$'s return trigger in Region $B$, and walking straight back returns to Region $A$ (never to a third region).

```text
               ZWIN ESTUARY / NORTH SEA (West)
                         ~  ~  ~
    +-------------------------------+       +-------------------------------+       +------------------------+
    |    WALLED CITY OF BRUGES      |       |       BRUGES OUTSKIRTS        |       |  BROTHERHOOD SANCTUARY |
    |         "bruges_city"         |       |          "outskirts"          |       |       "sanctuary"      |
    |         2880 x 2160           |       |          2400 x 1140          |       |       1800 x 1140      |
    |                               |       |                               |       |                        |
    |               [East Gate] ===>+=====> | [West Gate]  == [Zwin Bridge] | ====> | [West Cliff Trail]     |
    |                 (x=2768,1258) |       |  (x=0,504)     (Tollhouse)    |       |  (x=0,416..624)        |
    |                               |       |       |                       |       |                        |
    |       [South Port Gate]       |       |   (Towpath)                   |       |      (Virelai Wing     |
    |         (x=1386,1996)         |       |       v                       |       |       Sorties)         |
    +---------------+---------------+       | [SW Port Towpath]             |       +-----------+------------+
                    ^                       |   (x=320,1056)                |                   |
                    |                       +---------------+---------------+                   | (airborne
                    v                                       ^                                   |  sortie:
    +---------------+---------------------------------------+---------------+                   |  "flight")
    | [NW City Gate] (x=676,0)              [NE Towpath Gate] (x=1484,0)    |                   v
    |                          PORT OF BRUGES ("bruges")                    |       +------------------------+
    |                               1600 x 1040                             |       |   WHISPERING PINES     |
    |                                                                       |       |        "wilds"         |
    |   ~ De Zwaan ~   Quay & Warehouse    Ropewalk      [Cottage Door]     |       |      2880 x 2160       |
    |                                                     (x=1280,846)      |       |                        |
    |                                                          |            |       |  [Watchtower Outpost]  |
    +----------------------------------------------------------+------------+       |    (x=2620,255)        |
                                                               v                    +-----------+------------+
                                                +--------------+------------+                   |
                                                | WILLEM'S COTTAGE ("house")|                   v
                                                |   Interior (400..880 x    |       +-----------+------------+
                                                |    180..545 / 1280x720)   |       |  WATCHTOWER HEARTH     |
                                                +---------------------------+       | ("hearth", 1280x720)   |
                                                                                    +------------------------+
```

### 1.2 Kingdom Campaign Charter Overview (Flanders → Brabant → Meuse)

Charted in View Mode `2` (**Kingdom Charter**) of the `[M]` chart via `WorldRealmChartData.gd` + `WorldRealmChartDraw.gd`, connecting Book I Flanders seamlessly into Book II+ inland Belgium:

```text
  [COUNTY OF FLANDERS]            [DUCHY OF BRABANT]               [HESBAYE & NAMUR]             [MEUSE BORDERLANDS]
  Port & City of Bruges           Brabant Reed-Fens               Hesbaye Uplands               Ardennes Mist-Gorges
    ↔ Bruges Outskirts      ──►     ("brabant_fens")       ──►      ("hesbaye_uplands")   ──►     ("ardennes_ridge")
    ↔ Sanctuary Cliffs                │                               │                           │
    ↔ Whispering Pines                ▼                               ▼                           ▼
                                  Louvain (Dijle)                 Namur Cliff-Citadel           Meuse Blood-Citadel
                                    ("louvain")                     ("namur_citadel")             ("blood_citadel")
                                      │
                                      ▼
                                  Old Heverlee Woods & Shrine
                                    ("old_heverlee")
```

- **Overland & Aerial Links:** Solid ink roads follow Flanders coast -> Brabant Fens -> Louvain -> Old Heverlee -> Hesbaye -> Namur -> Ardennes -> Blood-Citadel; teal dashed corridors mark Virelai wing sorties; silver dotted curves track Kestrel courier dispatches between Captain Anna and the Boy.
- **Discovery State:** Visiting any region (`ForestMapPanel.set_player_location`) automatically unlocks its `REALM_NODES` pin via `GameState.unlock_realm_node(node_id)`, while later Book II frontier provinces remain faint uncharted mist seals until reached or unlocked in the campaign.

---

## 2. 1:1 Bidirectional Walk-Portal & Doorway Registry

Every seamless border walk-portal uses `RegionBase.register_walk_portal(id, rect, move_dir_hint, callback, sign_label, banner_title, banner_sub)` with `portal_cooldown` protection, proximity archway directional silhouettes, a `0.18s` camera fade-in + `BorderBannerPanel` oak signboard upon crossing, and spawns the arriving player outside the opposite trigger box. During Chapter 1 (`current_step < ACT2_SANCTUARY`), Port exit gates check `is_portal_unlocked(id)` so customs guards stop early skips cleanly before Act 4 free roam opens.

### 2.1 Bruges Coast Overworld & Interiors

| Connection | From Region | Portal ID | Trigger `Rect2` | `move_dir_hint` | Lands in Region | Spawn `Vector2` | Facing | Paired Return ID | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Port NW ↔ City South** | `bruges` | `north_city_gate` | `Rect2(676, 0, 88, 38)` | `Vector2.UP` | `bruges_city` | `(1440, 1960)` | `Vector2.UP` | `city_south_exit` | Between Warehouse & Ropewalk (`x=720`); Chapter 1 customs-locked by Gatewarden Maerten until `ACT2_SANCTUARY` |
| **City South ↔ Port NW** | `bruges_city` | `city_south_exit` | `Rect2(1386, 1996, 108, 72)` | `Vector2.DOWN` | `bruges` | `(720, 68)` | `Vector2.DOWN` | `north_city_gate` | Steenstraat / South Bastion Gate |
| **Port NE ↔ Outskirts SW** | `bruges` | `ne_outskirts_gate` | `Rect2(1484, 0, 88, 38)` | `Vector2.UP` | `outskirts` | `(380, 1018)` | `Vector2.UP` | `outskirts_south_port` | East of Ropewalk (`x=1484..1572`); Chapter 1 toll-locked by Customsman Dirk until `ACT2_SANCTUARY` |
| **Outskirts SW ↔ Port NE** | `outskirts` | `outskirts_south_port` | `Rect2(320, 1056, 120, 84)` | `Vector2.DOWN` | `bruges` | `(1528, 68)` | `Vector2.DOWN` | `ne_outskirts_gate` | Dirt towpath south from Crossroads |
| **City East ↔ Outskirts West** | `bruges_city` | `city_east_exit` | `Rect2(2768, 1258, 96, 92)` | `Vector2.RIGHT` | `outskirts` | `(96, 560)` | `Vector2.RIGHT` | `outskirts_west_city` | Crosses East Moat to Causeway |
| **Outskirts West ↔ City East** | `outskirts` | `outskirts_west_city` | `Rect2(0, 504, 84, 112)` | `Vector2.LEFT` | `bruges_city` | `(2716, 1304)` | `Vector2.LEFT` | `city_east_exit` | Cobble approach west of Tollhouse |
| **Outskirts East ↔ Sanctuary** | `outskirts` | `outskirts_east_sanctuary` | `Rect2(2308, 444, 92, 148)` | `Vector2.RIGHT` | `sanctuary` | `(132, 515)` | `Vector2.RIGHT` | `act4_west_gate` | Dune trail past Zwin Bridge |
| **Sanctuary ↔ Outskirts East** | `sanctuary` | `act4_west_gate` | `Rect2(0, 416, 108, 208)` | `Vector2.LEFT` | `outskirts` | `(2272, 520)` | `Vector2.LEFT` | `outskirts_east_sanctuary` | Active in `sanctuary_phase == 4` prior to `city_bounty_overheard` |
| **Port Cottage ↔ Inside** | `bruges` | `house_door` | `Rect2(1280, 846, 60, 40)` | `Vector2.UP` | `house` | `(640, 455)` | `Vector2.UP` | `house_exit` | Uncle Willem & Clara's cottage |
| **Cottage Inside ↔ Port** | `house` | `house_exit` | `Rect2(610, 474, 60, 36)` | `Vector2.DOWN` | `bruges` | `(1310, 902)` | `Vector2.DOWN` | `house_door` | Threshold onto cottage cobblestone step |

### 2.2 Frontier Borderlands

| Connection | From Region | Portal ID | Trigger `Rect2` | `move_dir_hint` | Lands in Region | Spawn `Vector2` | Facing | Paired Return ID | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Wilds Outpost ↔ Hearth** | `wilds` | `wilds_outpost` | `Rect2(2578, 231, 84, 52)` (`OUTPOST_POS=(2620,255)`) | `Vector2.UP` | `hearth` | Inside Watchtower | `Vector2.UP` | `hearth_door` | Triggers interior egg-warming cutscene |
| **Hearth ↔ Wilds Outpost** | `hearth` | `hearth_door` | `Rect2(610, 470, 60, 38)` | `Vector2.DOWN` | `wilds` | `(1380, 225)` | `Vector2.DOWN` | `wilds_outpost` | Active during `ACT3_EGG_TREK`; talking to Anna after warming rides Virelai to `sanctuary` `(342, 504)` |

### 2.3 Scripted Narrative & Aerial Transitions

- **`PortOfBrugesAmbush` -> `house` -> `sanctuary`:** Church betrayal / ambush capture cuts to `house` `(640, 445)` during `SNITCH_TO_CHURCH`, then rescue flies/transitions to `sanctuary` (`arrival_cutscene: true`).
- **`sanctuary` -> `flight` -> `wilds` -> `hearth` -> `sanctuary`:** Brotherhood sorties (`sortie: 1` returns to `sanctuary` `(465, 440)`; `sortie: 2` crash-lands in `wilds`; Watchtower Hearth flies back to `sanctuary` `(342, 504)` with `act4_debate_intro: true`).
- **`SanctuaryAct4` Finale -> `brabant_fens`:** Completing Kestrel's midnight Sanctuary escape advances via `"Continue to Book II: Brabant Fens"` into `brabant_fens` (`book2_intro: true`).

### 2.4 Brabant Province & Dijle Basin (Book II Act I)

| Connection | From Region | Portal ID | Trigger `Rect2` | `move_dir_hint` | Lands in Region | Spawn `Vector2` | Facing | Paired Return ID | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Brabant East ↔ Louvain West** | `brabant_fens` | `brabant_to_louvain` | `Rect2(2092, 650, 68, 128)` | `Vector2.RIGHT` | `louvain` | `(226, 1040)` | `Vector2.RIGHT` | `louvain_west_fens` | Locked behind Mill Sluice Gate until Hatchling Vent Crawl (`brabant_vent_unlocked`) |
| **Louvain West ↔ Brabant East** | `louvain` | `louvain_west_fens` | `Rect2(60, 976, 52, 128)` | `Vector2.LEFT` | `brabant_fens` | `(2040, 710)` | `Vector2.LEFT` | `brabant_to_louvain` | Exits through Brusselsepoort west onto the Dijle dike bridge |
| **Louvain South → Old Heverlee** | `louvain` | `louvain_south_heverlee` | `Rect2(986, 1986, 128, 70)` | `Vector2.DOWN` | *(Milestone 3 checkpoint)* | `—` | `—` | `—` | Exits Naamsepoort south; unlocks upon winning Abbey Breakout & Golden Resonance burst (`louvain_breakout_won`) |

---

## 3. Map Expansion Checklist (Always Follow When Adding/Moving Gates)

1. **Strict 1:1 Symmetry:** Never point two different entrances (`bruges_city` South Gate and `outskirts` South Port Towpath) into a single shared destination gate unless both exits lead to that one hub intentionally. Each road must pair **Portal A → Spawn B** cleanly outside **Portal B**, whose return leads strictly back to **Spawn A**.
2. **Spawn Margin & Cooldown:** Place landing `spawn` at least **25–40 px clear** of the return `walk_portal` rectangle (`RegionBase.portal_cooldown` provides `0.85s` safety after transition, and `enter_region` should snap `director.camera.position = player.position` + set `player.cutscene_hidden = false`).
3. **Visual Opening Alignment:** Carve matching openings in both `StaticBody2D` colliders AND `_draw_static_ground` / road rects / foreground overhang canopies so no tree or fence straddles a portal throat.
4. **Triple Sync:** Whenever layout, gates, or roads change, update:
   - The region's GDScript geometry & portals + this document (`docs/WORLD_TOPOLOGY.md`).
   - `scripts/ui/ForestMapPanel.gd` (`[M]` Connected World Map links, badges, and `_player_pin_world_map()` bounds).
   - `bruges_map_builder.html` (all **7** presets: `bruges_city`, `port_of_bruges`, `outskirts`, `sanctuary`, `frontier_wilds`, `willem_house`, `watchtower_hearth`).
   - `scripts/data/PlaytestPresets.gd` if a new beat/region jump entry is needed in `[F1]`.
