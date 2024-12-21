local math_util = { }

function math_util.lerp_number(from, to, amount)
    return from + (to - from) * math.clamp(amount, 0, 1)
end

function math_util.lerp_vector(from, to, amount)
	local len = #from

	if len ~= #to then error "different dimensions of vectors" end

	local vec = { }

	for i = 1, len do
		vec[i] = math_util.lerp_number(from[i], to[i], amount)
	end

	return vec
end

function math_util.vec3_equals(v1, v2)
	return
	v1[1] == v2[1] and
	v1[2] == v2[2] and
	v1[3] == v2[3]
end

function math_util.vecn_equals(v1, v2)
	local len = #v1

	if len ~= #v2 then error "different dimensions of vectors" end
	
	for i = 1, len do
		if v1[i] ~= v2[i] then return false end
	end

	return true
end

function math_util.rotation_matrix(vec)
	return
	mat4.rotate(
		mat4.rotate(
			mat4.rotate(
				{ 1, 0, 0 },
				vec[1]
			),
			{ 0, 1, 0 },
			vec[2]
		),
		{ 0, 0, 1 },
		vec[3]
	)
end

return math_util