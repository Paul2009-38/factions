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
        --! @brief access table
        access = {players = {}, factions = {}},
    }
    return table
end

-- Create a empty ip table.
function factions.create_ip_table() 
    local table = {
        ip = ""
    }
    return table
end

-- Create a empty player table.
function factions.create_player_table() 
    local table = {
        faction = ""
    }
    return table
end

-- Create a empty claim table.
function factions.create_parcel_table() 
    local table = {
        faction = ""
    }
    return table
end

-- helper functions
function factions.db_is_empty(table)
    for k, v in pairs(table) do
        return false
    end
    return true
end

function factions.remove_key(db, db_name, db_data, key, write)
    if not db_data then
        db_data = db.get(db_name)
    end

    db_data[key] = nil

    if factions.db_is_empty(db_data) then
        db.remove(db_name)
        return nil
    end

    if write then
        db.set(db_name, db_data)
    end
    
    return db_data
end

-- faction data check on load
local function update_data(db, db_name, db_data, empty_table, write)
    local needs_update = false

    if not db_data then
        db_data = db.get(db_name)
    end

    for k, v in pairs(empty_table) do
        if db_data[k] == nil then
            db_data[k] = v
            needs_update = true
            minetest.log("Adding property " .. k .. " to " .. db_name .. " file.")
        end
    end

    if write and needs_update then
        db.set(db_name, db_data)
    end
    
    return db_data
end

minetest.register_on_mods_loaded(function()
    minetest.log("Checking faction files.")
    for k, v in factions.factions.iterate() do
        update_data(factions.factions, k, nil, factions.create_faction_table(), true)
    end

    minetest.log("Checking parcel files.")
    for k, v in factions.parcels.iterate() do
        update_data(factions.parcels, k, nil, factions.create_parcel_table(), true)
    end

    minetest.log("Checking player files.")
    for k, v in factions.players.iterate() do
        update_data(factions.players, k, nil, factions.create_player_table(), true)
    end

    minetest.log("Checking ip files.")
    for k, v in factions.player_ips.iterate() do
        update_data(factions.player_ips, k, nil, factions.create_ip_table(), true)
    end
end)
