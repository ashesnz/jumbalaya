function reset_hit_order()
	G.HIT_ORDER = clear_table(G.HIT_ORDER)
end

--- Records a rendered node in the collision hash (draw order preserved).
function track_hit_target(obj)
	if obj then G.HIT_ORDER[#G.HIT_ORDER + 1] = obj end
end
