local def_global_privileges = nil
if factions_config.faction_user_priv == true then
    def_global_privileges = {"faction_user"}
end

factions.register_command ({"claim o", "claim one"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		return claim_helper(player, faction, parcelpos)
    end
})
factions.register_command ({"claim a", "claim auto"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.claim_auto(player, faction)
    end
})
factions.register_command ({"claim f", "claim fill"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.claim_fill(player, faction)
    end
})
factions.register_command ({"claim s", "claim square"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    format = {"string"},
    on_success = function(player, faction, pos, parcelpos, args)
		local arg = args.strings[1]
        if arg then
            local r = tonumber(arg)
            if not r then
                minetest.chat_send_player(player, "Only use numbers in the second cmd parameter [0-9].")
                return
            end
            factions.claim_square(player, faction, r)
        else
            factions.claim_square(player, faction, 3)
        end
    end
})
factions.register_command ({"claim c", "claim circle"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    format = {"string"},
    on_success = function(player, faction, pos, parcelpos, args)
		local arg = args.strings[1]
        if arg then
            local r = tonumber(arg)
            if not r then
                minetest.chat_send_player(player, "Only use numbers in the second cmd parameter [0-9].")
                return
            end
            factions.claim_circle(player, faction, r)
        else
            factions.claim_circle(player, faction, 3)
        end
    end
})
factions.register_command ("claim all", {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.claim_all(player, faction)
    end
})
factions.register_command ({"claim l", "claim list"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
        local aclaims = "All claims:\n"
        for i in pairs(faction.land) do
            aclaims = aclaims .. i .. "\n"
        end
        minetest.chat_send_player(player, aclaims)
    end
})
factions.register_command ({"claim h", "claim help"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.claim_help(player, arg_two)
    end
})

factions.register_command ({"unclaim o", "unclaim one"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		return unclaim_helper(player, faction, parcelpos)
    end
})
factions.register_command ({"unclaim a", "unclaim auto"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.unclaim_auto(player, faction)
    end
})
factions.register_command ({"unclaim f", "unclaim fill"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.unclaim_fill(player, faction)
    end
})
factions.register_command ({"unclaim s", "unclaim square"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    format = {"string"},
    on_success = function(player, faction, pos, parcelpos, args)
		local arg = args.strings[1]
        if arg then
            local r = tonumber(arg)
            if not r then
                minetest.chat_send_player(player, "Only use numbers in the second cmd parameter [0-9].")
                return
            end
            factions.unclaim_square(player, faction, r)
        else
            factions.unclaim_square(player, faction, 3)
        end
    end
})
factions.register_command ({"unclaim c", "unclaim circle"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    format = {"string"},
    on_success = function(player, faction, pos, parcelpos, args)
		local arg = args.strings[1]
        if arg then
            local r = tonumber(arg)
            if not r then
                minetest.chat_send_player(player, "Only use numbers in the second cmd parameter [0-9].")
                return
            end
            factions.unclaim_circle(player, faction, r)
        else
            factions.unclaim_circle(player, faction, 3)
        end
    end
})
factions.register_command ("unclaim all", {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.unclaim_all(player, faction)
    end
})
factions.register_command ({"unclaim l", "unclaim list"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
        local aclaims = "All claims:\n"
        for i in pairs(faction.land) do
            aclaims = aclaims .. i .. "\n"
        end
        minetest.chat_send_player(player, aclaims)
    end
})
factions.register_command ({"unclaim h", "unclaim help"}, {
    faction_permissions = {"claim"},
    global_privileges = def_global_privileges,
    dont_show_in_help = true,
    on_success = function(player, faction, pos, parcelpos, args)
		factions.unclaim_help(player, arg_two)
    end
})
