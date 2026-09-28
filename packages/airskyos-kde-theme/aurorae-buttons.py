#!/usr/bin/env python3
"""Give Aurorae title-bar buttons a solid round background.

AirSkyOS window decorations are fully transparent (the glass effect draws the
title bar), so the button glyphs disappear on busy or same-coloured content.
This puts a white (light theme) / black (dark theme) disc behind every button
state and makes the glyph the opposite colour.

    aurorae-buttons.py <aurorae theme dir> light|dark
"""
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

SVG_NS = "http://www.w3.org/2000/svg"
BUTTONS = ("close", "maximize", "minimize", "restore",
           "alldesktops", "keepabove", "keepbelow", "shade", "help")

# state -> (disc colour, glyph colour)
PALETTE = {
    "light": {
        "active":      ("#ffffff", "#1c1c1c"),
        "hover":       ("#e9e9e9", "#000000"),
        "pressed":     ("#d2d2d2", "#000000"),
        "inactive":    ("#ffffff", "#6b6b6b"),
        "deactivated": ("#ffffff", "#b4b4b4"),
        "outline":     "rgba(0,0,0,0.18)",
    },
    "dark": {
        "active":      ("#000000", "#f5f5f5"),
        "hover":       ("#262626", "#ffffff"),
        "pressed":     ("#3a3a3a", "#ffffff"),
        "inactive":    ("#000000", "#bdbdbd"),
        "deactivated": ("#000000", "#6e6e6e"),
        "outline":     "rgba(255,255,255,0.22)",
    },
}

# every namespace used by the Inkscape-made button files
for prefix, uri in {
    "": SVG_NS,
    "svg": SVG_NS,
    "dc": "http://purl.org/dc/elements/1.1/",
    "cc": "http://creativecommons.org/ns#",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "sodipodi": "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
    "inkscape": "http://www.inkscape.org/namespaces/inkscape",
    "xlink": "http://www.w3.org/1999/xlink",
}.items():
    ET.register_namespace(prefix, uri)


def q(tag):
    return f"{{{SVG_NS}}}{tag}"


def set_style(el, **props):
    style = el.get("style", "")
    items = dict(p.split(":", 1) for p in style.split(";") if ":" in p)
    for k, v in props.items():
        items[k.replace("_", "-")] = v
    el.set("style", ";".join(f"{k}:{v}" for k, v in items.items()))


def state_of(group_id):
    # "active-center", "hover-center", "hover-inactive-center", ...
    base = group_id[: -len("-center")]
    for state in ("pressed", "hover", "deactivated", "inactive", "active"):
        if base.startswith(state):
            return state
    return "active"


def parent_map(root):
    return {c: p for p in root.iter() for c in p}


def is_hitbox(el):
    return re.search(r"(^|;)opacity:0\.00", el.get("style", "")) is not None


def process(path, pal):
    tree = ET.parse(path)
    root = tree.getroot()
    parents = parent_map(root)
    changed = False
    for g in list(root.iter(q("g"))):
        gid = g.get("id", "")
        if not gid.endswith("-center"):
            continue
        state = state_of(gid)
        disc_colour, glyph = pal[state]
        descendants = [e for e in g.iter() if e is not g]

        # Where is this state's 22x22 cell? The files were drawn by hand and
        # use mixed transforms, so reuse the element that already spans the
        # cell, in its own coordinate system: the old hover/pressed circle,
        # else the invisible 22x22 hit box.
        anchor = next((e for e in descendants if e.tag == q("circle") and float(e.get("r", 0)) >= 10), None)
        if anchor is not None:
            cx, cy, r = float(anchor.get("cx")), float(anchor.get("cy")), float(anchor.get("r"))
        else:
            anchor = next((e for e in descendants if e.tag == q("rect") and not e.get("transform")
                           and float(e.get("width", 0)) >= 20 and float(e.get("height", 0)) >= 20), None)
            if anchor is None:
                continue
            x, y = float(anchor.get("x", 0)), float(anchor.get("y", 0))
            w, h = float(anchor.get("width")), float(anchor.get("height"))
            cx, cy, r = x + w / 2, y + h / 2, min(w, h) / 2

        disc = ET.Element(q("circle"), {
            "id": f"{gid}-airskyos-disc",
            "cx": f"{cx:g}", "cy": f"{cy:g}", "r": f"{r - 0.75:g}",
        })
        set_style(disc, fill=disc_colour, fill_opacity="1", stroke=pal["outline"],
                  stroke_width="0.75", opacity="1")
        parent = parents[anchor]
        idx = list(parent).index(anchor)
        if anchor.tag == q("circle"):
            parent.remove(anchor)          # replace the translucent circle
            parent.insert(idx, disc)
        else:
            parent.insert(idx + 1, disc)   # just above the hit box

        # any other translucent big circles (duplicates) go away
        for e in descendants:
            if e is not anchor and e.tag == q("circle") and float(e.get("r", 0)) >= 10 and e in parents:
                parents[e].remove(e)

        # glyphs: every remaining visible shape
        for e in g.iter():
            if e is disc or e.tag not in (q("path"), q("rect"), q("polygon"), q("ellipse"), q("circle")):
                continue
            if is_hitbox(e):
                continue
            set_style(e, fill=glyph)
            style = e.get("style", "")
            if "stroke:" in style and "stroke:none" not in style:
                set_style(e, stroke=glyph)

        # The original inactive / deactivated states were faded with group
        # opacity; the glyph colour does that now, so the disc stays solid.
        for e in g.iter():
            if e.tag == q("g") and "opacity" in e.get("style", ""):
                set_style(e, opacity="1")
            elif e is not disc and not is_hitbox(e) and re.search(r"(^|;)opacity:0\.[1-9]", e.get("style", "")):
                set_style(e, opacity="1")
        changed = True

    if changed:
        tree.write(path, xml_declaration=True, encoding="UTF-8")
    return changed


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in PALETTE:
        sys.exit(__doc__)
    theme, variant = Path(sys.argv[1]), sys.argv[2]
    for name in BUTTONS:
        f = theme / f"{name}.svg"
        if f.is_file() and process(f, PALETTE[variant]):
            print(f"  {f.name}: {variant} buttons")


if __name__ == "__main__":
    main()
