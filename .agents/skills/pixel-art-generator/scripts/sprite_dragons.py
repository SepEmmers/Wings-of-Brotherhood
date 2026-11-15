"""
Animated dragon sprites (Virelai, Greyling, Dying Black Dragon, Wild Reapers/Longwings, Hatchling).
"""

import math
import os
import random
from pixel_art_lib import PAL, PixelCanvas, blend_color

# ============================================================================
# 4. ANIMATED DRAGONS (VIRELAI, GREYLING, DYING BLACK-SCALED DRAGON)
# ============================================================================

def make_dragons(sprites_dir: str):
    def _draw_swept_wing(
        canvas: PixelCanvas,
        cx: int,
        sh_dx: int,
        sh_y: int,
        armpit_y: int,
        elbow_i: int,
        wr_y: int,
        span: int,
        tip_y: int,
        colors: dict,
        arch_depth: float = 4.5,
    ):
        """Draw paired top-down swept dragon wings (leading bone + thumb claw facing +y head, scalloped membrane trailing -y tail)."""
        bays = 3
        cusp_indices = [round((span - 1) * k / bays) for k in range(1, bays)]
        for side in (-1, 1):
            cusp_pts = []
            for i in range(span):
                wx = cx + side * (sh_dx + i)
                if i <= elbow_i:
                    t_arm = i / max(1, elbow_i)
                    front_y = int(round(sh_y + (wr_y - sh_y) * t_arm))
                else:
                    t_out = (i - elbow_i) / max(1, span - 1 - elbow_i)
                    front_y = int(round(wr_y + (tip_y - wr_y) * t_out))
                t_span = i / max(1, span - 1)
                base_back_y = int(round(armpit_y + ((tip_y - 2) - armpit_y) * t_span))
                u = t_span * bays
                arch_in = int(round(math.sin((u % 1.0) * math.pi) * arch_depth)) if i < span - 1 else 0
                back_y = min(front_y - (1 if i >= span - 2 else 2), base_back_y + arch_in)
                if i in cusp_indices:
                    cusp_pts.append((wx, back_y))
                for wy in range(back_y, front_y + 1):
                    if wy >= front_y - 2:
                        col = colors["hi"]
                    elif wy <= back_y + 1:
                        col = colors["rim"]
                    elif (wx + wy) % colors.get("pat_mod", 7) == 0:
                        col = colors["pat"]
                    else:
                        col = colors["mid"]
                    canvas.pset(wx, wy, col)

            sx0 = cx + side * sh_dx
            wr_x = cx + side * (sh_dx + elbow_i)
            tip_x = cx + side * (sh_dx + span - 1)
            # Wing-finger ribs fanning backward from wrist to trailing scallop points
            for cx_pt, cy_pt in cusp_pts:
                canvas.line(wr_x, wr_y - 1, cx_pt, cy_pt + 1, colors["rib"])
            # Leading arm bone + outer wingtip spar along front (+y) edge
            canvas.line(sx0, sh_y - 1, wr_x, wr_y - 1, colors["bone_shad"])
            canvas.line(wr_x, wr_y - 1, tip_x, tip_y - 1, colors["bone_shad"])
            canvas.line(sx0, sh_y, wr_x, wr_y, colors["bone"])
            canvas.line(wr_x, wr_y, tip_x, tip_y, colors.get("outer_bone", colors["bone"]))
            # Forward-pointing ivory wrist claw & wingtip spur
            canvas.pset(wr_x, wr_y + 1, colors["claw"])
            canvas.pset(wr_x + side, wr_y + 1, colors["claw"])
            canvas.pset(tip_x, tip_y + 1, colors["claw"])

    # 1. Anna's Emerald Dragon 'Virelai' (88x72 -> 176x144, idle 0/1 & happy feeding eat_0/eat_1)
    def _paint_virelai(frame: int, eat_mode: bool = False) -> None:
        da = PixelCanvas(88, 72)
        wr_y = (41 if frame == 1 else 43) if not eat_mode else (41 if frame == 0 else 39)
        tip_y = (20 if frame == 1 else 26) if not eat_mode else (24 if frame == 0 else 19)
        armpit_y = 25 if frame == 0 else 23
        _draw_swept_wing(
            da, cx=44, sh_dx=7, sh_y=38, armpit_y=armpit_y,
            elbow_i=12, wr_y=wr_y, span=34, tip_y=tip_y,
            colors={"hi": "E2", "mid": "E1", "rim": "E0", "pat": "E2", "pat_mod": 7, "bone": "E3", "bone_shad": "G2", "rib": "E2", "claw": "C4"},
        )

        # Curled armored emerald tail (idle gently waves; eat_mode wags left _0 -> right _1)
        tail_bias = 0.0 if not eat_mode else (-6.5 if frame == 0 else 6.5)
        for ty in range(5, 22):
            u_tail = max(0.0, (22 - ty) / 17.0)
            tx = int(round(44 + math.sin(ty * 0.35) * 4 + tail_bias * u_tail))
            w = 2 if ty < 12 else 3
            da.rect(tx - w, ty, w * 2, 1, "E1")
            da.pset(tx, ty, "E3")
        da.ellipse(45 + tail_bias, 5, 4, 2.5, "E2")

        # Muscular torso & dorsal scales
        da.ellipse(44, 31, 9.5, 13.0, "E0")
        da.ellipse(44, 31, 8.0, 11.5, "E1")
        da.ellipse(44, 30, 5.5, 9.0, "E2")
        for sy in range(20, 42, 3):
            da.rect(43, sy, 2, 2, "E3")

        # Medieval Oiled-Leather & Hemp Brotherhood Rider Harness
        da.rect(36, 25, 16, 3, "T1")
        da.line(36, 25, 51, 25, "T3")
        da.rect(36, 34, 16, 3, "H1")
        da.line(36, 34, 51, 34, "H2")
        da.rect(42, 23, 4, 16, "T2")
        for cx in (38, 49):
            da.pset(cx, 26, "Y2")
            da.pset(cx, 35, "Y2")
        da.rect(33, 28, 4, 7, "T0")
        da.rect(51, 28, 4, 7, "T0")
        da.rect(34, 29, 2, 5, "T2")
        da.rect(52, 29, 2, 5, "T2")

        # Neck & Noble Horned Head
        hdy = 0 if not eat_mode else (3 if frame == 0 else -1)
        da.ellipse(44, 46 + hdy // 2, 5.2, 5.0, "E1")
        da.ellipse(44, 46 + hdy // 2, 3.2, 4.0, "E2")
        da.ellipse(44, 54 + hdy, 7.2, 6.8, "E0")
        da.ellipse(44, 54 + hdy, 6.0, 5.5, "E1")
        da.ellipse(44, 55 + hdy, 4.0, 4.2, "E2")
        da.ellipse(44, 58 + hdy, 3.0, 2.2, "E3")
        da.line(39, 49 + hdy, 34, 43 + hdy, "C3")
        da.line(40, 50 + hdy, 35, 44 + hdy, "C2")
        da.line(49, 49 + hdy, 54, 43 + hdy, "C3")
        da.line(48, 50 + hdy, 53, 44 + hdy, "C2")
        da.rect(39, 55 + hdy, 2, 2, "Y2")
        da.rect(47, 55 + hdy, 2, 2, "Y2")
        da.pset(40, 56 + hdy, "K")
        da.pset(48, 56 + hdy, "K")

        if eat_mode and frame == 0:
            # Parted lower jaws & ivory fangs reaching for ration
            da.rect(40, 59 + hdy, 8, 5, "I0")
            da.rect(41, 60 + hdy, 6, 3, "I1")
            da.pset(41, 59 + hdy, "L0")
            da.pset(46, 59 + hdy, "L0")
            da.rect(42, 61 + hdy, 4, 2, "R3")
        elif eat_mode and frame == 1:
            # Happy chomp gleam & celebration sparks
            da.pset(38, 56 + hdy, "R3")
            da.pset(49, 56 + hdy, "R3")
            for sx, sy in ((30, 52), (57, 52), (33, 59), (54, 59)):
                da.pset(sx, sy, "Y2")
                da.pset(sx, sy - 1, "Y3")

        da.add_outline("DE", selective_hue=True)
        out_name = f"dragon_anna_eat_{frame}.png" if eat_mode else f"dragon_anna_{frame}.png"
        da.save_png(os.path.join(sprites_dir, out_name))
        if not eat_mode and frame == 0:
            da.save_png(os.path.join(sprites_dir, "dragon_anna.png"))

    for frame in (0, 1):
        _paint_virelai(frame, eat_mode=False)
        _paint_virelai(frame, eat_mode=True)

        # Top-down saddle rider sprite facing +y to match flight direction cleanly
        sr = PixelCanvas(20, 22)
        lean = 1 if frame == 1 else 0
        # Stirrup boots straddling harness ribs
        sr.rect(3, 5 + lean, 3, 5, "T0")
        sr.rect(4, 6 + lean, 1, 3, "T2")
        sr.rect(14, 5 + lean, 3, 5, "T0")
        sr.rect(15, 6 + lean, 1, 3, "T2")
        # Leather reins reaching forward toward dragon neck
        sr.line(5, 15 + lean, 7, 19, "T0")
        sr.line(14, 15 + lean, 12, 19, "T0")
        # Coat torso & diagonal Brotherhood hemp shoulder sling
        sr.ellipse(10, 8 + lean, 4.5, 4.0, "U0")
        sr.ellipse(10, 8 + lean, 3.6, 3.0, "U1")
        sr.line(7, 6 + lean, 12, 11 + lean, "H1")
        sr.pset(10, 9 + lean, "Y2")
        # Arms & hands gripping reins ahead
        sr.rect(4, 9 + lean, 2, 5, "U2")
        sr.rect(14, 9 + lean, 2, 5, "U2")
        sr.rect(4, 14 + lean, 2, 2, "P2")
        sr.rect(14, 14 + lean, 2, 2, "P2")
        # Chestnut hair crown seen from top-behind + brow/nose peeking forward (+y)
        sr.ellipse(10, 12 + lean, 3.8, 3.6, "B0")
        sr.ellipse(10, 11 + lean, 3.2, 3.0, "B1")
        sr.pset(9, 10 + lean, "B2")
        sr.pset(11, 10 + lean, "B2")
        sr.rect(9, 15 + lean, 2, 1, "P2")
        sr.add_outline("DK", selective_hue=True)
        sr.save_png(os.path.join(sprites_dir, f"boy_saddle_{frame}.png"))

    # 2. Kestrel (Silver-Slate Greyling) — Sculpted 3-Stage Growth Progression
    #    - Year 1 wounded/hurt & Year 1 healed w/ cliffsage wrap (`48x40` -> `96x80`)
    #    - Year 3 sleek adolescent courier w/ apprentice breast strap (`64x52` -> `128x104`)
    #    - Year 5 full-grown Adult Silver Greyling w/ Brotherhood dispatch harness (`76x62` -> `152x124`)
    def _paint_greyling(stage: str, frame: int = 0, hurt: bool = False) -> PixelCanvas:
        specs = {
            "y1": {"w": 48, "h": 40, "sh_dx": 3, "sh_y": 20, "elbow": 6, "span": 18,
                   "wr_y": (23, 22), "tip_y": (14, 11), "amp_y": (13, 12), "arch": 1.6,
                   "torso_rx": 4.8, "torso_ry": 6.2, "torso_y": 19, "head_y": 29, "head_rx": 4.7, "head_ry": 4.1, "snout_y": 34},
            "y3": {"w": 64, "h": 52, "sh_dx": 4, "sh_y": 27, "elbow": 8, "span": 24,
                   "wr_y": (31, 29), "tip_y": (17, 13), "amp_y": (17, 15), "arch": 2.2,
                   "torso_rx": 5.8, "torso_ry": 8.2, "torso_y": 26, "head_y": 39, "head_rx": 5.2, "head_ry": 4.7, "snout_y": 46},
            "y5": {"w": 76, "h": 62, "sh_dx": 5, "sh_y": 32, "elbow": 10, "span": 29,
                   "wr_y": (37, 35), "tip_y": (19, 14), "amp_y": (19, 17), "arch": 2.6,
                   "torso_rx": 7.2, "torso_ry": 10.2, "torso_y": 30, "head_y": 46, "head_rx": 6.0, "head_ry": 5.4, "snout_y": 54},
        }
        sp = specs[stage]
        w, h = sp["w"], sp["h"]
        cx = w // 2
        dg = PixelCanvas(w, h)
        dy = -1 if (frame == 1 and not hurt) else 0
        lift = 1 if hurt else 0

        if hurt:
            # Uneven slumped young courier wings on straw/cobble
            for side, droop in ((-1, 2), (1, 0)):
                for i in range(15):
                    wx = cx + side * (4 + i)
                    back_y = 18 + i // 4 + droop
                    front_y = 26 - i // 5 + droop
                    for wy in range(back_y, front_y + 1):
                        col = "SG2" if wy >= front_y - 1 else ("SG0" if wy <= back_y + 1 else "SG1")
                        dg.pset(wx, wy, col)
                dg.line(cx + side * 4, 24 + droop, cx + side * 14, 23 + droop, "SG3")
            # Raw left wing laceration fleck before Sister Maren's cliffsage salve
            dg.pset(cx - 10, 22, "BLD")
            dg.pset(cx - 9, 23, "BLD2")
            dg.pset(cx - 11, 23, "BLD")
        else:
            wing_colors = {
                "hi": "SG2", "mid": "SG1", "rim": "SG0",
                "pat": "SG3" if stage == "y1" else "W5", "pat_mod": 8 if stage == "y5" else 9,
                "bone": "SG3", "outer_bone": "W5", "bone_shad": "SG0", "rib": "SG2", "claw": "C4",
            }
            _draw_swept_wing(
                dg, cx=cx, sh_dx=sp["sh_dx"], sh_y=sp["sh_y"] + dy,
                armpit_y=sp["amp_y"][frame] + dy, elbow_i=sp["elbow"],
                wr_y=sp["wr_y"][frame] + dy, span=sp["span"], tip_y=sp["tip_y"][frame] + dy,
                colors=wing_colors, arch_depth=sp["arch"],
            )

        # Articulated serpentine tail with sleek diamond silver courier rudder fluke at top (-y)
        tail_base_y = sp["torso_y"] - int(sp["torso_ry"]) + 2 + lift
        tail_top_y = 5 if stage == "y1" else 6
        wag = (-2.0 if frame == 0 else 2.0) if not hurt else -4.0
        for ty in range(tail_top_y, tail_base_y + 1):
            u = max(0.0, (tail_base_y - ty) / max(1.0, tail_base_y - tail_top_y))
            bend = math.sin(u * math.pi * 1.15) * (2.6 if stage == "y1" else 3.8) + wag * (u ** 1.3)
            tx = int(round(cx + bend))
            rad = 1 if u > 0.65 else (2 if stage != "y5" or u > 0.3 else 3)
            dg.rect(tx - rad, ty, rad * 2 + 1, 1, "SG1" if u > 0.5 else "SG0")
            dg.pset(tx, ty, "W5" if (stage == "y5" and ty % 2 == 0) else "SG3")
        tip_x = int(round(cx + wag))
        fluke_r = 2 if stage == "y1" else 3
        for dt in range(-fluke_r, fluke_r + 1):
            fw = max(0, fluke_r - abs(dt))
            dg.line(tip_x - fw, tail_top_y + dt, tip_x + fw, tail_top_y + dt, "SG2" if abs(dt) > 0 else "SG3")
        dg.pset(tip_x, tail_top_y, "W5")

        # Sleek muscular Greyling torso + dorsal spine ridge
        ty_c = sp["torso_y"] + dy + lift
        dg.ellipse(cx, ty_c, sp["torso_rx"], sp["torso_ry"], "SG0")
        dg.ellipse(cx, ty_c, sp["torso_rx"] - 1.3, sp["torso_ry"] - 1.2, "SG1")
        dg.ellipse(cx, ty_c - 0.5, sp["torso_rx"] - 2.6, sp["torso_ry"] - 2.6, "SG2")
        spine_step = 2 if stage == "y1" else 3
        for sy in range(ty_c - int(sp["torso_ry"]) + 2, ty_c + int(sp["torso_ry"]) - 1, spine_step):
            dg.rect(cx - 1 if stage == "y5" else cx, sy, 2 if stage == "y5" else 1, 1, "W5" if stage == "y5" else "SG3")

        # Timeline Gear / Treatment Markers across Growth
        if stage == "y1" and not hurt:
            # Maren's linen cliffsage bandage wrapped over left shoulder (matches Year 1 dialogue portrait)
            dg.line(cx - 5, ty_c - 1, cx - 1, ty_c - 4, "L0")
            dg.line(cx - 5, ty_c, cx - 1, ty_c - 3, "L1")
            dg.pset(cx - 3, ty_c - 2, "E2")
            dg.pset(cx - 4, ty_c - 1, "E3")
        elif stage == "y3":
            # Healed faint silver scar on left shoulder + Brotherhood leather chest strap & brass tag
            dg.line(cx - 6, ty_c - 2, cx - 4, ty_c - 3, "W5")
            dg.line(cx - 5, ty_c + 2, cx + 5, ty_c + 2, "T0")
            dg.line(cx - 4, ty_c + 3, cx + 4, ty_c + 3, "T2")
            dg.rect(cx - 1, ty_c + 2, 2, 2, "Y2")
        elif stage == "y5":
            # Full Light Courier Rigging: fitted leather shoulder straps, brass chest clasp & tucked canvas pouches
            dg.line(cx - 6, ty_c - 2, cx + 6, ty_c + 4, "T0")
            dg.line(cx - 6, ty_c + 4, cx + 6, ty_c - 2, "T0")
            dg.line(cx - 5, ty_c - 1, cx + 5, ty_c + 3, "T2")
            dg.line(cx - 5, ty_c + 3, cx + 5, ty_c - 1, "T2")
            dg.rect(cx - 1, ty_c, 3, 3, "Y1")
            dg.pset(cx, ty_c + 1, "Y3")
            # Compact bevel-tucked hemp courier dispatch tubes behind shoulders
            dg.rect(cx - 8, ty_c - 1, 3, 4, "H0")
            dg.rect(cx - 7, ty_c, 2, 2, "H2")
            dg.rect(cx + 6, ty_c - 1, 3, 4, "H0")
            dg.rect(cx + 6, ty_c, 2, 2, "H2")

        # Slender agile neck + tapering falcon-courier cranium & swept silver ear-crest plumes
        neck_y = (ty_c + sp["head_y"] + lift) // 2
        neck_w = 2.6 if stage == "y1" else (3.2 if stage == "y3" else 3.8)
        dg.ellipse(cx, neck_y, neck_w, 3.8 if stage == "y1" else 4.8, "SG1")
        dg.ellipse(cx, neck_y, max(1.4, neck_w - 1.2), 2.8 if stage == "y1" else 3.6, "SG2")

        hy = sp["head_y"] + dy + lift
        sny = sp["snout_y"] + dy + lift
        dg.ellipse(cx, hy, sp["head_rx"], sp["head_ry"], "SG0")
        dg.ellipse(cx, hy, sp["head_rx"] - 1.1, sp["head_ry"] - 1.0, "SG1")
        dg.ellipse(cx, hy - 0.5, sp["head_rx"] - 2.2, sp["head_ry"] - 2.0, "SG2")
        # Sleek tapering courier snout reaching +y
        for sy_off in range(max(1, sny - hy)):
            t_s = sy_off / max(1, sny - hy)
            sw = max(1, int(round((2.6 if stage == "y1" else 3.2) * (1.0 - t_s * 0.55))))
            dg.rect(cx - sw, hy + sy_off, sw * 2 + 1, 1, "SG2" if t_s < 0.6 else "SG3")
            dg.pset(cx, hy + sy_off, "W5")
        dg.pset(cx - 1, sny - 1, "SG0")
        dg.pset(cx + 1, sny - 1, "SG0")

        # Swept Greyling ear-crest plumes (growing distinctly longer & double-plumed by Year 5!)
        plume_dx = 5 if stage == "y1" else (7 if stage == "y3" else 9)
        plume_dy = -4 if stage == "y1" else (-6 if stage == "y3" else -8)
        if hurt:
            plume_dy = -1
        for side in (-1, 1):
            dg.line(cx + side * 3, hy - 2, cx + side * plume_dx, hy + plume_dy, "SG3")
            dg.line(cx + side * 3, hy - 1, cx + side * (plume_dx - 1), hy + plume_dy + 1, "SG2")
            if stage in ("y3", "y5"):
                dg.pset(cx + side * plume_dx, hy + plume_dy, "W5")
            if stage == "y5":
                dg.line(cx + side * 4, hy, cx + side * (plume_dx + 1), hy - 4, "SG3")
                dg.pset(cx + side * (plume_dx + 1), hy - 4, "W5")

        # Expressive keen golden-amber eyes
        eye_dx = 2 if stage == "y1" else 3
        dg.pset(cx - eye_dx, hy + 1, "Y2")
        dg.pset(cx + eye_dx, hy + 1, "Y2")
        dg.pset(cx - eye_dx, hy, "Y3")
        dg.pset(cx + eye_dx, hy, "Y3")
        if stage in ("y3", "y5"):
            dg.pset(cx - eye_dx + 1, hy + 1, "K")
            dg.pset(cx + eye_dx - 1, hy + 1, "K")

        dg.add_outline("DN", selective_hue=True)
        return dg

    for frame in (0, 1):
        dg1 = _paint_greyling("y1", frame=frame, hurt=False)
        dg1.save_png(os.path.join(sprites_dir, f"dragon_greyling_{frame}.png"))
        if frame == 0:
            dg1.save_png(os.path.join(sprites_dir, "dragon_greyling.png"))
        _paint_greyling("y3", frame=frame, hurt=False).save_png(os.path.join(sprites_dir, f"dragon_greyling_y3_{frame}.png"))
        _paint_greyling("y5", frame=frame, hurt=False).save_png(os.path.join(sprites_dir, f"dragon_greyling_y5_{frame}.png"))

    _paint_greyling("y1", frame=0, hurt=True).save_png(os.path.join(sprites_dir, "dragon_greyling_hurt.png"))

    # Helper: Sculpted Dying / Reveal / Dead Unseen Black-Scaled Dragon (112x84 -> 224x168)
    def _build_fallen_black_dragon(mode: str, breath: int = 0) -> PixelCanvas:
        db = PixelCanvas(112, 84)
        slump = 3 if mode == "dead" else 0
        by = slump

        # Grounded ash crater shadow beneath chest, flank & tail (fractional radii prevent cardinal spikes)
        db.ellipse(54, 60, 41.3, 15.3, (16, 15, 22, 122))
        db.ellipse(48, 57, 29.4, 11.4, (12, 10, 16, 136))

        # Sinuous tapering S-curved tail cradling bottom edge toward nest hollow
        tail_pts = []
        for s in range(52):
            t = s / 51.0
            if t < 0.45:
                u = t / 0.45
                tx = 38 - u * 21 + math.sin(u * math.pi) * -3
                ty = 48 + by + u * 16
            else:
                u = (t - 0.45) / 0.55
                tx = 17 + u * 66
                ty = 64 + by * 0.6 + math.sin(u * math.pi) * 7.5 - u * 3.0
            rad = max(1.3, 5.2 * (1.0 - t * 0.76))
            tail_pts.append((int(round(tx)), int(round(ty)), rad, s))
        for tx, ty, rad, s in tail_pts:
            db.ellipse(tx, ty + 1, rad, max(1.0, rad * 0.78), "O0")
            db.ellipse(tx, ty, max(1.0, rad * 0.85), max(1.0, rad * 0.68), "O1")
            if s % 4 == 0:
                db.pset(tx, ty - max(1, int(rad * 0.55)), "O3")
                if s % 8 == 0 and rad > 1.8:
                    db.pset(tx + 1, ty - max(1, int(rad * 0.55)), "CS2")
            elif s % 4 == 2:
                db.pset(tx, ty, "O2")
        # Barbed tail spade tip pointing lovingly near the egg hollow
        sp_x, sp_y = tail_pts[-1][0], tail_pts[-1][1]
        db.line(sp_x, sp_y, sp_x + 5, sp_y - 2, "O2")
        db.line(sp_x + 1, sp_y + 1, sp_x + 4, sp_y + 2, "O0")
        db.pset(sp_x + 5, sp_y - 2, "O3")

        # Far/Left tattered anatomical bat-wing splayed behind torso
        l_sh = (44, 38 + by)
        l_elb = (31, 27 + by)
        l_wri = (24, 21 + by)
        l_tips = [(8, 37 + by), (16, 48 + by), (26, 51 + by), (35, 48 + by)]
        # Polygon-free triangle fan membrane fill with scalloped edges & torn hunter notch
        def _fill_tri_wing(p0, p1, p2, notch_hole=False):
            minx = max(0, min(p0[0], p1[0], p2[0]))
            maxx = min(111, max(p0[0], p1[0], p2[0]))
            miny = max(0, min(p0[1], p1[1], p2[1]))
            maxy = min(83, max(p0[1], p1[1], p2[1]))
            denom = (p1[1] - p2[1]) * (p0[0] - p2[0]) + (p2[0] - p1[0]) * (p0[1] - p2[1])
            if denom == 0:
                return
            for py in range(miny, maxy + 1):
                for px in range(minx, maxx + 1):
                    a = ((p1[1] - p2[1]) * (px - p2[0]) + (p2[0] - p1[0]) * (py - p2[1])) / denom
                    b = ((p2[1] - p0[1]) * (px - p2[0]) + (p0[0] - p2[0]) * (py - p2[1])) / denom
                    c = 1.0 - a - b
                    if a >= 0.0 and b >= 0.0 and c >= 0.0:
                        # Scallop trim along trailing web (b+c near 1, middle between b & c)
                        if a < 0.22 and abs(b - c) < 0.28 and (a + 0.14 * (1.0 - abs(b - c) * 3.0)) < 0.22:
                            continue
                        if notch_hole and abs(px - 19) <= 2 and abs(py - (35 + by)) <= 2:
                            continue
                        if a > 0.65:
                            col = "O2" if (px + py) % 2 else "O1"
                        elif b < 0.15 or c < 0.15:
                            col = "O0"
                        else:
                            col = "O1" if ((px * 3 + py * 5) % 7) else "O2"
                        db.pset(px, py, col)

        _fill_tri_wing(l_wri, l_tips[0], l_tips[1], notch_hole=True)
        _fill_tri_wing(l_wri, l_tips[1], l_tips[2], notch_hole=True)
        _fill_tri_wing(l_sh, l_wri, l_tips[2])
        _fill_tri_wing(l_sh, l_tips[2], l_tips[3])
        db.line(l_sh[0], l_sh[1], l_elb[0], l_elb[1], "O3")
        db.line(l_elb[0], l_elb[1], l_wri[0], l_wri[1], "O3")
        for ti, tip in enumerate(l_tips):
            src = l_wri if ti < 3 else l_sh
            db.line(src[0], src[1], tip[0], tip[1], "O2" if ti > 0 else "O3")
        db.rect(l_wri[0] - 1, l_wri[1] - 2, 2, 2, "C4")

        # Hind thigh & coiled clawed leg anchored in dirt
        db.ellipse(38, 49 + by, 10.5, 8.5, "O0")
        db.ellipse(38, 48 + by, 8.5, 6.8, "O1")
        db.ellipse(36, 45 + by, 5.5, 4.0, "O2")
        db.line(33, 55 + by, 28, 59 + by, "O1")
        db.pset(27, 60 + by, "C3")

        # Sculpted heavy obsidian ribcage & shoulder mass (gentle chest heave in frame 1)
        rb = by - breath
        db.ellipse(50, 44 + rb, 17.5, 13.0, "O0")
        db.ellipse(50, 43 + rb, 15.2, 10.8, "O1")
        db.ellipse(48, 39 + rb, 11.5, 7.6, "O2")
        # Carapace scale plate bands & moonlight dorsal ridge spines
        for idx, rx in enumerate(range(37, 62, 4)):
            plate_y = 33 + rb + abs(rx - 49) // 5
            db.line(rx, plate_y + 1, rx - 2, plate_y + 7, "O0")
            db.line(rx + 1, plate_y + 1, rx - 1, plate_y + 6, "O2")
            db.rect(rx, plate_y - 2, 2, 3, "O3")
            if idx % 2 == 0:
                db.pset(rx, plate_y - 3, "CS2")
        # Sinuous plated neck connecting chest smoothly forward-right to cranium
        for i in range(18):
            u = i / 17.0
            nx = int(58 + u * 16)
            ny = int(43 + by + math.sin(u * math.pi) * -2.5 + u * 7.5)
            nrad = 6.2 - u * 1.3
            db.ellipse(nx, ny + 1, nrad, nrad * 0.88, "O0")
            db.ellipse(nx, ny, nrad * 0.82, nrad * 0.72, "O1")
            if i % 3 == 0:
                db.pset(nx, ny - int(nrad * 0.65), "O3")
                db.pset(nx + 1, ny + int(nrad * 0.55), "CS")

        # Heavy foreleg braced forward under chest & gripping earth beside head
        db.ellipse(57, 50 + by, 6.0, 5.0, "O0")
        db.ellipse(57, 49 + by, 4.6, 3.8, "O2")
        db.line(58, 52 + by, 63, 58 + by, "O1")
        db.line(59, 52 + by, 64, 58 + by, "O2")
        db.ellipse(67, 59 + by, 4.8, 2.8, "O0")
        db.ellipse(66, 58 + by, 3.8, 2.0, "O1")
        for cx_t, cy_t in ((69, 60 + by), (72, 59 + by), (66, 61 + by)):
            db.line(cx_t, cy_t, cx_t + 2, cy_t + 1, "C4")

        # Anatomical Near/Right Wing: protective cape in dying, raised canopy in reveal/breath, limp in dead
        r_sh = (54, 41 + rb)
        if mode in ("reveal", "breath"):
            r_elb = (53, 25)
            r_wri = (56, 15)
            r_tips = [(85, 16), (80, 29), (71, 36), (62, 36)]
        elif mode == "dead":
            r_elb = (59, 36 + by)
            r_wri = (68, 34 + by)
            r_tips = [(91, 44 + by), (83, 51 + by), (72, 51 + by), (63, 47 + by)]
        else:
            r_elb = (59, 30 + rb)
            r_wri = (68, 25 + rb)
            r_tips = [(88, 33 + rb), (84, 44 + rb), (75, 47 + rb), (66, 44 + rb)]

        _fill_tri_wing(r_wri, r_tips[0], r_tips[1])
        _fill_tri_wing(r_wri, r_tips[1], r_tips[2])
        _fill_tri_wing(r_sh, r_wri, r_tips[2])
        _fill_tri_wing(r_sh, r_tips[2], r_tips[3])
        db.line(r_sh[0], r_sh[1], r_elb[0], r_elb[1], "O3")
        db.line(r_elb[0], r_elb[1], r_wri[0], r_wri[1], "CS2")
        for ti, tip in enumerate(r_tips):
            src = r_wri if ti < 3 else r_sh
            db.line(src[0], src[1], tip[0], tip[1], "O3" if ti < 2 else "O2")
        db.rect(r_wri[0], r_wri[1] - 1, 2, 2, "C4")

        # Sculpted Horned Dragon Head & Tapered Jaws facing down-right (or braced east in breath)
        hx, hy = (77, 48 + by - breath) if mode == "breath" else (77, 50 + by)
        db.ellipse(hx, hy, 8.3, 6.2, "O0")
        db.ellipse(hx, hy - 1, 7.1, 4.9, "O1")
        db.ellipse(hx - 1, hy - 2, 4.6, 2.9, "O2")
        # Tapered sculpted snout bridge & subtle flared muzzle
        for step_s in range(15):
            u = step_s / 14.0
            sx = int(hx + 3 + u * 14)
            sy = int(hy + u * (1.2 if mode == "breath" else 3.0))
            half_h = max(2, int(3.8 * (1.0 - u * 0.50)))
            for py in range(sy - half_h, sy + half_h):
                col = "O2" if py <= sy - half_h + 1 else ("O0" if py == sy + half_h - 1 else "O1")
                db.pset(sx, py, col)
            if step_s in (3, 7, 11):
                db.pset(sx, sy - half_h, "O3")
        db.rect(hx + 14, hy + (0 if mode == "breath" else 1), 2, 2, "O3")  # flared nostril crest
        # Parted lower mandible (widely flared with amber throat glow when clearing Stone Causeway)
        if mode == "breath":
            db.line(hx + 2, hy + 4, hx + 16, hy + 8, "O0")
            db.line(hx + 3, hy + 5, hx + 15, hy + 9, "O1")
            db.line(hx + 6, hy + 3, hx + 16, hy + 4, "Y1")
            db.line(hx + 8, hy + 4, hx + 17, hy + 5, "Y3")
            db.pset(hx + 14, hy + 6, "L0")
            db.pset(hx + 11, hy + 6, "L1")
        else:
            db.line(hx + 2, hy + 4, hx + 15, hy + 5, "O0")
            db.line(hx + 3, hy + 5, hx + 14, hy + 6, "O1")
            db.pset(hx + 13, hy + 4, "L0")  # lower canine fang
            db.pset(hx + 10, hy + 4, "L1")
        # Sweeping ribbed slate-ivory horns & jaw spurs
        for off_y, col_h in ((0, "C3"), (-1, "C2"), (1, "C0")):
            db.line(hx - 3, hy - 4 + off_y, hx - 12, hy - 13 + off_y, col_h)
            db.line(hx - 12, hy - 13 + off_y, hx - 17, hy - 15 + off_y, "C4" if off_y == 0 else col_h)
        db.line(hx - 5, hy - 1, hx - 13, hy - 7, "C2")
        db.line(hx - 5, hy + 3, hx - 11, hy + 1, "O3")  # cheek frill spikes
        # Soulful amber dragon eye (bright & protective in dying/reveal/breath, gently closed in dead)
        if mode == "dead":
            db.line(hx + 2, hy - 1, hx + 6, hy, "K")
            db.line(hx + 2, hy - 2, hx + 6, hy - 1, "O3")
        else:
            db.line(hx + 1, hy - 3, hx + 6, hy - 2, "O3")  # brow ridge
            db.rect(hx + 2, hy - 1, 4, 2, "Y1")
            db.pset(hx + 2, hy - 1, "Y3")
            db.pset(hx + 4, hy, "K")
            db.pset(hx + 4, hy - 1, "Y0")

        # Deep Crimson Wound & Embedded Iron-Bound Church Ballista Quarrel
        wx, wy = 45, 39 + rb
        db.ellipse(wx, wy, 3.4, 2.3, "DO")
        db.ellipse(wx, wy, 2.6, 1.8, "BLD")
        db.pset(wx + 1, wy, "BLD2")
        db.line(wx - 1, wy + 2, wx + 1, wy + 5, "BLD")  # blood trickle down scale seam
        db.line(wx, wy - 1, wx - 11, wy - 18, "T0")
        db.line(wx + 1, wy - 1, wx - 10, wy - 18, "T2")
        db.pset(wx - 1, wy - 2, "C3")  # iron socket collar
        db.pset(wx, wy - 3, "C4")
        db.line(wx - 9, wy - 16, wx - 13, wy - 21, "I0")
        db.rect(wx - 13, wy - 21, 5, 4, "I0")
        db.line(wx - 12, wy - 20, wx - 9, wy - 17, "I1")
        db.pset(wx - 11, wy - 20, "Y1")

        db.add_outline("DO", selective_hue=True)
        return db

    # 3. Dying Unseen Black-Scaled Dragon (112x84 -> 224x168, 2 gentle breath frames)
    for frame in (0, 1):
        db = _build_fallen_black_dragon("dying", breath=1 if frame == 1 else 0)
        db.save_png(os.path.join(sprites_dir, f"dragon_black_dying_{frame}.png"))
        if frame == 0:
            db.save_png(os.path.join(sprites_dir, "dragon_black_dying.png"))

    # 4. Wild Yellow Reaper Middleweight (80x64, 2 swept wing-beat frames)
    for frame in (0, 1):
        dr = PixelCanvas(80, 64)
        _draw_swept_wing(
            dr, cx=40, sh_dx=6, sh_y=36, armpit_y=23 if frame == 0 else 21,
            elbow_i=11, wr_y=40 if frame == 0 else 37, span=30, tip_y=25 if frame == 0 else 19,
            colors={"hi": "BL2", "mid": "Y1", "rim": "BL1", "pat": "Y0", "pat_mod": 8, "bone": "Y2", "bone_shad": "BL1", "rib": "BL2", "claw": "C4"},
        )
        for ty in range(6, 22):
            tx = 40 + int(math.sin(ty * 0.4) * 3)
            dr.rect(tx - 2, ty, 4, 1, "BL1")
            dr.pset(tx, ty, "Y2")
        dr.ellipse(40, 29, 8.5, 11.5, "BL0")
        dr.ellipse(40, 29, 7.0, 9.8, "BL1")
        dr.ellipse(40, 28, 4.5, 7.5, "BL2")
        dr.ellipse(40, 44, 4.5, 4.5, "BL1")
        dr.ellipse(40, 51, 6.2, 5.5, "BL0")
        dr.ellipse(40, 51, 5.0, 4.2, "BL2")
        dr.line(36, 47, 32, 42, "C3")
        dr.line(44, 47, 48, 42, "C3")
        dr.rect(36, 52, 2, 2, "I1")
        dr.rect(42, 52, 2, 2, "I1")
        dr.add_outline("DK", selective_hue=True)
        dr.save_png(os.path.join(sprites_dir, f"dragon_reaper_{frame}.png"))
        if frame == 0:
            dr.save_png(os.path.join(sprites_dir, "dragon_reaper.png"))

    # 5. Wild Longwing Acid-Breather (84x68, 2 swept wing-beat frames: rose-crimson & amber plumage)
    for frame in (0, 1):
        dl = PixelCanvas(84, 68)
        _draw_swept_wing(
            dl, cx=42, sh_dx=6, sh_y=38, armpit_y=24 if frame == 0 else 22,
            elbow_i=12, wr_y=42 if frame == 0 else 39, span=32, tip_y=25 if frame == 0 else 19,
            colors={"hi": "R4", "mid": "R3", "rim": "D1", "pat": "D1", "pat_mod": 9, "bone": "R4", "outer_bone": "Y2", "bone_shad": "D0", "rib": "Y2", "claw": "C4"},
        )
        for ty in range(6, 23):
            tx = 42 + int(math.sin(ty * 0.38) * 3)
            dl.rect(tx - 2, ty, 4, 1, "D1")
            dl.pset(tx, ty, "Y2")
        dl.ellipse(42, 31, 8.5, 11.8, "D0")
        dl.ellipse(42, 31, 7.0, 10.0, "D1")
        dl.ellipse(42, 30, 4.8, 7.8, "R3")
        dl.ellipse(42, 46, 4.5, 4.6, "D1")
        dl.ellipse(42, 53, 6.2, 5.8, "D0")
        dl.ellipse(42, 53, 5.0, 4.5, "R3")
        dl.line(37, 48, 32, 43, "Y2")
        dl.line(47, 48, 52, 43, "Y2")
        dl.rect(38, 54, 2, 2, "E2")
        dl.rect(44, 54, 2, 2, "E2")
        dl.add_outline("DR", selective_hue=True)
        dl.save_png(os.path.join(sprites_dir, f"dragon_longwing_{frame}.png"))
        if frame == 0:
            dl.save_png(os.path.join(sprites_dir, "dragon_longwing.png"))

    # 6. Black-Scaled Dragon Variants: Wing-Lift Reveal, Breath Blast & Dead Stillness (112x84 -> 224x168)
    for variant in ("reveal", "dead"):
        dv = _build_fallen_black_dragon(variant, breath=0)
        dv.save_png(os.path.join(sprites_dir, f"dragon_black_{variant}.png"))
    for frame in (0, 1):
        dbr = _build_fallen_black_dragon("breath", breath=frame)
        dbr.save_png(os.path.join(sprites_dir, f"dragon_black_breath_{frame}.png"))

    # 8. Flying Wild Black-Scaled Dragon for Sky Attack Cutscene (96x72, 2 swept wing frames)
    for frame in (0, 1):
        dbf = PixelCanvas(96, 72)
        _draw_swept_wing(
            dbf, cx=48, sh_dx=7, sh_y=40, armpit_y=25 if frame == 0 else 22,
            elbow_i=14, wr_y=45 if frame == 0 else 41, span=38, tip_y=27 if frame == 0 else 20,
            colors={"hi": "O2", "mid": "O1", "rim": "O0", "pat": "CS2", "pat_mod": 9, "bone": "O3", "bone_shad": "O0", "rib": "O2", "claw": "C4"},
        )
        # Whipping armored tail
        for ty in range(6, 26):
            tx = 48 + int(math.sin(ty * 0.35 + frame) * 4)
            dbf.rect(tx - 2, ty, 4, 1, "O1")
            dbf.pset(tx, ty, "O3")
        # Heavy obsidian fuselage & dipping horned head
        dbf.ellipse(48, 33, 9.5, 13.0, "O0")
        dbf.ellipse(48, 33, 7.8, 11.2, "O1")
        dbf.ellipse(48, 31, 5.2, 8.5, "O2")
        dbf.ellipse(48, 49, 5.0, 5.0, "O1")
        dbf.ellipse(48, 56, 7.0, 6.2, "O0")
        dbf.ellipse(48, 56, 5.5, 4.8, "O2")
        dbf.line(43, 51, 38, 46, "C3")
        dbf.line(53, 51, 58, 46, "C3")
        dbf.rect(44, 57, 2, 2, "Y2")
        dbf.rect(50, 57, 2, 2, "Y2")
        # Wounded quarrel sticking from left flank (from earlier Hunter ambush)
        dbf.ellipse(40, 32, 3, 2, "BLD")
        dbf.line(39, 31, 31, 20, "T2")
        dbf.rect(29, 17, 4, 4, "I1")
        dbf.add_outline("DO", selective_hue=True)
        dbf.save_png(os.path.join(sprites_dir, f"dragon_black_fly_{frame}.png"))

    # 9. Coal-Black Obsidian Hatchling (32x32, 2 wing-flutter frames)
    for frame in (0, 1):
        dh = PixelCanvas(32, 32)
        dh.ellipse(16, 26, 7, 3, (18, 18, 22, 95))
        lift = -2 if frame == 1 else 0
        # Stubby little bat wings
        for side in (-1, 1):
            wx0 = 16 + side * 4
            wx1 = 16 + side * 12
            step = 1 if side > 0 else -1
            for wx in range(wx0, wx1 + step, step):
                dist = abs(wx - wx0)
                top_y = 14 + dist // 3 + lift
                bot_y = 21 - dist // 3 + lift
                for wy in range(top_y, bot_y):
                    dh.pset(wx, wy, "O2" if wy == top_y else "O1")
            dh.line(wx0, 14 + lift, wx1, 16 + lift, "O3")
        # Curled small tail
        dh.line(15, 22, 10, 25, "O1")
        dh.line(10, 25, 8, 23, "O2")
        # Plump round black hatchling belly & chest
        dh.ellipse(16, 19, 4.8, 5.2, "O0")
        dh.ellipse(16, 19, 3.6, 4.0, "O1")
        dh.ellipse(16, 18, 2.2, 2.5, "O2")
        # Large expressive hatchling head + stub horns + glowing amber eyes
        dh.ellipse(16, 12, 5.0, 4.5, "O0")
        dh.ellipse(16, 12, 4.0, 3.6, "O1")
        dh.ellipse(16, 11, 2.8, 2.2, "O2")
        dh.line(13, 8, 11, 5, "C3")
        dh.line(19, 8, 21, 5, "C3")
        dh.rect(13, 12, 2, 2, "Y2")
        dh.rect(17, 12, 2, 2, "Y2")
        dh.pset(13, 12, "Y3")
        dh.pset(17, 12, "Y3")
        dh.add_outline("DO", selective_hue=True)
        dh.save_png(os.path.join(sprites_dir, f"dragon_black_hatchling_{frame}.png"))

    # 10. Stage 1 Golden Prophecy Hatchling (24x22, 3 dirs x 2 flutter/step frames)
    # Cat-sized soot-obsidian newborn dragonet with cracking molten-gold seams beneath.
    for frame in (0, 1):
        lift = -2 if frame == 1 else 0
        stride = 1 if frame == 1 else -1

        # DOWN (facing viewer, 3/4 top-down)
        hd = PixelCanvas(24, 22)
        hd.ellipse(12, 18, 5.5, 2.2, (12, 14, 18, 95))
        # Whipping curled tail peeking behind right hip
        hd.line(15, 16, 19 + frame, 18, "O0")
        hd.line(15, 15, 19 + frame, 17, "O2")
        hd.pset(20 if frame == 1 else 19, 17, "Y2")
        # Fluttering soot wings with glowing gold wing-joint bone
        for side in (-1, 1):
            for i in range(1, 7):
                wx = 12 + side * (3 + i)
                top_y = 8 + lift + (i // 3)
                bot_y = 14 + lift - (i // 3)
                for wy in range(top_y, bot_y + 1):
                    col = "O0" if wy == bot_y else ("O1" if i < 5 else "O2")
                    hd.pset(wx, wy, col)
            # Leading gold-seamed spar & tiny claw spark
            hd.line(12 + side * 4, 9 + lift, 12 + side * 8, 9 + lift, "Y1")
            hd.pset(12 + side * 4, 8 + lift, "Y2")
            hd.pset(12 + side * 9, 9 + lift, "C4")
        # Plump dragonet torso & stepping fore/hind paws
        hd.ellipse(12, 14, 4.2, 4.4, "O0")
        hd.ellipse(12, 14, 3.3, 3.5, "O1")
        hd.ellipse(12, 13, 2.2, 2.2, "O2")
        # Molten gold scale-cracks showing on chest & ribs
        hd.line(11, 13, 11, 16, "Y1")
        hd.pset(12, 13, "Y2")
        hd.pset(12, 15, "Y3")
        hd.pset(10, 14, "Y1")
        hd.pset(14, 14, "Y1")
        hd.rect(8, 17 + (0 if frame == 0 else -1), 2, 2, "O2")
        hd.rect(14, 17 + (-1 if frame == 0 else 0), 2, 2, "O2")
        # Expressive soot-black head, stub horns, bright amber eyes
        hd.ellipse(12, 8, 4.4, 3.8, "O0")
        hd.ellipse(12, 8, 3.5, 3.0, "O1")
        hd.ellipse(12, 7, 2.4, 1.8, "O2")
        hd.line(9, 4, 8, 2, "C3")
        hd.line(15, 4, 16, 2, "C3")
        hd.pset(12, 5, "Y2")  # forehead gold diamond seam
        hd.pset(12, 6, "Y1")
        for ex in (9, 14):
            hd.rect(ex, 8, 2, 2, "Y2")
            hd.pset(ex, 8, "Y3")
        hd.rect(11, 10, 2, 1, "O3")
        hd.add_outline("DO", selective_hue=True)
        hd.save_png(os.path.join(sprites_dir, f"dragon_gold_s1_down_{frame}.png"))

        # UP (facing away, golden dorsal ridge & animated tail)
        hu = PixelCanvas(24, 22)
        hu.ellipse(12, 18, 5.5, 2.2, (12, 14, 18, 95))
        for side in (-1, 1):
            for i in range(1, 7):
                wx = 12 + side * (3 + i)
                top_y = 7 + lift + (i // 3)
                bot_y = 13 + lift - (i // 3)
                for wy in range(top_y, bot_y + 1):
                    hu.pset(wx, wy, "O2" if wy == top_y else "O1")
            hu.line(12 + side * 4, 8 + lift, 12 + side * 8, 8 + lift, "Y1")
            hu.pset(12 + side * 9, 8 + lift, "C4")
        # Back torso + glowing shedding dorsal spine
        hu.ellipse(12, 12, 4.0, 4.4, "O0")
        hu.ellipse(12, 12, 3.0, 3.5, "O1")
        hu.line(12, 9, 12, 16, "Y1")
        hu.pset(12, 10, "Y3")
        hu.pset(12, 13, "Y2")
        hu.pset(12, 15, "Y3")
        # Curving agile tail towards camera
        t_dx = -1 if frame == 0 else 1
        hu.line(12, 16, 12 + t_dx, 19, "O1")
        hu.line(12 + t_dx, 19, 13 + t_dx * 2, 20, "Y1")
        hu.pset(13 + t_dx * 2, 20, "Y2")
        # Crown back & swept horns
        hu.ellipse(12, 7, 3.8, 3.2, "O0")
        hu.ellipse(12, 7, 2.8, 2.4, "O1")
        hu.line(9, 4, 8, 2, "C3")
        hu.line(15, 4, 16, 2, "C3")
        hu.pset(12, 5, "Y2")
        hu.add_outline("DO", selective_hue=True)
        hu.save_png(os.path.join(sprites_dir, f"dragon_gold_s1_up_{frame}.png"))

        # SIDE (facing RIGHT cleanly for flip_h left/right mirroring)
        hs = PixelCanvas(24, 22)
        hs.ellipse(12, 18, 6.2, 2.2, (12, 14, 18, 95))
        # Whip tail streaming left with gold tip spark
        tail_y = 14 if frame == 0 else 12
        hs.line(8, 14, 4, tail_y, "O1")
        hs.line(4, tail_y, 2, tail_y + (1 if frame == 0 else -1), "O2")
        hs.pset(2, tail_y + (1 if frame == 0 else -1), "Y2")
        # Hind & fore stepping legs
        hs.rect(8 - stride, 16, 2, 3, "O1")
        hs.rect(14 + stride, 16, 2, 3, "O2")
        hs.pset(9 - stride, 18, "C3")
        hs.pset(15 + stride, 18, "C3")
        # Plump dragonet fuselage with flank gold seams peeking beneath obsidian
        hs.ellipse(11, 13, 4.8, 3.5, "O0")
        hs.ellipse(11, 13, 3.8, 2.6, "O1")
        hs.ellipse(11, 12, 2.6, 1.6, "O2")
        hs.pset(10, 12, "Y2")
        hs.pset(11, 13, "Y3")
        hs.pset(13, 13, "Y1")
        # Upper fluttering wing arching back-up
        wing_lift = -2 if frame == 1 else 0
        for i in range(7):
            wx = 11 - i
            top_y = 6 + wing_lift + i // 3
            bot_y = 11 + wing_lift - i // 4
            for wy in range(top_y, bot_y + 1):
                hs.pset(wx, wy, "O2" if wy == top_y else ("O1" if (wx + wy) % 3 else "O0"))
        hs.line(12, 9 + wing_lift, 6, 6 + wing_lift, "Y1")
        hs.pset(6, 6 + wing_lift, "Y2")
        # Alert head & tapered muzzle facing right
        hs.ellipse(16, 9, 3.6, 3.2, "O0")
        hs.ellipse(16, 9, 2.8, 2.4, "O1")
        hs.rect(18, 8, 4, 3, "O1")
        hs.line(18, 8, 21, 8, "O2")
        hs.pset(21, 9, "Y1")      # tiny nostril glint
        hs.line(15, 6, 13, 3, "C3") # swept ear-horn
        hs.pset(15, 6, "Y2")
        hs.rect(17, 8, 2, 2, "Y2")
        hs.pset(17, 8, "Y3")
        hs.add_outline("DO", selective_hue=True)
        hs.save_png(os.path.join(sprites_dir, f"dragon_gold_s1_side_{frame}.png"))

        # DIAGONAL DOWN-RIGHT (3/4 front-right cute walking dragonet; flip_h mirrors left)
        hdd = PixelCanvas(24, 22)
        hdd.ellipse(12, 18, 5.8, 2.2, (12, 14, 18, 95))
        # Whip tail curving away up-left with gold tip glint
        tail_dy = 1 if frame == 0 else -1
        hdd.line(9, 15, 5, 13 + tail_dy, "O0")
        hdd.line(5, 13 + tail_dy, 3, 10 + tail_dy, "O2")
        hdd.pset(3, 10 + tail_dy, "Y2")
        # Far-left raised wing + near-left tucked wing with gold spar
        for side_w, (wx_off, wy_off, span) in ((-1, (-4, 0, 5)), (1, (4, 1, 4))):
            for i in range(span):
                wx = 11 + side_w * (3 + i)
                top_y = 7 + lift + wy_off + i // 3
                bot_y = 13 + lift + wy_off - i // 3
                for wy in range(top_y, bot_y + 1):
                    hdd.pset(wx, wy, "O0" if wy == bot_y else ("O1" if i < span - 1 else "O2"))
            hdd.line(11 + side_w * 3, 8 + lift + wy_off, 11 + side_w * (2 + span), 8 + lift + wy_off, "Y1")
            hdd.pset(11 + side_w * (2 + span), 8 + lift + wy_off, "C4")
        # Plump chest angled down-right + alternating stepping paws
        hdd.ellipse(12, 14, 4.4, 3.8, "O0")
        hdd.ellipse(12, 14, 3.4, 2.9, "O1")
        hdd.pset(12, 13, "Y2")
        hdd.pset(13, 14, "Y3")
        hdd.pset(13, 16, "Y1")
        hdd.rect(9 - stride, 16, 2, 3, "O1")
        hdd.rect(14 + stride, 16, 2, 3, "O2")
        # 3/4 cute rounded head, tiny muzzle toward bottom-right, both bright eyes visible
        hdd.ellipse(14, 9, 4.2, 3.5, "O0")
        hdd.ellipse(14, 9, 3.3, 2.7, "O1")
        hdd.ellipse(14, 8, 2.1, 1.6, "O2")
        hdd.line(11, 5, 9, 3, "C3")
        hdd.line(15, 5, 16, 3, "C3")
        hdd.pset(14, 6, "Y2")
        hdd.rect(16, 9, 3, 2, "O1")
        hdd.pset(18, 10, "Y1")
        hdd.rect(12, 8, 2, 2, "Y2")
        hdd.pset(12, 8, "Y3")
        hdd.rect(15, 8, 2, 2, "Y2")
        hdd.pset(15, 8, "Y3")
        hdd.add_outline("DO", selective_hue=True)
        hdd.save_png(os.path.join(sprites_dir, f"dragon_gold_s1_diag_down_{frame}.png"))

        # DIAGONAL UP-RIGHT (3/4 back-right cute walking dragonet; flip_h mirrors left)
        hdu = PixelCanvas(24, 22)
        hdu.ellipse(12, 18, 5.6, 2.2, (12, 14, 18, 95))
        # Stepped legs
        hdu.rect(9 - stride, 16, 2, 3, "O1")
        hdu.rect(14 + stride, 16, 2, 3, "O2")
        # Fluttering back wings across diagonal shoulders
        for i in range(6):
            wx = 10 - i
            top_y = 6 + lift + i // 3
            bot_y = 12 + lift - i // 3
            for wy in range(top_y, bot_y + 1):
                hdu.pset(wx, wy, "O2" if wy == top_y else "O1")
        hdu.line(10, 7 + lift, 5, 7 + lift, "Y1")
        hdu.pset(5, 7 + lift, "C4")
        # 3/4 back torso + glowing shedding dorsal spine seams
        hdu.ellipse(12, 13, 4.2, 4.0, "O0")
        hdu.ellipse(12, 13, 3.2, 3.1, "O1")
        hdu.line(11, 10, 12, 16, "Y1")
        hdu.pset(11, 11, "Y3")
        hdu.pset(12, 14, "Y2")
        # Curving agile tail trailing bottom-left with gold tip spark
        t_off = -1 if frame == 0 else 1
        hdu.line(10, 16, 6, 18 + t_off, "O1")
        hdu.line(6, 18 + t_off, 4, 19 + t_off, "Y1")
        hdu.pset(4, 19 + t_off, "Y2")
        # Crown & swept horns + small profile cheek eye glint on right
        hdu.ellipse(14, 8, 3.8, 3.2, "O0")
        hdu.ellipse(14, 8, 2.8, 2.4, "O1")
        hdu.line(11, 5, 9, 2, "C3")
        hdu.line(15, 5, 16, 2, "C3")
        hdu.pset(13, 6, "Y2")
        hdu.pset(17, 8, "Y3")
        hdu.add_outline("DO", selective_hue=True)
        hdu.save_png(os.path.join(sprites_dir, f"dragon_gold_s1_diag_up_{frame}.png"))


