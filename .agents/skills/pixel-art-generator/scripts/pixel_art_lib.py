"""
Core Pixel-Art Canvas, Cohesive 32-Color + Ramp Palette, and Grid/Shading Helpers
for Temeraire: Wings of the Brotherhood.
"""

import math
import struct
import zlib

# Cohesive Medieval Flemish & Dragon Palette + Harmonious Shading Ramps
PAL = {
    ".": (0, 0, 0, 0),
    # Outlines & Deep Neutrals
    "K": (27, 23, 29, 255),       # Warm Ink Outline
    "S": (43, 36, 44, 255),       # Deep Slate
    "N": (14, 12, 18, 255),       # Void Night
    "DK": (38, 24, 22, 255),      # Warm Umber Outline
    "DN": (18, 26, 38, 255),      # Deep Navy Outline
    "DE": (19, 41, 32, 255),      # Deep Forest Outline
    "DR": (52, 20, 22, 255),      # Deep Brick/Crimson Outline
    "DO": (18, 20, 28, 255),      # Obsidian Outline

    # Canal Water (Deep Zwin -> Foam)
    "W0": (20, 46, 66, 255),
    "W1": (30, 68, 94, 255),
    "W2": (44, 93, 122, 255),
    "W3": (72, 134, 162, 255),
    "W4": (132, 186, 204, 255),
    "W5": (198, 226, 232, 255),

    # Cobblestone, Granite & Slate
    "C0": (46, 43, 47, 255),
    "C1": (68, 63, 67, 255),
    "C2": (96, 89, 90, 255),
    "C3": (128, 120, 118, 255),
    "C4": (162, 154, 148, 255),
    "CS": (58, 64, 72, 255),      # Cool Slate Stone
    "CS2": (84, 92, 102, 255),

    # Flemish Brick & Terracotta Roofs
    "R0": (68, 30, 27, 255),
    "R1": (104, 48, 40, 255),
    "R2": (138, 66, 52, 255),
    "R3": (170, 96, 72, 255),
    "R4": (198, 128, 96, 255),

    # Timber, Wharf Planks & Leather
    "T0": (48, 28, 17, 255),
    "T1": (78, 47, 28, 255),
    "T2": (112, 70, 42, 255),
    "T3": (146, 96, 58, 255),
    "T4": (178, 126, 80, 255),

    # Foliage, Pine, Brotherhood Emerald & Hemp
    "G0": (32, 48, 28, 255),
    "G1": (48, 72, 37, 255),
    "G2": (72, 102, 49, 255),
    "G3": (106, 136, 68, 255),
    "E0": (24, 54, 42, 255),
    "E1": (38, 82, 64, 255),
    "E2": (58, 114, 88, 255),
    "E3": (86, 148, 112, 255),
    "H0": (136, 104, 54, 255),
    "H1": (176, 140, 80, 255),
    "H2": (214, 180, 112, 255),
    "H3": (236, 208, 148, 255),

    # Skin Ramps (Warm & Shaded)
    "P0": (148, 98, 72, 255),     # Deep Skin Shadow (chin, neck, nostril)
    "P1": (184, 130, 98, 255),    # Mid Skin Shadow
    "P2": (218, 170, 134, 255),   # Base Skin
    "P3": (242, 204, 170, 255),   # Skin Highlight
    "PK": (216, 138, 116, 255),   # Rosy Cheek / Lip Tint

    # Hair Ramps
    "B0": (54, 33, 20, 255),      # Dark Chestnut
    "B1": (92, 56, 33, 255),      # Mid Chestnut
    "B2": (132, 84, 50, 255),     # Chestnut Highlight
    "BL0": (156, 114, 58, 255),   # Sandy / Baker Blonde Shadow
    "BL1": (198, 154, 88, 255),   # Blonde Base
    "BL2": (228, 190, 122, 255),  # Blonde Highlight
    "GR0": (110, 108, 106, 255),  # Silver/Grey Shadow
    "GR1": (156, 154, 148, 255),  # Grey Hair
    "GR2": (204, 200, 194, 255),  # Grey Highlight

    # Cloth & Uniforms
    "U0": (32, 52, 70, 255),      # Boy Navy/Slate Tunic Deep
    "U1": (48, 76, 100, 255),     # Boy Tunic Mid
    "U2": (72, 108, 134, 255),    # Boy Tunic Light
    "D0": (96, 36, 44, 255),      # Clara Rose Dress Deep
    "D1": (138, 54, 62, 255),     # Clara Dress Mid
    "D2": (172, 76, 84, 255),     # Clara Dress Highlight
    "I0": (86, 16, 22, 255),      # Inquisitor Crimson Deep
    "I1": (134, 28, 36, 255),     # Inquisitor Crimson Mid
    "I2": (176, 46, 52, 255),     # Inquisitor Crimson Highlight
    "L0": (236, 228, 212, 255),   # Cream Linen Highlight
    "L1": (208, 198, 180, 255),   # Cream Linen Base
    "L2": (166, 156, 140, 255),   # Linen Shadow

    # Lantern Glow, Gold, Brass & Fire
    "Y0": (178, 104, 28, 255),    # Tarnished Brass / Ember
    "Y1": (226, 152, 48, 255),    # Warm Gold / Flame
    "Y2": (252, 208, 92, 255),    # Bright Gold / Candle
    "Y3": (252, 240, 192, 255),   # Cream Spark / Catchlight

    # Black-Scaled Dragon & Greyling Obsidian/Silver Ramps
    "O0": (18, 20, 28, 255),      # Deepest Obsidian
    "O1": (28, 33, 46, 255),      # Primary Black Scale
    "O2": (44, 53, 74, 255),      # Slate-Blue Rim Scale
    "O3": (70, 84, 114, 255),     # Iridescent Moonlight Rim
    "SG0": (56, 62, 72, 255),     # Silver Greyling Dark
    "SG1": (94, 102, 116, 255),   # Silver Greyling Mid
    "SG2": (138, 148, 162, 255),  # Silver Greyling Light
    "SG3": (182, 190, 200, 255),  # Silver Greyling Highlight

    # Eye Whites & Blood/Ember
    "EW": (244, 242, 236, 255),
    "BLD": (146, 32, 34, 255),
    "BLD2": (192, 54, 48, 255),
}


def shade_color(rgba, factor: float):
    r, g, b, a = rgba
    return (
        max(0, min(255, int(r * factor))),
        max(0, min(255, int(g * factor))),
        max(0, min(255, int(b * factor))),
        a,
    )


def blend_color(c1, c2, t: float):
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
        int(c1[3] + (c2[3] - c1[3]) * t),
    )


class PixelCanvas:
    def __init__(self, w: int, h: int, fill=(0, 0, 0, 0)):
        self.w = w
        self.h = h
        if isinstance(fill, str):
            fill = PAL[fill]
        self.px = [list(fill) for _ in range(w * h)]

    def pset(self, x: int, y: int, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            if isinstance(col, str):
                col = PAL[col]
            if col[3] > 0:
                if col[3] < 255:
                    bg = self.px[y * self.w + x]
                    if bg[3] == 0:
                        self.px[y * self.w + x] = list(col)
                    else:
                        alpha = col[3] / 255.0
                        inv = 1.0 - alpha
                        self.px[y * self.w + x] = [
                            int(col[0] * alpha + bg[0] * inv),
                            int(col[1] * alpha + bg[1] * inv),
                            int(col[2] * alpha + bg[2] * inv),
                            min(255, int(bg[3] + col[3] * (1.0 - bg[3] / 255.0))),
                        ]
                else:
                    self.px[y * self.w + x] = list(col)

    def pset_raw(self, x: int, y: int, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            if isinstance(col, str):
                col = PAL[col]
            self.px[y * self.w + x] = list(col)

    def pget(self, x: int, y: int):
        if 0 <= x < self.w and 0 <= y < self.h:
            return tuple(self.px[y * self.w + x])
        return (0, 0, 0, 0)

    def rect(self, x: int, y: int, w: int, h: int, col):
        for py in range(y, y + h):
            for px in range(x, x + w):
                self.pset(px, py, col)

    def rect_outline(self, x: int, y: int, w: int, h: int, col):
        for px in range(x, x + w):
            self.pset(px, y, col)
            self.pset(px, y + h - 1, col)
        for py in range(y, y + h):
            self.pset(x, py, col)
            self.pset(x + w - 1, py, col)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, col):
        x0 = int(math.floor(cx - rx))
        x1 = int(math.ceil(cx + rx))
        y0 = int(math.floor(cy - ry))
        y1 = int(math.ceil(cy + ry))
        for py in range(y0, y1 + 1):
            for px in range(x0, x1 + 1):
                nx = (px - cx) / max(0.5, rx)
                ny = (py - cy) / max(0.5, ry)
                if nx * nx + ny * ny <= 1.0:
                    self.pset(px, py, col)

    def circle(self, cx: int, cy: int, r: int, col):
        self.ellipse(cx, cy, r + 0.15, r + 0.15, col)

    def line(self, x0: int, y0: int, x1: int, y1: int, col, thickness: int = 1):
        dx = abs(x1 - x0)
        dy = abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx - dy
        cx, cy = x0, y0
        while True:
            if thickness <= 1:
                self.pset(cx, cy, col)
            else:
                self.circle(cx, cy, thickness // 2, col)
            if cx == x1 and cy == y1:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                cx += sx
            if e2 < dx:
                err += dx
                cy += sy

    def draw_grid(self, ox: int, oy: int, rows: list[str], cmap: dict):
        """Blit an ASCII art matrix onto the canvas using cmap (char -> PAL key or RGBA)."""
        for r_idx, row in enumerate(rows):
            for c_idx, ch in enumerate(row):
                if ch in (" ", "."):
                    continue
                val = cmap.get(ch)
                if val is None:
                    val = PAL.get(ch)
                if val is not None:
                    self.pset(ox + c_idx, oy + r_idx, val)

    def blit(self, other: "PixelCanvas", ox: int, oy: int, flip_x: bool = False):
        for y in range(other.h):
            for x in range(other.w):
                sx = (other.w - 1 - x) if flip_x else x
                col = other.pget(sx, y)
                if col[3] > 0:
                    self.pset(ox + x, oy + y, col)

    def add_outline(self, outline_col="K", selective_hue: bool = True):
        """Add a crisp 1px outer silhouette outline. When selective_hue=True, tints outline toward neighbor hue."""
        base_oc = PAL[outline_col] if isinstance(outline_col, str) else outline_col
        to_mark = []
        for y in range(self.h):
            for x in range(self.w):
                if self.pget(x, y)[3] == 0:
                    adj = None
                    # Prefer cardinal neighbors for clean corner-free pixel-art silhouette
                    for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                        ncol = self.pget(x + dx, y + dy)
                        if ncol[3] > 180:
                            adj = ncol
                            break
                    if adj is not None:
                        if selective_hue:
                            # Mix 35% of neighbor dark tone with 65% outline ink
                            oc = (
                                int(base_oc[0] * 0.72 + adj[0] * 0.14),
                                int(base_oc[1] * 0.72 + adj[1] * 0.14),
                                int(base_oc[2] * 0.72 + adj[2] * 0.14),
                                255,
                            )
                        else:
                            oc = base_oc
                        to_mark.append((x, y, oc))
        for x, y, oc in to_mark:
            self.pset(x, y, oc)

    def refine_epx_architecture(self, add_mortar_micro: bool = True) -> "PixelCanvas":
        """Upscale 2x using Eric's Pixel Expansion (EPX / Scale2x) so Gothic arches,
        spires, and rose windows stay razor-sharp at ~1.5x world texel density."""
        out = PixelCanvas(self.w * 2, self.h * 2)
        for y in range(self.h):
            for x in range(self.w):
                P = self.pget(x, y)
                A = self.pget(x, y - 1)
                B = self.pget(x + 1, y)
                C = self.pget(x - 1, y)
                D = self.pget(x, y + 1)
                p1, p2, p3, p4 = P, P, P, P
                if C == A and C != D and A != B:
                    p1 = A
                if A == B and A != C and B != D:
                    p2 = B
                if D == C and D != B and C != A:
                    p3 = C
                if B == D and B != A and D != C:
                    p4 = D
                if add_mortar_micro and P[3] == 255 and p1 == P and p2 == P and p3 == P and p4 == P:
                    # Subtle micro-relief seam on broad masonry/shingle runs while keeping silhouettes untouched
                    if ((x + y) % 5 == 0) and (A == P and B == P and C == P and D == P):
                        r, g, b, a = P
                        p4 = (max(0, r - 6), max(0, g - 6), max(0, b - 5), a)
                ox, oy = x * 2, y * 2
                out.pset_raw(ox, oy, p1)
                out.pset_raw(ox + 1, oy, p2)
                out.pset_raw(ox, oy + 1, p3)
                out.pset_raw(ox + 1, oy + 1, p4)
        return out

    def save_png(self, path: str):
        raw = bytearray()
        for y in range(self.h):
            raw.append(0)
            for x in range(self.w):
                r, g, b, a = self.px[y * self.w + x]
                raw.extend((r, g, b, a))

        def chunk(tag: bytes, data: bytes) -> bytes:
            return (
                struct.pack("!I", len(data))
                + tag
                + data
                + struct.pack("!I", zlib.crc32(tag + data) & 0xFFFFFFFF)
            )

        ihdr = struct.pack("!IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0)
        idat = zlib.compress(bytes(raw), 9)
        png_bytes = (
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", idat)
            + chunk(b"IEND", b"")
        )
        with open(path, "wb") as f:
            f.write(png_bytes)
