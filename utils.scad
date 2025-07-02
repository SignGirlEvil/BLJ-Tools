function is_even (x) = x % 2 == 0;

function make_rosenbrock_banana (a, b) =
    function (x)
        ((a - x[0]) ^ 2) +
        (b * ((x[1] - (x[0] ^ 2)) ^ 2));

function sphere_func (x, i=0, tot=0) = 
    i >= len(x) ?
        tot :
        sphere_func(x, i + 1, tot + (x[i] ^ 2));

function add_func_results (func_to_add_1, func_to_add_2) =
    function (x) 
        func_to_add_1(x) + func_to_add_2(x);

function square_func_results (func_to_sq) =
    function (x) func_to_sq(x) ^ 2;

function mult_func_results_by_val (func_to_mult, val) =
    function (x) func_to_mult(x) * val;

function half_square_func_results (func_to_hs) =
    mult_func_results_by_val(
        square_func_results(func_to_hs), 0.5
    );

function repeat_list_elems (list, times=2, i=0, rep_list=[]) =
    assert(is_list(list))
    assert(times >= 1)
    let(is_base_case = i >= len(list))
    is_base_case ?
        rep_list :
        repeat_list_elems(
            list, times, i + 1,
            concat(
                rep_list,
                [for (j = [0: times - 1]) list[i]]
            )
        );

function randf (min_val=0, max_val=1, seed=undef) =
    let(
        seed = is_undef(seed) ? 
            rands(0, 100, 1)[0] : seed
    )
    rands(min_val, max_val, 1, seed)[0];
