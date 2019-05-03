local on_death = {}

minetest.register_on_prejoinplayer(function(name, ip)
	factions.player_ips.set(name, ip)
end)

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
			on_death[name] = nil
		end
	end
)

minetest.register_on_respawnplayer(
    function(player)
        local name = player:get_player_name()
		local faction, facname = factions.get_player_faction(name)
        
		if not faction then
            return false
        else
			on_death[name] = nil
            if not faction.spawn then
                return false
            else
                player:set_pos(faction.spawn)
                return true
            end
        end
    end
)

minetest.register_on_dieplayer(
function(player)
	local pname = player:get_player_name()
	if on_death[pname] then
		return
	end
    local faction, name = factions.get_player_faction(pname)
    if not faction then
        return
    end
    factions.decrease_power(name, factions_config.power_per_death)
	on_death[pname] = true
    return
end
)
