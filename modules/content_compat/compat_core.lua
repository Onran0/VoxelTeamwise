local compat_core = { }

local originals = { }

function compat_core.copy_library(name)
	local copy = table.copy(_G[name])

	originals[name] = copy

	return copy
end

function compat_core.restore_all_libraries()
	for libraryName, libraryOriginal in pairs(originals) do
		for fieldName, fieldValue in pairs(libraryOriginal) do
			_G[libraryName][fieldName] = fieldValue
		end
	end

	originals = { }
end

return compat_core