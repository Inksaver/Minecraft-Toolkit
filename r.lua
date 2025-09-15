version = 20250915.1500
-- Last edited: see version YYYYMMDD.HHMM
local usage = [[r = 1 turn to right
r # : moves # turns to right]]
args = {...}

function main()
	local numTurns = 0

	if args[1] ~= nil then
		if args[1]:lower() == "h" then
			term.clear()
			term.setCursorPos(1,1)
			print(usage)
			print("Fuel Level: "..turtle.getFuelLevel())
			error()
		else
			numTurns = tonumber(args[1])
			if numTurns == nil then
				print("Use a number as argument, not "..args[1])
				error()
			end
			for i = 1, numTurns do
				turtle.turnRight()
			end
		end
	else
		turtle.turnRight()
		numTurns = 1
	end

	print("Turned Right "..numTurns.." times. Fuel: "..turtle.getFuelLevel())
end

main()
