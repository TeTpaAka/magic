function sample_spell(player, pointed_thing) 
end

-- activate the spells
minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	wands.unlock_spell(playername, "spells:light")
	wands.unlock_spell(playername, "spells:dig")
	wands.unlock_spell(playername, "spells:place")
end)

minetest.register_node("spells:lightball", {
	drawtype = "plantlike",
	tiles = {"spells_lightball.png"},
	paramtype = "light",
	light_source = 13,
	walkable = false,
	drop = "",
	groups = { dig_immediate = 3 }
})

wands.register_spell("spells:light", {
	title = "Light Orb",
	description = "Places a ball of light",
	type = "node",
	cost = 10,
	func = function(player, pointed_thing)
		local pos = pointed_thing.above
		local node = minetest.get_node(pos)
		if (node.name == "air") then
			minetest.set_node(pos, {name = "spells:lightball"})
			return true
		end
		return false
	end
})

wands.register_spell("spells:dig", {
	title = "Dig Block",
	description = "Digs the block you're pointing at",
	type = "node",
	cost = 20,
	func = function(player, pointed_thing)
		local playername = player:get_player_name()
		local pos = minetest.get_pointed_thing_position(pointed_thing)
		if (minetest.is_protected(pos, playername)) then
			return false
		end
		local node = minetest.get_node(pos)
		minetest.dig_node(pos)
		local drops = minetest.get_node_drops(node.name, "wands:wand_1")
		local inv = player:get_inventory()
		for _,drop in pairs(drops) do
			inv:add_item("main", drop)
		end
		return true
	end
})

wands.register_spell("spells:place", {
	title = "Place Block",
	description = "Places a block where you point to",
	type = "node",
	cost = 20,
	func = function(player, pointed_thing)
		local playername = player:get_player_name()
		local pos = pointed_thing.above
		if (minetest.is_protected(pos, playername)) then
			return false
		end
		local idx = player:get_wield_index() + 1
		local stack = player:get_inventory():get_stack(player:get_wield_list(), idx)
		local success = false
		stack, success = minetest.item_place(stack, player, pointed_thing)
		player:get_inventory():set_stack(player:get_wield_list(),idx, stack)
		return success
	end
})
