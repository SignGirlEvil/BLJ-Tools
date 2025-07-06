function fix_val_err_func (idxs, vals) =
    assert(is_list(idxs))
    assert(len(idxs) == 1)
    assert(is_list(vals))
    let(
        i = idxs[0],
        target_val = vals[0]
    )
    function (x)
        assert(is_list(x))
        let(actual_val = x[i])
        actual_val - target_val;

function disp_err_func (idxs, vals) =
    assert(is_list(idxs))
    assert(len(idxs) == 2)
    assert(is_list(vals))
    let(
        i1 = idxs[0], i2 = idxs[1],
        target_disp = vals[0]
    )
    function (x)
        assert(is_list(x))
        let(actual_disp = x[i1] - x[i2])
        actual_disp - target_disp;

function dist_err_func (idxs, vals) =
    assert(is_list(idxs))
    assert(len(idxs) == 4)
    assert(is_list(vals))
    let(
        ix1 = idxs[0], iy1 = idxs[1],
        ix2 = idxs[2], iy2 = idxs[3],
        target_dist = vals[0]
    )
    function (x)
        assert(is_list(x))
        let(
            pt_1 = [x[ix1], x[iy1]],
            pt_2 = [x[ix2], x[iy2]],
            disp_vect = pt_2 - pt_1,
            actual_dist = norm(disp_vect)
        )
    actual_dist - target_dist;

function _punish (val, min_or_max_val, pwr) =
    abs(val - min_or_max_val) ^ pwr;

function val_in_range_err_func (idxs, vals) =
    assert(is_list(idxs))
    assert(len(idxs) == 1)
    assert(is_list(vals))
    let(
        i = idxs[0],
        min_val = vals[0],
        max_val = vals[1],
        pwr = is_undef(vals[2]) ? 2 : vals[2]
    )
    function (x)
        assert(is_list(x))
        let(
            val = x[i],
            punish = function (min_or_max)
                _punish(val, min_or_max, pwr)
        )
        is_undef(min_val) ?
            is_undef(max_val) ?
                0 :
                val > max_val ?
                    punish(max_val) :
                    0 :
            val < min_val ?
                punish(min_val) :
                is_undef(max_val) ?
                    0 :
                    val > max_val ?
                        punish(max_val) :
                        0;

function vals_rel_pos_err_func (idxs, vals) =
    assert(is_list(idxs))
    assert(len(idxs) == 2)
    assert(is_list(vals))
    let(
        i1 = idxs[0], i2 = idxs[1],
        pwr = vals[0],
        target_dir = sign(vals[1])
    )
    function (x)
        assert(is_list(x))
        let(
            val_1 = x[i1], val_2 = x[i2],
            disp = val_1 - val_2,
            actual_dir = sign(disp)
        )
        actual_dir == 0 ? 0 :
        actual_dir == target_dir ? 0 :
        _punish(disp, 0, pwr);

/*
include <BOSL2/std.scad>;

// CONSTRAINT FUNCTIONS AND GRADIENTS

// Residual function for the constraint x1 = val
function fix_val_res_fn (i, val=0) =
    function (x) x[i] - val;

function fix_val_res_grad_fn (i, val=0) =
    function (x) 1;

// Residual function for the constraint x1 - x2 = diff
function val_diff_res_fn (i1, i2, diff=0) = 
    function (x) x[i1] - x[i2] - diff;

function val_diff_res_grad_fn (i1, i2, diff=0) =
    [function (x) 1, function (x) -1];

// Residual function for the distance constraint that (x1, y1) and (x2, y2) are dist units apart, ((x1 - x2) ^ 2) + ((y1 - y2) ^ 2) = dist ^ 2
function pt_dist_res_fn (ix1, iy1, ix2, iy2, dist=1) =
    function (x)
        ((x[ix1] - x[ix2]) ^ 2) + 
        ((x[iy1] - x[iy2]) ^ 2) -
        (dist ^ 2);

function pt_dist_res_grad_fn (ix1, iy1, ix2, iy2, dist=1) =
    [function (x)  2 * (x[ix1] - x[ix2]),
     function (x)  2 * (x[iy1] - x[iy2]),
     function (x) -2 * (x[ix1] - x[ix2]),
     function (x) -2 * (x[iy1] - x[iy2])];


// NUMERIC SOLVER FUNCTIONS

function default_jacobian_func_mat (n) =
    repeat(function (x) 0, [n, n]);

function default_func_list (n) =
    repeat(function (x) 0, n);

function default_func_jacobian_list (n) =
    [default_func_list(n),
     default_jacobian_func_mat(n)];

function set_func_jacobian_list (func_jacobian_list, func, row, grad_funcs, idxs) = 
    let(
        func_list = func_jacobian_list[0],
        j_mat = func_jacobian_list[1],
        j_mat_row = j_mat[row]
    )
    [
        list_set(func_list, row, func),
        list_set(j_mat, row, list_set(
            j_mat_row, idxs, grad_funcs))
    ];
*/