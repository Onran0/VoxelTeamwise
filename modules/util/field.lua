local field = { }

function field:wrap(object, ...)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    local properties = { ... }

 	if #properties == 1 and type(properties[1]) == "table" then properties = properties[1] end

 	local property = properties[1]

 	if #properties > 1 then
	    for i = 2, #properties do
	    	object = object[property]
	    	property = properties[i]
	    end
	end

    self.object = object
    self.property = property

	return obj
end

function field:get() return self.object[self.property] end

function field:set(value) self.object[self.property] = value end

return field