include <BOSL2/std.scad>;
include <openscad-scon/scon.scad>;
include <constraints.scad>;

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

function list_append (list, val) =
    concat(list, [val]);

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
                
// SKETCH SCON

SKETCH_SCON = [
    ["pts", []],
    ["constraints", []]
];

function sketch_pts (sketch_scon) =
    scon_value(sketch_scon, ["pts"]);

function sketch_pt (sketch_scon, pt_idx=0) =
    scon_value(sketch_scon, ["pts", pt_idx]);

function sketch_num_pts (sketch_scon) =
    len(sketch_pts(sketch_scon));

function sketch_constraints (sketch_scon) =
    scon_value(sketch_scon, ["constraints"]);

module begin_sketch () {
    $sketch_scon = SKETCH_SCON;
    children();
}

// POINT SCON

function pt_scon (x=0, y=0) = [
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
    scon_set(sketch_scon, ["pts", i, "x"], x);

function set_pt_y (sketch_scon, i, y) =
    scon_set(sketch_scon, ["pts", i, "y"], y);

module add_pt (x=0, y=0) {
    $sketch_scon =
        add_pt($sketch_scon, pt_scon(x, y));
    
    children();
}

module draw_pt (pt_scon, r=3, $fn=12, i=undef, with_name=false) {
    move(pt_xy(pt_scon)) {
        circle(r=r, $fn=$fn);
        
        if (with_name && is_def(i)) {
            fwd(1.25 * r)
                text(
                    str("pt-", i),
                    size=1.5 * r,
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

function constraint_scon (type, idxs, vals) = [
    ["type", type],
    ["sketch_idxs", idxs],
    ["vals", vals]
];

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

module add_constraint (type, sketch_idxs, vals) {
    $sketch_scon =
        add_constraint(
            $sketch_scon,
            constraint_scon(type, sketch_idxs, vals)
        );
    
    children();
}

// SKETCH SOLVING FUNCTIONS

PT_X = "pt-x";
PT_Y = "pt-y";

function _flattened_pts_list (pts_scon_list, i=0, list=[]) =
    i >= len(pts_scon_list) ? list :
        _flattened_pts_list(
            pts_scon_list,
            i + 1,
            concat(
                list,
                pt_xy(pts_scon_list[i])
            )
        );

function _sketch_index_to_solver_index (nom_i, type, num_pts) =
    type == PT_X ? 2 * nom_i :
    type == PT_Y ? (2 * nom_i) + 1 :
    undef;

function _solver_index_to_sketch_index (sketch_i, type, num_pts) =
    type == PT_X ? round(sketch_i / 2.0) :
    type == PT_Y ? round((sketch_i - 1) / 2.0) :
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

function _is_even (x) = x % 2 == 0;

function _pt_types_list (num_points, i=0, list=[]) =
        let(
            type = _is_even(i) ? PT_X : PT_Y,
            is_final = i / 2 >= num_points
        )
        is_final ?
            list :
            _pt_types_list(
                num_points, i + 1,
                concat(list, [type])
            );
        

function update_sketch_scon_from_solution (sketch_scon, xf, solver_idx=0, sketch_idxs=undef) =
    let(
        sketch_idxs = is_undef(sketch_idxs) ?
            _solver_indices_to_sketch_indices(
                count(len(xf)),
                _pt_types_list(
                    sketch_num_pts(sketch_scon)
                ),
                sketch_num_pts(sketch_scon)
            )
             : sketch_idxs,
        sketch_idx = sketch_idxs[solver_idx],
        is_final = solver_idx >= len(xf),
        is_x = _is_even(solver_idx)
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

function _add_fix_x_to_fj_list (fj_list, row, sketch_idx, val) =
    let(i = _sketch_index_to_solver_index(
            sketch_idx, PT_X, len(fj_list[0])
        )
    )
    set_func_jacobian_list(
        fj_list,
        fix_val_res_fn(i, val),
        row,
        fix_val_res_grad_fn(i, val),
        i
    );

function _add_fix_y_to_fj_list (fj_list, row, sketch_idx, val) =
    let(i = _sketch_index_to_solver_index(
            sketch_idx, PT_Y, len(fj_list[0])
        )
    )
    set_func_jacobian_list(
        fj_list,
        fix_val_res_fn(i, val),
        row,
        fix_val_res_grad_fn(i, val),
        i
    );

function _add_h_dist_to_fj_list (fj_list, row, sketch_idxs, h_dist) =
    let(idxs = _sketch_indices_to_solver_indices(
            sketch_idxs,
            [PT_X, PT_X],
            len(fj_list[0])
        ),
        ix1 = idxs[0], ix2 = idxs[1]
    )
    set_func_jacobian_list(
        fj_list,
        val_diff_res_fn(ix1, ix2, h_dist),
        row,
        val_diff_res_grad_fn(ix1, ix2, h_dist),
        idxs
    );

function _add_v_dist_to_fj_list (fj_list, row, sketch_idxs, v_dist) =
    let(idxs = _sketch_indices_to_solver_indices(
            sketch_idxs,
            [PT_Y, PT_Y],
            len(fj_list[0])
        ),
        iy1 = idxs[0], iy2 = idxs[1]
    )
    set_func_jacobian_list(
        fj_list,
        val_diff_res_fn(iy1, iy2, v_dist),
        row,
        val_diff_res_grad_fn(iy1, iy2, v_dist),
        idxs
    );

function _add_dist_to_fj_list (fj_list, row, sketch_idxs, dist) =
    let(
        expanded_sketch_idxs = [
            sketch_idxs[0], sketch_idxs[0],
            sketch_idxs[1], sketch_idxs[1]
        ],
        idxs = _sketch_indices_to_solver_indices(
                    expanded_sketch_idxs,
                    _pt_types_list(4),
                    len(fj_list[0])
        ),
        ix1 = idxs[0], iy1 = idxs[1],
        ix2 = idxs[2], iy2 = idxs[3]
    )
    set_func_jacobian_list(
        fj_list,
        pt_dist_res_fn(ix1, iy1, ix2, iy2, dist),
        row,
        pt_dist_res_grad_fn(
            ix1, iy1, ix2, iy2, dist
        ),
        idxs
    );

function _add_constraint_to_fj_list (fj_list, row, constraint_scon) =
    let(
        type = constraint_type(constraint_scon),
        sketch_idxs = constraint_sketch_idxs(constraint_scon),
        vals = constraint_vals(constraint_scon)
    )
    type == FIX_X ?
        _add_fix_x_to_fj_list(
            fj_list, row, sketch_idxs, vals
        ) :
    type == FIX_Y ?
        _add_fix_y_to_fj_list(
            fj_list, row, sketch_idxs, vals
        ) :
    type == H_DIST ?
        _add_h_dist_to_fj_list(
            fj_list, row, sketch_idxs, vals
        ) :
    type == V_DIST ?
        _add_v_dist_to_fj_list(
            fj_list, row, sketch_idxs, vals
        ) :
    type == DIST ?
        _add_dist_to_fj_list(
            fj_list, row, sketch_idxs, vals
        ) :
    undef;
        
function solve_sketch (sketch_scon, func_jacobian_list=undef, row=0, x0=undef) =
    let(
        x0 = is_undef(x0) ? 
                _flattened_pts_list(
                    sketch_pts(sketch_scon)
                ) :
                x0,
        n = len(x0),
        func_jacobian_list =
            is_undef(func_jacobian_list) ?
                default_func_jacobian_list(n) :
                func_jacobian_list,
        constraints =
            sketch_constraints(sketch_scon),
        constraint_scon = constraints[row],
        is_final = row >= len(constraints)
    )
    is_final ?
        newton_raphson(
            func_jacobian_list[0],
            func_jacobian_list[1],
            x0=x0
        ) :
        solve_sketch(
            sketch_scon,
            _add_constraint_to_fj_list(
                func_jacobian_list, row,
                constraint_scon
            ),
            row + 1, x0
        );
    

module solve_sketch () {
    xf = solve_sketch($sketch_scon);
    $sketch_scon =
        update_sketch_scon_from_solution(
            $sketch_scon, xf
        );
    children();
}

module draw_sketch (pt_r=3, pt_fn=12) {
    pts = sketch_pts($sketch_scon);
    
    for (i = idx(pts)) {
        let (pt_scon = pts[i])
            draw_pt(
                pt_scon, r=pt_r, $fn=pt_fn,
                i=i, with_name=true
            );
    }
    
    children();
}
