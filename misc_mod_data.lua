misc_mod_data = {}
misc_mod_data.data = {factions_version = "0.8.1",config = factions_config}

--read some basic information
local factions_worldid = minetest.get_worldpath()

function misc_mod_data.save()
    local file,error = io.open(factions_worldid .. "/" .. "factions_misc_mod_data.txt","w")

    if file ~= nil then
        file:write(minetest.serialize(misc_mod_data.data))
        file:close()
    else
        minetest.log("error","MOD factions: unable to save factions misc mod data!: " .. error)
    end
end

function misc_mod_data.load()
    local file,error = io.open(factions_worldid .. "/" .. "factions_misc_mod_data.txt","r")

    if file ~= nil then
        local raw_data = file:read("*a")
        misc_mod_data.data = minetest.deserialize(raw_data)
        file:close()
	else
		misc_mod_data.save()
    end
end

function misc_mod_data.check_file()
    local file,error = io.open(factions_worldid .. "/" .. "factions_misc_mod_data.txt","r")

    if file ~= nil then
        file:close()
	else
		misc_mod_data.save()
    end
end