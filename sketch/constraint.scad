include <constants.scad>;
use <pt.scad>;
use <seg.scad>;
use <sketch.scad>;
use <solve.scad>;
include <../utils.scad>;

// CONSTRAINT ERROR FUNCTIONS

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
    //echo(idxs=idxs, vals=vals)
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

/*
function rel_ang_err_func (idxs, vals) =
    assert(is_list(idxs))
    assert(len(idxs) == 4)
    assert(is_list(vals
*/

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

// CONSTRAINT SCON FUNCTIONS

function constraint_scon (type, sketch_idxs, vals) =
[
    ["type", type],
    ["sketch_idxs", sketch_idxs],
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

function add_constraint (sketch_scon, type, sketch_idxs, vals) =
    let(
        sketch_idxs = is_list(sketch_idxs) ?
            sketch_idxs : [sketch_idxs],
        vals = is_list(vals) ? vals: [vals],
        constraint_scon = 
            constraint_scon(
                type, sketch_idxs, vals
            ),
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
    $sketch_scon =
        add_constraint(
            $sketch_scon, type,
            sketch_idxs, vals
        );
    
    children();
}
