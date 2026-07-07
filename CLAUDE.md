# OpenSCAD_case

Parametric case/box/enclosure library in plain OpenSCAD (no external libraries — must load in
[OpenSCAD-gui](../OpenSCAD-gui), a custom JS-based OpenSCAD engine that does **not** support
BOSL2 or other `use`/`include` third-party libs beyond its drag-drop `.scad` file provider).

## Constraint: no BOSL2

Unlike other OpenSCAD projects in this workspace, do **not** `include <BOSL2/std.scad>` here.
OpenSCAD-gui resolves `include`/`use` only against files dropped into its own file provider,
keyed by lowercased basename — it has no bundled library set. Every module in this repo must be
self-contained vanilla OpenSCAD so it renders identically in real OpenSCAD and in OpenSCAD-gui.

## Reusing the hinge library

Box lids need hinges — don't reinvent them here. `../OpenSCAD_hinge/hinge_library.scad` already
has parametric, vanilla-OpenSCAD hinge modules (`knuckle_hinge`, `piano_hinge`, `living_hinge`,
`door_butt_hinge`, `snap_lid_hinge`). Reference it directly:

```openscad
include <../OpenSCAD_hinge/hinge_library.scad>
include <case_library.scad>

// position a hinge along the lid seam of a case module, e.g.:
translate([box_length/2 - 20, box_width, box_wall_h])
    rotate([90,0,0])
        piano_hinge(length=box_length - 40, leaf_width=10, leaf_thickness=box_wall_t);
```

If a case needs a hinge variant that doesn't exist yet, add it to
`../OpenSCAD_hinge/hinge_library.scad` (with its own demo/render/schematic per that project's
CLAUDE.md) rather than defining a one-off hinge module inside this repo. Keep hinge geometry
and case geometry in separate libraries so both stay independently reusable and loadable by
OpenSCAD-gui.

## Layout

- `case_library.scad` — main library, one module per case/box type, all vanilla OpenSCAD.
- `examples/` — one demo file per case type, `include`s the library (and the hinge library
  where a lid needs one) and instantiates it with sane defaults for preview.
- `renders/` — PNG preview per case type, regenerate with:
  `openscad -o renders/<name>.png --imgsize=800,600 examples/<name>_demo.scad`

## Conventions

- All modules parameterised: outer/inner dimensions, wall thickness, corner radius, lid type
  (snap-fit / hinged / screw-down), mounting hole layout, `$fn` passed through, no hardcoded
  constants.
- Origin/orientation: box sits centered on the XY origin, base at Z=0, lid opens away from the
  hinge edge (+Y by convention) so hinge modules from `OpenSCAD_hinge` drop straight onto the
  lid seam without re-deriving orientation.
- Units: mm.

## Workflow

- Add new case type: new module in `case_library.scad` + matching `examples/<name>_demo.scad`
  + rendered PNG in `renders/` + row in the README table.
- Test load path: this repo must also open standalone in real OpenSCAD (`openscad
  examples/<name>_demo.scad`) as a regression check against the OpenSCAD-gui engine.
