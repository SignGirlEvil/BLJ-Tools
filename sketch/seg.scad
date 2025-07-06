include <constants.scad>;
use <constraint.scad>;
use <pt.scad>;
use <sketch.scad>;
use <solve.scad>;
include <../utils.scad>;

function seg_scon (start, end) =
    assert(is_int(start))
    assert(is_int(end))
    [
        ["start", start],
        ["end",   end]
    ];
    
function is_seg_scon (scon) =
    !is_list(scon) ? false :
    len(scon) != 2 ? false :
    scon_map_has_keys(
        scon,
        ["start", "end"]
    );

function seg_start_id (seg_scon) =
    assert(is_seg_scon(seg_scon))
    scon_value(seg_scon, ["start"]);

function seg_end_id (seg_scon) =
    assert(is_seg_scon(seg_scon))
    scon_value(seg_scon, ["end"]);

function seg_pt_indices (seg_scon) =
    assert(is_seg_scon(seg_scon))
    [
        seg_start_id(seg_scon),
        seg_end_id(seg_scon)
    ];

function seg_pt_xys (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        seg_scon =
            sketch_seg(sketch_scon, seg_id),
        start_id = seg_start_id(seg_scon),
        end_id = seg_end_id(seg_scon),
        start_xy = pt_xy(
            sketch_pt(sketch_scon, start_id)
        ),
        end_xy = pt_xy(
            sketch_pt(sketch_scon, end_id)
        )
    )
    [start_xy, end_xy];

function seg_direction (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        pt_xys = seg_pt_xys(sketch_scon, seg_id),
        start_xy = pt_xys[0],
        end_xy = pt_xys[1],
        diff = end_xy - start_xy
    )
    normalized(diff);

function seg_angle (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        dir = seg_direction(
            sketch_scon, seg_id
        )
    )
    atan2(dir[1], dir[0]);

function seg_length (sketch_scon, seg_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        pt_xys = seg_pt_xys(sketch_scon, seg_id),
        start_xy = pt_xys[0],
        end_xy = pt_xys[1],
        diff = end_xy - start_xy
    )
    norm(diff);

function add_seg (sketch_scon, start_id, end_id) =
    assert(is_sketch_scon(sketch_scon))
    let(
        seg_scon = seg_scon(start_id, end_id),
        old_segs_list =
            sketch_segs(sketch_scon),
        new_segs_list =
            list_append(old_segs_list, seg_scon)
    )
    scon_set(
        sketch_scon, ["segs"], new_segs_list
    );

module add_seg (start_id, end_id) {
    $sketch_scon =
        add_seg(
            $sketch_scon, start_id, end_id
        );
    
    children();
}

function add_wire (sketch_scon, pt_ids, closed=false, i=0) =
    assert(is_sketch_scon(sketch_scon))
    assert(is_list(pt_ids))
    assert(len(pt_ids) >= 2)
    let(
        pt_ids = closed ?
            concat(pt_ids, pt_ids[0]) : pt_ids,
        base_case = i >= len(pt_ids) - 1,
        start_id = pt_ids[i],
        end_id = pt_ids[i + 1]
    )
    base_case ?
        sketch_scon :
        add_wire(
            add_seg(
                sketch_scon, start_id, end_id
            ), pt_ids, false, i + 1
        );

module add_wire (pt_ids, closed=false) {
    $sketch_scon = 
        add_wire($sketch_scon, pt_ids, closed);
    
    children();
}

module draw_seg (sketch_scon, seg_id, w=3, with_name=false) {
    seg_pt_xys = 
        seg_pt_xys(sketch_scon, seg_id);
    
    start = seg_pt_xys[0];
    end = seg_pt_xys[1];
    mid = 0.5 * (start + end);
    angle = seg_angle(sketch_scon, seg_id);
    length = seg_length(sketch_scon, seg_id);
    
    move(mid) rotate(angle) {
        square([length, w], center=true);
        if (with_name) {
            fwd(1.25 * w) up(1) color("green")
                text(
                    str("seg-", seg_id),
                    size=2.0 * w,
                    halign="center",
                    valign="top"
                );
        }
    }
}
