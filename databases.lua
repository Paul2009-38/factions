--! @class factions
--! @brief main class for factions
factions = {}

-- Create cold databases.
factions.factions = colddb.Colddb(minetest.get_worldpath() .. "/factions/factions")
factions.parcels = colddb.Colddb(minetest.get_worldpath() .. "/factions/parcels")
factions.players = colddb.Colddb(minetest.get_worldpath() .. "/factions/players")
factions.player_ips = colddb.Colddb(minetest.get_worldpath() .. "/factions/ips")

-- Memory only storage.
factions.onlineplayers = {}
