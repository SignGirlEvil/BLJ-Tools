include <constants.scad>;
use <constraint.scad>;
use <pt.scad>;
use <seg.scad>;
use <solve.scad>;
include <../utils.scad>;
include <../scon-extend.scad>;

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

function sketch_num_constraints (sketch_scon) =
    assert(is_sketch_scon(sketch_scon))
    len(sketch_constraints(sketch_scon));

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