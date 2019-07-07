local storage = minetest.get_mod_storage()
storagedb = {}

function storagedb.Storagedb(dir)
	local self = {}
	
	local directory = dir
	local mem_pool = {}
	local mem_pool_del = {}
	local add_to_mem_pool = true
	local serializer = minetest.serialize
	local deserializer = minetest.deserialize
	
	-- make tables weak so the garbage-collector will remove unused data
	setmetatable(mem_pool, {__mode = "kv"})
	setmetatable(mem_pool_del, {__mode = "kv"})

	local function storekey(key)
        local list = minetest.deserialize(storage:get_string(directory))
        if not list then
            list = {}
            list[dir .. "/" .. key] = key
        else
            list[dir .. "/" .. key] = key
        end
        storage:set_string(directory, minetest.serialize(list))
    end
    local function removekey(key)
        local list = minetest.deserialize(storage:get_string(directory))
        if not list then
            list = {}
        else
            list[dir .. "/" .. key] = nil
        end
        storage:set_string(directory, minetest.serialize(list))
    end
    local function getkeys()
        local list = minetest.deserialize(storage:get_string(directory))
        if not list then
            list = {}
        end
        return list
    end
	
	self.get_memory_pool = function()
		return mem_pool
	end
	self.set_memory_pool = function(pool)
		mem_pool = pool
	end
	self.add_to_memory_pool = function(value)
		if value then
			add_to_mem_pool = value
		end
		return add_to_mem_pool
	end
	self.get_serializer = function()
		return serializer, deserializer
	end
	self.set_serializer = function(coder, decoder)
		serializer = coder
		deserializer = decoder
	end
	local function load_into_mem(name, _table)
		if add_to_mem_pool then
			mem_pool[name] = {mem = _table}
		end
	end
	local function load_table(name)
		local f = storage:get_string(string.format("%s/%s", directory, name))
		if f then
			local data = deserializer(f)
			return data
		end
		return nil
	end
	local function save_table(name, _table)
		if save_table == nil or name == nil then
			return false
		end
		storekey(name)
		storage:set_string(string.format("%s/%s", directory, name), minetest.serialize(_table))
	end
	local function save_key(name)
		storage:set_string(string.format("%s/%s", directory, name), "")
	end
	local function load_key(name)
		local f = storage:get_string(string.format("%s/%s", directory, name))
		if f ~= "" then
			return true
		end
		return false
	end
	self.set_mem = function(name, _table)
		load_into_mem(name, _table)
		mem_pool_del[name] = nil
	end
	self.save_mem = function(name)
		if mem_pool[name] ~= nil then
			save_table(name, mem_pool[name].mem)
		end
		mem_pool_del[name] = nil
	end
	
	self.clear_mem = function(name)
		mem_pool[name] = nil
		mem_pool_del[name] = nil
	end

	self.set = function(name, _table)
		save_table(name, _table)
		if add_to_mem_pool then
			load_into_mem(name, _table)
		end
		mem_pool_del[name] = nil
	end

	self.set_key = function(name)
		save_key(name)
		if add_to_mem_pool then
			load_into_mem(name, "")
		end
		mem_pool_del[name] = nil
	end

	self.get = function(name, callback)
		if mem_pool_del[name] then
			if callback then
				callback(nil)
			end
			return nil
		end
		local pm = mem_pool[name]
		if pm then
			if callback then
				callback(pm.mem)
			end
			return pm.mem
		else
			local _table = load_table(name)
			if _table then
				load_into_mem(name, _table)
				if callback then
					callback(_table)
				end
				return _table
			end
		end
		mem_pool_del[name] = true
		return nil
	end

	self.remove = function(name)
		mem_pool[name] = nil
		mem_pool_del[name] = true
		removekey(name)
		storage:set_string(string.format("%s/%s", directory, name), "")
	end

	self.sub_database = function(path)
		local db = storagedb.Storagedb(dir .. "/" .. path)
		return db
	end
	self.to_array = function()
		local entries = {}

		for k, v in pairs(getkeys()) do
			entries[#entries + 1] = v
		end

		return entries
	end
	self.to_table = function()
		local entries = {}

		for k, v in pairs(getkeys()) do
			entries[v] = true
		end

		return entries
	end
	self.iterate = function()
		local entries = {}

		for k, v in pairs(getkeys()) do
			entries[v] = true
		end

		return pairs(entries)
	end
	
	return self
end
