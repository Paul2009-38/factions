factions_chat = {}
factions.commands = {}

local function register_command(cmd_name, cmd)
    factions.commands[cmd_name] = { -- default command
        name = cmd_name,
        faction_permissions = {},
        global_privileges = {},
        format = {},
        infaction = true,
		description = "This command has no description.",
		ignore_param_limit = false,
		or_perm = false,
		dont_show_in_help = false,
        run = function(self, player, argv)
            if self.global_privileges then
                local tmp = {}
                for i in ipairs(self.global_privileges) do
                    tmp[self.global_privileges[i]] = true
                end
                local bool, missing_privs = minetest.check_player_privs(player, tmp)
                if not bool then
                    minetest.chat_send_player(player, "Unauthorized.")
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
			if not self.ignore_param_limit then
				if #argv < #(self.format) then
					minetest.chat_send_player(player, "Not enough parameters.")
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
                        minetest.chat_send_player(player, "Specified faction " .. arg .. " does not exist")
                        return false
                    else
                        table.insert(args.factions, fac)
                    end
                elseif argtype == "player" then
					local data = minetest.get_auth_handler().get_auth(arg)
					if data then
						table.insert(args.players, arg)
					else
						minetest.chat_send_player(player, "Player does not exist.")
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
                    if not self.or_perm and not factions.has_permission(facname, player, perm) then
                        minetest.chat_send_player(player, "You do not have the faction permission " .. perm)
                        return false
					elseif self.or_perm and factions.has_permission(facname, player, perm) then
						one_p = true
						break
                    end
                end
            end
			if self.or_perm and one_p == false then
			    minetest.chat_send_player(player, "You do not have any of faction permissions required.")
                return false
			end
            -- get some more data
            local pos = minetest.get_player_by_name(player):get_pos()
            local parcelpos = factions.get_parcel_pos(pos)
            return self.on_success(player, player_faction, pos, parcelpos, args)
        end,
        on_success = function(player, faction, pos, parcelpos, args)
            minetest.chat_send_player(player, "Not implemented yet!")
        end
	}
	-- count cmd spaces.
	local words = cmd_name:split(" ")
	local word_spaces = 0
	for k in pairs(words) do
		word_spaces = word_spaces + 1
	end
	cmd.word_spaces = word_spaces
    -- override defaults
    for k, v in pairs(cmd) do
        factions.commands[cmd_name][k] = v
    end
end

function factions.register_command(cmd_name, cmd)
	local cmd_type = type(cmd_name)
	local next = false
	if cmd_type == "string" then
	register_command(cmd_name, cmd)
	elseif cmd_type == "table" then
		for k, v in pairs(cmd_name) do
			if next and cmd.dont_show_in_help == nil then
				cmd.dont_show_in_help = true
			end
			register_command(v, cmd)
			next = true
		end
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

local def_global_privileges = nil
if factions_config.faction_user_priv == true then
	minetest.register_on_newplayer(function(player)
		local name = player:get_player_name()
		local privs = minetest.get_player_privs(name)
		privs.faction_user = true
		minetest.set_player_privs(name, privs)
	end)
	def_global_privileges = {"faction_user"}
end
local path = minetest.get_modpath("fac_chat")
dofile(path .. "/commands.lua")
dofile(path .. "/subcommands.lua")

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
function factions_chat.cmdhandler(playername, parameter)
	local player = minetest.env:get_player_by_name(playername)
	local params = parameter:split(" ")
    local player_faction, facname = factions.get_player_faction(playername)
	if parameter == nil or parameter == "" then
        if player_faction then
            minetest.chat_send_player(playername, "You are in faction " .. player_faction.name .. ". Type /f help for a list of commands.")
        else
            minetest.chat_send_player(playername, "You are part of no faction")
        end
		return
	end
	--local cmd = factions.commands[params[1]]
	local cmd = factions.commands[parameter]
	if not cmd then
		cmd = factions.commands[params[1]]
		if not cmd then
			minetest.chat_send_player(playername, "Unknown command.")
			return false
		end
	end
    local argv = {}
    for i = 1 + cmd.word_spaces, #params, 1 do
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
local a_z = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e"
			, "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
function factions.create_help_text()
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
end

minetest.register_on_mods_loaded(function()
	factions.create_help_text()
end)
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
	local msg = "factions mod\nUsage:\n"
	local has, missing = minetest.check_player_privs(playername, {faction_admin = true})
	if has then
		msg = msg .. premade_help_admin
	else
		msg = msg .. premade_help
	end
	minetest.chat_send_player(playername, msg, false)
end

init_commands()
