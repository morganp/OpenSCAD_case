# todo

## Done 2026-07-09 — hinged_box redesign (two-tray, pinned hinges)

Review found the old flat-fold design unprintable at all (the open-pose lid panel floated at
`z = height - wall` with nothing beneath it), on top of the fold-geometry bugs listed on
2026-07-07. Rebuilt as two trays (body + lid) with pinned hinges fused across the back seam:

- [x] Default hinge now robust: `hinge_type="piano"` knuckle hinge, 1.75mm filament pin.
- [x] Hinge selectable: `"piano"` / `"knuckle"` (discrete, `hinge_count`) / `"crate"`.
- [x] Crate hinge supported for the rugged look; printed 4mm pins emitted beside the parts.
- [x] Rugged box variation: `ribs` / `rib_w` / `rib_depth` params (front wall + over lid top).
- [x] `pose="closed"` assembled preview (would have caught the old fold bugs).
- [x] Alignment lip + front snap latch (ridge on lip, groove inside lid wall), chamfered
      cam faces, correct engagement depths.
- [x] Separate lid depth (`lid_depth`) — the obloid two-tray model.
- [x] Hinge count 1/2/3 via `hinge_count` (knuckle/crate).
- [x] `echo()` print-dimension + pin readout.
- [x] Lid text on the outer top face (was on the inner face in the old design).
- [x] Box now centered on the XY origin per repo conventions (was corner-at-origin).
- [x] Living-hinge variant dropped: with a top-edge fold axis the open lid can never rest on
      the bed unless body and lid depths are equal, so the old print-in-place promise was
      geometrically false. All 2026-07-07 fold-bug items are moot with the redesign.
- [x] Hinge library: `parts="leaf1"/"leaf2"` on knuckle/piano/crate hinges (+ README rows),
      `screws_per_leaf=0` guard on crate_hinge.

## Open

- [ ] Print-in-place clamshell variant (equal-depth halves hinged at the top rim — the only
      layout where a fold-flat living hinge is actually printable); needs a
      webs-on-one-side option (`groove_side`) in `living_hinge`.
- [ ] Diagonal dividers: none / single diagonal / diagonal X.
- [ ] Opener tabs (thumb notch), count auto/1/2.
- [ ] Multi-color 3MF: box / lid / text colors (`color()` exports to 3MF in recent
      OpenSCAD); "color text flush" variant in addition to deboss/emboss.
- [ ] Rough weight estimate in the `echo()` readout.
- [ ] Draw-latch / toggle-clasp option for the rugged box (snap lip is the only latch now).
- [ ] Optional side ribs + back ribs that dodge the hinge strap positions.
- [ ] Lip top-edge lead-in chamfer for easier closing.
- [ ] Verify OpenSCAD-gui loads the new files (list comprehensions, `parts` param).
