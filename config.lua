factions_config = {}

factions_config.protection_max_depth = tonumber(minetest.setting_get("protection_max_depth")) or -512
factions_config.power_per_parcel = tonumber(minetest.setting_get("power_per_parcel")) or 0.5
factions_config.power_per_death = tonumber(minetest.setting_get("power_per_death")) or 0.25
factions_config.power_per_tick = tonumber(minetest.setting_get("power_per_tick")) or 0.125
factions_config.tick_time = tonumber(minetest.setting_get("tick_time")) or 60
factions_config.power_per_attack = tonumber(minetest.setting_get("power_per_attack")) or 10
factions_config.faction_name_max_length = tonumber(minetest.setting_get("faction_name_max_length")) or 50
factions_config.rank_name_max_length = tonumber(minetest.setting_get("rank_name_max_length")) or 25
factions_config.maximum_faction_inactivity = tonumber(minetest.setting_get("maximum_faction_inactivity")) or 604800
factions_config.maximum_parcelless_faction_time = tonumber(minetest.setting_get("maximum_parcelless_faction_time")) or 10800
factions_config.power = tonumber(minetest.setting_get("power")) or 0
factions_config.maxpower = tonumber(minetest.setting_get("maxpower")) or 0
factions_config.power_per_player = tonumber(minetest.setting_get("power_per_player")) or 2.
factions_config.enable_power_per_player = minetest.settings:get_bool("power_per_playerb") or true
factions_config.attack_parcel = minetest.settings:get_bool("attack_parcel") or false
factions_config.faction_diplomacy = minetest.settings:get_bool("faction_diplomacy") or true
--[[
factions_config.protection_max_depth = -512
factions_config.power_per_parcel = 0.5
factions_config.power_per_death = 0.25
factions_config.power_per_tick = 0.125
factions_config.tick_time = 60
factions_config.power_per_attack = 10
factions_config.faction_name_max_length = 50
factions_config.rank_name_max_length = 25
factions_config.maximum_faction_inactivity = 604800
factions_config.maximum_parcelless_faction_time = 10800
factions_config.power = 0
factions_config.maxpower = 0
factions_config.power_per_player = 2
factions_config.enable_power_per_player = true
factions_config.attack_parcel = false
factions_config.faction_diplomacy = true
--]]