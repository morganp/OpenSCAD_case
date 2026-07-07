// case_library.scad
// Parametric case/box library — plain OpenSCAD, no external includes (see hinge include below
// for the one exception: it pulls in ../OpenSCAD_hinge/hinge_library.scad, tagged so
// OpenSCAD-gui can auto-fetch it too).
//
// @github: morganp/OpenSCAD_hinge
include <../OpenSCAD_hinge/hinge_library.scad>

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

module _rounded_rect(l, w, r, fn=48) {
    rr = min(r, l/2, w/2);
    hull() {
        for (cx = [rr, l-rr]) for (cy = [rr, w-rr])
            translate([cx, cy]) circle(r=rr, $fn=fn);
    }
}

module _box_shell(length, width, height, wall, corner_r, fn) {
    difference() {
        linear_extrude(height=height) _rounded_rect(length, width, corner_r, fn);
        translate([wall, wall, wall])
            linear_extrude(height=height) // overshoots the top on purpose -> open top
                _rounded_rect(length - 2*wall, width - 2*wall, max(0.1, corner_r - wall), fn);
    }
}

module _dividers(length, width, height, wall, div_x, div_y, div_thickness) {
    inner_l = length - 2*wall;
    inner_w = width  - 2*wall;
    div_h   = height - wall; // stop below the rim so a lid can still seat flush
    if (div_x > 0) {
        step = inner_l / (div_x + 1);
        for (i = [1:div_x])
            translate([wall + step*i - div_thickness/2, wall, wall])
                cube([div_thickness, inner_w, div_h]);
    }
    if (div_y > 0) {
        step = inner_w / (div_y + 1);
        for (i = [1:div_y])
            translate([wall, wall + step*i - div_thickness/2, wall])
                cube([inner_l, div_thickness, div_h]);
    }
}

// ---------------------------------------------------------------------------
// hinged_box — print-in-place hinged, snap-fit box with optional dividers.
//
// Printed flat/open (as generated): box footprint X:[0,length] Y:[0,width], lid hinges off
// the BACK wall (Y=width) via a living_hinge and lays out flat further along +Y. After
// printing, fold the lid ~180° about the hinge to close — it snaps shut against a latch
// ridge on the box's FRONT wall (Y=0), opposite the hinge.
//
// Orientation note: because the lid is printed flat/open and folded 180° to close, its
// OPEN-POSE TOP face (the one facing up during printing) ends up facing INTO the box once
// folded closed; the OPEN-POSE BOTTOM face becomes the box's outward-facing lid top. This
// module engraves/embosses lid_text on the open-pose top face for print visibility — flip
// `lid_text_emboss` or mirror the text yourself if you need it on the outward face instead.
//
// Snap-fit clearances here are a best-effort approximation, not laser-tuned to any one
// printer/material — verify fit on your printer and adjust `lid_clearance` / `latch_bump`
// before relying on the latch.
// ---------------------------------------------------------------------------
module hinged_box(
    length          = 120,
    width           = 80,
    height          = 40,
    wall            = 2.4,
    corner_r        = 6,
    div_x           = 0,
    div_y           = 0,
    div_thickness   = 1.6,
    hinge_depth     = 10,     // Y-span of the living-hinge strip (fold direction)
    hinge_margin    = 8,      // inset of the hinge from each end along X
    hinge_web       = 0.6,    // living_hinge web_thickness
    hinge_grooves   = 3,
    lid_len         = 0,      // Y-span of the lid panel in the open/print pose; 0 = auto
    lid_rim         = 6,      // depth of the lid's downturned skirt
    lid_clearance   = 0.3,    // radial clearance between skirt and box outer wall
    latch_w         = 14,     // width of the snap latch, centered on the front wall
    latch_bump      = 0.8,    // ridge protrusion / groove depth
    lid_text        = "",
    lid_text_size   = 10,
    lid_text_depth  = 0.6,
    lid_text_emboss = false,
    fn              = 48
) {
    hinge_span = length - 2*hinge_margin;
    hinge_z    = height - wall/2;
    lid_len_actual = lid_len > 0 ? lid_len : (width - hinge_depth + wall);
    ridge_h    = min(3, lid_rim * 0.4);

    // --- box ---
    difference() {
        union() {
            _box_shell(length, width, height, wall, corner_r, fn);
            _dividers(length, width, height, wall, div_x, div_y, div_thickness);
        }
        // latch ridge socket relief isn't needed on the box side; the ridge itself is added below
    }
    // latch ridge on the box's front (Y=0) outer face, opposite the hinge
    translate([length/2 - latch_w/2, -latch_bump, hinge_z - lid_rim/2 - ridge_h/2])
        cube([latch_w, latch_bump + 0.01, ridge_h]);

    // --- hinge ---
    translate([length/2, width + hinge_depth/2, hinge_z])
        rotate([0, 0, 90])
            living_hinge(
                width         = hinge_span,
                length        = hinge_depth,
                thickness     = wall,
                web_thickness = hinge_web,
                groove_count  = hinge_grooves,
                groove_width  = 1.0
            );

    // --- lid (open/print pose, extends beyond the hinge in +Y) ---
    y0 = width + hinge_depth;
    difference() {
        union() {
            // flat panel
            translate([0, y0, height - wall])
                cube([length, lid_len_actual, wall]);
            // side skirts (X invariant under the fold, so these land directly on the box's
            // left/right outer walls once closed)
            translate([-lid_clearance - wall, y0, height])
                cube([wall, lid_len_actual, lid_rim]);
            translate([length + lid_clearance, y0, height])
                cube([wall, lid_len_actual, lid_rim]);
            // front skirt (the edge that swings down to meet the box's front wall)
            translate([-lid_clearance - wall, y0 + lid_len_actual - wall, height])
                cube([length + 2*(lid_clearance + wall), wall, lid_rim]);
        }
        // latch groove on the inner face of the front skirt, centered mid-height so it lines
        // up with the box's latch ridge after the 180° fold (see module docstring)
        translate([length/2 - latch_w/2, y0 + lid_len_actual - wall - 0.01, height + lid_rim/2 - ridge_h/2 - latch_bump*0.2])
            cube([latch_w, wall - latch_bump - 0.01 + 0.02, ridge_h + latch_bump*0.4]);
        // lid text, engraved into the open-pose top face
        if (!lid_text_emboss && len(lid_text) > 0)
            translate([length/2, y0 + lid_len_actual/2, height - lid_text_depth + 0.01])
                linear_extrude(height=lid_text_depth)
                    text(lid_text, size=lid_text_size, halign="center", valign="center");
    }
    // emboss variant: text raised proud of the open-pose top face
    if (lid_text_emboss && len(lid_text) > 0)
        translate([length/2, y0 + lid_len_actual/2, height])
            linear_extrude(height=lid_text_depth)
                text(lid_text, size=lid_text_size, halign="center", valign="center");
}
