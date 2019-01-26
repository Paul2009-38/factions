--!path of mod
factions_modpath = minetest.get_modpath("factions")

dofile (factions_modpath .. "/config.lua")
dofile (factions_modpath .. "/hud.lua")
dofile (factions_modpath .. "/factions.lua")
dofile (factions_modpath .. "/chatcommands.lua")
dofile (factions_modpath .. "/nodes.lua")
dofile (factions_modpath .. "/convert.lua")

minetest.after(1, hudUpdateClaimInfo)
minetest.after(factions_config.tick_time, factionUpdate)
