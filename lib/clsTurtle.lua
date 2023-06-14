version = 20230614.1400
--[[
	https://pastebin.com/tvfj90gK
	Last edited: see version YYYYMMDD.HHMM
	save as clsTurtle.lua, preferably in /lib folder
	as is not meant to be run directly from CraftOS command line
	usage:
	T = require("lib/clsTurtle").new()
	T:clear()
	T:forward(2)
	To use logging 
	T = require("lib.clsTurtle"):new(true) -- true enables logfile to log.txt
	
	Computercraft started with mc version 1.7.10 and went to 1.8.9
	ccTweaked started around mc 1.12 and currently at 1.18
	mc 1.18 has new blocks and bedrock at -64, so needs to be taken into account.
	_HOST = The ComputerCraft and Minecraft version of the current computer environment.
	For example, ComputerCraft 1.93.0 (Minecraft 1.15.2).
]]

local bedrock = 0
local ceiling = 255
local deletesWater = false
local mcMajorVersion = tonumber(_HOST:sub(_HOST:find("Minecraft") + 10, _HOST:find("\)") - 1)) -- eg 1.18 or 1.20 -> 1.18, 1.20
if tonumber(mcMajorVersion) == nil then -- 1.18.3 NAN
	mcMajorVersion = tonumber(_HOST:sub(_HOST:find("Minecraft") + 10, _HOST:find("\)") - 3)) -- eg 1.19.4 -> 1.19
end
if mcMajorVersion < 1.7  and mcMajorVersion >= 1.18 then -- 1.12 to 1.??
	bedrock = -64
	ceiling = 319
end
if mcMajorVersion < 1.7  and mcMajorVersion <= 1.12 then -- 1.12 to 1.??
	deletesWater = true
end
local stone = {	
				"minecraft:cobblestone",
				"minecraft:cobbled_deepslate",
				"minecraft:netherrack",
				"minecraft:blackstone",
				"minecraft:basalt",
				"minecraft:tuff",
				"minecraft:granite",
				"minecraft:diorite",
				"minecraft:andesite",
				"minecraft:end_stone",
				"minecraft:stone",
				"minecraft:dirt",
				"minecraft:glass",
				"minecraft:purpur_block",
				"minecraft:terracotta",
				"minecraft:white_terracotta",
				"minecraft:red_terracotta",
				"minecraft:orange_terracotta",
				"minecraft:yellow_terracotta",
				"minecraft:brown_terracotta",
				"minecraft:light_gray_terracotta"
			  } -- must be exact mc names!
			  
local flowers =
{
	"minecraft:sapling",
	"minecraft:oak_sapling",
	"minecraft:spruce_sapling",
	"minecraft:birch_sapling",
	"minecraft:jungle_sapling",
	"minecraft:acacia_sapling",
	"minecraft:dark_oak_sapling",
	"minecraft:leaves",
	"minecraft:oak_leaves",
	"minecraft:spruce_leaves",
	"minecraft:birch_leaves",
	"minecraft:jungle_leaves",
	"minecraft:acacia_leaves",
	"minecraft:dark_oak_leaves",
	"minecraft:azalea_leaves",
	"minecraft:flowering_azalea_leaves",
	"minecraft:dandelion",
	"minecraft:poppy",
	"minecraft:blue_orchid",
	"minecraft:allium",
	"minecraft:azure_bluet",
	"minecraft:red_tulip",
	"minecraft:orange_tulip",
	"minecraft:white_tulip",
	"minecraft:pink_tulip",
	"minecraft:oxeye_daisy",
	"minecraft:cornflower",
	"minecraft:lily_of_the_valley",
	"minecraft:sunflower",
	"minecraft:lilac",
	"minecraft:rose_bush",
	"minecraft:peony",
	"minecraft:wither_rose",
	"minecraft:spore_blossom",
	"minecraft:fern",
	"minecraft:large_fern",
	"minecraft:grass",
	"minecraft:tall_grass",
	"minecraft:azalea",
	"minecraft:flowering_azalea",
	"minecraft:deadbush",
	"minecraft:dead_bush",
	"minecraft:seagrass",
	"minecraft:tall_seagrass",
	"minecraft:sea_pickle",
	"minecraft:brown_mushroom",
	"minecraft:red_mushroom",
	"minecraft:crimson_fungus",
	"minecraft:warped_fungus",
	"minecraft:crimson_roots",
	"minecraft:warped_roots",
	"minecraft:vine",
	"minecraft:vines",
	"minecraft:weeping_vines",
	"minecraft:twisting_vines",
	"minecraft:sugar_cane",
	"minecraft:kelp",
	"minecraft:kelp_plant",
	"minecraft:moss_block",
	"minecraft:moss_carpet",
	"minecraft:hanging_roots",
	"minecraft:big_dripleaf",
	"minecraft:small_dripleaf",
	"minecraft:bamboo",
	"minecraft:cactus",
	"minecraft:glow_lichen",
	"minecraft:waterlily",
	"minecraft:lily_pad",
	"minecraft:pumpkin",
	"minecraft:melon",
	"minecraft:melon_block",
	"minecraft:cocoa",
	"minecraft:double_plant",
	"minecraft:sponge",
	"minecraft:wet_sponge",
}
			  
local clsTurtle = {}
clsTurtle.__index = clsTurtle

setmetatable(clsTurtle,
{
	__call = function (cls, ...)
    return cls.new(...)
	end,
})
-- if you want to pass arguments at construction...
function clsTurtle.new(useLog) --note dot, NOT colon, list of args or ... table
	local self = setmetatable({}, clsTurtle)
	if useLog == nil then useLog = false end
	self.x = 0
	self.y = 0
	self.z = 0
	self.facing = 0
	self.compass = ""
	self.equippedLeft = ""
	self.equippedRight = ""
	self.placeSlot = 0
	self.placeItem = ""
	self.osVersion = os.version() -- eg CraftOS 1.8
	self.userBlocks = {}
	self.useLog = useLog
	if self.useLog then
		print("Logging enabled")
		sleep(1.5)
	end
	self.logFileName = "log.txt"
	self.logFileExists = false
	return self
end

-- helper function for iterating lists
function clsTurtle.values(self,t) -- general diy iterator
	local i = 0
	return function()
		i = i + 1
		return t[i]
	end
end
--[[
	logging methods set from calling program
	T:setLogFileName("log.txt") (example)
	T:deleteLog() -- if new log required every time program is run
	T:setUseLog(true) -- allows logging statements to be left in this class code, will only operate if this flag is set#
	extensive use for debugging has been left in the function clsTurtle.checkInventoryForItem() as this was a nightmare to get working
]]
function clsTurtle.getUseLog(self)
	return self.useLog
end
function clsTurtle.setUseLog(self, use)
	self.useLog = use
	return use
end
function clsTurtle.getLogExists(self)
	local exists = false
	if fs.exists(self.logFileName) then
		exists = true
	end
	return exists
end
function clsTurtle.getLogFileName(self)
	return self.logFileName
end
function clsTurtle.setLogFileName(self, value)
	self.logFileName = value
end
function clsTurtle.getCurrentFileSize(self)		
	if self.logFileExists then
		return fs.getSize(self.logFileName)
	else
		return 0
	end
end
function clsTurtle.deleteLog(self)		
	if fs.exists(self.logFileName) then
		fs.delete(self.logFileName)
	end
	self.logFileExists = false
	
	return true
end
function clsTurtle.appendLine(self, newText)
	local handle = ""
	
	if fs.exists(self.logFileName) then --logFile already created
		handle = fs.open(self.logFileName, "a") 
	else
		handle = fs.open(self.logFileName, "w") --create file
	end
	self.logFileExists = true
	handle.writeLine(newText)
	handle.close()
end
function clsTurtle.saveToLog(self, text, toScreen)
	if toScreen == nil then
		toScreen = true
	end
	if text ~= "" and text ~= nil then
		if toScreen then
			print(text)
		end
		if self.useLog then
			clsTurtle.appendLine(self, text)
		end
	end
end

-- getters and setters
function clsTurtle.getValue(self) return self.value end --debug test for object creation with args
function clsTurtle.getX(self) return self.x end
function clsTurtle.setX(self, newVal) self.x = newVal end
function clsTurtle.getY(self) return self.y end
function clsTurtle.setY(self, newVal) self.y = newVal end
function clsTurtle.getZ(self) return self.z end
function clsTurtle.setZ(self, newVal) self.z = newVal end
function clsTurtle.getFacing(self) return self.facing end
function clsTurtle.setFacing(self, newVal)
	local direction = {"south", "west", "north", "east"}
	self.facing = newVal
	if self.facing < 0 then
		self.facing = 3
	elseif self.facing > 3 then
		self.facing = 0
	end
	self.compass = direction[self.facing + 1] --+1 to allow for lua indexing at 1
end
function clsTurtle.getCompass(self) return self.compass end
function clsTurtle.getPlaceItem(self) return self.placeItem end
function clsTurtle.setPlaceItem(self, item, useDamage)
	local success = false
	local slot = clsTurtle.getItemSlot(self, item, useDamage)
	if slot > 0 then
		self.placeItem = item
	end
end
function clsTurtle.getEquipped(self, side)
	retValue = ""
	if side == "left" then
		retValue = self.equippedLeft
	else
		retValue = self.equippedRight
	end
	return retValue
end
function clsTurtle.setEquipped(self, side, value)
	if side == "left" then
		self.equippedLeft = value
	elseif side == "right" then
		self.equippedRight = value
	end
end
function clsTurtle.getUserBlocks(self)
	-- self.userBlocks[1] = {string<name>, string<item>, int<count>, bool<userChoice>}
	return self.userBlocks
end
function clsTurtle.getUserBlockType(self, name)
	local retValue = {} --retValue["minecraft:stone_pressure_plate"] = 2
	if next(self.userBlocks) ~= nil then
		for i = 1, #self.userBlocks do
			if self.userBlocks[i][1] == name then
				retValue[self.userBlocks[i][2]] = self.userBlocks[i][3]
			end
		end
	end
	return retValue --retValue["minecraft:stone_pressure_plate"] = 2, retValue["minecraft:oak_pressure_plate"] = 2
end
function clsTurtle.addUserBlocks(self, blockTable)
	table.insert(self.userBlocks, blockTable)
end

-- change direction and movement methods
function clsTurtle.attack(self, direction)	
	direction = direction or "forward"
	local slot = turtle.getSelectedSlot()
	turtle.select(1)
	local success = false
	local attackLimit = 30 -- won't get in infinite loop attacking a minecart chest
	local Attack
	if direction == "up" then
		Attack = turtle.attack
	elseif direction == "down" then
		Attack = turtle.attackDown
	else
		Attack = turtle.attackUp
	end
	
	while Attack() do --in case mob around
		sleep(1.5)
		attackLimit = attackLimit - 1
		if attackLimit <= 0 then
			break
		end			
	end

	if attackLimit > 0 then
		success = true
	end
	turtle.select(slot)
	return success
end

function clsTurtle.doMoves(self, numBlocksRequested, direction)
	local errorMsg = nil
	local numBlocksMoved = 0
	local Move, Dig, Detect
	local bypass = false
	local bypassCount = 0
	local blockType
	numBlocksRequested = numBlocksRequested or 1
	clsTurtle.refuel(self, steps)
	turtle.select(1)
	-- re-assign turtle functions to new variables
	if direction == "forward" or direction == "back" then
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
	
	if direction == "back" then
		clsTurtle.turnRight(self, 2)
	end
	
	for i = 1, numBlocksRequested, 1 do
		local digOK, digError
		if bypass then
			bypassCount = bypassCount + 1
			if bypassCount >= 1 then
				bypass = false
				bypassCount = 0
			end
		else
			if Detect() then -- block above/forward/below
				blockType, bypass = clsTurtle.checkNoDigBlocks(self, direction)
				if bypass then --moved round bedrock, spawner, turtle or full chest
					digOK, digError = Dig()
					if digOK then
						sleep(0.5) -- allow sand / gravel to drop if digging forward / up
					else -- unable to dig, or nothing to dig
						if digError:lower():find("unbreakable") ~= nil then -- different messages between versions all contain 'unbreakable'
							errorMsg = digError
							print(digError)
							break
						else -- not bedrock, could be mob or minecart
							clsTurtle.attack(self, direction)
						end
					end
				end 
			end
			if not bypass then
				local moveOK, moveError = Move() -- try to move forward/up/down
				if moveOK then
					numBlocksMoved = numBlocksMoved + 1
					clsTurtle.changeCoords(self, direction)
				else
					while not moveOK do -- did not move if obstruction
						digOK, digError = Dig()
						if digOK then
							sleep(0.5) -- allow sand / gravel to drop if digging forward / up
						else -- unable to dig, or nothing to dig
							if digError:lower():find("unbreakable") ~= nil then -- different messages between versions all contain 'unbreakable'
								errorMsg = digError
								print(digError)
								break
							else -- not bedrock, could be mob or minecart
								clsTurtle.attack(self, direction)
							end
						end
						moveOK, moveError = Move() -- try to move forward/up/down again
						if moveOK then
							numBlocksMoved = numBlocksMoved + 1
							clsTurtle.changeCoords(self, direction)
						end
					end
				end
			end
		end
	end
	
	if direction == "back" then
		clsTurtle.turnRight(self, 2)
	end
	
	return numBlocksMoved, errorMsg
end

function clsTurtle.back(self, steps)
	steps = steps or 1
	local success = false
	local blocksMoved, errorMsg = clsTurtle.doMoves(self, steps, "back")
	if blocksMoved == steps then
		success = true
	end
	return success, blocksMoved, errorMsg
end

function clsTurtle.changeCoords(self, direction)
	--  0 = go south (z increases)
	--	1 = go west  (x decreases)
	--	2 = go north (z decreases
	--	3 = go east  (x increases)
	if direction == "forward" then
		if self.facing == 0 then
			self.z = self.z + 1 
		elseif self.facing == 1 then
			self.x = self.x - 1
		elseif self.facing == 2 then
			self.z = self.z - 1
		else
			self.x = self.x + 1
		end
	elseif direction == "back" then
		if self.facing == 0 then
			self.z = self.z - 1
		elseif self.facing == 1 then
			self.x = self.x + 1
		elseif self.facing == 2 then
			self.z = self.z + 1
		else
			self.x = self.x - 1
		end
	elseif direction == "up" then
		self.y = self.y + 1
	elseif direction == "down" then
		self.y = self.y - 1
	end
end

function clsTurtle.down(self, steps, getBlockType)
	steps = steps or 1
	if getBlockType == nil then getBlockType = false end
	local success = false
	local blockType = nil
	local blocksMoved, errorMsg = clsTurtle.doMoves(self, steps, "down")
	if blocksMoved == steps then
		success = true
	end
	if getBlockType then
		blockType = clsTurtle.getBlockType(self, "down")
	end
	return success, blocksMoved, errorMsg, blockType
end

function clsTurtle.forward(self, steps)    
	steps = steps or 1
	local success = false
	local blocksMoved, errorMsg = clsTurtle.doMoves(self, steps, "forward")
	if blocksMoved == steps then
		success = true
	end
	return success, blocksMoved, errorMsg
end

function clsTurtle.turnLeft(self, steps)
	steps = steps or 1
	for i = 1, steps do
		turtle.turnLeft()
		self.facing = self.facing - 1
		if self.facing < 0 then
			self.facing = 3
		end
	end
end

function clsTurtle.turnRight(self, steps)
	steps = steps or 1
	for i = 1, steps do
		turtle.turnRight()
		self.facing = self.facing + 1
		if self.facing > 3 then
			self.facing = 0
		end
	end
end

function clsTurtle.up(self, steps)
	steps = steps or 1
	local success = false
	local blocksMoved, errorMsg = clsTurtle.doMoves(self, steps, "up")
	if blocksMoved == steps then
		success = true
	end
	return success, blocksMoved, errorMsg
end
-- other methods
function clsTurtle.checkInventoryForItem(self, items, quantities, required, message)
	local lib = {}
	
	function lib.checkInventory(self, items, quantities, inventory)
		--[[
		Does the inventory have any or all of the items required? 
		Multiple choices are similar alternatives eg cobblestone, dirt. Most requests are single item
		eg requested: {"stone", "dirt"}, quantities: { 256, 256 }
		eg inventory: {"minecraft:cobblestone" = 128, "minecraft:dirt" = 100}  = 228: still need 28 cobble or dirt
		could be empty!
		]]
		-- on first entry currentItems = {}
		local waiting = true 			-- return value. set to false if not enough put in the inventory for this item
		local quantitiesFound = {} 		-- table of quantities found, based on no of items needed
		for i = 1, #quantities do		-- Initialise table eg {0, 0, 0}	
			table.insert(quantitiesFound, 0)
		end 
		for i = 1, #items do 								-- check if item(s) already present
			local findItem = items[i]
			for k, v in pairs(inventory) do 				-- eg: {"minecraft:cobblestone" = 128, "minecraft:dirt" = 203}
				if findItem:find("\:") ~= nil then 			-- specific item requested eg "minecraft:cobblestone"
					if findItem == k then 					-- exact match eg "minecraft:cobblestone" requested, "minecraft:cobblestone" found
						item = k							-- item = "minecraft:cobblestone"
						quantitiesFound[i] = v
					end
				else 										-- non specific eg "log", "pressure_plate", "stone"
					if findItem == "stone" then 			-- check for allowed blocks in global table stone
						for _, stonetype in ipairs(stone) do
							if k == stonetype then			-- k = "minecraft:cobblestone" matches with stonetype
								quantitiesFound[i] = quantitiesFound[i] + v
							end
						end
					elseif k:find(findItem) ~= nil then 	-- similar item exists already eg "pressure_plate" is in "minecraft:stone_pressure_plate"
						quantitiesFound[i] = quantitiesFound[i] + v
					end
				end
			end
		end
		local totalFound = 0
		for i = 1, #quantities do
			totalFound = totalFound + quantitiesFound[i]
			if totalFound >= quantities[i] then
				waiting = false
			end
		end
		if waiting then -- update quantities
			for i = 1, #quantitiesFound do
				quantitiesFound[i] = totalFound -- when player asked to supply alternatives, this gives quantities
			end
		end
		return waiting, quantitiesFound
	end
	
	function lib.getInventory(self)
		--[[ table eg: {"minecraft:cobblestone" = 256, "minecraft:cobbled_deepslate = 256"}  ]]
		local inventory = {}
		for slot = 1, 16 do
			local slotContains, slotCount, slotDamage = clsTurtle.getSlotContains(self, slot)
			if slotContains ~= "" then -- eg "minecraft:cobblestone"
				if inventory[slotContains] ~= nil then --already exists in inventory
					inventory[slotContains] = inventory[slotContains] + slotCount --update quantities
				else
					inventory[slotContains] = slotCount
				end
			end
		end
		return inventory
	end
		
	if required == nil then required = true end
	if message == nil then message = "" end 	-- add further instructions
	local inventory = lib.getInventory(self) 	-- create table of blocktypes and quantities
	local inventoryChanged = false
	local enteringLoop = true
	local waiting = true
	local quantitiesFound = {}
	while waiting do -- true on first entry, also enteringLoop = true check slots and inventory in waiting loop to see if new items are added
		--clsTurtle.clear(self)
		if inventoryChanged or enteringLoop then
			clsTurtle.clear(self)
			enteringLoop = false --flag reset loop has iterated at least once
			inventoryChanged = false
			waiting, quantitiesFound = lib.checkInventory(self, items, quantities, inventory) -- are we still waiting, table of found quantities
			if waiting then --insufficient items so ask for more
				if message ~= "" then
					print(message)
				end
				if quantitiesFound[1] < quantities[1] then
					print("Add "..quantities[1] - quantitiesFound[1].." "..clsTurtle.trimItemName(self, items[1]).." to any slot(s)")
					for i = 2, #items do
						print("Or add "..quantities[i] - quantitiesFound[i].." "..clsTurtle.trimItemName(self, items[i]).." to any slot(s)")
					end
				end
				if not required then
					print("(Optional: 'Enter' if not required)")
				end
			end
		end
		if waiting then -- not enough onBoard, so wait for user to interact with inventory or press Enter
			local event, param1 = os.pullEvent()
			if event == "turtle_inventory" then
				inventoryChanged = true
				-- user has added, moved or removed inventory items
				inventory = lib.getInventory(self)
			--elseif event == "key"  and not required then
			elseif event == "key" then
				if param1 == keys.enter then
					clsTurtle.clear(self)
					return nil -- stop waiting and exit
				end
			end
		end
	end
	if required then
		return quantitiesFound
	else
		return nil --if item not required
	end
end

function clsTurtle.checkNoDigBlocks(self, direction, moveRound) 
	if moveRound == nil then
		moveRound = false
	end
	local bypass = false
	local isSpawner = false
	local blockType, blockModifier = clsTurtle.getBlockType(self, direction)
	-- if mob spawner or chest found, go round it. Do not break!
	if blockType ~= "" then
		if blockType:find("spawner") ~= nil then
			clsTurtle.writeCoords(self, "SpawnerCoords.txt")
			bypass = true
			isSpawner = true
			print("Spawner Found!")
		elseif blockType:find("turtle") ~= nil then --do not break another turtle
			bypass = true
		elseif blockType:find("chest") ~= nil or blockType:find("minecart") ~= nil then
			local success, msg
			repeat
				success, msg = clsTurtle.suck(self, direction)
			until not success
			if clsTurtle.getFirstEmptySlot(self) == 0 then -- turtle is full
				bypass = true
			else
				clsTurtle.dig(self, direction)
			end
		end
	end
	if bypass and (moveRound or isSpawner)  then
		if direction == "up" then
			clsTurtle.go(self, "F1U2R2F1R2", false, 0, false, false)
		elseif direction == "forward" then
			clsTurtle.go(self, "U1F2D1", false, 0, false, false)
		elseif direction == "down" then
			clsTurtle.go(self, "F1D2R2F1R2", false, 0, false, false)
		end
		--blockType, blockModifier = clsTurtle.getBlockType(self, direction)
	end
	return blockType, bypass -- bypass true should be used to reduce steps in calling routine
end

function clsTurtle.clear(self)
	term.clear()
	term.setCursorPos(1,1)
end

function clsTurtle.craft(self, item, quantity)	
	--[[
		eg stairs, 40
		setup for crafting chest, planks, stairs
	]]
	local craftOK = false
	local message = ""
	local chestSlot = 0
	local holeSlot = 0
	local sourceSlot = 0
	local turns = 0
	
	chestSlot = clsTurtle.getItemSlot(self, "chest", -1) --get the slot number containing a chest
	if chestSlot == 0 then -- chest not found
		if item == "planks" then -- could be new turtle and tree felling
			sourceSlot = clsTurtle.getItemSlot(self, "log", -1) --get the slot number containing log(s)	
			if sourceSlot > 0 then
				if turtle.craft() then
					return true, ""
				else
					return false, "Unable to craft planks"
				end
			end
		elseif item == "chest" then -- assume chest needed and logs are onboard
			sourceSlot = clsTurtle.getItemSlot(self, "log", -1) --get the slot number containing log(s)	
			if sourceSlot > 0 then
				if turtle.craft() then-- craft logs into planks
					sourceSlot = clsTurtle.getItemSlot(self, "planks", -1) --get the slot number containing planks
					if sourceSlot > 0 then				
						turtle.select(sourceSlot)
						turtle.transferTo(16) --move crafting item to 16
						turtle.select(16)
						turtle.transferTo(1, 1)
						turtle.transferTo(2, 1)
						turtle.transferTo(3, 1)
						turtle.transferTo(5, 1)
						turtle.transferTo(7, 1)
						turtle.transferTo(9, 1)
						turtle.transferTo(10, 1)
						turtle.transferTo(11, 1)
						if turtle.craft() then
							return true, ""
						else
							return false, "Unable to craft chest"
						end
					end
				else
					return false, "Unable to craft planks"
				end
			else
				return false, "No logs available"
			end
		else
			return false, "No chest for crafting"
		end
	end
	local stock = {}
	--[[
		rt.total = total
		rt.mostSlot = slotData.mostSlot
		rt.leastSlot = slotData.leastSlot
		rt.mostCount = slotData.mostCount
		rt.leastCount = slotData.leastCount
		]]
	if item:find("stairs") ~= nil then -- craft stairs, check stone, planks
		stock = clsTurtle.getStock(self, "stone", -1) --get the slot number containing stone
		sourceSlot = stock.mostSlot
		message = "No stone for crafting stairs"
	elseif item:find("chest") ~= nil then -- craft chest
		stock = clsTurtle.getStock(self, "planks", -1) --get the slot number containing planks
		sourceSlot = stock.mostSlot
		message = "No planks for crafting chest"
	elseif item:find("planks") ~= nil then -- craft planks
		stock = clsTurtle.getStock(self, "log", -1) --get the slot number containing logs
		sourceSlot = stock.mostSlot
		message = "No logs for crafting planks"
	end
	if sourceSlot == 0 then
		return false, message
	end
	while turtle.detect() do --check for clear space to place chest
		clsTurtle.turnRight(self, 1)
		turns = turns + 1
		if turns == 4 then
			turns = 0
			break
		end
	end
	turtle.select(1)
	while turtle.detect() do --clear space in front. Use loop in case of sand/gravel falling
		turtle.dig()
		sleep(.5)
	end
	turtle.select(chestSlot) --should be slot with chest
	while not turtle.place() do
		clsTurtle.attack(self)
	end
	-- fill chest with everything except required items
	for i = 1, 16 do
		if i ~= sourceSlot then
			turtle.select(i)
			turtle.drop()
		end
	end
	-- error here if turtle empty
	turtle.select(sourceSlot)
	turtle.transferTo(16) --move crafting item to 16
	--ready to craft
	turtle.select(16)
	if item:find("planks") ~= nil then -- crafting planks
		turtle.transferTo(1, quantity / 4)
	elseif item:find("chest") ~= nil then  --craft("chest", 1)
		--8 planks = 1 chest 
		turtle.transferTo(1, 1)
		turtle.transferTo(2, 1)
		turtle.transferTo(3, 1)
		turtle.transferTo(5, 1)
		turtle.transferTo(7, 1)
		turtle.transferTo(9, 1)
		turtle.transferTo(10, 1)
		turtle.transferTo(11, 1)
	elseif item:find("stairs") ~= nil then  --craft("stairs", 40)
		--6 cobblestone = 4 stairs
		turtle.transferTo(1, math.ceil(quantity / 4))
		turtle.transferTo(5, math.ceil(quantity / 4))
		turtle.transferTo(6, math.ceil(quantity / 4))
		turtle.transferTo(9, math.ceil(quantity / 4))
		turtle.transferTo(10, math.ceil(quantity / 4))
		turtle.transferTo(11, math.ceil(quantity / 4))
	end
	turtle.select(16)
	turtle.drop() --drop remaining resources before crafting
	-- Attempt to craft item into slot 16
	if turtle.craft() then
		craftOK = true
		--now put crafted item in chest first, so will mix with any existing similar items
		turtle.drop()
	else --crafting not successful, so empty out all items into chest
		for i = 1, 16 do
			if turtle.getItemCount(i) > 0 then
				turtle.select(i)
				turtle.drop()
			end
		end
	end
	turtle.select(1) --empty chest into slot 1 onwards
	while turtle.suck() do end
	turtle.dig() -- collect chest
	if turns > 0 then --return to original position
		clsTurtle.turnLeft(self,turns)
	end
	
	return craftOK, message
end

function clsTurtle.createTunnel(self, length, allowAbandon)
	-- clsTurtle.go(self, path, useTorch, torchInterval, leaveExisting)
	-- assume at floor level at start
	local leaveExisting = true
	local useTorch = false
	local distance  = 1
	local blockAbove = ""
	local aboveType = 0
	local blockBelow = ""
	local belowType = 0
	local waterCountAbove = 0
	local waterCountBelow = 0
	local onGround = true
	for i = 1, length do
		if onGround then -- 1, 3, 5, 7 etc
			blockBelow, belowType = clsTurtle.getBlockType(self, "down")
			if blockBelow ~= "" then
				if blockBelow:find("lava") ~= nil then
					clsTurtle.go(self, "C2L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockBelow:find("water") ~= nil then
					clsTurtle.go(self, "C2", useTorch, 0, leaveExisting)
					waterCountBelow = waterCountBelow + 1
				else
					clsTurtle.go(self, "C2", useTorch, 0, leaveExisting)
				end
			else
				clsTurtle.go(self, "C2", useTorch, 0, leaveExisting)
			end
			clsTurtle.up(self, 1)
			onGround = false
			blockAbove, aboveType = clsTurtle.getBlockType(self, "up")
			if blockAbove ~= "" then
				if blockAbove:find("lava") ~= nil then
					clsTurtle.go(self, "C0L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockAbove:find("water") ~= nil then
					clsTurtle.go(self, "C0L1C1R2C1L1", useTorch, 0, leaveExisting)
					waterCountAbove = waterCountAbove + 1
				else
					clsTurtle.go(self, "C0", useTorch, 0, leaveExisting)
				end
			else
				clsTurtle.go(self, "C0", useTorch, 0, leaveExisting)
			end
			-- if on first block check behind
			if i == 1 then
				clsTurtle.go(self, "R2C1R2", useTorch, 0, leaveExisting)
			end
			if distance >= 8 then
				if distance % 8 == 0 then -- 8th or other position
					clsTurtle.go(self, "t5", useTorch, 0, false)
				end
			end
		else -- at ceiling 2, 4, 6, 8 etc
			blockAbove, aboveType = clsTurtle.getBlockType(self, "up")
			if blockAbove ~= "" then
				if blockAbove:find("lava") ~= nil then
					clsTurtle.go(self, "C0L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockAbove:find("water") ~= nil then
					clsTurtle.go(self, "C0L1C1R2C1L1", useTorch, 0, leaveExisting)
					waterCountAbove = waterCountAbove + 1
				else
					clsTurtle.go(self, "C0", useTorch, 0, leaveExisting)
				end
			else
				clsTurtle.go(self, "C0", useTorch, 0, leaveExisting)
			end
			if distance == 2 then
				clsTurtle.go(self, "t1", useTorch, 0, false)
			end
			clsTurtle.down(self, 1)
			onGround = true
			blockBelow, belowType = clsTurtle.getBlockType(self, "down")
			if blockBelow ~= "" then
				if blockBelow:find("lava") ~= nil then
					clsTurtle.go(self, "C2L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockBelow:find("water") ~= nil then
					clsTurtle.go(self, "C2", useTorch, 0, leaveExisting)
					waterCountBelow = waterCountBelow + 1
				else
					clsTurtle.go(self, "C2", useTorch, 0, leaveExisting)
				end
			else
				clsTurtle.go(self, "C2", useTorch, 0, leaveExisting)
			end
		end
		-- now move forward if length > 1
		if length > 1 then
			if i < length then -- not on last iteration
				clsTurtle.forward(self,1)
				distance = distance + 1
			else -- on last iteration
				if not onGround then
					clsTurtle.go(self, "C1", useTorch, 0, leaveExisting)
					clsTurtle.down(self, 1)
					onGround = true
				end
			end
		else -- one unit only so move down
			clsTurtle.down(self, 1)
			onGround = true
		end
		
		if allowAbandon then
			if waterCountAbove + waterCountBelow >= 6 then
				if not onGround then
					clsTurtle.down(self, 1)
					onGround = true
				end
				break
			end
		end
	end
	
	return distance -- 1 to length. cut short if 3 or more water
end

function clsTurtle.detect(self, direction)
	direction = direction or "forward"
	
	local Detect = turtle.detect
	if direction == "up" then
		Detect = turtle.detectUp
	elseif direction == "down" then
		Detect = turtle.detectDown
	end
	
	return Detect()
end

function clsTurtle.dig(self, direction, bypass, slot)
	--[[ To dig a chest use T:dig(direction, false)  ]]
	direction = direction or "forward"
	slot = slot or 1
	if bypass == nil then bypass = true	end-- allows digging any block including chests and spawners
	local success = false
	local blockType = ""
	local Dig = turtle.dig
	if direction == "up" then
		Dig = turtle.digUp
	elseif direction == "down" then
		Dig = turtle.digDown
	end
	
	turtle.select(slot)
	if bypass then
		blockType, bypass = clsTurtle.checkNoDigBlocks(self, direction, false)
	end
	if not bypass then --bypass true if chest, turtle or minecart 
		while Dig() do
			sleep(0.5)
			success = true
		end
	end

	return success
end

function clsTurtle.digValuable(self, direction)
	local Dig = turtle.dig
	if direction == "up" then
		Dig = turtle.digUp
	elseif direction == "down" then
		Dig = turtle.digDown
	end
	local isValuable, blockType = clsTurtle.isValuable(self, direction)
	if isValuable then
		Dig()
	else --check for lava
		if blockType == "minecraft:lava" then
			clsTurtle.place(self, "minecraft:bucket", -1, direction)  -- will automatically find empty bucket and refuel
		end
	end
end

function clsTurtle.drop(self, direction, slot, amount)
	direction = direction or "forward"
	slot = slot or 1
	local success = false
	local drop = turtle.drop
	if direction == "up" then
		drop = turtle.dropUp
	elseif direction == "down" then
		drop = turtle.dropDown
	end
	if slot == 0 then
		print("Slot 0 parameter T:drop")
		error()
	end
	turtle.select(slot)

	if amount == nil then
		success = drop()
	else
		success = drop(amount)
	end
	
	return success
end

function clsTurtle.dropAll(self, direction)
	direction = direction or "forward"
	local Drop = turtle.drop
	local success = true
	if direction == "up"  then
		Drop = turtle.dropUp
	elseif direction == "down" then
		Drop = turtle.dropDown
	end
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			turtle.select(i)
			if not Drop() then
				success = false
			end
		end
	end
	
	return success
end

function clsTurtle.dropItem(self, item, direction, keepAmount)
	direction = direction or "forward"
	local itemSlot = 0
	local stockData = {}
	local success = false
	
	if keepAmount == nil or keepAmount <= 0 then -- drop everything
		itemSlot = clsTurtle.getItemSlot(self, item, -1)
		while itemSlot > 0 do
			if not clsTurtle.drop(self, direction, itemSlot) then
				return false
			end
			itemSlot = clsTurtle.getItemSlot(self, item, -1)
		end
	else -- keep a specific amount
		-- {rt.total, rt.mostSlot, rt.leastSlot, rt.mostCount, rt.leastCount}
		stockData = clsTurtle.getStock(self, item)
		while stockData.total > keepAmount do
			if stockData.total - stockData.leastCount > keepAmount then
				success = clsTurtle.drop(self, direction, stockData.leastSlot)
			else
				success = clsTurtle.drop(self, direction, stockData.leastSlot, stockData.total - keepAmount)
			end
			if not success then
				break
			end
			stockData = clsTurtle.getStock(self, item)
		end
	end
	
	return true
end

function clsTurtle.dumpRefuse(self, direction, keepCobbleStacks)
	--dump dirt, cobble, sand, gravel
	local Drop = turtle.drop
	if direction == "up" then
		Drop = turtle.dropUp
	else
		Drop = turtle.dropDown
	end
	keepCobbleStacks = keepCobbleStacks or 0
	local itemlist = {"gravel", "stone", "sand", "flint"}
	local blockType = ""
	local blockModifier
	local slotCount
	local cobbleCount = 0

	clsTurtle.sortInventory(self)
	for i = 1, 16 do
		blockType, slotCount,  blockModifier = clsTurtle.getSlotContains(self,i)
		
		if blockType:find("cobble") ~= nil or blockType:find("netherrack") then
			if cobbleCount > keepCobbleStacks then
				turtle.select(i)
				Drop()
			else
				cobbleCount = cobbleCount + 1
			end
		end
		for j = 1, #itemlist do
			if string.find(blockType, itemlist[j]) ~= nil then
				turtle.select(i)
				Drop()
				break
			end
		end
	end
	turtle.select(1)
end

function clsTurtle.emptyInventory(self, direction)
	--[[ Dump everything!]]
	direction = direction or "down"
	local Drop = turtle.dropDown
	if direction == "up" then
		Drop = turtle.dropUp
	elseif direction == "forward" then
		Drop = turtle.drop
	end
	for i = 1, 16 do
		turtle.select(i)
		Drop()
	end
	turtle.select(1)
end

function clsTurtle.emptyInventorySelection(self, direction, exceptions, quantities)
	--[[ Dump everything except items in exceptions eg {"oak_sapling"}, {64} ]]
	clsTurtle.sortInventory(self)
	direction = direction or "down"
	local Drop = turtle.dropDown
	if direction == "up" then
		Drop = turtle.dropUp
	elseif direction == "forward" then
		Drop = turtle.drop
	end
	for i = 1, 16 do
		turtle.select(i)
		if turtle.getItemCount(i) > 0 then
			local item = turtle.getItemDetail(i)
			local name = item.name
			local inKeepItems = false
			local index = 0
			for j = 1, #exceptions do
				--print("Checking "..i.." "..name.." with "..exceptions[j])
				if name:find(exceptions[j]) ~= nil then
					inKeepItems = true
					index = j
				end
			end
			if inKeepItems then
				--print(name.." found "..quantities[index].." needed")
				if quantities[index] > 0 then
					local dropAmount = item.count - quantities[index]
					quantities[index] = quantities[index] - item.count
					if quantities[index] < 0 then
						quantities[index] = 0
					end
					if dropAmount > 0 then
						Drop(dropAmount)
					end
					-- else if 0 do not drop
				end
			else
				Drop()
			end
		end
	end
	turtle.select(1)
end

function clsTurtle.emptyTrash(self, direction)
	direction = direction or "down"
	local Drop = turtle.dropDown
	if direction == "up" then
		Drop = turtle.dropUp
	elseif direction == "forward" then
		Drop = turtle.drop
	end
	local slotData = {}
	local itemName = ""
	local move = false
	-- store these items permanently inside turtle
	local keepItems = 	{"netherrack", "cobblestone", "chest", "torch", "ore", "bucket", "coal", "diamond", "debris", "deepslate","iron","gold","copper"}			
	local keepit = false					
	-- empty excess cobble, dirt, all gravel, unknown minerals
	-- keep max of 1 stack
	clsTurtle.sortInventory(self)
	for i = 1, 16 do
		keepit = false
		if turtle.getItemCount(i) > 0 then
			itemName = clsTurtle.getItemName(self, i) -- eg 'minecraft:andesite'
			for _,v in pairs(keepItems) do
				--if v == item then
				if itemName:find(v) ~= nil then
					keepit = true
					break
				end
			end
			if not keepit then
				turtle.select(i)
				Drop()
				sleep(0.2)
			end
		end
	end
	clsTurtle.sortInventory(self)
	clsTurtle.emptyTrashItem(self, direction, "minecraft:cobblestone", 192)
	clsTurtle.emptyTrashItem(self, direction, "minecraft:netherrack", 192)
	clsTurtle.emptyTrashItem(self, direction, "minecraft:cobbled_deepslate", 192)
	slotData = clsTurtle.getStock(self, "minecraft:coal", 0)
	if slotData.total > 64 then
		if slotData.mostSlot ~= slotData.leastSlot and slotData.leastSlot ~= 0 then
			turtle.select(slotData.leastSlot)
			turtle.refuel()
		end
	end
	turtle.select(1)
end

function clsTurtle.emptyTrashItem(self, direction, item, keepAmount)
	--[[ deprecated. left for legacy applications ]]
	clsTurtle.dropItem(self, item, direction, keepAmount)
end

function clsTurtle.equip(self, side, useItem, useDamage)
	useDamage = useDamage or 0
	--slotData.leastSlot, slotData.leastModifier, total, slotData
	local slot, damage = clsTurtle.getItemSlot(self, useItem, -1)
	local currentSlot = turtle.getSelectedSlot()
	local success = false
	--[[
	minecraft:crafting_table
	minecraft:diamond_pickaxe
	minecraft:diamond_sword
	minecraft:diamond_shovel
	minecraft:diamond_hoe
	minecraft:diamond_axe
	wireless modem = ComputerCraft:CC-Peripheral, damage = 1
	]]
	if slot > 0 then
	--if slot > 0 and damage == useDamage then
		turtle.select(slot)
		if side == "right" then
			if turtle.equipRight() then
				success = true
				self.equippedRight = useItem
			end
		else
			if turtle.equipLeft() then
				success = true
				self.equippedLeft = useItem
			end
		end
	end
	turtle.select(currentSlot)
	
	return success
end

function clsTurtle.fillVoid(self, direction, tblPreferredBlock, leaveExisting)
	if tblPreferredBlock == nil then tblPreferredBlock = {} end
	if type(preferredBlock) ~= "table" then preferredBlock = {preferredBlock} end
	if leaveExisting == nil then leaveExisting = true end
	
	local Detect = turtle.detect
	local Place = turtle.place
	local Dig = turtle.dig
	if direction == "up" then
		Detect = turtle.detectUp
		Place = turtle.placeUp
		Dig = turtle.digUp
	elseif direction == "down" then
		Detect = turtle.detectDown
		Place = turtle.placeDown
		Dig = turtle.digDown
	end
	local placed = false
	local noBlocks = false
	local slot = 0
	--check if vegetation and remove
	if clsTurtle.isSeaweed(self, direction) then
		Dig()
	end
	if next(tblPreferredBlock) ~= nil then -- check for preferredBlock
		for i = 16, 1, -1 do
			if turtle.getItemCount(i) > 0 then
				local data = turtle.getItemDetail(i) -- returns {count = x, name = 'minecraft:item" in 1.16.2)
				--if data.name:find(preferredBlock) ~= nil then could confuse minecraft:nether_brick with minecraft:nether_brick_fence
				for k,v in pairs(tblPreferredBlock) do
					if data.name == v then
						slot = i
						break
					end
				end
			end
		end
	end
	if slot == 0 then --preferred block not found
		for i = 16, 1, -1 do
			if turtle.getItemCount(i) > 0 then
				local data = turtle.getItemDetail(i) -- returns {count = x, name = 'minecraft:item" in 1.16.2)
				for j = 1, #stone do -- using 'stone' table (class variable)
					if data.name == stone[j] then
						slot = i --slot no
						break
					end
				end
			end
		end
	end
	
	if slot > 0 then
		if not Detect() or not leaveExisting then -- fill void or replace existing block
			turtle.select(slot)
			Dig()
			local attempts = 0
			while not Place() do
				attempts = attempts + 1
				clsTurtle.attack(self, direction)
				print("Attacking: "..attempts.."/30")
				sleep(0.5)
				if attempts > 30 then
					return false, false
				end
			end
			placed = true
		end
	else
		noBlocks = true
	end
	
	turtle.select(1)
	return placed, noBlocks
end

function clsTurtle.findBedrockTop(self, height)
	-- clsTurtle.place(self, blockType, damageNo, direction, leaveExisting
	-- clsTurtle.go(self, path, useTorch, torchInterval, leaveExisting)
	local bedrockFound = false
	repeat
		bedrockFound = false
		clsTurtle.clear(self)
		print("Checking surrounding  blocks...")
		for i = 1, 4 do
			clsTurtle.turnLeft(self, 1)
			local block = clsTurtle.getBlockType(self, "forward")
			if block:find("bedrock") then
				bedrockFound = true
				print("Bedrock found...")
			else
				print("Found: "..block .. " in front")
			end
		end
		if bedrockFound then
			clsTurtle.up(self, 1)
			height = height -1 
			clsTurtle.place(self, "stone", -1, "down", true)
			print("Moving up...")
		end
	until not bedrockFound
	repeat
		bedrockFound = false
		local moved = 0
		for i = 1, 5 do
			if clsTurtle.forward(self, 1) then
				moved = moved + 1
				for i = 1, 4 do
					clsTurtle.turnLeft(self, 1)
					if clsTurtle.getBlockType(self, "forward"):find("bedrock") then
						bedrockFound = true
						print("Bedrock found: not continuing this row")
					end
				end
				if bedrockFound then
					break
				end
			else -- hit bedrock
				print("Hit bedrock in front")
				bedrockFound = true
				break
			end
		end
		clsTurtle.turnLeft(self, 2)
		for i = 1, moved do
			clsTurtle.go(self, "C2F1", false, 0, true)
		end
		clsTurtle.go(self, "L2C1", false, 0, true)
		if bedrockFound then
			print("Moving up...")
			clsTurtle.go(self, "U1C2", false, 0, true)
			height = height -1
		else
			print("Area clear of bedrock...")
		end
	until bedrockFound == false
	return height
end

function clsTurtle.getBlockType(self, direction)
	--[[ turtle.inspect() returns two values
		1) boolean (true/false) success
		2) table with two or more values:
		.name (string) e.g. "minecraft:log"
		.metadata (integer) e.g. 0
		oak has metadata of 0, spruce 1, birch 2 etc
		CC Tweaked / later MC versions:
		No .metadata
		.state {axis = "y"}
		.tags (["minecraft:logs"] = true, ["minecraft:logs_that_burn"] = true, ["minecraft:oak_logs"] = true}
	]]
	local blockType = ""
	local blockModifier = nil
	local success = false
	local data = {} --initialise empty table variable
 
	if direction == "up" then
		success, data = turtle.inspectUp() -- store information about the block above in a table	
	elseif direction == "down" then
		success, data = turtle.inspectDown() -- store information about the block below in a table
	else
		success, data = turtle.inspect() -- store information about the block ahead in a table
	end
	if success then -- block found
		blockType = data.name -- eg "minecraft:log"
		blockModifier = data.metadata
	end
	
	return blockType, blockModifier, data -- eg "minecraft:oak_log" , "", table
end

function clsTurtle.getCoords(self, fromFile)
	fromFile = fromFile or false
	--get world coordinates from player
	local coord = 0
	local response = ""
	local continue = true
	local event = ""
	local param1 = ""
	local getInput = true
	
	clsTurtle.clear(self)
	-- use built-in filesystem fs
	if fs.exists("homeCoords.txt") then --ask user if current coords are correct
		local fileHandle = fs.open("homeCoords.txt", "r")
		strText = fileHandle.readLine()
		self.x = tonumber(string.sub(strText, 3))
		strText = fileHandle.readLine()
		self.y = tonumber(string.sub(strText, 3))
		strText = fileHandle.readLine()
		self.z = tonumber(string.sub(strText, 3))
		strText = fileHandle.readLine()
		clsTurtle.setFacing(self, tonumber(string.sub(strText, 3)))
		fileHandle.close()
		clsTurtle.saveToLog(self, "Coordinates loaded from file:", false)
		clsTurtle.saveToLog(self, "x = "..self.x..", y = "..self.y..", z = "..self.z..", f = "..self.facing, false)
		print("Coordinates loaded from file:\n")
		print("XYZ: - "..self.x.." / "..self.y.." / "..self.z.."\n")
		print("Facing: "..self.compass)
		print("\nUse F3 to check these coordinates")
		write("\nAre they correct (y/n + Enter)?")
		response = read()
		if response == "y" or response == "" then
			getInput = false
		else
			clsTurtle.clear(self)
		end
	end
	if getInput then
		print("IMPORTANT! Stand directly behind turtle")
		print("Press F3 to read coordinates")
		print()
		continue = true
		while continue do
			print("Please enter your X coordinate")
			write("  x = ")
			coord = nil
			while coord == nil do
				coord = tonumber(read())
				if coord == nil then
					clsTurtle.clear(self)
					print("Incorrect input. Use numbers only!")
					print()
					print("Please enter your X coordinate")
					write("  x = ")
				end
			end
			self.x = coord
			clsTurtle.clear(self)
			print("Please enter your Y coordinate")
			write("  y = ")
			coord = nil
			while coord == nil do
				coord = tonumber(read())
				if coord == nil then
					clsTurtle.clear(self)
					print("Incorrect input. Use numbers only")
					print()
					print("Please enter your y coordinate")
					write("  y = ")
				end
			end
			self.y = coord
			clsTurtle.clear(self)
			print("Please enter your Z coordinate")
			write("  z = ")
			coord = nil
			while coord == nil do
				coord = tonumber(read())
				if coord == nil then
					clsTurtle.clear(self)
					print("Incorrect input. Use numbers only")
					print()
					print("Please enter your z coordinate")
					write("  z = ")
				end
			end
			self.z = coord
			response = true
			while response do
				response = false
				clsTurtle.clear(self)
				print("Enter Direction you are facing:")
				print("  0,1,2,3 (s,w,n,e)")
				print()
				print(  "  Direction = ")
				event, param1 = os.pullEvent ("char")
				if param1 == "s" or param1 == "S" then
					coord = 0
				elseif param1 == "w" or param1 == "W" then
					coord = 1
				elseif param1 == "n" or param1 == "N" then
					coord = 2
				elseif param1 == "e" or param1 == "E" then
					coord = 3
				elseif param1 == "0" or param1 == "1" or param1 == "2" or param1 == "3" then
					coord = tonumber(param1)
				else
					print()
					print("Incorrect input: "..param1)
					print()
					print("Use 0,1,2,3,n,s,w,e")
					sleep(2)
					response = true
				end
			end
			clsTurtle.setFacing(self, coord)
			clsTurtle.clear(self)
			print("Your current location is:")
			print()
			print("  x = "..self.x)
			print("  y = "..self.y)
			print("  z = "..self.z)
			print("  facing "..self.compass.." ("..self.facing..")")
			print()
			write("Is this correct? (y/n)")
			event, param1 = os.pullEvent ("char")
			if param1 == "y" or param1 == "Y" then
				continue = false
			end
		end
		-- correct coords to compensate for player standing position
		-- First tree is considered as point zero, on startup, turtle is in front of this tree
		-- Player is behind turtle, use 2 blocks to compensate
		-- facing:		Change:
		-- 0 (S)		z+1
		-- 1 (W)		x-1
		-- 2 (N)		z-1
		-- 3 (E)		x+1
		if self.facing == 0 then
			self.z = self.z + 2
		elseif self.facing == 1 then
			self.x = self.x - 2
		elseif self.facing == 2 then
			self.z = self.z - 2
		elseif self.facing == 3 then
			self.x = self.x + 2
		end
		
		-- create/overwrite 'homeCoords.txt'
		local fileHandle = fs.open("homeCoords.txt", "w")
		fileHandle.writeLine("x="..self.x)
		fileHandle.writeLine("y="..self.y)
		fileHandle.writeLine("z="..self.z)
		fileHandle.writeLine("f="..self.facing)
		fileHandle.close()
		clsTurtle.saveToLog(self, "homeCoords.txt file created", true)
		clsTurtle.saveToLog(self, "x = "..clsTurtle.getX(self)..", y = "..clsTurtle.getY(self)..", z = "..clsTurtle.getZ(self)..", f = "..clsTurtle.getFacing(self), false)
	end
end

function clsTurtle.getFirstEmptySlot(self)
	local slot = 0
	local emptySlots = 0
	for i = 1,16 do
		if turtle.getItemCount(i) == 0 then
			if slot == 0 then
				slot = i
			end
			emptySlots = emptySlots  + 1
		end
	end
	return slot, emptySlots
end

function clsTurtle.getInput(self)
	--[[
		returns correctly interpreted value without errors caused by user
		usage: in main program - local input = T:getInput()
		local choice = input.getBoolean("Do you like Lua?")
		if choice then
			print("Yay!")
		end
	]]
	
	local function tchelper(first, rest)
		return first:upper()..rest:lower()
	end
	local input = {}
	function input.getBoolean(prompt) -- assumes yes/no type entries from user
		while true do
			write(prompt.."_")
			userInput = read()
			if string.len(userInput) == 0 then
				print("\nJust pressing the Enter key doesn't work...")
			else		
				if string.sub(userInput, 1, 1):lower() == "y" then
					userInput = true
					break
				elseif string.sub(userInput, 1, 1):lower() == "n" then
					userInput = false
					break
				else
					print("\nOnly anything starting with y or n is accepted...")
				end
			end	
		end
		return userInput
	end
	function input.getString(prompt, withTitle, minInt, maxInt) -- withTitle, minInt and maxInt are given defaults if not passed
		withTitle = withTitle or false
		minInt = minInt or 1
		maxInt = maxInt or 20
		while true do
			write(prompt.."_")
			userInput = read()
			if string.len(userInput) == 0 then
				print("\nJust pressing Enter doesn't work...")
			else		
				if string.len(userInput) >= minInt and string.len(userInput) <= maxInt then
					if withTitle then
						userInput = input.toTitle(userInput)
					end
					break
				else
					print("\nTry entering text between "..minInt.." and "..maxInt.." characters...")
				end
			end
		end
	
		return userInput
	end
	function input.getInteger(prompt, minInt, maxInt) -- minInt and maxInt are given defaults if not passed
		minInt = minInt or 0
		maxInt = maxInt or 65536
		while true do
			write(prompt.."_")
			userInput = read()
			if string.len(userInput) == 0 then
				print("\nJust pressing the Enter key doesn't work...")
			else
				if tonumber(userInput) ~= nil then
					userInput = tonumber(userInput)
					if userInput >= minInt and userInput <= maxInt then
						break
					else
						print("\nTry a number from "..minInt.." to "..maxInt.."...")
					end
				else
					print("\nTry entering a number - "..userInput.." does not cut it...")
				end
			end
		end
		return userInput
	end
	
	function input.toTitle(inputText) --converts any string to Title Case
		return inputText:gsub("(%a)([%w_']*)", tchelper)
	end
	
	return input
end

function clsTurtle.getItemCount(self, item, modifier)
	local slot, damage, total, slotData = clsTurtle.getItemSlot(self, item, modifier) --return .leastSlot, .leastModifier, total, slotData
	return total
end

function clsTurtle.getItemName(self, slot)
	local data = {} --initialise empty table variable
	data.name = ""
	
	if turtle.getItemCount(slot) > 0 then
		data = turtle.getItemDetail(slot)
	end
	
	return data.name
end

function clsTurtle.getItemSlot(self, item, useDamage)
	-- return slot no with least count, damage(modifier) and total count available
	-- along with a table of mostSlot, mostCount, leastSlot, leastCount
	-- if minecraft:log or log2, names for 1.16.2 changed to 'minecraft:oak_log' etc so use wildcards 'log'
	-- damage for 1.16.2 does not exist and is always nil
	item = item or "common"
	useDamage = useDamage or -1 -- -1 damage means is not relevant
	local data = {} --initialise empty table variable
	local slotData = {}
	local total = 0
	local common =
	{
		"minecraft:cobblestone",
		"minecraft:deepslate",
		"minecraft:cobbled_deepslate",
		"minecraft:netherrack",
		"minecraft:stone",
		"minecraft:granite",
		"minecraft:diorite",
		"minecraft:andesite",
		"minecraft:end_stone",
		"minecraft:tuff",
		"minecraft:basalt",
		"minecraft:dirt"
		-- will be selected in this order of priority after preferredBlock
	}
	-- setup return table
	slotData.firstSlot = 0
	slotData.lastSlot = 0
	slotData.mostSlot = 0
	slotData.mostName = ""
	slotData.mostCount = 0
	slotData.mostModifier = 0
	slotData.leastSlot = 0
	slotData.leastName = ""
	slotData.leastCount = 0
	slotData.leastModifier = 0
	for i = 1, 16 do
		local count = turtle.getItemCount(i)
		local doProcess = false
		if count > 0 then
			data = turtle.getItemDetail(i) -- returns {count = x, name = 'minecraft:item" in 1.16.2)
			if item:find("\:") ~= nil then -- find exact match only
				if data.name == item and (data.damage == nil or data.damage == useDamage or useDamage == -1) then
					doProcess = true
					if slotData.firstSlot == 0 then
						slotData.firstSlot = i
					end
					slotData.lastSlot = i
				end
			else
				if item:find("common") ~= nil or item == "any" or item == "stone" then
					for j = 1, #common do
						if data.name == common[j] then
							doProcess = true
							if slotData.firstSlot == 0 then
								slotData.firstSlot = i
							end
							slotData.lastSlot = i
						end
					end
				elseif data.name:find(item) ~= nil and (data.damage == nil or data.damage == useDamage or useDamage == -1) then
					doProcess = true
					if slotData.firstSlot == 0 then
						slotData.firstSlot = i
					end
					slotData.lastSlot = i
				end
			end
			if doProcess then
				total = total + count
				if count > slotData.mostCount then
					slotData.mostSlot = i
					slotData.mostName = data.name
					slotData.mostCount = count
					slotData.mostModifier = data.damage
				end
				if count < slotData.leastCount then
					slotData.leastSlot = i
					slotData.leastName = data.name
					slotData.leastCount = count
					slotData.leastModifier = data.damage
				end
			end
		end
	end
	if slotData.mostSlot > 0 then
		if slotData.leastSlot == 0 then
			slotData.leastSlot = slotData.mostSlot
			slotData.leastName = slotData.mostName
			slotData.leastCount = slotData.mostCount
			slotData.leastModifier = slotData.mostModifier
		end
	end
	
	--return slotData.leastSlot, slotData.leastModifier, total, slotData -- integer, integer, integer, table OR integer, nil, integer, table
	return slotData.lastSlot, slotData.leastModifier, total, slotData -- integer, integer, integer, table OR integer, nil, integer, table
end

function clsTurtle.getMostItem(self, excludeItem)
	--[[ Used to get user choice of stone based on quantity ]]
	excludeItem = excludeItem or ""
	local data = {} --initialise empty table variable
	local inventory = {}
	local mostItem = ""
	local mostCount = 0
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			data = turtle.getItemDetail(i)
			if inventory[data.name] == nil then
				inventory[data.name] = data.count
			else
				inventory[data.name] = inventory[data.name] + data.count
			end
		end
	end
	for k,v in pairs(inventory) do
		if mostItem == "" then
			if excludeItem ~= "" then
				if k:find(excludeItem) == nil then
					mostItem = k
					mostCount = v
				end
			else
				mostItem = k
				mostCount = v
			end
		else
			if inventory[k] > mostCount then
				mostItem = k
				mostCount = v
			end
		end
	end
	return mostItem, mostCount
end

function clsTurtle.getSaplingSlot(self, name)
	local saplingSlot = 0
	local count = 0
	local data = {name = ""} -- in case no saplings found
	if name == nil then
		name = "sapling"
	end
	for i = 1, 16 do
		count = turtle.getItemCount(i)
		if count > 0 then
			data = turtle.getItemDetail(i) -- returns {count = x, name = 'minecraft:item" in 1.16.2)
			if data.name:find(name) ~= nil then
				saplingSlot = i
				break
			end
		end
	end
	return saplingSlot, data.name, count -- 0, "" / "minecraft:oak_sapling", 6
end

function clsTurtle.getPlaceChestDirection(self)
	local facing = self.facing
	local chestDirection = "forward"
	local turns = 0
	
	for i = 1, 4 do
		if turtle.detect() then
			clsTurtle.turnRight(self, 1)
			turns = turns + 1
		else
			break
		end
	end
	if turns == 4 then -- full circle
		turns = 0
		if turtle.detectDown() then -- no space below
			if turtle.detectUp() then
				if clsTurtle.dig(self, "up") then
					chestDirection = "up"
				end
			else
				chestDirection = "up"
			end
		else
			chestDirection = "down"
		end
	end
	return chestDirection, turns -- will be "forward" or "up", 0 - 3
end

function clsTurtle.getSlotContains(self, slotNo)
	local data = {} --initialise empty table variable
	
	local slotCount = 0
	local slotContains = ""
	local slotDamage = 0
	if turtle.getItemCount(slotNo) > 0 then
		data = turtle.getItemDetail(slotNo)
		slotCount = data.count
		slotContains = data.name
		slotDamage = data.damage -- nil on CCTweaked
	end
	
	return slotContains, slotCount, slotDamage
end

function clsTurtle.getStock(self, item, modifier)
	-- return total units and slot numbers of max and min amounts
	local slot, damage, total, slotData = clsTurtle.getItemSlot(self, item, modifier) --return .leastSlot, .leastModifier, total, slotData
	local rt = {}
	rt.total = total
	rt.mostSlot = slotData.mostSlot
	rt.leastSlot = slotData.leastSlot
	rt.mostCount = slotData.mostCount
	rt.leastCount = slotData.leastCount
	if slot == 0 then
		if modifier == nil then
			--clsTurtle.saveToLog(self, "getStock()"..tostring(item).."= not found", true)
		else
			--clsTurtle.saveToLog(self, "getStock()"..tostring(item).."("..tostring(modifier)..")= not found")
		end
	end
	
	return rt --{rt.total, rt.mostSlot, rt.leastSlot, rt.mostCount, rt.leastCount}
end

function clsTurtle.getSolidBlockCount(self)
	local retValue = 0
	local solids = {'cobble', 'stone', 'dirt', 'granite', 'andesite', 'diorite', 'deepslate', 'glass', 'tuff'}
	local slotCount, slotContains, slotDamage
	for i = 1, 16 do
		-- slotContains, slotCount, slotDamage
		slotContains, slotCount, slotDamage = clsTurtle.getSlotContains(self, i)
		for _, v in ipairs(solids) do
			if slotContains:find(v) ~= nil then
				retValue = retValue + slotCount
			end
		end
	end
	return retValue
end

function clsTurtle.getTotalItemCount(self)
	local count = 0
	
	for i = 1, 16 do
		count = count + turtle.getItemCount(i)
	end
	return count
end

function clsTurtle.go(self, path, useTorch, torchInterval, leaveExisting, preferredBlock)
	useTorch = useTorch or false -- used in m and M to place torches in mines
	if leaveExisting == nil then
		leaveExisting = false
	end
	torchInterval = torchInterval or 8
	if preferredBlock == nil then
		preferredBlock = {} -- used for C command to allow faster placing of specific block
	else
		if type(preferredBlock) ~= "table" then
			preferredBlock = {preferredBlock}
		end
	end
	
	local intervalList =
	{
		1, 
		torchInterval * 1 + 1,
		torchInterval * 2 + 1,
		torchInterval * 3 + 1,
		torchInterval * 4 + 1,
		torchInterval * 5 + 1,
		torchInterval * 6 + 1
	}
	local slot = turtle.getSelectedSlot()
	turtle.select(1)		
	local commandList = {}
	local command = ""
	local direction = {"up", "forward", "down"}
	-- remove spaces from path
	path = string.gsub(path, " ", "")
	-- make a list of commands from path string eg "x0F12U1" = x0, F12, U1
	for i = 1, string.len(path) do
		local character = string.sub(path, i, i) -- examine each character in the string
		if tonumber(character) == nil then -- char is NOT a number
			if command ~= "" then -- command is NOT empty eg "x0"
				table.insert(commandList, command) -- add to table eg "x0"
			end
			command = character -- replace command with new character eg "F"
		else -- char IS a number
			command = command..character -- add eg 1 to F = F1, 2 to F1 = F12
			if i == string.len(path) then -- last character in the string
				table.insert(commandList, command)
			end
		end
	end
	-- R# L# F# B# U# D# +0 -0 d0 = Right, Left, Forward, Back, Up, Down, up while detect and return, down while not detect, down and place while not detect
	-- dig:			  x0,x1,x2 (up/fwd/down)
	-- suck:		  s0,s1,s2
	-- place chest:   H0,H1,H2 
	-- place sapling: S0,S1,S2
	-- place Torch:   T0,T1,T2
	-- place Hopper:  P0,P1,P2
	-- mine floor:	  m# = mine # blocks above and below, checking for valuable items below, and filling space with cobble or dirt
	-- mine ceiling:  M# = mine # blocks, checking for valuable items above, and filling space with cobble or dirt
	-- mine ceiling:  N# same as M but not mining block below unless valuable
	-- mine floor:    n# mine block below and/or fill void + check left side
	-- mine ceiling:  Q# same as M + mine block below if valuable + left side
	-- mine wall:     q# mine # blocks forward, check left side and patch
	-- tunnel top:	  A# fill voids above and both sides
	-- tunnel bottom: E# fill voids both sides, remove floor
	-- tunnel bottom: X# fill voids both sides and floor
	-- QuickMine      V# take block above if valuable, fill void above, fill void below
	-- QuickCoridoor  W# take block below, take block above if valuable, fill void above
	-- mine - bedrock Z#
	-- place:		  C,H,r,S,T,P,^ = Cobble / cHest / DIrT / Sapling / Torch / hoPper /stair in direction 0/1/2 (up/fwd/down) eg C2 = place cobble down
	-- place:         t = 0/1 = place behind, 2 = cobble first, up torch, forward down
	-- place:		  e = ladder, direction
	-- place:		  @ = any block in inventory, direction
	-- X			  mine block below and/or fill void, then check sides (X = trench)
	-- +			  while detectUp digUp and move up. Return to original position after
	-- ^			  place stairs
	clsTurtle.refuel(self, 15)
	turtle.select(1)
	for cmd in clsTurtle.values(self, commandList) do -- eg F12 or x1
		local move = string.sub(cmd, 1, 1)
		local modifier = tonumber(string.sub(cmd, 2))
		if move == "A" then --mine block above and/or fill void + fill both sides
			turtle.select(1)
			--[[check block behind
			clsTurtle.turnRight(self, 2)
			clsTurtle.digValuable(self, "forward")
			clsTurtle.fillVoid(self, "forward")
			clsTurtle.turnRight(self, 2)]]
			for i = 1, modifier + 1 do --eg A16 run loop 17 x
				clsTurtle.digValuable(self, "up")
				clsTurtle.fillVoid(self, "up")
				clsTurtle.turnLeft(self, 1)
				clsTurtle.digValuable(self, "forward")
				clsTurtle.fillVoid(self, "forward")
				clsTurtle.turnRight(self, 2)
				clsTurtle.digValuable(self, "forward")
				clsTurtle.fillVoid(self, "forward")
				clsTurtle.turnLeft(self, 1)
				--clsTurtle.dig(self, "down") -- create player coridoor
				if i <= modifier then -- A16 = move forward 16x
					clsTurtle.forward(self, 1)
				end
			end
			--check block at end
			clsTurtle.digValuable(self, "forward")
			clsTurtle.fillVoid(self, "forward")
		elseif move == "B" then
			clsTurtle.back(self, modifier)
		elseif move == "c" then
			if turtle.detectDown() then
				--check if vegetation and remove
				if clsTurtle.isSeaweed(self, "down") then
					turtle.digDown()
				end
			end
			if not turtle.detectDown() then
				if not clsTurtle.place(self, "minecraft:cobblestone", -1, "down") then
					clsTurtle.place(self, "minecraft:dirt", -1, "down")
				end
			end
		elseif move == "C" then
			-- fillVoid(self, direction, tblPreferredBlock, leaveExisting)
			clsTurtle.digValuable(self, direction[modifier + 1])
			clsTurtle.fillVoid(self, direction[modifier + 1], preferredBlock, leaveExisting)
		elseif move == "d" then -- down and place while not detect
			if modifier == 1 then
				clsTurtle.fillVoid(self, "forward", preferredBlock)
			end
			while not turtle.detectDown() do
				clsTurtle.down(self, 1)
				if modifier == 1 then
					clsTurtle.fillVoid(self, "forward", preferredBlock)
				end
			end
			if modifier == 1 then
				clsTurtle.fillVoid(self, "forward", preferredBlock)
			end
		elseif move == "D" then
			clsTurtle.down(self, modifier)
		elseif move == "e" then -- ladder above / in front / below
			clsTurtle.place(self, "minecraft:ladder", -1, direction[modifier + 1], false)
		elseif move == "E" then --mine block below + fill both sides
			turtle.select(1)
			--check block behind
			clsTurtle.turnRight(self, 2)
			clsTurtle.digValuable(self, "forward")
			clsTurtle.fillVoid(self, "forward")
			clsTurtle.turnRight(self, 2)
			for i = 1, modifier + 1 do --eg A16 run loop 17 x
				clsTurtle.turnLeft(self, 1)
				clsTurtle.digValuable(self, "forward")
				clsTurtle.fillVoid(self, "forward")
				clsTurtle.turnRight(self, 2)
				clsTurtle.digValuable(self, "forward")
				clsTurtle.fillVoid(self, "forward")
				clsTurtle.turnLeft(self, 1)
				clsTurtle.dig(self, "down") -- create player coridoor
				if i <= modifier then -- A16 = move forward 16x
					clsTurtle.forward(self, 1)
				end
			end
			--check block at end
			clsTurtle.digValuable(self, "forward")
			clsTurtle.fillVoid(self, "forward")
		elseif move == "F" then
			clsTurtle.forward(self, modifier)
		elseif move == "H" then
			clsTurtle.place(self, "minecraft:chest", -1, direction[modifier + 1], leaveExisting)
		elseif move == "L" then
			clsTurtle.turnLeft(self, modifier)
		elseif move == "m" then --mine block below and/or fill void
			--T:go("m8", false, 0, false, brick)
			for i = 1, modifier + 1 do --eg m8 run loop 9 x
				turtle.select(1)
				local isValuable, blockType = clsTurtle.isValuable(self, "down")
				if isValuable or blockType == "minecraft:gravel" or not leaveExisting then
					turtle.digDown() -- dig if gravel
				elseif blockType == "minecraft:lava" then
					clsTurtle.place(self, "minecraft:bucket", -1, "down")
				end
				clsTurtle.dig(self, "up") -- create player coridoor
				if not turtle.detectDown() then
					clsTurtle.fillVoid(self, "down", preferredBlock, leaveExisting)
				end
				if i <= modifier then -- n8 = move forward 8x. check for initial use in mine to avoid torch in wrong place
					if useTorch then
						if  (i == intervalList[1] and modifier >= 16) or
							i == intervalList[2] or
							i == intervalList[3] or
							i == intervalList[4] or
							i == intervalList[5] then
							clsTurtle.up(self, 1)
							clsTurtle.place(self, "minecraft:torch", -1, "down", false)
							clsTurtle.forward(self, 1)
							clsTurtle.down(self, 1)
						else
							clsTurtle.forward(self, 1)
						end
					else
						clsTurtle.forward(self, 1)
					end
				end
			end
		elseif move == "M" then --mine block above and/or fill void
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = clsTurtle.isValuable(self, "up")
				if isValuable then
					clsTurtle.dig(self, "up")
				elseif blockType == "minecraft:lava" then
					clsTurtle.place(self, "minecraft:bucket", -1, "up")
				end
				if not turtle.detectUp()then
					clsTurtle.fillVoid(self, "up", preferredBlock)
				end
				if i <= modifier then -- will not move forward if modifier = 0
					if useTorch then
						if  i == intervalList[1] or
							i == intervalList[2] or
							i == intervalList[3] or
							i == intervalList[4] or
							i == intervalList[5] then
							clsTurtle.place(self, "minecraft:torch", -1, "down", false)
						end
					end
					clsTurtle.forward(self, 1)
				end
			end
		elseif move == "n" then --mine block below and/or fill void + check left side
			for i = 1, modifier + 1 do --eg m8 run loop 9 x
				turtle.select(1)
				local isValuable, blockType = clsTurtle.isValuable(self, "down")
				if isValuable or blockType == "minecraft:gravel" or not leaveExisting then
					turtle.digDown() -- dig if valuable or gravel
				else --check for lava
					if blockType == "minecraft:lava" then
						clsTurtle.place(self, "minecraft:bucket", -1, "down")
					end
				end
				clsTurtle.dig(self, "up") -- create player coridoor
				if not turtle.detectDown() then
					clsTurtle.fillVoid(self, "down", preferredBlock)
				end
				clsTurtle.turnLeft(self, 1)
				local isValuable, blockType = clsTurtle.isValuable(self, "forward")
				if isValuable or not leaveExisting then
					turtle.dig() -- dig if valuable
				end
				if not turtle.detect() then
					clsTurtle.fillVoid(self, "forward", preferredBlock, leaveExisting)
				end
				clsTurtle.turnRight(self, 1)	
				if i <= modifier then -- m8 = move forward 8x
					if useTorch then
						if  i == intervalList[1] or
							i == intervalList[2] or
							i == intervalList[3] or
							i == intervalList[4] or
							i == intervalList[5] then
							clsTurtle.up(self, 1)
							clsTurtle.place(self, "minecraft:torch", -1, "down", false)
							clsTurtle.forward(self, 1)
							clsTurtle.down(self, 1)
						else
							clsTurtle.forward(self, 1)
						end
					else
						clsTurtle.forward(self, 1)
					end
				end
			end
		elseif move == "N" then --mine block above and/or fill void + mine block below if valuable
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = clsTurtle.isValuable(self, "up")
				if isValuable then
					clsTurtle.dig(self, "up")
				elseif blockType == "minecraft:lava" then
					clsTurtle.place(self, "minecraft:bucket", -1, "up")
				end
				if not turtle.detectUp() then
					clsTurtle.fillVoid(self, "up", preferredBlock)
				end
				turtle.select(1)
				isValuable, blockType = clsTurtle.isValuable(self, "down")
				if isValuable then
					clsTurtle.dig(self, "down")
					clsTurtle.fillVoid(self, "down", preferredBlock)
				else
					if clsTurtle.getBlockType(self, "down") == "minecraft:lava" then
						clsTurtle.place(self, "minecraft:bucket", -1, "down")
					end
				end
				if i <= modifier then
					clsTurtle.forward(self, 1)
				end
			end
		elseif move == "P" then
			clsTurtle.place(self, "minecraft:hopper", -1, direction[modifier + 1], leaveExisting)
		elseif move == "q" then --mine block and fill voids on left side left side
			for i = 1, modifier + 1 do
				turtle.select(1)
				clsTurtle.turnLeft(self, 1)
				if clsTurtle.isValuable(self, "forward") then
					turtle.dig() -- dig if valuable
				end
				if not turtle.detect() then
					clsTurtle.fillVoid(self, "forward", preferredBlock)
				end
				clsTurtle.turnRight(self, 1)	
				if i <= modifier then
					clsTurtle.forward(self, 1)
				end
			end
		elseif move == "Q" then --mine block above and/or fill void + mine block below if valuable + left side
			for i = 1, modifier + 1 do
				turtle.select(1)
				if clsTurtle.isValuable(self, "up") then
					clsTurtle.dig(self, "up")
				else --check for lava
					if clsTurtle.getBlockType(self, "up") == "minecraft:lava" then
						clsTurtle.place(self, "minecraft:bucket", -1, "up")
					end
				end
				if not turtle.detectUp() then
					clsTurtle.fillVoid(self, "up", preferredBlock)
				end
				clsTurtle.turnLeft(self, 1)
				if clsTurtle.isValuable(self, "forward") then
					turtle.dig() -- dig if valuable
				end
				if not turtle.detect() then
					clsTurtle.fillVoid(self, "forward", preferredBlock)
				end
				clsTurtle.turnRight(self, 1)	
				if clsTurtle.isValuable(self, "down") then
					turtle.digDown()
				end
				if i <= modifier then
					clsTurtle.forward(self, 1)
				end
			end
		elseif move == "r" then
			clsTurtle.place(self, "minecraft:dirt", -1, direction[modifier + 1], leaveExisting)
		elseif move == "R" then
			clsTurtle.turnRight(self, modifier)
		elseif move == "s" then
			if modifier == 0 then
				while turtle.suckUp() do end
			elseif modifier == 1 then
				while turtle.suck() do end
			elseif modifier == 2 then
				while turtle.suckDown() do end
			end
		elseif move == "S" then
			clsTurtle.place(self, "sapling", -1, direction[modifier + 1], leaveExisting)
		elseif move == "t" then
			-- 0 = placeUp does not work with os 1.8
			-- 1 = turn round, placeForward
			-- 2 = placeDown
			-- 3 = turnLeft, placeUp
			-- 4 = turnround, placeUp
			-- 5 = place down without block
			if modifier == 0 then -- os < 1.8
				clsTurtle.place(self, "minecraft:torch", -1, "up", false)
			elseif modifier == 1 then --place behind
				clsTurtle.turnLeft(self, 2)
				--local block, blockType = clsTurtle.isWaterOrLava(self, "forward")
				--if block ~= "minecraft:water" and block ~= "minecraft:lava" then
					clsTurtle.place(self, "minecraft:torch", -1, "forward", false)
				--end
				clsTurtle.turnLeft(self, 2)
			elseif modifier == 2 then -- place below for 2
				if not clsTurtle.place(self, "minecraft:cobblestone", -1,"down") then
					clsTurtle.place(self, "minecraft:dirt", -1, "down")
				end
				clsTurtle.up(self, 1)
				--local block, blockType = clsTurtle.isWaterOrLava(self, "down")
				--if block ~= "minecraft:water" and block ~= "minecraft:lava" then
					clsTurtle.place(self, "minecraft:torch", -1, "down", false)
				--end
				clsTurtle.forward(self, 1)
				clsTurtle.down(self, 1)
			elseif modifier == 3 then --turnLeft, placeUp (on ground to wall)
				clsTurtle.turnLeft(self, 1)
				clsTurtle.place(self, "minecraft:torch", -1, "up", false)
				clsTurtle.turnRight(self, 1)
			elseif modifier == 4 then --turnLeft, placeUp (on ground to wall)
				clsTurtle.turnLeft(self, 2)
				clsTurtle.place(self, "minecraft:torch", -1, "up", false)
				clsTurtle.turnLeft(self, 2)
			elseif modifier == 5 then --cobble first, then torch
				clsTurtle.place(self, "minecraft:torch", -1, "down", false)
			end
		elseif move == "T" then
			clsTurtle.place(self, "minecraft:torch", -1, direction[modifier + 1], leaveExisting)
		elseif move == "u" then -- move up and place forward/down
			repeat
				if modifier == 1 then
					clsTurtle.fillVoid(self, "forward", preferredBlock, leaveExisting)
				end
				clsTurtle.up(self, 1)
				if modifier == 1 then
					clsTurtle.fillVoid(self, "forward", preferredBlock, leaveExisting)
				end
				clsTurtle.fillVoid(self, "down", preferredBlock, leaveExisting)
			until not turtle.inspectUp()
			if modifier == 1 then
				clsTurtle.fillVoid(self, "forward", preferredBlock, leaveExisting)
			end
		elseif move == "U" then
			clsTurtle.up(self, modifier)
		elseif move == "x" then
			if modifier == 0 then
				clsTurtle.dig(self, "up")
			elseif modifier == 1 then
				clsTurtle.dig(self, "forward")
			elseif modifier == 2 then
				while turtle.detectDown() do
					turtle.digDown()
				end
			end
		elseif move == "V" then --QuickMine
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = clsTurtle.isValuable(self, "down")
				if isValuable then
					clsTurtle.dig(self, "down")
				elseif blockType == "minecraft:lava" then
					clsTurtle.place(self, "minecraft:bucket", -1, "down")
				end
				isValuable, blockType = clsTurtle.isValuable(self, "up")
				if isValuable then
					clsTurtle.dig(self, "up")
				elseif blockType == "minecraft:lava" then
					clsTurtle.place(self, "minecraft:bucket", -1, "up")
				end
				if not turtle.detectUp()then
					clsTurtle.fillVoid(self, "up", preferredBlock)
				end
				if not turtle.detectDown()then
					clsTurtle.fillVoid(self, "down", preferredBlock)
				end
				if i <= modifier then -- will not move forward if modifier = 0
					clsTurtle.forward(self, 1)
				end
			end
		elseif move == "W" then --QuickCoridoor
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = clsTurtle.isValuable(self, "up")
				if isValuable then
					clsTurtle.dig(self, "up")
				elseif blockType == "minecraft:lava" then
					clsTurtle.place(self, "minecraft:bucket", -1, "up")
				end
				if not turtle.detectUp()then
					clsTurtle.fillVoid(self, "up", preferredBlock)
				end
				clsTurtle.isWaterOrLava(self, "down") -- automatically removes lava
				clsTurtle.dig(self, "down")
				if i <= modifier then -- will not move forward if modifier = 0
					clsTurtle.forward(self, 1)
				end
			end
		elseif move == "X" then --mine block below and/or fill void, then check sides (X = trench)
			for i = 1, modifier + 1 do --eg X8 run loop 9 x
				turtle.select(1)
				local isValuable, blockType = clsTurtle.isValuable(self, "down")
				if isValuable or blockType == "minecraft:gravel" or blockType == "minecraft:sand" or blockType:find("grass") ~= nil then
					turtle.digDown() -- dig if gravel
				else --check for lava
					if blockType == "minecraft:lava" then
						clsTurtle.place(self, "minecraft:bucket", -1, "down")
					end
				end
				clsTurtle.dig(self, "up") -- create player coridoor
				if not turtle.detectDown() then
					clsTurtle.fillVoid(self, "down")
				end
				clsTurtle.turnRight(self, 1)
				if not turtle.detect() then
					clsTurtle.fillVoid(self, "forward")
				end
				clsTurtle.turnLeft(self, 2)
				if not turtle.detect() then
					clsTurtle.fillVoid(self, "forward")
				end
				clsTurtle.turnRight(self, 1)
				if i <= modifier then -- X8 = move forward 8x
					clsTurtle.forward(self, 1)
				end
			end
		elseif move == "Z" then -- mine to bedrock
			for i = 1, modifier + 1 do	
				turtle.select(1)
				local goUp = 0
				while clsTurtle.down(self, 1) do
					goUp = goUp + 1
				end
				for j = goUp, 1, -1 do
					for k = 1, 4 do
						clsTurtle.turnRight(self, 1)
						if clsTurtle.isValuable(self, "forward") then
							clsTurtle.place(self, "minecraft:cobblestone", -1, "forward")
						end
					end
					clsTurtle.up(self, 1)
					clsTurtle.place(self, "minecraft:cobblestone", -1, "down")
					turtle.select(1)
				end
				if i <= modifier then 
					clsTurtle.forward(self, 2)
				end
			end
		elseif move == "+" then
			local height = 0
			while turtle.detectUp() do
				clsTurtle.up(self, 1)
				height = height + 1
			end
			clsTurtle.down(self, height)
		elseif move == "-" then
			while not turtle.inspectDown() do
				clsTurtle.down(self, 1)
			end
		elseif move == "*" then
			local goUp = 0
			while not turtle.inspectDown() do
				clsTurtle.down(self, 1)
				goUp = goUp + 1
			end
			if goUp > 0 then
				for i = 1, goUp do
					clsTurtle.up(self, 1)
					if not clsTurtle.place(self, "minecraft:cobblestone", -1, "down") then
						clsTurtle.place(self, "minecraft:dirt", -1, "down")
					end
				end
				goUp = 0
			else
				turtle.digDown()
				if not clsTurtle.place(self, "minecraft:cobblestone", -1, "down") then
					clsTurtle.place(self, "minecraft:dirt", -1, "down")
				end
			end
		elseif move == "^" then --place stair
			if not clsTurtle.place(self, "stairs", -1, direction[modifier + 1], false) then -- ending false forces block replacement
				print("could not place stairs "..direction[modifier + 1])
				clsTurtle.place(self, "minecraft:cobblestone", -1, direction[modifier + 1], false)
			end
		elseif move == "@" then -- any item in inventory
			clsTurtle.place(self, "", -1, direction[modifier + 1], leaveExisting)
		end
	end
	turtle.select(slot)
end

function clsTurtle.harvestTree(self, extend, craftChest, direction)
	extend = extend or false
	craftChest = craftChest or false
	direction = direction or "forward"
	local goHeight = 0
	local onLeft = true		-- default position in double tree
	if direction == "forward" then
		turtle.dig()       	-- dig base of tree
		clsTurtle.forward(self, 1) -- go under tree with 1 log. Will refuel if needed
	end
	-- check if on r or l of double width tree
	clsTurtle.turnLeft(self, 1)
	local blockType = clsTurtle.getBlockType(self, "forward")
	if blockType:find("log") ~= nil then
		extend = true
		onLeft = false 				-- placed on right side of 2 block tree
	end
	clsTurtle.turnRight(self, 2)	-- check if double tree
	blockType = clsTurtle.getBlockType(self, "forward")
	if blockType:find("log") ~= nil then
		extend = true
		onLeft = true 				-- placed on left side of 2 block tree
	end
	clsTurtle.turnLeft(self, 1)	-- return to correct position
	if craftChest then
		clsTurtle.dig(self, "up")
		clsTurtle.up(self, 1)
		clsTurtle.dig(self, "up")
		while not clsTurtle.detect(self, "down") do
			clsTurtle.down(self, 1)
		end
		clsTurtle.craft(self, "planks", 8)
		clsTurtle.craft(self, "chest", 1)
		while clsTurtle.detect(self, "up") do
			clsTurtle.up(self, 1)
			goHeight = goHeight + 1
		end
	end
	-- Loop to climb up tree and harvest trunk and surrounding leaves
	while clsTurtle.dig(self, "up") do -- continue loop while block detected above
		clsTurtle.up(self, 1)  -- Move up
		goHeight = goHeight + 1
		-- Inner loop to check for leaves/ break double tree logs
		for i = 1, 4 do
			blockType = clsTurtle.getBlockType(self, "forward")
			if blockType:find("log") ~= nil or blockType:find("leaves") ~= nil then
				clsTurtle.dig(self, "forward") --Dig leaves / logs in double tree. Leave bee nests
			end
			clsTurtle.turnRight(self, 1)
		end
	end
	-- At top of the tree. New loop to return to ground
	if extend then
		if onLeft then
			clsTurtle.go(self, "F1R1F1R2")
		else
			clsTurtle.go(self, "F1L1F1R2")
		end
		while turtle.detectUp() do
			clsTurtle.up(self, 1)
			goHeight = goHeight + 1
		end
	end
	for i = 1, goHeight do
		if extend then
			for j = 1, 4 do
				clsTurtle.dig(self, "forward")
				clsTurtle.turnRight(self, 1)
			end
		end
		clsTurtle.down(self, 1)
	end
	-- check for logs below in case felling started above ground
	while clsTurtle.getBlockType(self, "down"):find("log") ~= nil do
		clsTurtle.down(self, 1)
	end
	if extend then
		if onLeft then
			clsTurtle.go(self, "F1L1F1R2")
		else
			clsTurtle.go(self, "F1R1F1R2")
		end
	end
	return extend	-- true if double tree
end

function clsTurtle.harvestWholeTree(self, direction)	
	--RECURSIVE FUNCTION - BEWARE!
	local blockType, modifier, height

	if direction == "up" then
		clsTurtle.refuel(self, 15)
		if clsTurtle.isLog(self, "up") then
			clsTurtle.up(self, 1)
			if clsTurtle.isLog(self, "up") then
				clsTurtle.harvestWholeTree(self, "up")
			end
		end
		clsTurtle.down(self, 1)
		for i = 1, 4 do
			-- check all round
			if clsTurtle.isLog(self, "forward") then
				clsTurtle.harvestWholeTree(self, "forward")
			else
				blockType, modifier = clsTurtle.getBlockType(self, "forward")
				if blockType ~= "" then
					if string.find(blockType, "leaves") ~= nil then
						clsTurtle.forward(self, 1)
						clsTurtle.harvestWholeTree(self, "forward")
						clsTurtle.back(self, 1)
					end
				end
			end
			clsTurtle.turnRight(self, 1)
		end
	elseif direction == "forward" then
		if clsTurtle.isLog(self, "forward") then
			clsTurtle.refuel(self, 15)
			
			clsTurtle.forward(self, 1)
			if turtle.detectUp() then
				turtle.digUp()
			end
			if clsTurtle.isLog(self, "forward") then
				clsTurtle.harvestWholeTree(self, "forward")
			end
			--check left side
			clsTurtle.turnLeft(self, 1)
			if clsTurtle.isLog(self, "forward") then
				clsTurtle.harvestWholeTree(self, "forward")
			end
			-- check right side
			clsTurtle.turnRight(self, 2)
			if clsTurtle.isLog(self, "forward") then
				clsTurtle.harvestWholeTree(self, "forward")
			end
			clsTurtle.turnLeft(self, 1)
			clsTurtle.back(self, 1)
		end
	end
end

function clsTurtle.isEmpty(self)
	local isEmpty = true
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			isEmpty = false
			break
		end
	end
	return isEmpty
end

function clsTurtle.isLog(self, direction) 
	local success = false
	local blockType, modifier
	
	local Detect = turtle.detect
	if direction == 'up' then
		Detect = turtle.detectUp
	elseif direction == 'down' then
		Detect = turtle.detectDown
	end
	
	if Detect() then
		blockType, modifier = clsTurtle.getBlockType(self, direction)
		if string.find(blockType, 'log') ~= nil then
			success = true
		end
	end
	
	return success
end

function clsTurtle.isValuable(self, direction) 
	local success = false
	local blockType = ""
	local blockModifier

	local ignoreList = "minecraft:dirt,minecraft:grass,minecraft:stone,minecraft:gravel,minecraft:chest,"..
					 "minecraft:cobblestone,minecraft:sand,minecraft:torch,minecraft:bedrock,minecraft:ladder"..
					 "minecraft:netherrack,minecraft:blackstone,minecraft:basalt"..
					 "minecraft:granite,minecraft:diorite,minecraft:andesite"..
					 "minecraft:deepslate,minecraft:cobbled_deepslate,minecraft:tuff"

					 
	local Detect = turtle.detect
	
	if direction == "up" then
		Detect = turtle.detectUp
	elseif direction == "down" then
		Detect = turtle.detectDown
	end
	
	if Detect() then
		blockType, blockModifier = clsTurtle.getBlockType(self, direction)
	end
	
	if blockType ~= "" then --block found
		success = true
		if ignoreList:find(blockType) ~= nil then
			success = false
		end
	end
	if success then
		-- check if diamond. or netherite if so ensure space in inventory
		if blockType:find("diamond") ~= nil or blockType:find("debris") ~= nil then
			clsTurtle.dumpRefuse(self, direction)
		end
	end
	return success, blockType
end

function clsTurtle.isSeaweed(self, direction)
	--[[ look for seaweed in specified direction ]]
	local Detect = turtle.detect
	local blockName, blockModifier
	if direction == "up" then
		Detect = turtle.detectUp
	elseif direction == "down" then
		Detect = turtle.detectDown
	end
	if Detect() then
		blockName, blockModifier = clsTurtle.getBlockType(self, direction)
	end
	if clsTurtle.isVegetation(self, blockName) then
		return true
	end
	return false
end

function clsTurtle.isEmpty(self)
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			return false
		end
	end
	return true
end

function clsTurtle.isVegetation(self, blockName)
	blockName = blockName or ""
	for _, v in pairs(flowers) do
		if blockName == v then
			return true
		end
	end
	
	return false
end

function clsTurtle.isWater(self, direction)
	direction = direction or "forward"
	local isWater = false
	local isSource = false
	if not clsTurtle.detect(self, direction) then --air, water or lava
		local block, blockType, data = clsTurtle.getBlockType(self, direction)
		if block:find("water") ~= nil or block == "minecraft:bubble_column" or block:find("ice") ~= nil then -- allows for bubble_column
			isWater = true
			if block == "minecraft:bubble_column" then
				isSource = true
			end
			if block:find("ice") ~= nil then
				isSource = true
				isIce = true
			end
			if data.state.level ~= nil then
				if data.state.level == 0 then
					isSource = true
				end
			end
		end
	end
	return isWater, isSource, isIce
end

function clsTurtle.isWaterOrLava(self, direction)
	direction = direction or "forward"
	local blockType = ""
	local blockModifier = -1
	if not clsTurtle.detect(self, direction) then --air, water or lava
		blockType, blockModifier = clsTurtle.getBlockType(self, direction)
		if blockType:find("lava") ~= nil then 
			clsTurtle.place(self, "minecraft:bucket", -1, direction, false) -- auto refuel
		end
	end
	return blockType, blockModifier -- "" or 'minecraft:xxxx"
end

function clsTurtle.menu(self, title, list)
	local retValue = 0
	response = true
	while response do
		response = false
		clsTurtle.clear(self)
		print(title.."\n")
		for i = 1, #list, 1 do
			print("\t"..i..".  "..list[i])
		end
		print("Type number of your choice (1 to "..#list..")_")
		event, param1 = os.pullEvent ("char")
		local choice = tonumber(param1)
		if choice ~= nil then -- number typed
			if choice >= 1 or choice <= #list then
				retValue = choice
			end
		else
			print()
			print("Incorrect input: "..param1)
			print()
			print("Type numbers only, from 1 to "..#list)
			sleep(2)
			response = true
		end
	end
	return retValue -- 1 to no of items in the list
end

function clsTurtle.place(self, blockType, damageNo, direction, leaveExisting, signText)
	if leaveExisting == nil then
		leaveExisting = true
	end
	signText = signText or ""
	local success = false
	local doContinue = true
	local slot
	local dig = true
	-- assign place methods according to direction
	local Place = turtle.place
	if direction == "up" then
		Place = turtle.placeUp
	elseif direction == "down" then
		Place = turtle.placeDown
	end
	if blockType == "minecraft:bucket" then -- empty bucket for lava or water
		slot = clsTurtle.getItemSlot(self, blockType, damageNo)
		if slot > 0 then
			turtle.select(slot)
			if Place() then -- lava or water collected
				if clsTurtle.getSlotContains(self, slot) == "minecraft:lava_bucket" then
					clsTurtle.refuel(self, 0)
				end
				success = true
			end
		end
	else
		if blockType == "" then --use any
			blockType = "common"
			slot = turtle.getSelectedSlot()
			if  clsTurtle.getItemName(self, i) == "minecraft:sand" or clsTurtle.getItemName(self, i) == "minecraft:gravel" then
				for i = 1, 16 do
					if turtle.getItemCount(i) > 0 then
						local name = clsTurtle.getItemName(self, i)
						if  name ~= "minecraft:sand" and name ~= "minecraft:gravel" then
							slot = i
							break
						end
					end
				end
			end
		else
			slot = clsTurtle.getItemSlot(self, blockType, damageNo)
		end
		local existingBlock, modifier = clsTurtle.getBlockType(self, direction)
		if leaveExisting then -- do not remove existing block unless sand gravel water or lava
			-- check if water / lava
			if clsTurtle.detect(self, direction) then -- not water or lava
				if blockType == "" then -- place any block
					if existingBlock ~= "minecraft:sand" and existingBlock ~= "minecraft:gravel" then --leave anything except sand/gravel		
						doContinue = false
						success = true
					end
				else --place specific block
					-- ignore dirt, grass, stone, cobble
					if  existingBlock == "minecraft:dirt" or
						existingBlock == "minecraft:stone" or
						existingBlock == "minecraft:cobblestone" or
						existingBlock == "minecraft:grass_block" or
						existingBlock == "minecraft:granite" or
						existingBlock == "minecraft:diorite" or
						existingBlock == "minecraft:andesite" or
						existingBlock == "minecraft:netherrack" or
						existingBlock == "minecraft:end_stone" or
						existingBlock == "minecraft:tuff" or
						existingBlock == "minecraft:deepslate" or
						existingBlock == "minecraft:cobbled_deepslate" or
						existingBlock == "minecraft:basalt" or
						existingBlock:find("turtle") ~= nil then			
						doContinue = false
						success = true
					end
				end
			end		
		end
		if doContinue then -- water or lava in next block or leaveExisting = false
			while clsTurtle.dig(self, direction) do
				sleep(0.5)
			end
			if slot > 0 then
				turtle.select(slot)
				if Place(signText) then
					success = true
				else
					if blockType == "" then
						local done = false
						while not done do
							for i = 1, 16 do
								if turtle.getItemCount(i) > 0 then
									local itemName = clsTurtle.getItemName(self, i)
									if  itemName ~= "minecraft:sand" and itemName ~= "minecraft:gravel" then
										turtle.select(i)
										if Place then
											done = true
											success = true
											break
										end
									end
								end
							end
							if not done then
								print("Out of blocks to place")
								sleep(10)
							end
						end
					else
						if clsTurtle.attack(self, direction) then
							Place()
						else
							print("Error placing "..blockType.." ? chest or minecart below")
							--clsTurtle.saveToLog("Error placing "..blockType.." ? chest or minecart below")
						end
					end
				end
			end
		end
	end
	return success, slot
end

function clsTurtle.refuel(self, minLevel, toLimitOnly)	
	minLevel = minLevel or 15
	if toLimitOnly == nil then
		toLimitOnly = false
	end
	if minLevel == 0 then
		toLimitOnly = true
	end
	local itemSlot = 0
	local slot = turtle.getSelectedSlot()
	local count = 0
	local item = ""
	local damage = 0
	local refuelOK = false
	
	if turtle.getFuelLevel() >= minLevel and minLevel > 0 then -- prevent auto refuel eg fell tree
		return false
	end

	if turtle.getFuelLevel() >= turtle.getFuelLimit() and toLimitOnly then
		return false
	else
		if turtle.getFuelLevel() < minLevel or minLevel == 0 then
			-- check each slot for fuel item
			for i = 1, 16 do
				item, count, damage = clsTurtle.getSlotContains(self, i)
				if item == "minecraft:lava_bucket" then
					turtle.select(i)
					if turtle.refuel() then
						print("refuelled with lava: "..turtle.getFuelLevel().." / "..turtle.getFuelLimit())
						refuelOK = true
						break
					else
						print("lava block deleted: "..turtle.getFuelLevel().." / "..turtle.getFuelLimit())
						refuelOK = true
						break
					end
				end
				if item == "minecraft:coal" then
					turtle.select(i)
					if turtle.refuel(1) then
						while turtle.getFuelLevel() < minLevel and turtle.getItemCount(i) > 0 do
							turtle.refuel(1)
						end
						print("refuelled with coal: "..turtle.getFuelLevel())
						refuelOK = true
					end
				end
			end
			if not refuelOK then
				for i = 1, 16 do
					item, count, damage = clsTurtle.getSlotContains(self, i)
					if string.find(item, "planks") ~= nil then
						turtle.select(i)
						if turtle.refuel() then
							print("refuelled with planks: "..turtle.getFuelLevel())
							refuelOK = true
						end
					end
				end
			end
			if not refuelOK then
				local success = false
				for i = 1, 16 do
					item, count, damage = clsTurtle.getSlotContains(self, i)
					if string.find(item, "log") ~= nil then --logs onboard
						print("Refuelling with log slot "..tostring(i)..", crafting planks")
						if clsTurtle.craft(self, "planks", 4) then
							success = true
						else
							print("refuel() error crafting planks")
						end
						if success then
							local planksSlot, damage, count = clsTurtle.getItemSlot(self, "planks", -1)
							turtle.select(planksSlot)
							if turtle.refuel() then
								refuelOK = true
							end
						end
					end
				end
			end
			if not refuelOK and turtle.getFuelLevel() == 0 then
				term.clear()
				term.setCursorPos(1,1)
				print("Unable to refuel: "..turtle.getFuelLevel().." fuel remaining")
				--checkInventoryForItem(self, items, quantities, required, message)
				local result = clsTurtle.checkInventoryForItem(self, {"minecraft:lava_bucket", "coal", "planks"}, {1, 10, 32}, false) -- false allows user to press enter
				if result == nil then
					return false
				end
			end
		end
		turtle.select(slot)
		
		return refuelOK
	end
end

function clsTurtle.selectPlaceItem(self, item, useDamage)
	local success = false
	clsTurtle.getItemSlot(self, item, useDamage)
	if self.placeSlot > 0 then
		self.placeItem = item
	end
end

function clsTurtle.setEquipment(self)
	-- if contains a crafting table, puts it on the right. Any other tool on the left
	clsTurtle.clear(self)
	print("Setting up equipment...")
	local emptySlotR = clsTurtle.getFirstEmptySlot(self) -- first empty slot
	if emptySlotR == 0 then -- all slots full
		turtle.select(16)
		turtle.drop()
		emptySlotR = 16
	end
	local emptySlotL = 0 -- used later
	local eqRight = "" 
	local eqLeft = ""
	local equippedRight = "" 
	local equippedLeft = ""
	local count = 0
	local damage = 0
	local pickaxeSlot, damage, total = clsTurtle.getItemSlot(self, "minecraft:diamond_pickaxe", -1)
	local swordSlot, damage, total = clsTurtle.getItemSlot(self, "minecraft:diamond_sword", -1)
	local hoeSlot, damage, total = clsTurtle.getItemSlot(self, "minecraft:diamond_hoe", -1)
	local craftTableSlot, damage, total = clsTurtle.getItemSlot(self, "minecraft:crafting_table", -1)
	if emptySlotR > 0 then -- empty slot found
		turtle.select(emptySlotR)
		if turtle.equipRight() then -- remove tool on the right
			eqRight, count, damage = clsTurtle.getSlotContains(self, emptySlotR) -- eqRight contains name of tool from right side
			if eqRight == "minecraft:crafting_table" then
				craftTableSlot = emptySlotR
				eqRight = "" 
			elseif eqRight == "minecraft:diamond_pickaxe" then
				pickaxeSlot = emptySlotR
				eqRight = "" 
			elseif eqRight == "minecraft:diamond_sword" then
				swordSlot = emptySlotR
				eqRight = "" 
			elseif eqRight == "minecraft:diamond_hoe" then
				hoeSlot = emptySlotR
				eqRight = "" 
			end -- eqRight 
			emptySlotL = clsTurtle.getFirstEmptySlot(self) -- get next empty slot
			if emptySlotL == 0 then -- all slots full
				if emptySlotR ~= 15 then
					turtle.select(15)
					turtle.drop()
					emptySlotL = 15
				else
					turtle.select(16)
					turtle.drop()
					emptySlotL = 16
				end
			end
		else -- nothing equipped on right side
			emptySlotL = emptySlotR
		end
		if emptySlotL > 0 then -- empty slot found
			turtle.select(emptySlotL)
			if turtle.equipLeft() then -- remove tool on the left
				eqLeft, count, damage = clsTurtle.getSlotContains(self, emptySlotL) -- eqLeft contains name of tool from left side
				if eqLeft == "minecraft:diamond_pickaxe" then
					pickaxeSlot = emptySlotL
					eqLeft = "" 
				elseif eqLeft == "minecraft:diamond_sword" then
					swordSlot = emptySlotL
					eqLeft = ""
				elseif eqLeft == "minecraft:diamond_hoe" then
					hoeSlot = emptySlotL
					eqLeft = ""
				elseif eqLeft == "minecraft:crafting_table" then
					craftTableSlot = emptySlotL
					eqLeft = ""
				end
			end
		end
		if pickaxeSlot > 0 then
			turtle.select(pickaxeSlot)
			turtle.equipLeft()
			equippedLeft = "minecraft:diamond_pickaxe"	
			self.equippedLeft = "minecraft:diamond_pickaxe"
		end
		if craftTableSlot > 0 then
			turtle.select(craftTableSlot)
			turtle.equipRight()
			equippedRight = "minecraft:crafting_table"
			self.equippedRight = "minecraft:crafting_table"
		end
		inInventory = ""
		if swordSlot > 0 then
			inInventory = "minecraft:diamond_sword"
		elseif hoeSlot > 0 then
			inInventory = "minecraft:diamond_hoe"
		end
	end
	-- any tools equipped except diamond_pickaxe and crafting_table have been removed to inventory
	return equippedRight, equippedLeft, inInventory
end
	
function clsTurtle.sortInventory(self)
	local lib = {}
	
	function lib.checkForStorage(self)
		local direction = ""
		local blockType = clsTurtle.getBlockType(self, "forward")
		if blockType:find("barrel") ~= nil or blockType:find("chest") ~= nil then
			return "forward"
		end
		blockType = clsTurtle.getBlockType(self, "up")
		if blockType:find("barrel") ~= nil or blockType:find("chest") ~= nil then
			return "up"
		end
		blockType = clsTurtle.getBlockType(self, "down")
		if blockType:find("barrel") ~= nil or blockType:find("chest") ~= nil then
			return "down"
		end
	end
	
	function lib.chestSort(self, chestDirection)
		for i = 1, 16 do	-- fill chest with everything
			clsTurtle.drop(self, chestDirection, i)
		end
		local success, msg
		repeat
			success, msg = clsTurtle.suck(self, chestDirection)
		until not success
		--while clsTurtle.suck(self, chestDirection) do end -- remove everything
	end
	
	local chestSlot = clsTurtle.getItemSlot(self, "minecraft:chest", -1) --get the slot number containing a chest
	if chestSlot == 0 then
		chestSlot = clsTurtle.getItemSlot(self, "minecraft:barrel", -1) --get the slot number containing a barrel
	end
	local blockType
	local facing = self.facing
	local chestPlaced = false
	local chestDirection, turns = "", 0
	if chestSlot > 0 then -- chest found
		local chestDirection, turns = clsTurtle.getPlaceChestDirection(self)	-- find empty block to place it.
		for i = 1, 10 do	-- attempt to place chest 10x
			if clsTurtle.place(self, "minecraft:chest", -1, chestDirection) then
				chestPlaced = true
				break
			elseif clsTurtle.place(self, "minecraft:barrel", -1, chestDirection) then
				chestPlaced = true
				break
			else
				clsTurtle.attack(self, chestDirection) -- will force wait for mob
			end
		end
		if chestPlaced then
			lib.chestSort(self, chestDirection)
			--while clsTurtle.suck(self, chestDirection) do end -- remove everything
			clsTurtle.dig(self, chestDirection, false) -- collect chest (false = do not bypass chest)
		end
		if turns > 0 then	--return to original position
			clsTurtle.turnLeft(self, turns)
		end
	else
		chestDirection = lib.checkForStorage(self)
		chestPlaced = true
		if chestDirection ~= "" then
			lib.chestSort(self, chestDirection)
		end
	end
	if not chestPlaced then	-- no chest or unable to place it
		for x = 1, 15 do -- sort inventory
			for i = x + 1 , 16 do
				if turtle.getItemCount(i) > 0 then
					turtle.select(i)
					if turtle.compareTo(x) then
						turtle.transferTo(x)
					end
				end
			end
		end
		for  x = 1, 15 do
			if turtle.getItemCount(x) == 0 then -- slot empty, move from next available filled slot
				for i = x + 1, 16 do
					if turtle.getItemCount(i) > 0 then
						turtle.select(i)
						turtle.transferTo(x)
						break
					end
				end
			end
		end
	end
	turtle.select(1)
end

function clsTurtle.suck(self, direction, slot, quantity)
	slot = slot or 1
	direction = direction or "forward"
	-- success, msg = turtle.suck()
	-- success = true / false
	-- msg = "No space for items" / nil
	
	turtle.select(slot)
	local Suck = turtle.suck
	if direction == "up" then
		Suck = turtle.suckUp
	elseif direction == "down" then
		Suck = turtle.suckDown
	end
	local success, msg
	if quantity == nil then
		success, msg = Suck()
	else
		success, msg = Suck(quantity)
	end
	return success, msg
end

function clsTurtle.trimItemName(self, item)
	itemName = item
	colonPos = item:find(":")
	if colonPos ~= nil then
		itemName = item:sub(colonPos + 1)
	end
	
	return itemName
end

function clsTurtle.writeCoords(self, filename)
	-- create/append e.g 'SpawnerCoords.txt'
	local fileHandle = fs.open(filename, "a")
	fileHandle.writeLine("x="..self.x)
	fileHandle.writeLine("y="..self.y)
	fileHandle.writeLine("z="..self.z)
	fileHandle.writeLine("f="..self.facing)
	fileHandle.close()
	clsTurtle.saveToLog(self, filename.." file created", true)
	clsTurtle.saveToLog(self, "x = "..clsTurtle.getX(self)..", y = "..clsTurtle.getY(self)..", z = "..clsTurtle.getZ(self)..", f = "..clsTurtle.getFacing(self), false)
end

doLog = clsTurtle.saveToLog --shortcut for logging within this class. usage: doLog(self, string<text>, bool<toScreen=true>) ex: doLog(self, "This message also shows on terminal", true)
return clsTurtle