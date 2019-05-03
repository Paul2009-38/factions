function factions.increase_power(name, power)
	local faction = factions.factions.get(name)
	
    faction.power = faction.power + power
	
    if faction.power > faction.maxpower  - faction.usedpower then
        faction.power = faction.maxpower - faction.usedpower
    end
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
    
	factions.factions.set(name, faction)
end

function factions.decrease_power(name, power)
    local faction = factions.factions.get(name)
	
	faction.power = faction.power - power
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
    
	factions.factions.set(name, faction)
end

function factions.increase_maxpower(name, power)
    local faction = factions.factions.get(name)
	
	faction.maxpower = faction.maxpower + power
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
    
	factions.factions.set(name, faction)
end

function factions.decrease_maxpower(name, power)
    local faction = factions.factions.get(name)
	
	faction.maxpower = faction.maxpower - power
	
    if faction.maxpower < 0. then -- should not happen
        faction.maxpower = 0.
    end
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
	
	factions.factions.set(name, faction)
end

function factions.increase_usedpower(name, power)
	local faction = factions.factions.get(name)

    faction.usedpower = faction.usedpower + power
	
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
	
	factions.factions.set(name, faction)
end

function factions.decrease_usedpower(name, power)
   local faction = factions.factions.get(name)
   
   faction.usedpower = faction.usedpower - power
    if faction.usedpower < 0. then
        faction.usedpower = 0.
    end
	for i in pairs(factions.onlineplayers[name]) do
		updateHudPower(minetest.get_player_by_name(i), faction)
	end
	
	factions.factions.set(name, faction)
end
