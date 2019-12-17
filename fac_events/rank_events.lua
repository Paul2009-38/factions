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
