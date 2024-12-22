local ops_manager = { }

function ops_manager:new(server)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.server = server
    self.opsList = { }

    return obj
end

function ops_manager:load_data(path)
	if file.exists(path) then
		self.opsList = file.readlines(path)
	end
end

function ops_manager:save_data(path)
	local text = ""

    for i = 1, #self.opsList do
        text = text..self.opsList[i]..'\n'
    end

    file.write(path, text)
end

function ops_manager:assign_operator_status(name)
    if not table.has(self.opsList, name) then
        table.insert(self.opsList, name)
        self.server:log("player with nickname '"..name.."' is now operator")
    end
end

function ops_manager:remove_operator_status(name)
    if table.has(self.opsList, name) then
        table.remove(self.opsList, table.index(self.opsList, name))
        self.server:log("player with nickname '"..name.."' is no longer an operator")
    end
end

function ops_manager:is_operator(name)
    return table.has(self.opsList, name)
end

return ops_manager