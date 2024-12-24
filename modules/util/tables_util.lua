local tables_util = { }

function tables_util.equals(a, b, deep)
	local len = #a

	if len ~= #b then return false end

	local arr = is_array(a)

	if arr ~= is_array(b) then return false end

	local at, bt

	if arr then
		if not deep then
			for i = 1, len do
				if a[i] ~= b[i] then return false end
			end
		else
			for i = 1, len do
				at, bt = type(a[i]), type(b[i])

				if at ~= bt then return false
				elseif at == "table" then
					if not tables_util.equals(a[i], b[i], deep) then return false end
				elseif a[i] ~= b[i] then return false end
			end
		end
	elseif table.count_pairs(a) ~= table.count_pairs(b) then return false
	else
		if not deep then
			for key, value in pairs(a) do
				if b[key] ~= value then return false end
			end
		else
			for key, value in pairs(a) do
				at, bt = type(value), type(b[key])

				if at ~= bt then return false
				elseif at == "table" then
					if not tables_util.equals(a[i], b[i], deep) then return false end
				elseif value ~= b[key] then return false end
			end
		end
	end

	return true
end

return tables_util