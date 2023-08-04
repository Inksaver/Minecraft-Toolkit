version = 20230804.1000
--[[
	**********Toolkit v2**********
	https://pastebin.com/UFvjc1bw
	Last edited: see version YYYYMMDD.HHMM
	if NOT online:
		Make sure you create a folder 'lib' and place menu.lua and clsTurtle.lua into it
	else
		lib folder will be created and files obtained automatically!
	end
]]

args = {...} -- eg "farm", "tree"

local menu, T
--[[
Computercraft started with mc version 1.7.10 and went to 1.8.9
ccTweaked started around mc 1.12.2 and currently at 1.18
mc 1.18 has new blocks and bedrock at -64, so needs to be taken into account.
_HOST = The ComputerCraft and Minecraft version of the current computer environment.
For example, ComputerCraft 1.93.0 (Minecraft 1.15.2).
]]
local bedrock = 0
local ceiling = 255
local deletesWater = false
local brick = "minecraft:nether_brick" -- pre 1.16+ name
local mcMajorVersion = tonumber(_HOST:sub(_HOST:find("Minecraft") + 10, _HOST:find("\)") - 1)) -- eg 1.18 or 1.20 -> 1.18, 1.20
if tonumber(mcMajorVersion) == nil then -- 1.18.3 NAN
	mcMajorVersion = tonumber(_HOST:sub(_HOST:find("Minecraft") + 10, _HOST:find("\)") - 3)) -- eg 1.19.4 -> 1.19
end

if mcMajorVersion < 1.7  and mcMajorVersion >= 1.18 then -- 1.12 to 1.??
	bedrock = -64
	ceiling = 319
end
if mcMajorVersion < 1.7  and mcMajorVersion >= 1.16 then -- 1.12 to 1.??
	brick = "minecraft:nether_bricks"
end
if mcMajorVersion < 1.7  and mcMajorVersion <= 1.12 then --- turtle in source deletes it. 1.7.10 to 1.12
	deletesWater = true
end

local utils = {}

function utils.calculateDimensions(R)
	if R.data == "" then -- not being called from other functions
		if R.width == 0 then -- user chose auto settings
			R.length = utils.calculateDistance(R.length) -- still facing forward
			print("Calculated Length = "..R.length)
			T:turnRight(1) -- ready to check width
			R.width = utils.calculateDistance(R.width) -- now facing right
			print("Calculated width = "..R.width)
			T:go("R2F"..R.width - 1 .."L1".. "F"..R.length - 1 .."R2") -- back at start. width/length confirmed
		end
	end
	if R.height == 0 then -- use auto settings based on water detection
		R.height = 64
	end
	return R
end

function utils.calculateDistance(estDistance)
	--[[
	measure length
	movement stops when either solid block in front or solid below
	called from utils.calculateDimensions
	]]
	local moves = 1
	local nonSolidBelow = utils.clearVegetation("down")
	if estDistance == 0 then
		while nonSolidBelow and turtle.forward() do -- while able to move and air/water below
			moves = moves + 1
			nonSolidBelow = utils.clearVegetation("down")
		end
	else
		while moves < estDistance * 2 do -- loop can only run for max of double estimated distance
			if turtle.forward() then -- able to move forward
				moves = moves + 1
			else
				break
			end
			if not utils.clearVegetation("down") then -- solid below
				turtle.back()
				moves = moves - 1
				break
			end
		end
	end
	return moves
end

function utils.checkFuelNeeded(quantity)
	local fuelNeeded = quantity - turtle.getFuelLevel() -- eg 600
	if fuelNeeded > 0 then
		if T:checkInventoryForItem({"minecraft:lava_bucket"}, {1}, false) == nil then	
			if T:checkInventoryForItem({"coal"}, {math.ceil(fuelNeeded / 60)}, false) == nil then
				T:checkInventoryForItem({"planks"}, {math.ceil(fuelNeeded / 15)})
			end
		end
		T:refuel(quantity, true)
	end
end

function utils.clearVegetation(direction)
	local isAirWaterLava = true	-- default true value air/water/lava presumed
	-- blockType, blockModifier, data
	local blockType, blockModifier = T:getBlockType(direction)
	if blockType ~= "" then --not air
		if T:isVegetation(blockType) then
			T:dig(direction)
		elseif blockType:find("water") == nil
			   and blockType:find("lava") == nil
			   and blockType:find("bubble") == nil
			   and blockType:find("ice") == nil then
			-- NOT water, ice or lava 
			isAirWaterLava = false -- solid block
		end
	end
	
	return isAirWaterLava --clears any grass or sea plants, returns true if air or water, bubble column or ice
end

function utils.createPath(R) -- 51
	--[[places a path in air/lava/water. R can also be of type int]]
	local length = 0
	if type(R) == "table" then
		length = R.length
	else
		length = R
	end
	local numBlocks = 0
	local continue = true
	for i = 1, 2 do
		T:fillVoid("down", {}, false)
		T:forward(1)
		numBlocks = numBlocks + 1
	end
	local place = utils.clearVegetation("down")
	while place do -- while air, water, normal ice, bubble column or lava below
		if T:fillVoid("down", {}, false) then -- false if out of blocks
			T:forward(1)
			numBlocks = numBlocks + 1
			if numBlocks % 8 == 0 then
				if T:getItemSlot("minecraft:torch", -1) > 0 then
					T:turnRight(2)
					T:place("minecraft:torch", -1, "forward", false)
					T:turnRight(2)
				end
			end
		else
			break
		end
		if length > 0 and numBlocks >= length then -- not infinite path (length = 0)
			break
		end
		place = utils.clearVegetation("down")
	end
	return {numBlocks} -- returned as a table in case called as task 51 back to main()
end

function utils.createWaterSource(level)
	if level == nil then
		level = 0
	end
	if level > 0 then
		T:up(level)
	elseif level < 0 then
		T:down(math.abs(level))
	end
	-- assume on flat surface, but allow for blocks above
	T:go("x0C2F1 x0C2F1 x0C2F1 x0C2R1 F1 x0C2F1 x0C2F1 x0C2R1 F1 x0C2F1 x0C2F1 x0C2R1 F1 x0C2F1 x0C2", false, 0, false)
	T:go("R1F1D1", false, 0, false) --move to corner and drop down
	T:go("C2F1R1 C2F1R1 C2F1R1 C2F1R1", false, 0, false)
	T:go("U1")
	for i = 1, 2 do
		T:place("minecraft:water_bucket", -1, "down", false)
		T:go("F1R1F1R1", false, 0, false)
	end
	-- refill water buckets
	for i = 1, 2 do
		sleep(0.5)
		T:place("minecraft:bucket", -1, "down", false)
	end
	T:go("R2F1R1F1R1")
	-- end above lower left of pond (starting point)
	return {}
end

function utils.drainWaterLava(R) -- 84
	local lib = {}
		
	function lib.startCorner()
		-- assume starting mid 3 high column
		T:go("D1C1R1C1 U1C1 L1C1 U1C1 R1C1 L1D1 C2C0", false, 0, true)
		-- finished on same mid 3 high column with wall in front and right completed
	end
	
	function lib.midWall()
		-- assume starting mid 3 high column
		T:go("D1R1C1 U1C1 U1C1 L1D1 C2C0", false, 0, true)
		-- finished on same mid 3 high column with wall on right completed
	end
	
	function lib.endCorner()
		-- assume starting mid 3 high column
		T:go("D1R1C1 R1C1 U1C1 L1C1 U1C1 R1C1 L2D1 C2C0", false, 0, true)
		-- finished on same mid 3 high column with wall behind and right completed
	end
	
	function lib.backTurn(offset)
		-- assume starting mid 3 high column with completed wall behind
		T:go("L1F"..offset.."L2C1 R1D1C1 U1C1 U1C1 D1")
		-- end next row along the width, facing the back, mid point
		-- wall ahead completed
	end
	
	function lib.frontTurn()
		-- assume starting mid 3 high column facing back
		-- next move is to turn toward previous wall and remove

		T:go("L2D1C1 U1C1 U1C1 D1R1 C2C0 F1R2C1 L1")
		-- end facing back ready to remove wall
	end
	
	function lib.placeRetainingWall(distance)
		-- assume starting above 3 block high area facing front (player)
		--T:down(1)
		for i = 1, distance do
			if i == 1 then -- start wall
				lib.startCorner()
			else
				if i < distance then -- mid wall
					lib.midWall()
				else -- end of the wall
					lib.endCorner()
				end
			end
			if i < distance then
				if not turtle.back() then
					T:go("R2F1R2")
				end
				T:go("C1", false, 0, true)
			end
		end
		return 1
	end
		
	function lib.placeDam(distance)
		--T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		local waterPresent = false
		for i = 1, distance do
			if T:isWater("down") then
				waterPresent = true
			end
			T:go("C0C2")
			if i < distance then
				if not turtle.back() then
					T:go("R2F1R2")
				end
				T:go("C1", false, 0, true)
			end
		end
		return waterPresent
	end
	
	function lib.removeDam(distance)
		-- facing towards back, dig wall up down and ahead
		for i = 1, distance do
			T:go("x0x2")
			if i < distance then
				T:forward(1)
			end
		end
		T:turnRight(2)
		-- end up back to retaining wall, mid point
	end
	
	if R.data == "" then
		if turtle.detectDown() then -- on solid surface
			turtle.forward()
		end
	end
	if deletesWater then --turtle replaces source so use clearSolid()
		R.silent = true
		R.down = true
		R.up = false
		clearSolid(R)
	else -- mc 1.12.15+ turtle does NOT replace source blocks
		-- place first stone along the length of water and measure length
		R = utils.calculateDimensions(R)
		local depth = 0
		for h = 1, R.height do
			local waterPresent = false -- resets at each level
			local row = 0
			T:go("R2D2", false, 0, true)	-- at start, level 2, facing towards the front, move backards
			--lib.startCorner()
			row = row + lib.placeRetainingWall(R.length)
			lib.backTurn(1)
			if lib.placeDam(R.length) then
				waterPresent = true
			end
			row = row + 1
			-- left side wall has been built, 2 rows of walls laid. row = 2
			while row < R.width - 1 do -- eg width=2, row=2, this will not run. width=5, row=2
				lib.frontTurn()
				lib.removeDam(R.length)
				lib.backTurn(2)
				if lib.placeDam(R.length) then
					waterPresent = true
				end
				row = row + 1
			end
			-- lay right wall
			lib.frontTurn()
			lib.removeDam(R.length)
			lib.backTurn(2)
			row = row + lib.placeRetainingWall(R.length)
			lib.frontTurn()
			lib.removeDam(R.length) -- faces to front on finish
			T:go("L1F1R1")
			lib.removeDam(R.length) -- faces to front on finish
			depth = depth + 3
			T:go("L1F"..R.width - 1 .."R1D1")
			if depth == R.height or not waterPresent then -- still replacing water
				T:up(depth - 1) -- when h == R.height will go up
				break -- in case water dries up before loop has completed
			end
		end
	end
	return {}
end

function utils.dropSand()
	while not turtle.detectDown() do -- over water. will be infinite loop if out of sand
		if not T:place("sand", -1, "down", false) then
			print("Out of sand. Add more to continue...")
			sleep(2)
		end
	end
	return true --will only get to this point if turtle.detectDown() = true
end

function utils.pause(R)
	--[[
	allows 2 turtles to co-operate
	When they face each other and move together
	R.side = "R" or "L"
	]]
	local rsIn = rs.getAnalogueInput("front")
	local rsOut = 1
	local present = false
	local confirmed = false
	local timer = 0
	local endTimer = 0
	local finished = false
	T:go(R.side.."1")
	rs.setAnalogueOutput("front", 0) -- switch off output
	local blockType = T:getBlockType("forward")
	while blockType:find("turtle") == nil do
		menu.colourWrite("Waiting for other turtle "..endTimer, colors.orange, nil, nil, false, true)
		blockType = T:getBlockType("forward")
		sleep(0.1)
		timer = timer + 0.1
		if timer >= 1 then
			timer = 0
			endTimer = endTimer + 1
		end
	end
	timer = 0
	endTimer = 0
	
	while not finished do
		if endTimer == 0 then
			if present then
				if confirmed then
					menu.colourWrite("Turtle confirmed: input = "..rsIn.." output = "..rsOut, colors.orange, nil, nil, false, true)
				else
					menu.colourWrite("Other turtle ok: input = "..rsIn.." output = "..rsOut, colors.orange, nil, nil, false, true)
				end
			else
				menu.colourWrite("Waiting: input = "..rsIn.." output = "..rsOut, colors.orange, nil, nil, false, true)
			end
		end
		sleep(0.1)
		timer = timer + 1
		if endTimer > 0 then
			endTimer = endTimer + 1
		end
		if endTimer >= 10 then -- allows time for other computer to get ready
			finished = true
		end
		rs.setAnalogueOutput("front", 1) -- output 1 as a signal initially
		if present then
			rs.setAnalogueOutput("front", rsOut) -- output 1 as a signal initially
		end
		rsIn = rs.getAnalogueInput("front")
		if rsIn == 1 then
			present = true
			if not confirmed then
				rsOut = 7
			end
		elseif rsIn == 7 then
			present = true
			confirmed = true
			rsOut = 15
		elseif rsIn == 15 or confirmed then
			menu.colourWrite("endTimer active = "..endTimer, colors.orange, nil, nil, false, true)
			endTimer = endTimer + 1 -- start endTimer
		end
	end
	T:go(R.side.."3")
	
	return rsIn -- 15
end

function utils.startWaterFunction(inWater, onWater, maxDescent, goIn)
	--[[
		Use with utils.getWaterStatus
		could be inWater and not onWater if on single layer of water with floor below
	]]
	maxDescent = maxDescent or 1 -- prevents continuous down due to lack of water
	if goIn == nil then	-- turtle should submerge
		goIn = true
	end
	local descent = 0 -- counter for going down
	if inWater then -- job done
		return inWater, onWater
	end
	if onWater and goIn then --inWater already returned so must be false
		if turtle.down() then
			if T:getBlockType("forward"):find("water") ~= nil or T:getBlockType("forward"):find("bubble") ~= nil then
				inWater = true
				return inWater, onWater
			end
		end
	end
	if not onWater then
		T:forward(1)
	end
	-- should now be above water, but may be further down so onWater still false
	while T:getBlockType("down"):find("water") == nil and T:getBlockType("down"):find("bubble") == nil do-- go down until water below
		if turtle.down() then
			descent = descent + 1
			if descent >= maxDescent then -- limit descent in case no water present
				onWater = false
				return inWater, onWater -- false,false
			end
		else
			onWater = false
			return inWater, onWater -- false,false
		end
	end
	-- now above water
	if goIn then
		turtle.down() -- now inside water block
		inWater = true
	end
	return inWater, onWater
end

function utils.fillBucket(direction)
	if T:place("minecraft:bucket", -1, direction, true) then
		sleep(0.3)
		return true
	else
		return false
	end
end

function utils.getEmptyBucketCount()
	local lastSlot, leastModifier, total, slotData = T:getItemSlot("minecraft:bucket", -1)
	return total
end

function utils.getRoofStats(R)
	local isWidthOdd = R.width % 2 == 1 			-- is the width odd or even?
	local isLengthOdd = R.length % 2 == 1 			-- is the length odd or even?
	if isWidthOdd then
		R.height = math.floor(R.width / 2)			-- eg 7 x 5 roof, layers = 5 / 2 = 2
	else
		R.height = R.width / 2						-- eg 17 x 8 roof, layers = 8 / 2 = 4
	end
	
	local width = 2									-- assume even width with  2 block roof ridge
	local length = R.length - R.height - 1			-- assume even width with  2 block roof ridge
	if isWidthOdd then
		width = 3									-- adjust to allow for single width roof ridge
	end
	if isLengthOdd then
		length = R.length - R.height				-- adjust as 1 layer less
	end
	
	return R, isWidthOdd, isLengthOdd, width, length
end

function utils.getWater()
	if deletesWater then
		T:place("minecraft:bucket", -1, "down") -- take water from source
		sleep(0.2)
		T:place("minecraft:bucket", -1, "down") -- take water from source
	else
		if not turtle.detectDown() then
			T:go("C2", false, 0, false)
		end
		T:place("minecraft:bucket", -1, "forward") -- take water from source
		sleep(0.2)
		T:place("minecraft:bucket", -1, "forward") -- take water from source
	end
end

function utils.getWaterBucketCount()
	-- lastSlot, leastModifier, total, slotData  = T:getItemSlot(item, useDamage)
	local lastSlot, leastModifier, total, slotData = T:getItemSlot("minecraft:water_bucket", -1)
	return total
end

function utils.getWaterStatus()
	--[[ Usage:
	local inWater, onWater = utils.getWaterStatus() -- returns turtle position near water
	utils.startWaterFunction(onWater, inWater, 2, true) -- move INTO water max 2 blocks down
	utils.startWaterFunction(onWater, inWater, 5, false) -- move ABOVE water max 5 blocks down
	]]
	local onWater = false
	local inWater = false
	for i = 1, 4 do
		if T:getBlockType("forward"):find("water") ~= nil  or T:getBlockType("forward"):find("bubble") ~= nil then
			inWater = true
		end
		T:turnRight(1)
	end
	if T:getBlockType("down"):find("water") ~= nil or T:getBlockType("down"):find("bubble") ~= nil then
		onWater = true
	end
	return inWater, onWater
end

function utils.goBack(blocks)
	blocks = blocks or 1
	local success = true
	for i = 1, blocks do
		if not turtle.back() then
			success = false
			T:go("R2F1R2")
		end
	end
	
	return success
end

function utils.getPrettyPrint(promptColour, menuPromptColour)
	promptColour = promptColour or colors.yellow
	menuPromptColour = menuPromptColour or colors.white
	
	local pp = {}
	pp.prompt = promptColour
	pp.itemColours = {}
	pp.menuPrompt = menuPromptColour
	pp.allowModifier = true -- can the menu return 'q' or 'h' / 'i'
	
	return pp
end

function utils.initialiseCanal(R)
	-- return moves
	local moves = 1
	local oTurn = "R"
	if R.side == "R" then
		oTurn = "L"
	end
	local newCanal, isWater, isSource = false, false, false
	if (R.subChoice == 1 or R.subChoice == 4) and R.data == 1 then 	-- left / right side on towpath stays in place for 4 part canal
		if deletesWater then
			T:go(oTurn.."1F1")						-- turn to face canal centre, go forward over water
			isWater, isSource = T:isWater("down")
			if isSource then 						-- canal already exists
				T:go(oTurn.."1")					-- stay above water, face existing canal
			else									-- NOT above source
				T:go("D1"..oTurn.."1")				-- go to canal floor, face existing
				newCanal = true						-- flag create 6 water source blocks
			end
		else										-- NOT deletesWater
			T:go(oTurn.."1F1D1"..oTurn.."1") 		-- move into canal, face back along any existing canal
			isWater, isSource = T:isWater("forward")
			if isSource then
				T:go(R.side.."2") 					-- face forward for new canal
			else
				newCanal = true
			end
		end
	elseif R.subChoice == 2 or R.subChoice == 3 then-- left / right side above canal finishing pos if deletesWater
		if deletesWater then
			isWater, isSource = T:isWater("down")
			if isSource then 
				T:go(R.side.."2")					-- face towards existing canal
			else
				T:go("D1"..R.side.."2")				-- go down and face existing canal		 				-- no water ahead
				newCanal = true						-- already in newCanal starting position
			end
		else										-- NOT deletesWater
			T:go("D1"..R.side.."2")					-- facing existing on canal floor
			isWater, isSource = T:isWater("forward")
			if isSource then						-- water ahead
				T:go(R.side.."2")					-- face forward for new canal
			else 									
				newCanal = true
			end
		end
	elseif R.subChoice == 5 or R.subChoice == 6 then -- left / right  side in canal base. Assume NOT deletesWater
		T:go(R.side.."2") 							-- check if water behind	
		isWater, isSource = T:isWater("forward")
		if isSource then
			T:go(oTurn.."2") 	
		else
			newCanal = true
		end
	end
	if newCanal then 								-- no water ahead, facing start wall of new canal *|<| | |
		utils.newCanal(R) 							-- start new canal, finish facing new canal 6 block water sources
		moves = 2
	end
	
	return moves 									-- facing forward ready for new canal *|>| | |
end

function utils.move(R, blocks, reverse)
	if reverse == nil then
		reverse = false
	end
	if reverse then
		if R.subChoice == 2 then -- reverse direction
			T:up(blocks)
		else
			T:down(blocks)
		end
		return blocks * -1
	else
		if R.subChoice == 1 then
			T:up(blocks)
		else
			T:down(blocks)
		end
		return blocks
	end
end

function utils.newCanal(R)
	--  no source in front as this function called
	local lib = {}
	
	function lib.newCanalSide(oTurn)
		T:go("C1 U1x1 U1x1 D2"..oTurn.."1", false, 0, false)
	end
	
	function lib.newCanalBase(R)
		local oTurn = "R"								-- assume R.side = "L"
		if R.side == "R" then
			oTurn = "L"
		end
		if not turtle.detectDown() then					-- air / water below: fill floor
			T:go(oTurn.."1D1")							-- *|>| | | to *|V| | | turn towards canal centre, go down ready to repair neighbouring canal base 
			if T:getBlockType("forward"):find("turtle") ~= nil then -- turtle in similar position
				if R.side == "L" then					-- only left side repairs, so wait 1 second
					sleep(1)
					T:go("C1")							-- repair neighbouring canal base
				end
			else
				T:go("C1")								-- repair neighbouring canal base
			end
			T:go(R.side.."1")							-- *|V| | | to *|>| | | turn to face start 
			T:up(1)										-- *|>| | | return to canal floor 
		end
		T:go("C2", false, 0, false)
	end
	
														-- *|<| | |  facing end wall ready for new canal canal base level
	local oTurn = "R"									-- assume R.side = "L"
	if R.side == "R" then
		oTurn = "L"
	end
	lib.newCanalSide(oTurn)								-- *|<| | | wall fixed. to -- *|^| | | 
	lib.newCanalSide(oTurn)								-- *|^| | | wall fixed. to -- *|>| | | 
	lib.newCanalBase(R)									-- *|>| | | base fixed
	T:go("F1"..R.side.."1") 							-- *|>| | | to *| |>| | to *| |^| |
	lib.newCanalSide(oTurn)								-- *| |^| | to *| |>| |
	lib.newCanalBase(R)									-- *| |>| | base fixed
	T:go("F1"..R.side.."1") 							-- *| |>| | to *| | |>| to *| | |^|
	lib.newCanalSide(oTurn)								-- *| | |^| to *| | |>|
	lib.newCanalBase(R)									-- *| | |>| base fixed
	T:go(R.side.."2") 									-- *| | |>| to *| | |<|facing existing / back wall 
	T:forward(1)										-- *| |<| |
	T:place("minecraft:water_bucket", -1, "forward") 	-- *|W|<| | placed against start wall  
	T:go("L2")											-- *|W|>| |
	T:place("minecraft:water_bucket", -1, "forward") 	-- *|W|>|W| placed direction of travel 
	T:go("R2") 											-- *|W|<|W| rotate
	if deletesWater then
		T:up(1)
	else
		sleep(0.2)
	end
	utils.getWater()									-- *|W|<|W| 
	T:go(oTurn.."2F1")									-- *|W|<|W|  to *|W|W|>|  ready to go	
end

function utils.setStorageOptions()
	local storage = ""
	local storageBackup = ""
	if T:getItemSlot("barrel") > 0 then
		storage = "barrel"
		storageBackup = "barrel"
	end
	if T:getItemSlot("chest") > 0 then
		if storage == "" then
			storage = "chest"
		end
		storageBackup = "chest"
	end
	return storage, storageBackup
end

local pp = utils.getPrettyPrint()

local function buildWall(R)
	-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	local lib = {}
	
	function lib.singleLayer(R)
		for l = 1, R.length do
			if l == R.length and R.data == "house" then
				T:turnRight(1)
			end
			utils.goBack(1)
			T:go("C1", false, 0, false, R.useBlockType)
		end
	end
	
	function lib.doubleLayer(R)
		for l = 1, R.length do
			T:go("C2", false, 0, false, R.useBlockType)
			if l == R.length and R.data == "house" then
				T:turnRight(1)
			end
			utils.goBack(1)
			T:go("C1", false, 0, false, R.useBlockType)
		end
	end
	
	function lib.tripleLayer(R)
		for l = 1, R.length do
			T:go("C2C0", false, 0, false, R.useBlockType)
			if l == R.length and R.data == "house" then
				T:turnRight(1)
			end
			utils.goBack(1)
			T:go("C1", false, 0, false, R.useBlockType)
		end
	end
	
	-- R.width preset to 1
	local remaining = R.height
	
	if R.subChoice == 1 then
		T:forward(1)			-- face forward, move over first block
	end
	if R.height > 1 then
		T:up(1)					-- go up 1 block
	end
	if R.data ~= "house" then
		T:turnRight(2)				-- rotate 180
	end
	if R.height == 1 then		-- single block: place in front
		lib.singleLayer(R)
	elseif R.height == 2 then	-- 2 blocks, go backwards, place below and ahead
		lib.doubleLayer(R)
	else
		while remaining >= 3 do
			lib.tripleLayer(R)
			remaining = remaining - 3
			if remaining == 1 then
				T:go("U2F1R2")
			elseif remaining > 1 then
				T:go("U3F1R2")
			end
		end
		if remaining == 1 then
			lib.singleLayer(R)
		elseif remaining == 2 then
			lib.doubleLayer(R)
		end
	end
	if not R.silent then
		while turtle.down() do end
	end
	
	return {}
end

local function buildStructure(R)
	local lib = {}
	
	function lib.goDown(R)
		--T:go("L1F1 R1F1 L1")	-- now on ground floor
		if R.height > 1 then
			T:down(1)
		end
	end
	local buildHeight = R.height
	local height = R.height
	local width = R.width
	local length = R.length
	
	if R.subChoice == 1 then
		T:forward(1)			-- face forward, move over first block
	end
	if R.height > 3 then
		R.height = 3
	end
	T:turnRight(2)
	R.data = "house"
	R.silent = true	-- prevent return to ground after buildWall(R)
	R.subChoice = 2	-- do not move forward when building walls
	while height > 0 do
		buildWall(R)
		
		lib.goDown(R)
		R.length = width - 1
		buildWall(R)
		lib.goDown(R)
		
		R.length = length - 1
		buildWall(R)
		lib.goDown(R)
		
		R.length = width - 2
		buildWall(R)
		height = height - R.height	-- 1, 2 or 3
		if height > 0 then
			T:go("U2 R1F1 L1F1")
			R.height = height
			if height > 3 then
				R.height = 3
			end
			R.length = length
		end
	end
	
	T:go("U2F2")
	while turtle.down() do end
	T:go("R1F1R1")
	
	return {}
end

local function buildGableRoof(R)
	--[[
	stairs placement:
	   _|   up
	  
	   T L  forward
	   _
	    |   down

	]]
	local lib = {}
	
	function lib.placeRoof(R, outward)
		for i = 1, R.length + 2 do
			if R.useBlockType:find("stairs") ~= nil then
				T:place("stairs", 0, "up")
			else
				T:go("C0", false, 0, false, R.useBlockType)
			end
			if i < R.length + 2 then
				if outward then
					T:go("L1F1R1")
				else
					T:go("R1F1L1")
				end
			end
		end
	end
	
	function lib.placeGable(R, outward)
		local width = R.width
		for h = 1, R.height do
			for w = 1, width do
				T:go("C1")
				if w < width then
					if outward then
						T:go("L1F1R1")
					else
						T:go("R1F1L1")
					end
				end
			end
			if h < R.height then
				if outward then
					T:go("R1F1L1U1")
				else
					T:go("L1F1R1U1")
				end
			end
			width = width - 2
			outward = not outward
		end
		return outward
	end
	
	local outward = true
	-- go to centre of end wall if odd no, or half width if even
	R.height = math.floor(R.width / 2)
	local isOdd = R.width % 2 == 1 
	
	utils.goBack(1)
	T:go("R1F"..R.height - 1 .."U"..R.height - 1)	-- top of roof, under top layer
	for h = 1, R.height + 1 do						-- place tiles on left side of roof
		lib.placeRoof(R, outward)
		if h < R.height + 1 then
			utils.goBack(1)
			T:down(1)
			outward = not outward
		end
	end
	if isOdd then
		T:go("F"..R.height + 2 .."R2U"..R.height)
	else
		T:go("F"..R.height + 1 .."R2U"..R.height)
	end
	for h = 1, R.height + 1 do						-- place tiles on right side of roof
		lib.placeRoof(R, outward)
		if h < R.height + 1 then
			utils.goBack(1)
			T:down(1)
			outward = not outward
		end
	end
	-- gable ends
	if outward then
		T:go("F1R1U1")
	else
		T:go("F1L1U1")
	end
	outward = lib.placeGable(R, outward)
	T:go("F2R2 C1R2F"..R.length - 1 .."D"..R.height - 1)
	if outward then
		T:go("R1F"..R.height - 1 .."R1")
	else
		T:go("L1F"..R.height - 1 .."L1")
	end
	outward = not outward
	outward = lib.placeGable(R, outward)
	if isOdd then
		if outward then
			T:go("L1F1R1U2F1")
		else
			T:go("R1F1L1U2F1")
		end
		for i = 1, R.length do
			T:go("C2F1", false, 0, false)
		end
		for i = 1, R.length + 2 do
			utils.goBack(1)
			T:place("slab", 0, "forward")
		end
	end
	while turtle.down() do end
	
	return {}
end

local function buildPitchedRoof(R)
	--[[
	stairs placement:
	   _|   up
	  
	   T L  forward
	   _
	    |   down

	]]
	local lib = {}
		
	function lib.placeRoofSection(length)
		-- starts facing centre of building
		for i = 1, length do
			if i < length then
				if R.useBlockType:find("stairs") ~= nil then
					T:place("stairs", 0, "up")
				else
					T:go("C0", false, 0, false, R.useBlockType)
				end
				T:go("L1F1R1")
			end
		end
		-- ends facing centre of building
	end
	
	function lib.placeRoof(R, width, length)
		lib.placeRoofSection(length)
		T:go("R1")
		lib.placeRoofSection(width)
		T:go("R1")
		lib.placeRoofSection(length)
		T:go("R1")
		lib.placeRoofSection(width)
	end
	
	function lib.placeSlabs(length)
		-- add slabs at top
		T:go("U2F1L1")
		if length > 1 then
			T:forward(length - 3)
			for i = 1, length - 3 do
				T:place("slab", 0, "forward")
				utils.goBack(1)
			end
			T:place("slab", 0, "forward")
		else
			T:place("slab", 0, "forward")
		end
		T:go("D2R1")
		utils.goBack(1)
	end
	--[[
	Turtle MUST be placed on left corner of shortest dimension
	
	****   or T******
	****      *******
	****      *******
	****
	T***
	shortest dimension is R.width
	if width is odd, ignore top layer as is only 1 block wide
	]]
	local isWidthOdd, isLengthOdd, width, length = false, false, 0, 0
	R, isWidthOdd, isLengthOdd, width, length = utils.getRoofStats(R)
	T:go("F"..R.height - 1 .."R1F"..R.height - 1 .."U"..R.height - 1)		-- top of roof, under top layer
	if isWidthOdd then
		lib.placeSlabs(length)
	end
	for h = 1, R.height + 1 do						-- place tiles on left side of roof
		lib.placeRoof(R, width, length)
		length = length + 2							-- increase dimensions
		width = width + 2
		if h < R.height + 1 then
			utils.goBack(1)
			T:go("D1R1")
			utils.goBack(1)
		end
	end
	while turtle.down() do end
	
	return {}
end

local function clearAndReplantTrees() -- 25
	--[[ clear all trees in a rectangle area defined by walls, fences or non-dirt blocks
	replant with same type of sapling. If original tree 2 blocks wide, replant 4 if possible. ]]
	
	local lib = {}
	
	function lib.getSaplingFromLogType(log)
		--[[ get type of sapling to plant from log type ]]
		if log:find("oak") ~= nil then
			return "minecraft:oak_sapling"
		elseif log:find("spruce") ~= nil then
			return "minecraft:spruce_sapling"
		elseif log:find("birch") ~= nil then
			return "minecraft:birch_sapling"
		elseif log:find("jungle") ~= nil then
			return "minecraft:jungle_sapling"
		elseif log:find("acacia") ~= nil then
			return "minecraft:acacia_sapling"
		elseif log:find("dark_oak") ~= nil then
			return "minecraft:dark_oak_sapling"
		end
		return "sapling"
	end
	
	function lib.plantSapling(sapling, double)
		--[[ plant sapling(s) ]]
		if sapling == "" or sapling == nil then sapling = "sapling" end
		T:up(1)
		lib.suck()
		if double then	-- check if enough saplings
			--slotData.lastSlot, slotData.leastModifier, total, slotData = T:getItemSlot(sapling, -1)
			local a, b, total, _ = T:getItemSlot(sapling, -1)
			if total >= 4 then
				for i = 1, 4 do
					T:place(sapling, -1, "down")
					T:go("F1R1")
				end
				T:forward(1)		-- above pre-planted sapling
			else
				if not T:place(sapling, -1, "down") then
					T:place("sapling", -1, "down")
				end
			end
		else
			if not T:place(sapling, -1, "down") then
				T:place("sapling", -1, "down")
			end
		end
		turtle.select(1)
	end
		
	function lib.suck()
		--[[ Collect saplings, sticks and apples ]]
		turtle.select(1)
		turtle.suck()
		turtle.suckUp()
		turtle.suckDown()
	end
	
	function lib.turn(direction)
		--[[ change direction and return new value for direction ]]
		if direction == "r" then
			T:turnRight(1)
			direction = "l"
		else
			T:turnLeft(1)
			direction = "r"
		end
		return direction	-- will only change direction variable if return value is used
	end
	
	function lib.emptyInventory(blockTypeD)
		--[[ Empty all except 32 of each sapling and 1 chest ]]
		if blockTypeD == nil then
			blockTypeD = T:getBlockType("down")
		end
		if blockTypeD:find("chest") ~= nil or blockTypeD:find("barrel") ~= nil then
			-- empty logs, apples, sticks and all but 1 stack of each sapling type
			T:emptyInventorySelection("down", {"chest", "oak_sapling", "birch_sapling", "spruce_sapling", "acacia_sapling", "jungle_sapling","dark_oak_sapling"},{1, 32, 32, 32, 32, 32, 32})
			return true
		else
			return false
		end
	end
	
	function lib.moveDown(blockTypeD)
		--[[ move down until hit ground. Break leaves and continue ]]
		if blockTypeD == nil then
			blockTypeD = T:getBlockType("down")
		end
		while blockTypeD == "" or blockTypeD:find("leaves") ~= nil do	-- move down, breaking leavse
			T:down(1)
			lib.suck()
			blockTypeD = T:getBlockType("down")
		end
		return blockTypeD
	end
	
	function lib.moveForward()
		--[[ Move forward 1 block only, go down to ground while air or leaves below ]]
		local blockTypeF = T:getBlockType("forward")
		local blockTypeD = T:getBlockType("down")
		if blockTypeF == "" or blockTypeF:find("leaves") ~= nil then	-- air or leaves ahead
			T:forward(1)												-- move forward, breaking leaves
			T:dig("up")													-- remove leaves / low branches above to allow space for player
			lib.suck()
			blockTypeD = lib.moveDown()
			if not lib.emptyInventory(blockTypeD) then					-- check if above a corner chest / barrel
				if lib.isBorder(blockTypeD) then						-- not above chest so check if above border
					return false, blockTypeD							-- above a border block so stop
				end
			end
			blockTypeF = T:getBlockType("forward")
			return true, blockTypeF										-- moved ok, could be air or block in front
		end
		return false, blockTypeF 										-- did not move, obstacle in front NOT leaves or air
	end
	
	function lib.moveUp(blockTypeF)
		--[[ Move up until air in front (dig leaves / harvest tree) ]]
		if blockTypeF == nil then
			blockTypeF = T:getBlockType("forward")
		end
		while blockTypeF:find("dirt") ~= nil or
			  blockTypeF:find("grass_block") ~= nil or
			  T:isVegetation(blockTypeF) do	-- go up while dirt, grass-block or any vegetation in front
			T:up(1)
			blockTypeF = T:getBlockType("forward")
			if blockTypeF:find("log") ~= nil then
				lib.harvestTree(blockTypeF)
				return T:getBlockType("forward")
			elseif blockTypeF:find("leaves") ~= nil then
				T:dig("forward")
				return ""
			end
		end
		return blockTypeF	-- should be "" (air) or any border block
	end
	
	function lib.harvestTree(blockTypeF)
		--[[ Fell tree, returns true if double size ]]
		-- clsTurtle.harvestTree(extend, craftChest, direction)
		local saplingType = lib.getSaplingFromLogType(blockTypeF)
		local double = T:harvestTree(false, false, "forward")	-- assume single tree, will auto-discover
		lib.plantSapling(saplingType, double)
	end
	
	function lib.safeMove()
		--[[ move forward until border reached. loop breaks at that point ]]
		local blockTypeF = ""
		local success = true
		while success do
			success, blockTypeF = lib.moveForward()				-- move forward 1 block, return block type ahead
			if not success then 								-- did not move forwards, block in the way: either log, dirt/grass, border block or vegetation
				if blockTypeF:find("log") then 					-- tree found
					lib.harvestTree(blockTypeF)
					success = true								-- block (log) removed, try again
				else
					success = not lib.isBorder(blockTypeF)		-- Is at border?: if is at border success = false so loop stops
					if success then								-- Not at border. Dirt/grass vegetation in front
						blockTypeF = lib.moveUp(blockTypeF)		-- move up until leaves/log/air
						success = not lib.isBorder(blockTypeF)	-- Is at border?: if is at border success = false so loop stops
						if success then							-- keep moving forward
							if blockTypeF:find("log") then 		-- tree found
								lib.harvestTree(blockTypeF)	
							end
																-- else blockTypeF is air/leaves  border has been checked
						end
					end
				end
			end													-- else success = true, 1 block moved so continue
		end
	end
	
	function lib.isBorder(blockType)
		--[[ Is the block log, dirt, grass_block, vegetation: non-border, or other:border]]
		if blockType == nil then 					-- not passed as parameter
			blockType = T:getBlockType("forward")
		end
		if blockType == "" then 					-- air ahead: not border
			return false, ""
		else										-- could be border or other
			if blockType:find("dirt") ~= nil or blockType:find("grass_block") ~= nil or blockType:find("log") ~= nil then -- either dirt, grass block or log
				return false, blockType				-- dirt, grass, log: not border
			end
			if T:isVegetation(blockType) then 		-- vegetation found: not border
				return false, blockType
			end
		end
		return true, blockType						-- dirt, grass_block, log and vegetation eliminated:must be border
	end
	
	function lib.inPosition()
		--[[ check if in lower left corner ]]
		local inPosition = true 		-- assume correct
		if not turtle.detectDown() then	-- hanging in mid-air
			return false
		end
		T:turnLeft(1)
		if lib.isBorder() then
			-- so far so good
			T:turnLeft(1)
			if not lib.isBorder() then 	-- not in correct place
				inPosition = false
			end
			T:turnRight(2) 				-- return to original position
		else
			inPosition = false
			T:turnRight(1) 				-- return to original position
		end
		return inPosition
	end
	
	function lib.findBorder()
		--[[ assume started after reset. if log above harvest tree else return to ground. Find starting corner]]
		local blockType = T:getBlockType("up")					-- dig any logs above, return to ground
		local log = "sapling"
		if blockType:find("log") ~= nil then					-- originally felling a tree so complete it
			log = lib.getSaplingFromLogType(blockType)
			local double = T:harvestTree(false, false, "up")	-- assume single tree, will auto-discover
			lib.plantSapling(log, double)
		else													-- no log above so go downm
			blockType = lib.moveDown()							-- return to ground (or vegetation)
		end
		lib.safeMove()											-- move forward until border reached
		T:turnRight(1)
		lib.safeMove()											-- move forward until second border reached
		T:turnRight(1)											-- should now be in correct position
		lib.emptyInventory()									-- empty inventory if above a chest
	end
	
	local direction = "r"
	local blockTypeF = ""
	local success = false
	if not lib.inPosition() then 
		lib.findBorder()
	end
	local secondBorderFound = false
	while not secondBorderFound do
		lib.safeMove()														-- moves forward until reaches border forward or below
		lib.turn(direction)													-- turn r or l. direction is not changed
		success, blockTypeF = lib.isBorder()								-- no blockType passed as parameter so will return current block in new forward direction
		if success then
			secondBorderFound = true										-- game over
		elseif blockTypeF:find("log") ~= nil then							-- tree in front
			lib.harvestTree(blockTypeF)
		elseif blockTypeF == "" or blockTypeF:find("leaves") ~= nil then	-- air or leaves in front
			T:forward(1)													-- move forward 1 block
			lib.moveDown()													-- go down if required
		elseif	blockTypeF:find("dirt") ~= nil or
				blockTypeF:find("grass_block") ~= nil or
				T:isVegetation(blockTypeF) then								-- dirt, grass_block or vegetation in front
			blockTypeF = lib.moveUp(blockTypeF)								-- move up until air or border ahead.
			if lib.isBorder(blockTypeF) then								-- border ahead
				secondBorderFound = true
			else															-- air ahead									
				T:forward(1)												-- move forward 1 block
			end
		end
		direction = lib.turn(direction)										-- turn r or l. direction is changed to opposite
	end
	lib.moveDown()															-- return to ground level
	lib.emptyInventory()
	return {}
end

local function clearArea(R, useDirt) -- 71, called from 22
	if useDirt == nil then
		useDirt = true
	end
	local evenWidth = false
	local evenHeight = false
	local loopWidth
	-- go(path, useTorch, torchInterval, leaveExisting)
	if R.width % 2 == 0 then
		evenWidth = true
		loopWidth = R.width / 2
	else
		loopWidth = math.ceil(R.width / 2)
	end
	if R.length % 2 == 0 then
		evenHeight = true
	end
	turtle.select(1)
	-- clear an area between 2 x 4 and 32 x 32
	-- if R.width is even no, then complete the up/down run
	-- if R.width odd no then finish at top of up run and reverse
	-- should be on flat ground, check voids below, harvest trees
	for x = 1, loopWidth do
		-- Clear first column (up)
		for y = 1, R.length do
			if useDirt then
				if not turtle.detectDown() then
					T:place("minecraft:dirt", -1, "down", true)
				else --if not water, dirt, grass , stone then replace with dirt
					blockType, blockModifier = T:getBlockType("down")
					if blockType ~= "" then
						if blockType ~= "minecraft:dirt" and blockType ~= "minecraft:grass_block" then
							turtle.digDown()
							T:place("minecraft:dirt", -1, "down", true)
						end
					end
				end
			end
			if y < R.length then
				T:go("F1+1", false,0,false)
			end
		end
		-- clear second column (down)
		if x < loopWidth or (x == loopWidth and evenWidth) then -- go down if on R.width 2,4,6,8 etc
			T:go("R1F1+1R1", false,0,false)
			for y = 1, R.length do
				if useDirt then
					if not turtle.detectDown() then
						T:place("minecraft:dirt", -1, "down", true)
					else
						blockType, blockModifier = T:getBlockType("down")
						if blockType ~= "" then
							if blockType ~= "minecraft:dirt" and blockType ~= "minecraft:grass_block" then
								turtle.digDown()
								T:place("minecraft:dirt", -1, "down", true)
							end
						end
					end
				end
				if y < R.length then
					T:go("F1+1", false, 0, false)
				end
			end
			if x < loopWidth then 
				T:go("L1F1+1L1", false,0,false)
			else
				T:turnRight(1)
				T:forward(R.width - 1)
				T:turnRight(1)
			end
		else -- equals R.width but is 1,3,5,7 etc
			T:turnLeft(2) --turn round 180
			T:forward(R.length - 1)
			T:turnRight(1)
			T:forward(R.width - 1)
			T:turnRight(1)
		end
	end
	return {}
end

local function clearRectangle(R) -- 72
	--local function clearRectangle(width, length, up, down)
	-- height = 0: one level, 1 = +up, 2 = +down, 3 = +up/down
	local lib = {}
	function lib.UpDown(length)
		for l = 1, length do
			T:go("x0x2F1x0x2")
		end
	end
	
	function lib.Up(length)
		for l = 1, length do
			T:go("x0F1x0")
		end
	end
	
	function lib.Down(length)
		for l = 1, length do
			T:go("x2F1x2")
		end
	end
	
	function lib.Forward(length)
		T:forward(length)
	end
	
	-- could be 1 wide x xx R.length (trench) R.up and return
	-- could be 2+ x 2+
	-- even no of runs return after last run
	-- odd no of runs forward, back, forward, reverse and return
	turtle.select(1)
	if R.width == 1 then 					-- single block trench ahead only
		if R.up and R.down then				-- single block wide trench dig R.up and R.down = 3 blocks deep
			lib.UpDown(R.length - 1)
		elseif R.up then					-- single block wide trench dig R.up = 2 blocks deep
			lib.Up(R.length - 1)
		elseif R.down then				-- single block wide trench dig R.down = 2 blocks deep
			lib.Down(R.length - 1)
		else 							-- single block wide = 1 block deep
			lib.Forward(R.length - 1)
		end
		T:turnRight(2)					-- turn at the top of the run
		T:forward(R.length - 1)			-- return to start
		T:turnRight(2)					-- turn round to original position
	else 								-- R.width 2 or more blocks
		local iterations = 0 			-- R.width = 2, 4, 6, 8 etc
		if R.width % 2 == 1 then  		-- R.width = 3, 5, 7, 9 eg R.width 7
			iterations = (R.width - 1) / 2 -- iterations 1, 2, 3, 4 for widths 3, 5, 7, 9
		else
			iterations = R.width / 2		-- iterations 1, 2, 3, 4 for widths 2, 4, 6, 8
		end
		for i = 1, iterations do 		-- eg 3 blocks wide, iterations = 1
			if R.up and R.down then							-- dig R.up and R.down
				lib.UpDown(R.length - 1)
				T:go("x0x2R1F1x0x2R1x0x2")				-- turn round
				lib.UpDown(R.length - 1)
			elseif R.up then								-- dig R.up
				lib.Up(R.length - 1)
				T:go("x0R1F1x0R1x0")
				lib.Up(R.length - 1)
			elseif R.down then							-- dig R.down
				lib.Down(R.length - 1)
				T:go("x2R1F1x2R1x2")
				lib.Down(R.length - 1)
			else										-- no digging R.up or R.down
				lib.Forward(R.length - 1)
				T:go("R1F1R1")
				lib.Forward(R.length - 1)
			end
			-- if 1 less than end, reposition for next run
			if i < iterations then
				T:go("L1F1L1", false, 0, false)
			end
		end
		if R.width % 2 == 1 then  -- additional run and return to base needed
			T:go("L1F1L1", false, 0, false)
			if R.up and R.down then
				lib.UpDown(R.length - 1)
			elseif R.up then
				lib.Up(R.length - 1)
			elseif R.down then
				lib.Down(R.length - 1)
			else
				lib.Forward(R.length - 1)
			end
			T:turnRight(2)
			T:forward(R.length - 1)
		end
		T:go("R1F"..R.width - 1 .."R1", false, 0, false)
	end
	return {}
end

local function clearPerimeter(R) -- 74
	local lib = {}
	function lib.UpDown(length)
		for l = 1, length do
			T:go("x0x2F1x0x2")
		end
	end
	
	function lib.Up(length)
		for l = 1, length do
			T:go("x0F1x0")
		end
	end
	
	function lib.Down(length)
		for l = 1, length do
			T:go("x2F1x2")
		end
	end
	
	function lib.Forward(length)
		T:forward(length)
	end
	
	if R.up and R.down then
		for i = 1, 2 do
			lib.UpDown(R.length - 1)
			T:turnRight(1)
			lib.UpDown(R.width - 1)
			T:turnRight(1)
		end
	elseif R.up then
		for i = 1, 2 do
			lib.Up(R.length - 1)
			T:turnRight(1)
			lib.Up(R.width - 1)
			T:turnRight(1)
		end
	elseif R.down then
		for i = 1, 2 do
			lib.Down(R.length - 1)
			T:turnRight(1)
			lib.Down(R.width - 1)
			T:turnRight(1)
		end
	else
		for i = 1, 2 do
			lib.Forward(R.length - 1)
			T:turnRight(1)
			lib.Forward(R.width - 1)
			T:turnRight(1)
		end
	end
	return {}
end

local function clearBuilding(R) -- 75, 43
	--[[
	Clear the outer shell of a building, leaving inside untouched. Optional floor/ceiling removal
	clearBuilding(R)
	R.subChoice = 1-'up' or 2-'down'
	R.data.ceiling = true / false
	R.data.floor = true / false
	]]
	local height = 1
	local remaining = R.height -- eg 5
	local start = true
	local finish = false
	local lib = {}
	
	function lib.floorOrCeiling(R)
		T:go("F1R1 F1L1")
		R.length = R.length - 2
		R.width = R.width - 2
		clearRectangle(R)
		R.length = R.length + 2
		R.width = R.width + 2
		T:go("L1F1R1")
		utils.goBack(1)
	end
	
	function lib.singleLayer(R)
		R.up = false
		R.down = false
		if start then
			if R.data.ceiling or R.data.floor then	-- floor / ceiling to go. only one layer, so clearRectangle
				lib.floorOrCeiling(R)
			end
			start = false
		end
		if finish then
			if R.data.ceiling or R.data.floor then	-- floor / ceiling to go. only one layer, so clearRectangle
				lib.floorOrCeiling(R)
			end
			finish = false
		end
		clearPerimeter(R)						-- no floor / ceiling
	end
	
	function lib.doubleLayer(R)
		R.up = false
		R.down = false
		if start then
			if R.data.floor and R.subChoice == 1 then		-- going up and floor needs removing
				lib.floorOrCeiling(R)						-- remove floor/ceiling
			elseif R.data.ceiling and R.subChoice == 2 then -- going down and ceiling needs removing
				lib.floorOrCeiling(R)						-- remove floor/ceiling
			end
			start = false
		end
		if finish then
			if R.data.ceiling and R.subChoice == 1 then		-- going down and ceiling needs removing
				lib.floorOrCeiling(R)						-- remove floor/ceiling
			elseif R.data.floor and R.subChoice == 2 then 	-- going down and floor needs removing
				lib.floorOrCeiling(R)						-- remove floor/ceiling
			end
			finish = false
		end
		if R.subChoice == 1 then
			R.up = true
		else
			R.down = true
		end
		clearPerimeter(R)
	end
	
	function lib.tripleLayer(R)
		-- turtle in centre layer
		R.up = false
		R.down = false
		if start then
			if R.data.floor and R.subChoice == 1 then		-- going up and floor needs removing
				height = height + utils.move(R, 1, true)	-- move down 1 block
				lib.floorOrCeiling(R)						-- remove floor/ceiling
				height = height + utils.move(R, 1)		-- move up 1 block
			elseif R.data.ceiling and R.subChoice == 2 then -- going down and ceiling needs removing
				height = height + utils.move(R, 1, true)	-- move up 1 block
				lib.floorOrCeiling(R)						-- remove floor/ceiling
				height = height + utils.move(R, 1)		-- move down 1 block
			end
			start = false
		end
		if finish then
			if R.data.ceiling and R.subChoice == 1 then		-- going up and ceiling needs removing
				height = height + utils.move(R, 1, true)					-- move down 1 block
				lib.floorOrCeiling(R)						-- remove floor/ceiling
				height = height + utils.move(R, 1)							-- move up 1 block
			elseif R.data.floor and R.subChoice == 2 then 	-- going down and floor needs removing
				height = height + utils.move(R, 1, true)					-- move up 1 block
				lib.floorOrCeiling(R)						-- remove floor/ceiling
				height = height + utils.move(R, 1)							-- move up 1 block
			end
			finish = false
		end
		R.up = true
		R.down = true
		clearPerimeter(R)
	end
	--[[
	R.data = "up" or "down" as direction of travel
	R.up = true to remove ceiling
	R.down = true to remove floor
	]]
	R.silent = true
	if R.height < 3 then 						--1-3 layers only
		if R.height == 1 then 					--one layer only
			lib.singleLayer(R)
		elseif R.height == 2 then 				--2 layers only current + dig up/down
			lib.doubleLayer(R)
		end
	else -- 3 or more levels
		height = height + utils.move(R, 1)							-- move up/down 1 block for first layer
		while remaining >= 3 do -- min 3 levels
			lib.tripleLayer(R)
			remaining = remaining - 3
			if remaining == 0 then				-- all finished
				break
			elseif remaining == 1 then
				height = height + utils.move(R, 2)					-- move up/down 2 blocks
				lib.singleLayer(R)
			elseif remaining == 2 then
				height = height + utils.move(R, 2)					-- move up/down 2 blocks
				lib.doubleLayer(R)
			else
				height = height + utils.move(R, 3)					-- move up/down 3 blocks
				if remaining == 3 then
					finish = true
				else
					--height = height + 3
				end
			end
		end
	end
	
	if height > 1 then
		utils.move(R, height - 1, true) -- reverse direction
	end
	
	return {}
end

local function clearMineshaft(equippedRight, equippedLeft, inInventory) -- 19
	local lib = {}
	
	function lib.checkCobweb(directions, inInventory)
		assert(type(directions) == "table", "directions must be a table eg {'up','down'}")
		for _, direction in ipairs(directions) do
			if inInventory == "minecraft:diamond_sword" then -- using a sword
				local side = "left"
				local item = T:getBlockType(direction)
				if item == "minecraft:cobweb" then
					--clsTurtle.equip(self, side, useItem, useDamage)
					if equippedRight == "minecraft:diamond_pickaxe" then
						side = "right"
					end
					T:equip(side, "minecraft:diamond_sword")
					T:dig(direction)
					T:equip(side, "minecraft:diamond_pickaxe")
				else
					T:dig(direction)
				end
			else
				T:dig(direction)
			end
		end
	end

	-- check position by rotating until facing away from wall
	length = 0
	torch = 0
	turns = 0
	while not turtle.detect() do
		T:turnRight(1)
		turns = turns + 1
		if turns > 4 then
			return {"I am not facing a wall. Unable to continue"}
		end
	end
	T:turnRight(2)
	-- move forward until obstructed, digging up/down. place torches
	while not turtle.detect() do
		lib.checkCobweb({"up","down"}, inInventory) -- dig cobweb or any other block up/down
		length = length + 1
		torch = torch + 1
		if torch == 8 then
			torch = 0
			T:place("minecraft:torch", -1, "down", false) ---(self, blockType, damageNo, direction, leaveExisting, signText)
		end
		lib.checkCobweb({"forward"}, inInventory) -- dig cobweb or any other block in front
		T:forward(1)
	end
	-- turn right, forward, right, return to start with up/down dig
	T:go("R1")
	lib.checkCobweb({"up","down"}, inInventory) -- dig cobweb or any other block up/down
	T:go("F1R1")
	for i = 1, length, 1 do
		lib.checkCobweb({"up", "down", "forward"}, inInventory) -- dig cobweb or any other block up/down/forward
		T:forward(1)
	end
	-- move to other wall and repeat.
	T:go("R1")
	lib.checkCobweb({"up","down"}, inInventory) -- dig cobweb or any other block up/down
	T:go("F1")
	lib.checkCobweb({"up","down"}, inInventory) -- dig cobweb or any other block up/down
	T:go("F1R1")
	lib.checkCobweb({"up","down"}, inInventory) -- dig cobweb or any other block up/down
	for i = 1, length, 1 do
		lib.checkCobweb({"up", "down", "forward"}, inInventory) -- dig cobweb or any other block up/down/forward
		T:forward(1)
	end
	lib.checkCobweb({"up", "down"}, inInventory) -- dig cobweb or any other block up/down/forward
	
	return {}
end

local function clearMonumentLayer(R) -- 85
	R.up = true
	R.down = true
	R.silent = true
	if R.subChoice == 0 then
		R.up = false
		R.down = false
	end
	-- send turtle down until it hits bottom
	-- then clear rectangle of given size
	-- start above water, usually on cobble scaffold above monument
	if T:detect("down") then -- in case not over wall
		T:forward(1)
	end
	local height = 1
	-- go down until solid block detected
	while utils.clearVegetation("down") do
		T:down(1)
		height = height + 1
	end
	T:down(1)
	height = height + 1
	clearRectangle(R)
	T:up(height - 1)
	
	return {}
end

local function clearWaterPlants(R) -- 87
	local lib = {}
	
	function lib.getLength()
		local length = 1
		print("Checking water length")
		while utils.clearVegetation("forward") do
			T:forward(1)
			length = length + 1
		end
		for i = 1, length do
			turtle.back()
		end
		return length
	end
	
	function lib.clearDown(D)
		while utils.clearVegetation("down") do --clears any grass or sea plants, returns true if air or water, bubble column or ice
			T:down(1)
			D.depth = D.depth + 1
		end
		-- if slab at bottom, replace with solid block
		D.blockType = T:getBlockType("down")
		if D.blockType:find("slab") ~= nil then
			T:go("C2")
		end
		if D.depth > D.maxDepth then
			D.maxDepth = D.depth
		end
		
		return D
	end
	
	function lib.clearLength(D)
		local moves = 0
		local blockHeight = 1
		D.floorLength = 0 -- reset
		while moves < D.length - 1 do
			if utils.clearVegetation("forward") then
				T:forward(1)
				moves = moves + 1 
				if turtle.detectUp() then -- could be on monument going under arch, or faulty monument floor
					if not D.monumentArchesClear then
						D = lib.checkArches(D)
					end
				end
				local temp = D.depth
				D = lib.clearDown(D) -- go down if in water/air
				if blockHeight == 4 and D.depth - temp == 3 then -- could be just gone over 3 block high column in ocean monument
					if not D.monumentTopClear then
						D = lib.checkTop(D)
					end
					blockHeight = 1
				end
				if D.useBlockType == "prismarine" then
					if D.blockType:find("prismarine") == nil then
						-- on monument floor so restrict forward movement to 8 blocks
						D.floorLength = D.floorLength + 1
						if D.floorLength == 8 then
							D.blockType = T:getBlockType("forward")
							while D.blockType:find("prismarine") == nil do
								T:up(1)
								D.blockType = T:getBlockType("forward")
							end
							D.floorLength = 0
						end
					end
				end
				if moves >= D.length - 1 then
					D.width = D.width + 1	-- another length completed so increase width
					return D
				end
			else -- block in front
				blockHeight = 1
				local waterAbove = utils.clearVegetation("up")
				local waterAhead = utils.clearVegetation("forward") -- true if air/water in front
				while not waterAhead do 	-- solid block in front
					if waterAbove then 		-- move up
						T:up(1)
						D.depth = D.depth - 1
						blockHeight = blockHeight + 1
						if D.depth < 1 then
							D.width = D.width + 1	-- another length completed so increase width
							return D
						end
					else 					-- block above so go back
						while not waterAbove do
							utils.goBack()	--  returns true if no object behind, but moves anyway
							waterAbove = utils.clearVegetation("up")
							moves = moves - 1
							if moves == 0 then
								T:up(1)
								D.depth = D.depth - 1
								waterAbove = utils.clearVegetation("up")
								while not waterAbove do
									T:up(1)
									D.depth = D.depth - 1
								end
							end
						end
						-- go up 1 to prevent loop
						T:up(1)
						D.depth = D.depth - 1
					end
					waterAbove = utils.clearVegetation("up")
					waterAhead = utils.clearVegetation("forward")
				end
			end
		end
		D.width = D.width + 1	-- another length completed so increase width
		D.maxDepth = D.maxDepth + 1 -- +1 to allow for starting pos in top layer
		
		return D 
	end
	
	function lib.checkArches(D)
		-- gone under a block so could be monument arch (6)
		if T:getBlockType("up"):find("prismarine") ~= nil then -- confirm on monument, not previously cleared
			local direction = "" 	-- initialise direction
			T:go("B1U2F1R1")
			if T:getBlockType("forward"):find("prismarine") ~= nil then -- correct guess
				direction = "R"
			else	-- wrong direction. turn round and check other side
				T:go("R2")
				if T:getBlockType("forward"):find("prismarine") ~= nil then
					direction = "L"
				end
			end
			local path = "U1F1 U1F3 D1F1 D1R2 U2F5 D2"
			--for i = 1, 6 do
			T:go(path) -- clears arch top 1 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 2 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 3 and returns
			T:go(direction.."1F9"..direction.."1")
			T:go(path) -- clears arch top 4 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 5 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 6 and returns
			
			T:go(direction.."3F34"..direction.."2D2F1")
			D.monumentArchesClear =  true
		end
		return D
	end
	
	function lib.checkTop(D)
		-- gone over 3 block column so could be at the top of ocean monument
		if T:getBlockType("down"):find("prismarine") ~= nil then -- confirm on monument, not previously cleared
			local direction = "" 	-- initialise direction
			T:go("U3R1")			-- up to top of column and try right side
			if T:getBlockType("forward"):find("prismarine") ~= nil then -- correct guess
				direction = "L"
			else	-- wrong direction. turn round and check other side
				T:go("R2")
				if T:getBlockType("forward"):find("prismarine") ~= nil then
					direction = "R"
				end
			end
			if direction ~= "" then -- facing single block on layer 2
				T:go("U1F6"..direction.."1F5".. direction.."1F5"..direction.."1F5"..direction.."1") -- clear 4 single blocks
				T:go("F1U1"..direction.."1F1"..direction.."3") -- on top of monument
				T:go("F3".. direction.."1F3"..direction.."1F3"..direction.."1F3"..direction.."3") -- clear top, face return
				T:go("F2D5"..direction.."3B1")
			end
			D.monumentTopClear = true
		end
		return D
	end
	
	function lib.findBlockTypeEnd(D)
		D.blockType = "" -- reset
		repeat
			if utils.clearVegetation("forward") then
				T:forward(1)
				D = lib.clearDown(D) -- go down if in water/air, D.blockType is updated with floor type
			else -- block in front
				local waterAbove = utils.clearVegetation("up")
				local waterAhead = utils.clearVegetation("forward") -- true if air/water in front
				while not waterAhead do 	-- solid block in front
					if waterAbove then 		-- move up
						T:up(1)
					else 					-- block above so go back
						while not waterAbove do
							utils.goBack()	--  returns true if no object behind, but moves anyway
							waterAbove = utils.clearVegetation("up")
						end
					end
					waterAbove = utils.clearVegetation("up")
					waterAhead = utils.clearVegetation("forward")
				end
			end
		until D.blockType:find(D.useBlockType) == nil
		-- now above a non-prismarine block, facing away from monument
		T:turnRight(2) -- facing monument
		D.blockType = T:getBlockType("forward")
		while D.blockType:find(D.useBlockType) ~= nil do
			T:up(1)
			D.blockType = T:getBlockType("forward")
		end
		T:go("F1L1")
		D.blockType = T:getBlockType("down")
		while D.blockType:find(D.useBlockType) ~= nil do
			T:forward(1)
			D.blockType = T:getBlockType("down")
		end
		turtle.back()
		-- should now be at end of monument base
	end
	
	function lib.turn(D)
		local direction = "R"
		if not D.facingForward then
			direction = "L"
		end
		T:go(direction.. 1)
		if utils.clearVegetation("forward") then
			T:forward(1)
			--D.depth = D.depth + lib.clearDown(depth)
			D = lib.clearDown(D)
		else
			while not utils.clearVegetation("forward") do
				T:up(1)
				D.depth = D.depth - 1
			end
			T:forward(1)
		end
		T:go(direction.. 1)
		D.facingForward = not D.facingForward 
		
		return D
	end

	local D = {}
	D.depth = 0
	D.maxDepth = 0
	D.blockType = ""
	D.useBlockType = R.useBlockType -- "" or "prismarine"
	D.length = 0	-- copy of R.length used in lib.clearLength
	D.width = 0		-- increased every iteration
	D.facingForward = true
	D.monumentTopClear = false
	D.monumentArchesClear = false
	D.inWater = false
	D.onWater = false
	D.inWater, D.onWater = utils.getWaterStatus()
	D.floorLength = 0 -- used on monument floor
	
	if R.data == "clearWaterPlants" then -- NOT monument corner discovery
		D.inWater, D.onWater = utils.startWaterFunction(D.onWater, D.inWater, 2, true) -- move into water
		if R.length == 0 then
			R.length = lib.getLength()
		end
		if R.width == 0 then
			T:turnRight(1)
			R.width = lib.getLength()
			T:turnLeft(1)
		end
	end
	D.length = R.length
	D = lib.clearDown(D) -- go down to floor, set depth, maxDepth, blockType
	if R.data == "clearWaterPlants" then -- NOT monument corner discovery
		if R.width == 1 then
			print("Single row clearing")
			D = lib.clearLength(D) --D.width also increased
		else
			while D.width < R.width do -- D.width starts at 0
				-- now on floor, move along sea/river bed following contour
				D = lib.clearLength(D) --D.width also increased
				-- now turn and repeat
				if D.width < R.width then	
					D = lib.turn(D)
					if D.depth <= 0 then
						break
					end
				end
			end
		end
		-- finished so return to surface
		T:up(1) -- up 1 to check for water below
		while T:getBlockType("down"):find("water") ~= nil do
			T:up(1)
		end
		T:down(2) -- return to surface
		--[[while utils.clearVegetation("forward") do
			T:forward(1)
		end]]
	elseif R.data == "oceanMonumentColumns" then -- monument corner discovery
		-- this function used to find edge of monument base
		if D.blockType:find(D.useBlockType) ~= nil then
			lib.findBlockTypeEnd(D)
			return {""}
		else
			T:up(D.depth)
			return {"Prismarine not found on ocean floor"}
		end
	end
	if R.silent then
		return {D.maxDepth, R.length}
	else
		return {""}
	end
end

local function clearMountainSide(R) -- 78
	local lib = {}
	
	function lib.excavate(blocksFromOrigin, going, length, digDown)
		local firstUp = 0
		for i = 1, length do
			-- record first block dug above
			if turtle.digUp() then
				if firstUp == 0 then
					firstUp = i -- will record first successful dig up
				end
			end
			if digDown then
				turtle.digDown()
			end
			T:forward(1)
			if going then
				blocksFromOrigin = blocksFromOrigin + 1
			else
				blocksFromOrigin = blocksFromOrigin - 1
			end
		end
		
		return blocksFromOrigin, firstUp
	end
	
	function lib.cutSection(blocksFromOrigin, going, length, firstUp)
		local height = 0
		local digDown = false
		blocksFromOrigin, firstUp = lib.excavate(blocksFromOrigin, going, length, digDown)
		-- while at least 1 block dug above do
		while firstUp > 0 do
			if digDown then
				turtle.digDown()
			else
				digDown = true
			end
			T:go("R2U1x1U1x1U1x1x0") -- go up 3 turn round
			going = not going
			height = height + 3
			if firstUp > 1 then
				length = length - firstUp + 1
			end
			-- go forward R.length digging up/down
			blocksFromOrigin, firstUp = lib.excavate(blocksFromOrigin, going, length,  true)
		end
		T:down(height)
		
		return blocksFromOrigin, going
	end
	
	local originalLength = R.length
	local going = true
	local firstUp = 0
	local blocksFromOrigin = 0
	--T:forward(1) -- get into position
	blocksFromOrigin, going = lib.cutSection(blocksFromOrigin, going, R.length, firstUp)
	if R.width > 1 then --move left/right and repeat
		for i = 2, R.width do
			if going then
				T:turnRight(2)			
			end
			if blocksFromOrigin > 0 then
				T:forward(blocksFromOrigin)
			end
			T:turnRight(2)
			blocksFromOrigin = 0
			if R.subChoice == 0 then --Left <- Right
				T:go("L1F1R1")
			else
				T:go("R1F1L1")
			end
			going = true
			blocksFromOrigin, going = lib.cutSection(blocksFromOrigin, going, R.length, firstUp)
		end
	end
	
	return {}
end

local function clearSandWall(R) -- 81
	--dig down while on top of sand/red_sand/soul_sand
	local lib = {}
	
	function lib.checkAbove(height)
		if turtle.detectUp() then -- moved under a ledge
			T:go("B1U1")
			height = height - 1
		end
		return height
	end
	
	function lib.moveDown(height)
		blockType = T:getBlockType("down")
		while blockType:find("sand") ~= nil do
			T:down(1)
			height = height + 1
			blockType = T:getBlockType("down")
		end
		return height
	end
	
	function lib.moveForward(length)
		lib.digForward()
		T:forward(1)
		length = length + 1
		local blockType = T:getBlockType("forward")
		return length, blockType
	end
	
	function lib.digForward()
		while T:dig("forward") do
			while T:suck("forward") do end
			while T:suck("up") do end
		end
	end
	
	local moves  = 0
	local height = 0
	local length = 0
	local search = 0
	local reverse = false
	local blockType = T:getBlockType("down")
	if R.length == 0 then
		R.length = 64
	end
	
	print("Checking for sand below")
	while blockType:find("sand") == nil do --move forward until sand detected or 3 moves
		T:forward(1)
		search = search + 1
		blockType = T:getBlockType("down")
		if search > 3 then
			T:go("B"..search)
			return {"Unable to locate sand"}
		end
	end
	-- must be sand below
	height = lib.moveDown(height)	-- go down if sand below
	-- repeat until height == 0
	repeat -- starts at bottom of sand wall
		blockType = T:getBlockType("forward")
		if blockType:find("sand") ~= nil then -- sand in front
			length, blockType = lib.moveForward(length) -- move forward 1 and dig sand
			if blockType == "" or  blockType:find("sand") ~= nil then -- sand or nothing in front
				height = lib.moveDown(height)	-- go down if sand below
			end
		else -- solid block, air or water, not sand so move up
			if turtle.detect() then -- block in front
				blockType = T:getBlockType("down")
				if blockType:find("sand") ~= nil then -- sand below
					T:dig("down")
				end
				T:up(1)
				height = height - 1
			else -- air/water in front so move forward
				if length < 60 then -- in case missing wall and in open ocean
					length, blockType = lib.moveForward(length) -- move forward 1 and dig sand
					height = lib.checkAbove(height)
				else -- already > monument length of 56
					T:up(1)
					height = height - 1
				end
			end
		end
	until height == 0 or length == R.length
	blockType = T:getBlockType("down")
	if blockType:find("sand") ~= nil then -- sand below
		T:dig("down")
	end
	if height > 0 then -- finished as length ran out
		T:up(height)
	end
	-- stay at end of cleared wall unless user chose to return
	if R.data == "return" then
		T:go("R2F"..length.."R2")
	end
	
	return {}
end

local function clearSolid(R) -- 76
	--[[ direction = R.subChoice = 1 up or 2 down ]]
	local height = 1
	local remaining = R.height 
	local lib = {}
	
	function lib.singleLayer(R)
		R.up = false
		R.down = false
		clearRectangle(R)
	end
	
	function lib.doubleLayer(R)
		R.up = false
		R.down = false
		if R.subChoice == 1 then
			R.up = true
		else
			R.down = true
		end
		clearRectangle(R)
	end
		
	function lib.tripleLayer(R)
		-- turtle in centre layer
		R.up = true
		R.down = true
		clearRectangle(R)
	end

	R.silent = true
	if R.height < 3 then 							--1-3 layers only
		if R.height == 1 then 						--one layer only
			lib.singleLayer(R)
		elseif R.height == 2 then 					--2 layers only current + dig up/down
			lib.doubleLayer(R)
		end
	else -- 3 or more levels
		height = height + utils.move(R, 1)			-- move up/down 1 block for first layer
		while remaining >= 3 do 					-- min 3 levels
			lib.tripleLayer(R)
			remaining = remaining - 3
			if remaining == 0 then					-- all finished
				break
			elseif remaining == 1 then
				height = height + utils.move(R, 2)	-- move up/down 2 blocks
				lib.singleLayer(R)
			elseif remaining == 2 then
				height = height + utils.move(R, 2)	-- move up/down 2 blocks
				lib.doubleLayer(R)
			else
				height = height + utils.move(R, 3)	-- move up/down 3 blocks
				if remaining == 3 then
					finish = true
				end
			end
		end
	end
	
	if height > 1 then
		utils.move(R, height - 1, true) -- reverse direction
	end
	
	return {}
end

local function clearSandCube(R) -- 81
	R.data = ""
	for w = 1, R.width do
		clearSandWall(R)
		if w < R.width then
			if w % 2 == 1 then
				T:go("R1F1R1")
			else
				T:go("L1F1L1")
			end
		end
	end
	
	return {}
end

local function clearWall(R) -- 73
	local lib = {}
	
	function lib.move(direction, blocks, reverse)
		--[[ Move up or down by blocks count ]]
		if reverse == nil then
			reverse = false
		end
		if reverse then
			if direction == "down" then -- reverse direction
				T:up(blocks)
			else
				T:down(blocks)
			end
		else
			if direction == "up" then
				T:up(blocks)
			else
				T:down(blocks)
			end
		end
		return blocks
	end
	
	function lib.singleLayer(length)
		T:go("F"..length - 1)
	end
	
	function lib.doubleLayer(modifier, length)
		for i = 1, length do
			if i < length then
				T:go("x"..modifier.."F1")
			else
				T:go("x"..modifier)
			end
		end
	end
	
	function lib.tripleLayer(direction, length)
		for i = 1, length do
			if i < length then
				T:go("x0x2F1")
			else
				T:go("x0x2")
			end
		end
	end
	
	
	-- R.width preset to 1
	-- R.subChoice = 1 up / 2 down
	if R.height < 3 then
		R.silent = true
	end
	-- dig along and up/down for specified R.length
	local modifier = "0"
	local direction = "U"
	local outbound = true
	local height = 0
	if R.subChoice == 2 then
		 modifier = "2"
		 direction = "D"
	end
	if R.height == 1 then 				-- single block so dig and return
		lib.singleLayer(R.length)
	elseif R.height == 2 then
		lib.doubleLayer(modifier, R.length)
	else								-- 4 blocks or more. start with bulk 3 blocks
		local remaining = R.height
		T:go(direction.."1")			-- up 1 or down 1
		height = 1
		while remaining >= 3 do 
			lib.tripleLayer(direction, R.length)
			remaining = remaining - 3
			
			if remaining == 0 then		-- no more, return home, already in position
				
			elseif remaining == 1 or remaining == 2 then
				T:go(direction.."2")
				height = height + 2
			else
				T:go(direction.."3")
				height = height + 3
				if remaining >= 3 then -- another iteration
					T:go("R2")
					outbound = not outbound
				end
			end
		end
		-- 0, 1 or 2 layers left
		if remaining > 0 then
			T:go("R2")
			outbound = not outbound
			if remaining == 1 then
				lib.singleLayer(R.length)
			elseif remaining == 2 then
				lib.doubleLayer(modifier, R.length)
			end
		end
	end
	if outbound then
		T:go("R2F"..R.length)
	else
		T:forward(1)
	end
	direction = "D" -- reverse direction
	if R.subChoice == 2 then
		 direction = "U"
	end
	if height > 0 then
		T:go(direction..height.."R2")
	else
		T:go("R2")
	end
	return {}
end

local function convertWater(R) -- 88
	--[[
	if dry need enough buckets to place along (width + length - 1) / 2
	use 12 buckets
	start on floor + 1
	place slab down and water up along 2 edges. stay on this level
	return round same 2 edges removing slabs and and placing them 1 above
	placeUp water onto slabs on both edges
	repeat recover slabs, place 1 above , placeUp water
	
	for sloping water, place full area with slabs
	place sloping water on top of slabs
	remove slabs
	
	]]
	local lib = {}
	
	function lib.checkStartPosition()
		--[[
		0 T             -- T=turtle, W=wall, S=source, F=flowing
		1 W|S|F|F|F|F|F -- sloping flowing water
		2 W|F|F|F|F|F|F -- blocks removed after placing flowing water above
		3 W|S|S|S|S|S|S -- original sources
		4 W|?|?|?|?|?|? -- may be sources
		]]
		-- need to be on floor or R.height if specified
		local depth = 0
		local blockType = T:getBlockType("down")
		local isWaterUp, isSourceUp = T:isWater("up")
		local isWaterForward, isSourceForward = T:isWater("forward")
		local isWaterDown, isSourceDown = T:isWater("down")
		print("Block below is "..blockType)
		print("Water above is "..tostring(isWaterUp))
		print("Water forward is "..tostring(isWaterForward))
		print("Water below is "..tostring(isWaterDown))
		if blockType:find("water") == nil then -- on at least level 0
			print("Moving forward in 2 seconds...")
			sleep(2)
			T:forward(1)
			blockType = T:getBlockType("down")
			if blockType:find("water") ~= nil then
				print("Water found. Going down to floor")
				depth = -1
			else
				T:down(1)
				blockType = T:getBlockType("down")
				if blockType:find("water") ~= nil then
					depth = -2
				else
					return 0, "Not close to water. Aborting..."
				end
			end
		end
		while turtle.down() do
			depth = depth + 1
		end
		local emptyBuckets = utils.getEmptyBucketCount()
		for i = depth, 0, -1 do
			if emptyBuckets > 0 then
				lib.fillBuckets()
				emptyBuckets = utils.getEmptyBucketCount()
			end
			turtle.up()
		end
		
		return depth, ""
	end
	
	function lib.fillBuckets()
		local emptyBuckets = utils.getEmptyBucketCount()
		local direction = "forward"-- start with forward
		local isWater, isSource, isIce = T:isWater(direction)
		if emptyBuckets > 0 then
			if not isSource then
				direction = "down"
				isWater, isSource, isIce = T:isWater(direction)
				if not isSource then
					direction = "up"
					isWater, isSource, isIce = T:isWater(direction)
					if not isSource then
						direction = ""
					end
				end
			end
			if direction == "" then
				print("Unable to locate water source")
			else
				for i = 1, emptyBuckets do
					if utils.fillBucket(direction) then
						print("Bucket filled "..direction)
						sleep(0.3)
					else
						print("Unable to fill bucket ".. i .." / "..emptyBuckets)
					end
				end
			end
		end
		return utils.getWaterBucketCount()
	end
	
	function lib.placeSlabs(length)
		for i = 1, length do
			T:place("slab", -1, "down", false)
			if i < length then
				T:forward(1)
			end
		end
	end
	
	function lib.placeSources(length, place)
		local moves = 1
		local waterBuckets = utils.getWaterBucketCount()
		-- place sources alternate positions + start and finish
		while moves < length do
			if place then
				if T:place("minecraft:water_bucket", -1, "up") then
					print("Placed source up")
					waterBuckets = waterBuckets - 1
				end
			end
			place = not place
			if moves < length then
				T:forward(1)
				moves = moves + 1
			end
			if waterBuckets == 0 then
				T:down(1) -- break the slab below
				waterBuckets = lib.fillBuckets()
				T:up(1)
				T:place("slab", -1, "down", false)
			end
		end
		if T:place("minecraft:water_bucket", -1, "up") then -- end of length
			print("Placed final source up")
		end
		return place
	end
	
	function lib.moveSlabs(length)
		for i = 1, length do
			T:dig("down")
			T:up(1)
			T:place("slab", -1, "down", true)
			if i < length then
				T:forward(1)
				T:down(1)
			end
		end
	end
	
	function lib.recoverSlabs(length)
		for i = 1, length do
			T:dig("down")
			if i < length then
				T:forward(1)
			end
		end
	end
	
	local depth, message = lib.checkStartPosition()
	if message ~= "" then
		return {message}
	end
	local maxDepth = R.height
	local buckets = utils.getWaterBucketCount()
	R = utils.calculateDimensions(R) -- if R.width or R.length == 0
	T:down(depth)
	lib.placeSlabs(R.length)
	T:go("R1")
	lib.placeSlabs(R.width)
	T:go("R2")
	
	while depth > 0 do
		local place = true
		lib.fillBuckets()
		place = lib.placeSources(R.width, place)
		T:go("L1")
		place = lib.placeSources(R.length, place)
		lib.fillBuckets()
		T:go("R2")
		lib.moveSlabs(R.length) -- dig slab from below, move up and replace below
		T:go("R1F1D1")
		lib.moveSlabs(R.width - 1)
		T:go("R2") -- now moved up 1 layer
		depth = depth - 1
		if depth == 0 then
			place = lib.placeSources(R.width, true)
			T:go("L1")
			place = lib.placeSources(R.length, place)
			T:go("R2")
			lib.recoverSlabs(R.length)
			T:go("R1")
			lib.recoverSlabs(R.width)
		end
	end
	
	return {}
end

local function createBoatLift(R) -- 59 state:0=new, size:1=extend, side:0=left, 1=right
	-- build stepped lift with fencing gates and soul sand
	local lib = {}
	
	function lib.getWater(backToWater, downToWater)
		if backToWater > 0 then
			utils.goBack(backToWater)
		end
		if downToWater > 0 then
			T:down(downToWater)
		end
		T:place("minecraft:bucket", -1, "down") -- take water from source
		sleep(0.2)
		T:place("minecraft:bucket", -1, "down") -- take water from source
		if downToWater > 0 then
			T:up(downToWater)
		end
		if backToWater > 0 then
			T:forward(backToWater)
		end
	end
	
	--T:place(blockType, damageNo, direction, leaveExisting, signText)
	
	local backToWater = 0
	local downToWater = 
	
	T:go("R1F1L1") 										-- over canal facing forward
	for h = 1, R.height do
		lib.getWater(backToWater, downToWater)			-- check water supplies, return to starting position
		T:go("L1C1 R1D1 L1C1 R1", false, 0, false)		-- place towpath, forward, down, place towpath, face forward
		T:place("soul", -1, "down", false) 				-- place soulsand down
		T:place("soul", -1, "forward", false) 			-- place soulsand forward
		T:go("R1F1C1L1", false, 0, false)				-- place right towpath face forward
		T:place("soul", -1, "down", false) 				-- place soulsand down
		T:place("soul", -1, "forward", false) 			-- place soulsand forward
		T:go("U1 R1C1 L1")								-- place towpath, face forward
		T:place("water", -1, "down") 					-- place water down
		utils.goBack(1)
		T:place("gate", -1, "forward", false) 			-- place fence gate
		T:go("R1C1 U1C1 D1 L2F1 C1R1 F1 L1C1R1")		-- over left soul sand
		T:place("water", -1, "down") 					-- place water down
		utils.goBack(1)
		T:place("gate", -1, "forward", false) 			-- place fence gate
		T:go("U1 L1C1 R1F1 L1C1 R1x1")					-- facing forward first unit complete
		T:go("R1F1 L1x1 R1C1")
		utils.goBack(1)
		T:go("L1F1")
		if backToWater == 0 then
			backToWater = 1
		end
		backToWater = backToWater + 1
		downToWater = downToWater + 1
	end
	
	-- now finish the canal
	lib.getWater(backToWater, downToWater)
	T:go("D1 L1C1 U1C1")					-- build left towpath, facing towpath, above water level
	T:go("R1F1 L1C1 D1C1")					-- move forward, build towpath, facing towpath ground level
	T:go("R1C1 R1F1 L1C1 R1C1 U1C1")		-- build right towpath, facing towpath, above water level
	T:go("R1F1 L1C1 D1C1 U1")				-- build right towpath next to gate, facing towpath, above water level
	T:place("water", -1, "down") 
	utils.goBack(1)
	T:go("L1F1")
	T:place("water", -1, "down") 
	
	return {}
end

local function createBorehole(R)
	--[[go down to bedrock and return. Chart all blocks dug/ passed through]]
	local diary = {}
	local lib = {}
	local depth = R.height	-- eg 63 start position
	local moves = 0
	--R.height = current level
	
	function lib.addBlock(depth, blockType, diary)
		if blockType == "" then
			blockType = "air"
		end
		table.insert(diary, blockType)
		
		
		--[[if blockType ~= "" then
			local add = true
			for k,v in pairs(diary) do
				if blockType == v then
					add = false
					break
				end
			end
			if add then
				diary[depth] = blockType
			end
		end]]
		
		return diary
	end
	
	function lib.processItem(item)
		if item:find("minecraft") ~= nil then
			return item:sub(11)
		end
		return item
	end
	
	function lib.writeReport(R, diary)
		local numLevels = #diary						-- eg 125 levels
		local levelsPerCol = math.ceil(numLevels / 4)	-- eg 31.25 -> 32
		local lines = {}
		for l = 1, levelsPerCol do						-- add 32 empty strings
			table.insert(lines, "")
		end
		local lineNo = 1
		for k, v in ipairs(diary) do
			local level = R.height - k 					-- eg 63 range 63 to -59
			local lev = "      "
			local item = lib.processItem(v)
			if level < -9 then
				lev = tostring(level).."   "			-- "-10   " to "-59   "
			elseif level < 0 then				
				lev = "-0"..math.abs(level).."   "		-- "-09   " to "-01   " 
			elseif level < 10 then
				lev = " 0"..level.."   "				-- " 01   " to " 09   "
			elseif level < 100 then
				lev = " "..level.."   "					-- " 10   " to " 99   "
			else
				lev = " "..level.."  " 					-- " 100  " to " 319  "
			end
			local output = lev..item					-- eg "-10   grass_block"
			if #output > 20 then						-- eg "-10   some_long_block_name"  
				output = output:sub(1, 20)				-- eg "-10   some_long_block_" 
			else
				output = menu.padRight(output, 20, " ")	-- eg "-10   grass_block     "
			end
			lines[lineNo] = lines[lineNo]..output		-- add new entry to this line
			lineNo = lineNo + 1							-- increase line no
			if lineNo > levelsPerCol then				-- past last line number
				lineNo = 1								-- reset to 1
			end
		end
		
		local fileName = "borehole"..os.getComputerID()..".txt"
		local handle = fs.open(fileName, "w") 		--create file eg "borehole0.txt"
		handle.writeLine("Level Block         Level Block         Level Block         Level Block")
		for k,v in ipairs(lines) do
			handle.writeLine(v)
		end
		
		handle.close()
		
		return fileName
	end
	
	local blockType = T:getBlockType("down")
	while T:down(1) do
		depth = depth - 1
		moves = moves + 1
		if depth == R.depth then
			break
		end
		diary = lib.addBlock(depth, blockType, diary)
		blockType = T:getBlockType("down")
	end
	local fileName = lib.writeReport(R, diary)
	T:up(moves)
	
	return {"File '"..fileName.."' written"}
end

local function createBubbleLift(R) -- 15
	local lib = {}
	
	function lib.addLayer()
		T:go("F2 L1C1 R1C1 R1C1 L1", false, 0, true)
		turtle.back()
		T:place("minecraft:water_bucket", -1, "forward")
		T:dig("up")	-- clear block above so completed lift can be found
		turtle.back()
		T:dig("up")	-- clear block above so completed lift can be found
		T:place("stone", -1, "forward")
	end
	
	function lib.addSign()
		turtle.back()
		T:place("minecraft:water_bucket", -1, "forward")
		T:go("L1B1")
		T:place("sign", -1, "forward")
	end
	
	function lib.buildLift(toHeight)
		local built = lib.goToWater() 		-- returns lift blocks already placed, total height of drop from starting point
		local toBuild = toHeight - built 	-- no of blocks remaining to increase lift size
		local water = 0
		while toBuild > 0 do 				-- at least 1 block height remaining
			water = lib.fillBuckets(toBuild, false) -- no of water buckets onboard (could be more than required)
			if water > toBuild then			-- more water than required
				water = toBuild				-- reduce to correct amount
			end
			--while turtle.detect() do 		-- climb to top of existing lift
				--turtle.up()
			--end
			T:up(built)
			while water > 0 do
				lib.addLayer()
				water = water - 1
				T:up(1)
				toBuild = toBuild - 1
			end
			-- may still be some height to complete, but needs refill
			if toBuild > 0 then
				built = lib.goToWater() --return to source
				toBuild = toHeight - built
				--lib.fillBuckets(toBuild)
			end
		end
	end
	
	function lib.cleanUp(fromHeight)
		local plug = false
		T:turnRight(2)
		for i = 1, fromHeight do
			plug = false
			if turtle.detect() then
				plug = true
			end
			turtle.down()
			if plug then
				T:place("stone", -1, "up")
			end
		end
	end
	
	function lib.fillBuckets(toBuild, withSort)
		local emptySlots, water = lib.stackBuckets(withSort)-- gets no of empty slots + no of water buckets
		if water < toBuild then 					-- no of water buckets onboard less than required quantity
			for i = 1, toBuild do 					-- fill required no of buckets up to max space in inventory
				if emptySlots == 0 then 			-- inventory full
					break
				else
					if T:place("minecraft:bucket", -1, "down", false) then
						water = water + 1
						sleep(0.5)
					end
				end
				emptySlots = lib.getEmptySlots()
			end
		end
		
		return water
	end
	
	function lib.getEmptySlots()
		local empty = 0
		for i = 1, 16 do
			if turtle.getItemCount(i) == 0 then
				empty = empty + 1
			end
		end
		return empty
	end
	
	function lib.goToWater()
		local built = 0 -- measures completed lift height
		while turtle.down() do -- takes turtle to bottom of water source
			if turtle.detect() then
				built = built + 1
			end
		end
		T:up(1) -- above watersource ready to fill buckets
		-- height = height - 1
		-- built = built - 1 not required as next block is water source: not detected
		return built -- , height
	end
	
	function lib.stackBuckets(withSort)
		if withSort == nil then withSort = false end
		local data = {}
		local bucketSlot = 0
		local emptySlots = 0
		local water = 0
		if withSort then
			T:sortInventory()
		end
		for i = 1, 16 do
			-- find first empty bucket
			if turtle.getItemCount(i) > 0 then
				data = turtle.getItemDetail(i)
				if data.name == "minecraft:bucket" then
					if bucketSlot == 0 then
						bucketSlot = i
					else
						turtle.select(i)
						turtle.transferTo(bucketSlot)
					end
				elseif data.name == "minecraft:water_bucket" then
					water = water + 1
				end
			else
				emptySlots = emptySlots + 1
			end
		end
		return emptySlots, water
	end
	if R.data == "bedrock" then -- go up 2 
		T:up(2)
		R.height = R.height - 1
	end
	-- prepare source area and place soul sand
	T:go("R2 D1F1 D1C2 R1C1 R1", false, 0, true)			-- turn round, down 1, F-> 1 block from ladder, D1 check below, right, check side wall, right facing ladder
	T:place("minecraft:soul_sand", -1, "forward", false) 	-- placed at end of potential water source
	T:go("R1C1 R1", false, 0, true)							-- right, check side wall, right facing away from ladder
	T:go("F1C2 L1C1 R2C1 L1", false, 0, true) 				-- F->, prepare centre of water source: blocks down , left, right
	T:go("F1C2 L1C1 R1C1 R1C1 R1F1", false, 0, true)		-- F->, prepare end of water source, while turning, F->to centre, facing ladder
	-- ready for water sources to be placed
	T:place("minecraft:water_bucket", -1, "forward")		-- place front water source
	T:turnRight(2)											-- facing backward
	T:place("minecraft:water_bucket", -1, "forward")		-- place back water source
	T:go("R2U1") 											-- facing forward, U1, above centre of water source
	lib.fillBuckets(R.height, true)	-- fill as many buckets as required or until inventory full, sort inventory as well
	
	local nextToLadder = false
	--T:go("F2R1")
	T:go("x0F1 x0F1 R1") -- move forward 2 taking out blocks above
	if T:getBlockType("forward"):find("ladder") == nil then	-- no ladder here
		T:turnLeft(2)
		if T:getBlockType("forward"):find("ladder") ~= nil then	-- ladder here
			nextToLadder = true
		end
		T:turnRight(1)
	else
		nextToLadder = true
		T:turnLeft(1)
	end
	-- now above soul sand, facing forward
	if nextToLadder then								-- if nextToLadder, no need for signs
		utils.goBack(2) 								-- return to source centre
	else
		T:go("F2 L1C1R1C1R1C1L1", false, 0, true)		-- prepare layer 1
		lib.addSign()
		T:go("U1F1R1F1 L1C1R1C1R1C1L1", false, 0, true)	-- prepare layer 2
		lib.addSign()
		T:go("L1F1 R1F1R1", false, 0, true)	 			-- above source, level 2
	end
	-- ready to build lift
	lib.buildLift(R.height)
	lib.cleanUp(R.height)
	
	return {"Bubble lift created", "Check correct operation", "Check exit before using" }
end

local function createBubbleTrap(R) -- 34
	--[[
	Replace floor of existing volume of water with soulsand
	Used in river biome for squid farm. Area should be enclosed
	with solid walls surface to floor.
	Usually 7 blocks wide
	]]
	local lib = {}
	
	function lib.clearDown(depth)
		while utils.clearVegetation("down") do
			T:down(1)
			depth = depth + 1
		end
		T:place("soul_sand", -1, "down", false)
		return depth
	end
	
	function lib.clearLength(length, depth)
		local moves = 0
		while moves < length - 1 do
			if utils.clearVegetation("forward") then
				T:forward(1)
				moves = moves + 1 
				depth = lib.clearDown(depth) -- go down if in water/air
				if moves >= length - 1 then
					return depth
				end
			else -- block in front
				local waterAhead = utils.clearVegetation("forward") -- true if air/water in front
				while not waterAhead do 	-- solid block in front
					T:up(1)
					depth = depth - 1
					if depth < 1 then
						return 0
					end
					waterAhead = utils.clearVegetation("forward")
				end
			end
		end

		return depth
	end
	
	function lib.turn(facingForward, depth)
		local direction = "R"
		if not facingForward then
			direction = "L"
		end
		T:go(direction.. 1)
		if utils.clearVegetation("forward") then
			T:forward(1)
			depth = depth + lib.clearDown(depth)
		else
			while not utils.clearVegetation("forward") do
				T:up(1)
				depth = depth - 1
			end
		end
		T:go(direction.. 1)
		
		return depth
	end
	
	local depth = 0
	local length = 0
	local width = 0
	local outbound = true
	local facingForward = true
	local inWater, onWater = utils.getWaterStatus()
	inWater, onWater = utils.startWaterFunction(onWater, inWater, 2 ,true) -- move into water, max descent 2
	if R.length == 0 then
		R.length = lib.getLength()
	end
	if R.width == 0 then
		T:turnRight(1)
		R.width = lib.getLength()
		T:turnLeft(1)
	end
	-- go down to floor
	depth = lib.clearDown(depth)
	while width < R.width do
		-- now on floor, move along sea/river bed following contour
		depth = lib.clearLength(R.length, depth)
		width = width + 1
		-- now turn and repeat
		if width < R.width then	
			depth = lib.turn(facingForward, depth)
			facingForward = not facingForward
		end
	end
	-- finished so return to surface
	T:up(1) -- up 1 to check for water below
	while T:isWater("down") do
		T:up(1)
	end
	
	return {}
end

local function createCanal(R) -- 54
	--[[
	go(path, useTorch, torchInterval, leaveExisting)
	R.height = 0 or 1
	R.side = "R" or "L"
	R.subChoice =
		1 = left side, ground level (on towpath)
		2 = left side above canal water (new canal only)
		3 = right side above canal water (new canal only)
		4 = right side, ground level (on towpath)
		5 = left side in canal water (if present)
		6 = right side in canal water (if present)
	
	if R.height = 0 then already at correct height on canal floor
		check block below, block to left and block above, move forward tunnelling
		if entering water then move up, onto canal wall and continue pathway
		if tunnelling then flood canal
	else R.height = 1 then above water and on path across
		move forward, checking for water below
		if water finishes, move into canal, drop down and continue tunnelling
	]]
	local lib = {}
			
	function lib.side(R, maxLength)
		-- Already in position facing new canal, 2 water buckets
		local torch = R.length - maxLength					-- start torch count at 1-2 depending on lib.initialise()
		local sourceCount = 0								-- allow for 1 iteration of placing source blocks when changing from solid to water
		local numBlocks = 0									-- distance travelled
		local _, isSource = nil, false						-- initialise variables
		local oTurn = "R"									-- assume R.side == "L" -> oTurn = "R"
		if R.side == "R" then								-- R.side = "R"
			oTurn = "L"										-- oTurn = "L"
		end
		
		while numBlocks < maxLength do						-- loop from here. Facing forwards to extend canal
			torch = torch + 1								-- increase torch spacing interval
			numBlocks = numBlocks + 1						-- inrease block count
			if deletesWater then							-- up to and including mc 1.12.2
				T:forward(1)								-- move forward to extend canal  | |>|
				_, isSource = T:isWater("down")				-- check if source water below
				if isSource then
					sourceCount = sourceCount + 1			-- count source blocks
				else										
					T:down(1)								-- down to canal floor
					sourceCount = 0							-- reset
					T:go("C2", false, 0, false)				-- place block below
					T:up(1)									-- up to water level
				end											-- still facing away from canal
				T:go(R.side.."1F1C2", false, 0, false) 		-- go above towpath, place stone down, facing out
				if turtle.detectUp() then 					-- ? block above
					T:go(R.side.."2U1F1D1"..R.side.."2")	-- rotate to face canal, up 1 forward over canal, back down to water level, face towpath
				else
					utils.goBack(1)							-- face towpath
				end
				-- facing towpath
				if R.torchInterval > 0 then					-- Are torches required?
					if torch == R.torchInterval  or numBlocks == 0 then		-- check if ready to place
						torch = 0							-- reset interval counter
						T:go("U1F1")
						T:place("torch", -1, "down")		-- place torch
						utils.goBack(1)
						T:down(1)
					end
				end											-- facing towpath, above water
				-- facing towpath
				if isSource and scoreCount > 0 then
					T:go(oTurn.."1x0")						-- face new canal direction
				else										-- not source below, or first time found, ensures continous canal
					T:go(R.side.."1x0")						-- face back to existing canal
					T:place("water_bucket", -1, "down")		-- place water
					T:forward(1)							-- forward 1
					T:place("water_bucket", -1, "down")		-- place water
					utils.getWater() 							-- collects water from below
					utils.goBack(1) 						-- back 1
					T:go(oTurn.."1x0")						-- face new canal
				end
			else
				T:forward(1) 								-- move forward to extend canal
				_, isSource = T:isWater("forward")			-- check if source water ahead
				if isSource then							-- ? source ahead
					sourceCount = sourceCount + 1
				else
					sourceCount = 0
					if not turtle.detectDown() then			-- air / water below, but no source in front, so fill it
						T:go(oTurn.."1D1")					-- ready to repair neighbouring canal base
						if T:getBlockType("forward"):find("turtle") ~= nil then -- turtle in similar position
							if R.side == "L" then			-- only left side repairs, so wait 1 second
								sleep(1)
								T:go("C1")					-- repair neighbouring canal base
							end
							T:go(R.side.."1")				-- face forward
						else
							T:go("C1"..R.side.."1")			-- repair neighbouring canal base if air
						end
						T:up(1)
					end
					T:go("C2", false, 0, false)				-- place block below if not already source
				end
				T:go(R.side.."1C1", false, 0, false) 		-- face canal wall, replace with stone
				
				local placeTorch = false
				if R.torchInterval > 0 then					-- Are torches required?
					if torch == R.torchInterval  or numBlocks == 0 then		-- check if ready to place
						torch = 0							-- reset interval counter
						placeTorch = true
					end
				end
				if (isSource and placeTorch) or not isSource then
					T:go("U1x1 U1x1")						-- up 2 and excavate blocks above tow path
					if placeTorch then						-- torch required
						T:forward(1)						-- move over towpath
						T:place("torch", -1, "down")		-- place torch
						utils.goBack(1)						-- move back
					end
					T:down(2)								-- return to canal base
				end
				if isSource and sourceCount > 1 then 		-- source ahead found at least once
					T:go(oTurn.."1")						-- face newcanal as no water refill required
				else										-- not source in front, or first time found, ensures continous canal
					T:go(oTurn.."1C1") 						-- *| | | |>| face along new canal and block entrance
					utils.goBack(1)							-- *| | |>| | back 1
					T:place("water_bucket", -1, "forward")	-- *| | |>|W| place water
					T:go(oTurn.."2") 						-- *| | |<|W| face existing canal 
					_, isSource = T:isWater("forward")		-- *| |?|<|W| check if source water ahead 
					if not isSource then
						if not T:place("water_bucket", -1, "forward") then	-- place water again *| |W|<|W|
							while not T:place("bucket", -1, "forward") do -- wait for other turtle
								print("Out of water buckets")
								sleep(1)
							end
							sleep(0.2)
							T:place("bucket", -1, "forward") 
						end
					end
					utils.getWater() 							-- collects water *| |W|<|W|
					T:go(R.side.."2F1") 						-- face along new canal *| |W|>|W| to *| |W|W|>|
				end
			end
		end
	end
			
	local maxLength = 1024
	if R.length ~= 0 then
		maxLength = R.length
	end
	menu.clear()
	menu.colourWrite("Building canal "..R.side.." side .......", colors.yellow, nil, nil, false, true)
	local moves = utils.initialiseCanal(R) -- move to correct position and/or start new canal
	lib.side(R, maxLength - moves)
	
	return {}
end

local function createCorridor(R) -- 52
	local lib = {}
	
	function lib.placeTorch(R, torchSpaces, totalSteps)
		if R.torchInterval > 0 then -- torches onboard
			if torchSpaces == R.torchInterval then -- time to place another torch
				if totalSteps < R.length then -- not at end of run
					if T:getItemSlot("minecraft:torch") > 0 then
						T:place("minecraft:torch", -1, "down")
					end
					torchSpaces = 1
				end
			end
		end
		return torchSpaces -- original value or 1
	end
	
	local currentSteps = 0					-- counter for infinite length. pause every 64 blocks
	local totalSteps = 0					-- counter for all steps so far
	local torchSpaces = R.torchInterval		-- if torches present, counter to place with 8 blocks between
	if T:getItemSlot("minecraft:torch") == 0 then
		R.torchInterval = 0 -- set to default 9 in getTask()
	end
	for steps = 1, R.length do
		if not R.silent then
			if currentSteps >= 64 and R.length == 0 then
				-- request permission to continue if infinite
				T:clear()
				print("Completed "..totalSteps..". Ready for 64 more")
				print("Do you want to continue? (y/n)")
				response = read()
				if response:lower() ~= "y" then
					break
				end
				currentSteps = 0
			end
		end
		T:go("C2U1C0", false, 0, true)
		torchSpaces = lib.placeTorch(R, torchSpaces, totalSteps) -- original value or 1 if torch placed
		T:go("F1D1", false, 0, true)
		currentSteps = currentSteps + 1
		totalSteps = totalSteps + 1
		torchSpaces = torchSpaces + 1
	end
	return {}
end

local function createDragonTrap() -- 49
	local lib = {}
	
	function lib.attack()
		local totalHitsF = 0
		local totalHitsU = 0
		local totalHitsD = 0
		while true do
			local hitF = false
			local hitU = false
			local hitD = false
			if turtle.attackUp() then
				hitU = true
				totalHitsU = totalHitsU + 1
			end
			if turtle.attackDown() then
				hitD = true
				totalHitsD = totalHitsD + 1
			end
			if turtle.attack() then
				hitF = true
				totalHitsF = totalHitsF + 1
			end
			if hitF or hitU or hitD then
				print("hits forward: "..totalHitsF..", up: "..totalHitsU..", down: "..totalHitsD)
			end
		end
	end
	-- build up 145 blocks with ladders
	for i = 1, 145 do
		T:go("U1C2")
		turtle.back()
		T:place("minecraft:ladder", -1, "down")
		turtle.forward()
	end
	T:go("R2F1C1 L1C1 L2C1 R1")
	for i = 1, 100 do
		T:go("F1C2U1C0D1")
	end
	T:forward(1)
	T:place("minecraft:obsidian", -1, "down")
	T:go("R2F1x2R2")
	T:place("minecraft:water_bucket", -1, "forward")
	T:go("R2F6R2")
	lib.attack()
	return {}
end
	
local function createEnderTower(stage) -- 66
	--[[ lower base = stage 1, upper base = 2, tower = 3 ]]
	local lib = {}
	--[[ go(path, useTorch, torchInterval, leaveExisting, preferredBlock) ]]
	function lib.getEmptySlots()
		local empty = 0
		for i = 1, 16 do
			if turtle.getItemCount(i) == 0 then
				empty = empty + 1
			end
		end
		return empty
	end

	function lib.getStone(direction, stacks)
		--[[ get block user wants to use ]]
		local suck = turtle.suck	
		if direction == "down" then
			suck = turtle.suckDown
		end
		if T:getBlockType(direction) == "minecraft:chest" then
			T:sortInventory()
			local slot = T:getFirstEmptySlot() --find spare slot
			if slot > 0 then --empty slot found
				turtle.select(1)
				if stacks == 0 then
					while suck() do end
				else
					for i = 1, stacks do -- get # stacks of stone from chest
						suck()
					end
				end
				if T:getSlotContains(slot) == "" then
					return T:getMostItem()				-- empty chest
				else
					return T:getSlotContains(slot) 		-- use this as default building block
				end
			else
				return T:getMostItem()				-- full inventory
			end
		else
			return T:getMostItem()				-- no chest
		end
	end
	
	function lib.stackBuckets()
		local data = {}
		local bucketSlot = 0
		local emptySlots = 0
		local water = 0
		T:sortInventory()
		for i = 1, 16 do
			-- find first empty bucket
			if turtle.getItemCount(i) > 0 then
				data = turtle.getItemDetail(i)
				if data.name == "minecraft:bucket" then
					if bucketSlot == 0 then
						bucketSlot = i
					else
						turtle.select(i)
						turtle.transferTo(bucketSlot)
					end
				elseif data.name == "minecraft:water_bucket" then
					water = water + 1
				end
			else
				emptySlots = emptySlots + 1
			end
		end
		return emptySlots, water
	end
	
	function lib.countWaterBuckets()
		local data = {}
		local buckets = 0
		for i = 1, 16 do
			data = turtle.getItemDetail(i)
			if data.name == "minecraft:water_bucket" then
				buckets = buckets + 1
			end
		end
		return buckets
	end
	
	function lib.baseRun(preferredBlock, count, turn)
		for i = 1, count do
			T:go("C2F1", false, 0, false, preferredBlock)
		end
		T:go("C2"..turn, false, 0, false, preferredBlock)
	end
	
	function lib.outsideRun(preferredBlock)
		T:place("fence", -1, "down", false)
		T:forward(1)
		T:place(preferredBlock, -1, "down", false)
		T:forward(1)
		T:place(preferredBlock, -1, "down", false)
		T:forward(2)
		T:place(preferredBlock, -1, "down", false)
	end
	
	function lib.signRun(preferredBlock ,message)
		T:place(preferredBlock, -1, "down", false)
		T:forward(4)
		T:place(preferredBlock, -1, "down", false)
		turtle.back()
		turtle.back()
		T:down(1)
		T:place("sign", -1, "forward", false, message)
		T:go("U1F2")
	end
	
	function lib.goToWater(height)
		local built = 0 -- measures completed lift height
		while turtle.down() do -- takes turtle to bottom of water source
			height = height + 1
			if turtle.detect() then
				built = built + 1
			end
		end
		T:up(1) -- above watersource assuming it is 1-1.5 blocks deep
		height = height - 1
		-- built = built - 1 not required as next block is water source: not detected
		return built, height
	end
	
	function lib.fillBuckets(toBuild)
		local emptySlots, water = lib.stackBuckets() -- gets no of empty slots + no of water buckets
		if water < toBuild then -- no of water buckets onboard less than required quantity
			for i = 1, toBuild do -- fill required no of buckets up to max space in inventory
				emptySlots = lib.getEmptySlots()
				if emptySlots == 0 then -- inventory full
					break
				else
					if T:place("minecraft:bucket", -1, "down", false) then
						water = water + 1
						sleep(0.5)
					end
				end
			end
		end
		
		return water
	end
	
	function lib.buildLift(preferredBlock)
		local built = 0 -- measures completed lift height
		local height = 0 -- measures total height from starting position
		built, height = lib.goToWater(height) -- returns lift blocks already placed, total height of drop from starting point
		local toBuild = height - built -- no of blocks to increase lift size
		while toBuild > 0 do -- at least 1 block height remaining
			local water = lib.fillBuckets(toBuild) -- no of water buckets onboard (could be more than required)
			if water > toBuild then
				water = toBuild
			end
			while turtle.detect() do -- climb to top of existing lift
				turtle.up()
				height = height - 1
			end
			T:forward(1)
			for i = 1, water do -- build lift by no of water buckets
				if T:place("minecraft:water_bucket", -1, "forward", false) then
					T:up(1)
					height = height - 1
					toBuild = toBuild - 1
					T:place(preferredBlock, -1, "down", false)
				end
			end
			turtle.back()
			-- may still be some height to complete, but needs refill
			if toBuild > 0 then
				lib.goToWater(0) --return to source
				lib.fillBuckets(toBuild)
			end
		end
		if height > 0 then -- if any remaining distance
			T:up(height)
		end
		
	end
	
	function lib.buildSection(preferredBlock, solid)
		-- builds a section without any blocks in the centre
		-- second layer of each section end walls have fence posts
		T:go("F1C2 F2C2 F1R1", false, 0, false, preferredBlock) -- first side solid row
		if solid then -- first layer of each section
			T:go("F1C2 F1R1", false, 0, false, preferredBlock) -- top side solid row
		else
			T:go("F1") -- top side solid row
			if not T:place("fence", -1, "down", false) then-- first side
				T:place(preferredBlock, -1, "down", false)
			end
			T:go("F1R1") -- top side solid row
		end
		T:go("F1C2 F2C2 F1R1", false, 0, false, preferredBlock) -- far side solid row
		T:go("F1C2 F1R1U1", false, 0, false, preferredBlock) -- bottom side solid row
	end	
	--[[
		clsTurtle methods:
		clsTurtle.place(self, blockType, damageNo, direction, leaveExisting)
		clsTurtle.go(self, path, useTorch, torchInterval, leaveExisting, preferredBlock)
	]]
	-- remove 1 stack stone from chest
	local preferredBlock = lib.getStone("down", 1) -- use this as default building block
	if stage == 1 then
		-- build base floor
		--T:go("R2F2R1F3R1", false, 0, false, preferredBlock)
		T:go("R2F1C2R1F1C2F1C2F1C2R1", false, 0, false, preferredBlock)
		for i = 1, 2 do
			lib.baseRun(preferredBlock, 8, "R1F1R1")
			lib.baseRun(preferredBlock, 8, "L1F1L1")
			lib.baseRun(preferredBlock, 8, "R1F4R1")
		end
		-- move back to centre, build water source, with soul sand at base of first source
		--T:go("R1F3L1C2F1C2F2D1", false, 0, false, preferredBlock) --just behind chest, 1 below ground level
		T:go("R1F3L1F2C2F1D1", false, 0, false, preferredBlock) --1 block behind chest, 1 below ground level
		T:place("minecraft:soul_sand", -1, "down", false) -- over block 1 of water source
		T:go("F1C2F1C2", false, 0, false, preferredBlock) -- over block 2 of water source
		T:go("F1C2U1C2", false, 0, false, preferredBlock) -- over block 4 of water source
		T:go("F1C2F1C2R2F5R2", false, 0, false, preferredBlock) -- over block 1 of water source
		T:place("minecraft:water_bucket", -1, "down", false)
		T:forward(2) -- over block 3 of water source
		T:place("minecraft:water_bucket", -1, "down", false)
		turtle.back() -- over block 2 of water source
		T:place("minecraft:bucket", -1, "down", false)
		T:go("F2D1R2C2") -- over block 4 of water source
		T:go("U1", false, 0, false, preferredBlock)
		T:place("minecraft:water_bucket", -1, "down", false)
		T:forward(4)
		lib.stackBuckets() -- put all buckets in same slot
		T:dropItem("minecraft:dirt", "up", 0) -- drop dirt up:  clsTurtle.dropItem(self, item, direction, keepAmount)
		preferredBlock = lib.getStone("down", 6)
		T:go("R1F2R1U1") -- move to start position
		for i = 1, 2 do
			-- build first level of tower: 2 x outside run, 2 x sign run
			lib.outsideRun(preferredBlock)
			if i == 1 then -- place door
				T:go("L1F1L1F1L1D1")
				T:place("door", -1, "forward", false)
				T:go("U1L1F1R1F1L1")
			end
			T:go("R1F1R1")
			lib.signRun(preferredBlock, "Pint size\nzombies\nProhibited")
			T:go("L1F1L1C2", false, 0, false, preferredBlock)
			T:forward(4) -- miss out centre block
			T:place(preferredBlock, -1, "down", false)
			T:go("R1F1R1")
			lib.signRun(preferredBlock, "Pint size\nzombies\nProhibited")
			T:go("L1F1L1")
			lib.outsideRun(preferredBlock)
			if i == 1 then -- layer 1
				T:go("R1F1R1F1R1D1") -- place door
				T:place("door", -1, "forward", false)
				T:go("U1 R1F1 L1F5 L1U1 F2D1  F2R2 U1") -- go over door
			else -- layer 2
				T:go("L1F5L1F6R2U1") -- over corner of lower platform
			end
		end
		for i = 1, 2 do -- build both sides of platform, leave centre missing
			lib.baseRun(preferredBlock, 8, "R1F1R1")
			lib.baseRun(preferredBlock, 8, "L1F1L1")
			lib.baseRun(preferredBlock, 8, "R1F4R1")
		end
		T:go("R1F3L1C2F1C2F1C2F4C2F1C2F1C2", false, 0, false, preferredBlock) --fill in centre row
		--T:go("R2F6R1F1R1U1") -- go to start of tower base
		T:go("R2F7R2D3") -- go to start on top of chest
		T:sortInventory()
	elseif stage == 2 then
		-- start on top of chest, should have sufficient stone in inventory
		T:go("U3L1F1R1F1U1") -- go to start of tower base
		for i = 1, 7 do -- build 14 block high tower
			lib.buildSection(preferredBlock, false)
			lib.buildSection(preferredBlock, true)
		end
		T:go("R2F4R1F4R1", false, 0, false, preferredBlock) -- build upper platform (154 blocks remaining)
		for i = 1, 2 do -- build both sides of upper platform, leave centre missing
			lib.baseRun(preferredBlock, 12, "R1F1R1")
			lib.baseRun(preferredBlock, 12, "L1F1L1")
			lib.baseRun(preferredBlock, 12, "R1F1R1")
			lib.baseRun(preferredBlock, 12, "L1F1L1")
			lib.baseRun(preferredBlock, 12, "R1F6R1")
		end
		T:go("R1F5 L1C2 F1C2 F1C2 F1C2 F1C2 F4C2 F1C2 F1C2 F1C2 F1C2 ", false, 0, false, preferredBlock) --fill in centre row
		T:go("R2F5") -- return to drop area
		lib.buildLift(preferredBlock) -- build bubble lift
		T:go("F3R1F1R1U1") -- go to start of tower base
		T:go("C2F4 C2R1F1R1", false, 0, false, preferredBlock) 		-- left side layer 21
		T:go("F2C2 F2C2 L1F1L1", false, 0, false, preferredBlock) 	-- centre layer 21
		T:go("C2F4 C2R2U1", false, 0, false, preferredBlock) 		-- right side layer 21
		T:go("C2F4 C2R1F1R1", false, 0, false, preferredBlock) 		-- right side layer 22
		T:place("fence", -1, "down", false)							-- fence centre of bottom side layer 22
		T:go("F2C2 F2L1F1L1", false, 0, false, preferredBlock)		-- centre layer 22
		T:go("C2F4 C2R2F2L1F1R2D2", false, 0, false, preferredBlock) --ready to place ladder
		T:place("ladder", -1, "forward", false)
		T:up(1)
		T:place("ladder", -1, "forward", false)
		--T:go("U2R1F4R1F1R1") -- ready to make upper part of tower base
		T:go("U2R1F4R1F1R1") -- ready to make upper part of tower base
		for i = 1, 2 do -- build both sides of platform, leave centre missing
			lib.baseRun(preferredBlock, 8, "R1F1R1")
			lib.baseRun(preferredBlock, 8, "L1F1L1")
			lib.baseRun(preferredBlock, 8, "R1F4R1")
		end
		T:go("R1F3 L1C2 F1C2 F1C2 F1", false, 0, false, preferredBlock) --fill in centre row
		T:place("minecraft:soul_sand", -1, "down", false) 
		T:go("F1C2 F2C2 F1C2 F1C2", false, 0, false, preferredBlock)
		T:go("R2F6R1F1R1U1") -- go to start of tower base
		-- build 2 levels, finish signs and ladders
		T:go("C2F2 R1D2 U1", false, 0, false, preferredBlock)
		T:place("ladder", -1, "down", false)
		T:turnRight(1)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1R2F2C2 R1F2C2 R1", false, 0, false, preferredBlock) --top right corner
		T:go("F4C2B2D1", false, 0, false, preferredBlock)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1F2R1F1C2F1R1U1", false, 0, false, preferredBlock) --ready for second level
		T:go("C2F2 R2D1", false, 0, false, preferredBlock)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1R2F2C2R1", false, 0, false, preferredBlock) --top left corner
		T:go("F1R1C2F4C2", false, 0, false, preferredBlock) --mid bottom row
		T:go("L1F1L1C2", false, 0, false, preferredBlock) -- bottom right corner
		T:go("F2R2D1", false, 0, false, preferredBlock)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1R2F2C2", false, 0, false, preferredBlock) -- top right corner
		-- return to chest
		T:go("L1F1L1 F5D23R2", false, 0, false, preferredBlock) -- return to chest
		T:sortInventory()
	elseif stage == 3 then
		--[[ move to top of structure
		| 4 |
		|3 5|
		| X |
		|2 6|
		| 1 |
		]]
		local towerHeight = 128 -- even no only suggest 128
		while turtle.detect() do
			turtle.up()
		end
		T:go("F1U1", false, 0, false, preferredBlock) -- return to finish tower
		for i = 1, towerHeight do -- 1
			T:go("C2U1", false, 0, false, preferredBlock)
		end
		T:go("F1L1F1R1D2")
		while turtle.down() do -- 2
			T:fillVoid("up", {preferredBlock})
		end
		T:go("F1R2C1R2F1D1", false, 0, false, preferredBlock)
		for i = 1, towerHeight / 2 do -- 3
			T:go("U2C2", false, 0, false, preferredBlock)
		end
		T:go("U1F1R1F1R1D1", false, 0, false, preferredBlock) -- back of tower facing front
		local deviate = false
		while turtle.down() do -- 4
			T:place("fence", -1, "up", false)
			if turtle.down() then
				T:fillVoid("up", {preferredBlock})
			else
				T:go("F1R2C1R1F1R1D1", false, 0, false, preferredBlock)
				deviate = true
				break
			end
		end
		if not deviate then
			T:go("F1L1F1R1D1", false, 0, false, preferredBlock)
		end
		for i = 1, towerHeight / 2 do -- 5
			T:go("U2C2", false, 0, false, preferredBlock)
		end
		T:go("F2R2", false, 0, false, preferredBlock) -- facing back of tower
		while turtle.down() do -- 6
			T:fillVoid("up", {preferredBlock}) --layer 129
		end
		T:go("F1L2C1U"..towerHeight)
		T:go("F4R1F3R1U1", false, 0, false, preferredBlock)
		-- add small platform at the top
		lib.baseRun(preferredBlock, 8, "R1F1R1")
		lib.baseRun(preferredBlock, 8, "L1F3L1")
		lib.baseRun(preferredBlock, 8, "L1F1L1")
		lib.baseRun(preferredBlock, 8, "R1F1R1")
		T:go("C2 F1C2 F1C2 F4C2 F1C2 F1C2 R2F3", false, 0, false, preferredBlock) --fill in centre row
		lib.buildLift(preferredBlock) -- build bubble lift
	end
	return {}
end

local function createFarm(R, extend) -- 31
	-- if extend ~= nil then this has been called from createFarmExtension()
	-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	local lib = {}
	function lib.addWaterSource(R, pattern, storage)
		-- pattern = {"d","c","c","d"} t = place crafting  instead of dirt
		-- place(self, blockType, damageNo, direction, leaveExisting, signText)
		T:go("D1x2C2", false, 0, false, R.useBlockType)
		for i = 1, 4 do
			T:dig("forward")
			if pattern[i] == "d" then
				T:place("dirt", -1, "forward", false)
			elseif pattern[i] == "t" then
				--if not T:place("minecraft:crafting_table", -1, "forward", false) then
				if not T:place(storage, -1, "forward", false) then
					T:place("dirt", -1, "forward", false) -- dirt if no crafting table
				end
			else
				T:place(R.useBlockType, -1, "forward", false)
			end
			T:turnRight(1)
		end
		T:up(1)
		T:place("minecraft:water_bucket", -1, "down")
	end
	
	function lib.placeDirt(count, atCurrent)
		if atCurrent then
			local blockType = T:getBlockType("down")
			if blockType:find("dirt") == nil and blockType:find("grass_block") == nil then
				T:place("dirt", -1, "down", false)
			end
		end
		for  i = 1, count do
			T:forward(1)
			T:dig("up")
			local blockType = T:getBlockType("down")
			if blockType:find("dirt") == nil and blockType:find("grass_block") == nil then
				T:place("dirt", -1, "down", false)
			end
		end
	end

	function lib.placeStorage(storage, storageBackup)
		T:dig("down")
		if not T:place(storage, -1, "down", false) then-- place barrel/chest below
			T:place(storageBackup, -1, "down", false) -- place chest below
		end
	end

	
	-- extend "", "right" or "forward". only adds a single new farm.
	-- right adds farm and checks for existing front extensions, dealt with separately
	-- clsTurtle.place(blockType, damageNo, direction, leaveExisting)
	if extend == nil then
		extend = ""
	end
	local blockType = ""
	-- extend = "right": placed on cobble corner of existing farm facing right side
	-- extend = "front": placed on cobble corner of existing farm facing front
	-- else placed on ground at corner of potential new farm facing front
	
	local storage, storageBackup = utils.setStorageOptions()
	-- step 1 dig ditch round perimeter wall
	if extend == "right" then
		-- move to front corner ground ready for ditch
		T:go("F1L1F12D1R1", false, 0, false, R.useBlockType)
		-- cut ditch round new farm extension
		for i = 1, 12 do
			T:go("x0F1")
		end
		T:go("R1x0")
		for i = 1, 13 do
			T:go("x0F1")
		end
		T:go("R1x0")
		-- now at lower right corner. if extension below, do not cut ditch
		blockType = T:getBlockType("forward")
		if blockType:find("stone") ~= nil then -- already a farm extension on left side
			-- return to start for adding chests and walls
			T:go("U1R1F1L1F12", false, 0, false, R.useBlockType)
		else -- finish ditch
			for i = 1, 12 do
				T:go("x0F1")
			end
			T:go("R1U1F1") -- on corner of new extension
		end
	elseif extend == "forward" then
		T:go("L1F2R1D1", false, 0, false, R.useBlockType)
		-- cut ditch round new farm extension
		for i = 1, 12 do
			T:go("x0F1", false, 0, false, R.useBlockType)
		end
		T:go("R1x0", false, 0, false, R.useBlockType)
		for i = 1, 13 do
			T:go("x0F1", false, 0, false, R.useBlockType)
		end
		T:go("R1x0", false, 0, false, R.useBlockType)
		for i = 1, 11 do
			T:go("x0F1", false, 0, false, R.useBlockType)
		end
		T:go("U1x0F1R1F12R1", false, 0, false, R.useBlockType) -- on corner of new extension
	else -- new farm. cut a groove round the entire farm base
		-- move to left side of intended wall
		T:go("L1F1x0R1", false, 0, false, R.useBlockType)
		for j = 1, 4 do
			for i = 1, 12 do
				T:go("x0F1", false, 0, false, R.useBlockType)
			end
			T:go("R1x0F1", false, 0, false, R.useBlockType)
		end
		T:go("R1F1L1U1", false, 0, false, R.useBlockType)
	end
	-- stage 2 place sapling and double barrel/chest
	T:dig("down") --remove cobble if present
	T:place("dirt", -1, "down", false)
	T:go("F1R2")
	T:place("sapling", -1, "forward", false) -- plant sapling
	T:go("L1")
	lib.placeStorage(storage, storageBackup)
	T:go("L1F1R1")
	lib.placeStorage(storage, storageBackup)
	T:turnLeft(1)
	if extend == "right" then -- cobble wall exists so go forward to its end
		T:forward(9)
	else -- new farm or extend forward
		for i = 1, 9 do -- complete left wall to end of farm
			T:go("F1x0x2C2", false, 0, false, R.useBlockType)
		end
	end
	T:go("R1F1R1x0x2C2F1D1", false, 0, false, R.useBlockType)-- turn round ready for first dirt col
	lib.addWaterSource(R, {"d","c","c","d"}, storage) -- water at top of farm
	lib.placeDirt(9, false) -- place dirt back to start
	lib.addWaterSource(R, {"c","c","t","d"}, storage) -- water source next to chests, includes crafting table
	T:go("U1F1R2")
	if T:getBlockType("down"):find(storage) == nil and T:getBlockType("down"):find(storageBackup) == nil then
		lib.placeStorage(storage, storageBackup)
	end
	T:go("R1F1L1")
	if T:getBlockType("down"):find(storage) == nil and T:getBlockType("down"):find(storageBackup) == nil then
		lib.placeStorage(storage, storageBackup)
	end
	T:go("F1D1")
	lib.placeDirt(9, true)
	local turn = "R"
	for i = 1, 7 do
		T:go("F1U1x0C2"..turn.."1F1"..turn.."1x0x2C2F1D1", false, 0, false, R.useBlockType)
		lib.placeDirt(9, true)
		if turn == "R" then
			turn = "L"
		else
			turn = "R"
		end
	end
	T:go("F1U1x0C2"..turn.."1F1"..turn.."1x0x2C2F1D1", false, 0, false, R.useBlockType)
	lib.addWaterSource(R, {"d","c","c","d"}, storage)
	lib.placeDirt(9, false)
	lib.addWaterSource(R, {"c","c","d","d"}, storage)
	T:go("F1U1R1C2x0F1x0x2C2R1", false, 0, false, R.useBlockType)
	for i = 1, 11 do
		T:go("F1x0x2C2", false, 0, false, R.useBlockType)
	end
	-- add barrel/chest to any existing farm extension to the right
	T:go("L1F1L1")
	if T:getBlockType("down"):find("stone") == nil then -- farm extension already exists to right
		lib.placeStorage(storage, storageBackup)
	end
	T:go("L1F11")
	
	return {"Modular farm completed"}
end

local function createFarmExtension(R) -- 32
	-- assume inventory contains 4 chests, 64 cobble, 128 dirt, 4 water, 1 sapling
	-- check position by rotating to face tree/sapling
	local doContinue = true
	local treePresent = false
	local extend = "right" -- default
	if R.subChoice == 1 then
		extend = "forward"
	end
	local storage, storageBackup = utils.setStorageOptions()
	local blockType = T:getBlockType("down")
	if blockType:find(storage) == nil and blockType:find(storageBackup) == nil then
		return
		{
			"Barrel or chest not present below\n",
			"Unable to calculate position",
			"Move me next to/front of the tree/sapling",
			"lower left corner of the existing farm."
		}
	else
		for i = 1, 4 do
			blockType = T:getBlockType("forward")
			if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
				treePresent = true
				break
			end
			T:turnRight()
		end
		if not treePresent then
			return
			{
				"Unable to locate tree or sapling",
				"Plant a sapling on the lower left",
				"corner of the farm, or move me there"
			}
		end
	end
	if doContinue then -- facing tree. check if on front or l side of farm
		if extend == "forward" then
			T:go("R1F11") -- to other side of farm. may be stone or barrel/chest below
			blockType = T:getBlockType("down")
			if blockType:find(storage) ~= nil or blockType:find(storageBackup) ~= nil then
				doContinue = false
			end
		else
			T:go("R2F9") -- to right of farm, may be sapling/tree in front
			blockType = T:getBlockType("forward")
			if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
				doContinue = false
			end
		end
		if doContinue then -- extend farm.
			createFarm(R, extend)
		else
			return
			{
				"This farm has already been extended",
				"Move me next to/front of the tree / sapling",
				"of the last extension in this direction."
			}
		end
	end
	return {"Modular crop farm extended"}
end

local function createFloorCeiling(R) -- 79 size integer 1 to 4
	--[[
	R.up = true for ceiling
	R.down = true for floor
	R.height = 0 for normal
	R.height combined with R.up/R.down used for remote access
	]]
	
	local useBlock = T:getSlotContains(1)
	local waterPresent = false
	
	if R.useBlockType ~= "" then
		useBlock = R.useBlockType
	end
	print("Using ".. useBlock)
	local direction = "down"
	if R.up then
		direction = "up"
	end
	if R.height > 0 then -- remote placing. go up/down R.height first
		R.silent = true
		local depth = 0
		if R.down then -- floor could be under water
			while turtle.down() do
				depth = depth + 1
			end
		elseif R.up then
			while turtle.up() do
				depth = depth + 1
				if depth > R.height + 3 then
					break
				end
			end
		end
		if not(R.height - depth <= 2 or depth - R.height <= 2) then
			T:up(depth)
			return {"Measured depth/height of "..depth.." > setting: "..R.height}
		end
		-- not returned so depth acceptable
	end
	-- check if block above/below
	local blockBelow = turtle.detectDown()
	local blockAbove = turtle.detectUp()
	if R.subChoice == 2 then -- New floor over existing
		-- if no block below, assume in correct position and continue
		-- else move up 1 and continue
		if blockBelow then T:up(1) end
	elseif R.subChoice == 4 then -- New ceiling under existing
		-- if no block above, assume in correct position and continue
		-- else move down 1 and continue
		if blockAbove then T:down(1) end
	end
	
	local evenWidth = false
	local evenHeight = false
	local loopWidth
	-- go(path, useTorch, torchInterval, leaveExisting)
	if R.width % 2 == 0 then
		evenWidth = true
		loopWidth = R.width / 2
	else
		loopWidth = math.ceil(R.width / 2)
	end
	if R.length % 2 == 0 then
		evenHeight = true
	end
	-- if R.width is even no, then complete the up/down run
	-- if R.width odd no then finish at top of up run and reverse
	for x = 1, loopWidth do
		-- Clear first column (up)
		local tAvailable = T:getStock(useBlock, -1)
		if tAvailable.total < R.length and not R.silent then
			return {"Insufficient resources to complete current row"}
		end
		for y = 1, R.length do
			local blockType = T:getBlockType("forward")
			if not waterPresent then
				if blockType:find("lava") ~= nil or blockType:find("water") ~= nil then
					waterPresent = true
				end
			end
			T:place(useBlock, -1, direction, false) -- leaveExisting = false
			if y < R.length then
				T:go("F1", false, 0, false)
			end
		end
		-- clear second column (down)
		if x < loopWidth or (x == loopWidth and evenWidth) then -- go down if on R.width 2,4,6,8 etc
			T:go("R1F1R1", false,0,false)
			tAvailable = T:getStock(useBlock, -1)
			if tAvailable.total < R.length and not R.silent then
				return {"Insufficient resources to complete current row"}
			end
			for y = 1, R.length do
				T:place(useBlock, -1, direction, false) -- leaveExisting = false
				if y < R.length then
					T:go("F1", false, 0, false)
				end
			end
			if x < loopWidth then 
				T:go("L1F1L1", false,0,false)
			else
				T:turnRight(1)
				T:forward(R.width - 1)
				T:turnRight(1)
			end
		else -- equals R.width but is 1,3,5,7 etc
			T:turnLeft(2) --turn round 180
			T:forward(R.length - 1)
			T:turnRight(1)
			T:forward(R.width - 1)
			T:turnRight(1)
		end
	end
	if waterPresent then
		return {"water or lava found"}
	end
	return {""}
end

local function createIceCanal(R) -- 55
	--[[
		R.subChoice = 
		1: move right into canal, build left towpath
		2: build left towpath
		3: build right towpath
		4: move left into canal, build right towpath
		5: build alternating ice road
		6: create 3 block high air gap / 2 over water
	]]
	local oTurn = "R"
	if R.side == "R" then
		oTurn = "L"
	end
	local lib = {}
	
	function lib.iceCanalTowpath(R)
		-- move forward placing slabs along the way. If existing water canal, ceiling will be raised by 1 block
		local torchInterval = 0
		local placeIce = true
		for i = 1, R.length do
			local addTorch = false
			if R.torchInterval > 0 then
				if i == 1 then addTorch = true end
				if torchInterval >= R.torchInterval then
					addTorch = true
					torchInterval = 0
				end
			end
			lib.iceCanalEdge(R, addTorch, i, placeIce)
			torchInterval = torchInterval + 1
			placeIce = not placeIce
		end
		T:go(oTurn.."1")
	end
	
	function lib.iceCanalEdge(R, addTorch, numBlocks, placeIce)
		-- starting position facing canal side
		local blockType = T:getBlockType("forward")			-- ? air / slab / trapdoor / other
		local isWater, isSource, isIce = T:isWater("down")	-- water / ice below
		if blockType:find("slab") == nil and blockType:find("trapdoor") == nil then -- add slab
			if addTorch then														-- check if torch needed
				-- T:place(blockType, damageNo, direction, leaveExisting, signText)
				if not T:place("stone", -1, "forward", false) then
					T:checkInventoryForItem({"stone"}, {math.ceil(R.length / R.torchInterval)}, true)
				end
				T:go("U1x1 U1F1")	 				-- water level to 2 above water level
				if T:getItemSlot("minecraft:torch", -1) > 0 then
					T:place("torch", -1, "down", false)
				end
				utils.goBack(1)
				if isSource then					-- no need to clear block below water level
					T:down(2)						-- back to above water level
				else								-- not source at water level
					T:go("U1x1 D3")					-- clear blocks above, down to above water level
					if not isIce then				-- break block below if NOT ice
						T:dig("down")
					end
				end
			else
				if not T:place("slab", -1, "forward", false) then
					T:checkInventoryForItem({"slab"}, {R.length - numBlocks}, true)
				end
				if not isSource then				-- NOT on water, so dig above
					T:go("U1x1 U1x1 U1x1 D3")
				end
				if not isIce and not isSource then
					T:dig("down")
				end
			end
			-- else	slab or trapdoor already on side
		end
		if R.data == "ice" and placeIce and not isIce then -- R.data = "ice", placeIce = true, not already ice present
			T:place("ice", -1, "down", true)
		end
		if numBlocks < R.length then
			T:go(oTurn.."1F1"..R.side.."1")
		end
	end
	
	function lib.iceCanalCentreLeft(length)
		-- use only for placing ice to convert a water canal
		--place ice on alternate blocks until length reached or run out of ice
		local placeIce = true
		for i = 1, length do
			if T:getBlockType("down"):find("ice") == nil then -- no ice below
				T:dig("down") -- remove any existing block
				if placeIce then
					if not T:place("ice", -1, "down", true) then -- out of ice
						break
					end
					if i == length - 1 then
						break
					end
				end
			else -- ice already below
				placeIce = true
			end
			if turtle.digUp() then
				T:go("U1x0D1")
			end
			T:forward(1)
			placeIce = not placeIce -- reverse action
		end
	end
	
	function lib.iceCanalCentreRight(length)
		-- dig up/down/forward to clear space
		for i = 1, length + 1 do
			if turtle.digUp() then
				T:go("U1x0D1")
			end
			if i < length + 1 then
				T:go("x2F1")
			else
				T:dig("down")
			end
		end
	end
	
	function lib.initialise(R)
		if R.subChoice == 1 or R.subChoice == 4 then		
			local blockType = T:getBlockType("down")		-- ? at ground/water level or on top of existing slab/trapdoor
			if blockType:find("slab") ~= nil or blockType:find("trapdoor") ~= nil then -- slab/trapdoor already present
				T:go(oTurn.."1F1D1"..R.side.."2")			-- move right/left forward, down onto ice canal top, face canal wall
			elseif blockType:find("torch") ~= nil then
				T:go(oTurn.."1F1D2"..R.side.."2")			-- move right/left forward, down onto ice canal top, face canal wall
			else											-- assume on ground / water level
				T:go(oTurn.."1F1"..R.side.."2")				-- move right/left forward onto ice canal top, face canal wall
			end
		else
			if T:isWater("forward") then -- user put turtle inside canal water
				T:up(1)
			end
			T:go(R.side.."1")								-- face canal wall
		end
	end
	
	if R.length == 0 then R.length = 1024 end

	if R.subChoice < 5 then					-- towpath 1,2,3,4
		lib.initialise(R)					-- reposition
		lib.iceCanalTowpath(R)				-- build towpath
	elseif R.subChoice == 5 then			-- assume placed on existing ice or initial ice position
		lib.iceCanalCentreLeft(R.length)	-- place ice
	elseif R.subChoice == 6 then			-- assume placed at top of ice / water level
		lib.iceCanalCentreRight(R.length)	-- clear 3 high area
	end
	
	return {}
end

local function createIceCanalBorder(R) -- 59
	--[[ Used to convert water canal to ice with trapdoor / slab margin on one side ]]
	-- position gained from setup left = 0, right = 1
	local lib = {}
	
	function lib.placeTrapdoor()
		if T:getBlockType("down"):find("trapdoor") == nil then
			T:place("trapdoor", -1, "down", false) -- add trapdoors to canal towpath and activate them
		end
		return false
	end
	
	function lib.placeSlab()
		if T:getBlockType("down"):find("slab") == nil then
			T:place("slab", -1, "down", false)
		end
		return true
	end
	
	function lib.placeTorch(torchBlocks, onWater)
		if T:getItemSlot("minecraft:torch", -1) > 0 then
			if torchBlocks == 8 and onWater then
				-- T:fillVoid(direction, tblPreferredBlock, leaveExisting)
				T:fillVoid("down", {}, false)
				T:up(1)
				T:place("minecraft:torch", -1, "down", false)
				T:go("F1D1")
				torchBlocks = 0
			elseif torchBlocks == 9 and not onWater then
				T:go("R2")
				T:place("minecraft:torch", -1, "forward", false)
				T:go("L2")
				torchBlocks = 0
			end
		end
		return torchBlocks
	end
	
	local A = "R"
	local B = "L"
	if R.subChoice == 1 then
		A = "L"
		B = "R"
	end
	-- check position. Should be facing down canal with wall on same side
	-- so wall will be detected on i = 4 (if present)
	local turns = 0
	--local wallFound = false
	local numBlocks = 0
	if R.length == 0 then
		R.length = 2048
	end
	local isWater, isSource, isIce = T:isWater("down")
	while not isWater and not isIce do
		if not turtle.down() then
			break
		end -- move to ground -- canal edge / slab / trapdoor
		isWater, isSource, isIce = T:isWater("down")
	end
	local onWater = false
	local torchBlocks = 8	-- force torch placed on first block
	-- check if slab / trapdoor below
	blockType = T:getBlockType("down")
	if blockType:find("slab") ~= nil then
		onWater = true
	elseif blockType:find("trapdoor") ~= nil then
		onWater = false
		torchBlocks = 9
	elseif blockType:find("slab") == nil and blockType:find("trapdoor") == nil then -- not on existing slab / trapdoor
		T:up(1)
		if turtle.detectUp() then -- ceiling present: tunnel
			torchBlocks = 9
		else
			onWater = true
		end
	end
	redstone.setOutput("bottom", true)
	-- add trapdoors to canal towpath and activate them
	for i = 1, R.length do
		if torchBlocks >= 8 then
			torchBlocks = lib.placeTorch(torchBlocks, onWater)
		end
		--T:go(A.."1x2")
		if turtle.detectUp() then -- ceiling present: inside tunnel
			T:go(A.."1x2")
			onWater = lib.placeTrapdoor()
			T:go(B.."1F1")
		else
			onWater = lib.placeSlab()
			T:forward(1)
		end
		--T:go(B.."1F1")
		numBlocks = numBlocks + 1
		torchBlocks = torchBlocks + 1
		if T:getItemSlot("trapdoor", -1) == 0 or T:getItemSlot("slab", -1) == 0 then
			print("Out of slabs / trapdoors")
			break
		end
	end
	return {numBlocks}
end

local function createLadder(R) -- 12
	-- createLadder(R.data ="bedrock", R.height = 70, R.depth = -48)
	-- go(path, useTorch, torchInterval, leaveExisting)
	-- place(blockType, damageNo, direction, leaveExisting)
	local lib = {}
	
	function lib.placeLadder(direction, ledge, i, height)
		-- 1 check both sides and behind
		local fluid = false
		local block = T:isWaterOrLava("forward", ledge)
		if block:find("water") ~= nil or block:find("lava") ~= nil then
			--[[ surround 2 block shaft with blocks ]]
			T:go("R1C1 R1C1 R1C1 R1F1 L1C1 R1C1 R1C1 R1C1F1 R2C1 x1")
		else
			--[[ no water/lava so prepare ladder site]]
			T:go("F1 L1C1 R1C1 R1C1 L1B1", false, 0, true)
		end
		if not T:place("ladder", -1, "forward", false) then
			T:checkInventoryForItem({"ladder"}, {height - i}, false)
		end
		-- 3 check if ledge, torch
		if ledge == 0 and i > 1 then -- place block above unless new ladder
			T:place("common", -1, direction, false) -- any common block
		elseif ledge == 1 then
			T:place("minecraft:torch", -1, direction, false)
		elseif ledge == 2 then
			ledge = -1
		end
		
		return ledge
	end
	
	local retValue = {}
	local ledge = 0
	local height = math.abs(R.depth - R.height) --height of ladder
	local blockType = T:getBlockType("forward")
	if R.up then -- create ladder from current level to height specified
		for i = 1, height do -- go up, place ladder as you go
			ledge = lib.placeLadder("down", ledge, i, height) -- ladder placed forward, stone ledge for torch placed down
			if i <  height then
				T:up(1)
				ledge = ledge + 1
			end
		end		
	else -- R.down = true: ladder towards bedrock		
		local success = true
		local numBlocks, errorMsg = 0, ""
		T:down(1)
		for i = 1, height do -- go down, place ladder as you go
			ledge = lib.placeLadder("up", ledge, i, heigt) -- ladder placed forward, stone torch placed up
			--success, blocksMoved, errorMsg, blockType = clsTurtle.down(self, steps, getBlockType)
			if i < height then
				success, numBlocks, errorMsg, blockType = T:down(1, true) -- true = return blockType
				ledge = ledge + 1
			end
			-- if looking for stronghold then check for stone_bricks 
			if blockType:find("stone_bricks") ~= nil then
				table.insert(retValue, "Stronghold discovered")
				break -- stop descent at stronghold
			end
		end
		-- if user requested shelter create chamber at this level
		if R.data == "chamber" then -- user has chosen to build a chamber
			table.insert(retValue, "Shelter constucted at level".. R.depth)
			if blockType:find("bedrock") ~= nil then
				T:findBedrockTop(0) -- test to check if on safe level immediately above tallest bedrock
			end
			-- In shaft, facing start direction, on lowest safe level
			-- create a square space round shaft base, end facing original shaft, 1 space back
			T:go("L1n1 R1n3 R1n2 R1n3 R1n1", false, 0, true)
			T:go("U1Q1 R1Q3 R1Q2 R1Q3 R1Q1 R1D1", false, 0, true)
		end
	end
	
	return retValue
end

local function createLadderToWater(R) -- 86
	-- go down to water/lava with alternaate solid/open layers
	-- create a working area at the base
	-- Return to surface facing towards player placing ladders
	local inAir = true
	local numBlocks, errorMsg = 0, ""
	local height = 2
	local blockType = T:getBlockType("down")
	if blockType ~= "" then -- not over air
		T:forward(1)
	end
	T:go("R2D1") -- face player, go down 2
	while inAir do --success = false when hits water/lava
		blockType = T:isWaterOrLava("down")
		if blockType:find("water") ~= nil or blockType:find("lava") ~= nil then
			inAir = false
		end
		T:go("C1R1 C1R2 C1R1", false, 0, false)	-- surround front  and sides with cobble
		if inAir then
			T:down(1)
			height = height + 1
		end
		T:place("ladder", 0, "up")
	end
	-- In shaft, facing opposite start direction, on water/lava, ladders above
	T:go("C2", false, 0, false)
	utils.goBack(1)
	T:place("ladder", 0, "forward")
	T:up(3)
	height = height - 3
	for i = 1, height do
		if i < height then
			T:go("C2U1", false, 0, false)
		else
			T:go("C2", false, 0, false)
		end
	end

	return {}
end

local function createMine() -- 11
	-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	T:clear()	
	T:go("m32U1R2M16", true, 8, true) -- mine ground level, go up, reverse and mine ceiling to mid-point
	T:go("U2D2") -- create space for chest
	T:place("minecraft:chest", -1, "up", false)
	T:emptyTrash("up")
	T:go("D1R1m16U1R2M16", true, 8, true) -- mine floor/ceiling of right side branch
	T:emptyTrash("up")
	T:go("D1m16U1R2M16", true, 8, true) -- mine floor/ceiling of left side branch
	T:emptyTrash("up")
	T:go("L1M15F1R1D1", true, 8, true) -- mine ceiling of entry corridor, turn right
	T:go("F1x0 F1x0 n14 R1n32 R1n32 R1n32 R1n14 F1x0 F1U1", true, 8, true)-- mine floor of 36 x 36 square corridor
	T:go("R1F16R2") --return to centre
	T:emptyTrash("up")
	T:go("F16R1") --return to entry shaft
	T:go("F2Q14R1Q32R1Q32R1Q32R1Q14F2R1", true, 8, true) --mine ceiling of 36x36 square corridor. return to entry shaft + 1
	T:go("F16R2") --return to centre
	T:emptyTrash("up")
	-- get rid of any remaining torches
	while T:getItemSlot("minecraft:torch", -1) > 0 do
		turtle.select(T:getItemSlot("minecraft:torch", -1))
		turtle.dropUp()
	end
	T:go("F16R1F1R1") --return to shaft + 1
	for i = 1, 8 do
		T:go("N32L1F1L1", true, 8, true)
		T:go("N16L1F"..(i * 2).."R2", true, 8, true)
		T:emptyTrash("up")
		if i < 8 then
			T:go("F"..(i * 2).."L1N16R1F1R1", true, 8, true)
		else
			T:go("F"..(i * 2).."L1N16L1", true, 8, true)
		end
	end
	T:go("F17L1") -- close gap in wall, return to ladder + 1
	for i = 1, 8 do
		T:go("N32R1F1R1", true, 8, true)
		T:go("N16R1F"..(i * 2).."R2", true, 8, true)
		T:emptyTrash("up")
		if i < 8 then
			T:go("F"..(i * 2).."R1N16L1F1L1", true, 8, true)
		else
			T:go("F"..(i * 2).."R1N16R1", true, 8, true)
		end
	end
	T:go("F16R1")
	T:clear()
	return{"Mining operation complete"}
end

local function createMobFarmCube(R, blaze) -- 61, 62
	--[[
	Part 1 / 3 Mob Spawner Farm
	blaze = true: blaze spawner in nether
	R.subChoice is set to:
	1 = on spawner
	2 = bottom left corner
	3 = top left corner
	4 = bottom right, corner
	5 = top right corner
	R.width / R.length set by player (external size)
	]]
	if blaze == nil then blaze = false end
	local continue = false
	if R.subChoice == 2 then continue = true end
	R.direction = "clock"		-- starting on right side
	if not blaze then
		print("R.width: "..tostring(R.width))
		R.width = R.width - 2		-- internal width
		R.length = R.length - 2		-- internal length
		
		if R.subChoice == 2 or R.subChoice == 3 then
			R.direction = "anticlock"
		end
	end
	-- R.subChoice == 2 allows for 2-part operation 1 = main cube, 2 = rails etc
	T:clear()
	print("Begin: blaze="..tostring(blaze).." continue="..tostring(continue))
	local lib = {}
	
	function lib.floorSection(length)
		for i = 1, length do		-- starts on top left corner
			T:go("C2")
			if i < length then
				T:forward(1)
			else
				T:go("R1F1")
			end
		end
	end
	
	function lib.wallSection()
		for i = 1, 4 do
			for j = 1, 11 do
				T:go("C0C2", false, 0, false)
				if j < 11 then
					T:forward(1)
					T:go("R2C1L2", false, 0, false)
				else
					T:turnRight(1)
				end
			end
		end
	end
	
	function lib.ceiling()
		-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		-- all outer walls complete, now for remaining 9x9 ceiling
		for i = 1, 9 do
			for j = 1, 9 do
				T:go("C0x2", false, 0, true)
				if j < 9 then
					T:forward(1)
				else
					if i%2 == 1 then -- odd numbers 1,3,5,7,9
						if i < 9 then
							T:go("R1F1R1C0x2", false, 0, true)
						end
					else
						T:go("L1F1L1C0x2", false, 0, true)
					end
				end
			end
		end
	end
	
	function lib.clearWall(length)
		for i = 1, 4 do
			for j = 1, length do 
				if j < length then
					T:go("x0x2F1")
				else
					T:go("x0x2R1")
				end
			end
		end
	end
	
	function lib.isSpawner()
		local found, position = false, ""
		
		local blockType = T:getBlockType("down")
		if blockType:find("spawner") ~= nil then
			position = "top"
			found = true
		end
		if position == "" then
			blockType = T:getBlockType("up")
			if blockType:find("spawner") ~= nil then
				position = "bottom"
				found = true
			end
		end
		if position == "" then
			blockType = T:getBlockType("forward")
			if blockType:find("spawner") ~= nil then
				position = "forward"
				found = true
			end
		end
		return found, position
	end
	
	function lib.placeFloor(width, length, blockType)
		-- T:place(blockType, damageNo, direction, leaveExisting, signText)
		for i = 1, width do				
			for j = 1, length do
				T:place(blockType, -1, "down", false)
				if j < length then
					T:forward(1)
				else
					if i%2 == 1 then -- odd numbers 1,3,5,7,9
						if i < width then
							T:go("R1F1R1", false, 0, true)
						end
					else
						T:go("L1F1L1", false, 0, true)
					end
				end
			end
		end
	end
	
	function lib.searchStrip(distance)
		--go forward until hit either a wall or a chest
		local blocks = 1
		print("Searching strip, distance = "..distance)
		while blocks < distance do
			if turtle.forward() then
				blocks = blocks + 1
			else
				print("Checking for chest")
				if lib.isChest("forward") then
					if turtle.forward() then
						blocks = blocks + 1
					end
				else
					break
				end
			end
		end
	end
	
	function lib.findChests(R)
		for i = 1, 4 do
			print("Searching wall "..i)
			if i == 1 or i == 3 then
				lib.searchStrip(R.width) 	-- find and empty chests along width
			else
				lib.searchStrip(R.length) 	-- find and empty chests along length
			end
			if R.direction == "clock" then
				T:turnRight(1)
			else
				T:turnLeft(1)
			end
		end

		-- checked all walls
		T:go("F".. math.floor(R.width / 2)) -- now at mid-dungeon, next to wall
		if T:getItemSlot("chest") > 0 then
			if R.direction == "clock" then
				T:turnLeft(1)
			else
				T:turnRight(1)
			end
			-- now at mid-dungeon, facing wall
			-- deposit chest outside the dungeon
			while turtle.back() do end -- backing spawner
			T:go("F6x0x1x2")
			-- place(self, blockType, damageNo, direction, leaveExisting, signText)
			T:place("chest", -1, "forward", false)
			-- empty out all except stone and slab
			T:emptyInventorySelection("forward", {"cobble", "tuff", "slab", "granite", "andesite", "diorite" }, {0,0,0,0,0,0})
			T:turnLeft(2)
			while turtle.forward() do end -- facing spawner
		else
			if R.direction == "clock" then
				T:turnRight(1)
			else
				T:turnLeft(1)
			end
		end -- now at mid-dungeon, facing spawner
	end
	
	function lib.enterDungeon(R)
		--[[ find and empty any chests, return to dungeon wall ]]
		print("Entering dungeon")
		local blockType = T:getBlockType("forward")
		if blockType == "" then -- nothing in front.Error
			return false, "No block in front: Check position."
		else -- attempt entry into dungeon wall
			if R.subChoice == 2 then 	-- bottom left
				T:go("R1F1L1U2F2R1")
			elseif R.subChoice == 3 then	-- top left
				T:go("R1F1L1D1F2R1")
			elseif R.subChoice == 4 then	-- bottom right
				T:go("L1F1L1U2F2L1")
			elseif R.subChoice == 5 then	-- top right
				T:go("L1F1L1D1F2L1")
			end
			while turtle.down() do end -- either on floor or chest
			if lib.isChest("down") then
				turtle.down()
			end
			print("Searching for chests")
			lib.findChests(R)	-- go round inside walls  emptying chests. Finish mid-wall
		end
		return true, ""-- success, message
	end
	
	function lib.isChest(direction)
		direction = direction or "forward"
		local found = false
		local blockType = T:getBlockType(direction)
		if blockType:find("chest") ~= nil then -- chest found. early stages so empty and break it
			print("Chest found")
			found = true
			while T:suck(direction) do end
			T:dig(direction, false) -- false prevents checking for chests
		end
		return found
	end
		
	function lib.findSpawner(blaze)
		local moves  = 0
		local quit = false
		-- assume turtle placed on centre of inside spawner wall in front of spawner
		-- or as close as possible in Nether
		print("Checking if next to spawner")
		local found, position = lib.isSpawner() -- true/false, top/bottom/nil
		if not found then -- move forward towards spawner
			print("Not close to spawner")
			while turtle.forward() and not quit do
				moves = moves + 1
				if moves > 16 then
					quit = true
				end
			end
			found, position = lib.isSpawner() -- true/false, top/bottom/nil
			if not found then
				if blaze then -- could be behind a wall
					print("Assuming blaze spawner behind a wall")
					T:forward(1)
					moves = moves + 1
					while turtle.forward() and not quit do 
						moves = moves + 1
						if moves > 16 then
							quit = true
						end
					end
					found, position = lib.isSpawner() -- true/false, top/bottom/nil
					if not found then
						T:go("R2F"..moves + 2 .."R2")
					end
				end
			end
		end
		
		return found, position
	end
	
	function lib.rail(move, isPowered, count)
		if move ~= "" then
			T:go(move)
		end
		for i = 1, count do
			if isPowered then
				if not T:place("minecraft:powered_rail", -1, "down", false) then
					T:place("minecraft:golden_rail", -1, "down", false)
				end
			else
				T:place("minecraft:rail", -1, "down", false)
			end
			if i < count then
				T:forward(1)
			end
		end
	end
	
	if not continue then -- new mob cube either dungeon or blaze
		-- clsTurtle.go(self, path, useTorch, torchInterval, leaveExisting, preferredBlock)
		-- determine spawner position level 4, move to top of spawner (level 6)
		print("Checking if already at spawner")
		local found, position = lib.isSpawner() -- already on spawner?
		print("result: found="..tostring(found)..", position="..position)
		
		if blaze then 
			if not found then -- away from spawner
				found, position = lib.findSpawner(blaze)
			end
		else -- go to bottom of dungeon and empty chests
			if not found then --outside dungeon
				local success, message = lib.enterDungeon(R)
				if not success then
					return {message}
				end
				found, position = lib.findSpawner(blaze) -- is spawner in front / above / below?
			end 
		end
		
		if found then -- true: move to correct starting position
			--[[
			1 |c|c|c|c|c|c|c|c|c|c|c|
			2 |w| | | | | | | | | |w|
			3 |w| | | | | | | | | |w|
			4 |w| | | | | | | | | |w|
			5 |w| | | | | | | | | |w|
			6 |w| | | | |s| | | | |w|
			7 |w| | | | | | | | | |w|
			8 |w| | | | | | | | | |w|
			9 |w| | | | | | | | | |w|
		   10 |w| | | | | | | | | |w| exit level for overworld
		   11 |f|f|f|f|f|f|f|f|f|f|f|
		   12 |f|f|f|f|f|f|f|f|f|f|f| sub floor for overworld
			   1 2 3 4 5 6 7 8 9 1 1
			                     0 1
			]]
			-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
			if position == "bottom" then
				T:go("B1U2F1")
			elseif position == "forward" then
				T:go("U1F1")
			end
			
			T:up(1)
			T:place("slab", -1, "down", true) 				-- place slab on top T:place(blockType, damageNo, direction, leaveExisting)
			-- go up 2 blocks, forward 5, right, forward 5, right
			T:go("U2F5R1F5R1") 								-- Level 2: now placed 1 below ceiling inside wall, top right corner of new dungeon
			lib.wallSection() 								-- fix layers 1, 2, 3 including ceiling margin turtle at Level 2
			--T:go("F1R1 F1R2 C1R1", false, 0, false) 		-- exit wall, repair behind, still Level 2: fix ceiling
			T:go("F1R2 C1L1 F1R2 C1R1", false, 0, false)	-- exit wall, repair behind, still Level 2: fix ceiling
			lib.ceiling()									-- end opposite corner to start
			T:go("R2D3")									-- clear the inner walls inside original dungeon
			lib.clearWall(9)								-- clear the 9 x 9 area around the spawner
			T:go("F1R1F1L1")
			lib.clearWall(7)								-- clear the 7 x 7 area around the spawner
			T:go("F1R1F1L1")
			lib.clearWall(5)								-- clear the 5 x 5 area around the spawner. Also needed for cave spiders
			T:go("R2F1R1F1R1")
			T:go("F7R1 F8L1F1R2", false, 0, false)			-- return from ceiling, enter wall below previous section: Level 5
			lib.wallSection() 								-- deal with areas from spawner level up (4,5,6). walls only
			--T:go("F1R1F1R2C1R1D3", false, 0, false) 	-- exit wall, repair behind, embed 1 below original floor: Level 8
			T:go("F1R2 C1L1 F1R2 C1R1 D3", false, 0, false) -- exit wall, repair behind, embed 1 below original floor: Level 8
			clearRectangle({width = 9, length = 9, up = true, down = true}) -- clear levels 7,8,9
			T:go("L1F1 L1F1L2", false, 0, false) 			-- ready for next wall section
			if blaze then
				T:go("F1R1 F1L1 D3", false, 0, false) 		-- exit wall, move in ready for floor: Level 11
			else
				lib.wallSection() 						-- deal with walls on levels 7,8,9
				T:go("F1R2 C1L1 F1R2 C1R1 D3", false, 0, false) 	-- exit wall, repair behind, embed 4 below original floor: Level 11
			end
			--T:go("F1R1 F1R2C1 R1D3", false, 0, false) 	-- exit wall, repair behind, embed 4 below original floor: Level 11
			--print("Check: about to clear 3 floors 3 below spawner")
			--read()
			clearRectangle({width = 9, length = 9, up = true, down = true}) -- clear levels 10,11,12 
			T:go("L1F1L1F1L2", false, 0, false) -- ready for next wall section
			--print("Check: level 11, 5 north, 5 east")
			--read()
			if blaze then		-- blaze has rails placed on floor, second floor on top so walls not required
				clearPerimeter({width = 11, length = 11, up = true, down = true})
				T:go("F1R1F1L1U1", false, 0, false) -- exit wall, Level 10, facing entry point top right corner
				-- start in top right corner. border is made of slabs placed up
				-- fill in floor 9x9 rectangle below	
				lib.placeFloor(9, 9, "brick") -- ends facing wall on entrance side
				-- move to starting point in front of spawner,
				-- outside retaining wall, facing in, and ask for supplies
				T:go("L1F4 R1U4 F2R2")
				continue = true -- script continues below for blaze farm
			else	-- not blaze
				lib.wallSection() 	-- wall on layers 10,11,12
				T:go("F1R1F1R2C1R1U1", false, 0, false) -- exit wall, repair behind: Level 10, facing entry point top right corner
				T:down(1)
				lib.placeFloor(9, 9, "stone") -- ends facing wall on entrance side
				T:go("U1R2")
				lib.placeFloor(9, 9, "stone") -- ends facing wall on opposite side
				-- return to mid-point front
				T:go("R2F8 R1F4 L1F2")	-- exit at bottom of dungeon
				T:go("x1U1x1U1x1U1x1D3R2") -- rise to chest, then return ready for next stage
			end
		else
			return
			{
				"Spawner not found. Place me on top,",
				"immediately below, or facing it.",
				"\nEnter to quit"
			}
		end
	end
	if continue then
		T:clear()
		if R.data ~= "restart" then -- this function has NOT been stopped and restarted
			local text =
[[~yellow~Turtle is now ready to build the
killzone. Items required:

~lightGray~stone           512     slabs  36
~orange~powered rail    7       ~yellow~rail   64
~gray~hopper minecart 1       button 1
~red~redstone torch  2

~red~WARNING ~yellow~Inventory will be emptied
of some items if build is continued

~white~Enter for next menu
]]
			menu.colourText(nil, text, true)
			read()
			pp.itemColours = {colors.red, colors.lime}
			local choice = menu.new("Choose your option", {"Continue with build", "Re-start later"}, pp, "Type number + Enter") -- 1 = continue, 2= quit
			if choice == 2 then
				return {"Blaze spawner partial build halted"}
			end
			T:sortInventory()
			T:turnRight(2)
			T:emptyTrashItem("forward", "minecraft:netherrack", 0)
			T:emptyTrashItem("forward", brick, 0)
			T:emptyTrashItem("forward", "fence", 0)
			T:turnRight(2)
		end
		
		--clsTurtle.getItemSlot(self, item, useDamage): return slotData.lastSlot, slotData.leastModifier, total, slotData
		T:checkInventoryForItem({"stone"}, {512})
		T:checkInventoryForItem({"slab"}, {36})
		T:checkInventoryForItem({"minecraft:powered_rail", "minecraft:golden_rail"}, {8, 8})
		T:checkInventoryForItem({"minecraft:rail"}, {64})
		T:checkInventoryForItem({"minecraft:redstone_torch"}, {2})
		T:checkInventoryForItem({"minecraft:hopper_minecart"}, {1})
		T:checkInventoryForItem({"minecraft:stone_button"}, {1})
		print("Stand clear. Starting in 2 secs")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		-- return to starting point. rail laid first, bricks placed over rails
		T:go("F2 L2C1 R1 D3F4 R1")
		lib.rail("", true, 2) 			-- lay 2 plain rail at start first is later removed but keeps rails in line
		lib.rail("F1", false, 1) 		-- lay 1 plain rail
		lib.rail("F1", true, 3) 		-- lay 3 powered rail
		T:go("L1F1 D1C2 U1")
		T:place("minecraft:redstone_torch", -1, "down", false) --place redstone torch
		lib.rail("R2F1L1F1", false, 3)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 7)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 9)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 7)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 5) 	-- final strip
		lib.rail("F1", true, 3)			-- lay 3 powered rail
		T:go("F1C2 R1F1 R1F1 D1C2 U1")
		T:place("minecraft:redstone_torch", -1, "down", false)
		T:go("R2F1L1F1L1U1")
		-- lay floor 9 x 9 rectangle filling below
		for i = 2, 10 do -- repeat 9x
			T:go("m8", false, 0, false, brick)
			if i < 10 then
				if i % 2 == 0 then
					T:go("R1F1R1", false, 0, false, brick)
				else
					T:go("L1F1L1", false, 0, false, brick)
				end
			end
		end
		-- replace first rail with cobble and button
		T:go("R1F1R2D2x1C1B1", false, 0, false)
		T:place("minecraft:stone_button", -1, "forward", false)
		T:go("U2F2L1F1x2")
		T:place("minecraft:hopper_minecart", -1, "down", false)
		T:go("L1F1D1R2C1", false, 0, false, brick) -- cover minecart
		T:go("U1R1F2L1C0F1",false, 0, false)
		-- place slabs
		for j = 1, 4 do
			for i = 1, 9 do
				T:place("slab", -1, "up", false)
				T:forward(1)
			end
			if j < 4 then
				T:go("L1C0F1")
			end
		end
		T:go("L1F1L2") -- get in position
		-- build outer edge
		for j = 1, 4 do
			for i = 1, 9 do
				turtle.back()
				T:place("stone", -1, "forward", false)
			end
			if j < 4 then
				T:turnLeft(1)
				turtle.back()
				T:place("stone", -1, "forward", false)
			end
		end
		T:go("L1F1R2C1L1U1")
		for j = 1, 4 do
			for i = 1, 11 do
				T:go("C0x2F1")
			end
			T:go("C0x2R1F1")
		end
		T:go("R2F2 R1F1 R1")
		T:go("R2C1 R2Q14 R1Q14 R1Q14 R1Q13 R1D1", false, 0, false)
		T:go("L1F1R1")
		T:go("R2C1R2n14 R1n14 R1n14 R1n13 R1", false, 0, false)	-- now facing in on top of outer walkway
		
		T:go("F1D1C2 R1F1L1") 	-- move next to brick floor, 1 block above
		T:go("C2F1 C2F3")		-- miss out button, minecart
		T:go("C2F1 C2F1 C2F2")	-- miss out left redstone torch
		lib.floorSection(4)
		lib.floorSection(10)
		T:go("C2F2")			-- miss out right redstone torch
		lib.floorSection(8)

		for i = 1, 10 do
			T:go("C2")
			if i < 10 then
				T:forward(1)
			end
		end
		T:go("F1R1")		-- finished inner square, move onto final path

		lib.floorSection(12)
		lib.floorSection(12)
		lib.floorSection(12)
		for i = 1, 12 do
			T:go("C2")
			if i < 12 then
				T:forward(1)
			end
		end
		--T:go("U1L1 F1L1 C1U1x0 F1C1U1x0 F1C1U1x0 F1C2 F1C2 F1C2 F1C2 U1L1F1") -- back at original entrance
		T:go("U1L1 F1L1 F6U1C2 U1x1 L1F1") -- back at original entrance
	end
	return {}
end

local function floodMobFarm(R) -- 63
	--[[Part 2 / 3 Mob Spawner Farm turtle on floor, pointing towards water source wall]]
	local lib ={}
	
	function lib.setPosition(addWater)
		local width = 0
		while turtle.forward() do end					-- move forward until hit wall
		T:go("U1L1")
		while turtle.forward() do end					-- move forward until hit left wall
		if addWater then
			T:place("water", -1, "down", true) 			-- place water down
		end
		T:turnLeft(2)									-- turn round
		while turtle.forward() do
			width = width + 1 
		end			-- go forward 7
		if addWater then								-- back 1
			T:place("water", -1, "down", true) 			-- place water					
		end
		T:go("L2F".. math.floor(width / 2) .."L1")	-- turn round, go forward 3 (centre of wall), turn left
	end

	function lib.digFloor()
		T:go("x2F1 x2")									-- first block, move forward
		
		T:turnLeft(1)									-- left turn, go back into right side, facing left
		utils.goBack(1)
		T:go("x2 F1x2 F1x2 R1F1")						-- go right to left dig 3 blocks, forward on left side
		
		T:turnRight(1)									-- right turn, go back into left side, facing right
		utils.goBack(1)
		T:go("x2 F1x2 F1x2 F1x2 F1x2 L1F1")				-- go left to right dig 5 blocks, forward on right side
		
		T:turnLeft(1)									-- left turn, go back into right side, facing left
		utils.goBack(1)
		T:go("x2 F1x2 F1x2 F1x2 F1x2 F1x2 F1x2 R1F1")	-- go right to left dig 7 blocks, forward on left side
		
		T:turnRight(1)									-- right turn, go back into left side, facing right
		utils.goBack(1)
		T:go("x2 F1x2 F1x2 F1x2 F1x2 F1x2  F1x2  F1x2  F1x2 L1")	-- go left to right dig 5 blocks, face forward on right side
	end
	
	lib.setPosition(false)					-- move to back of cube and verify position
	if R.subChoice == 1 then
		T:forward(3)						-- forward 4 (centre of chamber)
	else
		T:forward(2)						-- forward 3
	end
	T:down(1)
	lib.digFloor()
	if R.subChoice == 1 then		
		T:go("D1F1 L1F8")
		utils.goBack(4)
		T:go("L1U1")
		lib.setPosition(true)				-- place water sources
		T:go("F8D2")
		-- go down 2, check floor, up 1, place fence
		T:go("D2C2U1", false, 0, true)
		T:place("fence", -1, "down", false)
		T:go("F1D1C2U1", false, 0, true)
		T:place("fence", -1, "down", false)
		T:go("F1U1R2", false, 0, true)
		T:go("F1R1U1")
		T:place("sign", -1, "down", false)
		T:go("U1C0D1")
		T:place("slab", -1, "up", false)
		T:go("R2F1R2")
		T:place("sign", -1, "forward", false)
		T:go("R1F1R2C1R1F1D1L1") --sitting on soul sand/dirt facing spawner
		if not T:place("minecraft:soul_sand", -1, "down", false) then
			T:place("minecraft:dirt", -1, "down", false)
		end
	else
		T:go("D1F1 L1F8")
		T:go("R1F1 R1F8")
		utils.goBack(4)
		T:go("R1U1")
		lib.setPosition(true)		-- place water sources
		T:go("F8D2F1C2F1")
	end
	
	return {}
end

local function createMobBubbleLift(R) -- 64
	-- Part 3 / 3 Mob Spawner Farm
	-- R.subChoice = 1 or 2 (left/right)
	local lib = {}
		
	function lib.down()
		local moves = 0
		while turtle.down() do
			moves = moves + 1
		end
		return moves
	end
	
	function lib.up()
		local moves = 0
		while turtle.up() do
			moves = moves + 1
		end
		return moves
	end
	-- check if dirt or soulsand below
	local turn = "R"
	if R.subChoice == 1 then
		turn = "L"
	end
	local blockType = T:getBlockType("down")
	if blockType ~= "minecraft:soul_sand" then
		T:dig("down")
		if not T:place("minecraft:soul_sand", -1, "down", false) then
			return {"Unable to find or place soulsand."}
		end
	end
	-- check facing sign, rotate if not
	blockType = T:getBlockType("forward")
	local turns = 0
	while blockType:find("sign") == nil do
		T:turnRight(1)
		turns = turns + 1
		if turns == 4 then
			return {"Unable to find sign."}
		end
		blockType = T:getBlockType("forward")
	end
	for i = 1, 3 do
		-- fill in back and one side, go up
		if turn == "R" then
			T:go("R1C1R1C1R1x1R1U1", false, 0, true)
		else
			T:go("L1C1L1C1L1x1L1U1", false, 0, true)
		end
	end
	for i = 1, 17 do
		-- tunnel up, filling 3 sides
		if turn == "R" then
			T:go("R1C1R1C1R1x1R1C1U1", false, 0, true)
		else
			T:go("L1C1L1C1L1x1L1C1U1", false, 0, true)
		end
	end
	-- move either left/right 8 blocks, repairing ceiling and sides
	if turn == "R" then
		T:go("C0R2C1R1F1C0C1R1C1R2C1L1F1A8", false, 0, true) -- fill top of column
	else
		T:go("C0L2C1L1F1C0C1L1C1L2C1R1F1A8", false, 0, true) -- fill top of column
	end
	-- turn round, go down 1, forward 7 blocks repairing bottom and sides
	T:go("D1C1R2X7", false, 0, true)
	-- turn round, go up, place cobble, forward 4, place cobble
	T:go("R2U1C2F4C2", false, 0, true)
	-- turn round forward 1 place water, forward 2, place water
	T:go("R2F1", false, 0, true)
	T:place("minecraft:water_bucket", -1, "down", false)
	T:forward(2)
	T:place("minecraft:water_bucket", -1, "down", false)
	T:go("R2F1")
	repeat
		-- refill both buckets
		T:place("minecraft:bucket", -1, "down", false)
		sleep(0.5)
		T:place("minecraft:bucket", -1, "down", false)
		-- back 4, down to solid, place water,
		for i = 1, 4 do
			turtle.back()
		end
		local moves = lib.down() -- returns no of blocks descent 0 to 19
		if moves > 0 then
			T:place("minecraft:water_bucket", -1, "forward", false)
			T:go("U1C2")
			if moves > 1 then
				T:place("minecraft:water_bucket", -1, "forward", false)
				T:go("U1C2")
			end
		end
		lib.up() -- 0 - 19
		T:forward(4)
	until moves <= 1
	-- delete water sources and remove cobble
	T:go("R2F3C1R2F1")
	for i = 1, 7 do -- go to end of run placing cobble
		T:go("C2F1")
	end
	T:turnRight(2)
	for i = 1, 7 do -- go to end of run, down 2
		T:go("x2F1x2")
	end
	T:go("R2F7D2")
	for i = 1, 18 do
		-- tunnel down, filling all 4 sides
		T:go("R1C1R1C1R1C1R1C1D1", false, 0, true)
	end
	-- block below, turn round, tunnel forward 6 blocks
	T:go("C2R2U1")
	for i = 1, 6 do
		T:go("R1C1L2C1R1")
		if i < 6 then
			T:forward(1)
		end
	end
	T:go("R2D1") -- drop down return to far wall
	for i = 1, 6 do	-- leave opening for player attack
		if turn == "R" then
			T:go("L1C1R2x1L1")
		else
			T:go("R1C1L2x1R1")
		end
		if i < 6 then
			T:forward(1)
		end
	end
	T:go("R2F1 D1C2 R1C1 L2C1 R1U1")
	T:place("water", -1, "down")
	T:go("F1D1")
	for i = 1, 5 do
		T:go("C2R1C1L2C1R1")
		if i < 5 then
			T:forward(1)
		end
	end
	if turn == "R" then
		T:go("L1F1C2F1C2U1R1")
	else
		T:go("R1F1C2F1C2U1L1")
	end
	return {}
end

local function createPlatform(R) -- 56
	-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	local forward = true
	for w = 1, R.width do
		for l = 1, R.length do
			T:go("x2C2", false, 0, false, R.useBlockType)
			if R.up then
				T:dig("up")
			end
			if l < R.length then
				T:forward(1)
			end
		end
		if w < R.width then
			if forward then
				if R.up then
					T:go("R1F1 x0R1")
				else
					T:go("R1F1 R1")
				end
			else
				if R.up then
					T:go("L1F1 x0L1")
				else
					T:go("L1F1 L1")
				end
			end
		end
		forward = not forward
	end
	return {}
end

local function createPortal(R) -- 42
	--[[
	R.length = length of portal NOT width default 4
	R.height = height of portal default 5
	R.width = thickness of portal default 1
	R.data = "bury" to embed bottom into ground
	R.subChoice 1 = facing portal, 2 = aligned
	]]
	local lib = {}
	
	function lib.buildBase()
		--T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		T:go("C2", false, 0, false, R.useBlockType)
		T:forward(1)
		for i = 1, R.length - 2 do -- R.length = 4: place when i=1,2
			T:place("minecraft:obsidian", 0, "down", false)
			T:forward(1)
		end
		T:go("C2", false, 0, false, R.useBlockType)
	end
	
	function lib.buildLayer()
		T:place("minecraft:obsidian", 0, "down", false)
		for i = 1, R.length - 1 do -- R.length = 4: forward when i=1,2,3
			T:forward(1)
		end
		T:place("minecraft:obsidian", 0, "down", false)
	end
	
	if R.data ~= "bury" then
		T:up(1)
	end
	if R.subChoice == 1 then
		T:go("F1R1")
	end
	local out = true
	for width = 1, R.width do
		lib.buildBase()
		for i = 1, R.height - 1 do
			T:go("R2U1")
			out = not out
			lib.buildLayer()
		end
		T:go("R2U1")
		out = not out
		lib.buildBase()
		if out then
			T:go("R2F"..R.length - 1)
		end
		if width < R.width then
			T:go("R1F1D"..R.height.."R1")
			out = true
		else
			T:go("L1F"..R.width.."D"..R.height.."R2")
		end
	end
	
	return {}
end

local function createPortalPlatform() -- 48
	--[[ Used in End World to use a trapdoor to push player through portal ]]
	local lib ={}
	
	function lib.findPortal()
		local found = false
		local onSide = false
		for i = 1, 64 do
			if not turtle.up() then -- hit block above
				found = true
				break
			end
		end
		if found then
			-- are we under the centre block, or one of the sides?
			if turtle.detect() then -- under a side
				onSide = true
			else	-- nothing in front, probably under centre, or facing wrong direction so check
				for i = 1, 4 do
					turtle.turnRight()
					if turtle.detect() then
						onSide = true
						break
					end
				end
			end
			if onSide then-- move to centre
				T:go("D1F1")
			end
		end
		local height = 3 -- allows for 2 bedrock + starting space
		while turtle.down() do
			height = height + 1
		end
		return found, height
	end
	
	function lib.addFloor(length)
		for i = 1, length do
			if i < length then
				T:go("C2F1", false, 0, true)
			else
				T:go("C2", false, 0, true)
			end
		end
	end
	
	function lib.buildLadder(height)
		for i = 1, height do
			--T:go("F1C1 R1C1 L2C1 L1F1L2", false, 0, true)
			T:go("F1C1 R1C1 L2C1 R1", false, 0, true)
			utils.goBack(1)
			if i > 3 then
				T:go("C2")
			end
			T:place("minecraft:ladder", 0, "forward", true)
			T:up(1)
		end
	end
	
	local found, height = lib.findPortal()
	if found then	-- position under centre of beacon
		-- build ladder up and create platform
		T:go("L1F1L1F2L2")
		T:checkInventoryForItem({"minecraft:ladder"},{height})
		T:checkInventoryForItem({"stone"},{height * 4 + 18})
		T:checkInventoryForItem({"trapdoor"},{1})
		lib.buildLadder(height) -- ends facing ladder, 1 block above
		
		T:go("R1")
		utils.goBack(1)
		T:go("C2F1 C2F1 C2F1 C2")
		T:go("R1F1R1")
		T:go("C2F1 C2F1 C2F1 C2")
		utils.goBack(2)
		T:go("R1F1")			-- facing portal entrance
		T:place("trapdoor", -1, "up", false)
	else
		return {"Portal not found. Move me under","the centre if possible.", "wait for purple beacon."}
	end
	return {}
end

local function createRailway(R) -- 93
	-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	if R.down then
		if R.height == 0 then
			local blockType = ""
			while blockType == "" do
				T:go("F1D1", false, 0, true)
				blockType = T:getBlockType("down")
				if blockType == "" then
					T:go("C2", false, 0, true)
				end
			end
		else
			for i = 1, R.height - 1 do
				T:go("F1D1C2", false, 0, false)
			end
		end
	elseif R.up then
		for i = 1, R.height do
			T:go("C1U1F1", false, 0, false)
		end
	end
	return {}
end

local function createRectanglePath(R) -- 710, 83 direct commands
	-- allow user to control length / width of each path
	-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	--local pp = utils.getPrettyPrint()
	local lib = {}
	
	function lib.forward(R)
		if R.subChoice == 1 then
			for i = 1, R.length do
				T:go("F1x0C2", false, 0, true)
			end
		else
			for i = 1, R.length do
				T:go("F1U1C0D1C2", false, 0, true)
			end
		end
	end
	
	function lib.back(R)
		for i = 1, R.length do
			turtle.back()
		end
	end
	
	function lib.left(R)
		T:turnLeft(R.length)
	end
	
	function lib.right(R)
		T:turnRight(R.length)
	end
	
	function lib.up(R)
		if R.subChoice == 1 then
			T:go("U2R2 x1R2 D1C2", false, 0, true)
		else
			T:go("U2R2 x1R2C0 D1C2", false, 0, true)
		end
	end
	
	function lib.down()
		T:go("D1C2", false, 0, true)
	end
	
	if R.data == "menu" then
		-- mimics direct commands using f.lua, r.lua etc with space between commands and number
		local width = 0
		local length = 0
		local choices =
		{
			"Forward 1 block",
			"Forward # blocks",
			"Back 1 block",
			"Back # blocks",
			"Turn Right",
			"Turn Left",
			"Up 1 block",
			"Down 1 block",
			"Quit"
		}
		local choice, modifier
		pp.itemColours = {colors.lime, colors.lime, colors.green, colors.green, colors.orange, colors.orange, colors.cyan, colors.cyan, colors.gray}
		while choice ~= 9 do
			choice, modifier = menu.menu("Choose next step", choices, pp, "Type number + Enter ")
			if choice == 1 then
				R.length = 1
				lib.forward(R)
			elseif choice == 2 then
				-- getInteger(prompt, minValue, maxValue, row, fg, bg, default) 
				R.length = menu.getInteger("Move forward how many blocks?", 1, 250, nil, colors.lime)
				lib.forward(R)
			elseif choice == 3 then
				R.length = 1
				lib.back(R)
			elseif choice == 4 then
				R.length = menu.getInteger("Move back how many blocks?", 1, 250, nil, colors.green)
				lib.back(R)
			elseif choice == 5 then
				R.length = 1
				lib.right(R)
			elseif choice == 6 then
				R.length = 1
				lib.left(R)
			elseif choice == 7 then
				lib.up(R)
			elseif choice == 8 then
				lib.down()
			end
		end
	else
		local instructions = 
[[~lightGray~Commands:

direction + ~blue~number ~yellow~eg ~white~f2 ~yellow~= forward ~blue~2
~lightGray~direction without number = ~blue~1

~yellow~f = forward  ~orange~b = backward
~lime~l = left     ~red~r = right
~lightGray~u = up       ~cyan~d = down

~red~q = quit

]] -- Direct control
		local cmd = ""
		while cmd ~= "q" do
			local line = menu.clear()
			line = menu.colourText(line, instructions)
			-- menu.getString(prompt, withTitle, minValue, maxValue, row, fg, bg, default) 
			input = menu.getString("command ", false, 1, 5, line, colors.yellow, colors.black):lower()
			-- remove spaces
			input = input:gsub( " ", "")
			cmd = input:sub(1,1)
			R.length = 1
			if #input > 1 then
				R.length = tonumber(input:sub(2))
			end
			if cmd == "q" then
				return{"User has quit application"}
			end
			if cmd == "f" then
				lib.forward(R)
			elseif cmd == "b" then
				lib.back(R)
			elseif cmd == "l" then
				lib.left(R)
			elseif cmd == "r" then
				lib.right(R)
			elseif cmd == "u" then
				lib.up(R)
			elseif cmd == "d" then
				lib.down()
			end
		end
	end
	return {}
end

local function createRetainingWall(R) -- 34, 82
	-- facing direction wall will take
	-- will need to rotate 180 to build
	-- if R.height > 0 then build to specified depth
	local lib = {}
		
	function lib.checkFloor()
		local newDepth = 0
		place = utils.clearVegetation("down") -- in case col in front is deeper
		while place do -- loop will be entered at least once
			T:down(1)
			newDepth = newDepth + 1
			place = utils.clearVegetation("down")
		end
		if newDepth > 0 then
			for j = 1, newDepth do	-- go up until column base is met
				T:go("U1C2")
			end
		end
	end
	
	function lib.patchMissingBlock()
		if turtle.back() then
			T:go("C1")
		else
			T:go("B1C1")
		end
	end
	
	function lib.placeSingle(height)
		local y = 0
		if height > 0 then
			T:go("D"..height)
			y = height
		else
			local place = utils.clearVegetation("down")
			while place do -- loop will be entered at least once
				place = utils.clearVegetation("down")
				if place then
					T:down(1)
					y = y + 1
				end
			end
		end
		-- return to surface, placing below
		for i = 1, y do
			T:go("U1C2", false, 0, true)
		end
	end
	
	function lib.placeDouble(height)
		--T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		local y = 0
		if not turtle.back() then
			T:go("B1")
		end
		if height > 0 then
			for i = 1, height do
				T:go("C1D1", false, 0, true)
			end
			T:go("C1", false, 0, true)
			y = height
		else
			local place = utils.clearVegetation("down")
			-- build back column
			while place do -- loop will be entered at least once
				place = utils.clearVegetation("down")
				if place then
					T:go("C1D1", false, 0, true)
					y = y + 1
				end
			end
			-- reached bottom. floor in front could drop down
			T:go("F1") -- move under first column
			lib.checkFloor()
			turtle.back() -- back at starting point
			T:go("C1", false, 0, true) 
		end
		-- return to surface, placing below
		for i = 1, y do
			T:go("U1C2", false, 0, true)
		end
	end
		
	function lib.placeTriple(height)
		--T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		local y = 0
		if turtle.back() then
			T:go("C1")
		else
			T:go("B1C1")
		end
		if height > 0 then
			for i = 1, height do
				T:go("C1D1", false, 0, true)
			end
			for i = 1, height do
				T:go("C1D1", false, 0, true)
			end
			T:go("C1R2C1", false, 0, true) --fill last block, then turn 180 to build opposite side
			y = height
		else
			local place = utils.clearVegetation("down")
			-- build back column
			while place do -- loop will be entered at least once
				place = utils.clearVegetation("down")
				if place then
					T:go("C1D1", false, 0, true)
					y = y + 1
				end
			end
			-- reached bottom. floor in front could drop down
			T:go("F1") -- move under first column
			lib.checkFloor()
			T:go("B1C1R2F1", false, 0, true) 
			lib.checkFloor()
			T:go("B1C1")
			-- return to surface , placing below and to front
		end
		for i = 1, y do
			T:go("C1U1C2", false, 0, true)
		end
		T:go("F1R2C1", false, 0, true)
		-- facing back again inside edge of col 3
		return y -- depth of this run
	end
	
	local topInPlace = false -- topInPlace = true already a path across the water eg monument rectangle
	if R.data == "withPath" then
		topInPlace = true
	end
	local place = false
	local inWater = false
	local onWater = false
	if not topInPlace then
		if R.length > 1 then
			inWater, onWater = utils.getWaterStatus() -- returns whether above water, or immersed
		end
	end
	
	local maxDepth = 5 --initial estimated value
	-- start at surface, move back 1 block
	-- each iteration completes 3 columns
	local numBlocks = T:getSolidBlockCount()
	print("Solid blocks in inventory: "..numBlocks)
	
	if R.length == 1 then -- single column down to water bed
		lib.placeSingle(R.height)
	elseif R.length == 2 then--down then up: 2 cols
		inWater, onWater = utils.startWaterFunction(onWater, inWater, 2, true) -- move into water
		T:go("R2") -- move to face player
		lib.placeDouble(R.height)
		if not inWater then
			T:go("U1C2", false, 0, true)
		end
	else -- R.length 3 or more
		if topInPlace then
			T:down(1) -- break through top
		else
			inWater, onWater = utils.startWaterFunction(onWater, inWater, 2, true) -- move into water
		end
		T:go("R2") -- move to face player
		-- now at water surface
		local remain = R.length
		while remain >= 3 do
			numBlocks = T:getSolidBlockCount()
			print("Inventory blocks: "..numBlocks.." depth: "..maxDepth)
			if numBlocks < maxDepth * 3 then
				--ask player for more
				T:checkInventoryForItem({"stone"}, {maxDepth * remain}, false)
			end
			local y = lib.placeTriple(R.height) -- moves back, places col in front, centre and behind. R.height = 0 for auto depth
			if y > maxDepth then
				maxDepth = y
			end
			remain = remain - 3
			if remain > 1 then
				lib.patchMissingBlock()
			end
		end
		if remain == 1 then -- 1 more column
			lib.patchMissingBlock()
			lib.placeSingle(R.height)
		elseif remain == 2 then -- 2 cols
			lib.placeDouble(R.height)
		end
		T:go("U1C2") -- above surface
	end
	return {}
end

local function createSafeDrop(R) -- 14
	-- dig down height blocks, checking for blocks on all sides
	local drop = 0
	local isBedrock = false
	T:down(2)
	drop = 2
	for i = 1, R.height - 1 do
		for j = 1, 4 do
			-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
			T:go("C1R1", false, 0, true)
		end
		if T:down(1) then
			 drop = drop + 1
		else
			isBedrock = true
			break
		end
		if T:isWaterOrLava("up") ~= "" then
			T:go("C0x0", false, 0, false) -- delete water/ lava block
		end
	end
	if not isBedrock then -- not sitting on bedrock, so break foot level exit block
		T:go("U1R2x1")
	end
	T:place("minecraft:water_bucket", -1, "down", false)
	if isBedrock then
		T:go("U1x1 U1x1")
	else
		T:go("U1x1")
	end
	T:up(drop - 2)
	
	return {"Safe drop completed "..drop .. " blocks"}
end

local function createSlopingWater(R) -- 34, 89
	--[[
	creates a sloping water area above existing lake/river/ocean
	R.width is usually 7 with an existing wall on 8th row
	R.length  is user choice, limited to bucket/slab quantities
	Places slabs into existing surface, places row of sources
	Removes slabs
	]]
	local lib = {}
	
	function lib.fillBuckets()
		local emptyBuckets = utils.getEmptyBucketCount()
		for i = 1, emptyBuckets do
			if utils.fillBucket("down") then
				print("Bucket filled down")
				sleep(0.3)
			else
				print("Unable to fill bucket ".. i .." / "..emptyBuckets)
			end
		end
		return utils.getWaterBucketCount()
	end
	
	local outbound = true
	local inWater, onWater = utils.getWaterStatus()
	inWater, onWater = utils.startWaterFunction(onWater, inWater, 2 ,false) -- move above water, max descent 2
	local waterBuckets = lib.fillBuckets()
	for w = 1, R.width do
		for l = 1, R.length do
			T:place("slab", -1, "down", false)
			if l < R.length then
				T:forward(1)
			end
		end
		if w < R.width then
			if outbound then
				T:go("R1F1R1")
			else
				T:go("L1F1L1")
			end
			outbound = not outbound
		end
	end
	if outbound then
		T:go("L1F"..R.width - 1 .."L1")
	else
		T:go("R1F"..R.width - 1 .."R1")
	end
	T:place("water", -1, "up", true) -- place in corner
	local move = true
	while move do
		move = turtle.forward()
		move = turtle.forward() -- false if at end of run
		T:place("water", -1, "up", true) -- alternate positions + end of run
	end
	T:go("R2D1")
	T:sortInventory() -- get all buckets into 1 slot
	for w = 1, R.width do
		for l = 1, R.length do
			if l < R.length then
				T:forward(1)
			end
		end
		if w < R.width then
			if outbound then
				T:go("R1F1R1")
			else
				T:go("L1F1L1")
			end
			outbound = not outbound
		end
	end
	if outbound then
		T:go("L1F"..R.width - 1 .."L1")
	else
		T:go("R1F"..R.width - 1 .."R1")
	end
	T:go("U2")
	
	return {}
end

local function createSquidFarmBase(R) -- 34
	-- dig down to y=45. assume starting at water level (64)
	local depth = 0
	local message =
[[Place the turtle under the grid
left corner above current pit
opening.
It will descend to the base and
continue to level y=45.

Enter to continue...
]]
	read()
	while turtle.down()do
		depth = depth + 1
	end
	T:down(1)
	R.height = 21 - depth
	R.width = 15
	R.length = 15
	R.silent = true
	R.data = "down"
	clearSolid(R)
	T:up(depth + 4)
	return {}
end

local function createSandWall(R) -- 81
	local success = true
	--move above water
	local maxMove = 2
	while turtle.detectDown() and maxMove > 0 do
		T:forward(1)
		maxMove = maxMove - 1
	end
	if R.length > 0 then
		for i = 1, R.length - 1 do
			success = utils.dropSand()
			T:forward(1, false)
		end
		success = utils.dropSand()
	else
		while not turtle.detectDown() do -- over water
			while not turtle.detectDown() do -- nested to allow forward movement
				success = utils.dropSand() -- drops sand and checks supplies
			end
			if success then
				T:forward(1, false)
			else -- out of sand
				break
			end
		end
	end
	return {}
end

local function createSinkingPlatform(R) -- 58
	local lib = {}
	
	function lib.stage1a(R)							-- build side wall left side
		for l = 1, R.length do 						--            | |*| |
			T:go("L1C1 R1C2", false, 0, false)		-- |*|>| | to |*|>| | place left wall
			if l == 1 then							-- first iteration
				T:go("U1C2 D1 F1C2", false, 0, false)-- |*|>| | to |*|*|>| up/down block to delete source at corner
			elseif l < R.length then				-- mid run
				T:go("F1C2", false, 0, false)		-- |*|>| | to |*|*|>| move forward
			else									-- end of run
				T:go("C1U1 C2D1", false, 0, false)	-- |*|>| | to |*|>|*| place end wall
			end
		end
	end
	
	function lib.stage1b(R)							-- same as stage1a on right side
		for l = 1, R.length do 
			T:go("R1C1 L1C2", false, 0, false)
			if l == 1 then
				T:go("U1C2 D1 F1C2", false, 0, false)
			elseif l < R.length then
				T:go("F1C2", false, 0, false)
			else
				T:go("C1U1 C2D1", false, 0, false)
			end
		end
	end
	
	function lib.stage2(forward)
		if forward then
			T:go("C1R1 F1L1 C1R2", false, 0, false)
		else
			T:go("C1L1 F1R1 C1L2", false, 0, false)
		end
	end
		
	local forward = true
	local goingRight = true
	local blockType = T:getBlockType("down")
	if blockType:find("water") ~= nil or blockType:find("lava") ~= nil then
		T:up(1)
	end
	for h = 1, R.height do						-- repeatedly create a platform, move down and repeat
		T:down(1) 								-- move down into existing platform
		if goingRight then 						-- first side
			if forward then						-- complete left side
				T:go("R2C1 L2", false, 0, false) -- | |>| | to |*|<| | to |*|>| | 
				lib.stage1a(R)					-- build left wall
				T:go("R1F1 L1C1 R2C2", false, 0, false)			-- turn ready for next side
			else
				T:go("L2C1 R2", false, 0, false) -- block 1, 1
				lib.stage1b(R)					-- turn ready for next side
				T:go("L1F1 R1C1 L2C2", false, 0, false)
			end
		else 									-- on right side so different approach
			if forward then
				T:go("L2C1 R2", false, 0, false) -- | |<| | to | |>|* | to | |<|*| 
				lib.stage1b(R)					
				T:go("C1L1 F1R1 C1L2 C2", false, 0, false)		-- turn ready for next side
			else								-- complete left side
				T:go("R2C1 L2", false, 0, false) -- block 1, 1
				lib.stage1a(R)					-- turn ready for next side
				T:go("C1R1 F1L1 C1R2 C2", false, 0, false)
			end
		end
		forward = not forward					-- continue strips across until at far edge
		for w = 1, R.width - 2 do
			for l = 1, R.length do
				if l < R.length then
					T:go("C2F1", false, 0, false)
				else
					T:go("C2", false, 0, false)
				end
			end
			if goingRight then
				lib.stage2(forward)
			else
				lib.stage2(not forward)
			end
			forward = not forward
		end										-- far side
		if goingRight then
			if forward then
				lib.stage1b(R)
			else
				lib.stage1a(R)
			end
		else
			if forward then
				lib.stage1a(R)
			else
				lib.stage1b(R)
			end
		end
		goingRight = not goingRight
		T:turnRight(2)
		forward = not forward
	end
	return {}
end

local function createStaircase(R) -- 13
	-- R# L# F# B# U# D# +0 -0 = Right, Left, Forward, Back, Up, Down, up while detect and return, down while not detect
	-- dig:			  x0,x1,x2 (up/fwd/down)
	-- suck:		  s0,s1,s2
	-- place chest:   H0,H1,H2 
	-- place sapling: S0,S1,S2
	-- place Torch:   T0,T1,T2
	-- place Hopper:  P0,P1,P2
	-- mine floor:	  m# = mine # blocks above and below, checking for valuable items below, and filling space with cobble or dirt
	-- mine ceiling:  M# = mine # blocks, checking for valuable items above, and filling space with cobble or dirt
	-- mine ceiling:  N# same as M but not mining block below unless valuable
	-- place:		  C,H,r,S,T,P,^ = Cobble / cHest / DIrT / Sapling / Torch / hoPper /stair in direction 0/1/2 (up/fwd/down) eg C2 = place cobble down
	
	-- 3| |B| |
	--   - - - 
	-- 2|A| |C|
	--   - - - 
	-- 1|^|D| |
	--   - - - 
	--   1 2 3 
	local lib = {}
	
	function lib.checkFluids()
		local isFluid = false
		-- check if water or lava present
		for i = 1, 4 do
			blockType = T:isWaterOrLava("forward")
			if blockType:find("lava") ~= nil or blockType:find("water") ~= nil then
				isFluid = true
			end
		end
		return isFluid
	end
	
	function lib.createStaircaseSection(onGround, levels, level)
		-- start 1,1,1, n
		-- stage A
		local isFluid = lib.checkFluids()
		local blockType = ""
		local data = T:getStock("stairs")
		if data.total == 0 then
			T:craft('stairs', 4)
		end
		if onGround and isFluid then
			-- add right side and block entrance
			T:go("R1C1R1C1R2")
		end
		if isFluid then
			T:go("L1C1 R1F1C2 L1C1 R1x1 R1C1 L1C2B1 C1x1 ^1C2", false, 0, true) --start:1,1,1,n stairs A on level 1, going back to 1,1,1,n
		else
			T:go("F1x1 R1C1 L1C2B1 ^1C2", false, 0, true)
		end
		if not onGround then
			-- stage A1
			T:go("L2C1L2", false, 0, true) -- start 1,1,1,n fix corner on level 1 end: 1,1,1,n
		end
		-- stage B
		T:go("U1L1", false, 0, true) -- end  1,1,1,w layer 2
		level = level + 1
		isFluid = lib.checkFluids()
		if isFluid then
			T:go("C1", false, 0, true) -- end  1,1,1,w layer 2
		end
		if not onGround then
			if isFluid then
				T:go("L1C1R1", false, 0, true) -- end  1,1,1,w layer 2
			end
		end
		-- stage C1
		if isFluid then
			T:go("R1C1F1C1x1 L1C1 R2C1 L1B1", false, 0, true)
		else
			T:go("R1F1 R1C1 L1B1", false, 0, true)
		end
		--level = level + 1
		--if level == levels then
			--return false, level
		--end
		-- stage C2
		T:go("U1")
		level = level + 1
		--if level == levels then
			--return true, level
		--end
		isFluid = lib.checkFluids()
		if isFluid then
			T:go("L1C1L1 C1L2 C1F1L1 C1R2 C1L1 B1C2 D1", false, 0, true) -- end 1,1,2,n
		else
			T:go("F1R1 C1L1 B1D1", false, 0, true) -- end 1,1,2,n
		end
		level = level - 1 -- went down in branch above
		--if level == levels then
			--return false, level
		--end
		-- stage D
		isFluid = lib.checkFluids()
		if isFluid then
			T:go("C1F1C1F1C1x1L1 C1R1 C1R1", false, 0, true) -- 3,1,2,e
		else
			T:go("F2 C1R1", false, 0, true) -- 3,1,2,e
		end
		
		return false, level
	end

	--local height = currentLevel -- eg 64 at top or 5 at bedrock
	local data = T:getStock("stairs")
	--{rt.total, rt.mostSlot, rt.leastSlot, rt.mostCount, rt.leastCount}
	local numStairs = data.total
	local levels = math.abs(R.depth - R.height) --height of stairs
	local numStairsNeeded = levels
	numStairsNeeded = numStairsNeeded - numStairs
	if numStairsNeeded > 40 then
		print('crafting '..numStairsNeeded..' : '..numStairs.. ' in stock')
		if T:craft('stairs', 40) then	-- max 40 so repeat
			data = T:getStock("stairs")
			if data.total == 0 then
				data = T:getStock("stairs")
			end
			numStairs = data.total
			numStairsNeeded = numStairsNeeded - numStairs
		else
			return {"Unable to craft stairs"}
		end
	end
	if numStairsNeeded > 0 then
		T:craft('stairs', numStairsNeeded)
	end
	local level = 0
	if R.down then -- go down towards bedrock
		local atBedrock = false
		for i = 1, levels do
			level = level - 1
			if not T:down() then
				atBedrock = true
				break
			end
		end
		if atBedrock then -- hit bedrock so get to level 5 / -59
			level = T:findBedrockTop(level)
			T:go("R1F1R1", false, 0, true)
		end
	end
	local onGround = true
	level = 0
	while level < levels do
		onGround, level = lib.createStaircaseSection(onGround, levels, level)
	end
	if not turtle.detectDown() then
		T:go("C2")
	end
	
	return{"Staircase completed"}
end

local function createTreefarm(R) -- 22
	local lib = {}
	--go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	function lib.buildWallSection(length, placePolished, useBlockType)
		useBlockType = useBlockType or ""
		for i = 1, length do
			if placePolished and i == length - 4 then
				T:place("polished", 0, "down")
				T:forward(1)
			else
				if i < length then
					T:go("C2F1", false, 0, false, useBlockType)
				end
			end
		end
	end
	
	function lib.placeFloor(length, useBlockType)
		for i = 1, length do
			T:go("x0C2", false, 0, false, useBlockType)
			if i < length then
				T:forward(1)
			end
		end
	end
	
	function lib.placeWater(length)
		T:place("water", 0, "down")
		T:go("F"..length.."R1")
	end
	
	function lib.placeCorners(length, numBlocks, useBlockType)
		for i = 1, numBlocks do
			T:go("C2F1", false, 0, false, useBlockType)
		end
		-- now at 5th space
		T:forward(length - (numBlocks * 2))
		for i = 1, numBlocks do
			T:go("C2", false, 0, false, useBlockType)
			if i < numBlocks then
				T:forward(1)
			end
		end
	end
	
	function lib.turn(outward)
		if outward then
			T:go("R1F1R1")
		else
			T:go("L1F1L1")
		end
		return not outward
	end
	
	local blockType
	local blockModifier
	-- R.data = "existing" if on existing tree farm
	-- R.up = true if clear area
	if R.up then
		clearArea(R, false)
	end

	if R.data == "existing" then
		T:go("R1F1 D1", false, 0, false) -- move 14 blocks, right, forward, down 1
		lib.buildWallSection(R.width - 1, false, R.useBlockType)
		T:turnLeft(1)
		lib.buildWallSection(R.length, false, R.useBlockType)
		T:turnLeft(1)
		lib.buildWallSection(R.width - 1, false, R.useBlockType)
		T:go("C2U1R2")
		lib.buildWallSection(R.width - 1, true, R.useBlockType)
		T:turnRight(1)
		lib.buildWallSection(R.length, true, R.useBlockType)
		T:turnRight(1)
		lib.buildWallSection(R.width, true, R.useBlockType)
		T:go("R1") -- on lower left corner facing forward
	else
		T:down(1)
		local placePolished = false
		for i = 1, 2 do
			lib.buildWallSection(R.length, placePolished, R.useBlockType)
			T:turnRight(1)
			lib.buildWallSection(R.width, placePolished, R.useBlockType)
			T:turnRight(1)
			lib.buildWallSection(R.length, placePolished, R.useBlockType)
			T:turnRight(1)
			lib.buildWallSection(R.width, placePolished, R.useBlockType)
			T:turnRight(1)
			placePolished = true
			if i == 1 then
				T:up(1)
			end
		end -- on lower left corner facing forward
	end
	T:go("F1R1 F1L1 D2") -- over 13 x 13 internal area
	local outward = true
	for i = 1, R.width - 2 do
		lib.placeFloor(R.length - 2, R.useBlockType)
		if i < R.width - 2 then
			outward = lib.turn(outward)
		end
	end
	T:go("U1R2") -- over 13 x 13 internal area opposite corner
	-- now add corners
	lib.placeCorners(R.length - 2, 4, R.useBlockType)
	outward = lib.turn(outward)
	lib.placeCorners(R.length - 2, 3, R.useBlockType)
	outward = lib.turn(outward)
	lib.placeCorners(R.length - 2, 2, R.useBlockType)
	outward = lib.turn(outward)
	lib.placeCorners(R.length - 2, 1, R.useBlockType)
	if outward then
		T:go("R1F"..R.width - 9 .."R1")
	else
		T:go("L1F"..R.width - 9 .."L1")
	end
	outward = not outward
	lib.placeCorners(R.length - 2, 1, R.useBlockType)
	outward = lib.turn(outward)
	lib.placeCorners(R.length - 2, 2, R.useBlockType)
	outward = lib.turn(outward)
	lib.placeCorners(R.length - 2, 3, R.useBlockType)
	outward = lib.turn(outward)
	lib.placeCorners(R.length - 2, 4, R.useBlockType) -- should be back in starting corner facing front
	
	T:go("U1R1")
	lib.placeWater(R.length - 3) -- place water down then move forward, turn right
	lib.placeWater(R.width - 3)
	lib.placeWater(R.length - 3) 
	lib.placeWater(R.width - 3)
	T:go("F".. math.floor((R.length - 2) / 2).."R1F".. math.floor((R.width - 2) / 2)) -- should be in centre
	T:go("D4C2 R1C1 R1C1 R1C1 R1F1 R2") -- facing back of hole ready to place water
	T:place("water", 0, "forward")
	T:go("R2F7U4")
	
	return {"Tree farm ready for planting"}
end

local function createWallOrFence(R)
	local lib = {}
	
	function lib.placeBarrel(R)
		if R.data == "barrel" then
			utils.goBack(1)
			T:go("L1F1")
			T:place("barrel", 0, "down", false)
			utils.goBack(1)
			T:go("R1")
			T:forward(1)
		end
	end
	
	function lib.placeTorch(R)
		T:up(1)
		local up = 1
		local blockType = T:getBlockType("forward")
		while blockType:find(R.useBlockType) ~= nil do
			T:up(1)
			up = up + 1
			blockType = T:getBlockType("forward")
		end
		T:place("torch", 0, "forward", true)
		T:down(up)
	end
	
	function lib.buildWall(R, length)
		-- T:place(blockType, damageNo, direction, leaveExisting, signText)
		local blockType = ""
		local blocks = 0
		lib.placeBarrel(R)
		while blocks < length do
			if turtle.back() then
				T:place(R.useBlockType, 0, "forward", true)
				if R.torchInterval > 0 then
					if blocks == 0 or blocks % R.torchInterval == 0 then
						lib.placeTorch(R)
					end
				end
				blocks = blocks + 1 -- still facing start position
				while turtle.down() do
					T:place(R.useBlockType, 0, "up", true)
				end
			else -- obstruction
				T:turnRight(2) -- facing away from start
				blockType = T:getBlockType("forward")
				if blockType:find("torch") ~= nil then
					T:go("F1R2")
					T:place(R.useBlockType, 0, "forward")
					blocks = blocks + 1 -- facing start
				elseif blockType:find("log") ~= nil then
					T:harvestTree()
					T:turnRight(2)
					T:place(R.useBlockType, 0, "forward")
					blocks = blocks + 1 -- facing start
				elseif T:isVegetation(blockType) then
					T:go("F1R2")
					T:place(R.useBlockType, 0, "forward")
					blocks = blocks + 1 -- facing start
				else -- cant go forward, go up instead
					while turtle.detect() and blockType:find("torch") == nil and blockType:find("log") == nil and not T:isVegetation(blockType) do -- block ahead, but not torch or tree
						while turtle.detectUp() do -- will only run if block above
							utils.goBack(1)
							blocks = blocks - 1
						end
						turtle.up()
						T:place(R.useBlockType, 0, "down", true)
						blockType = T:getBlockType("forward")
					end
					T:turnRight(2) -- facing start
				end
			end
		end
	end
	
	T:turnRight(2) --facing start position
	if R.width == 0 then -- single fence
		lib.buildWall(R, R.length)
	else	
		lib.buildWall(R, R.length - 1)
		T:go("R1") -- facing start so left turn = turnRight
		lib.buildWall(R, R.width - 1)
		T:go("R1")
		lib.buildWall(R, R.length - 1)
		T:go("R1")
		lib.buildWall(R, R.width - 2)
		T:go("U1")
		T:place(R.useBlockType, 0, "down", true)
	end
	
	return {"Wall or fence completed"}
end

local function createWaterCanal(R) -- 53
	-- designed for 4 turtles, but can be done with 1-3 as well
	-- R.subChoice = 1:towpath, optional torches, 2:water canal
	local lib = {}
	
	function lib.waterCanalTowpath(R, maxLength)
		local torch = R.length - maxLength					-- start torch count at 1-2 depending on lib.initialise()
		local numBlocks = 0									-- distance travelled
		while numBlocks < maxLength do						-- loop from here. Facing forwards to extend canal
			T:go("x0C2", false, 0, false)
			if R.torchInterval > 0 then
				if numBlocks == 0 or torch == R.torchInterval then
					T:up(1)
					T:place("torch", -1, "down", false)
					if numBlocks < maxLength then
						T:go("F1D1C2", false, 0, false)
						numBlocks = numBlocks + 1		
					else
						return
					end
					torch = 0
				end
			end
			T:forward(1)
			torch = torch + 1								-- increase torch spacing interval
			numBlocks = numBlocks + 1						-- inrease block count
		end
		T:dig("up")
	end
	
	function lib.waterCanal(R, maxLength)
		-- Already in position facing new canal, 2 water buckets
		local torch = R.length - maxLength					-- start torch count at 1-2 depending on lib.initialise()
		local sourceCount = 0								-- allow for 1 iteration of placing source blocks when changing from solid to water
		local numBlocks = 0									-- distance travelled
		local _, isSource = nil, false						-- initialise variables
		local oTurn = "R"									-- assume R.side == "L" -> oTurn = "R"
		if R.side == "R" then								-- R.side = "R"
			oTurn = "L"										-- oTurn = "L"
		end
		
		while numBlocks < maxLength do						-- loop from here. Facing forwards to extend canal
			torch = torch + 1								-- increase torch spacing interval
			numBlocks = numBlocks + 1						-- inrease block count
			if deletesWater then							-- up to and including mc 1.12.2
				T:forward(1)								-- move forward to extend canal  | |>|
				_, isSource = T:isWater("down")				-- check if source water below
				if isSource then
					sourceCount = sourceCount + 1			-- count source blocks
				else										
					T:down(1)								-- down to canal floor
					sourceCount = 0							-- reset
					T:go("C2", false, 0, false)								-- place block below
					T:up(1)									-- up to water level
				end											-- still facing away from canal
				if turtle.detectUp() then 					-- ? block above
					T:go("U1x0")							-- break block above
				end
				if not isSource or scoreCount == 0 then		-- not source below, or first time found, ensures continous canal
					T:go(R.side.."2x0")						-- face back to existing canal
					T:place("water_bucket", -1, "down")		-- place water
					T:forward(1)							-- forward 1
					T:place("water_bucket", -1, "down")		-- place water
					utils.getWater() 							-- collects water from below
					utils.goBack(1) 						-- back 1
					T:go(R.side.."2")						-- face new canal
				end
			else
				T:forward(1) 								-- move forward to extend canal
				_, isSource = T:isWater("forward")			-- check if source water ahead
				if isSource then							-- ? source ahead
					sourceCount = sourceCount + 1
				else
					sourceCount = 0
					if not turtle.detectDown() then			-- air / water below, but no source in front, so fill it
						T:go(oTurn.."1D1")					-- ready to repair neighbouring canal base
						if T:getBlockType("forward"):find("turtle") ~= nil then -- turtle in similar position
							if R.side == "L" then			-- only left side repairs, so wait 1 second
								sleep(1)
								T:go("C1", false, 0, true)					-- repair neighbouring canal base
							end
							T:go(R.side.."1")				-- face forward
						else
							T:go("C1"..R.side.."1",false, 0, true)	-- repair neighbouring canal base if air
						end
						T:up(1)
					end
					T:go("C2", false, 0, false)				-- place block below if not already source
				end
				T:go(R.side.."1C1"..oTurn.."1", false, 0, true) -- face canal wall, replace with stone if empty, face forward										
				if not isSource	and sourceCount == 0 then	-- not source in front, or first time found, ensures continous canal					
					T:go("C1", false, 0, true) 				-- *| | | |>| face along new canal and block entrance
					utils.goBack(1)							-- *| | |>| | back 1
					T:place("water_bucket", -1, "forward")	-- *| | |>|W| place water
					T:go(oTurn.."2") 						-- *| | |<|W| face existing canal 
					_, isSource = T:isWater("forward")		-- *| |?|<|W| check if source water ahead 
					if not isSource then
						if not T:place("water_bucket", -1, "forward") then	-- place water again *| |W|<|W|
							while not T:place("bucket", -1, "forward") do -- wait for other turtle
								print("Out of water buckets")
								sleep(1)
							end
							sleep(0.2)
							T:place("bucket", -1, "forward") 
						end
					end
					utils.getWater() 							-- collects water *| |W|<|W|
					T:go(R.side.."2F1") 						-- face along new canal *| |W|>|W| to *| |W|W|>|
				end
			end
		end
	end
		
	local maxLength = 1024
	if R.length ~= 0 then
		maxLength = R.length
	end
	menu.clear()
	menu.colourWrite("Building canal "..R.side.." side", colors.yellow, nil, nil, false, true)
	local moves = utils.initialiseCanal(R) -- move to correct position and/or start new canal
	if R.subChoice == 1 or R.subChoice == 4 then
		lib.waterCanalTowpath(R, maxLength)
	else
		lib.waterCanal(R, maxLength - moves)
	end
	
	return {}
end

local function createMobGrinder(R)
	-- go down 5 and create a cavity 9 wide, 5 long, 8 high
	-- assume facing out from spawner cube at base of exit (6 blocks above ground
	-- R.subChoice = 1 or 2 (sticky or normal pistons)
	
	local lib = {}
	
	function lib.getInventory(R)
		T:clear()
		menu.colourPrint("All blocks to be ejected. Ready? Enter", colors.red)
		read()
		T:emptyInventory("up")
		T:checkInventoryForItem({"stone"}, {20}, true, "Match existing walls?")
		if R.subChoice == 1 then -- sticky pistons
			T:checkInventoryForItem({"computercraft:computer_normal"}, {1})
			T:checkInventoryForItem({"minecraft:sticky_piston"}, {2})
		else
			T:checkInventoryForItem({"computercraft:computer_normal"}, {2})
			T:checkInventoryForItem({"minecraft:piston"}, {4})
			T:checkInventoryForItem({"computercraft:cable"}, {6})
			T:checkInventoryForItem({"computercraft:wired_modem"}, {2})
		end
		T:checkInventoryForItem({"polished"}, {23}, true, "Any polished block")
		T:checkInventoryForItem({"wall"}, {2}, true, "Any wall block ? match")
		T:checkInventoryForItem({"slab"}, {7}, true, "Any stone slab. ? polished / match")
		T:checkInventoryForItem({"minecraft:glass"}, {2})
		T:checkInventoryForItem({"minecraft:stone_pressure_plate"}, {1})
		T:checkInventoryForItem({"minecraft:dispenser"}, {1})
		T:checkInventoryForItem({"hopper"}, {1})
		T:checkInventoryForItem({"chest"}, {2})
		T:checkInventoryForItem({"minecraft:redstone"}, {9})
		T:checkInventoryForItem({"lava"}, {1})
		R.useBlockType = T:getPolishedItem("")
		if R.useBlockType == "" then
			R.useBlockType = T:getMostItem("", true)
		end
	end
	
	function lib.placeRedstone()
		T:go("D2U2")								-- in left corner facing right 
		T:place("slab", 0, "down")					-- place slab layer 1
		T:up(2)
		T:place("slab", 0, "down")					-- place slab layer 2
		T:up(1)
		T:place("redstone", 0, "down")
		T:go("F1D4 C2L1C1 L1U1", false, 0, false)	-- facing ground level slab
		T:place("redstone", 0, "forward")			-- redstone on ground level slab
		T:up(1)
		T:place("slab", 0, "down")					-- slab on layer 1
		T:up(2)
		T:place("slab", 0, "down")					-- slab on layer 3
		T:up(1)
		T:place("redstone", 0, "down")				-- redstone on layer 3 slab
		utils.goBack(1)
		T:down(3)									-- facing layer 1 slab
		T:place("redstone", 0, "forward")			-- redstone on layer 1 slab
		T:go("D2C2", false, 0, false)				-- under end of chest position
		T:place("redstone", 0, "forward")			-- redstone on level 0 floor
		T:go("R1C1R1", false, 0, false)				-- face right, repair back wall
		T:go("F1C2 L1C1 R1", false, 0, false)		-- under chest start
		T:go("F1C2 L1C1 R1", false, 0, false)		-- under hopper
		T:go("F1C2 L1C1 R1", false, 0, false)		-- under right side wall block
		T:go("U1L2")								-- ready for redstone
		for i = 1, 4 do
			T:place("redstone", 0, "down")			-- redstone under chest etc
			if i < 4 then
				T:forward(1)
			end
		end
		-- finishes facing slab at ground level, redstone below
	end
	
	function lib.placeStorage()
		-- starts facing slab at ground level, redstone below
		T:go("L1F1L2")								-- up and out ready for chest placement
		T:place("chest", 0, "forward")				-- end chest
		T:go("R1F1 L1F1 R1U2")						-- at above start chest position facing right
		T:place("slab", 0, "down")					-- slab above chest
		T:turnLeft(1)
		utils.goBack(1)								
		T:down(2)									-- in front of start chest position
		T:place("chest", 0, "forward")				-- start chest
		T:go("R1F2L2")								-- at pressure plate position facing left
		T:place("wall", 0, "forward")				-- place wall
		T:up(1)
		T:place("pressure", 0, "down")				-- place pressure plate
		T:go("R1F1 L1D1")							-- at second wall position
		T:place("hopper", 0, "forward")				-- place hopper into chest
		utils.goBack(1)
		T:place("wall", 0, "forward")				-- place second wall
		-- finishes on level 1 (ground) facing right side wall block
	end
	
	function lib.placePistons(R)
		-- starts on level 1 (ground) facing right side wall block
		T:go("U1F2 R1")									-- go over wall block, facing back wall layer 2
		T:place(R.useBlockType, 0, "forward", false)	-- replace back wall with polished block layer 2
		T:up(1)											-- layer 3
		T:place(R.useBlockType, 0, "forward", false)	-- replace back wall with polished block layer 3
		T:turnRight(1)									-- face right side
		if R.subChoice == 1 then						-- use sticky pistons x 2
			T:place(R.useBlockType, 0, "forward", false)-- polished block above second wall layer 3
			T:go("R2F1")								-- ready to place lower piston (works ok as slab already in place behind it)
		else
			T:go("F2R2")								-- move forward 2 and face left
			T:place("piston", 0, "forward")				-- lower replacer piston placed
			T:go("U1F2D1F1")							-- go up and over piston forward 1 ready for other piston
		end
		T:place("piston", 0, "forward")					-- lower piston placed
		utils.goBack(1)
		T:go("U1R1")									-- layer 4
		T:place(R.useBlockType, 0, "forward", false)	-- polished block back wall layer 4
		T:go("L1F2R2")									-- head left ready for dispenser
		T:place("dispenser", 0, "forward")				-- dispenser placed
		T:dropItem("lava", "forward")					-- drop lava bucket into dispenser
		T:go("U1F2 D1")									-- up and over dispenser, facing right side
		T:place("slab", 0, "down")						-- lower piston slab placed
		if R.subChoice == 1 then
			T:place(R.useBlockType, 0, "forward", false)-- polished block above second wall layer 4
			T:turnLeft(1)								-- facing back wall
		else
			T:go("F1L1")								-- at second computer position, facing back wall
			utils.goBack(1)								-- ready to place computer
			T:place("computercraft:computer_normal", 0, "forward", false)	-- place computer
			T:go("L1F1R1F1")							-- facing back wall in mob drop, level 4
		end
		T:place(R.useBlockType, 0, "forward", false)	-- polished block back wall layer 4
		T:turnLeft(1)
		T:go("U1F3R2")									-- level 5 ready for upper piston
		T:place("piston", 0, "forward")					-- upper piston placed
		T:go("U1F3D1R2")								-- up and over piston, facing left, level 5
		T:turnRight(1)									-- at mob drop, facing wall, level 5
		T:place(R.useBlockType, 0, "forward", false)	-- polished block back wall layer 5
		T:turnRight(1)									-- facing right side
		if R.subChoice == 1 then
			T:place(R.useBlockType, 0, "forward", false)-- right side polished block layer 5, facing right side, in mob drop 							-- layer 5 facing left side, in mob drop		
		else
			T:go("F1C1")								-- move forward, place temporary block
			utils.goBack(1)
			T:place("piston", 0, "forward")				-- upper replacer piston placed				
		end
		T:turnRight(2)	
		T:place("slab", 0, "forward")					-- upper piston slab placed
		T:turnLeft(1)									-- facing away from back wall
	end
	
	function lib.placeComputer(R)
		-- starts facing away from back wall, layer 5, in mob drop 			
		T:go("F1R1 F2R1 D1")							-- move to left computerposition, facing back wall, layer 4
		T:place("computercraft:computer_normal", 0, "forward", false)		-- place computer in gap, layer 4
	end
	
	function lib.placeColumnSection(direction)
		T:place(R.useBlockType, 0, "forward", false)
		T:go(direction.."1")
		T:place(R.useBlockType, 0, "forward", false)
		T:go(direction.."1")
		T:place(R.useBlockType, 0, "forward", false)	-- facing right
	end
	
	function lib.placeColumns(R)
		-- starts facing left computer, layer 4
		T:go("R1F2 L1")									-- facing mob drop level 4
		T:place("glass", 0, "down", false)
		T:up(1)											-- facing mob drop level 5
		T:place("glass", 0, "down", false)				-- on top of glass facing back wall at dungeon base level 5
		T:up(1)	
		T:place(R.useBlockType, 0, "down", false)		-- level 6 dungeon exit
		T:go("F1L1")
		lib.placeColumnSection("L")						-- facing right
		T:up(1)
		lib.placeColumnSection("R")						-- facing left
		T:up(1)
		lib.placeColumnSection("L")						-- facing right
		T:up(1)
		lib.placeColumnSection("R")						-- facing left
		T:up(1)
		T:place(R.useBlockType, 0, "forward", false)
		T:turnLeft(2)
		T:place(R.useBlockType, 0, "forward", false)	-- facing right
		T:turnLeft(1)
		utils.goBack(2)
		T:place(R.useBlockType, 0, "forward", false)
		T:down(9)
	end
	
	function lib.placeNetwork()
		T:go("R1F2L1 F3U3 F1L1F1 L1x1")								-- go behind second computer and remove block
		T:place("computercraft:wired_modem", 0, "forward", false)	-- place modem
		utils.goBack(1)
		T:place("computercraft:cable", 0, "forward", false)			-- place network cable
		T:place("computercraft:cable", 0, "forward", false)			-- place network cable (no need to move)
		T:go("R1F1 x2L1")											-- move forward, face back wall
		T:place("computercraft:cable", 0, "forward", false)
		T:go("R1F1 x2L1")
		T:place("computercraft:cable", 0, "forward", false)
		T:go("R1F1 x2L1F1 x1x2")									-- come behind left computer and expose back
		T:place("computercraft:wired_modem", 0, "forward", false)	-- place modem
		utils.goBack(1)
		T:place("computercraft:cable", 0, "forward", false)
		T:place("computercraft:cable", 0, "forward", false)
		T:go("L1D3 F4R1 F3U4 D4")									-- removes temporary block
	end
	
	local tempSubChoice = R.subChoice	-- store for later use
	R.width = 4							-- settings for createFloorCeiling()
	R.length = 9
	R.height = 0
	R.up = true
	T:turnRight(2)
	local isWater, isSource, isIce, level, isAir = T:isWater("forward")
	if not isWater then
		T:turnRight(2)
		return{"Not in correct position. Must be water behind"}
	end
	T:go("U1x1 U1L1 F4R2")					-- go up to starting point
	local data = createFloorCeiling(R)[1] 	-- place ceiling, returns to starting position. if water or lava present is returned as "water or lava found"
	if data == "water or lava found" then
		R.height = 10
		R.silent = true
		T:up(1)
		createSinkingPlatform(R)
		T:go("F4L1 U5x1 U1x1 U3R1 F4C0 R1F3C0 R1F8C0 R1F3C0 R1D9") 			-- re-open exit hole, return to floor level
	else -- no water or lava found so empty out area
		R.height = 10
		R.subChoice = 2
		clearSolid(R) -- 76
		T:down(R.height - 1)
		R.width = 4							-- settings for createFloorCeiling()
		R.length = 9
		R.height = 0
		R.down = true
		R.up = false
		R.subChoice = 1						-- replace existing floor
		createFloorCeiling(R)
	end
	
	R.subChoice = tempSubChoice
	lib.getInventory(R)
	lib.placeRedstone()
	lib.placeStorage()
	lib.placePistons(R)
	lib.placeComputer(R)		-- ends facing computer
	lib.placeColumns(R)
	if R.subChoice == 2 then
		lib.placeNetwork()
	end
	
	return {}
end

local function sandFillArea(R) -- 81
	--clearRectangle with sand drop
	-- could be 1 wide x xx length (trench) up and return
	-- could be 2+ x 2+
	-- even no of runs return after last run
	-- odd no of runs forward, back, forward, reverse and return
	local success
	local directReturn = true
	if R.width % 2 == 1 then
		directReturn = false
	end
	if R.width == 1 then -- trench ahead, so fill then return
		for i = 1, R.length - 1 do
			success = utils.dropSand()
			T:forward(1, false)
		end
		success = utils.dropSand()
		T:go("R2F"..(R.length - 1).."R2", false, 0, false)
	else --2 or more columns
		if directReturn then -- R.width = 2,4,6,8 etc
			for i = 1, R.width, 2 do -- i = 1,3,5,7 etc
				-- move along R.length, dropping sand
				for j = 1, R.length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				T:go("R1F1R1") --turn right and return on next column
				for j = 1, R.length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				if i < R.width - 2 then -- eg R.width = 8, i compares with 6: 1, 3, 5, 7
					T:go("L1F1L1")
				end
			end
			T:go("R1F"..R.width - 1 .."R1") --return home
		else
			for i = 1, R.width, 2 do -- i = 1,3,5,7 etc
				-- move along R.length, dropping sand
				for j = 1, R.length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				T:go("R1F1R1") --turn right and return on next column
				for j = 1, R.length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				T:go("L1F1L1")
			end
			-- one more run then return
			for j = 1, R.length - 1 do
				success = utils.dropSand()
				T:forward(1, false)
			end
			success = utils.dropSand()
			T:go("R2F"..R.length.."R1F"..R.width - 1 .."R1")
		end
	end
	return {}
end

local function deactivateDragonTower() -- 45
	-- go up centre of tower to bedrock
	local height = 0
	--numBlocksMoved, errorMsg = clsTurtle.doMoves(self, numBlocksRequested, direction)
	local numBlocks, message = T:doMoves(1, "up")
	while message == nil do
		numBlocks, message = T:doMoves(1, "up")
		height = height + 1
	end
	-- go round bedrock and destroy crystal
	T:go("F1R2U2x1U1x1")
	-- return to start
	T:down(height + 5)
	return {}
end

local function undermineDragonTowers() -- 44
	--[[
	        -13, -40....12, -40						NNW (4)   	NNE (5)
			
	    -34, -25............33, -25				NWW	(2)				NEE (9)
		
	-42, -1....................42, 0		W (1)						E (8)
	
	     -34, 24............33,24				SWW	(3)				SEE (10)
		 
		      -13,39....12, 39						SSW	(7)		SSE (6)
	
	North towers centres 25 blocks apart, 40 blocks north of axis
	Mid-North towers 67 blocks apart, 25 blocks north of axis
	W-E centres 84 blocks apart, on 0 axis
	Mid-south towers 67 blocks apart, 24 blocks south of axis
	South towers centres 25 blocks apart, 39 blocks south of axis
	]]
	
	local lib = {}
	function lib.findNextTower(maxDistance, withMarker)
		local distance = 0
		local blockTypeF = T:getBlockType("forward")
		local blockTypeD = T:getBlockType("down")
		for i = 1, maxDistance do
			if blockTypeF ~= "minecraft:obsidian" and blockTypeD ~= "minecraft:obsidian" then -- not in a tower
				if withMarker then -- used to mark 0 coordinate
					T:place("cobble", -1, "down", false) -- place cobblestone or cobbled deepslate to mark zero coordinate
				end
			else	-- obsidian found, could still be in an earlier tower
				if i > 10 then
					break
				end
			end
			T:go("F1x0")
			distance = distance + 1
			blockTypeF = T:getBlockType("forward")
			blockTypeD = T:getBlockType("down")
		end
		if distance == maxDistance then -- obsidian not found ? wrong place/ direction
			print("Obsidian not found")
			error()
		end
		-- will now be at side of a tower
		lib.findCentre() -- move into tower to find the other side
		return distance
	end
	
	function lib.findCentre()
		local width = 0
		-- while obsidian in front or below (previously entered tower) measure width and return to centre
		local blockTypeF = T:getBlockType("forward")
		local blockTypeD = T:getBlockType("down")
		while blockTypeF == "minecraft:obsidian" or blockTypeD == "minecraft:obsidian" do
			T:go("F1x0")
			width = width + 1
			blockTypeF = T:getBlockType("forward")
			blockTypeD = T:getBlockType("down")
		end
		-- will always go outside the tower 1 block. width of 5 block tower = 6
		T:go("R2F"..math.ceil(width / 2)) --return to centre of tower
		T:turnLeft(1) -- now find another edge of the tower, dig forward until out of obsidian
		for i = 1, math.ceil(width) do  -- give additional loops if missed centre
			blockTypeF = T:getBlockType("forward")
			blockTypeD = T:getBlockType("down")
			if blockTypeF == "minecraft:obsidian" or blockTypeD == "minecraft:obsidian" then
				T:go("F1x0")
			else
				break
			end
		end
		-- now outside different edge of the tower
		-- reverse and move width/2, dig up + 1 to mark centre, face original direction
		T:go("L2F"..math.ceil(width / 2).."R1U2x1")
		T:place("minecraft:end_stone", -1, "forward", false) -- place endstone to mark facing direction
		T:down(2)
	end
	
	function lib.findPath(maxLength)
		local blockTypeD = T:getBlockType("down")
		local distance = 0
		while blockTypeD:find("cobble") == nil and distance < maxLength do
			T:go("F1x0")							-- return to 0 axis, 
			distance = distance + 1
			blockTypeD = T:getBlockType("down")
		end
		return distance
	end
	
	-- start at 0,y,0, facing West
	T:dig("up")									-- in case not already done
	local maxLength = 0
	local blockTypeD
	local distance = lib.findNextTower(45, true)-- find W tower (1) and mark trail with cobble
	T:turnRight(2)						
	for i = 1, 8 do								-- head back East 8 blocks, turn left (facing north)
		T:go("F1x0")							-- this path may be off-axis, so dig double height
	end
	T:turnLeft(1)
	lib.findNextTower(30)						-- find NWW tower (2)
	T:turnRight(2)
	distance = lib.findPath(30)
	distance = distance + lib.findNextTower(30)	-- find SWW tower (3)
	T:turnRight(2)
	distance = lib.findPath(30)
	T:turnRight(1) 								-- should be on cobble path
	for i = 1, 21 do							-- move East 21 blocks, turn left facing North
		T:go("F1x0")
	end
	T:turnLeft(1)
	
	distance = lib.findNextTower(45)		-- find NNW tower (4)
	T:turnRight(1)							
	distance = lib.findNextTower(30)		-- find NNE tower (5)
	T:turnRight(1)
	distance = lib.findNextTower(85)		-- find SSE tower (6)
	T:turnRight(1)

	distance = lib.findNextTower(30)		-- find SSW tower (7)
	T:turnRight(1)
	distance = lib.findPath(40)				-- head North to 0 axis
	T:go("R1F13") 							-- return to 0,0 facing East
	distance = lib.findNextTower(45, true)	-- find E tower (8)
	
	T:turnRight(2)						
	for i = 1, 9 do
		T:go("F1x0")						-- this path may be off-axis, so dig double height
	end
	T:turnRight(1)
	
	distance = lib.findNextTower(30)		-- find NEE tower (9)
	T:turnRight(2)
	distance = lib.findPath(30) -- return to 0 axis
	distance = lib.findNextTower(30)		-- find SEE tower (10)
	T:turnRight(2)
	distance = lib.findPath(30) 			-- return to 0 axis
	T:go("L1F33")							-- return to 0, 0
	return {}
end

local function demolishPortal(R) -- 43
	--[[
	R.length = length of portal NOT width default 4
	R.height = height of portal default 5
	R.width = thickness of portal default 1
	R.data = "bury" to embed bottom into ground
	R.subChoice 1 = facing portal, 2 = aligned
	]]

	if R.subChoice == 1 then -- facing portal
		T:go("F"..R.width.."R1")
	else
		T:forward(1)
	end
	if R.data == "bury" then
		T:down(1)
	end

	R.data = "up"
	R.silent = true
	if R.width == 1 then
		return clearWall(R)
	else
		return clearBuilding(R, true, true)
	end
end

local function digTrench(R) -- 77
	local blockType
	-- go down R.height, move forward
	if R.length == 0 then
		R.length = 4096 -- will go out of loaded chunks and stop or max 4096 on a server
	end
	for i = 1, R.length do
		local count = 0
		for down = 1, R.height do
			blockType = T:isWaterOrLava("down") 
			-- go down only if no water or lava below
			if blockType:find("water") == nil and blockType:find("lava") == nil then
				T:down(1)
				count = count + 1
			end 
		end
		T:go("C2", false, 0, true)				-- if empty below fill void
		T:go("U"..count)						-- return to surface, continue if block above
		while turtle.detect() do				-- go up while block in front
			blockType = T:getBlockType("forward")
			if T:isVegetation(blockType) then
				T:dig("forward")
				break
			elseif blockType:find("log") ~= nil then
				T:harvestTree("forward", false)
			else
				T:up(1)
			end
		end
		T:forward(1)							-- move forward
		while not turtle.detectDown() do		-- go down until block detected
			blockType = T:isWaterOrLava("down") 
			if blockType:find("water") == nil and blockType:find("lava") == nil then
				T:down(1)
			else
				break
			end
		end
	end
	
	return {}
end

local function harvestRun(runLength)
	local blockType
	local blockModifier

	for i = 1, runLength do
		blockType, blockModifier = T:getBlockType("forward") -- store information about the block in front in a table
		if blockType ~= "" then
			if blockType:find("log") ~= nil then
				T:harvestTree(true, false)
			else
				T:forward(1)			
			end	
		else
			T:forward(1)
		end
	end
end	

local function harvestTreeFarm(R) -- 24
	local lib = {}
	
	function lib.getLogCount()
		local count = 0
		for i = 1,16 do
			local item, itemCount = T:getSlotContains(i)
			if item:find("log") ~= nil then
				count = count + itemCount
			end
		end
		
		return count
	end
	
	function lib.initialise()
		local blockType = T:getBlockType("forward")
		local logType = ""
		local startHeight = 0
		local range = 0
		if blockType == "" then
			while turtle.forward() do
				range = range + 1
				if range == 3 then
					break
				end
			end
		end
		blockType = T:getBlockType("forward")
		if blockType:find("dirt") ~= nil then
			T:up(1)
			startHeight = 1
		else
			if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
				logType = blockType
			end
		end
		
		return logType, startHeight
	end
	
	R.silent = true
	local treeType, startHeight = lib.initialise() -- possible ID tree type + move to correct position 1 above dirt
	
	T:forward(1)	-- dig first log/sapling/ air if not planted
	clearRectangle({width = 7, length = 7, up = true, down = true})
	T:go("L1F2L1F2R2")
	local height = 0
	local pastLogCount = -1
	local currentLogCount = lib.getLogCount()
	while currentLogCount ~= pastLogCount do
		T:up(3)
		height = height + 3
		pastLogCount = currentLogCount -- 0 when loop starts
		clearRectangle({width = 12, length = 12, up = true, down = true})
		currentLogCount = lib.getLogCount() -- eg 20 logs from first round
	end	
	T:down(height + startHeight)
	T:go("R1F2R1F2R2")
	
	return {}
end

local function harvestObsidian(R) -- 41
	local heightParts = math.floor(R.length / 8) -- eg 12/8 = 1
	local lastPart = R.length - (heightParts * 8) -- eg 12 - (1 * 8) = 4
	if R.width % 2 ~= 0 then
		R.width = R.width + 1
	end
	for y = 1, R.width do
		print("Mining column "..tostring(y).." of "..tostring(R.width))
		for j = 1, heightParts do
			T:go("m8")
		end
		if lastPart > 0 then
			T:go("m"..tostring(lastPart)) -- eg m4
		end
		-- R.width = tonumber(R.width)
		if y < R.width then
			if y % 2 == 0 then
				T:go("L1F1L1")
			else
				T:go("R1F1R1")
			end
		end
	end
	return {}
end

local function manageFarm(R)
	local lib = {}
	
	function lib.checkEquipment()
		--[[ Needs pickaxe and hoe equipped ]]
		T:clear()
		--T:checkInventoryForItem(items{}, quantities{}, required, message)
		print("Checking equipment. Please wait...")
		local equippedRight, equippedLeft, inInventory = T:setEquipment() -- any tools equipped except diamond_pickaxe and crafting_table have been removed to inventory
		--[[if equippedRight ~= "minecraft:crafting_table" then
			T:checkInventoryForItem({"minecraft:crafting_table"}, {1})
			local equippedRight, equippedLeft = T:setEquipment()
		end]]
		if inInventory ~= "minecraft:diamond_hoe" then
			T:checkInventoryForItem({"minecraft:diamond_hoe"}, {1}, true, "Diamond Hoe required for planting!")
		end
		if T:getItemSlot("minecraft:diamond_hoe") > 0 then
			return true
		end

		return false
	end
	
	function lib.checkPosition()
		--[[ first function called on start]]
		local atHome = false
		local blockType = T:getBlockType("down")
		print("Checking position "..blockType.. " below")
		if blockType:find("water") ~= nil then -- over water
			if lib.isStorage("forward") then
				atHome = true
				T:turnRight(1)
				if lib.isStorage("forward") then-- confirms in correct position, back to crops
					T:turnRight(2)
				else -- facing crafting table
					T:turnRight(1)
				end
			else -- not a chest: facing crops or crafting table
				T:turnRight(1)
				if lib.isStorage("forward") then -- confirms was facing crops
					atHome = true
					T:turnLeft(1)
				end
			end
			-- should now be facing crops. may be crafting table to left
		end
		return atHome-- now facing crops
	end
	
	function lib.crossFarm()
		-- used with goHome to find starting point
		local blockType = ""
		local isReady, cropType, status = lib.isCropReady("down")
		-- will go forward until chest or cobble detected below
		-- if detected within 1 move, this is ignored
		local numMoves = 0
		local endOfPath = false
		while not endOfPath do
			blockType = T:getBlockType("down", -1)
			if blockType == "" or cropType ~= "" then --crops or nothing below
				turtle.forward()
			elseif  blockType:find("barrel") ~= nil or blockType:find("chest") ~= nil or blockType:find("cobble") ~= nil then
				endOfPath = true
			end
			numMoves = numMoves + 1
		end
		return blockType -- either chest or cobble
	end
	
	function lib.farmInFront()
		--[[ facing crops on first farm. move to next farm in front ]]
		T:go("U1L1F11D1R1")							-- on next farm, facing crops
		local crop = lib.manageTree()				-- refuel, gather seeds and other crops
		local isFarmToRight, _ = lib.harvest(crop)	-- harvest field, store crops
		return isFarmToRight
	end
	
	function lib.farmToRight()
		--[[ facing crops on first farm. move to next farm on right side ]]
		T:go("U1F11D1")					-- on next farm, facing crops
		local crop = lib.manageTree()	-- refuel, gather seeds and other crops
		lib.harvest(crop)				-- harvest field, store crops
	end
	
	function lib.getCrops()
		T:turnRight(1)

		if lib.isStorage("forward") then
			lib.getSeeds("forward")
		end
		T:turnRight(1)
		if lib.isStorage("forward") then
			lib.getVeg("forward")
		end
		T:turnRight(2)
	end
	
	function lib.getSaplings(direction)
		--[[ get a single sapling from the chest ]]
		if direction == nil then
			direction = "forward"
		end
		while T:suck(direction, 1) do end -- remove saplings/ seeds

		T:dropItem("sapling", direction, 1) -- drop all but 1 saplings
		if not T:dropItem("seeds", direction, 0) then-- drop all seeds
			T:dropItem("seeds", "up", 0)
		end
		
		return T:getItemSlot("sapling", -1)
	end
	
	function lib.getSeeds(direction)
		--[[ get 1 stack of wheat seeds or 1 stack of beetroot seeds ]]	
		print("Collecting seeds from storage")
		while T:suck(direction, 1) do end -- remove saplings/ seeds
		T:dropItem("sapling", direction, 0) -- drop all saplings
		T:dropItem("minecraft:wheat_seeds", direction, 64) -- drop all but 64 seeds
		T:dropItem("minecraft:beetroot_seeds", direction, 64)
		local crop = ""
		if T:getItemSlot("minecraft:wheat_seeds", -1) > 0 then
			crop = "wheat"
			print("Field crop = "..crop)
		elseif T:getItemSlot("minecraft:beetroot_seeds", -1) > 0 then
			crop = "beetroot"
			print("Field crop = "..crop)
		end
		
		return crop
	end
	
	function lib.getVeg(direction)
		-- assume only one type of crop per field
		print("Collecting crops from storage")
		direction = direction or "forward"
		while T:suck(direction, 1) do end -- remove carrots / potatoes / wheat / beetroot
		--clsTurtle.dropItem(self, item, direction, keepAmount)
		T:dropItem("wheat", direction, 0)		-- drop all wheat
		T:dropItem("beetroot", direction, 0)	-- drop all beetroot
		T:dropItem("carrot", direction, 64)		-- drop all but 64 carrots
		T:dropItem("potato", direction, 64)		-- drop all but 64 potato
		local crop = ""
		if T:getItemSlot("potato", -1) > 0 then
			crop = "potato"
			print("Field crop = "..crop)
		elseif T:getItemSlot("carrot", -1) > 0 then
			crop = "carrot"
			print("Field crop = "..crop)
		end
		
		--T:turnRight(2) -- face crops
		return crop
	end
	
	function lib.goHome()
		-- after a re-boot go to start
		local success = false
		local onTree = false
		local onWater = false
		local onChest = false
		local onCobble = false
		local onField = false

		-- is tree above or in front
		-- check if log in front
		if T:getBlockType("forward"):find("log") ~= nil then -- about to harvest tree
			lib.harvestTree("forward") -- will only harvest if fuel below half of limit
			onTree = true
		elseif T:getBlockType("up"):find("log") ~= nil then -- harvesting tree
			lib.harvestTree("up")
			onTree = true
		elseif T:getItemSlot("log", -1) > 0 then -- tree just harvested 
			onTree = true
			turtle.up()
			if T:getBlockType("up"):find("log") ~= nil then -- harvesting tree
				lib.harvestTree("up")
			else
				while turtle.down() do end
			end
		end
		
		if onTree then -- tree harvested, but direction unknown
			local blockType = ""
			local turns = 0
			
			onChest = lib.isStorage("down")
			while not onChest do
				if turtle.forward() then
					if lib.isStorage("down") then
						onChest = true
					else
						turtle.back()
					end
				end
				if not onChest then
					T:turnRight(1)
					turns = turns + 1
				end
				if turns == 4 then
					break
				end
			end -- should be on chest. If not should be over water
			if onChest then -- onChest and onTree, go left,down
				T:go("R1F1D1R1")
			end
			atHome = lib.checkPosition()
			if atHome then
				return true -- exit function
			end
		else
			while turtle.down() do end -- no tree around, no logs onboard
		end
		if not onChest then -- no sign of tree harvest
			local blockType = T:getBlockType("down")
			if blockType:find("water") ~= nil then
				onWater = true
			elseif blockType:find("cobble") ~= nil then
				onCobble = true
			elseif blockType == "minecraft:dirt" or blockType == "minecraft:grass_block" then --on field after call to go down
				T:up(1)
				onField = true
			else
				--check for crops below
				local isReady, cropType, status = lib.isCropReady("down")
				if cropType ~= "" then
					onField = true
				end
			end
		end
		
		if onField then
			--[[ continue across until detect cobble or chest below ]]
			local cobble = -1
			local endBlock = lib.crossFarm()
			if endBlock:find("cobble") ~= nil then
				onCobble = true
			elseif endBlock:find("barrel") ~= nil or endBlock:find("chest") ~= nil then
				onChest = true
			end
			onField = false
		end
		-- check now for onWater, onCobble, onChest
		if onWater then -- must be on non-start water
			--[[0 chests near = top right / top left on single farm / bottom right on single farm
				1 chest near = top left on extended farm/ bottom right on extended farm
				crop,crop,chest,cobble = bottom right extended
				crop,crop,cobble,chest = top left extended farm
				]]
			-- turn until facing either cobble or chest
			local cobbleInFront = false
			local chestInFront = false
			local blockType = ""
			for i = 1, 4 do
				if lib.isStorage("forward") then
					onChest = true
				end
				if blockType:find("cobble") ~= nil then
					onCobble = true
				end
				if onChest or onCobble then
					T:go("U1F1")
					break
				else
					T:turnRight(1)
				end
			end
		end
		if onCobble then -- if onCobble find chest
			-- check which direction cobble continues
			for i = 1, 4 do
				if turtle.forward() then -- no obstruction
					local blockType = T:getBlockType("down")
					if blockType:find("cobble") ~= nil then --continue this route
						break
					elseif lib.isStorage("down") then
						onChest = true
						break
					end
				else -- blocked ? tree/sapling
					local blockType = T:getBlockType("forward")
					if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
						-- next to tree/sapling, but not on chest, must be behind extended farm tree
						T:go("R2F9") -- turn round and continue forwards to first farm tree
						if lib.isStorage("down") then --stay here and exit loop
							onChest = true
							break
						end
					end
				end
				if not onChest then
					turtle.back()
					T:turnLeft(1)
				end
			end
			if not onChest then -- still on cobble, facing wall length
				-- move forward until cobble runs out-- will be over retaining wall, or on chest
				while T:getBlockType("down"):find("cobble") ~= nil do
					if not turtle.forward() then -- movement obstructed, must be tree/sapling
						local blockType = T:getBlockType("forward")
						if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
							-- next to tree/sapling, but not on chest, must be behind extended farm
							T:go("R2F9") -- turn round and continue forwards
							if lib.isStorage("down") then --stay here and exit loop
								onChest = true
								break
							end
						end
					end
				end
				-- moved over last of cobble without obstruction = outside farm
				-- no longer on cobble, could be a chest
				if lib.isStorage("down") then
					onChest = true
				else
					-- turn round and continue back along cobble until reach other end
					T:go("R2")
					while T:getBlockType("down"):find("cobble") ~= nil do
						if not turtle.forward() then -- movement obstructed, must be tree/sapling
							local blockType = T:getBlockType("forward")
							if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
								-- next to tree/sapling
								if lib.isStorage("down") then --stay here and exit loop
									onChest = true
									break
								end
							end
						end
					end
				end
			end
			-- cobble ended, over edge of wall, on tree base with no sapling, or on chest
		end
		
		if onChest then -- if onChest find water
			-- check if next block is a chest
			for i = 1, 4 do
				if turtle.forward() then -- no obstruction
					local blockType = T:getBlockType("down")
					if blockType == "minecraft:dirt" or blockType == "minecraft:grass_block" then -- on tree base
						turtle.back()
						break
					elseif lib.isStorage("down") then --stay here and exit loop
						onChest = true
						break
					end
				else -- blocked ? tree/sapling
					local blockType = T:getBlockType("forward")
					if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
						-- next to tree/sapling
						break
					end
				end
				turtle.back()
				T:turnLeft(1)
			end
			-- now on chest next to tree
			T:go("R1F1D1")
			blockType = T:getBlockType("down")
			if blockType:find("water") ~= nil then
				return lib.checkPosition()
			else -- no water so return to other side of chest
				T:go("R2U1F2D1")
				blockType = T:getBlockType("down")
				if blockType:find("water") ~= nil then
					return lib.checkPosition()
				end
			end
		end
			
		return success
	end
	
	function lib.gotoTree(logSlot)
		-- assume facing crops
		T:turnRight(1)
		print("Extracting saplings from storage")
		lib.getSaplings("forward") -- gets one sapling only (if present)
		print("Moving to tree position")
		T:go("U1F1R1")
		lib.harvestTree("forward") -- fell tree or plant sapling, ends facing tree / dirt / sapling. sticks already used for fuel. excess saplings placed
		
		if logSlot == 0 then -- no logs passed as parameter
			logSlot = T:getItemSlot("log")
		end
		if logSlot > 0 then -- has logs so needs to craft and refuel
			T:go("R1F1D1") -- return to base, facing buried storage
		else
			T:go("R1F1D1R1") -- return to base, facing crops
		end
		
		return logSlot
	end
	
	function lib.harvest(crop)
		--[[
		cover the field in a set pattern.
		harvest crops if ripe
		till soil and plant new ones
		place seeds / harvest in chests
		return farm(s) to right / front
		]]
		T:go("U1") --ready to farm field
		local isFarmToRight = false
		local isFarmToFront = false
		local width = 9
		local length = 10
		local toRight = true
		for l = 1, length do
			for w = 1, width do
				isReady, blockType, _ = lib.isCropReady("down")
				turtle.select(1)
				if blockType == "" and crop ~= "" then -- ? untilled soil or air above water
					turtle.digDown()
					turtle.digDown()
					lib.plantCrop(crop, "down")
				elseif isReady then
					if crop == "" then
						crop = lib.setCrop(blockType)
					end
					lib.plantCrop(blockType, "down")
				end
				T:forward(1)
				if l == 1 and w == width then -- last block of first row at front of farm
					T:forward(1)
					if lib.isStorage("down") then
						isFarmToRight = true
					end
					turtle.back()
				end
			end
			-- end of the row: change direction
			if l < length then -- do not turn at final row
				lib.plantCrop(crop, "down")
				if toRight then
					T:go("L1F1L1")
				else
					T:go("R1F1R1")
				end	
			end
			toRight = not toRight
		end
		T:go("R1F1") -- goes over chest/cobble on top wall
		if lib.isStorage("down") then
			isFarmToFront = true
		end
		T:go("R2F"..length.."D1L1") -- go straight across to seed chest 10 blocks, facing crops
		lib.storeCrops() -- rotates from start to deposit seeds and crops, ends facing crops
		return isFarmToRight, isFarmToFront
	end	
	
	function lib.harvestTree(direction)
		--[[
			start in front of / during tree harvest
			Check if sapling present
			Harvest tree if present, replant sapling
			Dispose of apples. Use sticks as fuel
			Return to base
		]]
		if turtle.getFuelLevel() < turtle.getFuelLimit() / 2 then -- only harvest tree if fuel < half max
			direction = direction or "forward"
			local inFront = T:getBlockType("forward")
			print("Checking tree")
			if inFront == "" then -- no tree or sapling
				print("No sapling: planting sapling")
				T:place("sapling", -1, "forward", false)
			elseif inFront:find("log") ~= nil or direction == "up" then -- tree above or in front
				-- clsTurtle.harvestTree(self, extend, craftChest, direction)
				print("Harvesting tree")
				T:harvestTree(false, false, direction) --do not investigate side branches in case chunk unloaded
				T:go("R2F1R2") -- face dirt
				-- place(self, blockType, damageNo, direction, leaveExisting, signText)
				T:place("sapling", -1, "forward", false)
			end
			print("Dropping saplings into storage")
			T:dropItem("sapling", "down", 0) -- drop all saplings down into chest
			print("Disposing of apples")
			T:dropItem("apple", "up", 0) -- drop any apples
			local slot = T:getItemSlot("minecraft:stick") 
			if slot > 0 then -- use any sticks to refuel
				turtle.select(slot)
				turtle.refuel()
			end
		end
	end
	
	function lib.manageTree()
		--[[ starting position facing crops ]]
		local crop = ""
		local logSlot = T:getItemSlot("stick")
		if logSlot > 0 then
			turtle.select(logSlot)
			turtle.refuel()
		end
		logSlot = T:getItemSlot("log")
		local needsFuel = false
		
		if turtle.getFuelLevel() < turtle.getFuelLimit() / 2 then
			needsFuel = true
		end
		if needsFuel then
			print("Running Tree Manager")
			logSlot = lib.gotoTree(logSlot) -- check for sapling or harvest tree, retuns to start, ends facing buried barrel/chest if has logs, logSlot returned
		end
		if logSlot > 0 then
			if not needsFuel then 			-- logs already onboard, no tree harvest, so turn towards buried chest
				T:turnLeft(1)
			end
			T:go("F1") 						-- move to buried crafting chest
			lib.refuelWithLogs(logSlot) 	-- use any logs for fuel
			T:go("R2F1")					-- facing seed chest/barrel
		else
			T:turnRight(1) 					-- facing seed chest/barrel
		end
		
		crop = lib.getSeeds("forward") 		-- get 1 stack of beetroot / wheat seeds
		if crop == "" then
			print("No seeds available. Checking root veg")
			T:turnRight(1)					-- face crop chests
			crop = lib.getVeg("forward")	-- gets any carrots / potatoes
			T:turnRight(2)					-- face crops
		else
			T:turnLeft(1)					-- face crops
		end
		return crop
	end
	
	function lib.isCropReady(direction)
		local isReady = false
		local status = ""
		local blockType = ""
		local success = false
		local data = {}

		direction = direction or "forward"

		if direction == "down" then
			success, data = turtle.inspectDown()
		else
			success, data = turtle.inspect()
		end
		if success then
			blockType = data.name
			if data.name == "minecraft:carrots" then
				status = data.state.age.." / 7"
				if data.state.age == 7 then
					isReady = true
				end
			elseif data.name == "minecraft:potatoes" then
				status = data.state.age.." / 7"
				if data.state.age == 7 then
					isReady = true
				end
			elseif data.name == "minecraft:wheat" then
				status = data.state.age.." / 7"
				if data.state.age == 7 then
					isReady = true
				end
			elseif data.name == "minecraft:beetroots" then
				status = data.state.age.." / 3"
				if data.state.age == 3 then
					isReady = true
				end
			end
		end
		return isReady, blockType, status
	end

	function lib.isStorage(direction)
		blockType = T:getBlockType(direction)
		if blockType:find("barrel") ~= nil then
			return true, "barrel"
		elseif blockType:find("chest") ~= nil then
			return true, "chest"
		end
		
		return false, ""
	end
	
	function lib.plantCrop(crop, direction)
		local planted = false
		turtle.digDown() -- harvest existing and till soil
		if crop:find("potato") ~= nil then
			T:dropItem("poison", "up", 0)
		end
		planted = T:place("carrot", -1, direction)
		if not planted then
			planted = T:place("potato", -1, direction)
		end
		if not planted then
			planted = T:place("beetroot_seeds", -1, direction)
		end
		if not planted then
			planted = T:place("wheat_seeds", -1, direction)
		end
	end
	
	function lib.refuelWithLogs(logSlot)
		-- assume positioned in front of buried chest / barrel, saplings already dropped, apples dumped, sticks used as fuel
		print("Logs present: collecting crafting table")
		-- earlier versions used crafting table buried in the ground
		-- newer versions have a barrel or chest embedded in the ground, containing the crafting table
		print("Sorting Inventory")
		T:sortInventory()
		while T:suck("down") do end					-- empty out barrel/chest to find crafting table
		if T:getItemSlot("crafting") == 0 then
			print("Crafting table required in the ".. storageType.." below.\n\nAdd a crafting table and restart")
			error()
		end

		if T:equip("right", "minecraft:crafting_table") then -- swap equipment on right side
			for i = 1, 16 do						-- drop anything except logs down into barrel/chest/pit
				if T:getSlotContains(i):find("log") == nil then
					T:drop("down", i)
				else
					logSlot = i
				end
			end
			turtle.select(logSlot)
			turtle.transferTo(1)
			turtle.craft()							-- craft logs to planks
			logSlot = T:getItemSlot("planks")
			while logSlot > 0 do
				turtle.select(logSlot)
				turtle.refuel()
				logSlot = T:getItemSlot("planks")				
			end
							-- refuel using planks
			while T:suck("down") do end				-- recover items from storagebelow
			if not T:equip("right", "minecraft:diamond_hoe") then		-- re-equip
				T:equip("right", "minecraft:diamond_pickaxe")			
			end
			if T:dropItem("minecraft:crafting_table", "down") then
				turtle.refuel() -- use any sticks
			end
		else
			print("Unable to equip crafting table.\n\nCheck turtle inventory and chest or barrel below")
			error()
		end
	end
	
	function lib.returnToBack()
		--[[ move from farm at front back to starting farm ]]
		T:go("U1R1F11D1L1")
	end
	
	function lib.returnToLeft()
		--[[ move from farm on right back to starting farm ]]
		T:go("U1R2F11D1R2")
	end
	
	function lib.setCrop(blockType)
		if blockType:find("carrot") ~= nil then
			return "carrot"
		end
		if blockType:find("potato") ~= nil then
			return "potato"
		end
		if blockType:find("beetroot") ~= nil then
			return "beetroot"
		end
		if blockType:find("wheat") ~= nil then
			return "wheat"
		end
	end
	
	function lib.storeCrops()
		-- place crops and seeds into chests
		T:turnRight(1)
		if lib.isStorage("forward") then
			lib.storeSeeds("forward")
		end
		T:turnRight(1)
		if lib.isStorage("forward") then
			lib.storeVeg("forward")
		end
		T:turnRight(2) -- facing crops again
	end
	
	function lib.storeSeeds(direction)
		direction = direction or "forward"
		if lib.isStorage(direction) then -- chest exists
			if T:getItemSlot("minecraft:wheat_seeds") > 0 then
				if not T:dropItem("minecraft:wheat_seeds", direction, 0) then
					T:dropItem("minecraft:wheat_seeds", "up", 0)
				end -- drop all wheat seeds
			elseif T:getItemSlot("minecraft:beetroot_seeds") > 0 then
				if not T:dropItem("minecraft:beetroot_seeds", direction, 0) then-- drop all beetroot seeds
					T:dropItem("minecraft:beetroot_seeds", "up", 0)
				end
			end
		end
	end
	
	function lib.storeVeg(direction)
		direction = direction or "forward"
		T:dropItem("apple", "up", 0) -- drop all apples
		T:dropItem("poison", "up", 0) -- drop all poison potatoes
		if lib.isStorage(direction) then
			if not T:dropItem("carrot", direction, 0) then-- drop carrots
				--return false
			end
			T:dropItem("potato", direction, 0) -- drop potato
			T:dropItem("minecraft:wheat", direction, 0) -- drop all wheat
			T:dropItem("minecraft:beetroot", direction, 0) -- drop all beetroot
		end
	end
	
	function lib.watchFarm()
		--[[
		check status of crops in front of turtle.
		call lib.harvest when ripe
		return farm(s) found in front or to the right
		]]
		local isReady, crop, status = lib.isCropReady("forward")
		-- check state of crop in front. Harvest if ripe		
		while not isReady do
			isReady, crop, status = lib.isCropReady("forward")
			if not isReady then
				if crop == "" then
					print("No crops found in front")
					print("Plant seeds, carrots, potatoes")
					error()
				else
					print("Waiting for "..crop.." status: "..status)
				end
				sleep(60)
			end
		end
		print("Local crops ripe")
		
		return lib.manageTree() -- "" or collected seeds / root crops
	end
	
	--[[
		called from args on start, or from user choice
		farm already built, needs planting and/or harvesting
		needs both pickaxe and hoe
		may start in any position if chunk unloaded while running
	]]
	--local pp = utils.getPrettyPrint()
	
	local atHome = lib.checkPosition()-- facing crops, placed above water source
	if not atHome then
		if not lib.goHome() then -- try to find home
			return
			{
				"Unable to determine my position.\n",
				"Place me in the lower left corner",
				"over water, facing the crops with",
				"barrels or chests to my right and behind"
			}
		end
	end
	-- check equipment
	T:go("L1F1") -- over barrel
	local isStorage, storageType = lib.isStorage("down")
	if not isStorage then
		local message =
[["Farm upgrade required:
Previous designs had a crafting table
next to the water source.

 1. Place a barrel or chest under the turtle
    instead.
	
 2. Restart"
]]
		print(message)
		error()
	end
	-- must be storage below to get this far
	if lib.checkEquipment() then
		T:equip("right", "minecraft:diamond_hoe", 0) -- equip hoe and put crafting chest into inventory
		T:dropItem("crafting", "down")
		utils.goBack(1)
		T:turnRight(1)
	else
		return {"Unable to equip hoe."}
	end

	
	-- check if crops already planted
	local isReady, crop, status = lib.isCropReady("forward")
	if crop == "" then
		pp.itemColours = {colors.lightGray, colors.red, colors.orange, colors.brown}
		choices = {"wheat_seeds","beetroot_seeds", "carrot", "potato"}
		choice = menu.menu("Choose preferred crop", choices, pp, "Type number of your choice")
		crop = choices[choice]
		T:checkInventoryForItem({crop}, {95}, true, "Do not mix! add as many as you want")
	end

	while true do -- start infinite loop of watching crops, farming all modules
		if crop == "" then -- not already in inventory
			crop = lib.watchFarm() --waits if required, returns crop type when ripe
		end
		print("Beginning "..crop.." management")
		local isFarmToRight, isFarmToFront = lib.harvest(crop)
		if isFarmToRight then
			lib.farmToRight() -- no action if no farmToRight
			lib.returnToLeft() -- return home and continue with front
			isFarmToRight = false
		end
		
		if isFarmToFront then
			isFarmToRight = lib.farmInFront()
			if isFarmToRight then
				lib.farmToRight() -- no action if no farmToRight
				lib.returnToLeft() -- return home 
			end
			lib.returnToBack()
		end
		if not R.auto then -- not started from startup.lua
			T:go("L1F1")
			while T:suck("down") do end						-- recover items from storagebelow
			T:equip("right", "minecraft:crafting_table", 0) -- equip crafting_table 
			T:dropItem("diamond_hoe", "down") 				-- drop hoe into storage
			T:dropItem("crafting", "down") 					-- in case spare one picked by mistake
			utils.goBack(1)
			T:turnRight(1)
			return {"Crop management of all modules completed"}
		end
	end
	return {}
end

local function manageFarmSetup(R) -- 33
	local lib = {}
	
	function lib.disableAutostart()
		if fs.exists("start.txt") then
			fs.delete("start.txt")
		end
		if fs.exists("startup.lua") then
			fs.delete("startup.lua")
		end
	end
	
	function lib.enableAutostart()
		if not fs.exists("startup.lua") then
			local h = fs.open("startup.lua", "w")
			h.writeLine('function main()')
			h.writeLine('	if fs.exists("start.txt") then')
			h.writeLine('		local handle = fs.open("start.txt", "r")')
			h.writeLine('		local cmd = handle.readLine()')
			h.writeLine('		handle.close()')
			h.writeLine('		shell.run("tk.lua "..cmd)')
			h.writeLine('	end')
			h.writeLine('end')
			h.writeLine('main()')
			h.close()
		end
		local h = fs.open("start.txt", "w")
		if R.data == "farm" then
			h.writeLine('farm')
		end
		h.close()
		print("Startup files written")
	end
	
	T:clear()
	--local pp = utils.getPrettyPrint()
	local choices = {"Plant or harvest this farm complex"}
	local isManaged = fs.exists("start.txt")
	if isManaged then
		table.insert(choices, "Disable automatic farm management")
	else
		table.insert(choices, "Enable automatic farm management")
	end
	pp.itemColours = {colors.lime, colors.lightGray}
	local userChoice, modifier = menu.menu("Choose your option", choices, pp) -- 1 to 2
	if modifier == "q" then -- quit chosen
		return {"Player has quit"}
	end
	R.subChoice = userChoice
	if R.subChoice == 1 then -- harvest now
		R.silent = false
		R.data = "farm"
		R.auto = false
		return manageFarm(R)
	else -- enable/disable auto farm
		local line = menu.clear()
		if isManaged then
			local message = ( "This turtle has been configured to"..
							  "start automatically and run the farm"..
							  "management program.\n")
			line = menu.colourText(line, message, true, true)
			if menu.getBoolean("Do you want to disable this? (y/n)", line, colors.yellow, colors.black) then
				lib.disableAutostart()
			end
			return {"Autostart disabled. Reboot to activate"}
		else -- not managed
			local message = ( "~yellow~This turtle can be configured to be\n"..
							  "a dedicated farm manager.\n\n"..
							  "~lightGray~It will then start automatically and\n"..
							  "monitor the farm complex:\n\n"..
							  "~green~harvesting~yellow~ and ~lime~replanting ~yellow~continuously.\n")
			line = menu.colourText(line, message, true, true)
			if menu.getBoolean("Do you want to enable this? (y/n)", line + 2, colors.orange, colors.black) then
				lib.enableAutostart()
			else
				return {"Player cancelled operation"}
			end
			return {"Autostart enabled. Reboot to activate"}
		end
	end
	
	return {}
end

local function measure(R) -- 101
	-- measure height/ depth / length
	local lib = {}
	
	function lib.checkBlocks(R, blocks)
		local dimension = "height"
		local message = ""
		local measure = ""
		local doContinue = true
		if R.choice == 102 then
			dimension = "depth"
		elseif R.choice == 103 then
			dimension = "length"
		end
		blocks = blocks + 1
		if blocks > R.size then
			message = "Max "..dimension.." of "..R.size.." stopped measurement"
			measure = ""
			doContinue = false
		else
			measure = dimension.." measured: "..blocks.." blocks"
		end
		return doContinue, blocks, measure, message
	end
	
	local blocks = 1
	local method = ""
	local measure = ""
	local message = ""
	local doContinue = true
	if R.choice == 101 then				-- height
		if R.subChoice == 1 then		-- obstruction above
			method = "Method: Until obstruction above"
			while turtle.up() and doContinue do
				doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
			end
		elseif R.subChoice == 2 then	-- end of wall ahead
			method = "Method: Until no block detected ahead"
			while turtle.detect() and doContinue do
				if turtle.up() then
					doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
				else
					message = "Obstruction above stopped measurement"
					measure = ""
					doContinue = false
				end
			end
		elseif R.subChoice == 3 then	-- search for specific block min 3 characters
			method = "Method:Until search: '"..R.data.."' met"
			while turtle.detect() and doContinue do
				if turtle.up() then
					doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
					if doContinue then
						local blockType = T:getBlockType("forward")
						if blockType:find(R.data) ~= nil then
							measure = "Height measured: "..blocks.." blocks"
							message = "Found "..blockType
							doContinue = false
						end
					end
				else
					message = "Obstruction above stopped measurement"
					measure = ""
					doContinue = false
				end
			end
		end
		
		for i = 1, blocks do
			turtle.down()
		end
	elseif R.choice == 102 then	-- depth
		T:go("F1R2D1") -- go off the edge and face cliff/pit wall
		blocks = blocks + 1
		if R.subChoice == 1 then		-- obstruction water / lava below
			local move = true
			while move do
				local blockType = T:getBlockType("down")
				if blockType:find("water") ~= nil or blockType:find("lava") ~= nil then
					message1 = blockType.." found at "..blocks
					move = false
				else
					move = turtle.down()
					if move then
						blocks = blocks + 1
					else
						measure = "Depth measured: "..blocks.." blocks"
					end
				end
			end
			method = "Method: Until obstruction below"
		elseif R.subChoice == 2 then	-- end of wall in front`
			while turtle.detect() do
				if turtle.down() then
					blocks = blocks + 1
					measure = "Depth measured: "..blocks.." blocks"
				else
					message1 = "Obstruction below stopped measurement"
					break
				end
			end
			method = "Method: Until no block detected ahead"
		elseif R.subChoice == 3 then	-- specific block detected ahead
			method = "Method:Until search: '"..R.data.."' met"
			while turtle.detect() do
				if turtle.down() then
					blocks = blocks + 1
					local blockType = T:getBlockType("forward")
					if blockType:find(R.data) ~= nil then
						measure = "Depth measured: "..blocks.." blocks"
						message = "Found "..blockType
						break
					end
				else
					message = "Obstruction below stopped measurement"
					break
				end
			end
		end
		for i = 1, blocks do
			turtle.up()
		end
		T:go("F1R2")
	elseif R.choice == 103 then	-- length
		if R.subChoice == 1 then		-- obstruction ahead
			method = "Method: Until obstruction ahead"
			while turtle.forward() and doContinue  do
				doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
			end
		elseif R.subChoice == 2 then	-- end of ceiling above
			method = "Method: Until no block detected above"
			while turtle.detectUp() and doContinue do
				if turtle.forward() then
					doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
				else
					message = "Obstruction ahead stopped measurement"
					measure = ""
					doContinue = false
				end
			end
		elseif R.subChoice == 3 then	-- end of floor below
			method = "Method: Until no block detected below"
			while turtle.detectDown() and doContinue do
				if turtle.forward() then
					doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
				else
					message = "Obstruction ahead stopped measurement"
					measure = ""
					doContinue = false
				end
			end
		elseif R.subChoice == 4 then	-- search for specific block up min 3 characters
			method = "Method:Until search: '"..R.data.."' above met"
			while turtle.detectUp() and doContinue do
				if turtle.forward() then
					doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
					if doContinue then
						local blockType = T:getBlockType("up")
						if blockType:find(R.data) ~= nil then
							message = "Found "..blockType
							measure = "Length measured: "..blocks.." blocks"
							doContinue = false
						end
					end
				else
					message = "Obstruction ahead stopped measurement"
					measure = ""
					doContinue = false
				end
			end
		elseif R.subChoice == 5 then	-- search for specific block down min 3 characters
			method = "Method:Until search: '"..R.data.."' below met"
			--while turtle.detectDown() and doContinue do
			while doContinue do
				if turtle.forward() then
					doContinue, blocks, measure, message = lib.checkBlocks(R, blocks)
					if doContinue then
						local blockType = T:getBlockType("down")
						if blockType:find(R.data) ~= nil then
							message = "Found "..blockType
							measure = "Length measured: "..blocks.." blocks"
							doContinue = false
						end
					end
				else
					message = "Obstruction ahead stopped measurement"
					measure = ""
					doContinue = false
				end
			end
		end
		T:turnRight(2)	-- head home
		for i = 1, blocks do
			turtle.forward()
		end
		T:turnRight(2)
	elseif R.choice == 104 then	-- depth of stretch of water
		--R.length = 0 to auto calculate
		R.width = 1
		R.silent = true
		R.useBlockType = ""
		R.data = "clearWaterPlants"
		local data = clearWaterPlants(R)
		R.height = data[1]
		local length = data[2]
		T:go ("R2F"..length - 1 .."R2U1")
		return {"Greatest depth measured: ".. R.height,"Width of water: "..R.length}
	end
	if message == "" then
		return{method, measure}
	else
		return{method, measure, message}
	end
end

local function mineBedrockArea(R) -- 19
	--[[ 
	Assume on level 5 or -59
	for 1, width do
		for 1, length do
			go down until bedrock, digging/replacing all directions
			return to 5 / -59
			move forward 1 blocks
		end
		turn right/ forward 2 turn right
	end
	]]	
	local lib = {}
	
	function lib.clearColumn(R)
		local level = 0
		--T:go("L1x1R2x1L1")
		local success = T:down(1)
		while success do
			level = level + 1
			if R.data == "leaveExposed" then
				T:go("R1x1R1x1R1x1R1x1", false, 0, true)
			else
				T:go("R1C1R1C1R1C1R1C1", false, 0, true)
			end
			success = T:down(1)
		end
		if R.data == "leaveExposed" then
			T:go("U"..level)
		else
			T:go("U"..level.."C2")
		end
	end
	
	local goRight = true
	for i = 1, R.width do
		for j = 1, R.length do
			lib.clearColumn(R)
			T:forward(1)
		end
		if goRight then
			T:go("R1F1R1")
		else
			T:go("L1F1L1")
		end
		goRight = not goRight
	end
	return {}
end

local function oceanMonumentColumns(R)
	-- utility to find corners and build columns to surface
	local lib = {}
	
	function lib.buildColumn()
		local depth = 0
		while T:isWater("forward") do
			T:go("U1C2")
			depth = depth + 1
		end
		return depth
	end
	
	function lib.buildTower()
		T:go("F1C2 F1C2 F1C2")
		T:go("L1F1 L1C2 F1C2 F1C2 F1C2")
		T:go("R1F1 R1C2 F1C2 F1C2 F1C2")
		T:go("L1F1 L1C2 F1C2 F1C2 F1C2")
		
		T:go("R2")
		for i = 1, 4 do
			T:go("U1C2")
			for j = 1, 4 do
				T:go("F1C2 F1C2 F1C2 R1")
			end
		end
	end
	
	R.silent = true
	local blockType = T:getBlockType("down")
	while blockType:find("water") == nil do
		T:down(1) -- if on a platform will break through
		blockType = T:getBlockType("down")
	end
	--R.useBlockType = "prismarine", R.data = "oceanMonumentColumns" from getTask
	--local tempData = R.data
	--R.data = "clearWaterPlants"
	local result = clearWaterPlants(R)[1]
	if result ~= "" then
		return {result}
	else
		--on corner of monument, facing out to ocean
		local depth = lib.buildColumn()
		-- now above surface, block below at surface level
		for i = 1, 4 do
			T:turnRight(1)
			R.length = 57
			utils.createPath(R) -- roughly at next corner
			if i < 4 then
				T:down(depth-2) -- roughly at correct depth
				local waterBelow = utils.clearVegetation("down")
				while waterBelow do
					T:down(1)
					waterBelow = utils.clearVegetation("down")
				end
				blockType = T:getBlockType("down")
				while blockType:find("prismarine") ~= nil do
					T:forward(1)
					blockType = T:getBlockType("down")
				end
				turtle.back()
				depth = lib.buildColumn()
			end
		end
		-- completed retaining paths. Build small tower for easy access
		lib.buildTower()
	end
	
	return {}
end

local function placeRedstoneTorch(R) -- 91, 92
	local moves = 2
	local blockType = T:getBlockType("down")
	if R.data == "level" then
		T:turnLeft(1)
		utils.goBack(1)
		if blockType:find("rail") ~= nil then
			 moves = 3
		end
		T:down(moves)
		T:go("F1R1")
		--clsTurtle.place(self, blockType, damageNo, direction, leaveExisting)
		T:place(R.useBlockType, -1, "forward", false)
		utils.goBack(1)
		T:place("minecraft:redstone_torch", -1, "forward", true)
		T:turnLeft(1)
		utils.goBack(1)
		T:up(moves)
		T:go("F1R1F1")
	elseif R.data == "up" then -- sloping rail up/down is relative to dirtection facing
		moves = 3
		T:turnLeft(1)
		utils.goBack(1)
		if blockType:find("rail") ~= nil then
			 moves = 4
		end
		T:down(moves)
		T:go("F1L1")
		T:place("minecraft:redstone_torch", -1, "up", false)
		
		T:turnRight(1)
		utils.goBack(1)
		T:up(moves)
		T:go("F1R1")
	end
	return {}
end

local function plantTreefarm(R) -- 23
	--T:place(blockType, damageNo, direction, leaveExisting, signText)
	local lib = {}
	
	function lib.checkSaplings(saplings, firstChoice, secondChoice)
		local saplingSlot, sapling, count = T:getSaplingSlot(firstChoice)
		if count < 4  and secondChoice ~= "" then
			saplingSlot, sapling, count = T:getSaplingSlot(secondChoice)
		end
		if count == 0 then
			sapling = ""
		end
		
		return sapling, count
	end
	
	function lib.getSaplingInventory()
		local saplings = {}
		saplings.oak_sapling = 0
		saplings.spruce_sapling = 0
		saplings.birch_sapling = 0
		saplings.jungle_sapling = 0
		saplings.acacia_sapling = 0
		saplings.dark_oak_sapling = 0

		local firstChoice = ""
		local firstCount = 0
		local secondChoice  = ""
		local secondCount = 0
		for i = 1, 16 do
			if turtle.getItemCount(i) > 0 then
				local data = turtle.getItemDetail(i)
				if data.name:find("sapling") ~= nil then
					local name = data.name:sub(11) -- removes "minecraft:"
					saplings[name] = saplings[name] + data.count
				end
			end
		end
		
		for sapling, count in pairs(saplings) do
			if count > firstCount then
				firstCount = count
				firstChoice = sapling
			else
				if count > secondCount then
					secondCount = count
					secondChoice = sapling
				end
			end
		end
		return saplings, firstChoice, secondChoice -- table, "oak_sapling", "dark_oak_sapling"
	end
	
	function lib.createIsland(sapling, count, exit)
		-- place 4 dirt with saplings on all 4 unless jungle
		-- sapling count/type already checked
		T:forward(2) -- assume starting outside planting area
		for i = 1, 4 do
			T:go("R1F1")
			T:place("dirt", -1, "down", false)
		end
		T:up(1)
		if count >= 4 then
			for i = 1, 4 do
				T:go("R1F1")
				T:place(sapling, -1, "down", false)
			end
		else
			if sapling:find("dark") == nil and sapling ~= "" then
				T:place(sapling, -1, "down", false)
			end
		end
		if exit == "forward" then
			T:go("F1D1")
		elseif exit == "right" then
			T:go("R1F2D1")
		elseif exit == "left" then
			T:go("L1F1D1")
		elseif exit == "back" then
			T:go("R2F2D1")
		end
	end
	
	function lib.createSingle(sapling, exit)
		-- place single dirt with sapling on top
		-- sapling count/type already checked
		T:place("dirt", -1, "down", false)
		T:up(1)
		if not T:place(sapling, -1, "down", false) then -- try specific sapling
			T:place("sapling", -1, "down", false)		-- any available sapling
		end
		if exit == "forward" then
			T:go("F1D1")
		elseif exit == "right" then
			T:go("R1F1D1")
		elseif exit == "left" then
			T:go("L1F1D1")
		elseif exit == "back" then
			T:go("R2F1D1")
		end
	end

	local saplings, firstChoice, secondChoice = lib.getSaplingInventory()

	if firstChoice ~= "" then
		print("first sapling choice: "..firstChoice .. " ("..saplings[firstChoice]..")")
	end
	if secondChoice ~= "" then
		print("second sapling choice: "..secondChoice .. " ("..saplings[secondChoice]..")")
	end

	-- check type/size of farm
	if R.subChoice == 1 then -- 16 single trees
		local sapling, count = lib.checkSaplings(saplings, firstChoice, secondChoice)
		T:go("U1F4") -- outside first area
		for i = 1, 3 do	-- column 1/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		for i = 1, 2 do
			lib.createSingle(sapling, "right") -- place 4th dirt/saling and exit to right
			T:forward(1)
		end
		for i = 1, 2 do -- column 2/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		for i = 1, 2 do
			lib.createSingle(sapling, "left") -- place 4th dirt/saling and exit to right
			T:forward(1)
		end
		for i = 1, 2 do -- column 3/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		for i = 1, 2 do
			lib.createSingle(sapling, "right") -- place 4th dirt/saling and exit to right
			T:forward(1)
		end
		for i = 1, 3 do -- column 4/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		T:go("R1F6L1F2R2D1")	
	elseif R.subChoice == 2 then -- 4 double trees (4 saplings)
		-- assume placed 4 blocks from start
		local sapling, count = lib.checkSaplings(mostName, secondMostName)
		
		if count >= 4 then
			T:go("U1F3") -- outside first area
			lib.createIsland(sapling, count, "forward")
			sapling, count = lib.checkSaplings(mostName, secondMostName)
			T:go("F2")
			lib.createIsland(sapling, count, "right")
			sapling, count = lib.checkSaplings(mostName, secondMostName)
			T:go("F2")
			lib.createIsland(sapling, count,  "right")
			sapling, count = lib.checkSaplings(mostName, secondMostName)
			T:go("F2")
			lib.createIsland(sapling, count, "forward")
			T:go("R1D1F6L1F3R2") -- outside first area
		else
			return {"Insufficient saplings to plant"}
		end
	end
	return {}
end

local function quickMine(R) -- 17
	--[[
	mine valuable blocks from specified area
	if R.up set or lava/water found, ceiling is formed
	if R.down is set, or lava/water found layer is kept 1 block high
	R.subChoice
	1 At mine area start, on the floor
	2 At mine area start, on the ceiling
	3 On floor, start 1 block ahead
	4 On ceiling, start 1 block ahead
	5 On floor diagonally to left"
	]]
	local lib = {}
	
	function lib.refuel(direction)
		if T:place("minecraft:bucket", -1, direction) then
			T:refuel(1000, false)
		end
	end
	
	function lib.mine(R)
		-- starts on ceiling
		local isValuable, blockType
		for i = 1, R.length do
			local fillUp = R.up
			local fillDown = R.down
			isValuable, blockType = T:isValuable("down")
			if isValuable then
				T:dig("down")
			elseif blockType:find("water") ~= nil then
				fillDown = true
			elseif blockType:find("lava") ~= nil then
				lib.refuel("down")
				fillDown = true
			end
			isValuable, blockType = T:isValuable("up")
			if isValuable then
				T:dig("up")
			elseif blockType:find("water") ~= nil then
				fillUp = true
			elseif blockType:find("lava") ~= nil then
				lib.refuel("up")
				fillUp = true
			end
			--if not turtle.detectUp() and fillUp then
			if fillUp then
				T:fillVoid("up")
			end
			--if not turtle.detectDown() and fillDown then
			if fillDown then
				T:fillVoid("down")
			end
			if i < R.length then 
				T:forward(1)
			end
		end
	end
	
	local outbound = true
	
	if R.subChoice == 1 then
		T:up(1)
	elseif R.subChoice == 3 then
		T:go("U1F1")
	elseif R.subChoice == 4 then
		T:go("F1")
	elseif R.subChoice == 5 then
		T:go("U1R1 F1L1 F1")
	end
	
	for w = 1, R.width do
		lib.mine(R)
		if w < R.width then
			if outbound then
				T:go("R1F1R1")
			else
				T:go("L1F1L1")
			end
			outbound = not outbound
		end
		if T:getFirstEmptySlot() == 0 then
			T:dumpRefuse("forward", 1)
		end
	end
	if outbound then
		T:go("L1F"..R.width - 1 .."L1F"..R.length - 1)
	else
		T:go("R1F"..R.width - 1 .."R1")
	end
	
	return {}
end

local function quickMineCorridor(R) -- 16
	--[[
	R.subChoice
	1: At corridor start, on the floor
	2: At corridor start, on the ceiling
	3: On floor, start 1 block ahead
	4: On ceiling, start 1 block ahead
	]]
	if R.subChoice == 2 then
		T:down(1)
	elseif R.subChoice == 3 then
		T:forward(1)
	elseif R.subChoice == 4 then
		T:go("D1F1")
	end
	local width = R.width - 1
	local length = R.length - 1
	R.silent = true
	R.length = length
	createCorridor(R, true) -- put floor and ceiling for R.length, place torch at start
	T:turnRight(1)
	R.length = width
	createCorridor(R, true)
	T:turnRight(1)
	R.length = length
	createCorridor(R, true)
	T:turnRight(1)
	R.length = width
	createCorridor(R, true)
	T:turnRight(1)
	
	return {}
end

local function repairWall(startAt, height, width, replaceWith)
	-- go up to startAt
	
	-- if width = 1
	
		-- for h = startAt, height, 1 do
		
			-- replace block with replaceWith ("" = any)
			
			-- move up
			
		--end
		
		-- move back to beginning
		
	-- else
	
		-- remain = height % 2
		
		-- for w = 1, width - remain do
		
			-- for h = startAt, height, 1 do
			
				-- replace block with replaceWith ("" = any)
				
				-- move up
				
			--end
			
			-- move to the right 1 block
			
			-- for i = height, startAt, -1 do
			
				-- replace block with replaceWith ("" = any)
				
				-- move down
				
			--end
			
		-- end
		
	-- end
	
end

local function getTaskItemsList()
	-- list of items required for each task
	local text = {}
	--MINING
	text[11] = {"1 ladder for each level","levels / 4 torch (optional)","levels * 4 stone"}				-- ladder to bedrock
	text[12] = {"2 stairs for each level", "6 * levels stone", "1 chest"} 								-- stairs up/down
	text[13] = {"24 torch (optional)", "1 bucket (optional)", "64 stone", "1 chest"} 					-- mine at this level
	text[14] = {"levels * 4 stone","water_bucket"} 														-- safe drop to water block
	text[15] = {"levels * 4 stone", "1 soul sand", "1 water bucket"} 									-- single column bubble lift
	text[16] = {"1 bucket (optional)", "64 stone"} 														-- quick corridor
	text[17] = {"1 bucket (optional)", "64 stone"}														-- quick mine
	text[18] = {"1 bucket (optional)"}																	-- mine to bedrock
	text[19] = {"1 UNUSED diamond sword (optional)"}													-- rob mineshaft

	-- FORESTRY
	text[21] = {"1 chest (optional)"}																	-- Fell Tree
	text[22] = {"320 stone", "4 polished stone"} 														-- Create treefarm
	text[23] = {"min 4 saplings", "16 dirt"} 															-- plant treefarm
	text[24] = {"No items required"} 																	-- Harvest treefarm
	text[25] = {"width * length * 2 walls or fences", "torches (optional)", "4 barrels (optional)"}		-- fence or wall a forest
	text[26] = {"1 chest", " any saplings"} 															-- harvest and replant walled rectangle of natural forest
				
	-- FARMING			
	text[31] = {"64 stone","128 dirt (optional)", "4 water buckets","4 chests / barrels","1 sapling"}	-- Create modular crop farm
	text[32] = {"64 stone","128 dirt (optional)", "4 water buckets","5 chests/ barrels","1 sapling"}	-- extend modular farm
	text[33] = {"No items required"} 																	-- Manual harvest and auto setup
	text[34] = {"Walls or Fences", "Torches (optional)"}												-- Build a wall or fence
	text[35] = text[34]																					-- Wall or fence enclosed area

	-- OBSIDIAN
	text[41] = {"stone to cover area of obsidian"}														-- Harvest obsidian
	text[42] = {"2 x height + width obsidian", "4 stone"} 												-- build Nether portal
	text[43] = {"No items required"}																	-- demolish Nether portal
	text[44] = {"84 stone"} 																			-- undermine dragon towers
	text[45] = {"No items required"} 																	-- deactivate dragon tower
	text[46] = {"448 stone, 145 ladders, 1 obsidian, 1 water bucket"} 									-- dragon water trap
	text[47] = {"height * 4 stone","height * ladders", "1 trapdoor"}									-- build end portal platform
				
	--CANALS BRIDGES WALKWAYS
	text[51] = {"dirt or stone * length","torch (optional)"} 											-- single path
	text[52] = {"dirt or stone 2 * length","torch (optional)"} 											-- covered path / tunnel
	text[53] = {"2 * length stone or dirt","2 water buckets","torches (optional)"} 						-- water canal
	text[54] = {"0.5 * length Packed or blue ice","length * slabs","stone","torches (optional)"} 		-- Ice canal
	text[55] = {"width * length stone"} 																-- platform
	text[56] = {"width + 1 * length + 1 stone"} 														-- sinking platform
	text[57] = {"height * 10 stone","height * 4 + 2 soul sand, 2 water buckets"} 						-- Boat bubble lift
	
	-- MOB FARM
	text[61] = {"512 stone","1 slab"} 																	-- 9x9 cube round spawner
	text[62] = {"640 stone","37 slab","8 powered rail","64 rail","2 redstone torch",
				"1 hopper minecart","1 stone button"} 													-- 9x9 cube round blaze spawner
	text[63] = {"2 water buckets","If using bubble lift","2 fence","2 signs","1 slab",
				"1 soul sand (or dirt as placeholder)"} 												-- flood spawner chamber	
	text[64] = {"128 stone","2 water buckets","1 soul sand"} 											--Build bubble tower kill zone
	text[65] = {"1-2 computer","2 sticky or 4 normal pistons","6 network cable + 2 wired modems",
				"23 polished stone + 7 slabs","2 glass","1 stone pressure plate","1 dispenser",
				"1 hopper + 2 chest", "9 redstone", "1 lava bucket"} 									--Computercraft mob grinder
	text[66] = {"1856 stone, diorite etc (inc polished)","1 chest","10 empty buckets",
				"2 water buckets","192 fence","8 signs","3 ladder","2 soul sand"} 						-- build endermen observation tower
				
	-- AREA CARVING
	text[71] = {"width * length dirt"} 																	-- Clear field
	text[72] = {"No items required"} 																	-- Clear rectangle width, length
	text[73] = {"No items required"} 																	-- Clear wall height, length
	text[74] = {"No items required"} 																	-- Clear rectangle perimeter only width, length
	text[75] = {"No items required"}																	-- Clear structure floor/walls/ceiling
	text[76] = {"No items required"}																	-- clear solid
	text[77] = {"No items required"} 																	-- Dig a trench
	text[78] = {"No items required"} 																	-- carve mountain
	text[79] = {"width * height Any material floor / ceiling"} 											-- floor or ceiling
	text[710] =	{"Blocks to add 'floor as you go'"} 													-- Direct control of movement
				
	-- LAVA WATER
	text[81] = {"Enough sand or gravel to fill volume"} 												-- sand based utilities
	text[82] = {"length * depth stone"} 																-- vertical wall from surface
	text[83] = {"Blocks to add 'floor as you go'"} 														-- player driven path construction
	text[84] = {"width * length + extra stone"} 														-- water clearing by repeated block deletion
	text[85] = text[84] 																				-- sinking platform
	text[86] = {"Full inventories of sand or stone"}													-- Ocean monument utilities
	text[87] = {"ladder to height","stone, dirt netherrack 4 X height"} 								-- ladder to water/lava
	text[88] = {"No items required"} 																	-- clear water plants
	text[89] = {"water buckets / buckets"} 																-- convert flowing water to source
	text[810] = {"6 buckets","slabs to cover area"} 													-- create sloping water
				
	-- BUILDING and MINECART
	text[91] = {"length * height stone"}																-- Build a wall
	text[92] = {"length * height * 4 stone"}															-- build a walled area
	text[93] = {"length * width * height stairs", "length * slabs"}										-- build a gable roof
	text[94] = {"length * width * height stairs", "length * slabs"}										-- Build a pitched roof
	text[95] = {"1 block of choice","1 redstone torch"} 												-- place redstone torch under current block
	text[96] = {"1 block of choice","1 redstone torch"} 												-- place redstone torch on upward slope
	text[97] = {"height x block of choice","height/3 x redstone torch"} 								-- build downward slope
	text[98] = text[97]																					-- build upward slope
	return text
end

local function getTaskHelp(menuLevel, menuItem, noMenu, getInteger)
	-- display help about selected task
	-- terminal size = 39 x 13
--[[This line of text = 39 characters]]
	noMenu = noMenu or false
	getInteger = getInteger or false
	info = {}
	info.main = {}
	info.sub = {}
	table.insert(info.main,
	[[                ~lightGray~MINING:~white~
Can be used in over-world or nether.~brown~
Ladders and ~lightGray~stairs up/down    
Create a pre-formatted 33 x 33 blocks  
mine at chosen level.
~blue~Bubble lift and ~cyan~safe drop to water.~magenta~  
Faster version of ~white~33x33 mine pattern   
using ~magenta~corridor and ~pink~rectangle functions.~brown~
Mine bottom layer to bedrock (not worth
the fuel and time)
~brown~Strip resources from abandoned mines.
]])
	table.insert(info.main,
	[[               ~lime~FORESTRY:~brown~
Fell Tree can be used in Nether as well
for cutting any size tree / branches~lime~
Create a simple 16 single tree farm
or 4 double size (Dark oak or any type)
suitable for turtle harvesting.
~brown~ fence or wall a rectangle keeping
to contours.
~green~Forest can be harvested and replanted.
(Must be walled off)

]])
	table.insert(info.main,
	[[                ~green~FARMING:~yellow~
Farm modules can be built to fixed size
and placed next to each other in linear
or rectangular pattern.~lime~
Whole farm is managed by a dedicated
turtle, which must be equipped with a
diamond hoe as well as pickaxe.
Fuel obtained from a tree placed in the
corner of each module.
Double chests store produce and seeds.
]])
	table.insert(info.main,
	[[               ~red~OBSIDIAN:~lightGray~
The turtle can extract obsidian from
lava areas safely.~pink~
Nether portals can be built or removed
without needing diamond pickaxes.~orange~
End World dragon towers can be
undermined ready for deactivating.
End world towers can have the crystals
destroyed.~red~
Water trapped dragon attacked from above~brown~
Minecart end portal stations built.
]])
	table.insert(info.main,
	[[        ~brown~PATHS, BRIDGES, CANALS:~white~
Can be used in Nether and End.~lightGray~
Build pathways over air, water or lava
Optional roofed pathway for Nether use.
Tunnel through rock and place a floor
at the same time.~blue~
Build a water canal with towpath.~cyan~
Build a super-fast ice canal.~brown~
Platform for use over air, water, lava
Sinking version is removed and replaced
1 block lower each time
]])
	table.insert(info.main,
	[[             ~lightGray~SPAWNER FARMS:~brown~
Tools to create mob farms round
existing spawners. ~red~
Special version for Blaze farms
uses rail collection.~cyan~
Choice of bubble lift mob dropper
or ~brown~simple deep trench.~gray~
Enderman observation tower can be
built >128 above ground: is ~red~expensive.~gray~
Re-spawns new mobs when used.~red~
Suggest build only the base.
]])
	table.insert(info.main,
	[[    ~orange~AREA CLEARING AND REFORMING:~lime~
Tools to clear a field including trees~magenta~
Clear rectangles.~pink~
Clear single walls.~brown~
Clear hollow and~orange~solid structures.~brown~
Dig a trench.~gray~
Carve away side of a mountain.~lightBlue~
Place or replace floors and ceilings



]])
	table.insert(info.main,
	[[      ~blue~WATER AND LAVA TOOLS:~white~
Used to drain ocean monuments and
shipwrecks. Can also be used to make
underwater base. ~blue~Water is cleared using
sand dropping and recycling~cyan~
Destructive draining uses solid block
placing and recycling.~green~
Water plants can be removed without
damaging structures.~lightBlue~
Tools to manipulate water areas:
(convert to source, sloping water)
]])
	table.insert(info.main,
	[[         ~cyan~BUILDING, MINECART TOOLS:~lightGray~
Build simple walls, buildings and ~gray~roofs

~orange~Used to build diagonal uphill slope~brown~
and downhill slope for placing
45 degree rail tracks.~red~
Placing Redstone torches under powered
rails when above ground level (viaduct)



]])
	table.insert(info.main,
	[[           ~yellow~MEASURING TOOLS:
Used to measure
    ~red~Height
    ~purple~Depth
    ~magenta~Length~pink~
	
    Greatest depth of water




]])

	info.sub[11] = 
[[~yellow~Place me on the ground at ~red~^~yellow~
The ~brown~ladder ~yellow~will start at this level
and go up or down.

~lightGray~| | | | | |
~lightGray~| | |*| | | * = Ladder support block
| | |~brown~L~lightGray~| | | ~brown~L = Ladder
~lightGray~| | |~red~^~lightGray~| | | ~red~^ = Turtle
~lightGray~| | | | | |
| | | | | |

]]-- Ladder up/down
	info.sub[12] = 
[[~lightGray~Place me on the ground at ~red~^

~lightGray~| | | | | | | | * = Solid block
~lightGray~| |*|*|*|*|*| | ~cyan~^ = Stairs to back
~lightGray~| |*|-|~cyan~>~lightGray~|-|*| | ~cyan~> = Stairs to right
~lightGray~| |*|~cyan~^|~lightGray~*|~cyan~V~lightGray~|*| | ~cyan~V = Stairs to front
~lightGray~| |*|-|~cyan~<~lightGray~|-|*| | ~cyan~< = Stairs to left
~lightGray~| |*|~red~^~lightGray~|*|*|*| | - = Corner tread
~lightGray~| | | | | | | | ~red~^ = Turtle

~lightGray~Going ~blue~down~lightGray~ -> digs down then stairs up
]] -- Stairs up/down
		info.sub[13] = 
[[~yellow~Press F3 to check Y level.

~lightGray~| |~red~^~lightGray~| | | ~red~^ = Turtle behind ladder
~lightGray~| |~gray~s~lightGray~| | | ~gray~s = 1 block space
~lightGray~| |*| | | * = Ladder support block
~lightGray~| |~brown~L~lightGray~| | | ~brown~L = Ladder
~lightGray~| |~brown~s~lightGray~| | | ~brown~s~gray~ = 2 spaces (inc. ladder)
~lightGray~| |~red~V~lightGray~| | | ~red~V = Turtle ahead of ladder~yellow~

]]
	if bedrock == 0 then	--pre 1.18
		info.sub[13] = info.sub[13].."Place at Y = 5, 8, 11 ~red~(11 nether)" -- Create mine at this level
	else
		info.sub[13] = info.sub[13].."Place at Y = -59, -56, -53 (11 nether)" -- Create mine at this level
	end
	info.sub[14] = 
[[~yellow~Turtle goes ~blue~DOWN ~yellow~to chosen level
enclosing all sides of the column.
Water placed at bottom. Returns here.
If next to a ladder, place as below:

~lightGray~| | | | | |
~lightGray~| | |*| | | * = Ladder support block
| |~red~^~brown~|L|~red~^~lightGray~| | ~brown~L = ladder
~lightGray~| | | | | | ~red~^ = Turtle facing forward
~lightGray~| | | | | |
		   
]] -- safe drop
	info.sub[15] = 
[[~magenta~Direction of travel = UP!
~yellow~Place me on the ground. I will build a
3 x 1 ~blue~water ~yellow~source and a single column
bubble lift to the chosen height.
If next to a ladder, place as below:

~lightGray~| | | | | | ~blue~B = Bubble column
~lightGray~| | |*| | | * = Ladder support block
| |~blue~B~brown~|L|~blue~B~lightGray~| | ~brown~L = ladder
~lightGray~| |~red~^~lightGray~| |~red~^~lightGray~| | ~red~^ = Turtle facing forward
~lightGray~| | | | | |

]] -- single column bubble lift
	info.sub[16] = 
[[~yellow~Place me as below:
 1. On ~blue~floor   ~yellow~(feet height)
 2. On ~lime~ceiling ~yellow~(eye height)

~lightGray~B|B|B|B|B|B|B    ~yellow~W I D T H
~lightGray~B| | | | | |B               ~orange~L
~lightGray~B| |B|B|B| |B               ~orange~E
~lightGray~B| |B|B|B| |B               ~orange~N
~lightGray~B| |B|B|B| |B               ~orange~G 
~lightGray~B|~red~^~lightGray~| | | | |B  ~red~^~lightGray~ = Turtle   ~orange~T
~lightGray~B|~cyan~P~lightGray~|B|B|B|B|B  ~cyan~P~lightGray~ = Player   ~orange~H
]] -- quick corridor system
	info.sub[17] = 
[[~yellow~~yellow~Place me as below:
 1. On ~blue~floor   ~yellow~(feet height)
 2. On ~lime~ceiling ~yellow~(eye height)
~lightGray~B|B|B|B|B|B|B 
B| | | | | |B
B| |B|B|B| |B
B| |B|B|B| |B
B| |~lime~^~lightGray~|B|B| |B
B|~red~^~lightGray~|~magenta~^~lightGray~| | | |B ~white~^~lightGray~ = turtle
B|~cyan~P~lightGray~|B|B|B|B|B ~cyan~P~lightGray~ = Player
~yellow~Note colour of ~white~^~yellow~ matches next screen->
]] -- quick mine
		info.sub[18] = 
[[~yellow~Place me level -59 / 5 on the floor to
expose bedrock ~red~(slow and inefficient)

~lightGray~| | | |B| |B|     ~yellow~W I D T H
~lightGray~|B| | | | | |B               ~orange~L
~lightGray~| | | |B|B| |                ~orange~E
~lightGray~| | |B| | |B|                ~orange~N
~lightGray~|B| | | |B| |                ~orange~G 
~lightGray~| | | | | | |B               ~orange~T
~lightGray~|~red~^~lightGray~| | | |B| |B  ~red~^~lightGray~ = Turtle   ~orange~H
]] -- mine all blocks to bedrock pre 1.12
		info.sub[19] = 
[[~yellow~Place me on the end wall of a disused
mine in the centre block, 1 block above
the floor.
Provide a ~cyan~diamond ~yellow~sword for
harvesting string from spider webs~lightGray~

~gray~-------   - = Ceiling
~lightGray~| | | |
| |~red~T~lightGray~| |  ~red~T = Turtle (facing wall)
~lightGray~| | | |
~gray~-------  - = Floor
]] -- salvage mineshaft
	info.sub[21] = 
[[~yellow~Place me as below.
~brown~Chest ~yellow~ONLY required if ~blue~0 ~yellow~fuel

Plan view:

~green~   | | | |
~green~   | |~lime~T~green~| |  ~lime~T = Tree
~green~   | |~red~^~green~| |  ~red~^ = Turtle
~green~   | | | |



]] -- Fell Tree
	info.sub[22] = 
[[~yellow~Place me on ground as below ~red~^
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | ~brown~|D| |D| 
~lime~|*|~blue~ | | ~brown~|D|D|~blue~ | ~green~or |*|~blue~ | | | | | |
~lime~|*|~blue~ | | ~brown~|D|D|~blue~ | ~green~or |*|~blue~ | | ~brown~|D| |D|
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | | | | |
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | | | | |
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | | | | |
~lime~|~red~^~lime~|*|*|*|~blue~M~lime~|*| | ~green~or |~red~^~green~|*|*|*|~blue~M~green~|*|*|
~lime~4 ~brown~double ~green~       or 16 ~brown~single
~brown~D = Dirt, ~red~^ = Turtle, ~blue~M = Marker stone
]] -- Create treefarm
	info.sub[23] = 
[[~yellow~Place me on ground as below ~red~^
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | ~brown~|D| |D| 
~lime~|*|~blue~ | | ~brown~|D|D|~blue~ | ~green~or |*|~blue~ | | | | | |
~lime~|*|~blue~ | | ~brown~|D|D|~blue~ | ~green~or |*|~blue~ | | ~brown~|D| |D|
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | | | | |
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | | | | |
~lime~|*|~blue~ | | | | | | ~green~or |*|~blue~ | | | | | |
~lime~|*|*|*|*|~red~^~lime~|*| | ~green~or |*|*|*|*|~red~^~green~|*|*|
~green~4 ~brown~double ~green~       or 16 ~brown~single
~brown~D = dirt,~red~^ = Turtle, ~yellow~Max 16 saplings
Mixed OK. ~lime~Group 4 for double trees
]] -- Plant treefarm / Harvest treefarm
	info.sub[24] = info.sub[23] 
	info.sub[25] =
[[~yellow~Place me at ~red~^

~lightGray~|F|F|F|F|F|F|F| F = Fence or Wall
~lightGray~|F|~brown~B~lime~| | | |~brown~B~lightGray~|F| ~brown~B = Barrel (corners)
~lightGray~|F|~lime~ | | | | ~lightGray~|F|
~lightGray~|F|~lime~ | | | |~cyan~T~lightGray~|F| ~cyan~T = Tree
~lightGray~|F|~lime~ |~cyan~T~lime~| | | ~lightGray~|F|
~lightGray~|F|~lime~ | | | | ~lightGray~|F|
~lightGray~|F|~brown~B~lime~| |~cyan~T~lime~| |~brown~B~lightGray~|F| 
~lightGray~|~red~^~lightGray~|F|F|F|F|F|F| ~red~^ = Turtle
~yellow~Fence/Wall follows land contours
]] -- 
	info.sub[26] =
[[~yellow~A rectangular walled area of forest:
Place me at ~red~^

~lightGray~|F|F|F|F|F|F|F| F = Fence or wall
~lightGray~|F|~brown~B~lime~| | | |~brown~B~lightGray~|F| ~brown~B = Barrel (corners)
~lightGray~|F|~lime~ | | | | ~lightGray~|F|
~lightGray~|F|~lime~ | | | |~cyan~T~lightGray~|F| ~cyan~T = Tree
~lightGray~|F|~lime~ |~cyan~T~lime~| | | ~lightGray~|F|
~lightGray~|F|~lime~ | | | | ~lightGray~|F|
~lightGray~|F|~red~^~lime~| |~cyan~T~lime~| |~brown~B~lightGray~|F| ~red~^ = Turtle ~brown~(on Barrel)
~lightGray~|F|F|F|F|F|F|F|

]] -- manage walled forest
	info.sub[31] = 
[[~yellow~Place me on the ground as below ~red~^

~lightGray~|*|~green~ | | | | | | | | ~lightGray~* = Wall
~lightGray~|*|~green~ | | | | | | | |
~lightGray~|*|~green~ | | | | | | | |
~lightGray~|*|~green~ | | | | | | | |
~lightGray~|*|~green~ | | | | | | | | 
~brown~|B|B~green~| | | | | | | | ~brown~B = Barrel or Chest
~brown~|B|~blue~W~green~| | | | | | | | ~blue~W = Water
~lime~|~red~^~lime~|~brown~B|B|~lightGray~*|*|*|*|*|*| ~red~^ = Turtle
~yellow~                    Size = 13 x 13
]] -- Create modular crop farm
	info.sub[32] = 
[[~yellow~Place next to the tree as below ~red~^

~lightGray~|*|~green~ | | | | | | | | ~lightGray~* = Wall
~lightGray~|*|~green~ | | | | | | | |
~lightGray~|*|~green~ | | | | | | | | 
~lightGray~|*|~green~ | | | | | | | | 
~lightGray~|*|~green~ | | | | | | | | ~brown~B = Barrel or Chest
~brown~|B|B~green~| | | | | | | | ~blue~W = Water
~brown~|B|~blue~W~green~| | | | | | | | ~orange~S = Sapling or Tree
~orange~|S|~red~^~brown~|B|~lightGray~*|*|*|*|*|*| ~red~^ = Turtle
~yellow~                    Size = 13 x 13
]] -- Extend farm
	info.sub[33] = 
[[~yellow~Place as below (2 choices) ~blue~> ~yellow~or ~red~<

~lightGray~|*|~green~ | | | | | | | | ~lightGray~* = Wall
~lightGray~|*|~green~ | | | | | | | |
~lightGray~|*|~green~ | | | | | | | | 
~lightGray~|*|~green~ | | | | | | | | ~brown~B = Barrel or Chest
~lightGray~|*|~green~ | | | | | | | | ~blue~> = turtle on Water
~brown~|B|B~green~| | | | | | | | C = Crop (first)
~brown~|B|~blue~>~green~|C| | | | | | | ~orange~S = Sapling or Tree
~orange~|S|~red~<~brown~|B|~lightGray~*|*|*|*|*|*| ~red~< = Turtle on Chest
~yellow~Options to harvest or manage to follow.
]] -- Manual harvest and auto setup
	info.sub[34] = 
[[~yellow~Build a ~brown~fence ~yellow~or ~lightGray~wall ~yellow~to chosen length.

Turtle goes ~orange~BACKWARDS ~yellow~when started.

Start: length = 6, Turtle facing right

~lightGray~| |~red~>~lightGray~| | | | | | | ~red~> = Turtle

Finish:

~lightGray~| |F|F|F|F|F|F| | F = Fence or Wall
]] -- build fence or wall
	info.sub[35] = 
[[~yellow~Build a ~brown~fence ~yellow~or ~lightGray~wall ~yellow~
rectangular area.

~lightGray~| | | | | | | | ~brown~F = Fence or Wall
~lightGray~| ~brown~|F|F|F|F|F~lightGray~| |
~lightGray~| ~brown~|F| | | |F~lightGray~| |
~lightGray~| ~brown~|F| | | |F~lightGray~| |
~lightGray~| ~brown~|F| | | |F~lightGray~| |
~lightGray~| |~red~^~brown~|F|F|F|F| | ~red~^ = Turtle
~lightGray~| | | | | | | |

]] -- build rectangular fence or wall
	info.sub[41] = 
[[~yellow~Place me on any block on the left 
side facing the obsidian field.

~gray~|O|O|O|O|O| O = Obsidian
|O|O|O|O|O|
|O|O|O|O|O|
|O|O|O|O|O|
|~red~^~gray~|O|O|O|O| ~red~^ = Turtle
|~red~^~gray~| | | | |

]] -- Harvest obsidian
	info.sub[42] = 
[[~yellow~Place me on the ground as below ~red~> ~pink~^
~yellow~Start ~red~> ~yellow~(facing right) or ~pink~^ ~yellow~ahead
  
~lightGray~| |~red~>~lightGray~|O|O|*| | |    |*|O|O|*| face view             
   ~pink~^~lightGray~               |O|~purple~+ +~lightGray~|O|
                   |O|~purple~+ +~lightGray~|O|
~yellow~Result (plan)      ~lightGray~|O|~purple~+ +~lightGray~|O|
~lightGray~| |O|O|O|O| | |    |*|O|O|*|
                   ~green~--------- ground
~yellow~width=4, ~orange~height=5
]] -- build Nether portal
	info.sub[43] = info.sub[42] -- Demolish Nether portal
	info.sub[44] = 
[[~yellow~Place me on the ground ~red~<~yellow~ facing ~red~West.

~lime~x
                 ~lightGray~N
~lime~a~lightGray~   -1        | | | |  
~lime~x~lightGray~    0       ~red~W~lightGray~| |~red~<~lightGray~| |E  ~red~< = Turtle
~lime~i~lightGray~    1        | | | |  
~lime~s~lightGray~                S
    ~green~z axis    ~lightGray~-1 0 1
  
Centre of the dragon arena ~lime~X = 0, ~green~Z = 0
~yellow~                           facing ~red~West 
]] -- Find dragon tower centres
	info.sub[45] = 
[[~yellow~Place turtle in ceiling facing endstone

Plan view    Side view
~gray~             |*|*|*|*|*|
    |*|      |*|*|*|*|*|
  |*|*|*|    |*|*|*|*|*|
|*|*|*|*|*|  |*|*|*|*|*|  * ~lightGray~= Obsidian
~gray~|*|*|~yellow~E~gray~|*|*|  |*|*|*|*|*|  ~yellow~E ~lightGray~= Endstone
~gray~  |*|~red~^~gray~|*|    |*|*|~red~T~gray~|*|*|~red~ ^T ~lightGray~= Turtle
~gray~    |*|      |*|*| |*|*|
             |*|*| |*|*|
]] -- deactivate dragon tower
	info.sub[46] = 
[[~yellow~Place turtle on the ground at 100,49,0

|*|*|*|*|*|*|*|*|*|  ~lightGray~Dragon Island



~gray~    |*|*|*|*|*|  * ~lightGray~= Obsidian platform
~gray~    |*|*|*|*|*|
    |*|*|~red~T~gray~|*|*|  ~red~T ~lightGray~= Turtle
~gray~    |*|*|*|*|*|
    |*|*|*|*|*|
]] -- build dragon water trap
	info.sub[47] = 
[[~yellow~Place turtle under end world portal

~gray~        |B|     B ~lightGray~= Bedrock
~gray~      |B|B|B|
        ~purple~|P|     P ~lightGray~= Portal
~gray~      |B|B|B|
        |B|
         ~green~|		
         ~green~|      ~lime~Height measured first		
         ~green~|		
~red~         T	     T ~lightGray~= Turtle	
~yellow~  |*|*|*|*|*|*| ~red~Inventory AFTER height
]] -- build end portal minecart

	info.sub[51] = 
[[~yellow~Place me on the ground as below ~red~^

~yellow~Start:~blue~  |-|-|-|    - = air/water
~orange~        |-|-|-|    - = lava
~blue~        |-|-|-|
~lightGray~        |*|~red~^~lightGray~|*|    ~red~^ = Turtle

~yellow~Result:~blue~ |-|~lightGray~*|~blue~-|    - = air/water
~orange~        |-|~lightGray~*|~orange~-|    - = lava
~blue~        |-|~lightGray~*|~blue~-|
~lightGray~        |*|*|*|    * = Solid block
]] -- Single path
	info.sub[52] = 
[[~yellow~Place ~red~^ T~yellow~ at start of path or tunnel

~yellow~Plan view    Face view

~lightGray~|*|~green~*~lightGray~|*|      *|*|*|*|*   ~green~* = new block
~lightGray~|*|~green~*~lightGray~|*|      *|*|~green~*~lightGray~|*|*
~lightGray~|*|~green~*~lightGray~|*|      *|*| |*|*
~lightGray~|*|~green~*~lightGray~|*|      *|*|~red~T~lightGray~|*|*   ~red~^ T = Turtle
   ~red~^~lightGray~         ~green~- - * - -   ground

~green~Floor + ceiling ~yellow~placed for your safety!
]] -- Covered walkway / tunnel
	info.sub[53] = 
[[~yellow~plan view    Cross section view

~lightGray~|*|~blue~-|-~lightGray~|*|
~lightGray~|*|~blue~-|-~lightGray~|*|
~lightGray~|*|~blue~-|-~lightGray~|*|     ~lime~1 ~orange~2 ~brown~3 ~green~4  ~lightGray~= on ground
~lightGray~|~lime~^~lightGray~|~blue~^~lightGray~|~cyan~^~lightGray~|~green~^~lightGray~|    |*|~blue~5~lightGray~|~cyan~6~lightGray~|*| ~lightGray~= in water

~yellow~New canal       ~lime~1 ~orange~2 ~brown~3 ~green~4 ~yellow~on ground
~yellow~Extend existing ~lime~1 ~green~4 ~blue~5 ~cyan~6
~yellow~Extend on ocean ~lime~1     ~green~4~yellow~ on solid block
]] -- new/existing canal
--[[This line of text = 39 characters]]
	info.sub[54] = 
[[~yellow~New ice canal or convert existing water

~lightGray~ |*| | |*| 	|*| = ~magenta~Slab* ~lightGray~or ~pink~Trapdoor*
~lightGray~ |~orange~T~lightGray~|~blue~I~lightGray~| |*| 	|~blue~I~lightGray~| = ~blue~Ice (packed or blue)
~lightGray~ |*| | |*| 	| | = Air (empty block)
~lightGray~ |*|~blue~I~lightGray~| |~orange~T~lightGray~|  |~orange~T~lightGray~| = ~orange~Torch (optional)
  ~lime~1 2 3 4   ~lightGray~Turtle position: ~lime~Towpath
    ~blue~5 ~lightGray~6     Turtle position: ~blue~Ice ~lightGray~Air

position ~lime~1 ~lightGray~moves to ~lime~2~lightGray~, ~lime~4 ~lightGray~moves to ~lime~3
~lightGray~Height=2 blocks ~pink~*=Trapdoor ~lightGray~>2 ~magenta~*=Slab
]] -- ice canal
	info.sub[55] = 
[[~yellow~Place ~red~^~yellow~ any level air, water or lava.~lightGray~

| | | | | | | |
| |*|*|*|*|*| |  * = Block
| |*|*|*|*|*| |
| |*|*|*|*|*| |
| |*|*|*|*|*| |
| |~red~^~lightGray~|*|*|*|*| |  ~red~^ = Turtle~lightGray~
| | | | | | | |

Blocks placed under the turtle
]] -- Platform
	info.sub[56] = 
[[~yellow~Place ~red~^~yellow~ above water.~lightGray~
Existing platform replaced below

| |*|*|*|*|*| |  * = Block
| |*|*|*|*|*| |
| |*|*|*|*|*| |
| |*|*|*|*|*| |
| |~red~^~lightGray~|*|*|*|*| |  ~red~^ = Turtle~lightGray~
| | | | | | | |

Blocks placed under the turtle
]] -- Sinking platform
	info.sub[57] = 
[[~yellow~Boat Lift (Ice or Water)
Place turtle left side. ~blue~Source~yellow~ to right

Start~lightGray~        |*|~blue~ | ~lightGray~|*| ~yellow~Finish
~lightGray~             |*|~blue~ | ~lightGray~|*|
             |*|~cyan~S|S|~lightGray~*| ~cyan~S ~lightGray~= Soul sand
|*|*|*|*|    |*|~brown~S|S~lightGray~|*| ~brown~S = ~lightGray~Sand + gate
|~red~^~lightGray~|~blue~W|W~lightGray~|*|    |*~blue~|W|W|~lightGray~*| ~red~^ ~lightGray~= Turtle
|*|~blue~W|W~lightGray~|*|    |*|~blue~W|W~lightGray~|*|
|*|~blue~ | ~lightGray~|*|    |*|~blue~ | ~lightGray~|*| ~yellow~Ice canal needs
~lightGray~|*|~blue~ | ~lightGray~|*|    |*|~blue~ | ~lightGray~|*| ~yellow~2x2 water source
]] -- boat bubble lift
	info.sub[61] = 
[[~red~NOT ~yellow~for Blaze spawners!
Plan view          Side view~lightGray~
    T       T      T = Outside dungeon
 |*|*|*|*|*|*|*|   |*|~brown~1~lightGray~|*|*|*|~yellow~2~lightGray~|*| Top
T|*| | | | | |*|T  |*| | | | | |*|
 |*| | |~magenta~5~lightGray~| | |*|   |*| | |~magenta~5~lightGray~| | |*|
 |*| |~magenta~5~lightGray~|~orange~S~lightGray~|~magenta~5~lightGray~| |*|   |*|~lime~3~lightGray~|~magenta~5|~orange~S~lightGray~|~magenta~5|~green~4~lightGray~|*| Base
 |*| | |~magenta~5~lightGray~| | |*|
T|*| | | | | |*|T  * = Dungeon Wall
 |*|*|*|*|*|*|*|   ~orange~S = Spawner
~lightGray~    T       T      T = Turtle ~brown~1 ~yellow~2 ~lime~3 ~green~4
~magenta~5~lightGray~ = On top or adjacent (0 chests only)
]] -- 9x9 cube round spawner
	info.sub[62] = 
[[~yellow~Place turtle as indicated:
Plan view          Side view

~lightGray~|*|*|*|*|*|*|*|*|  ~lime~< T = Continue build
~lightGray~|*| | | | | | | |  ~red~< T = New build
~lightGray~|*| | | | | | | |
|*| | | |~purple~S~lightGray~| | | |~lime~<~red~<
~lightGray~|*| | | | | | | |           ~red~T
~lightGray~|*| | | | | | | |  |*| | | |~purple~S~lightGray~| | | |~lime~T~red~T
~lightGray~|*|*|*|*|*|*|*|*|  |*|*|*|*|*|*|*|*|
]] -- 9x9 cube round blaze spawner with minecart collection
	info.sub[63] = 
[[~yellow~ Plan view (truncated)    Side view

~lightGray~ |*| | | | | | | | | |*|  |*| | | | | |
~red~>~lightGray~|*| | | | |~purple~S~lightGray~| | | | |*|~red~<~lightGray~ |*| | | | |~purple~S~lightGray~|
 |*| | | | | | | | | |*|  |*| | | | | |
 |*| | | | | | | | | |*|  |*| | | | | |
 |*| | | | | | | | | |*|  |*| | | | | |
 |*| | | | | | | | | |*|  |*| | | | | |
 |*|*|*|*|*|*|*|*|*|*|*| ~red~T~lightGray~|*|*|*|*|*|*|
            ~red~^
~purple~S ~lightGray~= Spawner ~red~<> ^ T ~lightGray~= Turtle
]] -- Flood spawner chamber
	info.sub[64] = 
[[~yellow~Bubble lift: Plan view at start~lightGray~
 |*| | | | | | | | | |*|
 |*| | | | |~brown~F~lightGray~| | | | |*|
 |*|*|*|*|*|~brown~F~lightGray~|*|*|*|*|*|  ~brown~F ~lightGray~= Fence
           ~brown~|~red~^~brown~|~lightGray~= Turtle on ~brown~Soul Sand
		   
~yellow~Plan view completed~lightGray~		   
 |*| | | | |~brown~F~lightGray~| | | | |*|
 |*|*|*|*|*|~brown~F~lightGray~|*|*|*|*|*|  ~brown~F ~lightGray~= Fence
~yellow~kill zone~lightGray~|*|~blue~S~lightGray~|*|~yellow~kill zone ~lightGray~Left / Right
           ~lightGray~|*|        ~blue~S ~lightGray~= Bubble lift
]] -- Build bubble tower kill zone
	info.sub[65] = 
[[~yellow~Computercraft mob grinder

Plan view~lightGray~ |*~blue~| | | | | | | | | |~lightGray~*|
          |*~blue~| | | | | | | | | |~lightGray~*|
          |*|*|*|*|*~blue~| |~lightGray~*|*|*|*|*| Front
~red~T~yellow~urtle facing out    ~red~V~lightGray~              
                          
~yellow~Side view ~lightGray~|*|*|*|*|*|*|*|*|*|*|*|
          |*|*|*|*|*|*|*|*|*|*|*|
          |*|*|*|*|*|*|*|*|*|*|*|
~red~E~yellow~xit hole ~lightGray~|*|*|*|*|*|~red~T~lightGray~|*|*|*|*|*|
          ~gray~|*|*|*|*|*|*|*|*|*|*|*| Base
]] -- Computercraft mob grinder
	info.sub[66] = 
[[This is a 3 stage process:
1.New tower lower base: place me on
flat ground in open plain.

2.Upper base: place me in front of
the existing chest at tower base.

3.Main tower, only needed to respawn
mobs. Expensive, not recommended.
Place me in front of chest in ground.
]] -- Build endermen observation tower

	info.sub[71] = 
[[~yellow~Clear field

~lightGray~| | | | | |  Remove ~lime~trees ~lightGray~and ~pink~flowers
~lightGray~| | | | | |  Fill ~gray~holes
~lightGray~| | | | | |  Remove blocks > ground
| | | | | |
| | | | | |
|~red~^~lightGray~| | | | |  ~red~^ ~lightGray~= Turtle position

~yellow~Optional use ~brown~dirt ~yellow~as surface

]] -- Clear field
	info.sub[72] = 
[[~yellow~Clear rectangle

~lightGray~| | | | | |  Remove all blocks
~lightGray~| | | | | |  Optional dig ~lime~up
~lightGray~| | | | | |  Optional dig ~blue~down
~lightGray~| | | | | |
| | | | | |
|~red~^~lightGray~| | | | |  ~red~^ ~lightGray~= Turtle position
 ~red~^

~yellow~Can be used to clear 3 layers at a time

]] -- Clear rectangle

	info.sub[73] = 
[[~yellow~Clear wall
Plan view         Side view
                  ~gray~T ~lightBlue~T
~red~>~lightGray~|~orange~>~lightGray~|*|*|*|*|*|    ~cyan~T~lightGray~|~blue~T~lightGray~|*|*|*|*|*| Top
~lightGray~                   |*|*|*|*|*|*|
                   |*|*|*|*|*|*|
                   |*|*|*|*|*|*|
                   |*|*|*|*|*|*|
                  ~lime~T~lightGray~|~green~T~lightGray~|*|*|*|*|*| Base
				  
T = Turtle top / bottom/ inside / out
~yellow~Bottom to top or top to bottom
]] -- Clear wall
	info.sub[74] = 
[[~yellow~Clear rectangle ~red~perimeter only

~yellow~Plan view
~lightGray~| | | | | |  Remove all blocks
~lightGray~| |*|*|*| |  Optional dig ~lime~up
~lightGray~| |*|*|*| |  Optional dig ~blue~down
~lightGray~| |*|*|*| |
| |*|*|*| |
|~red~^~lightGray~| | | | |  ~red~^ ~lightGray~= Turtle position
~red~ ^
~yellow~Can be used to clear 3 layers at a time

]] -- Clear rectangle (perimeter only) 
	info.sub[75] = 
[[~yellow~Demolish cube structure
Plan view        Side view
               ~gray~T ~lightBlue~T
~lightGray~|*|*|*|*|*|*|  ~cyan~T~lightGray~|~blue~T~lightGray~|*|*|*|*|*|
|*|*|*|*|*|*|   |*|*|*|*|*|*|
|*|*|*|*|*|*|   |*|*|*|*|*|*|
|*|*|*|*|*|*|   |*|*|*|*|*|*|
|*|*|*|*|*|*|   |*|*|*|*|*|*|
|~lime~^~lightGray~|*|*|*|*|*|  ~lime~T~lightGray~|~green~T~lightGray~|*|*|*|*|*|
 ~green~^
~lightGray~^ T = Turtle (top/base in/out)
]] -- Clear structure floor/walls/ceiling hollow and solid
	info.sub[76] = info.sub[75]
	info.sub[77] = 
[[~yellow~Dig a trench (Plan view)

~lightGray~      |~red~>~lightGray~| | | | | | |
  
| |    ~red~>~lightGray~ = Turtle
| |    
| |
| |
| |    
|~red~^~lightGray~|    ~red~^~lightGray~ = Turtle
]] -- Dig a trench
	info.sub[78] = 
[[~yellow~Mountain carving     ~red~T ^ = Turtle
~yellow~Side view            Plan view

~lightGray~        |*|              |*|*|
~gray~ 	    |*~lightGray~|*|            ~gray~|*~lightGray~|*|*|*|
~gray~      |*~lightGray~|*|*|*|      ~gray~|*|*~lightGray~|*|*|*|*|
~gray~      |*~lightGray~|*|*|*|      ~gray~|*|*~lightGray~|*|*|*|*|
~gray~      |*~lightGray~|*|*|*|       ~red~^~gray~|*~lightGray~|*|*|*|
~gray~    |*|*~lightGray~|*|*|*|*|        |*|*|
   ~red~T~gray~|*|*|~lightGray~*|*|*|*|
 
]] -- Carve mountain
	info.sub[79] = 
[[~yellow~Place / Replace floor or ceiling

Plan view      Side view
~lightGray~| | | | | |    |*|*|*|*|*|
| | | | | |     T          Ceiling
| | | | | |
| | | | | |
| | | | | |     T          Floor
|~red~^~lightGray~| | | | |    |*|*|*|*|*|

~red~^ ~lightGray~T = Turtle position

]] -- (Re)place floor or ceiling
	info.sub[710] =
[[~yellow~Place me anywhere!
Menu or direct command interface.

~lightGray~Commands:

direction + ~blue~number ~yellow~eg ~white~f2 ~yellow~= forward ~blue~2

~yellow~f = forward  ~orange~b = backward
~lime~l = left     ~red~r = right
~lightGray~u = up       ~cyan~d = down

]] -- Direct control
	info.sub[81] = 
[[~blue~1.Drop sand or gravel wall
  ~yellow~Place me on water/lava surface
  
~lightBlue~2.Fill area with sand
  ~yellow~Place  on left corner of area
 
~yellow~3.Clear ~blue~(1) sand wall
  ~yellow~Place me on the surface of sand.

~yellow~4.Clear ~lightBlue~(2) sand filled area
  ~yellow~Place on left corner of sand field
]] -- Sand based utilities
	info.sub[82] = 
[[~yellow~Turtle position ~red~> T ~gray~(~red~V ~gray~to enclose)
~yellow~Plan view                      ~gray~Start:~red~V
~blue~|~red~>~blue~| | | | | | ~yellow~to ~lightGray~|*|*|*|*|*|~red~V~lightGray~|~gray~ enclose
                            ~gray~*  area
~yellow~Side view
 ~red~T
~blue~| | | | | | | ~yellow~to ~lightGray~|*|*|*|*|*|*|
~blue~| | | | | | |    ~lightGray~|*|*|*|*|*|*|
~blue~| | | | | | |    ~lightGray~|*|*|*|*|*|*|
~yellow~|S|~blue~ | | |~yellow~S|S|    |S|~lightGray~*|*|*|~yellow~S|S|
~yellow~|S|S|S|S|S|S|    |S|S|S|S|S|S|
]] -- build wall from water or lava surface downwards 	
	info.sub[83] = 
[[~yellow~Build a walled rectangle


~yellow~L ~lightGray~|*|*|*|*|*|*|
~yellow~e ~lightGray~|*| | | | |*|
~yellow~n ~lightGray~|*| | | | |*|
~yellow~g ~lightGray~|*| | | | |*|
~yellow~t ~lightGray~|*|*|*|*|*|*|
~yellow~h  ~red~^
~yellow~   W i d t h      ~red~^ ~lightGray~= Turtle


]] -- Create enclosed area
	info.sub[84] = 
[[~yellow~Clear volume of water

Plan view
~lightGray~|*|*|*|*|*|*|*|*|  * = Stone
|*|*~blue~| | |~lightGray~*|*~blue~| |~lightGray~*|  ~blue~| ~lightGray~= Water
|*~blue~| | | | | | |~lightGray~*|
|*~blue~| | | | | | |~lightGray~*|
|*~blue~| | | | | | |~lightGray~*|
|*~blue~| | | | | |~lightGray~*|*|
|*|~red~^~lightGray~|*~blue~| | | | |~lightGray~*|  ~red~^ ~lightGray~= Turtle
|*|*|*|*|*|*|*|*|  ~yellow~Width~blue~: ~yellow~6, ~orange~length~blue~:~orange~ 6

]] -- Clear volume of water
	info.sub[85] = info.sub[56] -- Sinking platform
	info.sub[861] = 
[[~yellow~Turtle placement  ~red~V~lime~ < ^ > ~yellow~over monument

~red~******    ******  * ~lightGray~= Avoid this area
~red~******    ******  V do not face front
******    ******  ~lime~< ^ > ~lightGray~Ideal facing~lightGray~
******    ******
~green~******~lime~++++~green~******  ~lime~+ ~lightGray~= Ideal position~green~
******~lime~++++~green~******  ~green~* ~lightGray~= Good position
~green~****************
****************  Or any corner < 12 
****************  blocks from edge
]]-- Ocean monument 85 subChoice 1: 4 corner pillars

	info.sub[862] = 
[[~yellow~Turtle positions ~red~> ^ < V

~lightGray~|*|~red~>~lightGray~|*|*|*|*|*|~red~<~lightGray~|*|  ~red~NOT ~lightGray~corner blocks!
|~red~V~lightGray~|             |~red~V~lightGray~|
|*|             |*|
|*|             |*|
|*|             |*|
|*|             |*|
|*|             |*|  ~yellow~Fill inventory~lightGray~
|~red~^~lightGray~|             |~red~^~lightGray~|  ~yellow~with stone.~lightGray~
|*|~red~>~lightGray~|*|*|*|*|*|~red~<~lightGray~|*|  ~yellow~Add when asked
]] -- Ocean monument build retaining walls

	info.sub[863] = 
[[~yellow~Turtle ~red~> < ~yellow~on side walls only

~lightGray~|*|*|*|*|*|*|*|*|*|*|
~lightGray~|~red~>~cyan~| *****   ***** |~red~<~lightGray~|
~lightGray~|~red~>~cyan~| *****   ***** |~red~<~lightGray~|
~lightGray~|~red~>~cyan~| *****   ***** |~red~<~lightGray~|
~lightGray~|~red~>~cyan~| *****+++***** |~red~<~lightGray~|
~lightGray~|~red~>~cyan~| *****+++***** |~red~<~lightGray~|
~lightGray~|~red~>~cyan~| ************* |~red~<~lightGray~|
~lightGray~|~red~>~cyan~| ************* |~red~<~lightGray~|
|*|*|*|*|*|*|*|*|*|*|
]] -- clear plants before sand draining
	info.sub[864] = info.sub[863]
	info.sub[865] = info.sub[863]
	info.sub[866] = info.sub[56]
	info.sub[867] = 
[[~yellow~Turtle positions ~red~> ^ < V
~green~|*|*|*|*|*~brown~|*|*|*|~red~V~brown~|*|
~green~|~red~>~green~|- - - - ~brown~- - - -|*|
~green~|*|- - - - ~brown~- - - -|*| ~lightGray~1 Turtle removes
~green~|*|- - - - ~brown~- - - -|*| ~lightGray~1 coloured area
~green~|*|- - - - ~brown~- - - -|*|
~orange~|*|- - - - ~lime~- - - -|*| ~lightGray~6 chests / area
~orange~|*|- - - - ~lime~- - - -|*| ~lightGray~Follow turtle
~orange~|*|- - - - ~lime~- - - -|*|
~orange~|*|- - - - ~lime~- - - -|~red~<~lime~| ~lightGray~30,000 fuel each!
~orange~|*|~red~^~orange~|*|*|*~lime~|*|*|*|*|*| ~lightGray~3,000 stone each!
]] -- Ocean monument drain and remove 1 of 4 quarters
	info.sub[87] = 
[[~yellow~Ladder to water / lava: Plan view

 ~blue~- ~red~- ~blue~- ~red~- ~blue~- ~red~- ~blue~-    ~blue~- ~red~- ~blue~- ~red~- ~blue~- ~red~- ~blue~-
 ~red~- ~blue~- ~red~- ~blue~- ~red~- ~blue~- ~red~-    ~red~- ~blue~- ~red~-~lightGray~|*|- ~blue~- ~red~-
 ~blue~- ~red~- ~blue~- ~red~- ~blue~- ~red~- ~blue~-    ~blue~- ~red~-~lightGray~|*|~brown~L~lightGray~|*|~red~- ~blue~- ~~lightGray~
|*|*|*|~red~^~lightGray~|*|*|*|  |*|*|*|*|*|*|*|
|*|*|*|*|*|*|*|  |*|*|*|*|*|*|*|
|*|*|*|*|*|*|*|  |*|*|*|*|*|*|*|

~red~^ ~lightGray~= Turtle facing water / lava
~brown~L ~lightGray~= Ladder

]] -- Ladder to water/lava	
	info.sub[88] = 
[[~yellow~Place ~red~T~yellow~urtle at water edge.
Returns max ~blue~d~yellow~epth. ~yellow~Water ~green~p~yellow~lants~yellow~ removed

   ~red~T                       T
~lightGray~|*|*| ~blue~| | | | | | | | | | ~lightGray~|*|
|*|*| ~blue~| | | | | | | | | ~lightGray~|*|*|
|*|*| ~blue~| | | | | | | ~lightGray~|*|*|*|*|
|*|*|*| ~blue~| | |~green~p~blue~| | ~lightGray~|*|*|*|*|*|
|*|*|*| ~blue~| | |~green~p~lightGray~|*|*|*|*|*|*|*|
|*|*|*|*~blue~|d~lightGray~|*|*|*|*|*|*|*|*|*|
|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
]] -- Clear water plants from enclosed area
	info.sub[89] = 
[[Place me on the left corner of the top
of retaining wall facing water
]] -- Convert all water to source
	info.sub[810] = 
[[Place me on the left corner of the top
of retaining wall facing water.
The source blocks are placed ahead to
selected length
]] -- Create sloping water

-- Building and railway
	info.sub[91] = 
[[~yellow~Build a wall

Plan view        Side view

~red~>~lightGray~| | | | | | |   |*|*|*|*|*|*|
                 |*|*|*|*|*|*|
                 |*|*|*|*|*|*|
                 |*|*|*|*|*|*|
                ~red~T~lightGray~|~red~T~lightGray~|*|*|*|*|*|

~red~> T~lightGray~ = Turtle
				 
]] -- Build a wall
	info.sub[92] = 
[[~yellow~Build a walled rectangle / house

Plan view         Side view

~yellow~L ~lightGray~|*|*|*|*|*|*|   |*|*|*|*|*|*|
~yellow~e ~lightGray~|*| | | | |*|   |*|*|*|*|*|*|
~yellow~n ~lightGray~|*| | | | |*|   |*|*|*|*|*|*|
~yellow~g ~lightGray~|*| | | | |*|   |*|*|*|*|*|*|
~yellow~t ~lightGray~|~red~^~lightGray~|*|*|*|*|*|  ~red~T~lightGray~|~red~T~lightGray~|*|*|*|*|*|
~yellow~h  ~red~^
~yellow~   W i d t h      ~red~^ T ~lightGray~= Turtle

]] -- Build a rectangular structure
	info.sub[93] = 
[[~yellow~Build a gable roof
Gable built on right side of turtle
Plan view       End view (width)
                     ~gray~+      gable top
~yellow~L ~lightGray~|*|*|*|*|*|      ~gray~+ + +    gable end
~yellow~e ~lightGray~|*| | | |*|    ~red~T~gray~ + + + +  gable end
~yellow~n ~lightGray~|*| | | |*|   |*|*|*|*|*| top of wall
~yellow~g ~lightGray~|*| | | |*|   |*|*|*|*|*|
~yellow~t ~lightGray~|*| | | |*|   |*|*|*|*|*|
~yellow~h ~lightGray~|~red~^~lightGray~|*|*|*|*|   |*|*|*|*|*|
~yellow~  W i d t h     W i d t h   ~red~^T ~lightGray~= Turtle
]] -- Build a gable end roof
	info.sub[94] =
[[~yellow~Build a pitched roof
Width ~red~MUST ~yellow~be ~red~<= ~yellow~Length eg ~red~4~yellow~ x 6
Plan view        End view (width)

                  ~red~T ~lightGray~on top of building
~yellow~L ~lightGray~|*|*|*|*|      |*|*|*|*|
~yellow~e ~lightGray~|*| | |*|      |*|*|*|*|
~yellow~n ~lightGray~|*| | |*|      |*|*|*|*|
~yellow~g ~lightGray~|*| | |*|      |*|*|*|*|
~yellow~t ~lightGray~|*| | |*|
~yellow~h ~lightGray~|~red~^~lightGray~|*|*|*|
~yellow~  W i d t h     ~red~^ T ~lightGray~= Turtle
]]-- Build a pitched roof
	info.sub[95] = 
[[~yellow~Place me on suspended railway stone
Redstone torch will go below me

~lightGray~_____
~lightGray~|*|*|\                           ~red~>~lightGray~|*|
    |*|~red~<                       ~lightGray~/|*|
      ~lightGray~|*|______~red~T~lightGray~_________    /~lightGray~|*|~red~!
       ~red~!~lightGray~|*|*|*|*|*|*|*|*|\ /|*|
               ~red~!        ~lightGray~|*|*|

~red~T < > ~lightGray~= Turtle ~red~! ~lightGray~= Redstone Torch
On block or above rail, face up slope
]] -- Place redstone torch under block
	info.sub[96] = info.sub[95]
	info.sub[97] = 
[[~yellow~Place me on last block before up/down

Build down            Build up~lightGray~

_____~red~T~lightGray~                        ___
|*|*|*|_                     _|*|
      |*|_                 _|*|
        |*|_             _|*|
          |*|__________~red~T~lightGray~|*|
            |*|*|*|*|*|*|		
~red~T~lightGray~ = Turtle on block, not above rail	
]] -- build down
	info.sub[98] =  info.sub[97]

--Measurement tools
	info.sub[101] = 
[[~yellow~Place me on floor.~lightGray~
            Measured Height:
|~lightBlue~*~lightGray~|*|*|*|   ~lightBlue~7. Overhead obstruction
            ~cyan~7. ~red~NOT ~cyan~turtle.detect()~lightGray~
  |*|*|*|
  |*|*|*|
  |~lime~S~lightGray~|*|*|   ~lime~4. Specific block found~lightGray~
  |*|*|*|
  |*|*|*|
  |*|*|*|
 ~red~T~lightGray~|*|*|*|   ~red~T~lightGray~ = Turtle
]] -- measure height
	info.sub[102] = 
[[~yellow~Depth measurement
Place me on the floor above pit / edge

    ~red~T~lightGray~
1|*|*|
2|*|*|
3|*|*|
4|*|*|         Measured depth: 
5|*|~lime~S~lightGray~|         ~lime~5. Specific block found
~lightGray~6              ~cyan~6. ~red~NOT ~cyan~turtle.detect()~lightGray~ 
7|*|*|~lightBlue~*~lightGray~|*| |   ~lightBlue~6. Obstruction below
]] -- measure depth
	info.sub[103] = 
[[~yellow~Length measurement

~lightGray~1 2 3 4 ~lime~5~lightGray~ 6 ~lime~7 ~cyan~8 ~lightBlue~9~lightGray~ 10
                      ~cyan~8. No block up
~lightGray~*|*|*|*|*|*|~lime~S~lightGray~| |*|*|  ~lime~7. Search block
~red~T~lightGray~                |*|  ~lightBlue~9. Obstruction
~lightGray~*|*|*|*|~lime~S~lightGray~|*|*| |*|*|  ~lime~5. Search block
                      ~cyan~8. No block down

~red~T ~lightGray~= Turtle

]] -- measure length
	info.sub[104] = info.sub[88] -- measure deepest section of water
	info.sub[105] =
[[~yellow~Place turtle anywhere:

 1. make a ~blue~borehole~yellow~ to chosen level.

 2. Write a report called:

 3. ~lime~borehole~blue~X~lime~.txt ~yellow~( ~blue~X ~yellow~= computer ID )

 4. ~orange~Return home

]] -- Borehole: Analyse blocks below
	info.sub[110] = 
[[~yellow~Multiple options for canal building:

~lightGray~| |~red~T~lightGray~|~lime~T~lightGray~| | 2 turtles: ~red~* W, ~lime~W *
~lightGray~|*|~blue~W|W|~lightGray~*|

~lightGray~|~red~T|~orange~T|~yellow~T|~brown~T~lightGray~| 4 turtles, ~red~*, ~orange~W, ~yellow~W, ~brown~*
~lightGray~|*|~blue~W|W|~lightGray~*|

~yellow~Option 1 for half canal per turtle
~yellow~Option 2 for quarter canal per turtle
]]
	local line = menu.clear()
	if menuLevel == 1 then -- general help
		line = menu.colourText(line, info.main[menuItem], true, true)
		term.write("Enter to continue ")
		read()
		return ""
	else -- item specific help
		if info.sub[menuItem] ~= nil then -- help file exists
			line = menu.colourText(line, info.sub[menuItem], true, true)
			if noMenu then
				

				if getInteger then
					return line -- ready for further input
				else
					term.setCursorPos(1, 13)
					menu.enterToContinue()
				end
			else
				term.setCursorPos(1, 13)
				term.write("Enter=exit, Any key + Enter=more ")
				return read()
			end
		end
	end
end

local function getTaskOptions()
	local options = {}
	options.main =
	{
		"Mining (includes Nether)",
		"Forestry",
		"Farming",
		"Obsidian, Nether & End",
		"Canal, bridge and walkway",
		"Spawner farm tools",
		"Area shaping and clearing",
		"Lava and Water",
		"Building and minecart",
		"Measuring tools"
	}
	table.insert(options,
	{
		"Ladder up or down",
		"Stairs up or down",
		"Create mine at this level",
		"Safe drop to water block",
		"Single column bubble lift",
		"QuickMine corridor system",
		"QuickMine rectangle",
		"Mine bedrock level",
		"Rob disused mineshaft"
	})
	table.insert(options,
	{
		"Fell Tree",
		"Create tree farm",
		"Plant tree farm",
		"Harvest tree farm",
		"Fence or wall a forest",
		"Harvest and replant forest"
	})
	table.insert(options,
	{
		"Create modular crop farm",
		"Extend modular crop farm",
		"Plant, harvest or manage crop farm",
		"Build a wall or fence",
		"Fence or wall an enclosure"
	})	
	table.insert(options,					
	{
		"Dig obsidian field",
		"Build Nether Portal",
		"Demolish Nether Portal",
		"Undermine Dragon Towers",
		"Deactivate Dragon Tower",
		"Build dragon water trap",
		"Build portal ladder & platform"
	})
	table.insert(options,
	{
		"Simple path on air, water or lava",
		"Covered path or tunnel",
		"Water canal (mulitple options)",
		"Ice canal (multiple options)",
		"Platform",
		"Sinking platform",
		"Boat bubble lift",
	})
	table.insert(options,
	{
		"Cube around spawner (NOT blaze)",
		"Cube around Blaze spawner",
		"Flood mob farm floor",
		"Create mob bubble lift",
		"Computercraft mob grinder",
		"Build Endermen observation tower"
	})
	table.insert(options,
	{
		"Clear field (inc trees)",
		"Clear a rectangle (+ u/d opt)",
		"Clear single wall up/down",
		"Clear rectangular wall section",
		"Clear hollow structure up/down",
		"Clear solid structure up/down",
		"Dig a trench",
		"Carve mountain side",
		"Place a floor or ceiling",
		"Direct control of movement"
	})
	table.insert(options,
	{
		"Sand based utilities",
		"Vertical wall from surface",
		"Create enclosed area",
		"Clear volume of water",
		"Sinking platform",
		"Ocean monument utilities",
		"Ladder down to water/lava",
		"Clear water plants",
		"Convert all water to source",
		"Create sloping water"
	})
	table.insert(options,
	{
		"Build a wall",
		"Build a walled area / house",
		"Build a gable end roof",
		"Build a pitched roof",
		"Place Redstone:torch level track",
		"Place Redstone:torch upward track",
		"Build downward track",
		"Build upward track"
	})
	table.insert(options,
	{
		"Measure height",
		"Measure depth",
		"Measure length",
		"Measure greatest depth",
		"Borehole: Analyse blocks below"
	})
	
	return options
end

local function getTaskColours()
	local options = {}
	options.main =
	{
		colors.lightGray, 	-- Mining (includes Nether)
		colors.lime, 		-- Forestry
		colors.green, 		-- Farming
		colors.red, 		-- Obsidian, Nether & End Portal
		colors.brown, 		-- Canal, bridge and walkway
		colors.lightGray, 	-- Mob farm tools
		colors.orange,		-- Area shaping and clearing
		colors.blue, 		-- Lava and Water
		colors.cyan,		-- Railway
		colors.purple 		-- Measuring tools
	}
	table.insert(options,
	{
		colors.brown, 		-- Ladder up or down
		colors.lightGray, 	-- Stairs up or down
		colors.lightGray, 	-- Create mine at this level
		colors.blue, 		-- Safe drop to water block
		colors.blue, 		-- Single column bubble lift
		colors.magenta, 	-- QuickMine corridor system
		colors.pink, 		-- QuickMine rectangle
		colors.gray, 		-- Mine bedrock level
		colors.brown 		-- Rob disused mineshaft
	})
	table.insert(options,
	{
		colors.brown, 		-- Fell Tree
		colors.lightGray, 	-- Create tree farm
		colors.lime, 		-- Plant tree farm
		colors.green, 		-- Harvest tree farm
		colors.brown, 		-- Fence or wall an enclosure
		colors.lime 		-- Harvest and replant forest
	})
	table.insert(options,
	{
		colors.yellow, 		-- Create modular crop farm
		colors.green, 		-- Extend modular crop farm
		colors.lime, 		-- Manage modular crop farm
		colors.brown, 		-- Build wall or fence
		colors.brown 		-- Build rectangle wall or fence
	})	
	table.insert(options,					
	{
		colors.lightGray, 	-- Dig obsidian field
		colors.purple, 		-- Build Nether Portal
		colors.gray, 		-- Demolish Nether Portal
		colors.orange, 		-- Undermine Dragon Towers
		colors.orange, 		-- Deactivate Dragon Tower
		colors.blue, 		-- Build dragon water trap
		colors.lightGray 	-- Build portal minecart station
	})
	table.insert(options,
	{
		colors.lightGray, 	-- Continuous path
		colors.gray, 		-- Covered walkway / tunnel
		colors.blue, 		-- Water canal
		colors.lightBlue, 	-- Ice canal (4 options)
		colors.brown, 		-- Platform
		colors.blue, 		-- Sinking platform for oceans
		colors.cyan 		-- Boat bubble lift
	})
	table.insert(options,
	{
		colors.brown, 		-- Cube around spawner (NOT blaze)
		colors.red, 		-- Cube around Blaze spawner
		colors.cyan, 		-- Flood mob farm floor
		colors.blue, 		-- Create mob bubble lift
		colors.brown, 		-- Dig mob drop trench
		colors.gray 		-- Build Endermen observation tower
	})
	table.insert(options,
	{
		colors.lime, 		-- Clear field (inc trees)
		colors.magenta, 	-- Clear a rectangle (+ u/d opt)
		colors.pink, 		-- Clear single wall up/down
		colors.purple, 		-- Clear rectangular wall section
		colors.brown, 		-- Clear hollow structure up/down
		colors.orange, 		-- Clear solid structure up/down
		colors.brown, 		-- Dig a trench
		colors.gray, 		-- Carve mountain side
		colors.lightBlue, 	-- Place a floor or ceiling
		colors.red 			-- Direct control of movement
	})
	table.insert(options,
	{
		colors.yellow, 		-- Sand based utilities
		colors.blue, 		-- Vertical wall from surface
		colors.blue, 		-- Create enclosed area
		colors.cyan, 		-- Clear volume of water
		colors.lightGray,	-- Sinking platform
		colors.orange, 		-- Ocean monument utilities
		colors.brown, 		-- Ladder down to water/lava
		colors.green, 		-- Clear water plants
		colors.lightBlue, 	-- Convert all water to source
		colors.blue 		-- Create sloping water
	})
	table.insert(options,
	{
		colors.yellow,		-- build a wall
		colors.orange,		-- build rectangular structure
		colors.lightGray,	-- gable end roof
		colors.gray,		-- pitched roof
		colors.red, 		-- Place Redstone:torch level track
		colors.red, 		-- Place Redstone:torch upward track
		colors.orange, 		-- Build downward track
		colors.brown 		-- Build upward track
	})
	table.insert(options,
	{
		colors.red, 		-- Measure height
		colors.purple, 		-- Measure depth
		colors.magenta, 	-- Measure length
		colors.pink, 		-- Measure greatest depth
		colors.lightBlue	-- Borehole: Analyse blocks below
	})
	
	return options
end

local function chooseTask(R)
--[[ 
	called from main()
	R = chooseTask(R)
	coloured menu:	
	local pp = 
	{
		prompt = colors.green,
		itemColours = {colors.white, colors.red, ... one for each item},
		menuPrompt = colors.yellow
	}
	choice, modifier = menu.menu or menu.new("Choose your option", options, pp)
	]]
	local lib = {}
	
	function lib.getHelp(choice, itemsRequired, pp)
		local listOfItems = itemsRequired[choice]
		local result = getTaskHelp(2, choice)
		if result ~= "" then -- any key + enter = more
			lib.showItems(listOfItems)
		end
		T:clear()
		pp.itemColours = {colors.green, colors.yellow, colors.orange, colors.red}
		local options ={"Continue with selected task", "return to menu", "Return to main menu","Quit application"}
		local option = menu.menu("Choose your option", options, pp, "Type number + Enter ")
		if option == 2 then
			choice = -2	-- return to subMenu
		elseif option == 3 then
			choice = 0 -- return to main menu
		elseif option == 4 then
			choice = -1 -- quit
		-- else return original value of choice
		end
		
		return choice -- if R.choice reset to 0, then re-starts, -1 == quit
	end
	
	function lib.showItems(listOfItems)
		T:clear()
		if next(listOfItems) ~= nil then
			menu.colourPrint("Items required:", colors.lime)
			for k,v in pairs(listOfItems) do
				menu.colourPrint("  "..v, colors.lightGray)
			end
		else
			menu.colourPrint("No items required", colors.lime)
		end
		menu.colourWrite("Enter to continue", colors.yellow, colors.black, nil, true)
		read()
	end
	
	function lib.getItemList(subChoice, itemsRequired)
		local listOfItems = itemsRequired[subChoice]
		lib.showItems(listOfItems)
	end
	
	function lib.getChoice(choice, subChoice)
		if subChoice > 9 then -- need more than 9 sub-options
			choice = subChoice + (choice * 100) -- 10 = 10 + 1000 = 1100
		else -- eg main option 1 (mining), sub-option 1 (create mine) = 1 + 10 = 11
			choice = subChoice + (choice * 10) -- 9 = 9 + 9 * 10 = 99, 1 + 10*10 = 101
		end
		return choice
	end
	
	local modifier = ""
	local subChoice = 0
	local prompt = "Choose an option"
	local mainPrompt = "Choose option (+h = help eg 3h):"
	local subPrompt = "Choose (+h = help +i = items eg 3h):"
	local options = getTaskOptions()
	local menuColours = getTaskColours()
	local itemsRequired = getTaskItemsList()
	local menuState = 0 -- use main menu
	-- local pp = utils.getPrettyPrint(colors.cyan, colors.magenta) -- specify menu title and prompt colours
	--local pp = utils.getPrettyPrint()-- uses default colours
	
	while menuState >= 0 do -- menuState has to be -1 to exit loop
		--[[
		menu returns choice=nil if user enters just q or h
		menu returns choice=2, modifier = "h" if 2h entered
		Mining (includes Nether)		white
		Forestry						lime
		Farming							lime
		Obsidian, Nether & End Portal	brown
		Canal, bridge and walkway		pink	
		Mob farm tools					gray
		Area shaping and clearing		purple	
		Lava and Water					blue
		Railway							magenta
		Measuring tools					cyan		
		]]
		
		if menuState == 0 then
			pp.itemColours = menuColours.main
			local mainChoice, modifier = menu.menu(mainPrompt, options.main, pp) -- open main menu options
			if modifier == "q" then
				R.choice = -1
				return R -- quit application
			elseif modifier == "h" then -- get help on main menu items
				getTaskHelp(1, mainChoice) -- "" or any return string for more
				R.choice = 0
				return R -- quit task system so it re-starts as help menu chosen R.choice = 0
			else
				menuState = 1 -- next level so use sub-menu
				R.choice = mainChoice -- 1-10
			end
		else
			pp.prompt = colors.yellow
			pp.itemColours = menuColours[R.choice]
			subChoice, modifier = menu.menu(subPrompt, options[R.choice], pp, "Back = 'q' or number + Enter: ") -- open submenu options
			if modifier == "q" then
				R.choice = 0	-- return to root menu. change this to -1 if quit application preferred
				return R -- quit task system so it re-starts first menu
			elseif modifier == "i" then -- get list of items
				local index = lib.getChoice(R.choice, subChoice)
				lib.getItemList(index, itemsRequired) -- list of items shown
				subChoice = nil -- allow menu to continue
			elseif modifier == "h" then -- get help on main menu items
				local index = lib.getChoice(R.choice, subChoice)
				index = lib.getHelp(index, itemsRequired, pp)
				--R = lib.getHelp(R, itemsRequired, pp) -- if R.choice reset to 0 then will continue
				if index == -2 then -- redraw sub-menu
					subChoice = nil -- allow menu to continue
				elseif index == -1 then -- if R.choice reset to 0 then will continue
					R.choice = -1
					return R
				elseif index == 0 then 
					R.choice = 0
					menuState = 0 -- if R.choice reset to 0 then back to main menu
				end
			end
			if subChoice ~= nil then
				R.choice = lib.getChoice(R.choice, subChoice)
				return R -- exit loop
			end
		end
	end
	return R
end

local function getTask(R)
	local lib = {}
	
	function lib.isAutoHelp(choice, noAutoHelp)
		for _, v in ipairs(noAutoHelp) do
			if choice == v then
				return true
			end
		end
		return false
	end
	
	local prompt = "Choose an option"
	local noAutoHelp = {53, 54, 81, 85}
	if not lib.isAutoHelp(R.choice, noAutoHelp) then -- exclude Water canal, ice canal, sand utilities, monument utilities
		getTaskHelp(2, R.choice, true)
		menu.clear()
	end
-- 01. MINING
	if R.choice >= 11 and  R.choice <= 13 then	-- createLadder, createStaircase, createMine)
		--getTaskHelp(2, R.choice, true)
		--menu.clear()
	elseif R.choice == 14 then	-- safe drop to water
		local currentLevel = menu.getInteger("Current level (F3->Y coord)? ", bedrock + 5, ceiling, nil, colors.lightGray)
		local destLevel = menu.getInteger("Go down to level? ("..currentLevel - 2 .." to "..bedrock + 5 ..")", bedrock + 5 , currentLevel - 2, nil, colors.blue, nil, bedrock + 5)
		R.height 	= math.abs(destLevel - currentLevel)
	elseif R.choice == 15 then	-- bubble lift
		local currentLevel = menu.getInteger("Current level (F3->Y coord)? ", bedrock + 5 , ceiling, nil, colors.blue, nil, bedrock + 5)
		local destLevel = menu.getInteger("Go up to level? ("..currentLevel + 2 .." to "..ceiling ..") ", currentLevel + 2, ceiling, nil, colors.lightGray)
		if currentLevel <= bedrock + 5 then
			if menu.getBoolean("Confirm at bedrock level (y / n) ", nil, colors.yellow, colors.black) then
				R.data = "bedrock"
			end
		end
		R.height 	= math.abs(destLevel - currentLevel)
	elseif R.choice == 16 then -- create mining corridor system default: square 17 x 17 
		local choices = {"At corridor start, on the floor",
						 "At corridor start, on the ceiling",
						 "On floor, move forward to start",
						 "On ceiling, move forward to start"}
		pp.itemColours = {colors.lime, colors.green, colors.magenta, colors.pink}
		local userChoice, modifier = menu.menu("Starting position?", choices, pp, "Type number + Enter ") -- 1 to 4
		if modifier == "q" then -- quit chosen
			return R
		end
		R.width 	= menu.getInteger("Width (2-64 default 17) ", 2, 64, nil, colors.yellow, nil, 17)
		R.length  	= menu.getInteger("Length (2-64 default 17) ", 2, 64, nil, colors.orange, nil, 17)
		R.torchInterval = 9 -- 8 spaces between torches
		if mcMajorVersion >= 1.18 then
			R.torchInterval = 17 -- 16 spaces between torches
		end
		R.subChoice = userChoice
	elseif R.choice == 17 then -- clear a rectangle, fill empty spaces above
		local choices = {"At mine area start, on the floor",
						 "At mine area start, on the ceiling",
						 "On floor, move forward to start",
						 "On ceiling, move forward to start",
						 "On floor diagonally to left"} -- just finished corridor
		pp.itemColours = {colors.lime, colors.green, colors.magenta, colors.pink, colors.red}
		local userChoice, modifier = menu.menu("Starting position?", choices, pp, "Type number + Enter ") -- 1 to 4
		if modifier == "q" then -- quit chosen
			return R
		end
		R.width 	= menu.getInteger("Width (2-64 default 15) ", 2, 64, nil, colors.yellow, nil, 15)
		R.length  	= menu.getInteger("Length (2-64 default 15) ", 2, 64, nil, colors.orange, nil, 15)
		R.subChoice = userChoice
	elseif R.choice == 18 then -- Mine bedrock area
		--getTaskHelp(2, R.choice, true)
		--menu.clear()
		R.width 	= menu.getInteger("Width (2-64 default 15) ", 2, 64, nil, colors.yellow, nil,  15)
		R.length 	= menu.getInteger("Length (2-64 default 15) ", 2, 64, nil, colors.orange, nil,  15)
		if menu.getBoolean("Leave bedrock exposed? (y/n) ", nil, colors.yellow, colors.black) then
			R.data = "leaveExposed"
		end
	elseif R.choice == 19 then -- salvage mine shaft
		
-- 02. FORESTRY
	elseif R.choice == 22 then --Create treefarm
		R.width = 15
		R.length = 15
		pp.itemColours = {colors.lightGray, colors.green}
		choices = {"New tree farm. Start here", "On right side of existing farm" }
		local choice = menu.menu(prompt, choices, pp, "Type number + Enter ")
		if choice == 2 then
			R.data = "existing"
		end
		R.up = menu.getBoolean({"Any blocks/trees above current level","in a 15 x 15 block area (y/n) "}, nil, colors.yellow, colors.black)
	elseif R.choice == 23 then -- plant treefarm
		local choices 	= {"16 single trees", "4 double trees any type"}
		pp.itemColours = {colors.lime, colors.green}
		R.subChoice = menu.menu(prompt, choices, pp, "Type number + Enter ")
	elseif R.choice == 24 then -- Harvest treefarm
	
	elseif R.choice == 25 then -- Build wall or fence
		R.width 	= menu.getInteger("Width of the area (1-64)", 1, 64, nil, colors.yellow)
		R.length  	= menu.getInteger("Length of the area (1-64)", 1, 64, nil, colors.orange)
		R.torchInterval = menu.getInteger("Torch spacing? (0-64)", 0, 64, nil, colors.red)
		if menu.getBoolean("Storage barrels in corners? (y/n)", nil, colors.brown) then
			R.data = "barrel"
		end
	elseif R.choice == 26 then -- Harvest and replant natural forest

		
-- 03. FARMING
	elseif R.choice == 31 then -- new crop farm

	elseif R.choice == 32 then -- extend crop farm
		local choices 	= {"Add a farm at the back", "Add a farm to the right"}
		pp.itemColours = {colors.lime, colors.green}
		R.subChoice = menu.menu(prompt, choices, pp, "Type number + Enter ")
	elseif R.choice == 33 then -- manage crop farm

	elseif R.choice == 34 then -- fence or wall
		R.length  	= menu.getInteger("Length of wall / fence (1-256)", 1, 256, nil, colors.orange)
		R.torchInterval = menu.getInteger("Torch spacing? (0-64)", 0, 64, nil, colors.red)
	elseif R.choice == 35 then -- rectangle fence or wall
		R.width 	= menu.getInteger("Width of the area (1-64)", 1, 64, nil, colors.yellow)
		R.length  	= menu.getInteger("Length of the area (1-64)", 1, 64, nil, colors.orange)
		R.torchInterval = menu.getInteger("Torch spacing? (0-64)", 0, 64, nil, colors.red)
	
-- 04. OBSIDIAN
	elseif R.choice == 41 then	-- Harvest obsidian
		R.width 	= menu.getInteger("Width of the area (1-64) ", 1, 64, nil, colors.yellow)
		R.length  	= menu.getInteger("Length of the area (1-64) ", 1, 64, nil, colors.orange)
	elseif R.choice == 42 or R.choice == 43 then -- build Nether portal / demolish Nether portal
		local choices = {"Facing portal: forward, turn right",
						 "Aligned with portal: start ahead"}
		pp.itemColours = {colors.pink, colors.red}
		local userChoice, modifier = menu.menu("Starting position?", choices, pp, "Type number + Enter ") -- 1 to 2
		R.subChoice = userChoice
		if modifier == "q" then -- quit chosen
			return R
		end
		R.length 	= menu.getInteger("Width of the portal ", 1, 64, nil, colors.yellow, nil, 4)
		R.height 	= menu.getInteger("Height of the portal ", 1, 64, nil, colors.lightGray, nil, 5)
		R.width 	= menu.getInteger("How deep (Enter = 1)", 1, 64, nil, colors.red, nil, 1)
		if menu.getBoolean("Base below surface (y/n)", nil, colors.orange) then
			R.data = "bury"
		end
	elseif R.choice == 44 then -- undermine dragon towers

	elseif R.choice == 45 then -- deactivate dragon tower
	
	elseif R.choice == 46 then -- build dragon water trap

	elseif R.choice == 47 then -- build end portal minecart station

	
-- 05. CANAL BRIDGE
	elseif R.choice == 51 then	--single path
		R.length 	= menu.getInteger("Path length? 0 = continuous ", 0, 1024, nil, colors.orange, nil, 64)
	elseif R.choice == 52 then	-- 2 block corridor / covered walkway
		R.length 	= menu.getInteger("Corridor length? 0 = continuous ", 0, 1024, nil, colors.orange, nil, 64)
		R.torchInterval = menu.getInteger("Torch spacing? (0-64)", 0, 64, nil, colors.red)
	elseif R.choice == 53 then	--left/right side of new/existing canal
		local line = getTaskHelp(2, 110, true, true) -- request line no of help display if needed for getInteger
		R.data = menu.getInteger("Choose method 1 or 2", 1, 2, line + 1, colors.white)
		menu.clear()
		line = getTaskHelp(2, R.choice, true, true) -- request line no of help display if needed for getInteger
		R.subChoice = menu.getInteger("Type position of turtle", 1, 6, line + 1, colors.white)
		local position = "on ground"
		local side = "left"
		local colour = colors.lime
		if R.subChoice == 1 then
			R.side = "L"
			R.height = 1
			position = "on ground"
			colour = colors.lime
		elseif R.subChoice == 2 then
			R.side = "L"
			R.height = 1
			position = "above canal"
			colour = colors.orange
		elseif R.subChoice == 3 then
			R.side = "R"
			R.height = 1
			position = "above canal"
			colour = colors.brown
		elseif R.subChoice == 4 then
			R.side = "R"
			R.height = 1
			side = "right"
			colour = colors.green
		elseif R.subChoice == 5 then
			R.side = "L"
			R.height = 0
			position = "on canal base"
			colour = colors.blue
		elseif R.subChoice == 6 then
			R.side = "R"
			R.height = 0
			position = "on canal base"
			side = "right"
			colour = colors.cyan
		end
		line = menu.clear()
		if R.data == 1 or (R.data == 2 and (R.subChoice == 1 or R.subChoice == 4)) then
			R.torchInterval = menu.getInteger("Torch spacing? (0-64)", 0, 64, line, colors.red, nil, 0)
		end
		-- menu.colourPrint(text, fg, bg, width)
		-- menu.colourText(row, text, reset)
		menu.colourPrint("Turtle placed "..side.." "..position, colour)
		R.length 	= menu.getInteger("Canal length? 0 = continuous ", 0, 2048, line + 2, colors.orange, nil, 64)
	elseif R.choice == 54 then	--ice canal 4 sections: edge+torch, edge, centre+ice, centre no ice
		local line = getTaskHelp(2, R.choice, true, true) -- request line no of help display if needed for getInteger
		R.subChoice = menu.getInteger("Type turtle position", 1, 6, line, colors.white)
		R.side = "L"
		local position = "on towpath"
		local side = "left"
		local colour = colors.lime
		line = menu.clear()
		if R.subChoice < 5 then
			R.torchInterval = menu.getInteger("Torch spacing? (0-64)", 0, 64, line, colors.red, nil, 0)
			if R.subChoice > 2 then
				side = "right"
				R.side = "R"
			end
			if R.subChoice == 1 or R.subChoice == 2 then
				-- menu.getBool(prompt, row, fg, bg, default)
				
				if menu.getBoolean("Place Ice as well? (y/n)", line + 1, colors.blue) then
					R.data = "ice"
				end
			end
		elseif R.subChoice == 5 then	
			R.data = "ice"
			position = "alternate air/ice"
			colour = colors.blue
		elseif R.subChoice == 6 then	
			position = "on air spaces"
			colour = colors.lightBlue
			side = "right"
			R.side = "R"
		end
		-- line = menu.clear()
		menu.colourPrint("Turtle on "..side.." side "..position, colour)
		R.length 	= menu.getInteger("Canal length? 0 = continuous ", 0, 2048, line + 2, colors.orange, nil, 64)
	elseif R.choice == 55 then	--platform
		R.width 	= menu.getInteger("Platform width", 1, 256, 1, colors.yellow)
		R.length 	= menu.getInteger("Platform length", 1, 256, 2, colors.orange)
		if menu.getBoolean("Remove blocks above? (y/n)",3, colours.red) then
			R.up = true
		end
		
	elseif R.choice == 56 then	--sinking platform
		R.width 	= menu.getInteger("Width (excluding retaining wall)? ", 1, 1024, nil, colors.yellow)
		R.length 	= menu.getInteger("Length (excluding retaining wall)? ", 1, 1024 / R.width, nil, colors.orange)
		R.height 	= menu.getInteger("Levels to go down?", 1, 1024 / R.width * R.length, nil, colors.blue)
	elseif R.choice == 57 then	--boat bubble lift
		R.height 	= menu.getInteger("Levels to go up?", 1, ceiling - 2, nil, colors.lightBlue)
	elseif R.choice == 58 then	--ice canal trapdoors
		R.subChoice = menu.getInteger("Am I on the left(0) or right(1)? ", 0, 1)
		R.length 	= menu.getInteger("Canal length? 0 = continuous ", 0, 2048, nil, colors.orange, nil, 64)
		
-- 06. MOB SPAWNER TOOLS
	elseif R.choice == 61 then -- create cube round mob spawner
		local text =
[[~yellow~Turtle placement options:

~lime~1. On top or in front of the spawner
   ~green~(cave spider OR no chests around)
~lightGray~2. Outside the dungeon at floor or
   ceiling level ~red~1 block from corner
~yellow~Make sure you have access to the block
facing the spawner, as any chests
found inside will be placed outside
the new dungeon wall at this height

~white~Enter to continue
]]
		menu.colourText(nil, text, true)
		read()
		local choices = {"Turtle on spawner (no chests)",
						 "Outside wall: left side, floor",
						 "Outside wall: left side, ceiling",
						 "Outside wall: right side, floor",
						 "Outside wall: right side, ceiling"}
		pp.itemColours = {colors.red, colors.lime, colors.orange, colors.green, colors.yellow}
		local userChoice, modifier = menu.new("Select turtle position", choices, pp) -- 1 to 5
		
		if modifier == "q" then -- quit chosen
			return "", R
		end
		R.subChoice 	= userChoice
		if R.subChoice > 1 then -- get dungeon wall dimensions
			R.width 	= menu.getInteger("Dungeon external width ", 0, 11, nil, colors.yellow, nil, 11)
			R.length 	= menu.getInteger("Dungeon external length ", 0, 11, nil, colors.orange, nil, 11)
		end
	elseif R.choice == 62 then -- Blaze spawner
		local text =
[[~yellow~Turtle placement options:

~red~1. On top of the spawner

~orange~2. At the same level, directly in front
   or in direct line to the spawner.
~yellow~   (can be behind a safety wall)

~lime~3. Continue build: in front of missing
   block in cube wall

~white~Enter to continue
]]
		menu.colourText(nil, text, true)
		read()
		pp.itemColours = {colors.red, colors.lime}
		R.subChoice = menu.new("Choose your option", {"New Blaze spawner", "Continuation (with killzone)"}, pp, "Type number + Enter") -- 1 = new, 2= continue
		if R.subChoice == 2 then
			R.data = "restart"
		end
	elseif R.choice == 63 then -- flood spawner cube
		local choices = {"Bubble lift", "Computercraft mob softener"}
		pp.itemColours = {colors.lime, colors.orange}
		local userChoice = menu.menu("Flood for Mob grinder type?", choices, pp, "Type number + Enter ")
		R.subChoice = userChoice -- 1 bubble, 2 computercraft
	elseif R.choice == 64 then -- create bubble lift at mob spawner
		local choices = {"Dropzone on left", "Dropzone on right"}
		pp.itemColours = {colors.lime, colors.orange}
		local userChoice = menu.menu("Which side do you want the mobs?", choices, pp, "Type number + Enter")
		R.subChoice = userChoice -- 1 left, 2 right
	elseif R.choice == 65 then -- Computercraft mob grinder
		local choices = {"Use Sticky pistons", "Use non-sticky pistons"}
		pp.itemColours = {colors.lime, colors.orange}
		local userChoice = menu.menu("Which type of pistons?", choices, pp, "Type number + Enter ")
		R.subChoice = userChoice -- 1 sticky, 2 normal
	
-- 07. AREA CARVING
	elseif R.choice == 71 then --Clear field
		R.width 	= menu.getInteger("Width of the area (1-64)", 1, 64, nil, colors.yellow)
		R.length  	= menu.getInteger("Length of the area (1-64)", 1, 64, nil, colors.orange)
		if menu.getBoolean("Dirt on the surface (y/n)", nil, colors.brown) then
			R.useBlockType = "dirt"
		end
	elseif R.choice == 72 then -- Clear solid rectangle R.width, R.length
		R.width 	= menu.getInteger("Rectangle width (1-256)", 1, 256, nil, colors.yellow)
		R.length  	= menu.getInteger("Rectangle length (1-256)", 1, 256, nil, colors.orange)
		R.up 		= menu.getBoolean("Remove blocks above?", nil, colors.yellow)
		R.down 		= menu.getBoolean("Remove blocks below?", nil, colors.orange)
		if menu.getBoolean("Am I outside clearing zone (y/n)?", nil, colors.yellow) then
			T:forward(1)
		end
	elseif R.choice == 73 then -- Clear wall
		R.width 	= 1
		R.length 	= menu.getInteger("Length of wall (1-256) ", 1, 256, nil, colors.orange)
		R.height 	= menu.getInteger("Height of wall (1-50) ", 1, 50, nil, colors.lightGray)
		pp.itemColours = {colors.lime, colors.orange}
		R.subChoice = menu.menu("Which direction?", {"Bottom -> Top", "Top -> Bottom"}, pp, "Type number + Enter ") -- open direction menu options
		if R.subChoice == 1 then
			if menu.getBoolean("Am I outside clearing zone (y/n)?", nil, colors.yellow) then
				T:forward(1)
			end
		else
			pp.itemColours = {colors.lightBlue, colors.cyan, colors.blue, colors.gray}
			local choice = menu.menu("Exact position?", {"On top of clearing zone", "In front of clearing zone", "Inside clearing zone","Above AND outside"}, pp, "Type number + Enter ") 
			if choice == 1 then
				T:down(1)
			elseif choice == 2 then
				T:forward(1)
			elseif choice == 4 then
				T:go("D1F1")
			end
		end
	elseif R.choice == 74 then -- Clear rectangle perimeter only R.width, R.length
		R.width 	= menu.getInteger("Perimeter width (1-256) ", 1, 256, nil, colors.yellow)
		R.length  	= menu.getInteger("Perimeter length (1-256) ", 1, 256, nil, colors.orange)
		R.height 	= 1
		if menu.getBoolean("Remove blocks above? (y/n)", 3, colours.red) then
			R.up = true
		end
		if menu.getBoolean("Remove blocks below? (y/n)", 4, colours.red) then
			R.down = true
		end
		if menu.getBoolean("Am I outside clearing zone (y/n)?", 5, colors.yellow) then
			T:forward(1)
		end
	elseif R.choice == 75 or R.choice == 76 then -- Clear hollow building floor/walls/ceiling OR clear solid object
		R.width 	= menu.getInteger("Structure width (1-256)", 1, 256, nil, colors.yellow)
		R.length  	= menu.getInteger("Structure length (1-256)", 1, 256, nil, colors.orange)
		R.height  	= menu.getInteger("Depth/Height (1-256)", 1, 256, nil, colors.lightGray)
		if R.choice == 75 then -- hollow building so need to check if floors/ceilings to be removed
			R.data = {}
			R.data.ceiling = false
			R.data.floor = false
			if menu.getBoolean("Remove ceiling? (y/n)", nil, colors.yellow, colors.black) then
				R.data.ceiling = true
			end
			if menu.getBoolean("Remove floor? (y/n)", nil, colors.orange, colors.black) then
				R.data.floor = true
			end
		end
		pp.itemColours = {colors.lime, colors.orange}
		R.subChoice = menu.menu("Which direction?", {"Bottom -> Top", "Top -> Bottom"}, pp, "Type number + Enter ") -- open direction menu options
		if R.subChoice == 1 then
			if menu.getBoolean("Am I outside clearing zone (y/n)?", nil, colors.yellow) then
				T:forward(1)
			end
		else
			pp.itemColours = {colors.lightBlue, colors.cyan, colors.blue, colors.gray}
			local choice = menu.menu("Exact position?", {"On top of clearing zone", "Outside clearing zone", "Inside clearing zone","Above AND outside"}, pp, "Type number + Enter ") 
			if choice == 1 then
				T:down(1)
			elseif choice == 2 then
				T:forward(1)
			elseif choice == 4 then
				T:go("D1F1")
			end
		end
	elseif R.choice == 77 then	-- Dig a trench
		R.height 	= menu.getInteger("Depth of the trench (1-64) ", 1, 64, nil, colors.blue)
		R.length 	= menu.getInteger("Trench length? 0 = continuous ", 0, 1024, nil, colors.orange)
	elseif R.choice == 78 then	-- Carve side of mountain
		pp.itemColours = {colors.lime, colors.orange}
		R.subChoice = menu.menu("Which side of me to remove?", {"Left", "Right"}, pp, "Type number + Enter ") -- open direction menu options
		R.width 	= menu.getInteger("Width of area to remove? ", 1, 1024, nil, colors.yellow)
		R.length 	= menu.getInteger("Length of area to remove? ", 0, 1024, nil, colors.orange)
	elseif R.choice == 79 then	-- Place a floor or ceiling
		local items = {	"Replacing current floor",
						"New floor over existing",
						"Replacing current ceiling",
						"New ceiling under existing"}
		pp.itemColours = {colors.lime, colors.orange, colors.green, colors.yellow}
		R.subChoice = menu.menu("Laying what?", items, pp, "Type number + Enter ")
		R.height = menu.getInteger({"Enter 0 for on-site placement",
								    "If in deep water or above reach",
									"Enter approx depth/height"}, 0, 64, nil, {colors.yellow, colors.blue, colors.cyan} )
		if R.subChoice < 3 then
			R.down = true
			R.width 	= menu.getInteger("Width of floor (1-64) ", 1, 64, nil, colors.yellow)
			R.length  	= menu.getInteger("Length of floor (1-64) ", 1, 64, nil, colors.orange)
		else
			R.up = true
			R.width 	= menu.getInteger("Width of ceiling (1-64) ", 1, 64, nil, colors.yellow)
			R.length  	= menu.getInteger("Length of ceiling (1-64) ", 1, 64, nil, colors.orange)
		end
	elseif R.choice == 710 or R.choice == 83 then -- Direct movement
		local choices = {"Simple path", "Covered 2 block high path"}
		pp.itemColours = {colors.lime, colors.orange}
		local userChoice = menu.menu("Choose your path option", choices, pp, "Type number + Enter ")
		R.subChoice	= userChoice -- 1 open, 2 covered
		choices = {"Command driven", "Menu driven"}
		userChoice = menu.menu("Choose your preference", choices, pp, "Type number + Enter ")
		if userChoice == 1 then
			R.data = "cmd"
		else
			R.data = "menu"
		end
		
-- 08. WATER LAVA
	elseif R.choice == 81 then -- Sand based utilities
		local line = getTaskHelp(2, R.choice, true, true) -- request line no of help display if needed for getInteger
		R.subChoice = menu.getInteger("Type number of choice", 1, 4, line, colors.white)
		T:clear()
		if R.subChoice == 1 then -- drop sand into water or lava surface until solid ground reached
			R.width	  = 1
			R.length  = menu.getInteger("Length of sand wall (0=to block) ", 0, 60, nil, colors.orange)
		elseif R.subChoice == 2 then	-- clear rectangle on top of building and fill with sand
			R.width   = menu.getInteger("Width of area (<=30) ", 1, 30, nil, colors.yellow)
			R.length  = menu.getInteger("Length of of area (<=30) ", 1, 30, nil, colors.orange)
		elseif R.subChoice == 3 then	-- clear sand wall or harvest sand
			R.width   = 1
			R.length  = menu.getInteger("Length of sand (0=auto-detect)", 0, 60, nil, colors.orange)
			choices = {"Stay at end of wall", "Return home"}
			pp.itemColours = {colors.lime, colors.orange}
			userChoice = menu.menu("Choose your preference", choices, pp, "Type number + Enter ")
			if userChoice == 2 then
				R.data = "return"
			end
		elseif R.subChoice == 4 then	-- remove sand from cube. start at top
			R.width   = menu.getInteger("Width of sand (<=30) ", 1, 30, nil, colors.yellow)
			R.length  = menu.getInteger("Length of of sand (<=30) ", 1, 30, nil, colors.orange)
			R.height  = 0
			R.data = "down" -- always starts at the top
		end
		if menu.getBoolean("Am I outside the active zone (y/n)?", nil, colors.yellow) then
			T:forward(1)
		end
	elseif R.choice == 82 then -- build wall from water or lava surface downwards
		R.width 	= 1
		if menu.getBoolean("Going 90 deg. from existing? (y/n)", nil, colors.yellow, colors.black) then
			getTaskHelp(2, 852, true)
			menu.clear()	
			R.length = 56
			R.data = "withPath" -- ensures turtle will break through path
			R.length = menu.getInteger({"Wall length minus corners","(Ocean monument default 56)","Number -> Enter or Enter only (56)"},
										1, 64, nil, {colors.yellow, colors.orange, colors.green}, colors.black, 56)
		else
			R.length 	= menu.getInteger("Length of the wall (1-60) ", 1, 60, nil, colors.yellow)
			R.height 	= menu.getInteger("Fixed depth or 0 = to floor ", 0, 60, nil, colors.yellow)
		end
	-- for 83 see 710
	elseif R.choice == 84 then -- Clear area of water bounded by blocks
		R.width 	= menu.getInteger("Width of water (0=autodetect) ", 0, 64, nil, colors.yellow)
		if R.width > 0 then
			R.length = menu.getInteger("Length of water", 1, 64, nil, colors.orange)
		end
		R.height 	= menu.getInteger("Depth of water (0=autodetect)", 0, 64, nil, colors.blue)
	elseif R.choice == 85 then -- Sinking platform
		R.width 	= menu.getInteger("Width (excluding retaining wall)? ", 1, 1024, nil, colors.yellow)
		R.length 	= menu.getInteger("Length (excluding retaining wall)? ", 1, 1024 / R.width, nil, colors.orange)
		R.height 	= menu.getInteger("Levels to go down?", 1, 1024 / R.width * R.length, nil, colors.blue)
	elseif R.choice == 86 then -- ocean monument utilities
		local items	= 
		{
			"Build 4 corner marker columns",
			"Retaining wall beween 2 columns",
			"Clear plants pre sand draining",
			"Drop sand wall",
			"Recover sand wall",
			"Sinking platform",
			"Drain and remove structure"	
		}
		pp.itemColours = {colors.lightGray, colors.brown, colors.blue, colors.yellow, colors.orange, colors.lightGray, colors.gray}
		R.subChoice = menu.menu("Which utility? ", items, pp)
		getTaskHelp(2, R.choice * 10 + R.subChoice, true)
		menu.clear()	
		if R.subChoice == 1 then -- Build 4 corner marker columns			
			R.useBlockType = "prismarine"
			R.data = "oceanMonumentColumns"
		elseif R.subChoice == 2 then -- Retaining wall beween 2 columns
			R.length = 56
			R.data = "withPath" -- ensures turtle will break through path
			T:clear()
			R.length = menu.getInteger({"Wall length minus corners","(Ocean monument default 56)","Number -> Enter or Enter only (56)"},
										 1, 64, nil, {colors.yellow, colors.orange, colors.green}, colors.black, 56)
		elseif R.subChoice == 3 then -- Clear plants pre sand draining
			R.useBlockType = "prismarine"
			R.data = "clearWaterPlants"
			R.silent = true
			R.width 	= menu.getInteger("water width (0=auto detect) ", 0, 64, nil, colors.yellow)
			R.length  	= menu.getInteger("water length (0=auto detect) ", 0, 64, nil, colors.orange)
		elseif R.subChoice == 4 then -- Drain using sand utilities
			R.width	  = 1
			R.length  = 0
		elseif R.subChoice == 5 then -- remove sand wall using sand utilities
			R.width	  = 1
			R.length  = 0
		elseif R.subChoice == 6 then -- sinking platform
			R.width = menu.getInteger("Width (excluding retaining wall)? ", 1, 1024, nil, colors.yellow)
			R.length = menu.getInteger("Length (excluding retaining wall)? ", 1, 1024 / R.width, nil, colors.orange)
			R.height = menu.getInteger("Levels to go down?", 1, 1024 / R.width * R.length, nil, colors.blue)
		elseif R.subChoice == 7 then -- Drain and remove structure
			R.width = 28
			R.length = 28
			R.height = menu.getInteger("Go down how far from current", 1, 64, nil, colors.blue)
		end
	elseif R.choice == 87 then -- Ladder to water/lava	
		R.height 	= menu.getInteger("est. height above (?F3) ", 1, 256, nil, colors.blue)
	elseif R.choice == 88 then -- Clear water plants from enclosed area
		R.data 		= "clearWaterPlants"
		R.width 	= menu.getInteger("water width (0=auto detect) ", 0, 64, nil, colors.yellow)
		R.length  	= menu.getInteger("water length (0=auto detect) ", 0, 64, nil, colors.orange)
	elseif R.choice == 89 then -- convert flowing water to source
		R.width 	= menu.getInteger("water width  (0=auto detect) ", 0, 64, nil, colors.yellow)
		if R.width > 0 then
			R.length = menu.getInteger("water length (0=auto detect) ", 0, 64, nil, colors.orange)
		end
		R.height 	= menu.getInteger("water depth (0=auto detect) ", 0, 64, nil, colors.blue)
	elseif R.choice == 810 then -- create sloping water
		R.width 	= menu.getInteger("water slope width (usually 7/8) ", 1, 8, nil, colors.yellow)
		R.length 	= menu.getInteger("water slope length ", 1, 64, nil, colors.orange)
	
-- 09. BUILDING & RAILWAY
	elseif R.choice == 91 then -- Build wall
		R.width 	= 1
		R.length 	= menu.getInteger("Length of wall (1-256) ", 1, 256, nil, colors.orange)
		R.height 	= menu.getInteger("Height of wall (1-50) ", 1, 50, nil, colors.lightGray)
		pp.itemColours = {colors.lime, colors.magenta}
		R.subChoice = menu.menu("What is my current position?", {"End of wall: Start ahead","Within the wall: start here"}, pp, "Type number + Enter")
	elseif R.choice == 92 then -- Build rectangular structure
		R.width 	= menu.getInteger("Building width (1-256)", 1, 256, nil, colors.yellow)
		R.length 	= menu.getInteger("Building length (1-256) ", 1, 256, nil, colors.orange)
		R.height 	= menu.getInteger("Building Height(1-50) ", 1, 50, nil, colors.lightGray)
		pp.itemColours = {colors.lime, colors.magenta}
		R.subChoice = menu.menu("What is my current position?", {"Outside building: Start ahead","Within the walls: start here"}, pp, "Type number + Enter")
	elseif R.choice == 93 or R.choice == 94 then -- Build gable roof / pitched roof
		R.width 	= menu.getInteger("Building width (1-256)", 1, 256, nil, colors.yellow)
		R.length 	= menu.getInteger("Building length (1-256) ", 1, 256, nil, colors.orange)
	elseif R.choice == 97 then -- build downward slope
		R.height  	= menu.getInteger("How many blocks down (0=to ground)?", 0, 256, nil, colors.blue)
		R.down = true
	elseif R.choice == 98 then -- build upward slope
		R.height  	= menu.getInteger("Go up by how many blocks?", 1, 256, nil, colors.lightGray)
		R.up = true
		
-- 10. MEASURING TOOLS
	elseif R.choice == 101 then -- measure height
		pp.itemColours = {colors.lightBlue, colors.cyan, colors.lime}
		R.subChoice	= menu.menu("Measure using?", {"Obstruction above", "No further blocks ahead", "Detect specific block ahead" }, pp, "Type number + Enter ") -- open direction menu options
		if R.subChoice == 3 then
			R.data = menu.getString({"Search for? eg 'ore', 'obsidian'",">"}, false, 3, 20, nil, {colors.lime, colors.yellow})
		end
		R.size = menu.getInteger("Max distance before abort?", 1, 1024, nil, colors.red, nil, 64)
	elseif R.choice == 102 then -- measure depth
		pp.itemColours = {colors.lime, colors.orange, colors.green}
		R.subChoice	= menu.menu("Measure using?", {"Water/Lava/Obstruction below", "No further blocks ahead", "Detect specific block ahead"}, pp, "Type number + Enter") -- open direction menu options
		if R.subChoice == 3 then
			R.data = menu.getString({"Search for? eg 'ore', 'obsidian'",">"}, false, 3, 20, nil, {colors.lime, colors.yellow})
		end
	elseif R.choice == 103 then -- measure length
		pp.itemColours = {colors.gray, colors.lime, colors.green, colors.blue, colors.cyan}
		R.subChoice	= menu.menu("Measure using?", {"Obstruction ahead",
													"No further blocks above",
													"No further blocks below",
													"Detect specific block above",
													"Detect specific block below"}, pp, "Type number + Enter") -- open direction menu options
		if R.subChoice == 4 or R.subChoice == 5 then
			R.data = menu.getString({"Search for? eg 'ore', 'obsidian'",">"}, false, 3, 20, nil, {colors.lime, colors.yellow})
		end
		R.size = menu.getInteger("Max distance before abort?", 1, 1024, nil, colors.red, nil, 64)
	elseif R.choice == 104 then -- measure greatest depth of water body
		pp.itemColours = {colors.lime, colors.orange}
		R.subChoice	= menu.menu("Measure using?", {"Player entered", "No further water below"}, pp, "Type number + Enter ") -- open direction menu options
		-- 1 = player entry, 2 = water length
		if R.subChoice == 1 then
			--R.length = utils.getSize(false, "water length (0=auto detect)", 0, 256)
			R.length = menu.getInteger("water length (0=auto detect) ", 0, 256)
		end
	elseif R.choice == 105 then -- drill borehole and write borhole.txt to file
		R.height = menu.getInteger("Current level (F3->Y coord)? ", bedrock + 5, ceiling, nil, colors.lightGray)
		R.depth = menu.getInteger("Go down to level? ("..R.height - 2 .." to "..bedrock + 5 ..")", bedrock + 5 ,R.height - 2, nil, colors.blue, nil, bedrock + 5)
	end
	
	return R
end

local function getTaskInventoryTo30(R)
	local retValue = {}
	local thanks = "Thank you.\n\nPress the ESC key\n\nStand Back..\n"
	--local pp = utils.getPrettyPrint()
	
	if R.choice == 0 then --Missing pickaxe
		T:checkInventoryForItem({"minecraft:diamond_pickaxe"}, {1})
		print("Diamond Pickaxe being tested...")
		T:setEquipment()
	elseif R.choice == 1 then --Missing crafting table
		T:checkInventoryForItem({"minecraft:crafting_table"}, {1}) -- 0 if not present
		print("Crafting table being tested...")
		T:setEquipment()
	elseif R.choice == 2 then --Missing chest
		T:checkInventoryForItem({"minecraft:chest"}, {1}) -- 0 if not present
		sleep(1.5)
		
	-- MINING
	
	elseif R.choice == 11 or R.choice == 12 then			-- ladder down / up / stairs down / stairs up
		local description = "Creating ladder going down"	-- default action description
		pp.itemColours = {colors.blue, colors.lightGray}
		pp.allowModifier = false -- only allow numbers to be returned
		local option = menu.menu("Which direction?", {"Going down","Going up"}, pp) 
		if option == 1 then
			R.down = true
			R.height = menu.getInteger("Current level (F3->Y coord)? ", bedrock + 5, ceiling, nil, colors.lightGray)
			R.depth = menu.getInteger("Go down to level? ("..R.height - 2 .." to "..bedrock + 5 ..") ", bedrock + 5 , R.height - 2, nil, colors.blue)
			if R.choice == 11 then
				if menu.getBoolean("Build a shelter at base? (y/n) ", nil, colors.yellow, colors.black) then
					R.data = "chamber"
				end
			end
			if R.choice == 13 then
				description = "Creating stairs going down"
			end
		else
			R.up = true
			--R.depth = utils.getSize(true,"Current level (F3->Y coord)? ", bedrock + 5, ceiling)
			--R.height = utils.getSize(true, "Go up to level? ("..R.depth + 2 .." to "..ceiling ..")", R.depth + 2, ceiling)
			R.depth = menu.getInteger("Current level (F3->Y coord)? ", bedrock + 5, ceiling, nil, colors.blue)
			R.height = menu.getInteger("Go up to level? ("..R.depth + 2 .." to "..ceiling ..") ", R.depth + 2, ceiling, nil, colors.lightGray)
			if R.choice == 11 then
				description = "Creating ladder going up"
			else
				description = "Creating stairs going up"
			end
		end
		local range = math.abs(R.height - R.depth)
		local inAir = menu.getBoolean("Are you in air or nether? (y/n) ", nil, colors.yellow, colors.black)
		--[[
		range examples
		-50 to -59 = -59 -(-50) = -9   down
		-59 to -50 = -50 -(-59) = 9    up
		 70 to -48 = -48 -   70 = -118 down
		  5 to  64 =  64 -   5  = 59   up
		]]
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		if R.choice == 11 then -- ladders
			utils.checkFuelNeeded(range * 2)
			T:checkInventoryForItem({"minecraft:ladder"}, {range})
			T:checkInventoryForItem({"minecraft:torch"}, {math.floor(range / 3)}, false)
			if inAir then
				range = range * 4 -- more blocks needed
			end
			T:checkInventoryForItem({"stone"}, {range})
		else -- stairs
			utils.checkFuelNeeded(range * 10) -- stairs: each layer needs 10 moves
			local numStairsNeeded = range
			local data = T:getStock("stairs")
			local numStairs = data.total
			local cobbleNeeded = math.min(range * 6, 256)
			if inAir then
				cobbleNeeded = range * 6 -- 5 blocks / layer unless in water or lava
			end
			if numStairs < numStairsNeeded then
				cobbleNeeded = cobbleNeeded + (math.floor((2 * (numStairsNeeded - numStairs)) / 3))
			end
			T:checkInventoryForItem({"stairs"}, {numStairsNeeded}, false)
			T:checkInventoryForItem({"stone"}, {cobbleNeeded})
			T:checkInventoryForItem({"minecraft:chest"}, {1}) 	-- needed for crafting
		end
		print(thanks)
		print(description)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		if R.choice == 11 then
			retValue = createLadder(R) -- "bedrock", 70, -48
		else
			retValue = createStaircase(R)
		end
	elseif R.choice == 13 then --Create Mine at this level
		utils.checkFuelNeeded(960)
		T:checkInventoryForItem({"minecraft:torch"}, {24}, false)
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"minecraft:chest"}, {1})
		sleep(2)
		print("CreateMine starting")
		retValue = createMine()
	elseif R.choice == 14 then	-- safe drop to water
		utils.checkFuelNeeded(R.height * 2)
		T:checkInventoryForItem({"minecraft:water_bucket"}, {1})
		T:checkInventoryForItem({"stone"}, {R.height * 2}, false) -- estimate only partial cloaking needed
		print(thanks)
		print("Creating safe drop ".. R.height.. " blocks deep")
		print("Wait for my return!")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createSafeDrop(R)
	elseif R.choice == 15 then	-- single column bubble lift
		utils.checkFuelNeeded(R.height * 6)
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		T:checkInventoryForItem({"sign"}, {2})
		T:checkInventoryForItem({"stone"}, {R.height * 2}, false) -- estimate only partial cloaking needed
		_, slots = T:getFirstEmptySlot() -- returns first empty slot, no of empty slots
		T:checkInventoryForItem({"minecraft:bucket"}, {slots}, false, "More buckets for speed!")
		print(thanks)
		print("Creating bubble lift ".. R.height.. " blocks high")
		print("Wait at the top via ladder...")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createBubbleLift(R)
	
	elseif R.choice == 16 then --QuickMine corridor
		utils.checkFuelNeeded((R.width * 2 + R.length * 2) * 2)
		T:checkInventoryForItem({"stone"}, {R.width * 2 + R.length * 2}, false)
		T:checkInventoryForItem({"minecraft:torch"}, {math.floor((R.width * 2 + R.length * 2) / R.torchInterval)}, false)
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		print("QuickMine corridor: R.subChoice "..R.width.. " x "..R.length)
		retValue = quickMineCorridor(R)
	elseif R.choice == 17 then --QuickMine
		utils.checkFuelNeeded(R.width * R.length)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		print("QuickMine rectangle: R.subChoice "..R.width.. " x "..R.length)
		retValue = quickMine(R)
	elseif R.choice == 18 then --Mine bedrock area
		utils.checkFuelNeeded(R.width * R.length)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		retValue = mineBedrockArea(R) -- R.data = "leaveExposed" or ""
	elseif R.choice == 19 then	-- salvage mineshaft
		local equippedRight, equippedLeft, inInventory = T:setEquipment() -- check for crafting table, sword, pickaxe, Put sword in spare slot
		if equippedLeft ~= "minecraft:diamond_pickaxe" and equippedRight ~= "minecraft:diamond_pickaxe" then
			T:checkInventoryForItem({"minecraft:diamond_pickaxe"}, {1}, true)
			equippedRight, equippedLeft, inInventory = T:setEquipment() -- check for crafting table, sword, pickaxe, Put sword in spare slot
		end
		if inInventory ~= "minecraft:diamond_sword" then
			T:checkInventoryForItem({"minecraft:diamond_sword"}, {1}, false, "To harvest spider webs\nyou need a diamond sword.") --checkInventoryForItem(self, items, quantities, required, message, name)
		end
		if T:getItemSlot("minecraft:diamond_sword") > 0 then
			inInventory = "minecraft:diamond_sword"
		end
		T:checkInventoryForItem({"minecraft:torch"}, {8}, false)
		if inInventory == "minecraft:diamond_sword" then
			print("Clearing Mineshaft and cobwebs")
		else
			print("Clearing Mineshaft")
		end
		retValue = clearMineshaft(equippedRight, equippedLeft, inInventory) -- pass whether the sword is present
		
	-- FORESTRY
	elseif R.choice == 21 then	-- Fell tree
		if T:isLog("forward") then
			if turtle.getFuelLevel() < 30 then
				T:checkInventoryForItem({"minecraft:chest"}, {1}, false,"Fuel level critical: "..turtle.getFuelLevel())
				turtle.select(1)
				T:dig("forward")
				T:craft("planks", 4)
				T:refuel()
				T:forward(1)
				T:up(2)
				T:craft("chest", 1)
			else
				T:forward(1)
			end
			print("Press esc within 2 seconds!")
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
			print("Felling tree")
			T:harvestWholeTree("up")
			while turtle.down() do end
			retValue = {"Tree Harvested"}
		else
			retValue =
			{
				"No log in front..",
				"Move me in front of a tree!"
			}
		end
	elseif R.choice == 22 then --Create treefarm
		utils.checkFuelNeeded(900)
		--T:checkInventoryForItem({"minecraft:dirt"}, {16})
		T:checkInventoryForItem({"stone"}, {320})
		T:checkInventoryForItem({"polished"}, {4}) -- used to mark launch positions
		T:checkInventoryForItem({"minecraft:water_bucket"}, {5})
		R.useBlockType = T:getMostItem("", true)
		print(thanks)
		sleep(2)
		print("Creating Tree Farm with "..R.useBlockType)
		retValue = createTreefarm(R)
	elseif R.choice == 23 then -- Plant treefarm
		if R.subChoice == 1 then
			utils.checkFuelNeeded(180)
			T:checkInventoryForItem({"dirt"}, {16})
			T:checkInventoryForItem({"sapling"}, {4}, "Max 16. NOT dark oak")
		elseif R.subChoice == 3 then
			utils.checkFuelNeeded(180)
			T:checkInventoryForItem({"dirt"}, {16})
			T:checkInventoryForItem({"sapling"}, {4}, "Max 16. 4 saplings / tree")
		end
		print(thanks)
		print("plantTreefarm starting: size "..R.subChoice)
		retValue = plantTreefarm(R)
	elseif R.choice == 24 then	-- Harvest treefarm
		print(thanks)
		os.sleep(2)
		print("Harvesting treefarm starting")
		retValue = harvestTreeFarm(R)
	elseif R.choice == 25 then	-- Build wall / fence
		utils.checkFuelNeeded(R.width * R.length * 2)
		local quantity = math.ceil((R.width + R.length) * 2.3)
		T:checkInventoryForItem({"wall", "fence"}, {quantity, quantity})
		if R.torchInterval > 0 then
			T:checkInventoryForItem({"minecraft:torch"}, {math.floor(quantity / R.torchInterval)}, false)
		end
		if R.data == "barrel" then
			T:checkInventoryForItem({"barrel"}, {4}, false)
		end
		R.useBlockType = T:getMostItem("", true)
		print("Creating "..R.width.." x "..R.length.." walled enclosure with "..R.useBlockType)
		retValue = createWallOrFence(R)
	elseif R.choice == 26 then	-- clear natural forest
		T:checkInventoryForItem({"minecraft:chest"}, {1})
		T:checkInventoryForItem({"sapling"}, {64}, false)
		print(thanks)
		print("Clearing and replanting trees")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = clearAndReplantTrees()
	end
	return retValue
end

local function getTaskInventoryTo70(R)
	local retValue = {}
	local thanks = "Thank you.\n\nPress the ESC key\n\nStand Back..\n"
	-- FARMING
	if R.choice == 31 then	-- Create modular farm
		utils.checkFuelNeeded(300)
		T:checkInventoryForItem({"cobble"}, {64})
		T:checkInventoryForItem({"dirt"}, {128}, false)
		T:checkInventoryForItem({"water_bucket"}, {4})
		T:checkInventoryForItem({"chest", "barrel"}, {5,5})
		T:checkInventoryForItem({"sapling"}, {1})
		T:checkInventoryForItem({"crafting"}, {1}) -- will be placed inside barrel / chest next to water source
		R.useBlockType = T:getMostItem("dirt", true) -- exclude dirt from count
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Creating modular farm with "..R.useBlockType)
		retValue = createFarm(R, false)
	elseif R.choice == 32 then	-- Extend modular farm
		utils.checkFuelNeeded(300)
		T:checkInventoryForItem({"cobble"}, {64})
		T:checkInventoryForItem({"dirt"}, {128}, false)
		T:checkInventoryForItem({"water_bucket"}, {4})
		T:checkInventoryForItem({"chest", "barrel"}, {5,5})
		T:checkInventoryForItem({"sapling"}, {1})
		T:checkInventoryForItem({"crafting"}, {1})
		R.useBlockType = T:getMostItem("dirt", true) -- exclude dirt from count
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Checking position...\n")
		retValue = createFarmExtension(R) -- subChoice = 1 for ahead, 2 for to the right
	elseif R.choice == 33 then	-- manage modular farm
		-- inventory checked in function depending on option taken
		R.data = "farm"
		retValue = manageFarmSetup(R)
	elseif R.choice == 34 then	-- build single fence
		utils.checkFuelNeeded(R.length)
		T:checkInventoryForItem({"wall", "fence"}, {R.length, R.length})
		if R.torchInterval > 0 then
			T:checkInventoryForItem({"minecraft:torch"}, {math.ceil(R.length / R.torchInterval)}, false)
		end
		R.useBlockType = T:getMostItem("minecraft:torch") -- exclude torch
		print("Creating "..R.length.." wall or fence with "..R.useBlockType)
		retValue = createWallOrFence(R) -- barrels not included in R.data, R.width = 0 so only single length
	elseif R.choice == 35 then	-- build fence
		utils.checkFuelNeeded(R.width * R.length * 2)
		local quantity = math.ceil((R.width + R.length) * 2.3)
		T:checkInventoryForItem({"wall", "fence"}, {quantity, quantity})
		if R.torchInterval > 0 then
			T:checkInventoryForItem({"minecraft:torch"}, {math.floor(quantity / R.torchInterval)}, false)
		end
		R.useBlockType = T:getMostItem("minecraft:torch") -- exclude torch
		print("Creating "..R.width.." x "..R.length.." walled enclosure with "..R.useBlockType)
		retValue = createWallOrFence(R) -- barrels not included in R.data
	-- OBSIDIAN
	elseif R.choice == 41 then --harvest obsidian
		utils.checkFuelNeeded(R.width * R.length * 3)
		T:checkInventoryForItem({"stone"}, {R.width * R.length})
		print(thanks)
		sleep(2)
		print("Harvesting obsidian area: size "..R.width.. " x "..R.length)
		retValue = harvestObsidian(R)
	elseif R.choice == 42 then --build nether portal
		utils.checkFuelNeeded(R.length * R.height * R.width)
		T:checkInventoryForItem({"minecraft:obsidian"}, {(R.length * R.height * R.width) - (R.width * 4)})
		T:checkInventoryForItem({"stone"}, {R.width * 4})
		R.useBlockType = T:getMostItem("obsidian", true) -- exclude obsidian from count
		print(thanks)
		sleep(2)
		print("Building Nether portal")
		retValue = createPortal(R)
	elseif R.choice == 43 then --demolish nether portal
		utils.checkFuelNeeded(20)
		print("Demolishing Nether portal")
		retValue = demolishPortal(R)
	elseif R.choice == 44 then --undermine dragon towers
		utils.checkFuelNeeded(500)
		T:checkInventoryForItem({"minecraft:cobblestone", "minecraft:cobbled_deepslate"}, {84, 84})
		print("Undermining dragon towers")
		retValue = undermineDragonTowers()
	elseif R.choice == 45 then --deactivate dragon tower
		utils.checkFuelNeeded(50)
		print("Deactivating dragon tower")
		retValue = deactivateDragonTower()
	elseif R.choice == 46 then --build dragon water trap
		utils.checkFuelNeeded(256)
		T:checkInventoryForItem({"stone"}, {356})
		T:checkInventoryForItem({"minecraft:obsidian"}, {1})
		T:checkInventoryForItem({"minecraft:ladder"}, {145})
		T:checkInventoryForItem({"minecraft:water_bucket"}, {1})
		print("Building dragon water trap")
		retValue = createDragonTrap()
	elseif R.choice == 47 then --build portal minecart station
		utils.checkFuelNeeded(200)
		menu.colourPrint("Inventory after height measurement", colors.red)
		menu.colourPrint("Enter to start measurement.", colors.lime)
		read()
		print("Building portal platform")
		retValue = createPortalPlatform()
		
	-- CANAL BRIDGE
	elseif R.choice == 51 then	-- continuous path over void/water/lava
		utils.checkFuelNeeded(512) -- allow for 512 R.length
		T:checkInventoryForItem({"stone"}, {R.length}, false)
		--T:checkInventoryForItem({"minecraft:cobblestone",  "minecraft:dirt"}, {64, 64}, false)
		T:checkInventoryForItem({"minecraft:torch"}, {math.floor(R.length/8)}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building continuous path")
		retValue = utils.createPath(R) -- returns {numBlocks}
	elseif R.choice == 52 then	-- simple 2 block corridor
		utils.checkFuelNeeded(R.length)
		T:checkInventoryForItem({"stone"}, {R.length * 2}, false)
		if R.torchInterval > 0 then
			T:checkInventoryForItem({"minecraft:torch"}, {math.ceil(R.length / R.torchInterval)}, false)
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building simple corridor")
		retValue = createCorridor(R)
	elseif R.choice == 53 then	-- canal management
		local torches = 0
		local length = R.length
		if length > 0 then
			utils.checkFuelNeeded(length * 4) -- allow for 1024 R.length
			if R.torchInterval > 0 then
				torches = math.floor(length / R.torchInterval)
			end
		else
			utils.checkFuelNeeded(2048) -- allow for 1024 R.length
			length = 256
		end
		T:checkInventoryForItem({"stone"}, {length * 2})
		if R.data == 1 or (R.data == 2 and (R.subChoice == 2 or R.subChoice == 3 or R.subChoice == 5 or R.subChoice == 6)) then
			T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		end
		if torches > 0 then
			T:checkInventoryForItem({"minecraft:torch"}, {torches}, false)
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building canal")
		if R.data == 1 then
			retValue = createCanal(R) -- eg 0, 312, 1 = complete a canal 312 blocks long on top of the wall
		else
			retValue = createWaterCanal(R)
		end
	elseif R.choice == 54 then	-- ice canal
		local default = R.length
		if R.length > 0 then
			utils.checkFuelNeeded(R.length)
		else
			default = 64
			utils.checkFuelNeeded(default * 2) -- allow for 128 min R.length
		end
		--R.subChoice = 1,2,3,4 edge+torch, ice canal, air, edge no torch
		if R.subChoice < 5 then	-- towpath with torches
			--T:checkInventoryForItem({"trapdoor"}, {default})
			T:checkInventoryForItem({"slab"}, {default})
			if R.torchInterval > 0 then
				T:checkInventoryForItem({"stone"}, {math.ceil(default / R.torchInterval)})
				T:checkInventoryForItem({"torch"}, {math.ceil(default / R.torchInterval)}, false)
			end
		end
		if R.subChoice == 5 or R.data == "ice" then	-- ice canal with 2 spaces above
			T:checkInventoryForItem({"minecraft:packed_ice", "minecraft:blue_ice"}, {math.ceil(R.length / 2), math.ceil(R.length / 2)}, false)
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building ice canal")
		retValue = createIceCanal(R)
	elseif R.choice == 55 then -- platform
		local volume = R.width * R.length
		utils.checkFuelNeeded(volume)
		T:checkInventoryForItem({"stone", "dirt"}, {volume, volume})
		R.useBlockType = T:getMostItem("", true) 
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building platform")
		retValue = createPlatform(R)
	elseif R.choice == 56 then -- sinking platform
		local volume = (R.width + 1) * (R.length + 1) 
		utils.checkFuelNeeded(volume * (R.height + 1))
		T:checkInventoryForItem({"stone"}, {volume + ((R.length * 2) + (R.width * 2) * R.height) + 1})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building sinking platform")
		retValue = createSinkingPlatform(R)
	elseif R.choice == 57 then -- boat bubble lift
		utils.checkFuelNeeded(R.height * 20)
		T:checkInventoryForItem({"minecraft:bucket","minecraft:water_bucket"}, {2, 2})
		T:checkInventoryForItem({"stone"}, {R.height * 10})
		T:checkInventoryForItem({"gate"}, {R.height * 2})
		T:checkInventoryForItem({"minecraft:soul_sand"}, {R.height * 2 + 2})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building boat bubble lift")
		retValue = createBoatLift(R)
		--retValue = createBoatLift(R) -- R.subChoice:0=new, R.subChoice:1=extend, R.length:0=left, 1=right
	elseif R.choice == 58 then	-- ice canal borders with trapdoors/slabs
		local default = R.length
		if R.length > 0 then
			utils.checkFuelNeeded(R.length)
		else
			default = 64
			utils.checkFuelNeeded(default * 2) -- allow for 128 min R.length
		end
		T:checkInventoryForItem({"trapdoor"}, {default})
		T:checkInventoryForItem({"slab"}, {default})
		T:checkInventoryForItem({"stone"}, {math.ceil(default / 8)})
		T:checkInventoryForItem({"torch"}, {math.ceil(default / 8)}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building ice canal barrier")
		retValue = createIceCanalBorder(R) -- 0 R.length = continue while supplies last
		
	-- MOB SPAWNER
	elseif R.choice == 61 then	--  9x9 hollow cube cobble lined
		utils.checkFuelNeeded(600) -- allow for 600 moves
		T:checkInventoryForItem({"stone"}, {512}, false, "Full cube uses ~700 blocks\nEstimate your requirements")
		T:checkInventoryForItem({"slab"}, {1})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createMobFarmCube(R, false) -- not blaze
	elseif R.choice == 62 then	-- Blaze spawner
		utils.checkFuelNeeded(2500) -- allow for 2500 moves
		if R.subChoice == 1 then
			T:checkInventoryForItem({"stone"}, {320})
			T:checkInventoryForItem({"slab"}, {1})
			print("You will be asked for more assets later")
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
		end
		retValue = createMobFarmCube(R, true)	
	elseif R.choice == 63 then	--  flood mob spawner
		utils.checkFuelNeeded(60) -- allow for 60 moves
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		if R.subChoice == 1 then
			T:checkInventoryForItem({"fence"}, {2})
			T:checkInventoryForItem({"sign"}, {2})
			T:checkInventoryForItem({"slab"}, {1})
			T:checkInventoryForItem({"minecraft:soul_sand", "minecraft:dirt"}, {1, 1}, true)
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = floodMobFarm(R)
	elseif R.choice == 64 then -- build bubble lift on top of soul sand
		utils.checkFuelNeeded(200) -- allow for 200 moves
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"stone"}, {128})
		if T:getBlockType("down") ~= "minecraft:soul_sand" then
			T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createMobBubbleLift(R)
	elseif R.choice == 65 then -- computercraft mob grinder
		utils.checkFuelNeeded(1000) -- allow for 1000 moves
		T:checkInventoryForItem({"stone"}, {256}) -- for ceiling, walls and floor of area
		R.useBlockType = T:getMostItem("", true) -- stone only, no exclusions
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createMobGrinder(R)
	elseif R.choice == 66 then -- build endermen tower
		-- build in 3 sections, base, tower, top
		getTaskHelp(2, 66) -- compulsory help display
		read() -- pause until user ready
		local numFuel = 700
		local choices = 
		{
			"New tower lower base",
			"Add tower upper base + killzone",
			"128 block tower to existing base"
		}
		pp.itemColours = {colors.lime, colors.orange, colors.green}
		local option, modifier = menu.menu("Select build stage:", choices, pp)
		if option == 1 then --lower base
			T:checkInventoryForItem({"minecraft:chest"}, {1})
			T:place("chest", -1, "down", false)
			T:emptyInventory("up")
			utils.checkFuelNeeded(320) -- allow for 320 moves
			T:checkInventoryForItem({"stone"}, {144}) -- <3 stacks
			T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
			T:checkInventoryForItem({"fence"}, {4})
			T:checkInventoryForItem({"sign"}, {4})
			T:checkInventoryForItem({"door"}, {2})
			T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		elseif option == 2 then -- upper base
			utils.checkFuelNeeded(710) -- allow for 703 moves
			T:checkInventoryForItem({"stone"}, {384}) -- 6 stacks
			T:checkInventoryForItem({"minecraft:bucket"}, {4})
			T:checkInventoryForItem({"fence"}, {15})
			T:checkInventoryForItem({"sign"}, {4})
			T:checkInventoryForItem({"ladder"}, {3})
			T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		else -- main tower
			utils.checkFuelNeeded(3000) -- allow for 3000 moves
			if T:getBlockType("down") ~= "minecraft:chest" then
				T:checkInventoryForItem({"minecraft:chest"}, {1})
				T:place("chest", -1, "down", false)
			end
			T:checkInventoryForItem({"stone"}, {768}) -- 12 stacks
			T:checkInventoryForItem({"minecraft:bucket"}, {10})
			T:checkInventoryForItem({"fence"}, {64})	-- 1 stacks		
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createEnderTower(option) -- 1, 2, or 3
	end
	return retValue
end

local function getTaskInventory(R)
	-- run this loop 2x per second to check if player has put anything in the inventory
	-- fuel 1 coal = 60 = 4 planks. 64 planks = 16 coal = 960 units
	local retValue = {}
	local thanks = "Thank you.\n\nPress the ESC key\n\nStand Back..\n"
	
	if R.choice < 31 then 
		return getTaskInventoryTo30(R) -- Mining, Forestry
	elseif R.choice < 71 then
		return getTaskInventoryTo70(R) -- Farming, Obsidian, Canal / Bridge
	elseif R.choice > 500 and R.choice < 700 then
		return getTaskInventoryTo70(R)
	else -- Area carving, Lava/Water, Railway
		-- AREA CARVING
		if R.choice == 71 then--Clear area
			utils.checkFuelNeeded(R.width * R.length * 3)
			if R.useBlockType == "dirt" then
				T:checkInventoryForItem({"minecraft:dirt"}, {R.width * R.length})
			end
			print(thanks)
			sleep(2)
			print("Clearing area: size "..R.width.. " x "..R.length)
			retValue = clearArea(R, true)
		elseif R.choice == 72 then --Clear rectangle
			-- R.choice, R.width(R.subChoice), R.length(R.width), up(R.length), down(R.height) from getTask()
			utils.checkFuelNeeded(R.width * R.length)
			print("Clearing rectangle: size "..R.width.. " x "..R.length)
			retValue = clearRectangle(R)
		elseif R.choice == 73 then --Clear wall
			utils.checkFuelNeeded(R.length * R.height)
			print("Removing wall "..R.length.." long x "..R.height.." high")
			retValue = clearWall(R)
		elseif R.choice == 74 then --Clear single R.height perimeter wall
			utils.checkFuelNeeded((R.width + R.length) * 2)
			print("Recycling wall section "..R.width.." x "..R.length)
			retValue = clearPerimeter(R)
		elseif R.choice == 75 then --Clear hollow structure
			utils.checkFuelNeeded((R.width * R.length) + ((R.width + R.length) * R.height))
			print("Recycling hollow object "..R.width.." x "..R.length.." height: "..R.height)
			retValue = clearBuilding(R)
		elseif R.choice == 76 then --Clear solid structure / extend water pool
			utils.checkFuelNeeded((R.width * R.length) + ((R.width + R.length) * R.height))
			print("Recycling solid object w:"..R.width..", l:"..R.length..", h:"..R.height)
			retValue = clearSolid(R)
		elseif R.choice == 77 then	-- Dig trench
			utils.checkFuelNeeded(R.height * R.length * 2)
			print(thanks)
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
			if R.length == 0 then
				print("Digging continuous trench "..R.height.." blocks deep")
			else
				print("Digging trench "..R.length.." blocks long, "..R.height.." blocks deep")
			end
			retValue = digTrench(R)
		elseif R.choice == 78 then --Carve mountain
			utils.checkFuelNeeded(R.length * R.width * 10)
			print("Carving mountain side "..R.width.." x "..R.length)
			retValue = clearMountainSide(R)
		elseif R.choice == 79 then -- Place floor or Ceiling
			local blocks = R.width * R.length
			utils.checkFuelNeeded(blocks)
			T:checkInventoryForItem({"stone", "log", "planks"}, {blocks, blocks, blocks}, false)
			R.useBlockType = T:getMostItem()
			retValue = createFloorCeiling(R) -- R.subChoice integer 1 to 4
		elseif R.choice == 710 then -- direct commands
			utils.checkFuelNeeded(200)
			createRectanglePath(R)
			
-- LAVA WATER
		elseif R.choice == 81 then -- Sand based utilities
			if R.subChoice == 1 then	-- Drop sand or gravel wall
				utils.checkFuelNeeded(100)
				T:checkInventoryForItem({"sand", "gravel"}, {1024, 1024}, false)
				if R.length == 0 then
					print("Building sand wall. Auto length: ")
				else
					print("Building sand wall. length: "..R.length)
				end
				retValue = createSandWall(R)
			elseif R.subChoice == 2 then	-- Fill area with sand
				utils.checkFuelNeeded(R.length * R.width)
				T:checkInventoryForItem({"sand"}, {1024}, false)
				print("Filling area with sand. length: "..R.length.." width: "..R.width)
				retValue = sandFillArea(R)
			elseif R.subChoice == 3 then -- Clear sand wall
				utils.checkFuelNeeded(200)
				if R.length == 0 then
					print("Digging sand. Auto length")
				else
					print("Digging sand. length: "..R.length)
				end
				retValue = clearSandWall(R)
			elseif R.subChoice == 4 then	-- Clear sand filled area
				utils.checkFuelNeeded(R.length * R.width * 4)
				print("Removing sand cube. length: "..R.length.." width: "..R.width)
				retValue = clearSandCube(R)
			end
		
		elseif R.choice == 82 then --build containing wall in water or lava
			utils.checkFuelNeeded(R.length * R.length)
			local depth = R.height
			if depth == 0 then
				depth = 20
			end
			T:checkInventoryForItem({"stone"}, {R.length * depth}, false)
			print("Building retaining wall in lava/water. length "..R.length)
			retValue = createRetainingWall(R)			
		elseif R.choice == 83 then -- create a rectangle path in water/lava
			utils.checkFuelNeeded(200)
			createRectanglePath(R)
		elseif  R.choice == 84 then -- Delete water/lava
			if R.width == 0 then
				utils.checkFuelNeeded(2000)
				T:checkInventoryForItem({"stone"}, {256}, false)
				print("Deleting water using auto-detection")
			else
				if R.height == 0 then
					utils.checkFuelNeeded(2000)
					T:checkInventoryForItem({"stone"}, {256}, false)
				else
					utils.checkFuelNeeded(R.width * R.length * R.height)
					T:checkInventoryForItem({"stone"}, {math.max(R.length, R.width) * 2}, false)
				end
				print("Deleting enclosed water "..R.width.." x "..R.length.." x ".. R.height)
			end
			retValue = utils.drainWaterLava(R)
		elseif  R.choice == 85 then -- Sinking platform
			local volume = (R.width + 1) * (R.length + 1) 
			utils.checkFuelNeeded(volume * (R.height + 1))
			T:checkInventoryForItem({"stone"}, {volume + ((R.length * 2) + (R.width * 2) * R.height) + 1})
			print(thanks)
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
			print("Building sinking platform")
			retValue = createSinkingPlatform(R)
		elseif R.choice == 86 then -- ocean monument utilities
			if R.subChoice == 1 then	-- Build 4 corner marker columns
				--R.useBlockType = "prismarine", R.data = "oceanMonumentColumns"
				T:checkInventoryForItem({"stone"}, {448})
				retValue = oceanMonumentColumns(R)
			elseif R.subChoice == 2 then	-- Retaining wall beween 2 columns
				T:checkInventoryForItem({"stone"}, {1024})
				retValue = createRetainingWall(R)
			elseif R.subChoice == 3 then	-- Clear plants pre sand draining
				retValue = clearWaterPlants(R)
			elseif R.subChoice == 4 then	-- Use sand draining
				utils.checkFuelNeeded(100)
				T:checkInventoryForItem({"sand", "gravel"}, {1024, 1024}, false)
				if R.length == 0 then
					print("Building sand wall. Auto length: ")
				else
					print("Building sand wall. length: "..R.length)
				end
				retValue = createSandWall(R)
			elseif R.subChoice == 5 then	-- remove sand wall
				utils.checkFuelNeeded(200)
				print("Digging sand from ocean monument")
				retValue = clearSandWall(R)
			elseif R.subChoice == 6 then	-- Drain and remove structure
				T:checkInventoryForItem({"stone"}, {1024})
				retValue = utils.drainWaterLava(R)
			end
		elseif R.choice == 87 then --ladder to water/lava
			utils.checkFuelNeeded(R.height * 2)
			T:checkInventoryForItem({"minecraft:ladder"}, {R.height}, true, "Add more to be safe!")
			local cobble = R.height * 3 + 10
			T:checkInventoryForItem({"stone"}, {cobble})
			print(thanks)
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
			print("Creating ladder to bedrock")
			retValue = createLadderToWater()
		elseif R.choice == 88 then --remove plants
			utils.checkFuelNeeded(R.length * R.width * 4)
			T:checkInventoryForItem({"sand", "stone"}, {64, 64})
			local width = R.width
			local length = R.length
			if width == 0 then
				width = "auto"
			end
			if length == 0 then
				length = "auto"
			end
			print("Removing water plants. length: "..length.." width: "..width)
			retValue = clearWaterPlants(R)
		elseif R.choice == 89 then -- convert flowing water to source
			--utils.checkFuelNeeded(R.length * R.width * 4) -- unknown as size not calculated
			T:checkInventoryForItem({"water_bucket", "bucket"}, {12, 12})
			T:checkInventoryForItem({"slab"}, {128})
			print("Converting water to source "..R.width.." x "..R.length.." x ".. R.height)
			retValue = convertWater(R)
		elseif R.choice == 810 then -- create sloping water
			utils.checkFuelNeeded(R.length * R.width * 3)
			local buckets = math.floor(R.length / 2) + 1
			T:checkInventoryForItem({"water_bucket", "bucket"}, {buckets, buckets})
			T:checkInventoryForItem({"slab"}, {R.length * R.width})
			print("Creating sloping water field "..R.width.." x "..R.length.." x ".. R.height)
			retValue = createSlopingWater(R)
		-- BUILDING & RAILWAY
		elseif R.choice == 91 then -- Build a wall
			local blocks = R.height * R.length 
			utils.checkFuelNeeded(blocks)
			T:checkInventoryForItem({"stone", "planks", "bricks"}, {blocks, blocks, blocks})
			R.useBlockType = T:getMostItem()
			print("Building a wall using "..R.useBlockType)
			sleep(2)
			retValue = buildWall(R)
		elseif R.choice == 92 then -- Build a rectangular structure
			local blocks = (R.height * R.length * 2) + (R.height * R.width * 2)
			utils.checkFuelNeeded(blocks)
			T:checkInventoryForItem({"stone", "planks", "bricks"}, {blocks, blocks, blocks})
			R.useBlockType = T:getMostItem()
			print("Building a house using "..R.useBlockType)
			sleep(2)
			retValue = buildStructure(R)
		elseif R.choice == 93 or R.choice == 94 then -- Build a gable end roof / pitched roof
			local blocks = ((R.width + 2) * (R.length + 2))
			utils.checkFuelNeeded(blocks)
			if menu.getBoolean("Using stairs / planks for roof (y/n)", nil, colors.yellow) then
				T:checkInventoryForItem({"planks", "stairs"}, {blocks, blocks})
			else
				T:checkInventoryForItem({"stone"}, {blocks})
			end
			
			R.useBlockType = T:getMostItem()
			if R.choice == 93 then 				-- Build a gableroof
				if R.width % 2 == 1 then
					T:checkInventoryForItem({"slab"}, {R.length + 2}, false, "Match slabs with roof blocks")
				end
				blocks = (R.width * 6)
				T:checkInventoryForItem({"stone", "planks", "bricks"}, {blocks, blocks, blocks}, true, "Match gable with existing building")
			else
				local isWidthOdd, isLengthOdd, width, length = false, false, 0, 0
				R, isWidthOdd, isLengthOdd, width, length = utils.getRoofStats(R)
				if isWidthOdd then
					T:checkInventoryForItem({"slab"}, {length - 2}, false, "Match slabs with roof blocks")
				end
			end
			print("Building a roof using "..R.useBlockType)
			sleep(2)
			if R.choice == 93 then 				-- Build a gableroof
				retValue = buildGableRoof(R)
			else								-- Build a pitched roof
				retValue = buildPitchedRoof(R)
			end
		elseif R.choice == 95 or R.choice == 96 then --place redstone torch level or downward slope
			utils.checkFuelNeeded(10)
			if R.choice == 95 then
				R.data = "level"
			else
				R.data = "up"
			end
			T:checkInventoryForItem({"stone"}, {1})
			R.useBlockType = T:getMostItem("", true)
			T:checkInventoryForItem({"minecraft:redstone_torch"}, {1})
			print("Placing redstone torch on ".. R.useBlockType)
			retValue = placeRedstoneTorch(R)
		elseif R.choice == 97 or R.choice == 98 then --build downward/upward slope
			local blocks = R.height * 2
			if R.height == 0 then
				blocks = 64
			end
			utils.checkFuelNeeded(blocks)
			T:checkInventoryForItem({"stone"}, {blocks})
			print("Building slope")
			sleep(2)
			retValue = createRailway(R)
		elseif R.choice == 101 or R.choice == 102 or R.choice == 103 or R.choice == 104 then -- measure height/depth/length
			retValue = measure(R)
		elseif R.choice == 105 then--Borehole
			retValue = createBorehole(R)
		end
	end
	return retValue
end

local function main()
	local lib = {}
	
	function lib.checkLabel()
		if os.getComputerLabel() == nil then
			os.setComputerLabel("toolkit")
			print("Computer label set to "..os.getComputerLabel())
		end
	end
	
	function lib.checkLibs(libDir, filename)
		local fileExists = false
		if fs.exists(libDir) then
			if not fs.isDir(libDir) then
				fs.move(libDir, libDir.."Renamed")
				fs.makeDir(libDir)
			end
		else
			fs.makeDir(libDir)
		end
		if fs.exists(fs.combine(libDir, filename)) or fs.exists(fs.combine(libDir, filename..".lua")) then
			fileExists = true
		end
		return fileExists
	end
	
	local doContinue = true
	lib.checkLabel() -- make sure turtle label is set
	--check if lib folder exists
	if not lib.checkLibs("lib", "clsTurtle") then
		-- use pastebin get to download clsTurtle to libs folder
		print("Missing clsTurtle.lua in libs directory")
		print("Attempting to obtain from Pastebin...")
		if shell.run("pastebin","get","tvfj90gK","lib/clsTurtle.lua") then
			print("clsTurtle.lua installed from Pastebin")
		else
			print("failed to install clsTurtle.lua from Pastebin")
			doContinue = false
		end
	end
	if not lib.checkLibs("lib", "menu") then
		-- use pastebin get to download menu.lua to libs folder
		print("Missing menu.lua in libs directory")
		print("Attempting to obtain from Pastebin...")
		if shell.run("pastebin","get","BhjbYsw4","lib/menu.lua") then
			print("menu.lua installed from Pastebin")
		else
			print("failed to install menu.lua from Pastebin")
			doContinue = false
		end
	end
	if doContinue then
		local result = {}
		local R =
		{
			choice = 0,
			subChoice = 0,
			size = 0,
			width = 0,
			length = 0,
			height = 0,
			depth = 0,
			up = false,
			down = false,
			silent = false,
			data = "",
			torchInterval = 0,
			useBlockType = "",
			auto = false,
			side = ""
		}
		menu = require("lib.menu")
		T = require("lib.clsTurtle").new(false) -- true enables logfile to log.txt note dot NOT colon
		T:clear()
		if args[1] ~= nil then
			if args[1] == "farm" then
				R.silent = true
				R.data = "farm"
				R.auto = true
				manageFarm(R)
			--elseif args[1] == "tree" then
				--manageTreeFarm() -- use file to read status
			elseif args[1] == "help" then
				-- missing turtle: player used 'tk help'
				T:setUseLog(true)
				T:setLogFileName("locate.txt")
				T:appendLine("Booting succeeded")
				T:appendLine("Block ahead: "..T:getBlockType("forward"))
				T:appendLine("Block above: "..T:getBlockType("up"))
				T:appendLine("Block below: "..T:getBlockType("down"))
			end
		else
			print("Minecraft major version: "..mcMajorVersion)
			print("Bedrock level: "..bedrock)
			if T:getUseLog() then
				print("Logging enabled")
			else
				print("Logging disabled")
			end	
			sleep(1)
			while R.choice == 0 do
				R = chooseTask(R)
			end
			if R.choice > 0 then
				R = getTask(R)
				result = getTaskInventory(R) -- table of comments
			end
		end
		T:clear()
		table.insert(result, "\nThank you for using 'survival toolkit'")
		local clr = {colors.yellow, colors.orange, colors.green, colors.lightBlue}
		local count = 1
		for _, value in ipairs(result) do
			--print(value)
			--.print(text, fg, bg, width)
			menu.colourPrint(tostring(value), clr[count])
			count = count + 1
			if count > #clr then
				count = 1
			end
		end
	else
		print("Add missing files and restart")
	end
end

main()