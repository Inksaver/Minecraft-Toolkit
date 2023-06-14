version = 20220429.1155
-- pastebin get Z9GBSM8e x.lua
-- https://pastebin.com/Z9GBSM8e
-- Last edited: see version YYYYMMDD.HHMM
local usage = [[x u or x 0 digUp()
x or x f or x 1 dig()
x d or x 2 digDown()]]
args = {...}

function main()
	local success = false
	local errorMessage = ""
	if args[1] ~= nil then
		if args[1]:lower() == "h" then
			term.clear()
			term.setCursorPos(1,1)
			print(usage)
			print("Fuel Level: "..turtle.getFuelLevel())
			error()
		else
			if args[1]:lower() == "u" or args[1] == "0" then
				success, errorMessage = turtle.digUp()
			elseif args[1]:lower() == "f" or args[1] == "1" then
				success, errorMessage = turtle.dig()
			elseif args[1]:lower() == "d" or args[1] == "2" then
				success, errorMessage = turtle.digDown()
			end
		end
	else -- assume forward
		success, errorMessage = turtle.dig()
	end
	if success then
		print("Block excavated")
	else
		print(errorMessage)
	end
end

main()