hud_ids = {}

function createHudfactionLand(player)
	if player then
		local name = player:get_player_name()
		local id_name = name .. "factionLand"
		
		if not hud_ids[id_name] then
			hud_ids[id_name] = player:hud_add({
				hud_elem_type = "text",
				name = "factionLand",
				number = 0xFFFFFF,
				position = {x=0.1, y = .98},
				text = "Parcel:",
				scale = {x=1, y=1},
				alignment = {x=0, y=0},
			})
		end
	end
end

function createHudFactionName(player, factionname)
	if player and factionname then
		local name = player:get_player_name()
		local id_name = name .. "factionName"
		
		if not hud_ids[id_name] then
			hud_ids[id_name] = player:hud_add({
				hud_elem_type = "text",
				name = "factionName",
				number = 0xFFFFFF,
				position = {x=1, y = 0},
				text = "Faction " .. factionname,
				scale = {x=1, y=1},
				alignment = {x=-1, y=0},
				offset = {x = -20, y = 20}
			})
		end
	end
end

function createHudPower(player, faction)
	if player and faction then
		local name = player:get_player_name()
		local id_name = name .. "powerWatch"
		
		if not hud_ids[id_name] then
			hud_ids[id_name] = player:hud_add({
				hud_elem_type = "text",
				name = "powerWatch",
				number = 0xFFFFFF,
				position = {x=0.9, y = .98},
				text = "Power: " .. faction.power .. " / " .. faction.maxpower - faction.usedpower,
				scale = {x=1, y=1},
				alignment = {x=-1, y=0},
				offset = {x = 0, y = 0}
			})
		end
	end
end

function removeHud(player, hudname)
	local name = ""
	local p = {}
	
	if type(player) ~= "string" then
		name = player:get_player_name()
		p = player
	else
		name = player
		p = minetest.get_player_by_name(player)
	end
	
	local id_name = name .. hudname
	
	if hud_ids[id_name] then
		p:hud_remove(hud_ids[id_name])
		hud_ids[id_name] = nil
	end
end

function updateHudPower(player, faction)
	local name = player:get_player_name()
	local id_name = name .. "powerWatch"
	
	if hud_ids[id_name] then
		player:hud_change(hud_ids[id_name], "text", "Power: " .. faction.power .. " / " .. faction.maxpower - faction.usedpower)
	end
end

function updateFactionName(player, factionname)
	local name = ""
	local p = {}
	
	if type(player) ~= "string" then
		name = player:get_player_name()
		p = player
	else
		name = player
		p = minetest.get_player_by_name(player)
	end
	
	local id_name = name .. "factionName"
	
	if hud_ids[id_name] then
		p:hud_change(hud_ids[id_name], "text", "Faction " .. factionname)
	end
end

function hudUpdateClaimInfo()
	local playerslist = minetest.get_connected_players()
	for i in pairs(playerslist) do
		local player = playerslist[i]
		local name = player:get_player_name()
		local faction, facname = factions.get_faction_at(player:getpos())
		local id_name = name .. "factionLand"
		
		if hud_ids[id_name] then
			local display = "Parcel:"
			if facname then
				display = display .. facname
			end
			player:hud_change(hud_ids[id_name], "text", display)
		end
	end
	minetest.after(3, hudUpdateClaimInfo)
end