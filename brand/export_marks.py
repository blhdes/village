"""Export VILLE's wordmark ("ville.") and app icon ("v.") as outlines of
Source Serif 4 Italic, unchanged: no point is drawn by hand.

Look chosen in the logo study workshop (2026-11-02):
    Source Serif 4 Italic · weight 670 · optical size 33 · tracking -1.5 % ·
    dot 140 % · dot 1 % of its size closer
The icon uses the same weight and dot at optical size 60 (it's drawn large),
at the size and baseline of the first icon export.

Needs:
    Source Serif 4 Italic from Google Fonts, "SourceSerif4-Italic[opsz,wght].ttf"
        (github.com/google/fonts, ofl/sourceserif4; SIL OFL 1.1). Not in the repo.
    fontTools in a virtual environment:  python3 -m venv .venv && .venv/bin/pip install fonttools
    HarfBuzz's hb-shape (brew install harfbuzz): it places the letters as
        browsers do, so spacing and kerning match the study page.

Usage:
    .venv/bin/python -I brand/export_marks.py FONT.ttf OUT_DIR

Then copy:
    OUT_DIR/v.svg, OUT_DIR/dot.svg     -> VILLE/VILLE/AppIcon.icon/Assets/
    OUT_DIR/WordmarkLetters.svg        -> VILLE/VILLE/Assets.xcassets/WordmarkLetters.imageset/
    OUT_DIR/WordmarkDot.svg            -> VILLE/VILLE/Assets.xcassets/WordmarkDot.imageset/
and set the printed canvas size in `VILLEWordmark` (widthInEms, heightInEms).

--check-first-export PATH checks this font against the first icon's "v"
(wght 400, `git show 75810cc:VILLE/VILLE/AppIcon.icon/Assets/v.svg`): it must
match to the hundredth of a unit.
"""

import argparse
import json
import re
import subprocess
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

WEIGHT = 670
WORDMARK_OPSZ = 33
ICON_OPSZ = 60
TRACKING = -0.015  # em, after every letter (CSS letter-spacing)
DOT_SCALE = 1.40
DOT_GAP = -0.01  # in the dot's own em, before it (CSS margin-left)

ICON_CANVAS = 1024
# Font size and baseline of the first icon export (wght 400), found by
# matching its "v" point for point on 2026-11-02.
ICON_FONT_SIZE = 962.747
ICON_BASELINE = 731.499

WORDMARK_EM = 1000.0  # the wordmark's canvas units per em


def ntos(number: float) -> str:
    return f"{number:.2f}"


def dimension(number: float) -> str:
    return str(int(number)) if float(number).is_integer() else ntos(number)


class ExplicitLinePen(SVGPathPen):
    """Writes every straight segment as "L x y" (never H, V or an implicit
    lineto), the format of the first icon export."""

    def _lineTo(self, pt):
        if pt == (self._lastX, self._lastY):
            return
        self._commands.append("L" + " ".join(self._ntos(n) for n in pt))
        self._lastCommand = "L"
        self._lastX, self._lastY = pt


class Font:
    """One instance of the variable font: outlines plus HarfBuzz positions."""

    def __init__(self, path: Path, wght: float, opsz: float):
        self.path = path
        self.variations = {"wght": wght, "opsz": opsz}
        self.ttfont = instancer.instantiateVariableFont(TTFont(path), self.variations)
        self.glyphs = self.ttfont.getGlyphSet()
        self.upem = self.ttfont["head"].unitsPerEm

    def shape(self, text: str) -> list[dict]:
        """Glyphs and positions in font units, as a browser lays them out
        (optional ligatures off, as CSS does when letter-spacing isn't 0).
        Glyph ids, mapped to fontTools' names: the file may carry no names."""
        variations = ",".join(f"{axis}={value}" for axis, value in self.variations.items())
        result = subprocess.run(
            [
                "hb-shape", f"--variations={variations}", "--output-format=json",
                "--no-glyph-names", "--features=-liga,-clig,-dlig", str(self.path), text,
            ],
            capture_output=True, text=True, check=True,
        )
        items = json.loads(result.stdout)
        order = self.ttfont.getGlyphOrder()
        for item in items:
            item["g"] = order[item["g"]]
        return items


def outline(font: Font, glyph: str, transform: tuple) -> tuple[str, tuple]:
    """SVG path data and bounds of one glyph under an affine transform."""
    path_pen = ExplicitLinePen(font.glyphs, ntos=ntos)
    bounds_pen = BoundsPen(font.glyphs)
    font.glyphs[glyph].draw(TransformPen(path_pen, transform))
    font.glyphs[glyph].draw(TransformPen(bounds_pen, transform))
    return path_pen.getCommands(), bounds_pen.bounds


def union(boxes):
    return (
        min(b[0] for b in boxes), min(b[1] for b in boxes),
        max(b[2] for b in boxes), max(b[3] for b in boxes),
    )


def svg(width: float, height: float, comment: str, paths: list[str], view_box: str, fill: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{dimension(width)}" height="{dimension(height)}" viewBox="{view_box}">\n'
        f"  <!-- {comment} -->\n"
        f'  <path d="{"".join(paths)}" fill="{fill}"/>\n'
        "</svg>\n"
    )


def layout_mark(font: Font, letters: str, size: float):
    """Letters (each followed by the tracking), then the dot, scaled and
    nudged, on one baseline. Returns [(glyph, x, scale)] at this font size."""
    unit = size / font.upem
    placed = []
    x = 0.0
    for item in font.shape(letters):
        placed.append((item["g"], x + item["dx"] * unit, 1.0))
        x += item["ax"] * unit + TRACKING * size
    x += DOT_GAP * DOT_SCALE * size
    (dot,) = font.shape(".")
    placed.append((dot["g"], x, DOT_SCALE))
    return placed


def draw_placed(font: Font, placed, size: float, origin_x: float, baseline_y: float):
    """Paths and bounds for placed glyphs, y flipped for SVG."""
    unit = size / font.upem
    drawn = []
    for glyph, x, scale in placed:
        s = unit * scale
        drawn.append(outline(font, glyph, (s, 0, 0, -s, origin_x + x, baseline_y)))
    return drawn


def numbers(path_data: str) -> list[float]:
    return [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", path_data)]


def check_first_export(font_path: Path, first_v: Path) -> float:
    """The worst difference between this font's "v" (wght 400) and the
    first export's, both at the first export's size and baseline."""
    font = Font(font_path, 400, ICON_OPSZ)
    first = re.search(r'd="([^"]+)"', first_v.read_text()).group(1)
    (glyph, _, _), _ = layout_mark(font, "v", ICON_FONT_SIZE)
    first_xs = numbers(first)[0::2]
    # Find the horizontal offset from the leftmost point, then compare all.
    probe, _ = outline(font, glyph, (ICON_FONT_SIZE / font.upem, 0, 0, -ICON_FONT_SIZE / font.upem, 0, ICON_BASELINE))
    offset = min(first_xs) - min(numbers(probe)[0::2])
    scale = ICON_FONT_SIZE / font.upem
    path, _ = outline(font, glyph, (scale, 0, 0, -scale, offset, ICON_BASELINE))
    ours, theirs = numbers(path), numbers(first)
    if len(ours) != len(theirs):
        raise SystemExit("The first export's v has a different number of points: another font?")
    return max(abs(a - b) for a, b in zip(ours, theirs))


def export_icon(font_path: Path, out: Path):
    font = Font(font_path, WEIGHT, ICON_OPSZ)
    placed = layout_mark(font, "v", ICON_FONT_SIZE)
    left, top, right, bottom = union([b for _, b in draw_placed(font, placed, ICON_FONT_SIZE, 0, ICON_BASELINE)])
    # Centered both ways on the canvas, as the first export was.
    dx = ICON_CANVAS / 2 - (left + right) / 2
    dy = ICON_CANVAS / 2 - (top + bottom) / 2
    (v_path, v_box), (dot_path, dot_box) = draw_placed(font, placed, ICON_FONT_SIZE, dx, ICON_BASELINE + dy)
    spec = f"Source Serif 4 Italic (SIL OFL 1.1), wght {WEIGHT}, opsz {ICON_OPSZ}"
    view_box = f"0 0 {ICON_CANVAS} {ICON_CANVAS}"
    (out / "v.svg").write_text(svg(
        ICON_CANVAS, ICON_CANVAS, f'"v" from {spec}. Outline exported unchanged (brand/export_marks.py).',
        [v_path], view_box, "#1C1C1E"))
    # The dot's own color is BrandRed's sRGB fallback; the "Red dot" layer
    # in AppIcon.icon/icon.json paints the Display P3 red over it.
    (out / "dot.svg").write_text(svg(
        ICON_CANVAS, ICON_CANVAS, f'"." from {spec}, scaled {DOT_SCALE:.0%} as a whole. Outline otherwise unchanged (brand/export_marks.py).',
        [dot_path], view_box, "#D80017"))
    return union([v_box, dot_box])


def export_wordmark(font_path: Path, out: Path):
    """Two layers on one tight canvas (1 em = 1000 units), so the dot can
    breathe on its own. Returns the canvas size in ems."""
    font = Font(font_path, WEIGHT, WORDMARK_OPSZ)
    placed = layout_mark(font, "ville", WORDMARK_EM)
    left, top, right, bottom = union([b for _, b in draw_placed(font, placed, WORDMARK_EM, 0, 0)])
    drawn = draw_placed(font, placed, WORDMARK_EM, -left, -top)
    width, height = right - left, bottom - top
    spec = (
        f"Source Serif 4 Italic (SIL OFL 1.1), wght {WEIGHT}, opsz {WORDMARK_OPSZ}, "
        f"tracking {TRACKING:+.1%}, placed by HarfBuzz"
    )
    view_box = f"0 0 {ntos(width)} {ntos(height)}"
    natural = 28 / WORDMARK_EM  # natural size: the top bar's 28 pt
    (out / "WordmarkLetters.svg").write_text(svg(
        width * natural, height * natural, f'"ville" from {spec}. Outlines exported unchanged (brand/export_marks.py).',
        [path for path, _ in drawn[:-1]], view_box, "#000000"))
    (out / "WordmarkDot.svg").write_text(svg(
        width * natural, height * natural,
        f'"." from {spec}, scaled {DOT_SCALE:.0%} as a whole and {-DOT_GAP:.0%} of its size closer. Outline otherwise unchanged (brand/export_marks.py).',
        [drawn[-1][0]], view_box, "#000000"))
    return width / WORDMARK_EM, height / WORDMARK_EM


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("font", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--check-first-export", type=Path)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    if args.check_first_export:
        worst = check_first_export(args.font, args.check_first_export)
        if worst > 0.02:
            raise SystemExit(f"This font doesn't match the first icon export (worst point {worst:.3f})")
        print(f"first icon export reproduced (worst point {worst:.3f})")

    left, top, right, bottom = export_icon(args.font, args.out)
    print(f"icon: x {left:.1f} to {right:.1f}, y {top:.1f} to {bottom:.1f} on a {ICON_CANVAS} canvas")

    width_em, height_em = export_wordmark(args.font, args.out)
    print(f"wordmark canvas: widthInEms {width_em:.5f}, heightInEms {height_em:.5f}")


if __name__ == "__main__":
    main()
