include <../sketch/all.scad>;

begin_sketch()
    // Create and connect four points
    add_pts(4)
    add_wire([0, 1, 2, 3], true)
    
    add_constraint(FIX_X, 0, -30)
    add_constraint(FIX_Y, 0,  20)
    
    add_constraint(DIST, [0, 1], 60)
    add_constraint(DIST, [1, 2], 40)
    
    add_constraint(HORIZONTAL, 0)
    add_constraint(VERTICAL, 1)
    add_constraint(HORIZONTAL, 2)
    add_constraint(VERTICAL, 3)
    
    solve_sketch()
    draw_sketch(pt_r=1, seg_w=0.75);
