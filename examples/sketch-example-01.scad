include <../sketch.scad>;

Point_2_Initial_y = 20; // [-20, 20]

begin_sketch()
    // Create four points
    add_pt()                    // 0
    add_pt()                    // 1
    add_pt(y=Point_2_Initial_y) // 2
    //add_pt() // 3
    
    // Fix pt-0 to the origin
    add_constraint(FIX_X, 0, 0)
    add_constraint(FIX_Y, 0, 0)
    
    // Set pt-1 5 units right and 5 units
    // below pt-0
    add_constraint(H_DIST, [1, 0], 5)
    add_constraint(V_DIST, [1, 0], -5)
    
    // Set pt-2 15 units left of pt-0 and
    // 40 units away from pt-1 (the initial
    // guess for pt-2 will affect where it
    // ends up because there are two solutions
    // to this distance constraint)
    add_constraint(H_DIST, [2, 0], -15)
    add_constraint(DIST, [2, 1], 25)
    
    solve_sketch()
    draw_sketch(1);
