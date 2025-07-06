include <constants.scad>;
use <constraint.scad>;
use <pt.scad>;
use <seg.scad>;
use <sketch.scad>;
include <../utils.scad>;
include <../math/numeric-methods.scad>;

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

function _constraint_err_func (sketch_scon, c_id) =
    let(
        constraint_scon = 
            sketch_constraint(sketch_scon, c_id),
        type =
            constraint_type(constraint_scon),
        sketch_idxs = constraint_sketch_idxs(
            constraint_scon
        ),
        vals =
            constraint_vals(constraint_scon)
    )
    //echo(type=type, idxs=sketch_idxs, vals=vals)
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
    type == HORIZONTAL ?
        disp_err_func(
            _sketch_indices_to_solver_indices(
                seg_pt_indices(
                    sketch_seg(
                        sketch_scon,
                        sketch_idxs[0]
                    )
                ),
                [PT_Y, PT_Y]
            ), [0]
        ) :
    type == VERTICAL ?
        disp_err_func(
            _sketch_indices_to_solver_indices(
                seg_pt_indices(
                    sketch_seg(
                        sketch_scon,
                        sketch_idxs[0]
                    )
                ),
                [PT_X, PT_X]
            ), [0]
        ) :
    function (x) 0;

function _construct_constraint_func_list (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    let(
        n = sketch_num_constraints(sketch_scon),
        func_list = [
            for (i = [0 : n - 1])
                _constraint_err_func(
                    sketch_scon, i
                )
        ]
    )
    len(func_list) == 0 ?
        [ZERO_FUNC] :
        func_list;

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
