include <utils.scad>;

function n_diff (func_to_diff, x, h=1e-4) =
    (func_to_diff(x + h) - func_to_diff(x - h)) /
    (2 * h);

function bind_all_but_one_index (func_to_bind, list, unbound_i) =
    assert(is_function(func_to_bind))
    assert(is_list(list))
    assert(unbound_i < len(list))
    assert(unbound_i >= 0)
    function (x) func_to_bind(
        [for (i = [0 : len(list) - 1])
         i == unbound_i ? x : list[i]]
    );

function n_gradient (func_to_grad, x, h=1e-4) =
    assert(is_list(x))
    let(
        n = len(x)
    )
    [
        for (i = [0 : n - 1])
        let(
            fn = bind_all_but_one_index(
                func_to_grad, x, i
            )
        )
        n_diff(fn, x[i], h)
    ];

function ternary_search (func_to_search, lo, hi, min_width=1e-9) =
    assert(hi >= lo)
    let(
        width = hi - lo,
        third_width = width / 3.0,
        left = third_width + lo,
        right = left + third_width,
        f_left = func_to_search(left),
        f_right = func_to_search(right)
    )
    width < min_width ? (lo + hi) / 2 :
    f_left < f_right ?
        ternary_search(
            func_to_search, lo, right, min_width
        ) :
        ternary_search(
            func_to_search, left, hi, min_width
        );

function abs_list (list) =
    [for (i = [0: len(list) - 1]) abs(list[i])];

function abs_total (list, tot=0, i=0) = 
    i >= len(list) ? tot :
        abs_total(list, tot + abs(list[i]), i + 1);

function abs_max (list) = max(abs_list(list));

function gradient_descent (func_to_gd, x, max_step=10, iters_left=100, abs_precision=1e-7, grad_h=1e-4, use_rand_step_mult=false, return_x_if_no_iters_left=false) =
    let(
        grad = n_gradient(
            func_to_gd, x, h=grad_h
        ),
        fh = function (h)
            func_to_gd(x - (h * grad)),
        optimal_step =
            ternary_search(fh, 0, max_step),
        step = use_rand_step_mult ?
            optimal_step * randf(0.25, 1) :
            optimal_step,
        next_x = x - (step * grad),
        abs_grad_max = abs_max(grad)
    )
    //echo(x=x, g=grad)
    iters_left <= 0 ? 
        (return_x_if_no_iters_left ?
            x : undef) :
    abs_grad_max <= abs_precision ?
        next_x :
        gradient_descent(
            func_to_gd, next_x,
            max_step, iters_left - 1,
            abs_precision, grad_h,
            use_rand_step_mult,
            return_x_if_no_iters_left
        );

function func_list_eval (func_list, x) =
    [for (fn = func_list) fn(x)];

function func_mat_eval (func_mat, x) =
    [for (row = func_mat) func_list_eval(row, x)];


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