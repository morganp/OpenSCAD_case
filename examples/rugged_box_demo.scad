include <../case_library.scad>

pose = "print"; // override for an assembly check: openscad -D 'pose="closed"'

hinged_box(
    length      = 140,
    width       = 90,
    height      = 45,
    lid_depth   = 20,
    wall        = 2.4,
    corner_r    = 7,
    hinge_type  = "crate",
    hinge_count = 2,
    hinge_len   = 32,
    ribs        = 4,
    pose        = pose
);
