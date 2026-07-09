include <../case_library.scad>

pose = "print"; // override for an assembly check: openscad -D 'pose="closed"'

hinged_box(
    length        = 120,
    width         = 80,
    height        = 40,
    lid_depth     = 15,
    wall          = 2.4,
    corner_r      = 6,
    div_x         = 2,
    div_y         = 1,
    lid_text      = "TOOLS",
    lid_text_size = 12,
    pose          = pose
);
