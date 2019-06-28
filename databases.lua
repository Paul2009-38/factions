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

-- Table hook functions.

-- Hook function to add or delete from the faction table.
function factions.on_create_faction_table(table)
    return table
end

-- Hook function to add or delete from the ip table.
function factions.on_create_ip_table(table)
    return table
end

-- Hook function to add or delete from the player table.
function factions.on_create_player_table(table)
    return table
end

-- Hook function to add or delete from the claim table.
function factions.on_create_claim_table(table)
    return table
end

-- Table creation.

-- Create a empty faction.
function factions.create_faction_table() 
    local table = {
		name = "",
        --! @brief power of a faction (needed for parcel claiming)
        power = factions_config.power,
        --! @brief maximum power of a faction
        maxpower = factions_config.maxpower,
        --! @brief power currently in use
        usedpower = 0.,
        --! @brief list of player names
        players = {},
        --! @brief table of ranks/permissions
        ranks = starting_ranks,
        --! @brief name of the leader
        leader = nil,
		--! @brief spawn of the faction
		spawn = {x = 0, y = 0, z = 0},
        --! @brief default joining rank for new members
        default_rank = "member",
        --! @brief default rank assigned to the leader
        default_leader_rank = "leader",
        --! @brief faction's description string
        description = "Default faction description.",
		--! @brief faction's message of the day.
		message_of_the_day = "",
        --! @brief list of players currently invited (can join with /f join)
        invited_players = {},
        --! @brief table of claimed parcels (keys are parcelpos strings)
        land = {},
        --! @brief table of allies
        allies = {},
		--
		request_inbox = {},
        --! @brief table of enemies
        enemies = {},
		--!
		neutral = {},
        --! @brief table of parcels/factions that are under attack
        attacked_parcels = {},
        --! @brief whether faction is closed or open (boolean)
        join_free = false,
        --! @brief gives certain privileges
        is_admin = false,
        --! @brief last time anyone logged on
        last_logon = os.time(),
		--! @brief how long this has been without parcels
		no_parcel = os.time(),
    }
    return factions.on_create_faction_table(table)
end

-- Create a empty ip table.
function factions.create_ip_table() 
    local table = {
        ip = ""
    }
    return factions.on_create_ip_table(table)
end

-- Create a empty player table.
function factions.create_player_table() 
    local table = {
        faction = ""
    }
    return factions.on_create_player_table(table)
end

-- Create a empty claim table.
function factions.create_claim_table() 
    local table = {
        faction = ""
    }
    return factions.on_create_claim_table(table)
end
