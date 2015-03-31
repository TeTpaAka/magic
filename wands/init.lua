local file = io.open(minetest.get_worldpath() .. "/wands", "r")
if (file) then
	print "reading wands..."
	wands = minetest.deserialize(file:read("*all"))
	file:close()
end
wands = wands or { }
wands.spells = { }
wands.unlocked_spells = wands.unlocked_spells or { }
wands.selected_spells = wands.selected_spells or { }
wands.formspec_lists = {}


-- registeres a spell with the name name
-- name should follow the naming conventions modname:spellname
--
-- spellspec is a table of the format:
-- { title       = "the visible name of the spell",
--   description = "a small description of the spell",
--   type        = "nothing" for yourself, "node" for the environment or "object" for objects, see pointed_thing,
--   cost        = amount of mana to get consumend
--   func        = function(player, pointed_thing) function to get called.
-- }
function wands.register_spell(name, spellspec)
	if (wands.spells[name] ~= nil) then
		print "There is already a spell with this name."
		return false
	end
	wands.spells[name] = {  title = spellspec.title or "missing title",
				description = spellspec.description or "missing description",
				type = spellspec.type,
				cost = spellspec.cost or 0,
				func = spellspec.func or nil }
end

-- unlocks the spell spell for the player playername
function wands.unlock_spell(playername, spell) 
	wands.unlocked_spells[playername] = wands.unlocked_spells[playername] or { }
	wands.unlocked_spells[playername][spell] = true
end

minetest.register_on_shutdown(function()
	print "writing wands..."
	local file = io.open(minetest.get_worldpath() .. "/wands", "w")
	if (file) then
		file:write(minetest.serialize({ selected_spells = wands.selected_spells,
						unlocked_spells = wands.unlocked_spells}))
		file:close()
	end
end)



local use = function(itemstack, user, pointed_thing)
	local playername = user:get_player_name()
	if (not playername) then
		return itemstack
	end
	if (not(wands.selected_spells[playername]) or not(wands.selected_spells[playername].list)) then
		return itemstack
	end
	local selected = tonumber(itemstack:get_metadata()) or 1
	if (not wands.selected_spells[playername].list[selected] or wands.spells[wands.selected_spells[playername].list[selected]] == nil) then
		return itemstack
	end
	if (pointed_thing.type == wands.spells[wands.selected_spells[playername].list[selected]].type) then
		if (wands.spells[wands.selected_spells[playername].list[selected]].func ~= nil) then
			if (mana.subtract(playername, wands.spells[wands.selected_spells[playername].list[selected]].cost)) then
				if (not wands.spells[wands.selected_spells[playername].list[selected]].func(user, pointed_thing)) then
					mana.add_up_to(playername, wands.spells[wands.selected_spells[playername].list[selected]].cost)
				end
			end
		end
	end
	return itemstack
end
local place = function(itemstack, placer, pointed_thing)
	local playername = placer:get_player_name()
	if (not playername) then
		return itemstack
	end
	if (not wands.selected_spells[playername] or not wands.selected_spells[playername].list) then
		return itemstack
	end
	local selected = tonumber(itemstack:get_metadata()) or 1
	selected = selected + 1
	if (selected >= 5 or selected > #wands.selected_spells[playername].list) then
		selected = 1
	end
	itemstack:set_name("wands:wand_"..selected)
	itemstack:set_metadata(selected)
	return itemstack
end


-- register the wand
for i = 1,5 do
	minetest.register_tool("wands:wand_"..i, {
		description = "A powerfull wand",
		inventory_image = "wands_wand.png^wands_"..i..".png",
		wield_image = "wands_wand.png",
		stack_max = 1,
		range = 20,
		on_use = use,
		on_place = place
 	})
end

local function spelllist(playername, uidx, sidx) 
	local formspec = "size[7.5,8]" ..
			 "label[.25,0;known spells:]" .. 
			 "textlist[.25,.5;3,7;known_spells;"
	if (wands.unlocked_spells[playername] == nil) then
		wands.unlocked_spells[playername] = {}
	end
	local unlocked_list = {}
	for spell,_ in pairs(wands.unlocked_spells[playername]) do
		if (wands.spells[spell] ~= nil) then
			formspec = formspec .. wands.spells[spell].title .. ","
			table.insert(unlocked_list, spell)
		end
	end
	formspec = string.sub(formspec, 1, -2)
	formspec = formspec .. ";" .. (uidx or 1) .. "]" ..
			 "label[4.25,0;selected spells:]" .. 
			"textlist[4.25,.5;3,7;selected_spells;"
	if (wands.selected_spells[playername] == nil) then
		wands.selected_spells[playername] = { list = { } }
	end
	local selected_list = {}
	for _,spell in ipairs(wands.selected_spells[playername].list) do
		formspec = formspec .. (wands.spells[spell] or {title = "unknown"}).title .. ","
		table.insert(selected_list, spell)
	end
	formspec = formspec .. ";" .. (sidx or 1) .. "]"

	formspec = formspec .. "button[3.35,2;1,.6;add_spell;+]" ..
			       "button[3.35,4;1,.6;remove_spell;-]"
	wands.formspec_lists[playername] = { unlocked_spells = unlocked_list,
					     unlocked_idx    = uidx or 1,
					     selected_spells = selected_list,
					     selected_idx    = sidx or 1 }

	return formspec
end

-- register the spellbook
minetest.register_tool("wands:spellbook", {
	description = "A book filled with spells",
	inventory_image = "wands_spellbook.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing) 
		local playername = user:get_player_name()
		if (not playername) then
			return itemstack
		end
		minetest.show_formspec(playername, "wands:spelllist", spelllist(playername))
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local playername = player:get_player_name()
	if (formname == "wands:spelllist") then
		if (fields["add_spell"]) then
			wands.selected_spells[playername] = wands.selected_spells[playername] or { list = { } }
			if (#wands.selected_spells[playername].list < 5) then
				table.insert(wands.selected_spells[playername].list, wands.formspec_lists[playername].unlocked_spells[wands.formspec_lists[playername].unlocked_idx]) 
			end
			minetest.show_formspec(playername, "wands:spelllist", spelllist(playername, wands.formspec_lists[playername].unlocked_idx, wands.formspec_lists[playername].selected_idx))
			return
		end
		if (fields["remove_spell"]) then
			wands.selected_spells[playername] = wands.selected_spells[playername] or { list = { } }
			table.remove(wands.selected_spells[playername].list,wands.formspec_lists[playername].selected_idx)
			minetest.show_formspec(playername, "wands:spelllist", spelllist(playername, wands.formspec_lists[playername].unlocked_idx))
			return
		end
		if (fields["known_spells"]) then
			local event = minetest.explode_textlist_event(fields.known_spells)
			wands.formspec_lists[playername].unlocked_idx = tonumber(event.index)
			return
		end
		if (fields["selected_spells"]) then
			local event = minetest.explode_textlist_event(fields.selected_spells)
			wands.formspec_lists[playername].selected_idx = tonumber(event.index)
			return
		end
	end
end)
