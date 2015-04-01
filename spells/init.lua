function sample_spell(player, pointed_thing) 
end

local playereffects_path = minetest.get_modpath("playereffects")

-- activate the spells
minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	wands.unlock_spell(playername, "spells:light")
	wands.unlock_spell(playername, "spells:dig")
	wands.unlock_spell(playername, "spells:place")
	wands.unlock_spell(playername, "spells:heal")
	wands.unlock_spell(playername, "spells:retrieve_item")
	if (playereffects_path) then
		wands.unlock_spell(playername, "spells:fly")
		wands.unlock_spell(playername, "spells:water_breath")
	end
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

wands.register_spell("spells:heal", {
	title = "Heal Yourself",
	description = "Heals yourself by 10 HP.",
	type = "anything",
	cost = 100,
	func = function(player, pointed_thing)
		if (player:get_hp() < 20) then
			player:set_hp(player:get_hp() + 10)
			return true
		end
		return false
	end
})

wands.register_spell("spells:retrieve_item", {
	title = "Retrieve Item",
	description = "Retrieves item",
	type = "object",
	cost = 10,
	func = function(player, pointed_thing)
		local object = pointed_thing.ref
		if (not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item") then
			local inv = player:get_inventory()
			if (inv and inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring))) then
				inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
				object:get_luaentity().itemstring = ""
				object:remove()
				return true
			end
		end
		print "test"
		return false
	end
})


if playereffects_path then
	-- Fly
	playereffects.register_effect_type("spells:fly_effect", "Fly (using k)", nil, {"fly"},
		function(player)
			local playername = player:get_player_name()
			local privs = minetest.get_player_privs(playername)
			if (privs.fly) then
				return false
			end
			privs.fly = true
			minetest.set_player_privs(playername, privs)
			return true
		end,
		function(effect, player)
			local playername = player:get_player_name()
			local privs = minetest.get_player_privs(playername)
			privs.fly = nil
			minetest.set_player_privs(playername, privs)
			return true
		end)
	wands.register_spell("spells:fly", {
		title = "Fly",
		description = "Allows you to fly (using k key)",
		type = "anything",
		cost = 100,
		func = function(player, pointed_thing)
			if (playereffects.apply_effect_type("spells:fly_effect", 60, player)) then
				return true
			end
			return false
		end
	})

	-- Breath under water
	playereffects.register_effect_type("spells:water_breath_effect", "Breath even under water", nil, {"breath"},
		function(player)
			player:set_breath(11)
			return true
		end,
		function(effect, player)
		end,
		false, true, 3)
	wands.register_spell("spells:water_breath", {
		title = "Water breath",
		description = "Let's you breath even when you're not in air",
		type = "anything",
		cost = 100,
		func = function(player, pointed_thing)
			if (playereffects.apply_effect_type("spells:water_breath_effect", 20, player)) then
				return true
			end
			return false
		end
	})
end
