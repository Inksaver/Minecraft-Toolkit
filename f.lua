version = 20240828.1400
-- https://pastebin.com/KXCakmNn
-- pastebin get KXCakmNn f.lua
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

Dig blocks above/below use + -

f 10 +- forward 10, dig above and below]]
usage.up = [[
u 10  :moves 10 blocks up unless
obstructed. No blocks broken

u 10 d :moves 10 blocks up unless
bedrock. Blocks are removed.

'd' or any character / string is ok]]
args = {...}

local above = false
local below = false
	
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
		if args[2] ~= nil then -- any character(s) here will work
			doDig = true
			if args[2]:lower():find("+") ~= nil then
				above = true
			end
			if args[2]:lower():find("-") ~= nil then
				below = true
			end
		end
	end
	return numBlocksRequested, doDig
end

function turnRound()
	turtle.turnRight()
	turtle.turnRight()
end

function doMoves(numBlocksRequested, doDig, direction)
	local errorMsg = nil
	local numBlocksMoved = 0
	local Move, Dig, Detect
	local turned = false
	
	-- re-assign turtle functions to new variables
	if direction == "forwards" then
		Move = turtle.forward
		Dig = turtle.dig
		Detect = turtle.detect
	elseif direction == "backwards" then
		Move = turtle.back
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
	
	for i = 1, numBlocksRequested, 1 do
		if above then turtle.digUp() end	-- user added + to arg
		if below then turtle.digDown() end	-- user added - to arg
		local moveOK, moveError = Move() 	-- try to move forward/up/down
		if doDig then						-- true if ANY args passed
			if moveOK then
				numBlocksMoved = numBlocksMoved + 1
			else 							-- did not move due to obstruction
				if direction == "backwards" and not turned then
					turnRound()
					turned = true
					Move = turtle.forward
				end
				while not moveOK do 		-- did not move if obstruction
					local digOK, digError = Dig()
					if digOK then
						sleep(0.5) 			-- allow sand / gravel to drop if digging forward / up
					else 					-- unable to dig, or nothing to dig
						if digError == "Unbreakable block detected" then
							return numBlocksMoved, digError
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
			else -- move did not succeed
				errorMsg = moveError
				break
			end
		end
	end
	if above then turtle.digUp() end
	if below then turtle.digDown() end
	if turned then -- was "backwards" but obstuction rotated 180 so need to turn round again
		turnRound()
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
	local directionIndex = 3 -- this is for f.lua
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
