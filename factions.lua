---------------------
--! @brief returns whether a faction can be created or not (allows for implementation of blacklists and the like)
--! @param name String containing the faction's name
factions.can_create_faction = function(name)
    if #name > factions_config.faction_name_max_length then
        return false
    elseif factions.factions.get(name) ~= nil then
        return false
    else
        return true
    end
end


util = {
    coords3D_string = function(coords)
        return coords.x..", "..coords.y..", "..coords.z
    end
}

starting_ranks = {["leader"] = {"build", "door", "container", "name", "description", "motd", "invite", "kick"
						, "spawn", "with_draw", "territory", "claim", "access", "disband", "flags", "ranks", "promote"},
                 ["moderator"] = {"claim", "door", "build", "spawn", "invite", "kick", "promote", "container"},
                 ["member"] = {"build", "container", "door"}
                }

-- Faction permissions:
--
-- build: dig and place nodes
-- pain_build: dig and place nodes but take damage doing so
-- door: open/close or dig doors
-- container: be able to use containers like chest
-- name: set the faction's name
-- description: Set the faction description
-- motd: set the faction's message of the day
-- invite: (un)invite players to join the faction
-- kick: kick players off the faction
-- spawn: set the faction's spawn
-- with_draw: withdraw money from the faction's bank
-- territory: claim or unclaim territory
-- claim: (un)claim parcels of land
-- access: manage access to territory and parcels of land to players or factions
-- disband: disband the faction
-- flags: manage faction's flags
-- ranks: create, edit, and delete ranks
-- promote: set a player's rank
-- diplomacy: be able to control the faction's diplomacy

factions.permissions = {"build", "pain_build", "door", "container", "name", "description", "motd", "invite", "kick"
						, "spawn", "with_draw", "territory", "claim", "access", "disband", "flags", "ranks", "promote"}
factions.permissions_desc = {"dig and place nodes", "dig and place nodes but take damage doing so", "open/close or dig faction doors", "be able to use containers like chest", "set the faction's name"
						, "Set the faction description", "set the faction's message of the day", "(un)invite players to join the faction", "kick players off the faction", "set player titles", "set the faction's spawn"
						, "withdraw money from the faction's bank", "claim or unclaim territory", "(un)claim parcels of land", "manage access to territory and parcels of land to players or factions"
						, "disband the faction", "manage faction's flags", "create, edit, and delete ranks", "set a player's rank"}
						
-- open: can the faction be joined without an invite?
-- monsters: can monsters spawn on your land?
-- tax_kick: will players be kicked for not paying tax?
-- animals: can animals spawn on your land?
factions.flags = {"open", "monsters", "tax_kick", "animals"}
factions.flags_desc = {"can the faction be joined without an invite?", "can monsters spawn on your land?(unused)", "will players be kicked for not paying tax?(unused)", "can animals spawn on your land?(unused)"}

if factions_config.faction_diplomacy == true then
	table.insert(factions.permissions, "diplomacy")
	
	table.insert(factions.permissions_desc, "be able to control the faction's diplomacy")
	
	local lt = starting_ranks["leader"]
	table.insert(lt, "diplomacy")
	starting_ranks["leader"] = lt
end

function factions.new() 
    return {
		name = "",
        --! @brief power of a faction (needed for parcel claiming)
        power = factions_config.power,
        --! @brief maximum power of a faction
        maxpower = factions_config.maxpower,
        --! @brief power currently in use
        usedpower = 0.,
        --! @brief list of player names
        players = {},
        --! @brief table of ranks/permissions
        ranks = starting_ranks,
        --! @brief name of the leader
        leader = nil,
		--! @brief spawn of the faction
		spawn = {x=0, y=0, z=0},
        --! @brief default joining rank for new members
        default_rank = "member",
        --! @brief default rank assigned to the leader
        default_leader_rank = "leader",
        --! @brief faction's description string
        description = "Default faction description.",
		--! @brief faction's message of the day.
		message_of_the_day = "",
        --! @brief list of players currently invited (can join with /f join)
        invited_players = {},
        --! @brief table of claimed parcels (keys are parcelpos strings)
        land = {},
        --! @brief table of allies
        allies = {},
		--
		request_inbox = {},
        --! @brief table of enemies
        enemies = {},
		--!
		neutral = {},
        --! @brief table of parcels/factions that are under attack
        attacked_parcels = {},
        --! @brief whether faction is closed or open (boolean)
        join_free = false,
        --! @brief gives certain privileges
        is_admin = false,
        --! @brief last time anyone logged on
        last_logon = os.time(),
		--! @brief how long this has been without parcels
		no_parcel = os.time(),
    }
end


--! @brief create a new empty faction
function factions.new_faction(name)
    local faction = factions.new()
	
    faction.name = name
    factions.factions.set(name, faction)
    factions.on_create(name)
	minetest.after(1, 
		function(name)
			factions.on_no_parcel(name)
	end, name)
	
	factions.onlineplayers[name] = {}
	
	return faction
end

function factions.set_name(oldname, name)
	local faction = factions.factions.get(oldname)
	faction.name = name
	
	for v, i in factions.factions.iterate() do
		if v ~= oldname then
			local fac = factions.factions.get(v)
			
			if fac.neutral[oldname] then
				fac.neutral[oldname] = nil
				fac.neutral[name] = true
			end
			
			if fac.allies[oldname] then
				fac.allies[oldname] = nil
				fac.allies[name] = true
			end
			
			if fac.enemies[oldname] then
				fac.enemies[oldname] = nil
				fac.enemies[name] = true
			end
			
			if fac.request_inbox[oldname] then
				local value = fac.request_inbox[oldname]
				fac.request_inbox[oldname] = nil
				fac.request_inbox[name] = value
			end
			
			factions.factions.set(v, fac)
		end
	end
	
	for parcel in pairs(faction.land) do
		factions.parcels.set(parcel, name)
	end
	
	for playername in pairs(faction.players) do
		factions.players.set(playername, name)
	end
	
	for playername in pairs(factions.onlineplayers[oldname]) do
		updateFactionName(playername, name)
	end
	
	factions.onlineplayers[name] = factions.onlineplayers[oldname]
	factions.onlineplayers[oldname] = nil
	
	factions.factions.remove(oldname)
	
	factions.factions.set(name, faction)
	factions.on_set_name(name, oldname)
	
end

function factions.count_land(name)
    local count = 0.
    for k, v in pairs(factions.factions.get(name).land) do
        count = count + 1
    end
    return count
end

function factions.add_player(name, player, rank)
	local faction = factions.factions.get(name)
	
	if factions.onlineplayers[name] == nil then
		factions.onlineplayers[name] = {}
	end
	
    factions.onlineplayers[name][player] = true
	
	factions.on_player_join(name, player)

	if factions_config.enable_power_per_player then
		local ip = factions.player_ips.get(player)
		local notsame = true
		for i, k in pairs(faction.players) do
			local other_ip = factions.player_ips.get(i)
			if other_ip == ip then
				notsame = false
				break
			end
		end
		if notsame then
			factions.increase_maxpower(name, factions_config.powermax_per_player)
		end
	end
	
	faction.players[player] = rank or faction.default_rank
    factions.players.set(player, name)
    faction.invited_players[player] = nil
	local pdata = minetest.get_player_by_name(player)
	if pdata then
		local ipc = pdata:is_player_connected()
		if ipc then
			createHudFactionName(pdata, name)
			createHudPower(pdata, faction)
		end
	end
    
	factions.factions.set(name, faction)
end

function factions.check_players_in_faction(name)
	for i, k in pairs(factions.factions.get(name).players) do
		return true
	end
	factions.disband(name, "Zero players on faction.")
	return false
end

function factions.remove_player(name, player)
	local faction = factions.factions.get(name)
	
	if factions.onlineplayers[name] == nil then
		factions.onlineplayers[name] = {}
	end
	
	factions.onlineplayers[name][player] = nil

    faction.players[player] = nil
	
	factions.factions.set(name, faction)
	
    factions.players.remove(player)
	factions.on_player_leave(name, player)
	
	if factions_config.enable_power_per_player then
		local ip = factions.player_ips.get(player)
		local notsame = true
		for i,k in pairs(faction.players) do
			local other_ip = factions.player_ips.get(i)
			if other_ip == ip then
				notsame = false
				break
			end
		end
		if notsame then
			factions.decrease_maxpower(name, factions_config.powermax_per_player)
		end
	end
	
	local pdata = minetest.get_player_by_name(player)
	if pdata then
		local ipc = pdata:is_player_connected()
		
		if ipc then
			removeHud(pdata,"factionName")
			removeHud(pdata,"powerWatch")
		end
	end
	
	factions.check_players_in_faction(name)
end

local parcel_size = factions_config.parcel_size

--! @brief disband faction, updates global players and parcels table
function factions.disband(name, reason)
	local faction = factions.factions.get(name)
	
	if not faction.is_admin then
		for v, i in factions.factions.iterate() do
			local fac = factions.factions.get(v)
			if fac ~= nil and fac.name ~= name then
				if fac.enemies[name] then
					factions.end_enemy(fac.name, name)
				end
				
				if fac.allies[name] then
					factions.end_alliance(fac.name, name)
				end
				
				if fac.neutral[name] then
					factions.end_neutral(fac.name, name)
				end
				
				if fac.request_inbox[name] then
					fac.request_inbox[name] = nil
				end
			end
			factions.factions.set(v, fac)
		end
		
		for k, _ in pairs(faction.players) do -- remove players affiliation
			factions.players.remove(k)
		end
		
		for k, v in pairs(faction.land) do -- remove parcel claims
			factions.parcels.remove(k)
		end
		
		factions.on_disband(name, reason)
		
		if factions.onlineplayers ~= nil and factions.onlineplayers[name] ~= nil then
			for i, l in pairs(factions.onlineplayers[name]) do
				removeHud(i, "factionName")
				removeHud(i, "powerWatch")
			end
			
			factions.onlineplayers[name] = nil
		end
		
		factions.factions.remove(name)
	end
end

--! @brief change the faction leader
function factions.set_leader(name, player)
	local faction = factions.factions.get(name)
	
    if faction.leader then
        faction.players[faction.leader] = faction.default_rank
    end
    faction.leader = player
    faction.players[player] = faction.default_leader_rank
    factions.on_new_leader()
	
	factions.factions.set(name, faction)
end

function factions.set_message_of_the_day(name, text)
    local faction = factions.factions.get(name)
	faction.message_of_the_day = text
	factions.factions.set(name, faction)
end

--! @brief check permissions for a given player
--! @return boolean indicating permissions. Players not in faction always receive false
function factions.has_permission(name, player, permission)
	local faction = factions.factions.get(name)
	
    local p = faction.players[player]
    if not p then
        return false
    end
    local perms = faction.ranks[p]
	if perms then
		for i in ipairs(perms) do
			if perms[i] == permission then
				return true
			end
		end
	else
		return false
	end
end

function factions.set_description(name, new)
	local faction = factions.factions.get(name)
	
    faction.description = new
    factions.on_change_description(name)
	
	factions.factions.set(name, faction)
end

--! @brief set faction openness
function factions.toggle_join_free(name, bool)
    local faction = factions.factions.get(name)
	
	faction.join_free = bool
    factions.on_toggle_join_free(name)
    
	factions.factions.set(name, faction)
end

--! @return true if a player can use /f join, false otherwise
function factions.can_join(name, player)
    local faction = factions.factions.get(name)
	return faction.join_free or faction.invited_players[player]
end

--! @brief faction's member will now spawn in a new place
function factions.set_spawn(name, pos)
    local faction = factions.factions.get(name)
	
	faction.spawn = {x = pos.x, y = pos.y, z = pos.z}
    factions.on_set_spawn(name)
    
	factions.factions.set(name, faction)
end

function factions.tp_spawn(name, playername)
	local faction = factions.factions.get(name)
	
	player = minetest.get_player_by_name(playername)
	
	if player then
		player:set_pos(faction.spawn)
	end
end

--! @brief send a message to all members
function factions.broadcast(name, msg, sender)
	if factions.onlineplayers[name] == nil then
		factions.onlineplayers[name] = {}
	end
	
	local message = name .. "> ".. msg
	
    if sender then
        message = sender .. "@" .. message
    end
	
    message = "Faction<" .. message
	
	minetest.log(message)
	
    for k, _ in pairs(factions.onlineplayers[name]) do
        minetest.chat_send_player(k, message)
    end
end

--! @brief checks whether a faction has at least one connected player
function factions.is_online(name)
	if factions.onlineplayers[name] == nil then
		factions.onlineplayers[name] = {}
	end
    for playername, _ in pairs(factions.onlineplayers[name]) do
		return true
    end
    return false
end

function factions.get_parcel_pos(pos)
	if factions_config.protection_style == "3d" then
		return math.floor(pos.x / parcel_size) * parcel_size .. "," .. math.floor(pos.y / parcel_size) * parcel_size .. "," .. math.floor(pos.z / parcel_size) * parcel_size
	else
		return math.floor(pos.x / parcel_size) * parcel_size .. "," .. math.floor(pos.z / parcel_size) * parcel_size
	end
end

function factions.get_player_faction(playername)
    local facname = factions.players.get(playername)
    if facname then
        local faction = factions.factions.get(facname)
        return faction, facname
    end
    return nil
end

function factions.get_faction(facname)
    return factions.factions.get(facname)
end

function factions.get_faction_at(pos)
	local y = pos.y
    if factions_config.protection_depth_height_limit and (pos.y < factions_config.protection_max_depth or pos.y > factions_config.protection_max_height) then
		return nil
    end
    local parcelpos = factions.get_parcel_pos(pos)
    return factions.get_parcel_faction(parcelpos)
end

function factions.faction_tick()
    local now = os.time()
    for facname, i in factions.factions.iterate() do
        local faction = factions.factions.get(facname)
		
		if faction ~= nil then
			if factions.is_online(facname) then
				if factions_config.enable_power_per_player then
					local count = 0
					for _ in pairs(factions.onlineplayers[facname]) do count = count + 1 end
					factions.increase_power(facname, factions_config.power_per_player * count)
				else
					factions.increase_power(facname, factions_config.power_per_tick)
				end
			end
			if now - faction.last_logon > factions_config.maximum_faction_inactivity or (faction.no_parcel ~= -1 and now - faction.no_parcel > factions_config.maximum_parcelless_faction_time)  then
				local r = ""
				if now - faction.last_logon > factions_config.maximum_faction_inactivity  then
					r = "inactivity"
				else
					r = "no parcel claims"
				end
				factions.disband(facname, r)
			end
		end
    end
end

function factionUpdate()
	factions.faction_tick()
	minetest.after(factions_config.tick_time, factionUpdate)
end
