function ip_convert()
	local path = minetest.get_worldpath() .. "/factions_iplist.txt"
    local file, error = io.open(path, "r")

    if file ~= nil then
        local raw_data = file:read("*a")
        local ips = minetest.deserialize(raw_data)
		file:close()
		
		for i, k in pairs(ips) do
			factions.player_ips.set(i, k)
		end
		
		os.rename(path, minetest.get_worldpath() .. "/factions_iplist_old.txt")
    end
end

function faction_convert()
	local path = minetest.get_worldpath() .. "/factions.conf"
    local file, error = io.open(path, "r")

    if file ~= nil then
        local raw_data = file:read("*a")
        local tabledata = minetest.deserialize(raw_data)
		file:close()
		
		if tabledata then
			for facname, faction in pairs(tabledata) do
				factions.factions.set(facname, faction)
				
				for player, rank in pairs(faction.players) do
					factions.players.set(player, facname)
				end
				
				for parcelpos, val in pairs(faction.land) do
					factions.parcels.set(parcelpos, facname)
				end
			end
			os.rename(path, minetest.get_worldpath() .. "/factions_old.txt")
		end
    end
end

ip_convert()
faction_convert()
