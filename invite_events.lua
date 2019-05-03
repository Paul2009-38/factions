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
