--! @param parcelpos position of the wanted parcel
--! @return whether this faction can claim a parcelpos
function factions.can_claim_parcel(name, parcelpos)
    local fn = factions.parcels.get(parcelpos)
	
	if fn == nil then
		return true
	end
	
	local faction = factions.factions.get(name)
	
	if fn then
		local fac = factions.factions.get(fn)
		
        if fac.power < 0. and faction.power >= factions_config.power_per_parcel and not faction.allies[fn] and not faction.neutral[fn] then
            return true
        else
            return false
        end
    elseif faction.power < factions_config.power_per_parcel then
        return false
    end
	
    return true
end

--! @brief claim a parcel, update power and update global parcels table
function factions.claim_parcel(name, parcelpos)
    -- check if claiming over other faction's territory
    local otherfac = factions.parcels.get(parcelpos)
    if otherfac then
        factions.unclaim_parcel(otherfac, parcelpos)
		factions.parcelless_check(otherfac)
    end
    factions.parcels.set(parcelpos, name)
	
	local faction = factions.factions.get(name)
	
    faction.land[parcelpos] = true
	
	factions.factions.set(name, faction)
	
    factions.decrease_power(name, factions_config.power_per_parcel)
    factions.increase_usedpower(name, factions_config.power_per_parcel)
    factions.on_claim_parcel(name, parcelpos)
	factions.parcelless_check(name)
end

--! @brief claim a parcel, update power and update global parcels table
function factions.unclaim_parcel(name, parcelpos)
    factions.parcels.remove(parcelpos)
	
	local faction = factions.factions.get(name)
	
    faction.land[parcelpos] = nil
	
	factions.factions.set(name, faction)
	
    factions.increase_power(name, factions_config.power_per_parcel)
    factions.decrease_usedpower(name, factions_config.power_per_parcel)
    factions.on_unclaim_parcel(name, parcelpos)
	factions.parcelless_check(name)
end

function factions.parcelless_check(name)
	local faction = factions.factions.get(name)
	
	if faction.land then
		local count = 0
		for index, value in pairs(faction.land) do
			count = count + 1
			break
		end
		if count > 0 then
			if faction.no_parcel ~= -1 then
				factions.broadcast(name, "Faction " .. name .. " will not be disbanded because it now has parcels.")
			end
			faction.no_parcel = -1
		else
			faction.no_parcel = os.time()
			factions.on_no_parcel(name)
		end
		factions.factions.set(name, faction)
	end
end

function factions.get_parcel_faction(parcelpos)
    local facname = factions.parcels.get(parcelpos)
    if facname then
        local faction = factions.factions.get(facname)
        return faction, facname
    end
    return nil
end

function claim_helper(player, faction, parcelpos, no_msgs)
	faction = factions.factions.get(faction.name)
	if not faction then
		return false
	end
	if faction.power < factions_config.power_per_parcel then
		if not no_msgs then
			minetest.chat_send_player(player, "Not enough power.")
		end
		return false
	end
	local p = parcelpos
	local can_claim = factions.can_claim_parcel(faction.name, p)
	
	if can_claim then
		minetest.chat_send_player(player, "Claming parcel " .. p)
		factions.claim_parcel(faction.name, p)
		return true
	else
		local parcel_faction = factions.get_parcel_faction(p)
		if parcel_faction and parcel_faction.name == faction.name then
			if not no_msgs then
				minetest.chat_send_player(player, "This parcel already belongs to your faction")
			end
			return false
		elseif parcel_faction and parcel_faction.name ~= faction.name then
			if not no_msgs then
				minetest.chat_send_player(player, "This parcel belongs to another faction")
			end
			return false
		else
			if not no_msgs then
				minetest.chat_send_player(player, "Your faction cannot claim any (more) parcel(s).")
			end
			return false
		end
	end
end

function unclaim_helper(player, faction, parcelpos, no_msgs)
	faction = factions.factions.get(faction.name)
	if not faction then
		return false
	end
	local parcel_faction = factions.get_parcel_faction(parcelpos)
	if not parcel_faction then
		if not no_msgs then
			minetest.chat_send_player(player, "This parcel does not exist.")
		end
		return false
	end
	if parcel_faction.name ~= faction.name then
		if not no_msgs then
			minetest.chat_send_player(player, "This parcel does not belong to you.")
		end
		return false
	else
		factions.unclaim_parcel(faction.name, parcelpos)
		return true
	end
end

local parcel_size = factions_config.parcel_size

function factions.claim_square(player, faction, r)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = math.floor(pos.x / parcel_size) * parcel_size
	pos.z = math.floor(pos.z / parcel_size) * parcel_size
	
	pos.x = pos.x - (parcel_size * (r - math.floor(r / 2)))
	pos.z = pos.z - (parcel_size * (r - math.floor(r / 2)))
	
	local timer = 0
	
	for i = 1, r do
		for l = 1, r do
			local p = {x = pos.x + (parcel_size * l), y = pos.y, z = pos.z + (parcel_size * i)}
			minetest.after(timer, claim_helper, player, faction, factions.get_parcel_pos(p), true)
			
			timer = timer + 0.1
		end
	end
end

local auto_list = {}

local function _claim_auto(player, faction)
	if auto_list[player] then
		local rplayer = minetest.get_player_by_name(player)
		local parcelpos = vector.round(rplayer:get_pos())
		claim_helper(player, faction, factions.get_parcel_pos(parcelpos), true)
		minetest.after(0.1, _claim_auto, player, faction)
	end
end

function factions.claim_auto(player, faction)
	if auto_list[player] then
		auto_list[player] = nil
		minetest.chat_send_player(player, "Auto claim disabled.")
	else
		auto_list[player] = true
		minetest.chat_send_player(player, "Auto claim enabled.")
		_claim_auto(player, faction)
	end
end

local function _claim_fill(player, faction, pos)
	if claim_helper(player, faction, factions.get_parcel_pos(pos), true) then
		local pos1 = {x = pos.x - parcel_size, y = pos.y, z = pos.z}
		minetest.after(math.random(0, 11) / 10, _claim_fill, player, faction, pos1)
		local pos2 = {x = pos.x + parcel_size, y = pos.y, z = pos.z}
		minetest.after(math.random(0, 11) / 10, _claim_fill, player, faction, pos2)
		local pos3 = {x = pos.x, y = pos.y, z = pos.z - parcel_size}
		minetest.after(math.random(0, 11) / 10, _claim_fill, player, faction, pos3)
		local pos4 = {x = pos.x, y = pos.y, z = pos.z + parcel_size}
		minetest.after(math.random(0, 11) / 10, _claim_fill, player, faction, pos4)
	end
end

function factions.claim_fill(player, faction)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = math.floor(pos.x / parcel_size) * parcel_size
	pos.z = math.floor(pos.z / parcel_size) * parcel_size
	
	_claim_fill(player, faction, pos)
end

local parcel_size_center = parcel_size / 2

function factions.claim_circle(player, faction, r)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = (math.floor(pos.x / parcel_size) * parcel_size) + parcel_size_center
	pos.z = (math.floor(pos.z / parcel_size) * parcel_size) + parcel_size_center
	
	for i = 1, 360 do
		minetest.after(0.05 * i, function(player, faction, r, pos)
			
			local angle = i * math.pi / 180
			
			local rpos = {x = pos.x + r * math.cos(angle), y = pos.y, z = pos.z + r * math.sin(angle)}
			
			claim_helper(player, faction, factions.get_parcel_pos(rpos), true)
			
		end, player, faction, r, pos)
	end
end

local function _claim_all(player, faction, pos)
	if faction.power >= factions_config.power_per_parcel then
		claim_helper(player, faction, factions.get_parcel_pos(pos), true)
		local pos1 = {x = pos.x - parcel_size, y = pos.y, z = pos.z}
		minetest.after(math.random(0, 11) / 10, _claim_all, player, faction, pos1)
		local pos2 = {x = pos.x + parcel_size, y = pos.y, z = pos.z}
		minetest.after(math.random(0, 11) / 10, _claim_all, player, faction, pos2)
		local pos3 = {x = pos.x, y = pos.y, z = pos.z - parcel_size}
		minetest.after(math.random(0, 11) / 10, _claim_all, player, faction, pos3)
		local pos4 = {x = pos.x, y = pos.y, z = pos.z + parcel_size}
		minetest.after(math.random(0, 11) / 10, _claim_all, player, faction, pos4)
	end
end

function factions.claim_all(player, faction)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = math.floor(pos.x / parcel_size) * parcel_size
	pos.z = math.floor(pos.z / parcel_size) * parcel_size
	
	_claim_all(player, faction, pos)
end

function factions.claim_help(player, func)
	local text = "<o,one, a,auto, f,fill, s,square, c,circle, all, h,help>, <none, number>"
	
	if func == "o" or func == "one" then
		text = "/f claim o\n/f claim one\n Claim one parcel."
	elseif func == "a" or func == "auto" then
		text = "/f claim a\n/f claim auto\nClaim as you walk around."
	elseif func == "f" or func == "fill" then
		text = "/f claim f\n/f claim fill\nClaim by filling."
	elseif func == "s" or func == "square" then
		text = "/f claim s <number>\n/f claim square <number>\nClaim by square and radius."
	elseif func == "c" or func == "circle" then
		text = "/f claim c <number>\n/f claim circle <number>\nClaim by circle and radius."
	elseif func == "all" then
		text = "/f claim all\nClaim all faction land."
	end
	
	minetest.chat_send_player(player, text)
end

function factions.unclaim_square(player, faction, r)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = math.floor(pos.x / parcel_size) * parcel_size
	pos.z = math.floor(pos.z / parcel_size) * parcel_size
	
	pos.x = pos.x - (parcel_size * (r - math.floor(r / 2)))
	pos.z = pos.z - (parcel_size * (r - math.floor(r / 2)))
	
	local timer = 0
	
	for i = 1, r do
		for l = 1, r do
			local p = {x = pos.x + (parcel_size * l), y = pos.y, z = pos.z + (parcel_size * i)}
			minetest.after(timer, unclaim_helper, player, faction, factions.get_parcel_pos(p), true)
			
			timer = timer + 0.1
		end
	end
end

local function _unclaim_auto(player, faction)
	if auto_list[player] then
		local rplayer = minetest.get_player_by_name(player)
		local parcelpos = vector.round(rplayer:get_pos())
		unclaim_helper(player, faction, factions.get_parcel_pos(parcelpos), true)
		minetest.after(0.1, _unclaim_auto, player, faction)
	end
end

function factions.unclaim_auto(player, faction)
	if auto_list[player] then
		auto_list[player] = nil
		minetest.chat_send_player(player, "Auto unclaim disabled.")
	else
		auto_list[player] = true
		minetest.chat_send_player(player, "Auto unclaim enabled.")
		_unclaim_auto(player, faction)
	end
end

local function _unclaim_fill(player, faction, pos)
	if unclaim_helper(player, faction, factions.get_parcel_pos(pos), true) then
		local pos1 = {x = pos.x - parcel_size, y = pos.y, z = pos.z}
		minetest.after(math.random(0, 11) / 10, _unclaim_fill, player, faction, pos1)
		local pos2 = {x = pos.x + parcel_size, y = pos.y, z = pos.z}
		minetest.after(math.random(0, 11) / 10, _unclaim_fill, player, faction, pos2)
		local pos3 = {x = pos.x, y = pos.y, z = pos.z - parcel_size}
		minetest.after(math.random(0, 11) / 10, _unclaim_fill, player, faction, pos3)
		local pos4 = {x = pos.x, y = pos.y, z = pos.z + parcel_size}
		minetest.after(math.random(0, 11) / 10, _unclaim_fill, player, faction, pos4)
	end
end

function factions.unclaim_fill(player, faction)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = math.floor(pos.x / parcel_size) * parcel_size
	pos.z = math.floor(pos.z / parcel_size) * parcel_size
	
	_unclaim_fill(player, faction, pos)
end

local parcel_size_center = parcel_size / 2

function factions.unclaim_circle(player, faction, r)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = (math.floor(pos.x / parcel_size) * parcel_size) + parcel_size_center
	pos.z = (math.floor(pos.z / parcel_size) * parcel_size) + parcel_size_center
	
	for i = 1, 360 do
		minetest.after(0.05 * i, function(player, faction, r, pos)
			
			local angle = i * math.pi / 180
			
			local rpos = {x = pos.x + r * math.cos(angle), y = pos.y, z = pos.z + r * math.sin(angle)}
			
			unclaim_helper(player, faction, factions.get_parcel_pos(rpos), true)
			
		end, player, faction, r, pos)
	end
end

local function _unclaim_all(player, faction)
	local timer = 0
	for i in pairs(faction.land) do
		minetest.after(timer, factions.unclaim_parcel, faction.name, i)
		timer = timer + 0.1
	end
end

function factions.unclaim_all(player, faction)
	local rplayer = minetest.get_player_by_name(player)
	local pos = vector.round(rplayer:get_pos())
	
	pos.x = math.floor(pos.x / parcel_size) * parcel_size
	pos.z = math.floor(pos.z / parcel_size) * parcel_size
	
	_unclaim_all(player, faction, pos)
end

function factions.unclaim_help(player, func)
	local text = "<o,one, a,auto, f,fill, s,square, c,circle, all, h,help>, <none, number>"
	
	if func == "o" or func == "one" then
		text = "/f unclaim o\n/f unclaim one\n Unclaim one parcel."
	elseif func == "a" or func == "auto" then
		text = "/f unclaim a\n/f unclaim auto\nUnclaim as you walk around."
	elseif func == "f" or func == "fill" then
		text = "/f unclaim f\n/f unclaim fill\nUnclaim by filling."
	elseif func == "s" or func == "square" then
		text = "/f unclaim s <number>\n/f unclaim square <number>\nUnclaim by square and radius."
	elseif func == "c" or func == "circle" then
		text = "/f unclaim c <number>\n/f unclaim circle <number>\nUnclaim by circle and radius."
	elseif func == "all" then
		text = "/f unclaim all\nUnclaim all faction land."
	end
	
	minetest.chat_send_player(player, text)
end

minetest.register_on_leaveplayer(
	function(player)
		auto_list[player:get_player_name()] = nil
	end
)