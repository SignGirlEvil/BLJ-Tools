include <openscad-scon/scon.scad>;
include <utils.scad>;

function scon_map_has_key (scon_map, key) =
    !is_undef(scon_map_get(scon_map, key));

function scon_map_has_keys (scon_map, keys, i=0) =
    i >= len(keys) ? true :
        scon_map_has_key(scon_map, keys[i]) &&
        scon_map_has_keys(scon_map, keys, i + 1);

function scon_map_get (scon_map, key) =
    let(
        result = search([key], scon_map)
    )
    len(result) <= 0 ?
        undef :
        scon_map[result[0]][1];

function scon_map_set (scon_map, key, val) =
    is_undef(scon_map_get(scon_map, key)) ?
        concat(scon_map, [[key, val]]) :
        [
            for (key_val = scon_map)
                let (
                    key_i = key_val[0],
                    val_i = key_val[1]
                )
                key_i == key ?
                    [key, val] :
                    [key_i, val_i]
        ];

function scon_list_set (scon_list, idx, val) =
    [
        for (i = [0 : len(scon_list) - 1])
            i == idx ? val : scon_list[i]
    ];

function scon_set (scon, path, val, dist=0) =
    let(
        base_case = dist >= len(path),
        key = base_case ? undef : path[dist],
        next_scon = base_case ? undef :
            is_string(key) ? 
                scon_map_get(scon, key) :
                scon[key]
    )
    base_case ? val :
        is_string(key) ?
            scon_map_set(
                scon, key,
                scon_set(
                    next_scon, path,
                    val, dist + 1
                )
            ) :
            scon_list_set(
                scon, key,
                scon_set(
                    next_scon, path,
                    val, dist + 1
                )
            );
