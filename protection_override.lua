local default_is_protected = minetest.is_protected

minetest.is_protected = function(pos, player)
    if minetest.check_player_privs(player, "protection_bypass") then
        return default_is_protected(pos, player)
    end
    
    local y = pos.y
	
    if factions_config.protection_depth_height_limit and (pos.y < factions_config.protection_max_depth or pos.y > factions_config.protection_max_height) then
        return default_is_protected(pos, player)
    end

    local parcelpos = factions.get_parcel_pos(pos)
    local parcel_faction, parcel_fac_name = factions.get_parcel_faction(parcelpos)
    local player_faction
    local player_fac_name

    if player then
        player_faction, player_fac_name = factions.get_player_faction(player)
    end
	
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
    return default_is_protected(pos, player)
end
