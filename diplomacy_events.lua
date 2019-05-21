function factions.start_diplomacy(name, faction)
	for l, i in factions.factions.iterate() do
		local fac = factions.factions.get(l)
		if l ~= name and not (faction.neutral[l] or faction.allies[l] or faction.enemies[l]) then
			if factions_config.faction_diplomacy == true then
				factions.new_neutral(name, l)
				factions.new_neutral(l, name)
			else
				factions.new_enemy(name, l)
				factions.new_enemy(l, name)
			end
		end
	end
end

function factions.new_alliance(name, faction)
	local bfaction = factions.factions.get(name)
	
    bfaction.allies[faction] = true
    factions.on_new_alliance(name, faction)
    if bfaction.enemies[faction] then
        factions.end_enemy(name, faction)
    end
	if bfaction.neutral[faction] then
        factions.end_neutral(name, faction)
    end
    
	factions.factions.set(name, bfaction)
end

function factions.end_alliance(name, faction)
    local bfaction = factions.factions.get(name)
	
	bfaction.allies[faction] = nil
    factions.on_end_alliance(name, faction)
    
	factions.factions.set(name, bfaction)
end

function factions.new_neutral(name, faction)
	local bfaction = factions.factions.get(name)
	
    bfaction.neutral[faction] = true
    
	factions.on_new_neutral(name, faction)
    if bfaction.allies[faction] then
        factions.end_alliance(name, faction)
    end
    if bfaction.enemies[faction] then
        factions.end_enemy(name, faction)
    end
    
	factions.factions.set(name, bfaction)
end

function factions.end_neutral(name, faction)
    local bfaction = factions.factions.get(name)
	
	bfaction.neutral[faction] = nil
    factions.on_end_neutral(name, faction)
    
	factions.factions.set(name, bfaction)
end

function factions.new_enemy(name, faction)
	local bfaction = factions.factions.get(name)
	
	bfaction.enemies[faction] = true
    factions.on_new_enemy(name, faction)
	
    if bfaction.allies[faction] then
        factions.end_alliance(name, faction)
    end
	
	if bfaction.neutral[faction] then
        factions.end_neutral(name, faction)
    end
    
	factions.factions.set(name, bfaction)
end

function factions.end_enemy(name, faction)
    local bfaction = factions.factions.get(name)
	
	bfaction.enemies[faction] = nil
    factions.on_end_enemy(name, faction)
    
	factions.factions.set(name, bfaction)
end