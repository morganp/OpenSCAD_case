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
    div_h   = height - wall; // flush with the rim; the lid tray gives headroom above the seam
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

// 45-degree chamfer cutter along the back edge at y=w, z=z: a diamond prism whose
// cross-section is centered on the edge line, so subtracting it from either the body
// (solid below/inside) or the lid (solid above/inside) chamfers that part's rim edge.
module _hb_edge_chamfer(l, w, z, ch) {
    s = ch * 1.4143;
    translate([-1, w, z])
        rotate([45, 0, 0])
            translate([0, -s/2, -s/2])
                cube([l + 2, s, s]);
}

// Alignment/dust lip on the body rim: a thin ring inset one wall + one clearance from the
// outer face, cut short of the back edge so nothing tall sits inside the hinge swing zone.
module _hb_lip(l, w, wall, c, lip_t, z, lip_h, y_max, corner_r, fn) {
    o = wall + c;
    intersection() {
        translate([0, 0, z - 0.05])
            linear_extrude(height=lip_h + 0.05)
                difference() {
                    translate([o, o])
                        _rounded_rect(l - 2*o, w - 2*o, max(0.1, corner_r - o), fn);
                    translate([o + lip_t, o + lip_t])
                        _rounded_rect(l - 2*o - 2*lip_t, w - 2*o - 2*lip_t,
                                      max(0.1, corner_r - o - lip_t), fn);
                }
        translate([-1, -1, z - 1]) cube([l + 2, y_max + 1, lip_h + 3]);
    }
}

// Snap ridge on the lip's front outer face: square bottom face retains the closed lid,
// chamfered top face cams the lid wall outward as it slides down over the lip.
module _hb_bump(l, wall, c, z, lip_h, latch_w, latch_bump) {
    bh = min(3, lip_h - 1.2);
    z0 = z + max(0.6, (lip_h - bh)/2);
    yo = wall + c; // lip outer face
    hull() {
        translate([l/2 - latch_w/2, yo - 0.01, z0])
            cube([latch_w, 0.02, bh]);
        translate([l/2 - latch_w/2, yo - latch_bump, z0])
            cube([latch_w, latch_bump, max(0.4, bh - latch_bump*1.5)]);
    }
}

// Body tray in closed-assembly coordinates: tub + dividers + lip + snap ridge + front ribs.
module _hb_body(l, w, hb, wall, corner_r, div_x, div_y, div_t,
                lip_h, lip_t, c, lip_ymax, latch_w, latch_bump,
                rib_xs, rib_w, rib_d, back_ch, fn) {
    difference() {
        union() {
            _box_shell(l, w, hb, wall, corner_r, fn);
            _dividers(l, w, hb, wall, div_x, div_y, div_t);
            _hb_lip(l, w, wall, c, lip_t, hb, lip_h, lip_ymax, corner_r, fn);
            _hb_bump(l, wall, c, hb, lip_h, latch_w, latch_bump);
            for (x = rib_xs)
                translate([x - rib_w/2, -rib_d, 0])
                    cube([rib_w, rib_d + 0.01, hb - 0.2]);
        }
        if (back_ch > 0)
            _hb_edge_chamfer(l, w, hb, back_ch);
    }
}

// Lid tray in closed-assembly coordinates (opening down, spanning z in [hb, hb+hl]):
// shell + front/top ribs + latch groove + lid text + hinge-clearance chamfer.
module _hb_lid(l, w, hb, hl, wall, corner_r, c,
               lip_h, latch_w, latch_bump,
               rib_xs, rib_w, rib_d, back_ch,
               txt, txt_size, txt_depth, txt_emboss, fn) {
    top = hb + hl;
    bh  = min(3, lip_h - 1.2);
    z0  = hb + max(0.6, (lip_h - bh)/2);
    gd  = latch_bump - c + 0.2; // groove depth into the wall, from its inner face
    difference() {
        union() {
            translate([0, 0, hb])
                difference() {
                    linear_extrude(height=hl) _rounded_rect(l, w, corner_r, fn);
                    translate([wall, wall, -0.05])
                        linear_extrude(height=hl - wall + 0.05)
                            _rounded_rect(l - 2*wall, w - 2*wall,
                                          max(0.1, corner_r - wall), fn);
                }
            for (x = rib_xs) {
                translate([x - rib_w/2, -rib_d, hb + 0.2])
                    cube([rib_w, rib_d + 0.01, hl - 0.2]);
                translate([x - rib_w/2, -rib_d, top - 0.01])
                    cube([rib_w, rib_d + w - 2, rib_d + 0.01]);
            }
            if (txt_emboss && len(txt) > 0)
                translate([l/2, w/2, top - 0.01])
                    linear_extrude(height=txt_depth + 0.01)
                        text(txt, size=txt_size, halign="center", valign="center");
        }
        // latch groove on the inner face of the front wall, mating the lip's snap ridge
        translate([l/2 - latch_w/2 - 0.3, wall - gd, z0 - 0.2])
            cube([latch_w + 0.6, gd + 0.01, bh + 0.5]);
        if (!txt_emboss && len(txt) > 0)
            translate([l/2, w/2, top - txt_depth])
                linear_extrude(height=txt_depth + 0.02)
                    text(txt, size=txt_size, halign="center", valign="center");
        if (back_ch > 0)
            _hb_edge_chamfer(l, w, hb, back_ch);
    }
}

// Hinge leaves along the back seam, in closed-assembly coordinates. The hinge modules
// generate flat at Z=0 with the axis along Y; this reorients them so the mount plane lands
// on the back face (y=w), the axis runs along X at the seam height, leaf2 straps onto the
// body (below the seam) and leaf1 onto the lid (above it).
module _hb_hinges(type, xs, w, hb, len_each, leaf_w, strap_w, kod, cod,
                  pin, pin_c, leaf_t, parts, fn) {
    for (x = xs)
        translate([x, w, hb])
            rotate([-90, 0, 0])
                rotate([0, 0, 90]) {
                    if (type == "crate")
                        crate_hinge(leaf_length=len_each, strap_width=strap_w,
                                    strap_thickness=leaf_t + 1.5,
                                    knuckle_od=cod, knuckle_count=3, axis_height=0,
                                    pin_d=pin, pin_clearance=pin_c, knuckle_gap=0.4,
                                    screws_per_leaf=0, print_pin=false, parts=parts, fn=fn);
                    else if (type == "piano")
                        piano_hinge(length=len_each, leaf_width=leaf_w, leaf_thickness=leaf_t,
                                    knuckle_od=kod, pin_d=pin, pin_clearance=pin_c,
                                    integral_pin=false, print_pin=false, parts=parts, fn=fn);
                    else
                        knuckle_hinge(leaf_length=len_each, leaf_width=leaf_w,
                                      leaf_thickness=leaf_t, knuckle_od=kod, knuckle_count=5,
                                      pin_d=pin, pin_clearance=pin_c, knuckle_gap=0.3,
                                      integral_pin=false, print_pin=false, parts=parts, fn=fn);
                }
}

// ---------------------------------------------------------------------------
// hinged_box — two-tray hinged box: body tray + lid tray joined by pinned hinges
// across the back seam, snap latch on the front.
//
// Two printed parts (body upright, lid beside it opening up), no supports. Each part
// carries its own fused hinge leaf; drop in the pin to assemble. Piano/knuckle hinges
// take a length of 1.75mm filament as the pin, the crate hinge takes a 4mm rod or the
// printed pins emitted next to the parts.
//
// hinge_type:
//   "piano"   — one continuous knuckle hinge across the back seam (default; robust,
//               even load spread, filament pin).
//   "knuckle" — hinge_count discrete knuckle hinges (lighter, classic look).
//   "crate"   — chunky raised-lug crate hinges for the rugged/ammo-box look; pair with
//               ribs > 0. Lid opens past 180 degrees.
//
// An alignment lip on the body rim registers the closed lid; a snap ridge on the lip's
// front face clicks into a groove inside the lid wall. Clearances are a best-effort
// starting point — verify fit and tune lid_clearance / latch_bump for your printer.
//
// Origin: box centered on the XY origin, base at Z=0, hinge on the +Y edge (per this
// repo's conventions). pose="closed" previews the assembled box for fit checks.
// ---------------------------------------------------------------------------
module hinged_box(
    length          = 120,
    width           = 80,
    height          = 40,     // body tray outer height (to the seam)
    lid_depth       = 15,     // lid tray outer height above the seam
    wall            = 2.4,
    corner_r        = 6,
    div_x           = 0,
    div_y           = 0,
    div_thickness   = 1.6,
    hinge_type      = "piano", // "piano" | "knuckle" | "crate"
    hinge_count     = 2,      // knuckle/crate: number of discrete hinges
    hinge_len       = 30,     // knuckle/crate: leaf length along X per hinge
    hinge_margin    = 8,      // hinge inset from each end along X
    knuckle_od      = 0,      // piano/knuckle barrel OD; 0 = auto (max(5, 2*wall))
    pin_d           = 0,      // hinge pin dia; 0 = auto (1.75 filament, 4 for crate)
    pin_clearance   = 0.25,
    leaf_thickness  = 2,      // hinge leaf/strap thickness on the back faces
    lip_h           = 4,      // alignment lip height above the seam
    lid_clearance   = 0.3,    // radial clearance between lip and lid inner wall
    latch_w         = 14,     // width of the snap latch, centered on the front
    latch_bump      = 0.8,    // snap ridge protrusion from the lip face
    ribs            = 0,      // rugged-look vertical ribs on the front + over the lid top
    rib_w           = 0,      // rib width; 0 = auto (2.5*wall)
    rib_depth       = 0,      // rib protrusion; 0 = auto (wall)
    lid_text        = "",
    lid_text_size   = 10,
    lid_text_depth  = 0.6,
    lid_text_emboss = false,  // true = raised (prints face-down: prefer deboss on FDM)
    pose            = "print", // "print" = both parts flat on the bed | "closed" = assembled
    fn              = 48
) {
    l = length; w = width; hb = height; hl = lid_depth; t = wall; c = lid_clearance;
    crate = hinge_type == "crate";
    kod   = knuckle_od > 0 ? knuckle_od : max(5, 2*t);
    cod   = 9;                                    // crate barrel OD
    pin   = pin_d > 0 ? pin_d : (crate ? 4 : 1.75);
    edge  = crate ? cod/2 + 0.4 : kod/2 + 0.3;    // barrel-to-strap edge, per hinge module
    leafw = max(4, min(10, hl - edge - 0.6));     // piano/knuckle leaf width, fits lid wall
    strapw = max(6, min(16, hl - edge - 0.6));    // crate strap width, fits lid wall
    ch    = crate ? 0 : 0.8;  // rim edge chamfer so the rim clears the low piano barrel
    lip_t = max(1.2, t/2);
    lip_ymax = w - t - c - (lip_h + 2*t);         // keep the lip out of the hinge swing zone
    rw    = rib_w > 0 ? rib_w : 2.5*t;
    rd    = rib_depth > 0 ? rib_depth : t;
    rib_m = max(corner_r, rw) + 2;
    rib_xs = ribs <= 0 ? [] : [for (i = [0:ribs-1]) rib_m + (l - 2*rib_m)*(i + 0.5)/ribs];
    xs    = (hinge_type == "piano" || hinge_count <= 1) ? [l/2]
          : [for (i = [0:hinge_count-1])
                hinge_margin + hinge_len/2
                + i*(l - 2*hinge_margin - hinge_len)/(hinge_count - 1)];
    len_each = hinge_type == "piano" ? l - 2*hinge_margin : hinge_len;
    standoff = crate ? cod : kod/2;               // hinge axis offset from the back face
    y_off    = 2*w + 15;                          // lid print position gap

    echo(str("hinged_box: body ", l, "x", w, "x", hb, "mm + lid ", l, "x", w, "x", hl,
             "mm, hinge=", hinge_type, ", pin d=", pin,
             crate ? "mm (printed pins beside the parts)"
                   : "mm (use a length of 1.75mm filament as the pin)"));

    translate([-l/2, -w/2, 0]) {
        _hb_body(l, w, hb, t, corner_r, div_x, div_y, div_thickness,
                 lip_h, lip_t, c, lip_ymax, latch_w, latch_bump,
                 rib_xs, rw, rd, ch, fn);
        _hb_hinges(hinge_type, xs, w, hb, len_each, leafw, strapw, kod, cod,
                   pin, pin_clearance, leaf_thickness, "leaf2", fn);

        if (pose == "closed") {
            _hb_lid(l, w, hb, hl, t, corner_r, c, lip_h, latch_w, latch_bump,
                    rib_xs, rw, rd, ch,
                    lid_text, lid_text_size, lid_text_depth, lid_text_emboss, fn);
            _hb_hinges(hinge_type, xs, w, hb, len_each, leafw, strapw, kod, cod,
                       pin, pin_clearance, leaf_thickness, "leaf1", fn);
            for (x = xs) // pins shown in place
                translate([x - len_each/2, w + standoff, hb])
                    rotate([0, 90, 0])
                        cylinder(h=len_each, r=pin/2, $fn=fn);
        } else {
            // lid printed opening-up beyond the body in +Y, its hinge leaf riding along
            translate([0, y_off, hb + hl])
                rotate([180, 0, 0]) {
                    _hb_lid(l, w, hb, hl, t, corner_r, c, lip_h, latch_w, latch_bump,
                            rib_xs, rw, rd, ch,
                            lid_text, lid_text_size, lid_text_depth, lid_text_emboss, fn);
                    _hb_hinges(hinge_type, xs, w, hb, len_each, leafw, strapw, kod, cod,
                               pin, pin_clearance, leaf_thickness, "leaf1", fn);
                }
            if (crate) // printed pins, one per hinge, lying in front of the body
                for (i = [0:len(xs)-1])
                    translate([l/2 - (len_each - 1)/2, -rd - 8 - i*(pin + 4), pin/2])
                        rotate([0, 90, 0])
                            cylinder(h=len_each - 1, r=pin/2, $fn=fn);
        }
    }
}
