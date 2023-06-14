version = 20220423.1005
-- https://pastebin.com/g7DjxRbr
-- pastebin get g7DjxRbr b.lua
-- Last edited: see version YYYYMMDD.HHMM
local usage = {}
usage.backwards = [[
b 10  :moves 10 blocks back unless
obstructed. No blocks broken

b 10 d :moves 10 blocks back unless
bedrock. Blocks are removed.

'd' or any character / string is ok]]
usage.down = [[
d 10  :moves 10 blocks down unless
obstructed. No blocks broken

d 10 d :moves 10 blocks down unless
bedrock. Blocks are removed.

'd' or any character / string is ok]]
usage.forwards = [[
f 10  :moves 10 blocks forward unless
obstructed. No blocks broken

f 10 d :moves 10 blocks forward unless
bedrock. Blocks are removed.

'd' or any character / string is ok]]
usage.up = [[
u 10  :moves 10 blocks up unless
obstructed. No blocks broken

u 10 d :moves 10 blocks up unless
bedrock. Blocks are removed.

'd' or any character / string is ok]]
args = {...}

function checkArgs(direction)
	local numBlocksRequested = 1
	local doDig = false
	if args[1] ~= nil then
		if args[1]:lower() == "h" then
			term.clear()
			term.setCursorPos(1,1)
			print(usage[direction])
			print("Fuel Level: "..turtle.getFuelLevel())
			error()
		else
			numBlocksRequested = tonumber(args[1])
			if numBlocksRequested == nil then
				print("Use a number as argument, not "..args[1])
				error()
			end
		end
		if args[2] ~= nil then -- any character here will work
			doDig = true
		end
	end
	return numBlocksRequested, doDig
end

function doMoves(numBlocksRequested, doDig, direction)
	local errorMsg = nil
	local numBlocksMoved = 0
	local Move, Dig, Detect
	
	-- re-assign turtle functions to new variables
	if direction == "forwards" or direction == "backwards" then
		Move = turtle.forward
		Dig = turtle.dig
		Detect = turtle.detect
	elseif direction == "up" then
		Move = turtle.up
		Dig = turtle.digUp
		Detect = turtle.detectUp
	else
		Move = turtle.down
		Dig = turtle.digDown
		Detect = turtle.detectDown
	end
	
	if direction == "backwards" then
		turtle.turnRight()
		turtle.turnRight()
	end
	
	for i = 1, numBlocksRequested, 1 do
		local moveOK, moveError = Move() -- try to move forward/up/down
		if doDig then
			if moveOK then
				numBlocksMoved = numBlocksMoved + 1
			else
				-- while moveOK == false do -- same effect if you prefer.
				while not moveOK do -- did not move if obstruction
					local digOK, digError = Dig()
					if digOK then
						sleep(0.5) -- allow sand / gravel to drop if digging forward / up
					else -- unable to dig, or nothing to dig
						if digError == "Unbreakable block detected" then
							errorMsg = digError
							break
						end
					end
					moveOK, moveError = Move() -- try to move forward/up/down again
					if moveOK then
						numBlocksMoved = numBlocksMoved + 1
					end
				end
			end
		else
			if moveOK then
				numBlocksMoved = numBlocksMoved + 1
			else
				errorMsg = moveError
			end
		end
	end
	
	if direction == "backwards" then
		turtle.turnRight()
		turtle.turnRight()
	end
	
	return numBlocksMoved, errorMsg
end

function printLog(direction, numBlocksRequested, numBlocksMoved, errorMsg)
	print("Moved "..direction.." "..numBlocksMoved.. " / ".. numBlocksRequested)
	if errorMsg ~= nil then
		print (errorMsg)
	end
end

function main()
	local directions = {"backwards", "down", "forwards", "up"}
	--***********************************************************************************************
	--Change this to 1-4 to suit application (forwards, up, down, backwards) f.lua, u.lua, d.lua, b.lua
	local directionIndex = 1 -- this is for b.lua
	--***********************************************************************************************
	local direction = directions[directionIndex] -- e.g backwards
	local numBlocksRequested, doDig = checkArgs(direction)
	if turtle.getFuelLevel() == 0 then
		print("No fuel")
	else
		print("Fuel level: "..turtle.getFuelLevel())
		local numBlocksMoved, errorMsg = doMoves(numBlocksRequested, doDig, direction)
		printLog(direction, numBlocksRequested, numBlocksMoved, errorMsg)
	end
end

main()