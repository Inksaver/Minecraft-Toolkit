-- https://www.youtube.com/watch?v=L-NXGsUv3Jo
local function getCobble(digDirection)
	if digDirection == "up" then -- dig 64 cobble then exit
		local count = 0
		while count < 64 do
			if turtle.detectUp() then
				turtle.digUp()
				count = count + 1
			end
		end
	else
		for i = 1, 4 do			-- dig 4 cobble then exit
			turtle.dig()
			turtle.turnRight()
		end
	end
end

local function getInventoryCount()
	local count = 0
	for i = 1, 16 do
		count = count + turtle.getItemCount(i)
	end
	return count
end

local function emptyTurtle(chestDirection)
	local function empty(Drop)
		for i = 1, 16 do
			turtle.select(i)
			if turtle.getItemCount(i) > 0 then
				if not Drop() then
					turtle.select(1)
					return false
				end
			end
		end
		turtle.select(1)
		return true
	end
	
	local Drop = turtle.drop
	if chestDirection == "down" then
		Drop = turtle.dropDown
		return empty(Drop)
	else -- up to 4 chests around turtle
		local allFull = true
		local success, data = turtle.inspect()
		for j = 1, 4 do
			if data.name == "minecraft:chest" then
				if empty(Drop) then
					allFull = false
				end
			end
			turtle.turnRight()
			success, data = turtle.inspect()
		end
		return allFull
	end
end

local function main()
	--[[ everything runs from here ]]
	local chestDirection = "forward"			-- assume chest(s) in front
	local digDirection = "up"					-- assume stone formed above
	local success, data = turtle.inspectDown()	-- is there a chest below?
	if data.name == "minecraft:chest" then		-- yes
		chestDirection = "down"					-- change chestDirection
		digDirection = "forward"				-- change dig direction
	end
	while true do 								-- run forever
		if emptyTurtle(chestDirection) then		-- successfully emptied turtle
			for i = 1, 16 do					-- get 64 more cobble
				getCobble(digDirection) 		-- 4 cobble per rotation = 64
			end
		else									-- chest full, now fill turtle
			if getInventoryCount() < 1024 then	-- still some space in the turtle
				getCobble(digDirection) 		-- 4 cobble only
			else
				print("Inventory full. Waiting for Player")
				sleep(10)						-- allows time for player to remove cobble
			end
		end
	end
end

main()


