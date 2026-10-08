"""Measure the per-layout `remap` knots for nodes.script.lua.

The layout tiles in tex/layouts.tga are plain geometric ramps. This finds, for
each tile, the ramp values at which the hills end, the rolling land gives way
to the flat plain, and the sea starts, so that by area each band makes up
about its share of the map.
There are no mountains: the far end of the map is a strip of hills. Paste the
printed `remap` lines into LAYOUTS in nodes.script.lua.
"""
import os

from PIL import Image

TEX = os.path.join(os.path.dirname(__file__), "..", "mod", "glcrte_mapzilla_balanced_1",
                   "content", "mapzilla_balanced", "tex", "layouts.tga")
KEYS = ["shore", "island", "inland_sea", "isthmus", "strait", "peninsula", "bay"]
TILE = 256
MARGIN = 0.1         # LAYOUT_MARGIN in nodes.script.lua
HILLS = 0.22         # hills share at the far end, unless the tile forces more
SEA = 0.10           # sea share, unless the tile forces more
ROLLING = 0.62       # of the lowland between them, the rolling part; the rest is flat


def main():
    px = Image.open(TEX).load()
    lo = int(round(TILE * MARGIN / (1 + 2 * MARGIN)))
    hi = TILE - lo
    for t, key in enumerate(KEYS):
        vals = sorted(px[t * TILE + x, y] / 255 for y in range(lo, hi) for x in range(lo, hi))
        n = len(vals)

        def q(f):
            return vals[min(n - 1, max(0, int(f * n)))]

        # A share already held at one single value (0 or 1) cannot be bent away.
        at0 = sum(v == 0 for v in vals) / n
        at1 = sum(v == 1 for v in vals) / n
        hills = max(HILLS, at0 + 0.02)
        sea = max(SEA, at1 + 0.02)
        rolling = hills + (1 - hills - sea) * ROLLING
        print(f"{key:11s} hills {hills:.3f} sea {sea:.3f}  "
              f"remap = {{ {q(hills):.3f}, {q(rolling):.3f}, {q(1 - sea):.3f} }}")


if __name__ == "__main__":
    main()
