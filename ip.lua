factions_ip = {}
factions_ip.player_ips = {}

--read some basic information
local factions_worldid = minetest.get_worldpath()

function factions_ip.save()
	if not minetest.safe_file_write(factions_worldid .. "/" .. "factions_iplist.txt", minetest.serialize(factions_ip.player_ips)) then
		minetest.log("error","MOD factions: unable to save faction player ips!: " .. error)
	end
end

function factions_ip.load()
    local file,error = io.open(factions_worldid .. "/" .. "factions_iplist.txt","r")

    if file ~= nil then
        local raw_data = file:read("*a")
        factions_ip.player_ips = minetest.deserialize(raw_data)
        file:close()
	else
		factions_ip.save()
    end
end