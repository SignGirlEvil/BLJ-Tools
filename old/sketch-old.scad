include <BOSL2/std.scad>;
include <openscad-scon/scon.scad>;
include <constraints.scad>;
include <../math/numeric-methods.scad>;
include <../utils.scad>;

// SCON LIBRARY EXTENSIONS

function scon_map_has_key (scon_map, key) =
    !is_undef(scon_map_get(scon_map, key));

function scon_map_has_keys (scon_map, keys, i=0) =
    i >= len(keys) ? true :
        scon_map_has_key(scon_map, keys[i]) &&
        scon_map_has_keys(scon_map, keys, i + 1);

function scon_map_get (scon_map, key) =
    let(
        result = search([key], scon_map)
    )
    len(result) <= 0 ?
        undef :
        scon_map[result[0]][1];

function scon_map_set (scon_map, key, val) =
    is_undef(scon_map_get(scon_map, key)) ?
        concat(scon_map, [[key, val]]) :
        [
            for (key_val = scon_map)
                let (
                    key_i = key_val[0],
                    val_i = key_val[1]
                )
                key_i == key ?
                    [key, val] :
                    [key_i, val_i]
        ];

function scon_list_set (scon_list, idx, val) =
    [
        for (i = [0 : len(scon_list) - 1])
            i == idx ? val : scon_list[i]
    ];

function scon_set (scon, path, val, dist=0) =
    let(
        base_case = dist >= len(path),
        key = base_case ? undef : path[dist],
        next_scon = base_case ? undef :
            is_string(key) ? 
                scon_map_get(scon, key) :
                scon[key]
    )
    base_case ? val :
        is_string(key) ?
            scon_map_set(
                scon, key,
                scon_set(
                    next_scon, path,
                    val, dist + 1
                )
            ) :
            scon_list_set(
                scon, key,
                scon_set(
                    next_scon, path,
                    val, dist + 1
                )
            );

// LIST UTILITY

function list_append (list, val) =
    concat(list, [val]);

/*
function list_slice (list, start=undef, step=undef, end=undef) =
    assert(is_list(list))
    let(
        n = len(list),
        start = default(start, 0),
        step = default(step, 1),
        end = default(end, n - 1)
    )
    assert(all_are_int([start, step, end]))
  */

function list_pop (list) =
    assert(is_list(list))
    assert(len(list) > 0, "Nothing to pop")
    len(list) == 1 ?
        [list[0], []] :
        [
            list[0],
            [for (i = [1 : len(list) - 1])
                list[i]]
        ];

// SKETCH SCON

function sketch_scon (pts=[], segs=[],  constraints=[]) =
    [
        ["pts", pts],
        ["segs", segs],
        ["constraints", constraints]
    ];

function is_sketch_scon (scon) =
    !is_list(scon) ? false :
    len(scon) != 3 ? false :
    scon_map_has_keys(
        scon, ["pts", "segs", "constraints"]
    );

function sketch_pts (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    scon_value(sketch_scon, ["pts"]);

function sketch_pt (sketch_scon, pt_idx=0) =
    assert(is_sketch_scon(sketch_scon))
    scon_value(sketch_scon, ["pts", pt_idx]);

function sketch_num_pts (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    len(sketch_pts(sketch_scon));

function sketch_segs (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    scon_value(sketch_scon, ["segs"]);

function sketch_seg (sketch_scon, seg_idx=0) =
    assert(is_sketch_scon(sketch_scon))
    scon_value(sketch_scon, ["segs", seg_idx]);

function sketch_num_segs (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    len(sketch_segs(sketch_scon));

function sketch_constraints (sketch_scon) =
    scon_value(sketch_scon, ["constraints"]);

function sketch_constraint (sketch_scon, c_idx=0) =
    assert(is_int(c_idx))
    assert(c_idx >= 0)
    assert(is_sketch_scon(sketch_scon))
    let(
        constraints =
            sketch_constraints(sketch_scon)
    )
    assert(c_idx < len(constraints))
    scon_value(
        sketch_scon, ["constraints", c_idx]
    );

function _sketch_seed (sketch_scon) =
    sketch_num_pts(sketch_scon);

module begin_sketch () {
    $sketch_scon = sketch_scon();
    children();
}

module draw_sketch (pt_r=3, seg_w=2, pt_fn=12) {
    num_pts = sketch_num_pts($sketch_scon);
    
    if (num_pts > 0) {
        for (i = [0: num_pts - 1]) {
            draw_pt(
                $sketch_scon, i,
                r=pt_r, $fn=pt_fn,
                with_name=true
            );
        }
    }
    
    num_segs = sketch_num_segs($sketch_scon);
    
    if (num_segs > 0) {
        for (i = [0: num_segs - 1]) {
            draw_seg(
                $sketch_scon, i, w=seg_w,
                with_name=true
            );
        }
    }
    
    children();
}

// POINT SCON

function pt_scon (x=undef, y=undef, seed=undef) =
    assert(is_num(x) || is_undef(x))
    assert(is_num(y) || is_undef(y))
    let(
        seed = is_undef(seed) ? randf() : seed,
        x = is_undef(x) ? randf(seed=seed) : x,
        y = is_undef(y) ? randf(seed=seed) : y
    )
    [
        ["x", x],
        ["y", y]
    ];

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

function add_pt (sketch_scon, pt_scon) =
    let(
        old_pts_list =
            sketch_pts(sketch_scon),
        new_pts_list =
            list_append(old_pts_list, pt_scon)
    )
    scon_set(sketch_scon, ["pts"], new_pts_list);

function set_pt_x (sketch_scon, i, x) =
    assert(is_num(x))
    scon_set(sketch_scon, ["pts", i, "x"], x);

function set_pt_y (sketch_scon, i, y) =
    assert(is_num(y))
    scon_set(sketch_scon, ["pts", i, "y"], y);

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
    
    seed = _sketch_seed($sketch_scon);
    
    $sketch_scon =
        add_pt(
            $sketch_scon, pt_scon(x, y, seed)
        );
    
    i = sketch_num_pts($sketch_scon) - 1;
    
    if (fixed_list == [true, true]) {
        add_constraint(FIX_X, [i], [x])
        add_constraint(FIX_Y, [i], [y])
        children();
    } else if (fixed_list == [true, false]) {
        add_constraint(FIX_X, [i], [x])
        children();
    } else if (fixed_list == [false, true]) {
        add_constraint(FIX_Y, [i], [y])
        children();
    } else {
        children();
    }
}

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
        
    }
}

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

// SEG SCON

function seg_scon (start, end) =
    assert(is_int(start))
    assert(is_int(end))
    [
        ["start", start],
        ["end",   end]
    ];
    
function is_seg_scon (scon) =
    !is_list(scon) ? false :
    len(scon) != 2 ? false :
    scon_map_has_keys(
        scon,
        ["start", "end"]
    );

function add_seg (sketch_scon, seg_scon) =
    assert(is_sketch_scon(sketch_scon))
    assert(is_seg_scon(seg_scon))
    let(
        old_segs_list =
            sketch_segs(sketch_scon),
        new_segs_list =
            list_append(old_segs_list, seg_scon)
    )
    scon_set(
        sketch_scon, ["segs"], new_segs_list
    );

function seg_start_id (seg_scon) =
    assert(is_seg_scon(seg_scon))
    scon_value(seg_scon, ["start"]);

function seg_end_id (seg_scon) =
    assert(is_seg_scon(seg_scon))
    scon_value(seg_scon, ["end"]);

function seg_pt_indices (seg_scon) =
    assert(is_seg_scon(seg_scon))
    [
        seg_start_id(seg_scon),
        seg_end_id(seg_scon)
    ];

function seg_pt_xys (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        seg_scon =
            sketch_seg(sketch_scon, seg_id),
        start_id = seg_start_id(seg_scon),
        end_id = seg_end_id(seg_scon),
        start_xy = pt_xy(
            sketch_pt(sketch_scon, start_id)
        ),
        end_xy = pt_xy(
            sketch_pt(sketch_scon, end_id)
        )
    )
    [start_xy, end_xy];

function seg_direction (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        pt_xys = seg_pt_xys(sketch_scon, seg_id),
        start_xy = pt_xys[0],
        end_xy = pt_xys[1],
        diff = end_xy - start_xy
    )
    normalized(diff);

function seg_angle (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        dir = seg_direction(
            sketch_scon, seg_id
        )
    )
    atan2(dir[1], dir[0]);

function seg_length (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        pt_xys = seg_pt_xys(sketch_scon, seg_id),
        start_xy = pt_xys[0],
        end_xy = pt_xys[1],
        diff = end_xy - start_xy
    )
    norm(diff);

module add_seg (start, end) {
    $sketch_scon =
        add_seg(
            $sketch_scon, seg_scon(start, end)
        );
    
    children();
}

module draw_seg (sketch_scon, seg_id, w=3, with_name=false) {
    seg_pt_xys = 
        seg_pt_xys(sketch_scon, seg_id);
    
    start = seg_pt_xys[0];
    end = seg_pt_xys[1];
    mid = 0.5 * (start + end);
    angle = seg_angle(sketch_scon, seg_id);
    length = seg_length(sketch_scon, seg_id);
    
    move(mid) rotate(angle) {
        square([length, w], center=true);
        if (with_name) {
            fwd(1.25 * w) up(1) color("green")
                text(
                    str("seg-", seg_id),
                    size=2.0 * w,
                    halign="center",
                    valign="top"
                );
        }
    }
}

// CONSTRAIN SCON

FIX_X = "fix-x";
FIX_Y = "fix-y";

H_DIST = "h-dist";
V_DIST = "v-dist";
DIST = "dist";

X_ABOVE = "x-above";
X_BELOW = "x-below";
X_BETWEEN = "x-between";

Y_ABOVE = "y-above";
Y_BELOW = "y-below";
Y_BETWEEN = "y-between";

ABOVE = "above";
BELOW = "below";
RIGHT_OF = "right-of";
LEFT_OF = "left-of";

function constraint_scon (type, idxs, vals) = [
    ["type", type],
    ["sketch_idxs", idxs],
    ["vals", vals]
];

function is_constraint_scon (scon) =
    !is_list(scon) ? false :
    len(scon) != 3 ? false :
    scon_map_has_keys(
        scon,
        ["type", "sketch_idxs", "vals"]
    );

function constraint_type (constraint_scon) =
    scon_value(constraint_scon, ["type"]);

function constraint_sketch_idxs (constraint_scon) =
    scon_value(constraint_scon, ["sketch_idxs"]);

function constraint_vals (constraint_scon) =
    scon_value(constraint_scon, ["vals"]);

function add_constraint (sketch_scon, constraint_scon) =
    let(
        old_constraints_list =
            sketch_constraints(sketch_scon),
        new_constraints_list =
            list_append(
                old_constraints_list,
                constraint_scon
            )
    )
    scon_set(
        sketch_scon, ["constraints"], 
        new_constraints_list
    );

module add_constraint (type, sketch_idxs, vals=[]) {
    //echo(type=type, idxs=sketch_idxs, vals=vals);
    $sketch_scon =
        add_constraint(
            $sketch_scon,
            constraint_scon(
                type,
                force_list(sketch_idxs),
                force_list(vals)
            )
        );
    
    children();
}

// SOLVING SKETCH

PT_X = "pt-x";
PT_Y = "pt-y";

function _flattened_pts_list (pts_scon_list, i=0, list=[]) =
    assert(is_list(pts_scon_list))
    i >= len(pts_scon_list) ? list :
        _flattened_pts_list(
            pts_scon_list,
            i + 1,
            concat(
                list,
                pt_xy(pts_scon_list[i])
            )
        );

function _sketch_index_to_solver_index (sketch_i, type, num_pts) =
    type == PT_X ? 2 * sketch_i :
    type == PT_Y ? (2 * sketch_i) + 1 :
    undef;

function _solver_index_to_sketch_index (solver_i, type, num_pts) =
    type == PT_X ? round(solver_i / 2.0) :
    type == PT_Y ? round((solver_i - 1) / 2.0) :
    undef;

function _sketch_indices_to_solver_indices (sketch_i_list, type_list, num_pts) =
    [
        for (i = idx(sketch_i_list))
            _sketch_index_to_solver_index(
                sketch_i_list[i],
                type_list[i],
                num_pts
            )
    ];

function _solver_indices_to_sketch_indices (solver_i_list, type_list, num_pts) =
    [
        for (i = idx(solver_i_list))
            _solver_index_to_sketch_index(
                solver_i_list[i],
                type_list[i],
                num_pts
            )
    ];

function _alt_pt_types_list (num_points, i=0, list=[]) =
        let(
            type = is_even(i) ? PT_X : PT_Y,
            is_final = i / 2 >= num_points
        )
        is_final ?
            list :
            _alt_pt_types_list(
                num_points, i + 1,
                concat(list, [type])
            );

function update_sketch_scon_from_solution (sketch_scon, xf, solver_idx=0, sketch_idxs=undef) =
    assert(is_list(xf))
    let(
        sketch_idxs = is_undef(sketch_idxs) ?
            _solver_indices_to_sketch_indices(
                count(len(xf)),
                _alt_pt_types_list(
                    sketch_num_pts(sketch_scon)
                ),
                sketch_num_pts(sketch_scon)
            )
             : sketch_idxs,
        sketch_idx = sketch_idxs[solver_idx],
        is_final = solver_idx >= len(xf),
        is_x = is_even(solver_idx)
    )
    is_final ?
        sketch_scon :
        update_sketch_scon_from_solution(
            is_x ?
                set_pt_x(
                    sketch_scon,
                    sketch_idx,
                    xf[solver_idx]
                ) :
                set_pt_y(
                    sketch_scon,
                    sketch_idx,
                    xf[solver_idx]
                ),
            xf, solver_idx + 1, sketch_idxs
        );

function _constraint_err_func (constraint_scon) =
    let(
        type =
            constraint_type(constraint_scon),
        sketch_idxs = constraint_sketch_idxs(
            constraint_scon
        ),
        vals =
            constraint_vals(constraint_scon)
    )
    type == FIX_X ?
        fix_val_err_func(
            _sketch_indices_to_solver_indices(
                sketch_idxs, [PT_X]
            ), vals
        ) :
    type == FIX_Y ?
        fix_val_err_func(
            _sketch_indices_to_solver_indices(
                sketch_idxs, [PT_Y]
            ), vals
        ) :
    type == H_DIST ?
        disp_err_func(
            _sketch_indices_to_solver_indices(
                sketch_idxs, [PT_X, PT_X]
            ), vals
        ) :
    type == V_DIST ?
        disp_err_func(
            _sketch_indices_to_solver_indices(
                sketch_idxs, [PT_Y, PT_Y]
            ), vals
        ) :
    type == DIST ?
        dist_err_func(
            _sketch_indices_to_solver_indices(
                repeat_list_elems(sketch_idxs),
                _alt_pt_types_list(2)
            ), vals
        ) :
    function (x) 0;

function _constraint_half_sq_err_func (constraint_scon) =
    half_square_func_results(
        _constraint_err_func(constraint_scon)
    );

function _construct_half_sq_err_func (sketch_scon, c_idx=0, hse_func=undef) =
    let(
        hse_func = is_undef(hse_func) ?
            function (x) 0 : hse_func,
        constraints =
            sketch_constraints(sketch_scon),
        constraint_scon = constraints[c_idx],
        is_base_case = is_undef(constraint_scon)
    )
    is_base_case ?
        hse_func :
        _construct_half_sq_err_func (
            sketch_scon, c_idx + 1,
            add_func_results(
                hse_func,
                _constraint_half_sq_err_func(
                    constraint_scon
                )
            )
        );

function _construct_constraint_func_list (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    let(
        constraints = 
            sketch_constraints(sketch_scon),
        func_list = [
            for (constraint_scon = constraints)
                _constraint_err_func(
                    constraint_scon
                )
        ]
    )
    func_list;

function _solve_sketch_mult_attempts (half_sq_err_func, xi, attempt=0,
    max_attempts=10) =
    let(
        num_iters = 1000,
        gd_result = gradient_descent(
            half_sq_err_func, xi,
            use_rand_step_mult=false,
            //use_rand_step_mult=true,
            iters_left = num_iters
        ),
        xf = gd_result[0],
        solution_found = gd_result[1]
    )
    //echo(a=attempt, xf=xf, sol_found=solution_found)
    solution_found ? xf :
    attempt >= max_attempts ? xf :
    _solve_sketch_mult_attempts(
        half_sq_err_func, xf,
        attempt + 1
    );
/*
        attempt == 0 ?
            _solve_sketch_mult_attempts(
                half_sq_err_func, xi,
                gradient_descent(
                    half_sq_err_func, xi
                ), attempt + 1
            ) :
        attempt == 1 ?
            _solve_sketch_mult_attempts(
                half_sq_err_func, xi,
                gradient_descent(
                    half_sq_err_func, xi,
                    use_rand_step_mult=true
                ), attempt + 1
            ) :
        attempt == 2 ?
            _solve_sketch_mult_attempts(
                half_sq_err_func, xi,
                gradient_descent(
                    half_sq_err_func, xi,
                    use_rand_step_mult=true,
                    iters_left=100*len(xi)
                ), attempt + 1
            ) :
        attempt == 3 ?
            _solve_sketch_mult_attempts(
                half_sq_err_func, xi,
                gradient_descent(
                    half_sq_err_func, xi,
                    use_rand_step_mult=true,
                    iters_left=100*len(xi),
                    return_x_if_no_iters_left=
                        true
                ), attempt + 1
            ) : xi :
    xf;
*/

/*
function solve_sketch (sketch_scon) =
    let(
        half_sq_err_func = 
            _construct_half_sq_err_func(
                sketch_scon
        ),
        xi = _flattened_pts_list(
            sketch_pts(sketch_scon)
        ),
        xf = _solve_sketch_mult_attempts(
            half_sq_err_func, xi
        )
    )
    update_sketch_scon_from_solution(
        sketch_scon, xf
    );
*/

function solve_sketch (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    let(
        err_func_list = 
            _construct_constraint_func_list(
                sketch_scon
            ),
        xi = _flattened_pts_list(
            sketch_pts(sketch_scon)
        ),
        solver_return = n_newton_raphson(
            err_func_list, xi
        ),
        xf = solver_return[0],
        solved = solver_return[1]
    )
    echo(solved=solved)
    update_sketch_scon_from_solution(
        sketch_scon, xf
    );

module solve_sketch () {
    $sketch_scon = solve_sketch($sketch_scon);
    children();
}
