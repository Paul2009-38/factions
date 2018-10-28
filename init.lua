--!path of mod
factions_modpath = minetest.get_modpath("factions")

dofile (factions_modpath .. "/config.lua")
dofile (factions_modpath .. "/misc_mod_data.lua")
dofile (factions_modpath .. "/hud.lua")
dofile (factions_modpath .. "/ip.lua")
dofile (factions_modpath .. "/factions.lua")
dofile (factions_modpath .. "/chatcommands.lua")
dofile (factions_modpath .. "/nodes.lua")

factions.load()
misc_mod_data.check_file()