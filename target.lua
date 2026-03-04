-- ia_gutenberg/target.lua

function ia_gutenberg.get_target_info(user, pointed_thing)
	local info = {
		user_name = user:get_player_name(),
		type = "self",
		meta = user:get_meta(),
		name = user:get_player_name(),
		pos = user:get_pos()
	}

	if pointed_thing.type == "node" then
		info.type = "node"
		info.pos  = pointed_thing.under
		info.meta = minetest.get_meta(info.pos)
		info.name = minetest.get_node(info.pos).name
	elseif pointed_thing.type == "object" then
		local ref = pointed_thing.ref
		info.type = ref:is_player() and "player" or "entity"
		info.ref  = ref
		info.meta = ref:get_meta()
		info.name = ref:is_player() and ref:get_player_name() or (ref:get_luaentity() and ref:get_luaentity().name)
		info.pos  = ref:get_pos()
	end

	return info
end
