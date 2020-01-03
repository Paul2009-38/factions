local def_global_privileges = nil
if factions_config.faction_user_priv == true then
    def_global_privileges = {"faction_user"}
end

factions.register_command("name", {
    faction_permissions = {"name"},
	format = {"string"},
    description = "Change the faction's name.",
	description_arg = " <name>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local factionname = args.strings[1]
        if factions.can_create_faction(factionname) then
			factions.set_name(faction.name, factionname)
            return true
        else
            minetest.chat_send_player(player, "Faction cannot be renamed.")
            return false
        end
    end
})
factions.register_command ("claim", {
    faction_permissions = {"claim"},
    description = "Claim the plot of land you're on.",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		return claim_helper(player, faction, parcelpos)
    end
})
factions.register_command("unclaim", {
    faction_permissions = {"claim"},
    description = "Unclaim the plot of land you're on.",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		return unclaim_helper(player, faction, parcelpos)
    end
})
--list all known factions
factions.register_command("list", {
    description = "List all registered factions.",
	description_arg = ":",
    infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local list = factions.factions.to_array()
        local tosend = "Existing factions:"
        for i, v in ipairs(list) do
            if i ~= #list then
                tosend = tosend .. " " .. v .. ","
            else
                tosend = tosend .. " " .. v
            end
        end
        minetest.chat_send_player(player, tosend, false)
        return true
    end
})
--show factions mod version
factions.register_command("version", {
    description = "Displays mod version.",
	description_arg = ":",
	infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player, "factions: version 0.8.9", false)
    end
})
--show description of faction
factions.register_command("info", {
    format = {"faction"},
    description = "Shows a faction's description.",
	description_arg = " <faction>:",
	infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player,
            "factions: " .. args.factions[1].name .. ": " ..
            args.factions[1].description, false)
        return true
    end
})
factions.register_command("leave", {
    description = "Leave your faction",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.remove_player(faction.name, player)
        return true
    end
})
factions.register_command("kick", {
    faction_permissions = {"kick"},
    format = {"player"},
    description = "Kick a player from your faction",
	description_arg = " <player>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local name = args.players[1]
        local victim_faction, facname = factions.get_player_faction(name)
		local kicker_faction, kicker_facname = factions.get_player_faction(player)
        if victim_faction and kicker_facname == facname and name ~= victim_faction.leader then -- can't kick da king
            factions.remove_player(facname, name)
            return true
        elseif not victim_faction or kicker_facname ~= facname then
            minetest.chat_send_player(player, name .. " is not in your faction")
            return false
        else
            minetest.chat_send_player(player, name .. " cannot be kicked from your faction")
            return false
        end
    end
})
--create new faction
factions.register_command("create", {
    format = {"string"},
    infaction = false,
    description = "Create a new faction",
	description_arg = " <faction>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        if faction then
            minetest.chat_send_player(player, "You are already in a faction")
            return false
        end
        local factionname = args.strings[1]
        if factions.can_create_faction(factionname) then
			local new_faction = factions.new_faction(factionname)
            factions.add_player(factionname, player, new_faction.default_leader_rank)
			new_faction.leader = player
			factions.start_diplomacy(factionname, new_faction)
            return true
        else
            minetest.chat_send_player(player, "Faction cannot be created.")
            return false
        end
    end
})
factions.register_command("join", {
    format = {"faction"},
    description = "Join a faction",
	description_arg = " <faction>:",
    infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        if faction ~= nil or faction then
			minetest.chat_send_player(player, "You need to leave your current faction in order to join this one.")
            return false
		end
		local new_faction = args.factions[1]
        if new_faction and factions.can_join(new_faction.name, player) then
            factions.add_player(new_faction.name, player)
        elseif new_faction then
            minetest.chat_send_player(player, "You cannot join this faction.")
            return false
		else
			minetest.chat_send_player(player, "Enter the right faction name.")
            return false
        end
        return true
    end
})
factions.register_command("disband", {
    faction_permissions = {"disband"},
    description = "Disband your faction",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.disband(faction.name)
        return true
    end
})
factions.register_command("flag", {
    faction_permissions = {"flags"},
    description = "Manage the faction's flags.",
	description_arg = " <flag> <value>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local msg = ""
        for i, k in pairs(factions.flags) do
            msg = msg .. i ..": ".. k .. "\n"
        end
		minetest.chat_send_player(player, msg)
		return true
    end
})
factions.register_command({"description", "desc"}, {
	format = {"string"},
    faction_permissions = {"description"},
    description = "Set your faction's description",
	description_arg = " <description>:",
	global_privileges = def_global_privileges,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.set_description(faction.name, table.concat(args.strings," "))
        return true
    end
})
factions.register_command("invite", {
    format = {"player"},
    faction_permissions = {"invite"},
    description = "Invite a player to your faction",
	description_arg = " <player>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        if args.players and args.players[1] then
			if player == args.players[1] then
				minetest.chat_send_player(player, "You can not invite yourself.")
				return
			end
			factions.invite_player(faction.name, args.players[1])
			minetest.chat_send_player(player, "Invite Sent.")
		end
        return true
    end
})
factions.register_command("invites", {
    description = "List invited players.",
	description_arg = ":",
	faction_permissions = {"invite"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player, "Invited players:")
		local foundplayer = false
		local msg = ""
		for p, _ in pairs(faction.invited_players) do
			msg = msg .. p .. "\n"
			foundplayer = true
		end
		if not foundplayer then
			minetest.chat_send_player(player, "None:")
			return false
		end
		minetest.chat_send_player(player, msg)
        return true
    end
})
factions.register_command("uninvite", {
    format = {"player"},
    faction_permissions = {"invite"},
    description = "Revoke a player's invite.",
	description_arg = " <player>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.revoke_invite(faction.name, args.players[1])
		minetest.chat_send_player(player, "Invite canceled.")
        return true
    end
})
factions.register_command("delete", {
    global_privileges = {"faction_admin"},
    format = {"faction"},
    infaction = false,
    description = "Delete a faction",
	description_arg = " <faction>:",
    on_success = function(player, faction, pos, parcelpos, args)
        factions.disband(args.factions[1].name)
        return true
    end
})
factions.register_command("ranks", {
    description = "List ranks within your faction",
	description_arg = ":",
	global_privileges = def_global_privileges,
	on_success = function(player, faction, pos, parcelpos, args)
		local msg = ""
		for rank, permissions in pairs(faction.ranks) do
			msg = msg .. rank .. ": " .. table.concat(permissions, " ") .. "\n"
		end
		minetest.chat_send_player(player, msg)
        return true
    end
})
factions.register_command("privs", {
    description = "List available rank privileges",
	description_arg = ":",
	global_privileges = def_global_privileges,
	infaction = false,
	on_success = function(player, faction, pos, parcelpos, args)
		local msg = "Privileges available:\n"
		for i, k in pairs(factions.permissions) do
			msg = msg .. i .. ": " .. k .. "\n"
		end
		minetest.chat_send_player(player, msg)
        return true
    end
})
factions.register_command({"message_of_the_day", "motd"}, {
    format = {"string"},
    faction_permissions = {"motd"},
    description = "Sets the message that shows up every time a faction member logs in.",
	description_arg = " <message>:",
	global_privileges = def_global_privileges,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
		local s = ""
		for i, l in pairs(args.strings) do
			s = s .. l .. " "
		end
        factions.set_message_of_the_day(faction.name, "Message of the day: " .. s)
        return true
    end
})
if factions_config.faction_diplomacy == true then
	factions.register_command("send_alliance", {
		description = "Send an alliance request to another faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			if target_faction then
				if not target_faction.request_inbox[faction.name] then
					if faction.allies[target_name] then
						minetest.chat_send_player(player, "You are already allys.")
						return false
					end
					if faction.enemies[target_name] then
						minetest.chat_send_player(player, "You need to be neutral in-order to send an alliance request.")
						return false
					end
					if target_name == faction.name then
						minetest.chat_send_player(player, "You can not send an alliance to your own faction")
						return false
					end
					if faction.request_inbox[target_name] then
						minetest.chat_send_player(player, "Faction " .. target_name .. "has already sent a request to you.")
						return false
					end
					target_faction.request_inbox[faction.name] = "alliance"
					factions.broadcast(target_faction.name, "An alliance request from faction " .. faction.name .. " has been sent to you.")
					factions.broadcast(faction.name, "An alliance request was sent to faction " .. target_name)
					factions.factions.set(target_name, target_faction)
				else
					minetest.chat_send_player(player, "You have already sent a request.")
				end
			else
				minetest.chat_send_player(player, target_name .. " is not a name of a faction")
			end
		end
	})
	factions.register_command("send_neutral", {
		description = "Send neutral to another faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			if target_faction then
				if not target_faction.request_inbox[faction.name] then
					if faction.allies[target_name] then
						minetest.chat_send_player(player, "You are already allys.")
						return false
					end
					if faction.neutral[target_name] then
						minetest.chat_send_player(player, "You are already neutral with this faction")
						return false
					end
					if target_name == faction.name then
						minetest.chat_send_player(player, "You can not send a neutral request to your own faction")
						return false
					end
					if faction.request_inbox[target_name] then
						minetest.chat_send_player(player, "Faction " .. target_name .. "has already sent a request to you.")
						return false
					end
					target_faction.request_inbox[faction.name] = "neutral"
					factions.broadcast(target_faction.name, "A neutral request from faction " .. faction.name .. " has been sent to you.")
					factions.broadcast(faction.name, "A neutral request was sent to faction " .. target_name)
					factions.factions.set(target_name, target_faction)
				else
					minetest.chat_send_player(player, "You have already sent a request.")
				end
			else
				minetest.chat_send_player(player, target_name .. " is not a name of a faction")
			end
		end
	})
	factions.register_command("accept", {
		description = "accept an request from another faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			if not target_faction then
				minetest.chat_send_player(player, target_name .. " Is not a faction.")
				return false
			end
			if faction.request_inbox[target_name] then
				if target_name == faction.name then
					minetest.chat_send_player(player, "You can not accept an request from own faction")
					return false
				end
				if faction.request_inbox[target_name] == "alliance" then
					factions.new_alliance(faction.name, target_name)
					factions.new_alliance(target_name, faction.name)
				else
					if faction.request_inbox[target_name] == "neutral" then
						factions.new_neutral(faction.name, target_name)
						factions.new_neutral(target_name, faction.name)
					end
				end
				faction.request_inbox[target_name] = nil
				factions.factions.set(faction.name, faction)
			else
				minetest.chat_send_player(player, "No request was sent to you.")
			end
		end
	})
	factions.register_command("refuse", {
		description = "refuse an request from another faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			if not target_faction then
				minetest.chat_send_player(player, target_name .. " Is not a faction.")
				return false
			end
			if faction.request_inbox[target_name] then
				if target_name == faction.name then
					minetest.chat_send_player(player, "You can not refuse an request from your own faction")
					return false
				end
				faction.request_inbox[target_name] = nil
				factions.broadcast(target_name, "Faction " .. faction.name .. " refuse to be your ally.")
				factions.broadcast(faction.name, "Refused an request from faction " .. target_name)
				factions.factions.set(faction.name, faction)
			else
				minetest.chat_send_player(player, "No request was sent to you.")
			end
		end
	})
	factions.register_command("declare_war", {
		description = "Declare war on a faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			if not target_faction then
				minetest.chat_send_player(player, target_name .. " Is not a faction.")
				return false
			end
			if not faction.enemies[target_name] then
				if target_name == faction.name then
					minetest.chat_send_player(player, "You can not declare war on your own faction")
					return false
				end
				if faction.allies[target_name] then
					factions.end_alliance(faction.name, target_name)
					factions.end_alliance(target_name, faction.name)
				end
				if faction.neutral[target_name] then
					factions.end_neutral(faction.name, target_name)
					factions.end_neutral(target_name, faction.name)
				end
				factions.new_enemy(faction.name, target_name)
				factions.new_enemy(target_name, faction.name)
			else
				minetest.chat_send_player(player, "You are already at war.")
			end
		end
	})
	factions.register_command("break", {
		description = "Break an alliance.",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			if not target_faction then
				minetest.chat_send_player(player, target_name .. " Is not a faction.")
				return false
			end
			if faction.allies[target_name] then
				if target_name == faction.name then
					minetest.chat_send_player(player, "You can not break an alliance from your own faction")
					return false
				end
				factions.end_alliance(faction.name, target_name)
				factions.end_alliance(target_name, faction.name)
				factions.new_neutral(faction.name, target_name)
				factions.new_neutral(target_name, faction.name)
			else
				minetest.chat_send_player(player, "You where not allies to begin with.")
			end
		end
	})
	factions.register_command("inbox", {
		description = "Check your diplomacy request inbox.",
		description_arg = ":",
		global_privileges = def_global_privileges,
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			local msg = "Inbox:\n"
			for i, k in pairs(faction.request_inbox) do
				if k == "alliance" then
					msg = msg .. "Alliance request from faction " .. i .. "\n"
				else
					if k == "neutral" then
						msg = msg .. "neutral request from faction " .. i .. "\n"
					end
				end
				empty = false
			end
			if empty then
				minetest.chat_send_player(player, "none:")
			else
				minetest.chat_send_player(player, msg)
			end
		end
	})
	factions.register_command("allies", {
		description = "Shows the factions that are allied to you.",
		description_arg = ":",
		global_privileges = def_global_privileges,
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			local msg = ""
			for i, k in pairs(faction.allies) do
				msg = msg .. i .. "\n"
				empty = false
			end
			if empty then
				minetest.chat_send_player(player, "none:")
			else
				minetest.chat_send_player(player, msg)
			end
		end
	})
	factions.register_command("neutral", {
		description = "Shows the factions that are neutral with you.",
		description_arg = ":",
		global_privileges = def_global_privileges,
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			local msg = ""
			for i, k in pairs(faction.neutral) do
				msg = msg .. i .. "\n"
				empty = false
			end
			if empty then
				minetest.chat_send_player(player, "none:")
			else
				minetest.chat_send_player(player, msg)
			end
		end
	})
	factions.register_command("enemies", {
		description = "Shows enemies of your faction",
		description_arg = ":",
		global_privileges = def_global_privileges,
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			local msg = ""
			for i, k in pairs(faction.enemies) do
				msg = msg .. i .. "\n"
				empty = false
			end
			if empty then
				minetest.chat_send_player(player, "none:")
			else
				minetest.chat_send_player(player, msg)
			end
		end
	})
end
factions.register_command("who", {
    description = "List players in a faction, and their ranks.",
	description_arg = " (none | <faction>):",
    infaction = false,
    global_privileges = def_global_privileges,
	format = {"string"},
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
        local str = args.strings[1]
		if str then
			local f = factions.get_faction(str)
			if not f or not f.players then
				minetest.chat_send_player(player, "Faction " .. str .. " does not exist.")
				return
			else
				minetest.chat_send_player(player, "Players in faction " .. f.name .. ": ")
				for p, rank in pairs(f.players) do
					minetest.chat_send_player(player, p .." (" .. rank .. ")")
				end
				return true
			end
		else
			local f = factions.get_player_faction(player)
			if not f or not f.players then
				minetest.chat_send_player(player, "Your not in a faction.")
				return
			else
				minetest.chat_send_player(player, "Players in faction " .. f.name .. ": ")
				for p, rank in pairs(f.players) do
					minetest.chat_send_player(player, p .." (" .. rank .. ")")
				end
				return true
			end
		end
        return true
    end
})
local parcel_size_center = factions_config.parcel_size / 2
factions.register_command("show_parcel", {
    description = "Shows parcel for six seconds.",
	description_arg = ":",
	global_privileges = def_global_privileges,
	infaction = false,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
		local parcel_faction = factions.get_parcel_faction(parcelpos)
		if not parcel_faction then
			minetest.chat_send_player(player, "There is no claim here")
			return false
		end
		local psc = parcel_size_center
		local fps = factions_config.parcel_size
		local ppos = {x = (math.floor(pos.x / fps) * fps) + psc, y = (math.floor(pos.y / fps) * fps) + psc, z = (math.floor(pos.z / fps) * fps) + psc}
		minetest.add_entity(ppos, "fac_objects:display")
        return true
    end
})
factions.register_command("new_rank", {
    description = "Add a new rank.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if faction.ranks[rank] then
				minetest.chat_send_player(player, "Rank already exists")
				return false
			end
			local success = false
			local failindex = -1
			for _, f in pairs(args.strings) do
				if f then
					for q, r in pairs(factions.permissions) do
						if f == r then
							success = true
							break
						else
							success = false
						end
					end
					if not success and _ ~= 1 then
						failindex = _
						break
					end
				end
			end
			if not success then
				if args.strings[failindex] then
					minetest.chat_send_player(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					minetest.chat_send_player(player, "No permission was given.")
				end
				return false
			end
			factions.add_rank(faction.name, rank, args.other)
			return true
		end
		minetest.chat_send_player(player, "No rank was given.")
		return false
    end
})
factions.register_command("replace_privs", {
    description = "Deletes current permissions and replaces them with the ones given.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if not faction.ranks[rank] then
				minetest.chat_send_player(player, "Rank does not exist")
				return false
			end
			local success = false
			local failindex = -1
			for _, f in pairs(args.strings) do
				if f then
					for q, r in pairs(factions.permissions) do
						if f == r then
							success = true
							break
						else
							success = false
						end
					end
					if not success and _ ~= 1 then
						failindex = _
						break
					end
				end
			end
			if not success then
				if args.strings[failindex] then
					minetest.chat_send_player(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					minetest.chat_send_player(player, "No permission was given.")
				end
				return false
			end
			factions.replace_privs(faction.name, rank, args.other)
			return true
		end
		minetest.chat_send_player(player, "No rank was given.")
		return false
    end
})
factions.register_command("remove_privs", {
    description = "Remove permissions from a rank.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if not faction.ranks[rank] then
				minetest.chat_send_player(player, "Rank does not exist")
				return false
			end
			local success = false
			local failindex = -1
			for _, f in pairs(args.strings) do
				if f then
					for q, r in pairs(factions.permissions) do
						if f == r then
							success = true
							break
						else
							success = false
						end
					end
					if not success and _ ~= 1 then
						failindex = _
						break
					end
				end
			end
			if not success then
				if args.strings[failindex] then
					minetest.chat_send_player(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					minetest.chat_send_player(player, "No permission was given.")
				end
				return false
			end
			factions.remove_privs(faction.name, rank, args.other)
			return true
		end
		minetest.chat_send_player(player, "No rank was given.")
		return false
    end
})
factions.register_command("add_privs", {
    description = "add permissions to a rank.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if not faction.ranks[rank] then
				minetest.chat_send_player(player, "Rank does not exist")
				return false
			end
			local success = false
			local failindex = -1
			for _, f in pairs(args.strings) do
				if f then
					for q, r in pairs(factions.permissions) do
						if f == r then
							success = true
							break
						else
							success = false
						end
					end
					if not success and _ ~= 1 then
						failindex = _
						break
					end
				end
			end
			if not success then
				if args.strings[failindex] then
					minetest.chat_send_player(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					minetest.chat_send_player(player, "No permission was given.")
				end
				return false
			end
			factions.add_privs(faction.name, rank, args.other)
			return true
		end
		minetest.chat_send_player(player, "No rank was given.")
		return false
    end
})
factions.register_command("set_rank_name", {
    description = "Change the name of given rank.",
	description_arg = " <old rank> <new rank>:",
    format = {"string","string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        local newrank = args.strings[2]
        if not faction.ranks[rank] then
            minetest.chat_send_player(player, "The rank does not exist.")
            return false
        end
		if faction.ranks[newrank] then
            minetest.chat_send_player(player, "This rank name was already taken.")
            return false
        end
        factions.set_rank_name(faction.name, rank, newrank)
        return true
    end
})
factions.register_command("del_rank", {
    description = "Replace and delete a rank.",
	description_arg = " <old rank> <new rank>:",
    format = {"string", "string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        local newrank = args.strings[2]
        if not faction.ranks[rank] or not faction.ranks[newrank] then
            minetest.chat_send_player(player, "One of the specified ranks does not exist.")
            return false
        end
        factions.delete_rank(faction.name, rank, newrank)
        return true
    end
})
factions.register_command("set_def_rank", {
    description = "Change the default rank given to new players and also replace rankless players in this faction",
	description_arg = " <rank>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        if not faction.ranks[rank] then
            minetest.chat_send_player(player, "This rank does not exist.")
            return false
        end
        factions.set_def_rank(faction.name, rank)
        return true
    end
})
factions.register_command("reset_ranks", {
    description = "Reset's all of the factions rankings back to the default ones.",
	description_arg = ":",
    format = {},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.reset_ranks(faction.name)
        return true
    end
})
factions.register_command("sethome", {
    description = "Set the faction's spawn",
	description_arg = ":",
    faction_permissions = {"spawn"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.set_spawn(faction.name, pos)
        return true
    end
})
factions.register_command("unsethome", {
    description = "Set the faction's spawn to zero",
	description_arg = ":",
    faction_permissions = {"spawn"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.set_spawn(faction.name, {x = 0, y = 0, z = 0})
        return true
    end
})
if factions_config.spawn_teleport == true then
	factions.register_command("home", {
		description = "Teleport to the faction's spawn",
		description_arg = ":",
		global_privileges = def_global_privileges,
		on_success = function(player, faction, pos, parcelpos, args)
			if player then
				minetest.chat_send_player(player, "Teleporting in five seconds.")
				factions.tp_spawn(faction.name, player)
			end
			return false
		end
	})
end
factions.register_command("where", {
    description = "See whose parcel you stand on.",
	description_arg = ":",
    infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local parcel_faction, facname = factions.get_parcel_faction(parcelpos)
        local place_name = facname or "Wilderness"
        minetest.chat_send_player(player, "You are standing on parcel " .. parcelpos .. ", part of " .. place_name)
        return true
    end
})
factions.register_command("help", {
    description = "Shows help for commands.",
	description_arg = ":",
    infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions_chat.show_help(player)
        return true
    end
})
factions.register_command("gethome", {
    description = "Shows your faction's spawn",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local spawn = faction.spawn
        if spawn then
            minetest.chat_send_player(player, "Home is at (" .. spawn.x .. ", " .. spawn.y .. ", " .. spawn.z .. ")")
            return true
        else
            minetest.chat_send_player(player, "Your faction has no spawn set.")
            return false
        end
    end
})
factions.register_command("promote", {
    description = "Promotes a player to a rank",
	description_arg = " <player> <rank>:",
    format = {"player", "string"},
    faction_permissions = {"promote"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        if faction.ranks[rank] then
			local name = args.players[1]
			local player_faction, facname = factions.get_player_faction(name)
			local promoter_faction, promoter_facname = factions.get_player_faction(player)
			if player_faction and promoter_facname == facname and player ~= name then
				factions.promote(faction.name, name, rank)
				minetest.chat_send_player(player, "Promoted " .. name .. " to " .. rank .. "!")
				return true
			elseif not player_faction or promoter_facname ~= facname then
				minetest.chat_send_player(player, name .. " is not in your faction")
				return false
			elseif player == name then
				minetest.chat_send_player(player, "You can not promote yourself!")
				return false
			else
				minetest.chat_send_player(player, name .. " cannot be promoted from your faction")
				return false
			end
        else
            minetest.chat_send_player(player, "The specified rank does not exist.")
            return false
        end
    end
})
factions.register_command("power", {
    description = "Display your faction's power",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		local pps = 0
		if factions_config.enable_power_per_player then
			if factions.onlineplayers[faction.name] == nil then
				factions.onlineplayers[faction.name] = {}
			end
			local t = factions.onlineplayers[faction.name]
			local count = 0
			for _ in pairs(t) do count = count + 1 end
			pps = factions_config.power_per_player * count
		else
			pps = factions_config.power_per_tick
		end
        minetest.chat_send_player(player, "Power: " .. faction.power .. " / " .. faction.maxpower - faction.usedpower .. "\nPower per " .. factions_config.tick_time .. " seconds: " .. pps .. "\nPower per death: -" .. factions_config.power_per_death)
        return true
    end
})
factions.register_command("free", {
    description = "Forcefully frees a parcel",
	description_arg = ":",
    infaction = false,
    global_privileges = {"faction_admin"},
    on_success = function(player, faction, pos, parcelpos, args)
        local parcel_faction = factions.get_parcel_faction(parcelpos)
        if not parcel_faction then
            minetest.chat_send_player(player, "No claim at this position")
            return false
        else
            factions.unclaim_parcel(parcel_faction.name, parcelpos)
            return true
        end
    end
})
factions.register_command("chat", {
    description = "Send a message to your faction's members",
	description_arg = " <message>:",
	global_privileges = def_global_privileges,
	format = {"string"},
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
        local msg = table.concat(args.strings, " ")
        factions.broadcast(faction.name, msg, player)
    end
})
factions.register_command("force_update", {
    description = "Forces an update tick.",
	description_arg = ":",
    global_privileges = {"faction_admin"},
	infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.faction_tick()
    end
})
factions.register_command("player", {
    description = "Get which faction a player is in",
	description_arg = " <player>:",
    infaction = false,
    format = {"string"},
	global_privileges = def_global_privileges,
	ignore_param_limit = true,
    on_success = function(player, faction, pos, parcelpos, args)
        local playername = args.strings[1]
		if not playername then
			playername = player
		end
        local faction1, facname = factions.get_player_faction(playername)
        if not faction1 then
            minetest.chat_send_player(player, "Player " .. playername .. " does not belong to any faction")
            return false
        else
            minetest.chat_send_player(player, "player " .. playername .. " belongs to faction " .. faction1.name)
            return true
        end
    end
})
factions.register_command("set_leader", {
    description = "Set a player as a faction's leader",
	description_arg = " <faction> <player>:",
    infaction = false,
    global_privileges = {"faction_admin"},
    format = {"faction", "player"},
    on_success = function(player, faction, pos, parcelpos, args)
        local playername = args.players[1]
        local playerfaction, facname = factions.get_player_faction(playername)
        local targetfaction = args.factions[1]
        if facname ~= targetfaction.name then
            minetest.chat_send_player(player, "Player " .. playername .. " is not in faction " .. targetfaction.name .. ".")
            return false
        end
        factions.set_leader(targetfaction.name, playername)
        return true
    end
})
factions.register_command("set_admin", {
    description = "Make a faction an admin faction",
	description_arg = " <faction>:",
    infaction = false,
    global_privileges = {"faction_admin"},
    format = {"faction"},
    on_success = function(player, faction, pos, parcelpos, args)
		if not args.factions[1].is_admin then
			minetest.chat_send_player(player,"faction " .. args.factions[1].name .. " is now an admin faction it can not be disband.")
		else
			minetest.chat_send_player(player,"faction " .. args.factions[1].name .. " is already an admin ")
		end
        args.factions[1].is_admin = true
		factions.factions.set(args.factions[1].name, args.factions[1])
        return true
    end
})
factions.register_command("remove_admin", {
    description = "Make a faction not an admin faction",
	description_arg = " <faction>:",
    infaction = false,
    global_privileges = {"faction_admin"},
    format = {"faction"},
    on_success = function(player, faction, pos, parcelpos, args)
		if args.factions[1].is_admin then
			minetest.chat_send_player(player,"faction " .. args.factions[1].name .. " is not an admin faction any more.")
		else
			minetest.chat_send_player(player,"faction " .. args.factions[1].name .. " is not an admin faction to begin with.")
		end
        args.factions[1].is_admin = false
		factions.factions.set(args.factions[1].name, args.factions[1])
        return true
    end
})
factions.register_command("reset_power", {
    description = "Reset a faction's power",
	description_arg = " <faction>:",
    infaction = false,
    global_privileges = {"faction_admin"},
    format = {"faction"},
    on_success = function(player, faction, pos, parcelpos, args)
        args.factions[1].power = 0
		factions.factions.set(args.factions[1].name, args.factions[1])
        return true
    end
})
factions.register_command("obliterate", {
    description = "Remove all factions",
	description_arg = ":",
    infaction = false,
    global_privileges = {"faction_admin"},
    on_success = function(player, faction, pos, parcelpos, args)
        for facname, i in factions.factions.iterate() do
            factions.disband(facname, "obliterated")
        end
        return true
    end
})
factions.register_command("get_factions_spawn", {
    description = "Get a faction's spawn",
	description_arg = " <faction>:",
    infaction = false,
    global_privileges = {"faction_admin"},
    format = {"faction"},
    on_success = function(player, faction, pos, parcelpos, args)
        local spawn = args.factions[1].spawn
        if spawn then
            minetest.chat_send_player(player, spawn.x .. "," .. spawn.y .. "," .. spawn.z)
            return true
        else
            minetest.chat_send_player(player, "Faction has no spawn set.")
            return false
        end
    end
})
factions.register_command("stats", {
    description = "Get stats of a faction",
	description_arg = " <faction>:",
    infaction = false,
    global_privileges = def_global_privileges,
    format = {"faction"},
    on_success = function(player, faction, pos, parcelpos, args)
        local f = args.factions[1]
		local pps = 0
		if factions_config.enable_power_per_player then
			if factions.onlineplayers[f.name] == nil then
				factions.onlineplayers[f.name] = {}
			end
			local t = factions.onlineplayers[f.name]
			local count = 0
			for _ in pairs(t) do count = count + 1 end
			pps = factions_config.power_per_player * count
		else
			pps = factions_config.power_per_tick
		end
        minetest.chat_send_player(player, "Power: " .. f.power .. " / " .. f.maxpower - f.usedpower .. "\nPower per " .. factions_config.tick_time .. " seconds: " .. pps .. "\nPower per death: -" .. factions_config.power_per_death)
        return true
    end
})
factions.register_command("seen", {
    description = "Check the last time a faction had a member logged in",
	description_arg = " <faction>:",
    infaction = false,
    global_privileges = def_global_privileges,
    format = {"faction"},
    on_success = function(player, faction, pos, parcelpos, args)
        local lastseen = args.factions[1].last_logon
        local now = os.time()
        local time = now - lastseen
        local minutes = math.floor(time / 60)
        local hours = math.floor(minutes / 60)
        local days = math.floor(hours / 24)
        minetest.chat_send_player(player, "Last seen " .. days .. " day(s), " ..
            hours % 24 .. " hour(s), " .. minutes % 60 .. " minutes, " .. time % 60 .. " second(s) ago.")
        return true
    end
})
