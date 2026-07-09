include <../case_library.scad>

pose = "print"; // override for an assembly check: openscad -D 'pose="closed"'

hinged_box(
    length     = 120,
    width      = 80,
    height     = 40,
    lid_depth  = 15,
    wall       = 2,   // flush hinge works down to 2mm walls: 2mm knuckles, 0.8mm rod pin

    corner_r   = 6,
    hinge_type = "flush",
    lid_text   = "STASH",
    pose       = pose
);
