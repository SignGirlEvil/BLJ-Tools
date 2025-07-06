include <constants.scad>;
use <constraint.scad>;
use <seg.scad>;
use <sketch.scad>;
use <solve.scad>;
include <../utils.scad>;

// PT SCON FUNCTIONS

function pt_scon (x=undef, y=undef, seed=undef) =
    assert(is_num(x) || is_undef(x))
    assert(is_num(y) || is_undef(y))
    let(
        seed = default(seed, randf()),
        x = default(x, randf(seed=seed)),
        y = default(y, randf(seed=seed))
    )
    [["x", x], ["y", y]];

function is_pt_scon (scon) =
    !is_list(scon) ? false :
    len(scon) != 2 ? false :
    scon_map_has_keys(scon, ["x", "y"]);

function pt_x (pt_scon) =
    scon_value(pt_scon, ["x"]);

function pt_y (pt_scon) =
    scon_value(pt_scon, ["y"]);

function pt_xy (pt_scon) =
    [pt_x(pt_scon), pt_y(pt_scon)];

// CONSTRUCTION

function add_pt (sketch_scon, x=undef, y=undef) =
    let(
        seed = _sketch_seed(sketch_scon),
        pt_scon = pt_scon(x, y, seed),
        old_pts_list =
            sketch_pts(sketch_scon),
        new_pts_list =
            list_append(old_pts_list, pt_scon)
    )
    scon_set(sketch_scon, ["pts"], new_pts_list);

module add_pt (x=undef, y=undef, fixed=false) {
    assert(is_list(fixed) || is_bool(fixed));
    
    fixed_list = is_list(fixed) ?
        fixed : [fixed, fixed];
    
    assert(!(fixed[0] && is_undef(x)),
        "Cannot fix x with undefined starting x-coordinate"
    );
    
    assert(!(fixed[1] && is_undef(y)),
        "Cannot fix y with undefined starting y-coordinate"
    );
    
    $sketch_scon = add_pt($sketch_scon, x, y);
    
    pt_id = sketch_num_pts($sketch_scon) - 1;
    
    if (fixed_list == [true, true]) {
        add_constraint(FIX_X, [pt_id], [x])
        add_constraint(FIX_Y, [pt_id], [y])
        children();
    } else if (fixed_list == [true, false]) {
        add_constraint(FIX_X, [pt_id], [x])
        children();
    } else if (fixed_list == [false, true]) {
        add_constraint(FIX_Y, [pt_id], [y])
        children();
    } else {
        children();
    }
}

function add_pts (sketch_scon, xy_list, i=0) =
    assert(is_sketch_scon(sketch_scon))
    let(
        base_case = i >= len(xy_list),
        xy = base_case ? [0, 0] : xy_list[i],
        x = xy[0], y = xy[1]
    )
    base_case ?
        sketch_scon :
        add_pts(
            add_pt(sketch_scon, x, y),
            xy_list, i + 1
        );

module add_pts (n_pts_or_coords_list) {
    assert(!is_undef(n_pts_or_coords_list));
    
    arg_is_int = is_int(n_pts_or_coords_list);
    arg_is_list = is_list(n_pts_or_coords_list);
    
    assert(arg_is_list || arg_is_int);
    
    if (arg_is_int) {
        n_pts = n_pts_or_coords_list;
        
        if (n_pts > 0) {
            add_pt()
            add_pts(n_pts - 1)
            children();
        } else {
            children();
        }
    } else {
        xy_list = n_pts_or_coords_list;
        
        $sketch_scon = add_pts(
            $sketch_scon, xy_list
        );
        children();
    }
}

function set_pt_x (sketch_scon, pt_id, x) =
    assert(is_num(x))
    scon_set(
        sketch_scon, ["pts", pt_id, "x"], x
    );

function set_pt_y (sketch_scon, pt_id, y) =
    assert(is_num(y))
    scon_set(
        sketch_scon, ["pts", pt_id, "y"], y
    );

// DRAWING

module draw_pt (sketch_scon, pt_idx, r=3, $fn=12, with_name=false) {
    pt_scon = sketch_pt(sketch_scon, pt_idx);
    
    move(pt_xy(pt_scon)) {
        circle(r=r, $fn=$fn);
        
        if (with_name) {
            fwd(1.25 * r) up(1) color("green")
                text(
                    str("pt-", pt_idx),
                    size=1.5 * r,
                    halign="center",
                    valign="top"
                );
        }
        
    }
}
