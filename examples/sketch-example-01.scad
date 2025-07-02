include <../sketch.scad>;

Point_2_Initial_x = 0; // [-30, 0]
Point_3_Initial_y = -15; // [-15, 5]

begin_sketch()
    // Create four points
    add_pts(2)
    add_pt(Point_2_Initial_x)
    add_pt(y=Point_3_Initial_y)
    
    // Fix pt-0 to (-10, 5)
    add_constraint(FIX_X, 0, -10)
    add_constraint(FIX_Y, 0, 15)
    
    // Set pt-1 15 units right and 5 units
    // below pt-0
    add_constraint(H_DIST, [1, 0], 15)
    add_constraint(V_DIST, [1, 0], -5)
    
    // Set pt-2 to always be on the x-axis
    // and 25 units away from pt-0
    add_constraint(FIX_Y, 2, 0)
    add_constraint(DIST, [2, 0], 25)
    
    add_constraint(H_DIST, [3, 1], 0)
    add_constraint(DIST, [3, 2], 10)
    
    solve_sketch()
    draw_sketch(1);
