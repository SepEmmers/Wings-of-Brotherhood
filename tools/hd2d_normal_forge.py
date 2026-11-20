"""
Deterministic HD-2D Surface Texture & Sprite Normal-Map Baker
==============================================================
Generates tileable 64x64 pixel-art PBR surface textures (+ wrap-seamless Sobel
normal maps) in `assets/hd2d/textures/` and height-field tangent normal maps in
`assets/hd2d/normals/` for existing Brabant Reed-Fens sprites in `assets/sprites/`.
Zero AI image generation: pure deterministic math + pixel height fields.
"""

from __future__ import annotations

from pathlib import Path
import numpy as np
from PIL import Image

ROOT_DIR = Path(__file__).resolve().parent.parent
SPRITES_DIR = ROOT_DIR / "assets" / "sprites"
TEX_OUT_DIR = ROOT_DIR / "assets" / "hd2d" / "textures"
NORM_OUT_DIR = ROOT_DIR / "assets" / "hd2d" / "normals"

BAYER_2X2 = np.array([[0.0, 0.5], [0.75, 0.25]], dtype=np.float32)

SPRITE_PREFIXES = (
    "boy17_",
    "boy_",
    "boy_carry_hands_",
    "boy_cradle_hands_",
    "boy_roll_",
    "boy_knife_",
    "dragon_gold_s1_",
    "dragon_greyling_",
    "dragon_anna",
    "npc_anna",
    "npc_baker",
    "npc_brotherhood_guard",
    "npc_city_guard",
    "npc_clara",
    "npc_dockhand",
    "npc_inquisitor",
    "npc_piet",
    "npc_quartermaster",
    "npc_shipmaster",
    "npc_watchman",
    "prop_hatchling_sling_",
    "prop_dragon_egg",
)

SPRITE_EXACT = {
    "boy_kneel.png",
    "building_baker.png",
    "building_house.png",
    "building_outpost.png",
    "building_ropewalk.png",
    "building_warehouse.png",
    "merchant_cog.png",
    "prop_pine_dark.png",
    "prop_pine_tree.png",
    "prop_fern_cluster.png",
    "prop_campfire_0.png",
    "prop_campfire_1.png",
    "prop_wall_brazier.png",
    "prop_bramble_thicket_1.png",
    "prop_bramble_thicket.png",
    "prop_crate.png",
    "prop_cairn_stone.png",
    "prop_noticeboard.png",
    "prop_milestone.png",
    "prop_bollard.png",
    "prop_lantern.png",
    "prop_river_stone_0.png",
    "prop_medieval_lever_idle.png",
    "prop_medieval_lever_pulled.png",
    "prop_culvert_tunnel_h.png",
    "prop_dragon_vent_grate.png",
    "prop_mutton_joint.png",
    "prop_meat_cut.png",
    "prop_rope_coil.png",
    "prop_hatchling_sling.png",
    "prop_barrel.png",
    "prop_bollard.png",
    "prop_bread_loaf.png",
    "prop_brick_bread_oven.png",
    "prop_church_pulpit.png",
    "prop_crate.png",
    "prop_flour_sack_stack.png",
    "prop_herring_bucket.png",
    "prop_herring_fish.png",
    "prop_lantern.png",
    "prop_lime_tree.png",
    "prop_milestone.png",
    "prop_noticeboard.png",
    "prop_pier_wake_0.png",
    "prop_pier_wake_1.png",
    "prop_port_gatehouse.png",
    "prop_rigging_post.png",
    "prop_rope_coil.png",
    "prop_rope_windlass.png",
    "prop_shuttle_pouch.png",
    "prop_stall_food.png",
    "prop_stall_gear.png",
    "prop_twine_cache.png",
    "prop_water_trough.png",
    "prop_slash_arc.png",
}


def _hash_noise(w: int, h: int, seed: int) -> np.ndarray:
    return np.random.default_rng(seed).random((h, w), dtype=np.float32)


def _bake_tileable_surface(
    rgb: np.ndarray,
    height: np.ndarray,
    out_path: Path,
    quantize_steps: int = 6,
    normal_strength: float = 1.15,
) -> None:
    """Applies subtle Bayer pixel dithering, AO, and wrap-seamless Sobel normal map."""
    h, w, _ = rgb.shape
    pad_z = np.pad(height, 1, mode="wrap")
    gx = (pad_z[1:-1, 2:] - pad_z[1:-1, :-2]) * normal_strength
    gy = (pad_z[2:, 1:-1] - pad_z[:-2, 1:-1]) * normal_strength
    gz = np.ones_like(gx) * 1.35
    inv_len = 1.0 / np.sqrt(gx * gx + gy * gy + gz * gz + 1e-8)
    nx = -gx * inv_len
    ny = -gy * inv_len
    nz = gz * inv_len

    dot = np.clip(nx * (-0.42) + ny * (-0.64) + nz * 0.64, -0.35, 1.0)
    bayer = np.tile(BAYER_2X2, (h // 2 + 1, w // 2 + 1))[:h, :w]
    lit = np.clip((dot + 0.35) / 1.35, 0.0, 1.0)
    q = np.floor(lit * quantize_steps + (bayer - 0.5) * 0.32) / float(quantize_steps)
    height_ao = np.clip(0.84 + 0.18 * (height / (float(np.max(height)) + 1e-4)), 0.72, 1.05)
    shade = (0.72 + 0.34 * q) * height_ao

    out_rgb = np.clip(rgb * shade[:, :, None], 0.0, 255.0).astype(np.uint8)
    Image.fromarray(out_rgb, "RGB").save(out_path)

    n_rgb = np.zeros((h, w, 3), dtype=np.uint8)
    n_rgb[:, :, 0] = np.clip((nx * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    n_rgb[:, :, 1] = np.clip((-ny * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    n_rgb[:, :, 2] = np.clip(nz * 255.0, 128, 255).astype(np.uint8)
    Image.fromarray(n_rgb, "RGB").save(out_path.with_name(f"{out_path.stem}_n.png"))


def _sculpt_fen_moss(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    n1 = _hash_noise(s, s, 2101)
    n2 = _hash_noise(s, s, 2102)
    wave = 0.5 + 0.5 * np.sin(xx * 0.29 + yy * 0.19) * np.cos(yy * 0.24 - xx * 0.15)
    tuft = np.clip(n1 * 0.62 + wave * 0.38, 0.0, 1.0)

    moss = np.array([56.0, 86.0, 48.0], dtype=np.float32)
    deep_fen = np.array([40.0, 62.0, 38.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = moss[c] * tuft + deep_fen[c] * (1.0 - tuft)

    reed_tip = (n2 > 0.91) & ((xx + yy) % 2 == 0)
    clover = (n2 > 0.85) & (n2 <= 0.88)
    rgb[reed_tip] = np.array([86.0, 112.0, 58.0], dtype=np.float32)
    rgb[clover] = np.array([72.0, 94.0, 64.0], dtype=np.float32)

    height = 1.1 + tuft * 1.4 + np.where(reed_tip, 1.0, 0.0) + n2 * 0.4
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=6, normal_strength=0.65)


def _sculpt_fen_peat(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    n1 = _hash_noise(s, s, 2201)
    n2 = _hash_noise(s, s, 2202)
    swell = 0.5 + 0.5 * np.sin(xx * 0.24 + yy * 0.18)
    peat = np.array([62.0, 54.0, 44.0], dtype=np.float32)
    damp = np.array([44.0, 48.0, 38.0], dtype=np.float32)
    mix = np.clip(n1 * 0.6 + swell * 0.4, 0.0, 1.0)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = peat[c] * mix + damp[c] * (1.0 - mix)
    sedge = n2 > 0.90
    rgb[sedge] = np.array([72.0, 92.0, 56.0], dtype=np.float32)
    height = 1.0 + mix * 1.5 + np.where(sedge, 1.1, 0.0)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=5, normal_strength=1.15)


def _sculpt_fen_dirt(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    n1 = _hash_noise(s, s, 2301)
    n2 = _hash_noise(s, s, 2302)
    rut = 0.5 + 0.5 * np.sin(xx * 0.196)
    base = np.array([96.0, 72.0, 50.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = base[c] + (n1 - 0.5) * 18.0 - rut * 10.0
    pebble = n2 > 0.92
    rgb[pebble] = np.array([118.0, 112.0, 102.0], dtype=np.float32)
    height = 1.4 + n1 * 1.2 - rut * 0.5 + np.where(pebble, 0.9, 0.0)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=6, normal_strength=0.72)


def _sculpt_flemish_cobble(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    row_h = 16
    col_w = 24
    row = yy // row_h
    ry = yy % row_h
    shift = (row % 2) * 12
    bx = (xx + shift) % col_w
    b_id = (row * 7 + ((xx + shift) // col_w) * 13) % 11
    mortar = (ry == 0) | (ry == 15) | (bx == 0) | (bx == col_w - 1)
    edge_dist = np.minimum(np.minimum(ry, row_h - 1 - ry), np.minimum(bx, col_w - 1 - bx)).astype(np.float32)

    n = _hash_noise(s, s, 2401)
    base = np.array([84.0, 86.0, 94.0], dtype=np.float32)
    tint = (b_id.astype(np.float32) - 5.0) * 3.2 + (n - 0.5) * 8.0
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = base[c] + tint
    moss_mortar = mortar & (n > 0.58)
    mortar_col = (44.0, 46.0, 50.0)
    moss_col = (54.0, 74.0, 48.0)
    for c in range(3):
        rgb[:, :, c] = np.where(mortar, mortar_col[c], rgb[:, :, c])
        rgb[:, :, c] = np.where(moss_mortar, moss_col[c], rgb[:, :, c])
    height = np.where(mortar, 0.4, 1.5 + np.minimum(edge_dist, 3.0) * 0.35 + n * 0.30)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=6, normal_strength=0.78)


def _sculpt_oak_planks(out_path: Path, dark: bool = False) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    plank_h = 16
    plank_idx = yy // plank_h
    in_plank_y = yy % plank_h
    joint_x = ((xx + plank_idx * 32) % 64) == 0
    seam_y = in_plank_y == 0
    is_seam = seam_y | joint_x

    rng = np.random.default_rng(2509 if dark else 2505)
    plank_tint = rng.uniform(-9.0, 9.0, size=4)
    grain_noise = rng.uniform(-7.0, 7.0, size=(s, s // 4))
    grain = np.repeat(grain_noise, 4, axis=1) + rng.uniform(-3.0, 3.0, size=(s, s))

    base = np.array([82.0, 56.0, 38.0] if dark else [136.0, 94.0, 58.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = base[c] + plank_tint[plank_idx] + grain * 0.85

    height = 2.6 + np.sin(in_plank_y / float(plank_h) * np.pi) * 0.9 + grain * 0.05
    seam_col = (30.0, 20.0, 16.0) if dark else (48.0, 32.0, 20.0)
    peg_col = (48.0, 44.0, 46.0) if dark else (72.0, 48.0, 30.0)
    for py in range(4):
        yc = py * plank_h
        offset_x = (py * 32) % 64
        for dx, dy in ((3, 4), (3, 11), (61, 4), (61, 11)):
            px = (offset_x + dx) % 64
            py_c = (yc + dy) % 64
            rgb[py_c, px] = peg_col
            height[py_c, px] = 3.8 if dark else 3.0
    for c in range(3):
        rgb[:, :, c] = np.where(is_seam, seam_col[c], rgb[:, :, c])
    height = np.where(is_seam, 0.3, height)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=6, normal_strength=1.25)


def _sculpt_weir_stone(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    row_h = 16
    col_w = 32
    row = yy // row_h
    ry = yy % row_h
    shift = (row % 2) * (col_w // 2)
    bx = (xx + shift) % col_w
    b_id = (row * 5 + ((xx + shift) // col_w) * 11) % 9
    mortar = (ry == 0) | (ry == 15) | (bx == 0) | (bx == col_w - 1)
    edge_dist = np.minimum(np.minimum(ry, row_h - 1 - ry), np.minimum(bx, col_w - 1 - bx)).astype(np.float32)

    n = _hash_noise(s, s, 2601)
    base = np.array([128.0, 124.0, 116.0], dtype=np.float32)
    tint = (b_id.astype(np.float32) - 4.0) * 3.2 + (n - 0.5) * 11.0
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = base[c] + tint
    moss = mortar & (n > 0.68)
    for c in range(3):
        rgb[:, :, c] = np.where(mortar, (62.0, 60.0, 58.0)[c], rgb[:, :, c])
        rgb[:, :, c] = np.where(moss, (70.0, 92.0, 60.0)[c], rgb[:, :, c])
    height = np.where(mortar, 0.2, 1.5 + np.minimum(edge_dist, 4.0) * 0.55 + n * 0.4)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=6, normal_strength=1.35)


def _sculpt_plaster_timber(out_path: Path) -> None:
    """Half-timbered medieval Flemish cream plaster framed by dark oak cross-beams."""
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    n = _hash_noise(s, s, 2701)
    beam = (yy < 6) | (yy >= 58) | (xx < 6) | (xx >= 58) | ((xx >= 29) & (xx <= 34))
    plaster = np.array([168.0, 154.0, 128.0], dtype=np.float32)
    timber = np.array([68.0, 46.0, 32.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        p_col = plaster[c] + (n - 0.5) * 12.0
        t_col = timber[c] + (n - 0.5) * 8.0
        rgb[:, :, c] = np.where(beam, t_col, p_col)
    height = np.where(beam, 3.2 + n * 0.4, 1.4 + n * 0.35)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=5, normal_strength=1.25)


def _sculpt_clay_roof(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    row_h = 16
    col_w = 16
    row = yy // row_h
    ry = yy % row_h
    shift = (row % 2) * 8
    bx = (xx + shift) % col_w
    seam = (ry == 15) | (bx == 0)
    n = _hash_noise(s, s, 2801)
    tid = (row * 5 + ((xx + shift) // col_w) * 9) % 7
    base = np.array([154.0, 68.0, 52.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = np.where(seam, 54.0, base[c] + (tid - 3.0) * 5.0 + (n - 0.5) * 10.0)
    moss = (ry >= 12) & (n > 0.84)
    rgb[moss] = np.array([82.0, 102.0, 62.0], dtype=np.float32)
    height = np.where(seam, 0.3, 1.0 + ry * 0.16 + n * 0.35)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=5, normal_strength=1.3)


def _sculpt_slate_roof(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    row_h = 16
    col_w = 16
    row = yy // row_h
    ry = yy % row_h
    shift = (row % 2) * 8
    bx = (xx + shift) % col_w
    seam = (ry == 15) | (bx == 0)
    n = _hash_noise(s, s, 2901)
    tid = (row * 5 + ((xx + shift) // col_w) * 9) % 7
    base = np.array([68.0, 76.0, 92.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = np.where(seam, 36.0, base[c] + (tid - 3.0) * 4.0 + (n - 0.5) * 8.0)
    height = np.where(seam, 0.3, 1.0 + ry * 0.15 + n * 0.3)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=5, normal_strength=1.3)


def _sculpt_flemish_brick(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    row_h = 8
    col_w = 16
    row = yy // row_h
    ry = yy % row_h
    shift = (row % 2) * 8
    bx = (xx + shift) % col_w
    mortar = (ry == 0) | (bx == 0)
    n = _hash_noise(s, s, 3101)
    bid = (row * 7 + ((xx + shift) // col_w) * 11) % 7
    ochre_warm = (row + ((xx + shift) // col_w)) % 4 == 0
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    base_brick = np.array([138.0, 74.0, 56.0], dtype=np.float32)
    alt_ochre = np.array([154.0, 102.0, 66.0], dtype=np.float32)
    mortar_col = np.array([152.0, 142.0, 122.0], dtype=np.float32)
    for c in range(3):
        b_col = np.where(ochre_warm, alt_ochre[c], base_brick[c]) + (bid - 3.0) * 6.0 + (n - 0.5) * 12.0
        m_col = mortar_col[c] + (n - 0.5) * 10.0
        rgb[:, :, c] = np.where(mortar, m_col, b_col)
    bevel = ((ry == 1) | (ry == 7) | (bx == 1) | (bx == 15)) & (~mortar)
    height = np.where(mortar, 0.35 + n * 0.15, np.where(bevel, 1.4 + n * 0.25, 2.25 + n * 0.35))
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=6, normal_strength=1.35)


def _sculpt_harbor_cobble(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    row_h = 8
    col_w = 10
    row = yy // row_h
    ry = yy % row_h
    shift = (row % 2) * 5
    bx = (xx + shift) % col_w
    seam = (ry == 0) | (bx == 0)
    n = _hash_noise(s, s, 3201)
    sid = (row * 5 + ((xx + shift) // col_w) * 9) % 6
    base = np.array([92.0, 98.0, 108.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    for c in range(3):
        stone = base[c] + (sid - 2.5) * 7.5 + (n - 0.5) * 14.0
        rgb[:, :, c] = np.where(seam, 38.0 + n * 8.0, stone)
    # Subtle Zwin sea-damp & dockside moss tint in crevices
    damp_crevice = (ry <= 1) & (n > 0.78)
    rgb[damp_crevice] = np.array([58.0, 74.0, 62.0], dtype=np.float32)
    bevel = ((ry == 1) | (ry == 7) | (bx == 1) | (bx == 9)) & (~seam)
    height = np.where(seam, 0.25, np.where(bevel, 1.35 + n * 0.25, 2.15 + n * 0.40))
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=6, normal_strength=1.40)


def _sculpt_sail_canvas(out_path: Path) -> None:
    s = 64
    yy, xx = np.mgrid[0:s, 0:s]
    n = _hash_noise(s, s, 3301)
    # Vertical cloth panels + horizontal reefing seams
    panel_seam = (xx % 16 == 0)
    reef_seam = (yy % 21 == 10)
    weave = (((xx + yy) % 2) * 2.0 - 1.0) * 4.5
    base = np.array([214.0, 198.0, 168.0], dtype=np.float32)
    rgb = np.zeros((s, s, 3), dtype=np.float32)
    salt_stain = (n < 0.28)
    for c in range(3):
        cloth = base[c] + weave + (n - 0.5) * 16.0 - np.where(salt_stain, 12.0, 0.0)
        cloth = np.where(panel_seam, cloth - 26.0, cloth)
        cloth = np.where(reef_seam, cloth - 20.0, cloth)
        rgb[:, :, c] = cloth
    height = 1.6 + weave * 0.04 + n * 0.30
    height = np.where(panel_seam, 2.25, height)
    height = np.where(reef_seam, 2.05, height)
    _bake_tileable_surface(rgb, height, out_path, quantize_steps=5, normal_strength=1.05)


def _sculpt_horizon_treeline(out_path: Path) -> None:
    """256x80 pixel-art distant Brabant treeline & far Louvain belfry spire silhouette."""
    w, h = 256, 80
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    height_map = np.zeros((h, w), dtype=np.float32)
    rng = np.random.default_rng(3001)

    for x in range(w):
        ridge_h = int(22 + 12 * np.sin(x * 0.055) + 7 * np.cos(x * 0.14) + rng.integers(-2, 3))
        if x % 14 < 10:
            pine_bump = int(10 * (1.0 - abs((x % 14) - 5) / 5.0))
            ridge_h += pine_bump
        # Distant Louvain spire silhouette near x=196..218
        if 194 <= x <= 218:
            dx = abs(x - 206)
            if dx <= 2:
                ridge_h = max(ridge_h, 66 - dx * 4)
            elif dx <= 7:
                ridge_h = max(ridge_h, 46)
            else:
                ridge_h = max(ridge_h, 36)

        ridge_h = min(h - 2, max(6, ridge_h))
        for y in range(h - ridge_h, h):
            elev = (y - (h - ridge_h)) / max(1.0, float(ridge_h))
            is_spire = 194 <= x <= 218 and (h - y) > 34
            if is_spire:
                col = (52, 56, 74) if elev < 0.4 else (38, 42, 58)
            else:
                col = (44, 62, 54) if elev < 0.35 else ((34, 48, 44) if elev < 0.72 else (26, 36, 36))
            rgba[y, x, :3] = col
            rgba[y, x, 3] = 255
            height_map[y, x] = 2.0 + (1.0 - elev) * 2.5

    Image.fromarray(rgba, "RGBA").save(out_path)

    pad_z = np.pad(height_map, 1, mode="edge")
    gx = (pad_z[1:-1, 2:] - pad_z[1:-1, :-2]) * 0.9
    gy = (pad_z[2:, 1:-1] - pad_z[:-2, 1:-1]) * 0.9
    gz = np.ones_like(gx) * 1.6
    inv = 1.0 / np.sqrt(gx * gx + gy * gy + gz * gz + 1e-8)
    nx, ny, nz = -gx * inv, -gy * inv, gz * inv
    n_rgba = np.zeros((h, w, 4), dtype=np.uint8)
    mask = rgba[:, :, 3] > 0
    n_rgba[mask, 0] = np.clip((nx[mask] * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    n_rgba[mask, 1] = np.clip((-ny[mask] * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    n_rgba[mask, 2] = np.clip(nz[mask] * 255.0, 128, 255).astype(np.uint8)
    n_rgba[mask, 3] = 255
    Image.fromarray(n_rgba, "RGBA").save(out_path.with_name(f"{out_path.stem}_n.png"))


def _bake_sprite_normal(src_path: Path, out_path: Path) -> None:
    """Builds a tangent-space normal map from sprite alpha dome + luminance relief."""
    img = Image.open(src_path).convert("RGBA")
    arr = np.asarray(img, dtype=np.float32)
    alpha = arr[:, :, 3] > 128.0
    h, w = alpha.shape

    # Exact integer Manhattan-to-Euclidean pillow dome inside opaque silhouette
    dist = np.zeros((h, w), dtype=np.float32)
    if np.any(alpha):
        cur = alpha.copy()
        for step in range(1, 14):
            pad = np.pad(cur, 1, mode="constant", constant_values=False)
            eroded = pad[1:-1, 1:-1] & pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
            dist[cur & (~eroded)] = float(step)
            if not np.any(eroded):
                break
            cur = eroded
        if np.any(cur):
            dist[cur] = 14.0
        dist_norm = np.clip(dist / max(1.0, float(np.max(dist))), 0.0, 1.0)
        dome = np.sqrt(dist_norm)
    else:
        dome = np.zeros((h, w), dtype=np.float32)

    lum = (0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]) / 255.0
    height = np.where(alpha, dome * 2.8 + lum * 1.1, 0.0)

    pad_z = np.pad(height, 1, mode="edge")
    gx = (pad_z[1:-1, 2:] - pad_z[1:-1, :-2]) * 0.95
    gy = (pad_z[2:, 1:-1] - pad_z[:-2, 1:-1]) * 0.95
    gz = np.ones_like(gx) * 1.55
    inv = 1.0 / np.sqrt(gx * gx + gy * gy + gz * gz + 1e-8)
    nx = -gx * inv
    ny = -gy * inv
    nz = gz * inv

    n_rgba = np.zeros((h, w, 4), dtype=np.uint8)
    n_rgba[:, :, 0] = 128
    n_rgba[:, :, 1] = 128
    n_rgba[:, :, 2] = 255
    n_rgba[alpha, 0] = np.clip((nx[alpha] * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    n_rgba[alpha, 1] = np.clip((-ny[alpha] * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    n_rgba[alpha, 2] = np.clip(nz[alpha] * 255.0, 128, 255).astype(np.uint8)
    n_rgba[alpha, 3] = 255
    Image.fromarray(n_rgba, "RGBA").save(out_path)


def main() -> None:
    TEX_OUT_DIR.mkdir(parents=True, exist_ok=True)
    NORM_OUT_DIR.mkdir(parents=True, exist_ok=True)

    _sculpt_fen_moss(TEX_OUT_DIR / "tex_fen_moss.png")
    _sculpt_fen_peat(TEX_OUT_DIR / "tex_fen_peat.png")
    _sculpt_fen_dirt(TEX_OUT_DIR / "tex_fen_dirt.png")
    _sculpt_flemish_cobble(TEX_OUT_DIR / "tex_flemish_cobble.png")
    _sculpt_oak_planks(TEX_OUT_DIR / "tex_oak_planks.png", dark=False)
    _sculpt_oak_planks(TEX_OUT_DIR / "tex_dark_timber.png", dark=True)
    _sculpt_weir_stone(TEX_OUT_DIR / "tex_weir_stone.png")
    _sculpt_plaster_timber(TEX_OUT_DIR / "tex_plaster_timber.png")
    _sculpt_clay_roof(TEX_OUT_DIR / "tex_clay_roof.png")
    _sculpt_slate_roof(TEX_OUT_DIR / "tex_slate_roof.png")
    _sculpt_flemish_brick(TEX_OUT_DIR / "tex_flemish_brick.png")
    _sculpt_harbor_cobble(TEX_OUT_DIR / "tex_harbor_cobble.png")
    _sculpt_sail_canvas(TEX_OUT_DIR / "tex_sail_canvas.png")
    _sculpt_horizon_treeline(TEX_OUT_DIR / "tex_horizon_treeline.png")

    norm_count = 0
    for p in sorted(SPRITES_DIR.glob("*.png")):
        name = p.name
        if name in SPRITE_EXACT or name.startswith(SPRITE_PREFIXES):
            _bake_sprite_normal(p, NORM_OUT_DIR / f"{p.stem}_n.png")
            norm_count += 1

    print(f"HD2D_FORGE_DONE textures=11 normals={norm_count}")
    print(f"HD2D_FORGE_DONE textures=14 normals={norm_count}")


if __name__ == "__main__":
    main()
