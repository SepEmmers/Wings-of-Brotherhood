"""
Shared palette legend helpers, ASCII-grid rasterizer, and grounding assertions
for 24x28 character sprites.
"""

from pixel_art_lib import PixelCanvas

STD_LEGEND = {
    ".": None,
    "h": "B0", "H": "B1", "r": "B2",
    "s": "P1", "S": "P2", "f": "P3", "p": "PK",
    "z": "P0",
    "e": "K",  "w": "EW",
    "d": "U0", "m": "U1", "l": "U2",
    "a": "L2", "A": "L1", "q": "L0",
    "t": "T0", "T": "T1", "u": "T2",
    "g": "Y0", "G": "Y2",
    "b": "T0", "B": "T1",
    "k": "S",  "K": "K",
    "x": "R1", "X": "R2",
}


def _build_canvas_from_ascii(lines: list[str], legend: dict, outline_col="K") -> PixelCanvas:
    assert len(lines) == 28, f"Expected 28 rows, got {len(lines)}"
    c = PixelCanvas(24, 28)
    for y, line in enumerate(lines):
        assert len(line) == 24, f"Row {y} len {len(line)} != 24: {line}"
        for x, ch in enumerate(line):
            key = legend.get(ch)
            if key is not None:
                c.pset(x, y, key)
    c.add_outline(outline_col, selective_hue=True)
    return c



def _assert_grounded(name: str, grid: list[str], expected_row: int = 24) -> None:
    if any(ch != "." for ch in grid[expected_row]) and all(ch == "." for ch in grid[expected_row + 1]):
        return
    raise AssertionError(f"Sprite '{name}' is NOT grounded cleanly at row {expected_row}!")

