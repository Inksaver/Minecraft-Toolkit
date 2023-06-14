version = 20220422.1005
-- https://pastebin.com/yWDKZpvj
-- pastebin get yWDKZpvj l.lua
-- Last edited: see version YYYYMMDD.HHMM
local usage = [[l = 1 turn to left
l # : moves # turns to left]]
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
				turtle.turnLeft()
			end
		end
	else
		turtle.turnLeft()
		numTurns = 1
	end

	print("Turned Left "..numTurns.." times. Fuel: "..turtle.getFuelLevel())
end

main()