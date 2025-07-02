
/*
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
*/

