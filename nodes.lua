function factions.can_use_node(pos, player,permission)
    if not player then
        return false
    end
    local parcel_faction = factions.get_faction_at(pos)
	if not parcel_faction then
        return true
    end
    local player_faction = factions.get_player_faction(player)
	if player_faction and (parcel_faction.name == player_faction.name or parcel_faction.allies[player_faction.name]) and player_faction:has_permission(player, permission) then
		return true
	end
end
-- Make default chest the faction chest.
if minetest.registered_nodes["default:chest"] then
	minetest.register_lbm({
		label = "Replace faction chest with default one.",
		name = "factions:replace_factions_chest",
		nodenames = {"factions:chest"},
		action = function(pos, node)
			minetest.swap_node(pos, {name = "default:chest"})
			local parcel_faction = factions.get_faction_at(pos)
			if parcel_faction then
				local meta = minetest.get_meta(pos)
				local name = parcel_faction.name
				meta:set_string("faction", name)
				meta:set_string("infotext", "Faction Chest (owned by faction " ..
					name .. ")")
			end
		end
	})
	local dc = minetest.registered_nodes["default:chest"]
	local def_on_rightclick = dc.on_rightclick

	local after_place_node = function(pos, placer)
		local parcel_faction = factions.get_faction_at(pos)
		if parcel_faction then
			local meta = minetest.get_meta(pos)
			local name = parcel_faction.name
			meta:set_string("faction", name)
			meta:set_string("infotext", "Faction Chest (owned by faction " ..
				name .. ")")
		end
	end
	local can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main") and
				factions.can_use_node(pos, player:get_player_name(),"container")
	end
	local allow_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		if not factions.can_use_node(pos, player:get_player_name(),"container") then
			return 0
		end
		return count
	end
	local allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not factions.can_use_node(pos, player:get_player_name(),"container") then
			return 0
		end
		return stack:get_count()
	end
	local allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if not factions.can_use_node(pos, player:get_player_name(),"container") then
			return 0
		end
		return stack:get_count()
	end
	local on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not factions.can_use_node(pos, clicker:get_player_name(),"container") then
			return itemstack
		end
		return def_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	end
	minetest.override_item("default:chest", {after_place_node = after_place_node,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_rightclick = on_rightclick})
end
-- Edit default doors and trapdoors to make them require the door permission.
local doors = {"doors:door_wood_a", "doors:door_wood_b", "doors:door_steel_a", "doors:door_steel_b", "doors:door_glass_a", "doors:door_glass_b", 
				"doors:door_obsidian_glass_a", "doors:door_obsidian_glass_b", "doors:trapdoor", "doors:trapdoor_open", "doors:trapdoor_steel", "doors:trapdoor_steel_open",
				"doors:woodglass_door_a", "doors:woodglass_door_b", "doors:slide_door_a", "doors:slide_door_b", "doors:screen_door_a", "doors:screen_door_b", "doors:rusty_prison_door_a",
				"doors:rusty_prison_door_b", "doors:prison_door_a", "doors:prison_door_b", "doors:japanese_door_a", "doors:japanese_door_b"}
for i, l in ipairs(doors) do
	local dw = minetest.registered_nodes[l]
	if dw then
		local def_on_rightclick = dw.on_rightclick
		local def_can_dig = dw.can_dig
		
		local on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if factions.can_use_node(pos, clicker:get_player_name(), "door") then
				def_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
			end
			return itemstack
		end
		
		local can_dig = nil
		
		if def_can_dig then
			can_dig = function(pos, digger)
				if factions.can_use_node(pos, digger:get_player_name(), "door") then
					return def_can_dig(pos, digger)
				end
				return false
			end
		else
			can_dig = function(pos, digger)
				if factions.can_use_node(pos, digger:get_player_name(), "door") then
					return true
				end
				return false
			end
		end
		minetest.override_item(l, {on_rightclick = on_rightclick,
			can_dig = can_dig})
	end
end

local door_items = {"doors:door_wood", "doors:door_steel", "doors:door_glass", "doors:door_obsidian_glass", "doors:trapdoor", "doors:trapdoor_steel", "doors:woodglass_door", "doors:slide_door",
					"doors:screen_door", "doors:rusty_prison_door", "doors:prison_door", "doors:japanese_door"}

for i, l in ipairs(door_items) do
	local it = minetest.registered_items[l]
	if it then
		local def_on_place = it.on_place
		if def_on_place ~= nil then
			local on_place = function(itemstack, placer, pointed_thing)
				local r = def_on_place(itemstack, placer, pointed_thing)
				local pos = pointed_thing.above
				local parcel_faction = factions.get_faction_at(pos)
				if parcel_faction then
					local meta = minetest.get_meta(pos)
					local name = parcel_faction.name
					meta:set_string("faction", name)
					meta:set_string("infotext", "Faction Door (owned by faction " ..
						name .. ")")
				end
				return r
			end
			minetest.override_item(l, {on_place = on_place})
		end
	end
end
-- Code below was copied from TenPlus1's protector mod(MIT) and changed up a bit.

local x = math.floor(factions_config.parcel_size / 2.1)

minetest.register_node("factions:display_node", {
	tiles = {"factions_display.png"},
	use_texture_alpha = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
			{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
			-- top
			{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
			-- bottom
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
			-- middle (surround parcel)
			{-.55,-.55,-.55, .55,.55,.55},
		},
	},
	selection_box = {
		type = "regular",
	},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",
})

minetest.register_entity("factions:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"factions:display_node"},
	timer = 0,

	on_step = function(self, dtime)

		self.timer = self.timer + dtime

		if self.timer > 6 then
			self.object:remove()
		end
	end,
})

-- End
