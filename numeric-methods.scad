include <utils.scad>;
include <BOSL2/std.scad>;

function is_func_list (func_list, i=0) =
    i >= len(func_list) ? true :
    !is_function(func_list[i]) ? false :
    is_func_list(func_list, i + 1);

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

function n_jacobian (func_list, x, h=1e-4) =
    assert(is_func_list(func_list))
    assert(is_list(x))
    [
        for (func_i = [0 : len(func_list) - 1])
        n_gradient(func_list[func_i], x, h)
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

function _get_grad (func_to_grad, x, gradd_func=undef, grad_h=1e-4) =
    assert(is_undef(gradd_func) || is_function(gradd_func))
    is_undef(gradd_func) ?
        n_gradient(func_to_grad, x, h=grad_h) :
        gradd_func(x);

function _get_step (func_to_step, x, grad, max_step=1, use_rand_step_mult=false) =
    let(
        max_grad_mult = max_step / norm(grad),
        fh = function(h)
            func_to_step(x - (h * grad)),
        optimal_step =
            ternary_search(fh, 0, max_grad_mult)
    )
    use_rand_step_mult ?
        optimal_step * randf(0.25, 1) :
        optimal_step;

function gradient_descent (func_to_gd, x, max_step=1, iters_left=100, abs_precision=1e-7, grad_h=1e-4, use_rand_step_mult=false, return_x_if_no_iters_left=true, grad_func=undef) =
    let(
        grad = _get_grad(
            func_to_gd, x, grad_func, grad_h
        ),
        step = _get_step(
            func_to_gd, x, grad, max_step,
            use_rand_step_mult
        ),
        next_x = x - (step * grad),
        abs_grad_max = abs_max(grad)
    )
    //echo(x=x, g=grad, step=step, i_left=iters_left)
    iters_left <= 0 ? 
        (return_x_if_no_iters_left ?
            [x, false] : [undef, false]) :
    abs_grad_max <= abs_precision ?
        [next_x, true] :
        gradient_descent(
            func_to_gd, next_x,
            max_step, iters_left - 1,
            abs_precision, grad_h,
            use_rand_step_mult,
            return_x_if_no_iters_left,
            grad_func
        );

function func_list_eval (func_list, x) =
    [for (fn = func_list) fn(x)];

function func_mat_eval (func_mat, x) =
    [for (row = func_mat) func_list_eval(row, x)];

/*
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
*/

function n_newton_raphson (func_list, x0, iters_left=50, max_abs_err=1e-7, h=1e-4) =
    assert(is_func_list(func_list))
    assert(is_list(x0))
    let(
        f_x0 = func_list_eval(func_list, x0),
        j_x0 = n_jacobian(func_list, x0, h),
        abs_err = abs_total(f_x0),
        close_enough_to_root =
            abs_err <= max_abs_err,
        too_many_iters = iters_left <= 0,
        c = linear_solve(j_x0, f_x0),
        solving_error = len(c) != len(x0),
        x1 = solving_error ? x0 : x0 - c
    )
    //echo(f_x0=f_x0)
    //echo(j_x0=j_x0)
    //echo(x0=x0)
    //echo(c=c)
    //echo(x1=x1)
    close_enough_to_root ? [x0, true] :
    too_many_iters ? [x0, false] :
    solving_error ? [x0, false] :
    n_newton_raphson(
        func_list, x1,
        iters_left - 1,
        max_abs_err, h
    );

/*
f1 = function (x)
    (5 * (x[0] ^ 2)) + 
    (x[0] * (x[1] ^ 2)) +
    (sin(2 * rad_to_deg(x[1])) ^ 2) - 2;

f2 = function (x)
    exp((2 * x[0]) - x[1]) +
    (4 * x[1]) - 3;

f_list = [f1, f2];
echo(n_newton_raphson(f_list, [1, 1]));
*/