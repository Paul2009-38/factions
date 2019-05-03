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
