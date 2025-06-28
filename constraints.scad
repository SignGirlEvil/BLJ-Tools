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

function func_list_eval (func_list, x) =
    [for (fn = func_list) fn(x)];

function func_mat_eval (func_mat, x) =
    [for (row = func_mat) func_list_eval(row, x)];

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

function newton_raphson (func_list, j_mat, x0=undef, max_iters=50, max_abs_err=1e-7) =
    let(
        root = repeat(0, len(func_list)),
        x0 = is_undef(x0) ?
            repeat(0, len(func_list)) : x0,
        fx0 = func_list_eval(func_list, x0),
        Jx0 = func_mat_eval(j_mat, x0),
        abs_err = sum(
            [for (i = idx(fx0))
             abs(fx0[i] - root[i])]
        )
    )
    abs_err <= max_abs_err ? x0 :
    max_iters <= 0 ? undef :
        newton_raphson(
            func_list, j_mat,
            x0 - linear_solve(Jx0, fx0),
            max_iters - 1,
            max_abs_err
        );
