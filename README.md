# OpenSCAD_case

Parametric case/box library, plain OpenSCAD, for Bambu/Orca-ready print-in-place boxes.
Loadable standalone in real OpenSCAD and by [OpenSCAD-gui](../OpenSCAD-gui).

## hinged_box — print-in-place hinged, snap-fit box

Inspired by the class of tool at [obloid.app/tools/hinged-box](https://obloid.app/tools/hinged-box):
adjustable size/depth, dividers, rounded corners, lid text, prints as one piece (box + living
hinge + lid), fold closed by hand after printing, snaps shut on a latch opposite the hinge.
This is an independent implementation built to that feature set, not a copy of that site's code.

![hinged_box render](renders/hinged_box.png)

**[▶ Open in SCAD Studio](https://lizard-spock.co.uk/openscad-gui/?github=morganp/OpenSCAD_case/examples/hinged_box_demo.scad)** —
view this example in the browser, no install; the library (and its hinge dependency) load automatically.

```openscad
include <case_library.scad>

hinged_box(
    length = 120, width = 80, height = 40,
    div_x = 2, div_y = 1,
    lid_text = "TOOLS"
);
```

### How it prints and folds

Printed **flat/open**: the box sits normally (open top up), a thin `living_hinge` strip bridges
its back top edge to a flat lid panel that extends further out in +Y, lid skirt walls point
*up* while flat. After printing, fold the lid ~180° over the hinge — the geometry is arranged so
the skirt walls end up wrapping down around the box's outer walls, and a latch ridge on the
box's front wall (opposite the hinge) snaps into a matching groove on the lid's front skirt.

Print settings (slicer profile, not module parameters): **0.2mm layer height, 3–4 walls, PLA or
PETG** — PETG holds up to repeated hinge flexing better than PLA.

| Parameter | Default | Meaning |
|---|---|---|
| `length` | 120 | Box outer footprint, X |
| `width` | 80 | Box outer footprint, Y (excludes the hinge/lid extension) |
| `height` | 40 | Box outer height, Z |
| `wall` | 2.4 | Wall thickness |
| `corner_r` | 6 | Outer corner rounding radius |
| `div_x` | 0 | Internal dividers splitting `length` (walls run along Y) |
| `div_y` | 0 | Internal dividers splitting `width` (walls run along X) |
| `div_thickness` | 1.6 | Divider wall thickness |
| `hinge_depth` | 10 | Y-span of the living-hinge strip (fold direction) |
| `hinge_margin` | 8 | Hinge inset from each end along X |
| `hinge_web` | 0.6 | Living-hinge web thickness (flex layer) |
| `hinge_grooves` | 3 | Living-hinge relief groove count |
| `lid_len` | 0 (auto) | Y-span of the lid panel in the open/print pose |
| `lid_rim` | 6 | Depth of the lid's downturned skirt |
| `lid_clearance` | 0.3 | Radial clearance between skirt and box outer wall |
| `latch_w` | 14 | Width of the snap latch, centered on the front wall |
| `latch_bump` | 0.8 | Ridge protrusion / groove depth |
| `lid_text` | "" | Text engraved (or embossed) into the lid |
| `lid_text_size` | 10 | Lid text size |
| `lid_text_depth` | 0.6 | Engrave/emboss depth |
| `lid_text_emboss` | false | true = raised text, false = engraved |
| `fn` | 48 | Circle resolution |

**Snap-fit note:** `lid_clearance` / `latch_bump` are a best-effort starting point, not tuned to
any specific printer or material — check fit on a test print and adjust before relying on the
latch.

**Orientation note:** because the lid folds 180° to close, its *open-pose top face* (facing up
during printing) ends up facing *into* the box once folded — the open-pose *bottom* face becomes
the box's outward-facing lid top. `lid_text` is engraved/embossed on the open-pose top face for
visibility while printing; mirror it yourself if you need it on the outward face instead.

## Regenerating previews

```sh
openscad -o renders/<name>.png --imgsize=1000,700 --autocenter --viewall examples/<name>_demo.scad
```
