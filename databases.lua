--! @class factions
--! @brief main class for factions
factions = {}

-- Create cold databases.
factions.root = colddb.Colddb(minetest.get_worldpath() .. "/factions")
factions.factions = factions.root.sub_database("factions")
factions.parcels = factions.root.sub_database("parcels")
factions.players = factions.root.sub_database("players")
factions.player_ips = factions.root.sub_database("ips")

-- Memory only storage.
factions.onlineplayers = {}
