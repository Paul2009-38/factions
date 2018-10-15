hud_ids = {}

createHudfactionLand = function(player)
	local name = player:get_player_name()
	hud_ids[name .. "factionLand"] = player:hud_add({
		hud_elem_type = "text",
		name = "factionLand",
		number = 0xFFFFFF,
		position = {x=0.1, y = .98},
		text = "Wilderness",
		scale = {x=1, y=1},
		alignment = {x=0, y=0},
	})
end

createHudFactionName = function(player,factionname)
	local name = player:get_player_name()
	local id_name = name .. "factionName"
	if not hud_ids[id_name] then
		hud_ids[id_name] = player:hud_add({
			hud_elem_type = "text",
			name = "factionName",
			number = 0xFFFFFF,
			position = {x=1, y = 0},
			text = "Faction "..factionname,
			scale = {x=1, y=1},
			alignment = {x=-1, y=0},
			offset = {x = -20, y = 20}
		})
	end
end

createHudPower = function(player,faction)
	local name = player:get_player_name()
	local id_name = name .. "powerWatch"
	if not hud_ids[id_name] then
		hud_ids[id_name] = player:hud_add({
			hud_elem_type = "text",
			name = "powerWatch",
			number = 0xFFFFFF,
			position = {x=0.9, y = .98},
			text = "Power "..faction.power.."/"..faction.maxpower - faction.usedpower.."/"..faction.maxpower,
			scale = {x=1, y=1},
			alignment = {x=-1, y=0},
			offset = {x = 0, y = 0}
		})
	end
end

updateHudPower = function(player,faction)
	local name = player:get_player_name()
	local id_name = name .. "powerWatch"
	if hud_ids[id_name] then
		player:hud_change(hud_ids[id_name],"text","Power "..faction.power.."/"..faction.maxpower - faction.usedpower.."/"..faction.maxpower)
	end
end

removeHud = function(player,hudname)
	local name = player:get_player_name()
	local id_name = name .. hudname
	if hud_ids[id_name] then
		player:hud_remove(hud_ids[id_name])
		hud_ids[id_name] = nil
	end
end

hudUpdate = function()
	minetest.after(3, 
	function()
		local playerslist = minetest.get_connected_players()
		for i in pairs(playerslist) do
			local player = playerslist[i]
			local name = player:get_player_name()
			local faction = factions.get_faction_at(player:getpos())
			local id_name = name .. "factionLand"
			if hud_ids[id_name] then
				player:hud_change(hud_ids[id_name],"text",(faction and faction.name) or "Wilderness")
			end
		end
		hudUpdate()
	end)
end

factionUpdate = function()
	minetest.after(factions.tick_time, 
	function()
		factions.faction_tick()
		factionUpdate()
	end)
end