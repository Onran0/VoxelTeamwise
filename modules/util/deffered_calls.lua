local deffered_calls = { }

local calls = { }

function deffered_calls.add(fn, ticksForWait)
	if ticksForWait then
		if ticksForWait <= 0 then error "ticks for wait must be high than zero" end
	else ticksForWait = 1 end

	table.insert(calls, { fn, ticksForWait })
end

function deffered_calls.process()
	for i = 1, #calls do
		local defferedCall = calls[i]

		local ticksForWait = defferedCall[2] - 1

		if ticksForWait == 0 then
			local status, error = pcall(deffered_calls[1])

			if not status then print("deferred call error:", error) end

			table.remove(calls, i)
			
			i = i - 1
		else defferedCall[2] = ticksForWait end
	end
end

return deffered_calls