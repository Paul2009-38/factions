--! @class factions
--! @brief main class for factions
factions = {}

-- Create cold databases.
factions.factions = colddb.Colddb("factions/factions")
factions.parcels = colddb.Colddb("factions/parcels")
factions.players = colddb.Colddb("factions/players")
factions.player_ips = colddb.Colddb("factions/ips")

-- Memory only storage.
factions.onlineplayers = {}

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
						, "player_title", "spawn", "with_draw", "territory", "claim", "access", "disband", "flags", "ranks", "promote"},
                 ["moderator"] = {"claim", "door", "build", "spawn", "invite", "kick", "promote"},
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
-- player_title: set player titles
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
						, "player_title", "spawn", "with_draw", "territory", "claim", "access", "disband", "flags", "ranks", "promote"}
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

function factions.start_diplomacy(name, faction)
	for l, i in pairs(factions.get_faction_list()) do
		local fac = factions.factions.get(i)
		if i ~= name and not (faction.neutral[i] or faction.allies[i] or faction.enemies[i]) then
			if factions_config.faction_diplomacy == true then
				factions.new_neutral(name, i)
				factions.new_neutral(i, name)
			else
				factions.new_enemy(name, i)
				factions.new_enemy(i, name)
			end
		end
	end
end

function factions.set_name(oldname, name)
	local faction = factions.factions.get(oldname)
	faction.name = name
	
	for i, v in pairs(factions.get_faction_list()) do
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

function factions.increase_power(name, power)
	local faction = factions.factions.get(name)
	
    faction.power = faction.power + power
	
    if faction.power > faction.maxpower  - faction.usedpower then
        faction.power = faction.maxpower - faction.usedpower
    end
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
    
	factions.factions.set(name, faction)
end

function factions.decrease_power(name, power)
    local faction = factions.factions.get(name)
	
	faction.power = faction.power - power
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
    
	factions.factions.set(name, faction)
end

function factions.increase_maxpower(name, power)
    local faction = factions.factions.get(name)
	
	faction.maxpower = faction.maxpower + power
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
    
	factions.factions.set(name, faction)
end

function factions.decrease_maxpower(name, power)
    local faction = factions.factions.get(name)
	
	faction.maxpower = faction.maxpower - power
	
    if faction.maxpower < 0. then -- should not happen
        faction.maxpower = 0.
    end
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
	
	factions.factions.set(name, faction)
end

function factions.increase_usedpower(name, power)
	local faction = factions.factions.get(name)

    faction.usedpower = faction.usedpower + power
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
	
	factions.factions.set(name, faction)
end

function factions.decrease_usedpower(name, power)
   local faction = factions.factions.get(name)
   
   faction.usedpower = faction.usedpower - power
    if faction.usedpower < 0. then
        faction.usedpower = 0.
    end
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
	
	factions.factions.set(name, faction)
end

function factions.count_land(name)
    local count = 0.
    for k, v in pairs(factions.factions.get(name).land) do
        count = count + 1
    end
    return count
end

minetest.register_on_prejoinplayer(function(name, ip)
	factions.player_ips.set(name, ip)
end)

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
		local ipc = pdata:is_player_connected(player)
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
		local ipc = pdata:is_player_connected(player)
		
		if ipc then
			removeHud(pdata,"factionName")
			removeHud(pdata,"powerWatch")
		end
	end
	
	factions.check_players_in_faction(name)
end

local parcel_size = factions_config.parcel_size

--! @param parcelpos position of the wanted parcel
--! @return whether this faction can claim a parcelpos
function factions.can_claim_parcel(name, parcelpos)
    local fn = factions.parcels.get(parcelpos)
	
	if fn == nil then
		return true
	end
	
	local faction = factions.factions.get(name)
	
	if fn then
		local fac = factions.factions.get(fn)
		
        if fac.power < 0. and faction.power >= factions_config.power_per_parcel and not faction.allies[fn] and not faction.neutral[fn] then
            return true
        else
            return false
        end
    elseif faction.power < factions_config.power_per_parcel then
        return false
    end
	
    return true
end

--! @brief claim a parcel, update power and update global parcels table
function factions.claim_parcel(name, parcelpos)
    -- check if claiming over other faction's territory
    local otherfac = factions.parcels.get(parcelpos)
    if otherfac then
        factions.unclaim_parcel(otherfac, parcelpos)
		factions.parcelless_check(otherfac)
    end
    factions.parcels.set(parcelpos, name)
	
	local faction = factions.factions.get(name)
	
    faction.land[parcelpos] = true
	
	factions.factions.set(name, faction)
	
    factions.decrease_power(name, factions_config.power_per_parcel)
    factions.increase_usedpower(name, factions_config.power_per_parcel)
    factions.on_claim_parcel(name, parcelpos)
	factions.parcelless_check(name)
end

--! @brief claim a parcel, update power and update global parcels table
function factions.unclaim_parcel(name, parcelpos)
    factions.parcels.remove(parcelpos)
	
	local faction = factions.factions.get(name)
	
    faction.land[parcelpos] = nil
	
	factions.factions.set(name, faction)
	
    factions.increase_power(name, factions_config.power_per_parcel)
    factions.decrease_usedpower(name, factions_config.power_per_parcel)
    factions.on_unclaim_parcel(name, parcelpos)
	factions.parcelless_check(name)
end

function factions.parcelless_check(name)
	local faction = factions.factions.get(name)
	
	if faction.land then
		local count = 0
		for index, value in pairs(faction.land) do
			count = count + 1
			break
		end
		if count > 0 then
			if faction.no_parcel ~= -1 then
				factions.broadcast(name, "Faction " .. name .. " will not be disbanded because it now has parcels.")
			end
			faction.no_parcel = -1
		else
			faction.no_parcel = os.time()
			factions.on_no_parcel(name)
		end
		factions.factions.set(name, faction)
	end
end

--! @brief disband faction, updates global players and parcels table
function factions.disband(name, reason)
	local faction = factions.factions.get(name)
	
	if not faction.is_admin then
		for i, v in pairs(factions.get_faction_list()) do
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
		
		for i, l in pairs(factions.onlineplayers[name]) do
			removeHud(i, "factionName")
			removeHud(i, "powerWatch")
		end
		
		factions.onlineplayers[name] = nil
		
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

--! @brief places player in invite list
function factions.invite_player(name, player)
	local faction = factions.factions.get(name)

    faction.invited_players[player] = true
    factions.on_player_invited(name, player)
    
	factions.factions.set(name, faction)
end

--! @brief removes player from invite list (can no longer join via /f join)
function factions.revoke_invite(name, player)
    local faction = factions.factions.get(name)
	
	faction.invited_players[player] = nil
    factions.on_revoke_invite(name, player)
    
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

function factions.new_alliance(name, faction)
	local bfaction = factions.factions.get(name)
	
    bfaction.allies[faction] = true
    factions.on_new_alliance(name, faction)
    if bfaction.enemies[faction] then
        factions.end_enemy(name, faction)
    end
	if bfaction.neutral[faction] then
        factions.end_neutral(name, faction)
    end
    
	factions.factions.set(name, bfaction)
end

function factions.end_alliance(name, faction)
    local bfaction = factions.factions.get(name)
	
	bfaction.allies[faction] = nil
    factions.on_end_alliance(name, faction)
    
	factions.factions.set(name, bfaction)
end

function factions.new_neutral(name, faction)
	local bfaction = factions.factions.get(name)
	
    bfaction.neutral[faction] = true
    
	factions.on_new_neutral(name, faction)
    if bfaction.allies[faction] then
        factions.end_alliance(name, faction)
    end
    if bfaction.enemies[faction] then
        factions.end_enemy(name, faction)
    end
    
	factions.factions.set(name, bfaction)
end

function factions.end_neutral(name, faction)
    local bfaction = factions.factions.get(name)
	
	bfaction.neutral[faction] = nil
    factions.on_end_neutral(name, faction)
    
	factions.factions.set(name, bfaction)
end

function factions.new_enemy(name, faction)
	local bfaction = factions.factions.get(name)
	
	bfaction.enemies[faction] = true
    factions.on_new_enemy(name, faction)
	
    if bfaction.allies[faction] then
        factions.end_alliance(name, faction)
    end
	
	if bfaction.neutral[faction] then
        factions.end_neutral(name, faction)
    end
    
	factions.factions.set(name, bfaction)
end

function factions.end_enemy(name, faction)
    local bfaction = factions.factions.get(name)
	
	bfaction.enemies[faction] = nil
    factions.on_end_enemy(name, faction)
    
	factions.factions.set(name, bfaction)
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
		minetest.sound_play("whoosh", {pos = faction.spawn, gain = 0.5, max_hear_distance = 10})
	end
end

--! @brief create a new rank with permissions
--! @param rank the name of the new rank
--! @param rank a list with the permissions of the new rank
function factions.add_rank(name, rank, perms)
    local faction = factions.factions.get(name)
	
	faction.ranks[rank] = perms
    factions.on_add_rank(name, rank)
    
	factions.factions.set(name, faction)
end

--! @brief replace an rank's permissions
--! @param rank the name of the rank to edit
--! @param add or remove permissions to the rank
function factions.replace_privs(name, rank, perms)
    local faction = factions.factions.get(name)
	
	faction.ranks[rank] = perms
    factions.on_replace_privs(name, rank)
    
	factions.factions.set(name, faction)
end

function factions.remove_privs(name, rank, perms)
	local faction = factions.factions.get(name)
	
	local revoked = false
	local p = faction.ranks[rank]
	
	for index, perm in pairs(p) do
		if table_Contains(perms, perm) then
			revoked = true
			table.remove(p, index)
		end
	end
	
	faction.ranks[rank] = p
	
	if revoked then
		factions.on_remove_privs(name, rank, perms)
	else
		factions.broadcast(name, "No privilege was revoked from rank " .. rank .. ".")
	end
    
	factions.factions.set(name, faction)
end

function factions.add_privs(name, rank, perms)
	local faction = factions.factions.get(name)
	
	local added = false
	local p = faction.ranks[rank]
	
	for index, perm in pairs(perms) do
		if not table_Contains(p, perm) then
			added = true
			table.insert(p, perm)
		end
	end
	
	faction.ranks[rank] = p
	
	if added then
		factions.on_add_privs(name, rank, perms)
	else
		factions.broadcast(name, "The rank " .. rank .. " already has these privileges.")
	end
    
	factions.factions.set(name, faction)
end

function factions.set_rank_name(name, oldrank, newrank)
	local faction = factions.factions.get(name)
	
	local copyrank = faction.ranks[oldrank]
	
	faction.ranks[newrank] = copyrank
	faction.ranks[oldrank] = nil
	
	for player, r in pairs(faction.players) do
        if r == oldrank then
            faction.players[player] = newrank
        end
    end
	
	if oldrank == faction.default_leader_rank then
		faction.default_leader_rank = newrank
		factions.broadcast(name, "The default leader rank has been set to " .. newrank)
	end
	
	if oldrank == faction.default_rank then
		faction.default_rank = newrank
		factions.broadcast(name, "The default rank given to new players is set to " .. newrank)
	end
	
    factions.on_set_rank_name(name, oldrank, newrank)
    
	factions.factions.set(name, faction)
end

function factions.set_def_rank(name, rank)
	local faction = factions.factions.get(name)

    for player, r in pairs(faction.players) do
        if r == rank or r == nil or not faction.ranks[r] then
            faction.players[player] = rank
        end
    end
	
	faction.default_rank = rank
	factions.on_set_def_rank(name, rank)
    
	factions.factions.set(name, faction)
end

function factions.reset_ranks(name)
	local faction = factions.factions.get(name)

	faction.ranks = starting_ranks
	faction.default_rank = "member"
	faction.default_leader_rank_rank = "leader"
    for player, r in pairs(faction.players) do
        if not player == leader and (r == nil or not faction.ranks[r]) then
            faction.players[player] = faction.default_rank
		elseif player == leader then
			faction.players[player] = faction.default_leader_rank_rank
        end
    end
	factions.on_reset_ranks(name)
    
	factions.factions.set(name, faction)
end

--! @brief delete a rank and replace it
--! @param rank the name of the rank to be deleted
--! @param newrank the rank given to players who were previously "rank"
function factions.delete_rank(name, rank, newrank)
	local faction = factions.factions.get(name)

    for player, r in pairs(faction.players) do
        if r == rank then
            faction.players[player] = newrank
        end
    end
    faction.ranks[rank] = nil
    factions.on_delete_rank(name, rank, newrank)
	if rank == faction.default_leader_rank then
		faction.default_leader_rank = newrank
		factions.broadcast(name, "The default leader rank has been set to "..newrank)
	end
	if rank == faction.default_rank then
		faction.default_rank = newrank
		factions.broadcast(name, "The default rank given to new players is set to "..newrank)
	end
    
	factions.factions.set(name, faction)
end

--! @brief set a player's rank
function factions.promote(name, member, rank)
    local faction = factions.factions.get(name)
	
	faction.players[member] = rank
    factions.on_promote(name, member)
	
	factions.factions.set(name, faction)
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

--------------------------
-- callbacks for events --

function factions.on_create(name)  --! @brief called when the faction is added to the global faction list
    minetest.chat_send_all("Faction " .. name .. " has been created.")
end

function factions.on_set_name(name, oldname)
    minetest.chat_send_all("Faction " .. oldname .. " has been changed its name to ".. name ..".")
end

function factions.on_no_parcel(name)
	local faction = factions.factions.get(name)

	local now = os.time() - faction.no_parcel
	local l = factions_config.maximum_parcelless_faction_time
	
    factions.broadcast(name, "This faction will disband in " .. l - now .. " seconds, because it has no parcels.")
end

function factions.on_player_leave(name, player)
    factions.broadcast(name, player .. " has left this faction")
end

function factions.on_player_join(name, player)
    factions.broadcast(name, player .. " has joined this faction")
end

function factions.on_claim_parcel(name, pos)
    factions.broadcast(name, "Parcel (" .. pos .. ") has been claimed.")
end

function factions.on_unclaim_parcel(name, pos)
    factions.broadcast(name, "Parcel ("..pos..") has been unclaimed.")
end

function factions.on_disband(name, reason)
    local msg = "Faction " .. name .. " has been disbanded."
    if reason then
        msg = msg .. " (" .. reason .. ")"
    end
    minetest.chat_send_all(msg)
end

function factions.on_new_leader(name)
    local faction = factions.factions.get(name)
	factions.broadcast(name, faction.leader .. " is now the leader of this faction")
end

function factions.on_change_description(name)
    local faction = factions.factions.get(name)
	factions.broadcast(name, "Faction description has been modified to: " .. faction.description)
end

function factions.on_player_invited(name, player)
    local faction = factions.factions.get(name)
	minetest.chat_send_player(player, "You have been invited to faction " .. faction.name)
end

function factions.on_toggle_join_free(name, player)
    local faction = factions.factions.get(name)
	if faction.join_free then
        factions.broadcast(name, "This faction is now invite-free.")
    else
        factions.broadcast(name, "This faction is no longer invite-free.")
    end
end

function factions.on_new_alliance(name, faction)
    factions.broadcast(name, "This faction is now allied with " .. faction)
end

function factions.on_end_alliance(name, faction)
    factions.broadcast(name, "This faction is no longer allied with " .. faction .. "!")
end

function factions.on_new_neutral(name, faction)
    factions.broadcast(name, "This faction is now neutral with ".. faction)
end

function factions.on_end_neutral(name, faction)
    factions.broadcast(name, "This faction is no longer neutral with " .. faction .. "!")
end

function factions.on_new_enemy(name, faction)
    factions.broadcast(name, "This faction is now at war with " .. faction)
end

function factions.on_end_enemy(name, faction)
    factions.broadcast(name, "This faction is no longer at war with " .. faction .. "!")
end

function factions.on_set_spawn(name)
	local faction = factions.factions.get(name)
    factions.broadcast(name, "The faction spawn has been set to (" .. util.coords3D_string(faction.spawn) .. ").")
end

function factions.on_add_rank(name, rank)
	local faction = factions.factions.get(name)
    factions.broadcast(name, "The rank " .. rank .. " has been created with privileges: " .. table.concat(faction.ranks[rank], ", "))
end

function factions.on_replace_privs(name, rank)
	local faction = factions.factions.get(name)
    factions.broadcast(name, "The privileges in rank " .. rank .. " have been delete and changed to: " .. table.concat(faction.ranks[rank], ", "))
end

function factions.on_remove_privs(name, rank, privs)
    factions.broadcast(name, "The privileges in rank " .. rank .. " have been revoked: " .. table.concat(privs, ", "))
end

function factions.on_add_privs(name, rank, privs)
    factions.broadcast(name, "The privileges in rank " .. rank .. " have been added: " .. table.concat(privs, ", "))
end

function factions.on_set_rank_name(name, rank,newrank)
    factions.broadcast(name, "The name of rank " .. rank .. " has been changed to " .. newrank)
end

function factions.on_delete_rank(name, rank, newrank)
    factions.broadcast(name, "The rank " .. rank .. " has been deleted and replaced by " .. newrank)
end

function factions.on_set_def_rank(name, rank)
    factions.broadcast(name, "The default rank given to new players has been changed to " .. rank)
end

function factions.on_reset_ranks(name)
    factions.broadcast(name, "All of the faction's ranks have been reset to the default ones.")
end

function factions.on_promote(name, member)
	local faction = factions.factions.get(name)
    minetest.chat_send_player(member, "You have been promoted to " .. faction.players[member])
end

function factions.on_revoke_invite(name, player)
    minetest.chat_send_player(player, "You are no longer invited to faction " .. name)
end

function factions.get_parcel_pos(pos)
	if factions_config.protection_style == "2d" then
		return math.floor(pos.x / parcel_size) * parcel_size .. "," .. math.floor(pos.z / parcel_size) * parcel_size
	elseif factions_config.protection_style == "3d" then
		return math.floor(pos.x / parcel_size) * parcel_size .. "," .. math.floor(pos.y / parcel_size) * parcel_size .. "," .. math.floor(pos.z / parcel_size) * parcel_size
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

function factions.get_parcel_faction(parcelpos)
    local facname = factions.parcels.get(parcelpos)
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

function factions.get_faction_list()

	local names = {}
	local directory = string.format("%s/factions/factions", minetest.get_worldpath())
	local nameslist = minetest.get_dir_list(directory)
	for k, v in pairs(nameslist) do
		names[#names + 1] = v:sub(0, v:len() - 5)
	end

    return names
end

minetest.register_on_dieplayer(
function(player)
    local faction, name = factions.get_player_faction(player:get_player_name())
    if not faction then
        return true
    end
    factions.decrease_power(name, factions_config.power_per_death)
    return true
end
)

function factions.faction_tick()
    local now = os.time()
    for i, facname in pairs(factions.get_faction_list()) do
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

minetest.register_on_joinplayer(
function(player)
	local name = player:get_player_name()
	minetest.after(5, createHudfactionLand, player)
    local faction, facname = factions.get_player_faction(name)
    if faction then
		if factions.onlineplayers[facname] == nil then
			factions.onlineplayers[facname] = {}
		end
		
		factions.onlineplayers[facname][name] = true
        faction.last_logon = os.time()
		
		factions.factions.set(facname, faction)
		
		minetest.after(5, createHudFactionName, player, facname)
		minetest.after(5, createHudPower, player, faction)
		
		if faction.no_parcel ~= -1 then
			local now = os.time() - faction.no_parcel
			local l = factions_config.maximum_parcelless_faction_time
			minetest.chat_send_player(name, "This faction will disband in " .. l - now .. " seconds, because it has no parcels.")
		end
		
		if factions.has_permission(facname, name, "diplomacy") then
			for _ in pairs(faction.request_inbox) do minetest.chat_send_player(name, "You have diplomatic requests in the inbox.") break end
		end
		
		if faction.message_of_the_day and (faction.message_of_the_day ~= "" or faction.message_of_the_day ~= " ") then
			minetest.chat_send_player(name, faction.message_of_the_day)
		end
    end
	
end
)

minetest.register_on_leaveplayer(
	function(player)
		local name = player:get_player_name()
		local faction, facname = factions.get_player_faction(name)
		local id_name1 = name .. "factionLand"
		
		if hud_ids[id_name1] then
			hud_ids[id_name1] = nil
		end
		
		if faction then
			factions.onlineplayers[facname][name] = nil
			local id_name2 = name .. "factionName"
			local id_name3 = name .. "powerWatch"
			if hud_ids[id_name2] then
				hud_ids[id_name2] = nil
			end
			if hud_ids[id_name3] then
				hud_ids[id_name3] = nil
			end
			for k, v in pairs(factions.onlineplayers[facname]) do
				return
			end
			factions.onlineplayers[facname] = nil
		end
	end
)

minetest.register_on_respawnplayer(
    function(player)
        local faction, facname = factions.get_player_faction(player:get_player_name())
        
		if not faction then
            return false
        else
            if not faction.spawn then
                return false
            else
                player:set_pos(faction.spawn)
                return true
            end
        end
    end
)

local default_is_protected = minetest.is_protected
minetest.is_protected = function(pos, player)
    local y = pos.y
	
    if factions_config.protection_depth_height_limit and (pos.y < factions_config.protection_max_depth or pos.y > factions_config.protection_max_height) then
        return false
    end

    local parcelpos = factions.get_parcel_pos(pos)
    local parcel_faction, parcel_fac_name = factions.get_parcel_faction(parcelpos)
    local player_faction, player_fac_name = factions.get_player_faction(player)
	
    -- no faction
    if not parcel_faction then
        return default_is_protected(pos, player)
    elseif player_faction then
        if parcel_faction.name == player_faction.name then
			if factions.has_permission(parcel_fac_name, player, "pain_build") then
				local p = minetest.get_player_by_name(player)
				p:set_hp(p:get_hp() - 0.5)
			end
            return not (factions.has_permission(parcel_fac_name, player, "build") or factions.has_permission(parcel_fac_name, player, "pain_build"))
        elseif parcel_faction.allies[player_faction.name] then
			if factions.has_permission(player_fac_name, player, "pain_build") then
				local p = minetest.get_player_by_name(player)
				p:set_hp(p:get_hp() - 0.5)
			end
			return not (factions.has_permission(player_fac_name, player, "build") or factions.has_permission(player_fac_name, player, "pain_build"))
		else
			return true
        end
    else
        return true
    end
end

function factionUpdate()
	factions.faction_tick()
	minetest.after(factions_config.tick_time, factionUpdate)
end
