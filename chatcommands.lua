local send_error = function(player, message)
    minetest.chat_send_player(player, message)
end

factions_chat = {}

factions.commands = {}

factions.register_command = function(cmd_name, cmd, ignore_param_count, or_perm, dont_show_in_help)
    factions.commands[cmd_name] = { -- default command
        name = cmd_name,
        faction_permissions = {},
        global_privileges = {},
        format = {},
        infaction = true,
        description = "This command has no description.",
		dont_show_in_help = dont_show_in_help,
        run = function(self, player, argv)
            if self.global_privileges then
                local tmp = {}
                for i in ipairs(self.global_privileges) do
                    tmp[self.global_privileges[i]] = true
                end
                local bool, missing_privs = minetest.check_player_privs(player, tmp)
                if not bool then
                    send_error(player, "Unauthorized.")
                    return false
                end
            end
            -- checks argument formats
            local args = {
                factions = {},
                players = {},
                strings = {},
				unknowns = {},
                other = {}
            }
			if not ignore_param_count then
				if #argv < #(self.format) then
					send_error(player, "Not enough parameters.")
					return false
				end
				else
				if self.format[1] then
					local fm = self.format[1]
					for i in ipairs(argv) do
						if #argv > #(self.format) then
							table.insert(self.format, fm)
						else
							break
						end
					end
				end
			end
			
            for i in ipairs(self.format) do
                local argtype = self.format[i]
                local arg = argv[i]
                if argtype == "faction" then
                    local fac = factions.get_faction(arg)
                    if not fac then
                        send_error(player, "Specified faction "..arg.." does not exist")
                        return false
                    else
                        table.insert(args.factions, fac)
                    end
                elseif argtype == "player" then
					local data = minetest.get_auth_handler().get_auth(arg)
					if data then
						table.insert(args.players, arg)
					else
						send_error(player, "Player does not exist.")
						return false
					end
                elseif argtype == "string" then
                    table.insert(args.strings, arg)
                else
					table.insert(args.unknowns, arg)
                end
            end
            for i=2, #argv do
				if argv[i] then
					table.insert(args.other, argv[i])
				end
            end

            -- checks permissions
            local player_faction, facname = factions.get_player_faction(player)
            if self.infaction and not player_faction then
                minetest.chat_send_player(player, "This command is only available within a faction")
                return false
            end
			local one_p = false
            if self.faction_permissions then
                for i in ipairs(self.faction_permissions) do
					local perm = self.faction_permissions[i]
                    if not or_perm and not factions.has_permission(facname, player, perm) then
                        send_error(player, "You do not have the faction permission " .. perm)
                        return false
					elseif or_perm and factions.has_permission(facname, player, perm) then
						one_p = true
						break
                    end
                end
            end
			if or_perm and one_p == false then
			    send_error(player, "You do not have any of faction permissions required.")
                return false
			end

            -- get some more data
            local pos = minetest.get_player_by_name(player):getpos()
            local parcelpos = factions.get_parcel_pos(pos)
            return self.on_success(player, player_faction, pos, parcelpos, args)
        end,
        on_success = function(player, faction, pos, parcelpos, args)
            minetest.chat_send_player(player, "Not implemented yet!")
        end
    }
    -- override defaults
    for k, v in pairs(cmd) do
        factions.commands[cmd_name][k] = v
    end
end

factions.register_commands = function(cmd_names, cmd, ignore_param_count, or_perm)
	local hide = false
	for k, v in pairs(cmd_names) do
		factions.register_command(k, cmd, ignore_param_count, or_perm, hide)
		hide = true
	end
end

local init_commands
init_commands = function()
	
	if factions_config.faction_user_priv == true then
		minetest.register_privilege("faction_user",
			{
				description = "this user is allowed to interact with faction mod",
				give_to_singleplayer = true,
			}
		)
	end
	
	
	minetest.register_privilege("faction_admin",
		{
			description = "this user is allowed to create or delete factions",
			give_to_singleplayer = true,
		}
	)
	
	local def_privs = {interact = true}
	if factions_config.faction_user_priv == true then
		def_privs.faction_user = true
	end
	
	minetest.register_chatcommand("f",
		{
			params = "<command> parameters",
			description = "Factions commands. Type /f help for available commands.",
            privs = def_privs,
			func = factions_chat.cmdhandler,
		}
	)
	
	minetest.register_chatcommand("faction",
		{
			params = "<command> parameters",
			description = "Factions commands. Type /faction help for available commands.",
            privs = def_privs,
			func = factions_chat.cmdhandler,
		}
	)
end
	

-------------------------------------------
-- R E G I S T E R E D   C O M M A N D S  |
-------------------------------------------

local def_global_privileges = nil

if factions_config.faction_user_priv == true then
	minetest.register_on_newplayer(function(player)
		local name = player:get_player_name()
		local privs = minetest.get_player_privs(name)
		privs.faction_user = true
		minetest.set_player_privs(name, privs)
	end
	)
	def_global_privileges = {"faction_user"}
end

factions.register_command ("name", {
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
            send_error(player, "Faction cannot be renamed.")
            return false
        end
    end
},false)

factions.register_command ("claim", {
    faction_permissions = {"claim"},
    description = "Claim the plot of land you're on.",
	description_arg = ":",
	format = {"string"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		local arg_one = args.strings[1]
		local arg_two = args.strings[2]
		if not arg_one or arg_one == "o" or arg_one == "one" then
			return claim_helper(player, faction, parcelpos)
		elseif arg_one == "a" or arg_one == "auto" then
			factions.claim_auto(player, faction)
		elseif arg_one == "f" or arg_one == "fill" then
			factions.claim_fill(player, faction)
		elseif arg_one == "s" or arg_one == "square" then
			if arg_two then
				local r = tonumber(arg_two)
				
				if not r then
					send_error(player, "Only use numbers in the second cmd parameter [0-9].")
					return
				end
				
				factions.claim_square(player, faction, r)
			else
				factions.claim_square(player, faction, 3)
			end
		elseif arg_one == "c" or arg_one == "circle" then
			if arg_two then
				local r = tonumber(arg_two)
				
				if not r then
					send_error(player, "Only use numbers in the second cmd parameter [0-9].")
					return
				end
				
				factions.claim_circle(player, faction, r)
			else
				factions.claim_circle(player, faction, 3)
			end
		elseif arg_one == "all" then
			factions.claim_all(player, faction)
		elseif arg_one == "l" or arg_one == "list" then
			local timer = 0
			minetest.chat_send_player(player, "All claims:")
			for i in pairs(faction.land) do
				minetest.after(timer, minetest.chat_send_player, player, i)
				timer = timer + 0.1
			end
		elseif arg_one == "h" or arg_one == "help" then
			factions.claim_help(player, arg_two)
		end
    end
},true)

factions.register_command("unclaim", {
    faction_permissions = {"claim"},
    description = "Unclaim the plot of land you're on.",
	description_arg = ":",
	format = {"string"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		local arg_one = args.strings[1]
		local arg_two = args.strings[2]
		if not arg_one or arg_one == "o" or arg_one == "one" then
			return unclaim_helper(player, faction, parcelpos)
		elseif arg_one == "a" or arg_one == "auto" then
			factions.unclaim_auto(player, faction)
		elseif arg_one == "f" or arg_one == "fill" then
			factions.unclaim_fill(player, faction)
		elseif arg_one == "s" or arg_one == "square" then
			if arg_two then
				local r = tonumber(arg_two)
				
				if not r then
					send_error(player, "Only use numbers in the second cmd parameter [0-9].")
					return
				end
				
				factions.unclaim_square(player, faction, r)
			else
				factions.unclaim_square(player, faction, 3)
			end
		elseif arg_one == "c" or arg_one == "circle" then
			if arg_two then
				local r = tonumber(arg_two)
				
				if not r then
					send_error(player, "Only use numbers in the second cmd parameter [0-9].")
					return
				end
				
				factions.unclaim_circle(player, faction, r)
			else
				factions.unclaim_circle(player, faction, 3)
			end
		elseif arg_one == "all" then
			factions.unclaim_all(player, faction)
		elseif arg_one == "l" or arg_one == "list" then
			local timer = 0
			minetest.chat_send_player(player, "All claims:")
			for i in pairs(faction.land) do
				minetest.after(timer, minetest.chat_send_player, player, i)
				timer = timer + 0.1
			end
		elseif arg_one == "h" or arg_one == "help" then
			factions.unclaim_help(player, arg_two)
		end
    end
},true)

--list all known factions
factions.register_command("list", {
    description = "List all registered factions.",
	description_arg = ":",
    infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local list = factions.get_faction_list()
        local tosend = "Existing factions:"
        
        for i,v in ipairs(list) do
            if i ~= #list then
                tosend = tosend .. " " .. v .. ","
            else
                tosend = tosend .. " " .. v
            end
        end
		
        minetest.chat_send_player(player, tosend, false)
        return true
    end
},false)

--show factions mod version
factions.register_command("version", {
    description = "Displays mod version.",
	description_arg = ":",
	infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player, "factions: version 0.8.8", false)
    end
},false)

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
},false)

factions.register_command("leave", {
    description = "Leave your faction",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.remove_player(faction.name, player)
        return true
    end
},false)

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
            send_error(player, name .. " is not in your faction")
            return false
        else
            send_error(player, name .. " cannot be kicked from your faction")
            return false
        end
    end
},false)

--create new faction
factions.register_command("create", {
    format = {"string"},
    infaction = false,
    description = "Create a new faction",
	description_arg = " <faction>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        if faction then
            send_error(player, "You are already in a faction")
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
            send_error(player, "Faction cannot be created.")
            return false
        end
    end
},false)

factions.register_command("join", {
    format = {"faction"},
    description = "Join a faction",
	description_arg = " <faction>:",
    infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        if faction ~= nil or faction then
			send_error(player, "You need to leave your current faction in order to join this one.")
            return false
		end
		
		local new_faction = args.factions[1]
		
        if new_faction and factions.can_join(new_faction.name, player) then
            factions.add_player(new_faction.name, player)
        elseif new_faction then
            send_error(player, "You cannot join this faction")
            return false
		else
			send_error(player, "Enter the right faction name.")
            return false
        end
		
        return true
    end
},false)

factions.register_command("disband", {
    faction_permissions = {"disband"},
    description = "Disband your faction",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.disband(faction.name)
        return true
    end
},false)

factions.register_command("flag", {
    faction_permissions = {"flags"},
    description = "Manage the faction's flags.",
	description_arg = " <flag> <value>:",
	global_privileges = def_global_privileges,
	format = {"string"},
    on_success = function(player, faction, pos, parcelpos, args)
		--"Make your faction invite-only."
		--"Allow any player to join your "
        --faction:toggle_join_free(false)
		local flag_name = args.strings[1]
		local bool = args.strings[2]
		if (flag_name == "help" or flag_name == "flags") or not bool then
			for i, k in pairs(factions.flags) do
				minetest.chat_send_player(player, k..": ".. factions.flags_desc[i] .. "\n")
			end
			return true
		end
		if flag_name and bool then
			local yes = false
			if bool == "yes" then
				yes = true
			elseif bool == "no" then
				yes = false
			else
				send_error(player, "Set the flags only to yes or no.")
				return false
			end
			if flag_name == "open" then
				factions.toggle_join_free(faction.name, yes)
			elseif flag_name == "monsters" then
			elseif flag_name == "tax_kick" then
			elseif flag_name == "animals" then
			else
				send_error(player, flag_name.." is not an flag.")
			end
		end
        return true
    end
},true)

factions.register_command("desc", {
	format = {"string"},
    faction_permissions = {"description"},
    description = "Set your faction's description",
	description_arg = " <description>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.set_description(faction.name, table.concat(args.strings," "))
        return true
    end
},true)

factions.register_command("invite", {
    format = {"player"},
    faction_permissions = {"invite"},
    description = "Invite a player to your faction",
	description_arg = " <player>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        if args.players and args.players[1] then
			if player == args.players[1] then
				send_error(player, "You can not invite yourself.")
				return
			end
			factions.invite_player(faction.name, args.players[1])
			minetest.chat_send_player(player, "Invite Sent.")
		end
        return true
    end
},false)

factions.register_command("invites", {
    description = "List invited players.",
	description_arg = ":",
	faction_permissions = {"invite"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player, "Invited players:")
		local foundplayer = false
		for p, _ in pairs(faction.invited_players) do
			minetest.chat_send_player(player, p)
			foundplayer = true
		end
		if not foundplayer then
			minetest.chat_send_player(player, "None:")
		end
        return true
    end
},false)

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
},false)

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
},false)

factions.register_command("ranks", {
    description = "List ranks within your faction",
	description_arg = ":",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        for rank, permissions in pairs(faction.ranks) do
            minetest.chat_send_player(player, rank .. ": " .. table.concat(permissions, " "))
        end
        return true
    end
},false)

factions.register_command("rank_privileges", {
    description = "List available rank privileges",
	description_arg = ":",
	global_privileges = def_global_privileges,
	infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
		minetest.chat_send_player(player, "Privileges available:\n")
		for i, k in pairs(factions.permissions) do
            minetest.chat_send_player(player, k .. ": " .. factions.permissions_desc[i] .. "\n")
        end
        return true
    end
},false)

factions.register_command("motd", {
    format = {"string"},
    faction_permissions = {"motd"},
    description = "Sets the message that shows up every time a faction member logs-in",
	description_arg = " <message>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		local s = ""
		for i, l in pairs(args.strings) do
			s = s .. l .. " "
		end
        factions.set_message_of_the_day(faction.name, "Message of the day: " .. s)
        return true
    end
},true)

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
						send_error(player, "You are already allys.")
						return false
					end
					
					if faction.enemies[target_name] then
						send_error(player, "You need to be neutral in-order to send an alliance request.")
						return false
					end
					
					if target_name == faction.name then
						send_error(player, "You can not send an alliance to your own faction")
						return false
					end
					
					if faction.request_inbox[target_name] then
						send_error(player, "Faction " .. target_name .. "has already sent a request to you.")
						return false
					end
					
					target_faction.request_inbox[faction.name] = "alliance"
					factions.broadcast(target_faction.name, "An alliance request from faction " .. faction.name .. " has been sent to you.")
					factions.broadcast(faction.name, "An alliance request was sent to faction " .. target_name)
					
					factions.factions.set(target_name, target_faction)
				else
					send_error(player, "You have already sent a request.")
				end
			else
				send_error(player, target_name .. " is not a name of a faction")
			end
		end
	},false)
	
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
						send_error(player, "You are already allys.")
						return false
					end
					
					if faction.neutral[target_name] then
						send_error(player, "You are already neutral with this faction")
						return false
					end
					
					if target_name == faction.name then
						send_error(player, "You can not send a neutral request to your own faction")
						return false
					end
					
					if faction.request_inbox[target_name] then
						send_error(player, "Faction " .. target_name .. "has already sent a request to you.")
						return false
					end
					
					target_faction.request_inbox[faction.name] = "neutral"
					factions.broadcast(target_faction.name, "A neutral request from faction " .. faction.name .. " has been sent to you.")
					factions.broadcast(faction.name, "A neutral request was sent to faction " .. target_name)
					
					factions.factions.set(target_name, target_faction)
				else
					send_error(player, "You have already sent a request.")
				end
			else
				send_error(player, target_name .. " is not a name of a faction")
			end
		end
	},false)
	
	factions.register_command("accept", {
		description = "accept an request from another faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			
			if faction.request_inbox[target_name] then
				if target_name == faction.name then
					send_error(player, "You can not accept an request from own faction")
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
				send_error(player, "No request was sent to you.")
			end
		end
	},false)
	
	factions.register_command("refuse", {
		description = "refuse an request from another faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			
			if faction.request_inbox[target_name] then
				if target_name == faction.name then
					send_error(player, "You can not refuse an request from your own faction")
					return false
				end
				
				faction.request_inbox[target_name] = nil
				factions.broadcast(target_name, "Faction " .. faction.name .. " refuse to be your ally.")
				factions.broadcast(faction.name, "Refused an request from faction " .. target_name)
				factions.factions.set(faction.name, faction)
				
			else
				send_error(player, "No request was sent to you.")
			end
		end
	},false)
	
	factions.register_command("declare_war", {
		description = "Declare war on a faction",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			
			if not faction.enemies[target_name] then
				if target_name == faction.name then
					send_error(player, "You can not declare war on your own faction")
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
				send_error(player, "You are already at war.")
			end
		end
	},false)
	
	factions.register_command("break", {
		description = "Break an alliance.",
		description_arg = " <faction>:",
		global_privileges = def_global_privileges,
		format = {"string"},
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local target_name = args.strings[1]
			local target_faction = factions.factions.get(target_name)
			
			if faction.allies[target_name] then
				if target_name == faction.name then
					send_error(player, "You can not break an alliance from your own faction")
					return false
				end
				
				factions.end_alliance(faction.name, target_name)
				factions.end_alliance(target_name, faction.name)
				factions.new_neutral(faction.name, target_name)
				factions.new_neutral(target_name, faction.name)
				
			else
				send_error(player, "You where not allies to begin with.")
			end
		end
	},false)
	
	factions.register_command("inbox", {
		description = "Check your diplomacy request inbox.",
		description_arg = ":",
		global_privileges = def_global_privileges,
		faction_permissions = {"diplomacy"},
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			
			for i, k in pairs(faction.request_inbox) do
				if k == "alliance" then
					minetest.chat_send_player(player, "Alliance request from faction " .. i .. "\n")
				else 
					if k == "neutral" then
						minetest.chat_send_player(player, "neutral request from faction " .. i .. "\n")
					end
				end
				
				empty = false
			end
			
			if empty then
				minetest.chat_send_player(player, "none:")
			end
		end
	},false)
	
	factions.register_command("allies", {
		description = "Shows the factions that are allied to you.",
		description_arg = ":",
		global_privileges = def_global_privileges,
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			
			for i, k in pairs(faction.allies) do
				minetest.chat_send_player(player, i .. "\n")
				empty = false
			end
			
			if empty then
				minetest.chat_send_player(player, "none:")
			end
		end
	},false)
	
	factions.register_command("neutral", {
		description = "Shows the factions that are neutral with you.",
		description_arg = ":",
		global_privileges = def_global_privileges,
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			
			for i, k in pairs(faction.neutral) do
				minetest.chat_send_player(player, i .. "\n")
				empty = false
			end
			
			if empty then
				minetest.chat_send_player(player, "none:")
			end
		end
	},false)
	
	factions.register_command("enemies", {
		description = "Shows enemies of your faction",
		description_arg = ":",
		global_privileges = def_global_privileges,
		on_success = function(player, faction, pos, parcelpos, args)
			local empty = true
			
			for i, k in pairs(faction.enemies) do
				minetest.chat_send_player(player, i .. "\n")
				empty = false
			end
			
			if empty then
				minetest.chat_send_player(player, "none:")
			end
		end
	},false)
end

factions.register_command("who", {
    description = "List players in a faction, and their ranks.",
	description_arg = " (none | <faction>):",
    infaction = false,
    global_privileges = def_global_privileges,
    format = {"string"},
    on_success = function(player, faction, pos, parcelpos, args)
        local str = args.strings[1]
		
		local f = {}
		
		if str then
			f = factions.get_faction(str)
			
			if not f and not f.players then
				f = factions.get_player_faction(player)
				if not f and not f.players then
					minetest.chat_send_player(player, "Your not in a faction.")
					return
				else
					minetest.chat_send_player(player, "Players in faction " .. f.name .. ": ")
					for p, rank in pairs(f.players) do
						minetest.chat_send_player(player, p .." (" .. rank .. ")")
					end
					return true
				end
			else
				minetest.chat_send_player(player, "Players in faction " .. f.name .. ": ")
				for p, rank in pairs(f.players) do
					minetest.chat_send_player(player, p .." (" .. rank .. ")")
				end
				return true
			end
		else
			f = factions.get_player_faction(player)
			if not f and not f.players then
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
},true)

local parcel_size_center = factions_config.parcel_size / 2

factions.register_command("show_parcel", {
    description = "Shows parcel for six seconds.",
	description_arg = ":",
	global_privileges = def_global_privileges,
	infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
		local parcel_faction = factions.get_parcel_faction(parcelpos)
		
		if not parcel_faction then
			send_error(player, "There is no claim here")
			return false
		end
		
		local psc = parcel_size_center
		local fps = factions_config.parcel_size

		local ppos = {x = (math.floor(pos.x / fps) * fps) + psc, y = (math.floor(pos.y / fps) * fps) + psc, z = (math.floor(pos.z / fps) * fps) + psc}
		minetest.add_entity(ppos, "factions:display")
        return true
    end
},false)

factions.register_command("new_rank", {
    description = "Add a new rank.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if faction.ranks[rank] then
				send_error(player, "Rank already exists")
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
					send_error(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					send_error(player, "No permission was given.")
				end
				return false
			end
			factions.add_rank(faction.name, rank, args.other)
			return true
		end
		send_error(player, "No rank was given.")
		return false
    end
},true)

factions.register_command("replace_privs", {
    description = "Deletes current permissions and replaces them with the ones given.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if not faction.ranks[rank] then
				send_error(player, "Rank does not exist")
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
					send_error(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					send_error(player, "No permission was given.")
				end
				return false
			end
			factions.replace_privs(faction.name, rank, args.other)
			return true
		end
		send_error(player, "No rank was given.")
		return false
    end
},true)

factions.register_command("remove_privs", {
    description = "Remove permissions from a rank.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if not faction.ranks[rank] then
				send_error(player, "Rank does not exist")
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
					send_error(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					send_error(player, "No permission was given.")
				end
				return false
			end
			factions.remove_privs(faction.name, rank, args.other)
			return true
		end
		send_error(player, "No rank was given.")
		return false
    end
},true)

factions.register_command("add_privs", {
    description = "add permissions to a rank.",
	description_arg = " <rank> <privs>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
		if args.strings[1] then
			local rank = args.strings[1]
			if not faction.ranks[rank] then
				send_error(player, "Rank does not exist")
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
					send_error(player, "Permission " .. args.strings[failindex] .. " is invalid.")
				else
					send_error(player, "No permission was given.")
				end
				return false
			end
			factions.add_privs(faction.name, rank, args.other)
			return true
		end
		send_error(player, "No rank was given.")
		return false
    end
},true)

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
            send_error(player, "The rank does not exist.")
            return false
        end
		if faction.ranks[newrank] then
            send_error(player, "This rank name was already taken.")
            return false
        end
        factions.set_rank_name(faction.name, rank, newrank)
        return true
    end
},false)

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
            send_error(player, "One of the specified ranks does not exist.")
            return false
        end
        factions.delete_rank(faction.name, rank, newrank)
        return true
    end
},false)

factions.register_command("set_def_rank", {
    description = "Change the default rank given to new players and also replace rankless players in this faction",
	description_arg = " <rank>:",
    format = {"string"},
    faction_permissions = {"ranks"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        if not faction.ranks[rank] then
            send_error(player, "This rank does not exist.")
            return false
        end
        factions.set_def_rank(faction.name, rank)
        return true
    end
},false)

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
},false)

factions.register_command("sethome", {
    description = "Set the faction's spawn",
	description_arg = ":",
    faction_permissions = {"spawn"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.set_spawn(faction.name, pos)
        return true
    end
},false)

factions.register_command("unsethome", {
    description = "Set the faction's spawn to zero",
	description_arg = ":",
    faction_permissions = {"spawn"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.set_spawn(faction.name, {x = 0, y = 0, z = 0})
        return true
    end
},false)

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
	},false)
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
},false)

factions.register_command("help", {
    description = "Shows help for commands.",
	description_arg = ":",
    infaction = false,
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        factions_chat.show_help(player)
        return true
    end
},false)

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
},false)

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
			
			if player_faction and promoter_facname == facname then
				factions.promote(faction.name, name, rank)
				minetest.chat_send_player(player, "Promoted " .. name .. " to " .. rank .. "!")
				return true
			elseif not player_faction or promoter_facname ~= facname then
				send_error(player, name .. " is not in your faction")
				return false
			else
				send_error(player, name .. " cannot be promoted from your faction")
				return false
			end
        else
            send_error(player, "The specified rank does not exist.")
            return false
        end
    end
},false)

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
},false)

factions.register_command("free", {
    description = "Forcefully frees a parcel",
	description_arg = ":",
    infaction = false,
    global_privileges = {"faction_admin"},
    on_success = function(player, faction, pos, parcelpos, args)
        local parcel_faction = factions.get_parcel_faction(parcelpos)
        if not parcel_faction then
            send_error(player, "No claim at this position")
            return false
        else
            factions.unclaim_parcel(parcel_faction.name, parcelpos)
            return true
        end
    end
},false)

factions.register_command("chat", {
    description = "Send a message to your faction's members",
	description_arg = " <message>:",
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local msg = table.concat(args.strings, " ")
        factions.broadcast(faction.name, msg, player)
    end
},true)

factions.register_command("force_update", {
    description = "Forces an update tick.",
	description_arg = ":",
    global_privileges = {"faction_admin"},
	infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        factions.faction_tick()
    end
},false)

factions.register_command("player", {
    description = "Get which faction a player is in",
	description_arg = " <player>:",
    infaction = false,
    format = {"string"},
	global_privileges = def_global_privileges,
    on_success = function(player, faction, pos, parcelpos, args)
        local playername = args.strings[1]
		if not playername then
			playername = player
		end
        local faction1, facname = factions.get_player_faction(playername)
        if not faction1 then
            send_error(player, "Player " .. playername .. " does not belong to any faction")
            return false
        else
            minetest.chat_send_player(player, "player " .. playername .. " belongs to faction " .. faction1.name)
            return true
        end
    end
},true)

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
            send_error(player, "Player " .. playername .. " is not in faction " .. targetfaction.name .. ".")
            return false
        end
        factions.set_leader(targetfaction.name, playername)
        return true
    end
},false)

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
},false)

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
},false)

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
},false)


factions.register_command("obliterate", {
    description = "Remove all factions",
	description_arg = ":",
    infaction = false,
    global_privileges = {"faction_admin"},
    on_success = function(player, faction, pos, parcelpos, args)
        for i, facname in pairs(factions.get_faction_list()) do
            factions.disband(facname, "obliterated")
        end
        return true
    end
},false)

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
            send_error(player, "Faction has no spawn set.")
            return false
        end
    end
},false)

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
},false)

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
},false)

-------------------------------------------------------------------------------
-- name: cmdhandler(playername, parameter)
--
--! @brief chat command handler
--! @memberof factions_chat
--! @private
--
--! @param playername name
--! @param parameter data supplied to command
-------------------------------------------------------------------------------
factions_chat.cmdhandler = function (playername,parameter)

	local player = minetest.env:get_player_by_name(playername)
	local params = parameter:split(" ")
    local player_faction, facname = factions.get_player_faction(playername)

	if parameter == nil or
		parameter == "" then
        if player_faction then
            minetest.chat_send_player(playername, "You are in faction " .. player_faction.name .. ". Type /f help for a list of commands.")
        else
            minetest.chat_send_player(playername, "You are part of no faction")
        end
		return
	end

	local cmd = factions.commands[params[1]]
    if not cmd then
        send_error(playername, "Unknown command.")
        return false
    end

    local argv = {}
    for i=2, #params, 1 do
        table.insert(argv, params[i])
    end
	
    cmd:run(playername, argv)

end

function table_Contains(t, v)
	for k, a in pairs(t) do
		if a == v then
			return true
		end		
	end
	return false
end

local premade_help = ""

local premade_help_admin = ""

local a_z = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}

for l, j in pairs(a_z) do
	for k, v in pairs(factions.commands) do
		if k:sub(1, 1) == j then
			if not v.dont_show_in_help then
				if not table_Contains(v.global_privileges, "faction_admin") then
					premade_help = premade_help .. "\t/f " .. k .. v.description_arg .. " " .. v.description .. "\n"
				end
				premade_help_admin = premade_help_admin .. "\t/f " .. k .. v.description_arg .. " " .. v.description .. "\n"
			end
		end
	end
end

a_z = nil

-------------------------------------------------------------------------------
-- name: show_help(playername, parameter)
--
--! @brief send help message to player
--! @memberof factions_chat
--! @private
--
--! @param playername name
-------------------------------------------------------------------------------
function factions_chat.show_help(playername)

	local MSG = function(text)
		minetest.chat_send_player(playername, text, false)
	end
	
	MSG("factions mod")
	MSG("Usage:")
	local has, missing = minetest.check_player_privs(playername,  {
    faction_admin = true})
	if has then
		MSG(premade_help_admin)
	else
		MSG(premade_help)
	end
end

init_commands()
