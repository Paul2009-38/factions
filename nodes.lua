function factions.can_use_node(pos, player, permission)
    if not player then
        return false
    end
    local parcel_faction = factions.get_faction_at(pos)
	if not parcel_faction then
        return true
    end
    local player_faction, facname = factions.get_player_faction(player)
	if player_faction and (parcel_faction.name == facname or parcel_faction.allies[facname]) and factions.has_permission(facname, player, permission) then
		return true
	end
end

minetest.register_on_mods_loaded(function()
	-- Make default chest the faction chest.
	if minetest.registered_nodes["default:chest"] then
		local dc = minetest.registered_nodes["default:chest"]
		local def_on_rightclick = dc.on_rightclick
		local after_place_node = function(pos, placer)
			local parcel_faction = factions.get_faction_at(pos)
			if parcel_faction then
				local meta = minetest.get_meta(pos)
				local name = parcel_faction.name
				meta:set_string("faction", name)
				meta:set_string("infotext", "Faction Container (owned by faction " ..
					name .. ")")
			end
		end
		local can_dig = function(pos, player)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:is_empty("main") and
					factions.can_use_node(pos, player:get_player_name(), "container")
		end
		local allow_metadata_inventory_move
		local def_allow_metadata_inventory_move = dc.allow_metadata_inventory_move
		if def_allow_metadata_inventory_move then
			allow_metadata_inventory_move = function(pos, from_list, from_index,
					to_list, to_index, count, player)
				if not factions.can_use_node(pos, player:get_player_name(), "container") and not minetest.check_player_privs(player, "protection_bypass") then
					return 0
				end
				return def_allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
			end
		else
			allow_metadata_inventory_move = function(pos, from_list, from_index,
					to_list, to_index, count, player)
				if not factions.can_use_node(pos, player:get_player_name(), "container") and not minetest.check_player_privs(player, "protection_bypass") then
					return 0
				end
				return count
			end
		end
		local allow_metadata_inventory_put
		local def_allow_metadata_inventory_put = dc.allow_metadata_inventory_put
		if def_allow_metadata_inventory_put then
			allow_metadata_inventory_put = function(pos, listname, index, stack, player)
				if not factions.can_use_node(pos, player:get_player_name(), "container") and not minetest.check_player_privs(player, "protection_bypass") then
					return 0
				end
				return def_allow_metadata_inventory_put(pos, listname, index, stack, player)
			end
		else
			allow_metadata_inventory_put = function(pos, listname, index, stack, player)
				if not factions.can_use_node(pos, player:get_player_name(), "container") and not minetest.check_player_privs(player, "protection_bypass") then
					return 0
				end
				return stack:get_count()
			end
		end
		local allow_metadata_inventory_take
		local def_allow_metadata_inventory_take = dc.allow_metadata_inventory_take
		if def_allow_metadata_inventory_take then
			allow_metadata_inventory_take = function(pos, listname, index, stack, player)
				if not factions.can_use_node(pos, player:get_player_name(), "container") and not minetest.check_player_privs(player, "protection_bypass") then
					return 0
				end
				return def_allow_metadata_inventory_take(pos, listname, index, stack, player)
			end
		else
			allow_metadata_inventory_take = function(pos, listname, index, stack, player)
				if not factions.can_use_node(pos, player:get_player_name(), "container") and not minetest.check_player_privs(player, "protection_bypass") then
					return 0
				end
				return stack:get_count()
			end
		end
		local on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not factions.can_use_node(pos, clicker:get_player_name(), "container") and not minetest.check_player_privs(clicker, "protection_bypass") then
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

	local door_items = {"doors:door_wood", "doors:door_steel", "doors:door_glass", "doors:door_obsidian_glass", "doors:woodglass_door", "doors:slide_door",
						"doors:screen_door", "doors:rusty_prison_door", "doors:prison_door", "doors:japanese_door", "ts_doors:door_default_aspen_wood", "ts_doors:door_full_default_aspen_wood", 
						"ts_doors:door_default_pine_wood", "ts_doors:door_full_default_pine_wood", "ts_doors:door_default_acacia_wood", "ts_doors:door_full_default_acacia_wood", 
						"ts_doors:door_default_wood", "ts_doors:door_full_default_wood", "ts_doors:door_default_junglewood", "ts_doors:door_full_default_junglewood", 
						"ts_doors:door_default_bronzeblock", "ts_doors:door_full_default_bronzeblock", "ts_doors:door_default_copperblock", "ts_doors:door_full_default_copperblock", 
						"ts_doors:door_default_diamondblock", "ts_doors:door_full_default_diamondblock", "ts_doors:door_full_default_goldblock", "ts_doors:door_default_steelblock", "ts_doors:door_full_default_steelblock"}

	local trapdoor_items = {"doors:trapdoor", "doors:trapdoor_steel", "ts_doors:trapdoor_default_aspen_wood", "ts_doors:trapdoor_full_default_aspen_wood",
						"ts_doors:trapdoor_default_wood", "ts_doors:trapdoor_full_default_wood", "ts_doors:trapdoor_default_acacia_wood", "ts_doors:trapdoor_full_default_acacia_wood",
						"ts_doors:trapdoor_default_bronzeblock", "ts_doors:trapdoor_full_default_bronzeblock", "ts_doors:trapdoor_default_copperblock", "ts_doors:trapdoor_full_default_copperblock", "ts_doors:trapdoor_full_default_diamondblock",
						"ts_doors:door_default_goldblock", "ts_doors:trapdoor_default_steelblock", "ts_doors:trapdoor_full_default_steelblock", "ts_doors:trapdoor_default_pine_wood", "ts_doors:trapdoor_full_default_pine_wood",
						"ts_doors:trapdoor_full_default_goldblock", "ts_doors:trapdoor_default_junglewood", "ts_doors:trapdoor_full_default_junglewood",
						"ts_doors:trapdoor_default_diamondblock", "ts_doors:trapdoor_default_goldblock"}					
						
	-- Edit default doors and trapdoors to make them require the door permission.
	local doors = {}
	local all_items = {}
	local item_count = 1
	local old_i = 0

	for i, l in ipairs(door_items) do
		doors[item_count] = l .. "_a"
		doors[item_count + 1] = l .. "_b"
		all_items[i] = l
		item_count = item_count + 2
		old_i = old_i + 1
	end

	for i, l in ipairs(trapdoor_items) do
		doors[item_count] = l
		doors[item_count + 1] = l .. "_open"
		all_items[old_i + i] = l
		item_count = item_count + 2
	end

	for i, l in ipairs(doors) do
		local dw = minetest.registered_nodes[l]
		if dw then
			local def_on_rightclick = dw.on_rightclick
			local def_can_dig = dw.can_dig
			
			local on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
				if factions.can_use_node(pos, clicker:get_player_name(), "door") or minetest.check_player_privs(clicker, "protection_bypass") then
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

	for i, l in ipairs(all_items) do
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

end)
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
