version = 20250410.2240
--[[
	https://pastebin.com/tvfj90gK
	Last edited: see version YYYYMMDD.HHMM
	save as T.lua, preferably in /lib folder
	as is not meant to be run directly from CraftOS command line
	usage:
	T = require("lib/T").new()
	T:clear()
	T:forward(2)
	To use logging 
	T = require("lib.T"):new(true) -- true enables logfile to log.txt
	
	Computercraft started with mc version 1.7.10 and went to 1.8.9
	ccTweaked started around mc 1.12 and currently at 1.21.1
	mc 1.18 has new blocks and bedrock at -64, so needs to be taken into account.
	_HOST = The ComputerCraft and Minecraft version of the current computer environment.
	For example, ComputerCraft 1.93.0 (Minecraft 1.15.2).
	
	This version no longer uses the 'damage' property found in older versions.
]]

local g = 0.3 -- time for gravity to work on sand/gravel
local bedrock = 0
local ceiling = 255
local deletesWater = false
local mcMajorVersion = tonumber(_HOST:sub(_HOST:find("Minecraft") + 10, _HOST:find("\)") - 1)) -- eg 1.18 or 1.20 -> 1.18, 1.20

function string:Split(sSeparator, nMax, bRegexp, noEmpty)
	--[[return a table split with sSeparator. noEmpty removes empty elements
		use: tblSplit = SplitTest:Split('~',[nil], [nil], false) or tblSplit = string.Split(SplitTest, '~')]]   
	assert(sSeparator ~= '','separator must not be empty string')
	assert(nMax == nil or nMax >= 1, 'nMax must be >= 1 and not nil')
	if noEmpty == nil then noEmpty = true end

	local aRecord = {}
	local newRecord = {}

	if self:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1

		local nField, nStart = 1, 1
		local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = self:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = self:find(sSeparator, nStart, bPlain)
			nMax = nMax-1
		end
		aRecord[nField] = self:sub(nStart)
		
		if noEmpty then --split on newline preserves empty values
			for i = 1, #aRecord do
				if aRecord[i] ~= "" then
					table.insert(newRecord, aRecord[i])
				end
			end
		else
			newRecord = aRecord
		end
	end
	
	return newRecord
end

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
				"minecraft:mossy_cobblestone",
				"minecraft:netherrack",
				"minecraft:blackstone",
				"minecraft:gilded_blackstone",
				"minecraft:polished_blackstone",
				"minecraft:polished_blackstone_bricks",
				"minecraft:cracked_polished_blackstone_bricks",
				"minecraft:chiseled_polished_blackstone",
				"minecraft:basalt",
				"minecraft:deepslate",
				"minecraft:cobbled_deepslate",
				"minecraft:chiseled_deepslate",
				"minecraft:polished_deepslate",
				"minecraft:deepslate_bricks",
				"minecraft:cracked_deepslate_bricks",
				"minecraft:deepslate_tiles",
				"minecraft:cracked_deepslate_tiles",
				"minecraft:tuff",
				"minecraft:tuff_bricks",
				"minecraft:polished_tuff",
				"minecraft:chiseled_tuff",
				"minecraft:chiseled_tuff_bricks",
				"minecraft:granite",
				"minecraft:diorite",
				"minecraft:andesite",
				"minecraft:end_stone",
				"minecraft:obsidian",
				"minecraft:stone",
				"minecraft:smooth_stone",
				"minecraft:stone_bricks",
				"minecraft:cracked_stone_bricks",
				"minecraft:chiseled_stone_bricks",
				"minecraft:mossy_stone_bricks",
				"minecraft:sandstone",
				"minecraft:smooth_sandstone",
				"minecraft:chiseled_sandstone",
				"minecraft:cut_sandstone",
				"minecraft:red_sandstone",
				"minecraft:smooth_red_sandstone",
				"minecraft:chiseled_red_sandstone",
				"minecraft:cut_red_sandstone",
				"minecraft:obsidian",
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
	"minecraft:wet_sponge"
}

local maSeeds = {
	"mysticalagriculture:prosperity_seed_base",
	"mysticalagriculture:soulium_seed_base",
	"mysticalagriculture:air_seeds",
	"mysticalagriculture:earth_seeds",
	"mysticalagriculture:water_seeds",
	"mysticalagriculture:fire_seeds",
	"mysticalagriculture:inferium_seeds",
	"mysticalagriculture:stone_seeds",
	"mysticalagriculture:dirt_seeds",
	"mysticalagriculture:wood_seeds",
	"mysticalagriculture:ice_seeds",
	"mysticalagriculture:deepslate_seeds",
	"mysticalagriculture:nature_seeds",
	"mysticalagriculture:dye_seeds",
	"mysticalagriculture:nether_seeds",
	"mysticalagriculture:coal_seeds",
	"mysticalagriculture:coral_seeds",
	"mysticalagriculture:honey_seeds",
	"mysticalagriculture:amethyst_seeds",
	"mysticalagriculture:pig_seeds",
	"mysticalagriculture:chicken_seeds",
	"mysticalagriculture:cow_seeds",
	"mysticalagriculture:sheep_seeds",
	"mysticalagriculture:squid_seeds",
	"mysticalagriculture:fish_seeds",
	"mysticalagriculture:slime_seeds",
	"mysticalagriculture:turtle_seeds",
	"mysticalagriculture:armadillo_seeds",
	"mysticalagriculture:rubber_seeds",
	"mysticalagriculture:silicon_seeds",
	"mysticalagriculture:sulfur_seeds",
	"mysticalagriculture:aluminum_seeds",
	"mysticalagriculture:saltpeter_seeds",
	"mysticalagriculture:apatite_seeds",
	"mysticalagriculture:iron_seeds",
	"mysticalagriculture:copper_seeds",
	"mysticalagriculture:nether_quartz_seeds",
	"mysticalagriculture:glowstone_seeds",
	"mysticalagriculture:redstone_seeds",
	"mysticalagriculture:obsidian_seeds",
	"mysticalagriculture:prismarine_seeds",
	"mysticalagriculture:zombie_seeds",
	"mysticalagriculture:skeleton_seeds",
	"mysticalagriculture:spider_seeds",
	"mysticalagriculture:creeper_seeds",
	"mysticalagriculture:rabbit_seeds",
	"mysticalagriculture:tin_seeds",
	"mysticalagriculture:bronze_seeds",
	"mysticalagriculture:zinc_seeds",
	"mysticalagriculture:brass_seeds",
	"mysticalagriculture:silver_seeds",
	"mysticalagriculture:lead_seeds",
	"mysticalagriculture:graphite_seeds",
	"mysticalagriculture:gold_seeds",
	"mysticalagriculture:lapis_lazuli_seeds",
	"mysticalagriculture:end_seeds",
	"mysticalagriculture:experience_seeds",
	"mysticalagriculture:breeze_seeds",
	"mysticalagriculture:blaze_seeds",
	"mysticalagriculture:ghast_seeds",
	"mysticalagriculture:enderman_seeds",
	"mysticalagriculture:steel_seeds",
	"mysticalagriculture:nickel_seeds",
	"mysticalagriculture:constantum_seeds",
	"mysticalagriculture:electrum_seeds",
	"mysticalagriculture:invar_seeds",
	"mysticalagriculture:uranium_seeds",
	"mysticalagriculture:ruby_seeds",
	"mysticalagriculture:sapphire_seeds",
	"mysticalagriculture:peridot_seeds",
	"mysticalagriculture:soulium_seeds",
	"mysticalagriculture:diamond_seeds",
	"mysticalagriculture:emerald_seeds",
	"mysticalagriculture:netherite_seeds",
	"mysticalagriculture:wither_skeleton_seeds",
	"mysticalagriculture:platinum_seeds",
	"mysticalagriculture:iridium_seeds",
	"mysticalagriculture:nether_star_seeds",
	"mysticalagriculture:dragon_egg_seeds"
}
			  
local T = {}
T.__index = T

setmetatable(T,
{
	__call = function (cls, ...)
    return cls.new(...)
	end,
})
-- if you want to pass arguments at construction...
function T.new(useLog) --note dot, NOT colon, list of args or ... table
	local self = setmetatable({}, T)
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
function T:values(t) -- general diy iterator
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
	extensive use for debugging has been left in the function T.checkInventoryForItem() as this was a nightmare to get working
]]
function T:getUseLog()
	return self.useLog
end
function T:setUseLog(use, filename, delete)
	self.logFileName = filename or "log.txt"
	if delete ~= nil then
		if delete then
			self:deleteLog()
		end
	end
	self.useLog = use
	return use
end
function T:getLogExists()
	local exists = false
	if fs.exists(self.logFileName) then
		exists = true
	end
	return exists
end
function T:getLogFileName()
	return self.logFileName
end
function T:setLogFileName(value)
	self.logFileName = value
end
function T:getCurrentFileSize()		
	if self.logFileExists then
		return fs.getSize(self.logFileName)
	else
		return 0
	end
end
function T:deleteLog()		
	if fs.exists(self.logFileName) then
		fs.delete(self.logFileName)
	end
	self.logFileExists = false
	
	return true
end
function T:appendLine(newText)
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
function T:saveToLog(text, toScreen)
	if toScreen == nil then
		toScreen = true
	end
	if text ~= "" and text ~= nil then
		if toScreen then
			print(text)
		end
		if self.useLog then
			self:appendLine(text)
			return true
		end
	end
	return false
end
-- getters and setters
function T:getValue() return self.value end --debug test for object creation with args
function T:getX() return self.x end
function T:setX(newVal) self.x = newVal end
function T:getY() return self.y end
function T:setY(newVal) self.y = newVal end
function T:getZ() return self.z end
function T:setZ(newVal) self.z = newVal end
function T:getFacing() return self.facing end
function T:setFacing(newVal)
	local direction = {"south", "west", "north", "east"}
	self.facing = newVal
	if self.facing < 0 then
		self.facing = 3
	elseif self.facing > 3 then
		self.facing = 0
	end
	self.compass = direction[self.facing + 1] --+1 to allow for lua indexing at 1
end
function T:getCompass() return self.compass end
function T:getPlaceItem() return self.placeItem end
function T:setPlaceItem(item)
	local success = false
	local slot = self:getItemSlot(item)
	if slot > 0 then
		self.placeItem = item
	end
end
function T:setEquipped(side, value)
	if side == "left" then
		self.equippedLeft = value
	elseif side == "right" then
		self.equippedRight = value
	end
end
function T:getUserBlocks()
	-- self.userBlocks[1] = {string<name>, string<item>, int<count>, bool<userChoice>}
	return self.userBlocks
end
function T:getUserBlockType(name)
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
function T:addUserBlocks(blockTable)
	table.insert(self.userBlocks, blockTable)
end
function T:getMASeeds()
	-- return list of Mystical Agriculture seeds
	return maSeeds
end
-- change direction and movement methods
function T:attack(direction)	
	direction = direction or "all"
	turtle.select(1)
	local success = false
	local attackLimit = 30 -- won't get in infinite loop attacking a minecart chest
	local Attack
	local up, down, forward = true, true, true
	if direction == "up" then
		Attack = turtle.attackUp
	elseif direction == "down" then
		Attack = turtle.attackDown
	elseif direction == "forward" then
		Attack = turtle.attack
	end
	if direction == "all" then
		while up or down or forward do
			forward = turtle.attack()
			up = turtle.attackUp()
			down = turtle.attackDown()
			if up or down or forward then -- attack in at least 1 direction succeeeded
				sleep(0.5)
			end
			attackLimit = attackLimit - 1
			if attackLimit <= 0 then
				break
			end
		end
	else
		while Attack() do --in case mob around
			sleep(0.5)
			attackLimit = attackLimit - 1
			if attackLimit <= 0 then
				break
			end			
		end
	end

	if attackLimit > 0 then
		success = true
	end
	return success
end

function T:doMoves(numBlocksRequested, direction)
	local errorMsg = nil
	local numBlocksMoved = 0
	local Move, Dig, Detect
	local bypass = false
	local bypassCount = 0
	local blockType
	numBlocksRequested = numBlocksRequested or 1
	self:refuel(steps)
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
		self:turnRight(2)
	end
	if numBlocksRequested == 0 then
		return 0
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
				blockType, bypass = self:checkNoDigBlocks(direction)
				if bypass then --moved round bedrock, spawner, turtle or full chest
					digOK, digError = Dig()
					if digOK then
						sleep(g) -- allow sand / gravel to drop if digging forward / up
					else -- unable to dig, or nothing to dig
						if digError:lower():find("unbreakable") ~= nil then -- different messages between versions all contain 'unbreakable'
							errorMsg = digError
							print(digError)
							break
						else -- not bedrock, could be mob or minecart
							self:attack()
						end
					end
				end 
			end
			if not bypass then
				local moveOK, moveError = Move() -- try to move forward/up/down
				if moveOK then
					numBlocksMoved = numBlocksMoved + 1
					self:changeCoords(direction)
				else
					while not moveOK do -- did not move if obstruction
						digOK, digError = Dig()
						if digOK then
							sleep(g) -- allow sand / gravel to drop if digging forward / up
						else -- unable to dig, or nothing to dig
							if digError:lower():find("unbreakable") ~= nil then -- different messages between versions all contain 'unbreakable'
								errorMsg = digError
								print(digError)
								break
							else -- not bedrock, could be mob or minecart
								self:attack()
							end
						end
						moveOK, moveError = Move() -- try to move forward/up/down again
						if moveOK then
							numBlocksMoved = numBlocksMoved + 1
							self:changeCoords(direction)
						end
					end
				end
			end
		end
	end
	
	if direction == "back" then
		self:turnRight(2)
	end
	
	return numBlocksMoved, errorMsg
end

function T:back(steps)
	steps = steps or 1
	local success = false
	local blocksMoved, errorMsg = self:doMoves(steps, "back")
	if blocksMoved == steps then
		success = true
	end
	return success, blocksMoved, errorMsg
end

function T:changeCoords(direction)
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

function T:down(steps, getBlock)
	steps = steps or 1
	if steps == 0 then 
		return true, 0, "", ""
	end
	if getBlock == nil then getBlock = false end
	local success = false
	local blockType = nil
	local blocksMoved, errorMsg = self:doMoves(steps, "down")
	if blocksMoved == steps then
		success = true
	end
	if getBlock then
		blockType = self:getBlockType("down")
	end
	return success, blocksMoved, errorMsg, blockType
end

function T:forward(steps)    
	steps = steps or 1
	local success = false
	local blocksMoved, errorMsg = self:doMoves(steps, "forward")
	if blocksMoved == steps then
		success = true
	end
	return success, blocksMoved, errorMsg
end

function T:turnLeft(steps)
	steps = steps or 1
	for i = 1, steps do
		turtle.turnLeft()
		self.facing = self.facing - 1
		if self.facing < 0 then
			self.facing = 3
		end
	end
end

function T:turnRight(steps)
	steps = steps or 1
	for i = 1, steps do
		turtle.turnRight()
		self.facing = self.facing + 1
		if self.facing > 3 then
			self.facing = 0
		end
	end
end

function T:up(steps)
	steps = steps or 1
	if steps == 0 then 
		return true, 0, ""
	end
	local success = false
	local blocksMoved, errorMsg = self:doMoves(steps, "up")
	if blocksMoved == steps then
		success = true
	end
	return success, blocksMoved, errorMsg
end
-- other methods
function T:checkInventoryForItem(items, quantities, required, message)
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
	
	--[[
	function lib.getInventory(self)
		-- table eg: {"minecraft:cobblestone" = 256, "minecraft:cobbled_deepslate = 256"} 
		local inventory = {}
		for slot = 1, 16 do
			local slotContains, slotCount = self:getSlotContains(slot)
			if slotContains ~= "" then -- eg "minecraft:cobblestone"
				if inventory[slotContains] ~= nil then --already exists in inventory
					inventory[slotContains] = inventory[slotContains] + slotCount --update quantities
				else
					inventory[slotContains] = slotCount
				end
			end
		end
		return inventory
	end]]
		
	if required == nil then required = true end
	if message == nil then message = "" end 	-- add further instructions
	--local inventory = lib.getInventory(self) 	-- create table of blocktypes and quantities
	local inventory = self:getInventoryItems() 	-- create table of blocktypes and quantities
	local inventoryChanged = false
	local enteringLoop = true
	local waiting = true
	local quantitiesFound = {}
	while waiting do -- true on first entry, also enteringLoop = true check slots and inventory in waiting loop to see if new items are added
		--T.clear(self)
		if inventoryChanged or enteringLoop then
			self:clear()
			enteringLoop = false --flag reset loop has iterated at least once
			inventoryChanged = false
			waiting, quantitiesFound = lib.checkInventory(self, items, quantities, inventory) -- are we still waiting, table of found quantities
			if waiting then --insufficient items so ask for more
				if message ~= "" then
					print(message)
				end
				if quantitiesFound[1] < quantities[1] then
					print("Add "..quantities[1] - quantitiesFound[1].." "..self:trimItemName(items[1]).." to any slot(s)")
					for i = 2, #items do
						print("Or add "..quantities[i] - quantitiesFound[i].." "..self:trimItemName(items[i]).." to any slot(s)")
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
				--inventory = lib.getInventory(self)
				inventory = self:getInventoryItems()
			--elseif event == "key"  and not required then
			elseif event == "key" then
				if param1 == keys.enter then
					self:clear()
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

function T:checkNoDigBlocks(direction, moveRound) 
	if moveRound == nil then
		moveRound = false
	end
	local bypass = false
	local isSpawner = false
	local blockType = self:getBlockType(direction)
	-- if mob spawner or chest found, go round it. Do not break!
	if blockType ~= "" then
		if blockType:find("spawner") ~= nil then
			self:writeCoords("SpawnerCoords.txt")
			bypass = true
			isSpawner = true
			print("Spawner Found!")
		elseif blockType:find("turtle") ~= nil then --do not break another turtle
			bypass = true
		elseif blockType:find("chest") ~= nil or blockType:find("minecart") ~= nil then
			local success, msg
			repeat
				success, msg = self:suck(direction)
			until not success
			if self:getFirstEmptySlot() == 0 then -- turtle is full
				bypass = true
			else
				self:dig(direction)
			end
		end
	end
	if bypass and (moveRound or isSpawner)  then
		if direction == "up" then
			self:go("F1U2R2F1R2", false, 0, false, false)
		elseif direction == "forward" then
			self:go("U1F2D1", false, 0, false, false)
		elseif direction == "down" then
			self:go("F1D2R2F1R2", false, 0, false, false)
		end
	end
	return blockType, bypass -- bypass true should be used to reduce steps in calling routine
end

function T:clear()
	term.clear()
	term.setCursorPos(1,1)
end

function T:craft(item, quantity)	
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
	
	chestSlot = self:getItemSlot("chest") --get the slot number containing a chest
	if chestSlot == 0 then -- chest not found
		if item == "planks" then -- could be new turtle and tree felling
			sourceSlot = self:getItemSlot("log") --get the slot number containing log(s)	
			if sourceSlot > 0 then
				if turtle.craft() then
					return true, ""
				else
					return false, "Unable to craft planks"
				end
			end
		elseif item == "chest" then -- assume chest needed and logs are onboard
			sourceSlot = self:getItemSlot("log") --get the slot number containing log(s)	
			if sourceSlot > 0 then
				if turtle.craft() then-- craft logs into planks
					sourceSlot = self:getItemSlot("planks") --get the slot number containing planks
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
		elseif item == "slab" then -- assume 3 stone -> slab for mob spawner
			sourceSlot = self:getItemSlot("stone") --get the slot number containing stone
			if sourceSlot > 0 then
				turtle.select(sourceSlot)
				turtle.transferTo(16) --move crafting item to 16
				turtle.select(16)
				turtle.transferTo(1, 1)
				turtle.transferTo(2, 1)
				turtle.transferTo(3, 1)
				for i = 4, 16 do
					if turtle.getItemCount(i) > 0 then
						turtle.select(i)
						turtle.dropUp()
					end
				end
				if turtle.craft(1) then
					return true, ""
				else
					return false, "Unable to craft slab"
				end
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
		stock = self:getStock("stone", -1) --get the slot number containing stone
		sourceSlot = stock.mostSlot
		message = "No stone for crafting stairs"
	elseif item:find("chest") ~= nil then -- craft chest
		stock = self:getStock("planks", -1) --get the slot number containing planks
		sourceSlot = stock.mostSlot
		message = "No planks for crafting chest"
	elseif item:find("planks") ~= nil then -- craft planks
		stock = self:getStock("log", -1) --get the slot number containing logs
		sourceSlot = stock.mostSlot
		message = "No logs for crafting planks"
	end
	if sourceSlot == 0 then
		return false, message
	end
	while turtle.detect() do --check for clear space to place chest
		self:turnRight(1)
		turns = turns + 1
		if turns == 4 then
			turns = 0
			break
		end
	end
	turtle.select(1)
	while turtle.detect() do --clear space in front. Use loop in case of sand/gravel falling
		turtle.dig()
		sleep(g)
	end
	turtle.select(chestSlot) --should be slot with chest
	while not turtle.place() do
		self:attack()
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
		self:turnLeft(turns)
	end
	
	return craftOK, message
end

function T:createTunnel(length, allowAbandon)
	-- T.go(self, path, useTorch, torchInterval, leaveExisting)
	-- assume at floor level at start
	local leaveExisting = true
	local useTorch = false
	local distance  = 1
	local blockAbove = ""
	local blockBelow = ""
	local waterCountAbove = 0
	local waterCountBelow = 0
	local onGround = true
	for i = 1, length do
		if onGround then -- 1, 3, 5, 7 etc
			blockBelow = self:getBlockType("down")
			if blockBelow ~= "" then
				if blockBelow:find("lava") ~= nil then
					self:go("C2L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockBelow:find("water") ~= nil then
					self:go("C2", useTorch, 0, leaveExisting)
					waterCountBelow = waterCountBelow + 1
				else
					self:go("C2", useTorch, 0, leaveExisting)
				end
			else
				self:go("C2", useTorch, 0, leaveExisting)
			end
			self:up(1)
			onGround = false
			blockAbove = self:getBlockType("up")
			if blockAbove ~= "" then
				if blockAbove:find("lava") ~= nil then
					self:go("C0L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockAbove:find("water") ~= nil then
					self:go("C0L1C1R2C1L1", useTorch, 0, leaveExisting)
					waterCountAbove = waterCountAbove + 1
				else
					self:go("C0", useTorch, 0, leaveExisting)
				end
			else
				self:go("C0", useTorch, 0, leaveExisting)
			end
			-- if on first block check behind
			if i == 1 then
				self:go("R2C1R2", useTorch, 0, leaveExisting)
			end
			if distance >= 8 then
				if distance % 8 == 0 then -- 8th or other position
					self:go("t5", useTorch, 0, false)
				end
			end
		else -- at ceiling 2, 4, 6, 8 etc
			blockAbove = self:getBlockType("up")
			if blockAbove ~= "" then
				if blockAbove:find("lava") ~= nil then
					self:go("C0L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockAbove:find("water") ~= nil then
					self:go("C0L1C1R2C1L1", useTorch, 0, leaveExisting)
					waterCountAbove = waterCountAbove + 1
				else
					self:go("C0", useTorch, 0, leaveExisting)
				end
			else
				self:go("C0", useTorch, 0, leaveExisting)
			end
			if distance == 2 then
				self:go("t1", useTorch, 0, false)
			end
			self:down(1)
			onGround = true
			blockBelow = self:getBlockType("down")
			if blockBelow ~= "" then
				if blockBelow:find("lava") ~= nil then
					self:go("C2L1C1R2C1L1", useTorch, 0, leaveExisting)
				elseif blockBelow:find("water") ~= nil then
					self:go("C2", useTorch, 0, leaveExisting)
					waterCountBelow = waterCountBelow + 1
				else
					self:go("C2", useTorch, 0, leaveExisting)
				end
			else
				self:go("C2", useTorch, 0, leaveExisting)
			end
		end
		-- now move forward if length > 1
		if length > 1 then
			if i < length then -- not on last iteration
				self:forward(1)
				distance = distance + 1
			else -- on last iteration
				if not onGround then
					self:go("C1", useTorch, 0, leaveExisting)
					self:down(1)
					onGround = true
				end
			end
		else -- one unit only so move down
			self:down(1)
			onGround = true
		end
		
		if allowAbandon then
			if waterCountAbove + waterCountBelow >= 6 then
				if not onGround then
					self:down(1)
					onGround = true
				end
				break
			end
		end
	end
	
	return distance -- 1 to length. cut short if 3 or more water
end

function T:detect(direction)
	direction = direction or "forward"
	
	local Detect = turtle.detect
	if direction == "up" then
		Detect = turtle.detectUp
	elseif direction == "down" then
		Detect = turtle.detectDown
	end
	
	return Detect()
end

function T:dig(direction, bypass, slot)
	--[[ To dig a chest use T:dig(direction, false)  ]]
	direction = direction or "forward"
	bypass = bypass or true -- allows digging any block including chests and spawners
	slot = slot or 1
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
		blockType, bypass = self:checkNoDigBlocks(direction, false)
	end
	if not bypass then --bypass true if chest, turtle or minecart 
		while Dig() do
			sleep(g)
			success = true
		end
	end
	turtle.select(1)
	return success
end

function T:digGravityBlock(direction)
	local Dig = turtle.dig
	if direction == "up" then
		Dig = turtle.digUp
	elseif direction == "down" then
		Dig = turtle.digDown
	end
	local blockType = self:getBlockType(direction)
	turtle.select(1)
	if blockType:find("sand") ~= nil or blockType:find("gravel") ~= nil then
		Dig()
		return true
	else
		return false
	end

end

function T:digValuable(direction)
	local Dig = turtle.dig
	if direction == "up" then
		Dig = turtle.digUp
	elseif direction == "down" then
		Dig = turtle.digDown
	end
	local isValuable, blockType = self:isValuable(direction)
	if isValuable then
		Dig()
		return true
	else --check for lava
		if blockType:find("lava") ~= nil then
			self:place("minecraft:bucket", direction)  -- will automatically find empty bucket and refuel
			return true
		else
			return false
		end
	end
	turtle.select(1)
end

function T:drop(direction, slot, amount)
	direction = direction or "forward"
	if slot == nil then
		slot = 1
	elseif type(slot) == "string" then
		slot = self:getItemSlot(slot)
	end
	local success = false
	local drop = turtle.drop
	if direction == "up" then
		drop = turtle.dropUp
	elseif direction == "down" then
		drop = turtle.dropDown
	end
	if slot > 0 then
		turtle.select(slot)

		if amount == nil then
			success = drop()
		else
			success = drop(amount)
		end
	end
	turtle.select(1)
	return success
end

function T:dropAll(direction)
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
	turtle.select(1)
	return success
end

function T:dropItem(item, direction, keepAmount, except)
	--[[ eg T:dropItem("essence", direction, 0, {"inferium", "prudentium", "tertium","imperium", "supremium"})
		drop all MysticalAgriculture essences except those listed
	]]
	direction = direction or "forward"
	local itemSlot = 0
	local success = false
	self:saveToLog("T:dropItem("..item..","..direction..","..tostring(keepAmount)..")")
	if except ~= nil then -- drop everything except specified
		for slot = 1, 16 do
			local itemInSlot = self:getSlotContains(slot)	-- eg mysticalagriculture:inferium_essence
			if itemInSlot ~= "" then
				local keep = false
				if itemInSlot:find(item) ~= nil then		-- slot contains partial match
					for _, v in ipairs(except) do			-- {"inferium", "prudentium", "tertium","imperium", "supremium"}
						if itemInSlot:find(v) ~= nil then	-- eg inferium_essence
							keep = true
							break
						end
					end
					if not keep then				-- not an excluded item: drop it
						success = self:drop(direction, slot)
					end
				end
			end
		end
	elseif keepAmount == nil or keepAmount <= 0 then -- drop everything
		itemSlot = self:getItemSlot(item)
		while itemSlot > 0 do
			if not self:drop(direction, itemSlot) then
				return false
			end
			itemSlot = self:getItemSlot(item)
		end
	else -- keep a specific amount
		local _, total, stockData  = T:getItemSlot(item)	-- integer, integer, table
		self:saveToLog("\ttotal = "..total..", keepAmount = "..keepAmount)
		while total > keepAmount do
			if total - stockData.leastCount > keepAmount then
				success = self:drop(direction, stockData.leastSlot)
			else
				success = self:drop(direction, stockData.leastSlot, total - keepAmount)
			end
			self:saveToLog("\tsuccess = "..tostring(success))
			if not success then
				break
			end
			_, total, stockData  = T:getItemSlot(item)	-- integer, integer, table
			self:saveToLog("\ttotal = "..total)
		end
		self:saveToLog("T:dropItem completed")
	end
	turtle.select(1)
	return success
end

function T:dumpRefuse(direction, keepCobbleStacks)
	--dump dirt, cobble, sand, gravel
	local Drop = turtle.drop
	if direction == "up" then
		Drop = turtle.dropUp
	else
		Drop = turtle.dropDown
	end
	keepCobbleStacks = keepCobbleStacks or 0
	local itemlist = {"gravel", "stone", "sand", "flint"}
	local cobbleCount = 0

	for i = 1, 16 do
		local blockType, slotCount,  blockModifier = self:getSlotContains(i)
		
		if blockType:find("cobble") ~= nil or blockType:find("netherrack") then
			if cobbleCount > keepCobbleStacks then
				turtle.select(i)
				Drop()
			else
				cobbleCount = cobbleCount + 1
			end
		end
		for j = 1, #itemlist do
			if blockType:find(itemlist[j]) ~= nil then
				turtle.select(i)
				Drop()
				break
			end
		end
	end
	turtle.select(1)
end

function T:emptyInventory(direction)
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

function T:emptyInventorySelection(direction, exceptions, quantities)
	--[[ Dump everything except items in exceptions eg {"oak_sapling"}, {64} ]]
	self:sortInventory()
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

function T:emptyTrash(direction)
	self:saveToLog("T:emptyTrash")
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
	local keepItems = 	{"netherrack", "cobble", "chest", "torch", "ore", "bucket", "coal", "diamond", "debris", "deepslate","iron","gold","copper"}			
	local keepit = false					
	-- empty excess cobble, dirt, all gravel, unknown minerals
	for i = 1, 16 do
		keepit = false
		if turtle.getItemCount(i) > 0 then
			itemName = self:getItemName(i) -- eg 'minecraft:andesite'
			for _,v in pairs(keepItems) do
				if itemName:find(v) ~= nil then
					keepit = true
					break
				end
			end
			if not keepit then
				turtle.select(i)
				Drop()
				sleep(g)
			end
		end
	end
	self:dropItem("minecraft:cobblestone", direction, 192)
	self:dropItem("minecraft:netherrack", direction, 192)
	self:dropItem("minecraft:cobbled_deepslate", direction, 192)
	slotData = self:getStock("minecraft:coal", 0)
	if slotData.total > 64 then
		if slotData.mostSlot ~= slotData.leastSlot and slotData.leastSlot ~= 0 then
			turtle.select(slotData.leastSlot)
			turtle.refuel()
		end
	end
	self:saveToLog("T:emptyTrash sortInventory...")
	self:sortInventory(false)
	self:saveToLog("T:emptyTrash sortInventory completed")
	turtle.select(1)
end

function T:emptyTrashItem(direction, item, keepAmount)
	--[[ deprecated. left for legacy applications ]]
	self:dropItem(item, direction, keepAmount)
end

function T:equip(side, useItem)
	--slotData.leastSlot, slotData.leastModifier, total, slotData
	local slot = self:getItemSlot(useItem)
	local currentSlot = turtle.getSelectedSlot()
	local success = false
	--[[
	minecraft:crafting_table
	minecraft:diamond_pickaxe
	minecraft:diamond_sword
	minecraft:diamond_shovel
	minecraft:diamond_hoe
	minecraft:diamond_axe
	wireless modem = ComputerCraft:CC-Peripheral
	]]
	if slot > 0 then
		turtle.select(slot)
		if side == "right" then
			if turtle.equipRight() then
				success = true
				self.equippedRight = useItem
			end
		elseif side == "left" then
			if turtle.equipLeft() then
				success = true
				self.equippedLeft = useItem
			end
		end
	end
	turtle.select(currentSlot)
	
	return success
end

function T:unequip(side)
	local success = false
	local slot = self:getFirstEmptySlot()
	turtle.select(slot)
	if side == "right" then
		if turtle.equipRight() then
			success = true
			self.equippedRight = ""
		end
	else
		if turtle.equipLeft() then
			success = true
			self.equippedLeft = ""
		end
	end
	
	return success, slot
end

function T:fillVoid(direction, tblPreferredBlock, leaveExisting)
	assert(type(direction) == "string", "direction is not a string: "..tostring(direction))
	assert( tblPreferredBlock == nil or
			type(tblPreferredBlock) == "string" or
			type(tblPreferredBlock) == "table", "tblPreferredBlock is not nil, string or table: "..tostring(tblPreferredBlock))
	assert( leaveExisting == nil or type(leaveExisting) == "boolean", "leaveExisting is not boolean: "..tostring(leaveExisting))
	
	if tblPreferredBlock == nil or tblPreferredBlock == "" then tblPreferredBlock = {} end
	if type(tblPreferredBlock) ~= "table" then tblPreferredBlock = {tblPreferredBlock} end -- always use a table
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
	
	
	
	local lib = {}
	
	function lib.place(direction, placeBlock, currentBlock, slot)
		if placeBlock ~= currentBlock then -- current block does not match type to be used as filler
			turtle.select(slot)
			Dig()
			local attempts = 0
			while not Place() do
				Dig()	-- added here in case of falling gravel etc.
				attempts = attempts + 1
				self:attack()
				print("Attacking: "..attempts.." / 5")
				sleep(g)
				if attempts == 5 then
					break
				end
			end
		end
		turtle.select(1)
		return true
	end
	
	local placed = false
	local noBlocks = false
	local slot = 0
	local placeBlock = ""
	--check if vegetation and remove
	if self:isSeaweed(direction) then
		Dig()
	end
	if self:isGravityBlock(direction) then
		Dig()
	end
	
	local continue = false
	local currentBlock = self:getBlockType(direction)
	if currentBlock ~= "" then  	-- solid block already present
		if 	currentBlock:find("gravel") == nil and
			currentBlock:find("sand") == nil  and
			currentBlock:find("water") == nil and
			currentBlock:find("lava") == nil then -- not water, lava, sand or gravel
			if leaveExisting then
				turtle.select(1)
				return true, false
			end
		end
	end
	
	-- make a table of all existing blocks
	local stock = self:getCurrentInventory() -- eg stock[1] = minecraft:dirt, stock[2] = "", stock[3] = "minecraft:cobblestone"
	
	--[[ debugging
	for k,v in pairs(tblPreferredBlock) do
		print("k: "..k.." v: "..tostring(v))
	end
	print("Enter to continue")
	read()]]
	
	if next(tblPreferredBlock) ~= nil then -- check for preferredBlock
		local found = false
		for i = 1, 16 do
			for k,v in pairs(tblPreferredBlock) do
				if stock[i]:find(v) ~= nil then	-- eg stock[3] = "minecraft:cobblestone"
					slot = i
					placeBlock = stock[i]
					found = true
					break
				end
			end
			if found then -- block found
				break
			end
		end
	end
	-- print("using slot no "..slot) read()


	if slot == 0 then -- no preferred block or not found
		-- check for any stock of stone in order
		local found = false
		for i = 1, #stone do -- using 'stone' table (class variable)
			for j = 1, 16 do
				if stock[j] == stone[i] then
					slot = j --slot no
					placeBlock = stock[j]
					found = true
					break
				end
			end
			if found then 
				break
			end
		end
	end
	
	if slot == 0 then -- no suitable block found
	-- print("No blocks found") read()
		noBlocks = true
	else
	-- print("Placing: "..placeBlock) read()
		placed = lib.place(direction, placeBlock, currentBlock, slot)
	end
	
	turtle.select(1)
	return placed, noBlocks
end

function T:findBedrockTop(height)
	-- T.place(self, blockType, direction, leaveExisting
	-- T.go(self, path, useTorch, torchInterval, leaveExisting)
	local bedrockFound = false
	repeat
		bedrockFound = false
		self:clear()
		print("Checking surrounding  blocks...")
		for i = 1, 4 do
			self:turnLeft(1)
			local block = self:getBlockType("forward")
			if block:find("bedrock") then
				bedrockFound = true
				print("Bedrock found...")
			else
				print("Found: "..block .. " in front")
			end
		end
		if bedrockFound then
			self:up(1)
			height = height -1 
			self:place("stone", "down", true)
			print("Moving up...")
		end
	until not bedrockFound
	repeat
		bedrockFound = false
		local moved = 0
		for i = 1, 5 do
			if self:forward(1) then
				moved = moved + 1
				for i = 1, 4 do
					self:turnLeft(1)
					if self:getBlockType("forward"):find("bedrock") then
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
		self:turnLeft(2)
		for i = 1, moved do
			self:go("C2F1", false, 0, true)
		end
		self:go("L2C1", false, 0, true)
		if bedrockFound then
			print("Moving up...")
			self:go("U1C2", false, 0, true)
			height = height -1
		else
			print("Area clear of bedrock...")
		end
	until bedrockFound == false
	return height
end

function T:getBlockType(direction)
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
	end
	
	return blockType, data -- eg "minecraft:oak_log" , {table}
end

function T:getCoords(fromFile)
	fromFile = fromFile or false
	--get world coordinates from player
	local coord = 0
	local response = ""
	local continue = true
	local event = ""
	local param1 = ""
	local getInput = true
	
	self:clear()
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
		self:setFacing(tonumber(string.sub(strText, 3)))
		fileHandle.close()
		self:saveToLog("Coordinates loaded from file:", false)
		self:saveToLog("x = "..self.x..", y = "..self.y..", z = "..self.z..", f = "..self.facing, false)
		print("Coordinates loaded from file:\n")
		print("XYZ: - "..self.x.." / "..self.y.." / "..self.z.."\n")
		print("Facing: "..self.compass)
		print("\nUse F3 to check these coordinates")
		write("\nAre they correct (y/n + Enter)?")
		response = read()
		if response == "y" or response == "" then
			getInput = false
		else
			self:clear()
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
					self:clear()
					print("Incorrect input. Use numbers only!")
					print()
					print("Please enter your X coordinate")
					write("  x = ")
				end
			end
			self.x = coord
			self:clear()
			print("Please enter your Y coordinate")
			write("  y = ")
			coord = nil
			while coord == nil do
				coord = tonumber(read())
				if coord == nil then
					self:clear()
					print("Incorrect input. Use numbers only")
					print()
					print("Please enter your y coordinate")
					write("  y = ")
				end
			end
			self.y = coord
			self:clear()
			print("Please enter your Z coordinate")
			write("  z = ")
			coord = nil
			while coord == nil do
				coord = tonumber(read())
				if coord == nil then
					self:clear()
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
				self:clear()
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
			self:setFacing(coord)
			self:clear()
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
		self:saveToLog("homeCoords.txt file created", true)
		self:saveToLog("x = "..self:getX()..", y = "..self:getY()..", z = "..self:getZ()..", f = "..self:getFacing(), false)
	end
end

function T:getCurrentInventory()
	-- make a table of all existing blocks
	local stock = {"","","","","","","","","","","","","","","",""}
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			data = turtle.getItemDetail(i) -- returns {count = x, name = 'minecraft:item" in 1.16.2)
			stock[i] = data.name
		end
	end	
	return stock -- eg stock[1] = minecraft:dirt, stock[2] = "", stock[3] = "minecraft:cobblestone"
end

function T:getEquipped(side, keepInInventory)
	-- side = "right", "left", "minecraft:diamond_pickaxe"
	keepInInventory = keepInInventory or true
	local item = ""
	local slot = self:getFirstEmptySlot()
	turtle.select(slot)
	if side == "right" then
		if turtle.equipRight() then				-- take out whatever is on right side
			item = self:getSlotContains(slot)
			if item == "" then
				slot = 0
			else
				if not keepInInventory then
					turtle.equipRight()			-- put it back
				end
			end
		end
	elseif side == "left" then
		if turtle.equipLeft() then
			item = self:getSlotContains(slot)
			if item == "" then
				slot = 0
			else
				if not keepInInventory then
					turtle.equipLeft()			-- put it back
				end
			end
		end
	else	-- side will be item required eg axe
		if turtle.equipRight() then				-- take out whatever is on right side
			item = self:getSlotContains(slot)
			if item ~= side then				-- not the required item
				turtle.equipRight()				-- put it back
				if turtle.equipLeft() then
					item = self:getSlotContains(slot)
					if item ~= side then				-- not the required item
						turtle.equipLeft()
						item = ""
						slot = 0
					end
				end
			end
		end
	end
	
	return item, slot	-- 0, "" if nothing equipped; 1, "minecraft:crafting_table"
end

function T:getFirstEmptySlot()
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

function T:getFirstItem(ofType)
	-- eg ofType = "seeds"
	ofType = ofType or ""
	local slot = 0
	local item, itemName, shortName = "", "", ""
	for i = 1, 16 do
		item = self:getItemName(i)		-- get full name of item
		if ofType == "" then			-- find any item
			itemName, shortName = self:getName(item)
			return item, itemName, shortName, i
		else
			if item:find(ofType) ~= nil then
				itemName, shortName = self:getName(item)
				return item, itemName, shortName, i
			end
		end
	end
	return item, itemName, shortName, slot
end

function T:getInput()
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
			--if string.len(userInput) == 0 then
			if userInput:len() == 0 then
				print("\nJust pressing the Enter key doesn't work...")
			else		
				--if string.sub(userInput, 1, 1):lower() == "y" then
				if userInput:sub(1, 1):lower() == "y" then
					userInput = true
					break
				--elseif string.sub(userInput, 1, 1):lower() == "n" then
				elseif userInput:sub(1, 1):lower() == "n" then
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
			if userInput == "" then
				print("\nJust pressing Enter doesn't work...")
			else		
				--if string.len(userInput) >= minInt and string.len(userInput) <= maxInt then
				if userInput:len() >= minInt and userInput:len() <= maxInt then
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
			if userInput == "" then
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

function T:getInventory()
	local temp = {}
	local blockCount = 0
	local blockTypeCount = 0
	local mostItem = ""
	
	for slot = 1, 16 do
		local slotContains, slotCount = T:getSlotContains(slot)
		if slotContains ~= "" then
			if temp[slotContains] == nil then
				temp[slotContains] = slotCount
				blockTypeCount = blockTypeCount + 1
			else
				temp[slotContains] = temp[slotContains] + slotCount
			end
			blockCount = blockCount + slotCount
		end
	end
	local names = {}
	local blockCounts = {}
	local mostCount = 0
	local mostItem = ""
	for block, count in pairs (temp) do
		table.insert(names, block)
		table.insert(blockCounts, count)
		if count > mostCount then
			mostCount = count
			mostItem = block
		end
	end
	local inventory = temp
	inventory.names = names
	inventory.quantities = blockCounts
	inventory.blockTypeCount = blockTypeCount
	inventory.blockCount = blockCount
	inventory.useBlock = mostItem
	inventory.mostBlock = mostItem
	inventory.mostCount = mostCount

	return inventory
	--[[
		{
		inventory["minecraft:cobblestone"] = 128
		inventory["minecraft:stone"] = 64
		inventory.names = {minecraft:cobblestone, minecraft:stone}
		inventory.quantities = {128, 64}
		inventory.blockTypeCount = 2,
		inventory.blockCount = 196,
		inventory.useBlock = "minecraft:cobblestone"
		inventory.mostBlock = "minecraft:cobblestone"
		inventory.mostCount = 128
		}
	]]
end

function T:updateInventory()
	local quit = false
	repeat
		local event, param1 = os.pullEvent()
		if event == "turtle_inventory" then	-- user has added, moved or removed inventory items
			return self:getInventory()
		elseif event == "key" then
			if param1 == keys.enter then
				quit = true
			end
		end
	until quit
	
	return nil
end

function T:getInventoryData()
	--[[ table eg: {"minecraft:cobblestone" = {1 = 64, 2 = 64, 5 = 10}, "minecraft:cobbled_deepslate" = {3 = 60, 4 = 17}}  ]]
	local inventory = {}
	for slot = 1, 16 do
		local slotContains, slotCount = self:getSlotContains(slot)
		if slotContains ~= "" then -- eg "minecraft:cobblestone"
			if inventory[slotContains] ~= nil then --already exists in inventory
				table.insert(inventory[slotContains], {slot = slotCount}) -- add new table for this lot and count
			else
				inventory[slotContains] = {slot = slotCount}
			end
		end
	end
	return inventory
	--[[
	{
		"minecraft:cobblestone" = {1 = 64, 2 = 64, 5 = 10},
		"minecraft:cobbled_deepslate" = {3 = 60, 4 = 17}
	}
	]]
end

function T:getInventoryItems()
	--[[ table eg: {"minecraft:cobblestone" = 256, "minecraft:cobbled_deepslate = 256"}  ]]
	local inventory = {}
	for slot = 1, 16 do
		local slotContains, slotCount = self:getSlotContains(slot)
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

function T:getItemCount(item)
	local slot, total, slotData = self:getItemSlot(item) --return .leastSlot, .leastModifier, total, slotData
	return total
end

function T:getItemName(slot)
	local data = {} --initialise empty table variable
	data.name = ""
	if slot > 0 and slot < 17 then
		if turtle.getItemCount(slot) > 0 then
			data = turtle.getItemDetail(slot)
		end
	end
	
	return data.name
end

function T:getItemSlot(item)
	-- return slot no with least count, and total count available
	-- along with a table of mostSlot, mostCount, leastSlot, leastCount
	-- if minecraft:log or log2, names for 1.16.2 changed to 'minecraft:oak_log' etc so use wildcards 'log'
	item = item or "stone"
	
	local slotData = {}	-- setup return table
	slotData.firstSlot = 0
	slotData.lastSlot = 0
	slotData.mostSlot = 0
	slotData.mostName = ""
	slotData.mostCount = 0
	slotData.leastSlot = 0
	slotData.leastName = ""
	slotData.leastCount = 0
	
	local lib = {}
	
	function lib.update(i, v)
		local count = turtle.getItemCount(i)
		if slotData.firstSlot == 0 then		-- setup .firstSlot
			slotData.firstSlot = i
		end
		if count > slotData.mostCount then	-- setup .mostCount
			slotData.mostSlot = i
			slotData.mostName = v
			slotData.mostCount = count
		end
		if count < slotData.leastCount then
			slotData.leastSlot = i
			slotData.leastName = v
			slotData.leastCount = count
		end
		slotData.lastSlot = i				-- setup / edit .lastSlot
		
		return count
	end
	
	local total = 0
	-- make a table of all existing blocks
	local stock = self:getCurrentInventory()	-- returns full names of all inventory items in a list 1-16
	
	if item:find("\:") ~= nil then 					-- find exact match only
		for i,v in ipairs(stock) do					-- iterate current inventory
			if v == item then						-- item found
				total = total + lib.update(i, v)
			end
		end
	elseif item:find("common") ~= nil or item == "any" or item == "stone" then -- find any stone, in prefence order from stone table
		local stoneFound = false
		for j = 1, #stone do -- using 'stone' table (class variable)
			for i = 1, 16 do
				if stock[i] == stone[j] then
					stoneFound = true -- found match in list priority
					item = stone[j]
					break
				end
			end
			if stoneFound then
				break
			end
		end
		if stoneFound then
			for i,v in ipairs(stock) do				-- iterate current inventory
				if v:find(item) ~= nil then			-- item found
					total = total + lib.update(i, v)
				end
			end
		end
	else -- find matching name
		for i,v in ipairs(stock) do				-- iterate current inventory
			if v:find(item) ~= nil then			-- item found
				total = total + lib.update(i, v)
			end
		end
	end

	if slotData.mostSlot > 0 then
		if slotData.leastSlot == 0 then
			slotData.leastSlot = slotData.mostSlot
			slotData.leastName = slotData.mostName
			slotData.leastCount = slotData.mostCount
		end
	end
	return slotData.lastSlot, total, slotData -- integer, integer, table
end

function T:getMostItem(excludeItem, stoneOnly)
	--[[ Used to get user choice of stone based on quantity ]]
	local lib = {}
	
	function lib.checkStone(item)
		for k,v in ipairs (stone) do
			if item == v then
				return true
			end
		end
		return false
	end
	
	excludeItem = excludeItem or ""
	stoneOnly = stoneOnly or false
	local data = {} 
	local inventory = {}
	local mostItem = ""
	local leastItem = ""
	local mostCount = 0
	local leastCount = 0
	local itemTypeCount = 0
	local itemCount = 0
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			data = turtle.getItemDetail(i)
			if inventory[data.name] == nil then
				inventory[data.name] = data.count
				itemTypeCount = itemTypeCount + 1
			else
				inventory[data.name] = inventory[data.name] + data.count
			end
			itemCount = itemCount + data.count
		end
	end
	for k,v in pairs(inventory) do
		if mostItem == "" then					-- not yet found mostItem
			if stoneOnly then 					-- only check for stone blocks
				if lib.checkStone(k) then		-- stone found
					if excludeItem == "" then 	-- no excluded items
						mostItem = k
						mostCount = v
						leastItem = k
						leastCount = v
					else
						if k:find(excludeItem) == nil then -- not found
							mostItem = k
							mostCount = v
							leastItem = k
							leastCount = v
						end
					end
				end
			else								-- not just stone in count
				if excludeItem == "" then 		-- no excluded items
					mostItem = k
					mostCount = v
					leastItem = k
					leastCount = v
				else
					if k:find(excludeItem) == nil then -- not found
						mostItem = k
						mostCount = v
						leastItem = k
						leastCount = v
					end
				end
			end
		else									-- mostItem found
			if stoneOnly then 					-- only check for stone blocks
				if lib.checkStone(k) then
					if excludeItem == "" then 	-- no excluded items
						if inventory[k] > mostCount then
							mostItem = k
							mostCount = v
						end
						if inventory[k] < leastCount then
							leastItem = k
							leastCount = v
						end
					else
						if k:find(excludeItem) == nil then -- not found
							if inventory[k] > mostCount then
								mostItem = k
								mostCount = v
							end
							if inventory[k] < leastCount then
								leastItem = k
								leastCount = v
							end
						end
					end
				end
			else
				if excludeItem == "" then 			-- no excluded items
					if inventory[k] > mostCount then
						mostItem = k
						mostCount = v
					end
					if inventory[k] < leastCount then
						leastItem = k
						leastCount = v
					end
				else
					if k:find(excludeItem) == nil then -- not found
						if inventory[k] > mostCount then
							mostItem = k
							mostCount = v
						end
						if inventory[k] < leastCount then
							leastItem = k
							leastCount = v
						end
					end
				end
			end
		end
	end
	
	--print("mostItem: "..mostItem.." mostCount: "..mostCount) read()
	return mostItem, mostCount, leastItem, leastCount, inventory
end

function T:getName(item)
	-- eg minecraft:beetroot_seeds -> beetroot_seeds or beetroot
	local marker, name, shortName = 0, "", ""
	marker = item:find("\:")			-- eg minecraft:beetroot_seeds -> 10
	if marker ~= nil then
		name = item:sub(marker + 1)		-- eg minecraft:beetroot_seeds -> beetroot_seeds
	else
		name = item
	end
	marker = name:find("_") 			-- eg beetroot_seeds -> 9
	if marker ~= nil then
		shortName = name:sub(1, marker)	-- eg beetroot_seeds -> beetroot
	else
		shortName = name
	end
	return name, shortName
end

function T:getNames(item)
	-- item MUST be full name
	-- eg minecraft:beetroot_seeds
	local parts, tblParts, mod, rest
	if item:find("\:") == nil then
		if item:find("_") == nil then
			return {item}	-- eg "seeds"
		else
			mod = ""
			rest = item
		end
	else
		parts = item:split(":")
		mod = parts[1]
		rest = parts[2]
	end
	tblParts = {}
	table.insert(tblParts, mod)
	parts = rest:split("_")
	for _, v in ipairs(parts) do
		table.insert(tblParts, v)
	end

	return tblParts -- eg {"minecraft","crafting", "table"} 
end

function T:getPolishedItem(blockType)
	--[[
		local blockType, count = T:getPolishedItem("")
		local blockType, count = T:getPolishedItem("slab")
		local blockType, count = T:getPolishedItem("stairs")
		local blockType, count = T:getPolishedItem("wall")
	]]
	local data = {} 
	local inventory = {}
	
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
		if k:find("polished") ~= nil then -- contains polished stairs, wall, slab,
			if blockType == "slab" or blockType == "stairs" or blockType == "wall" then
				if K:find(blockType) ~= nil then
					return k, v
				end
			else -- looking for polished_andesite, granite etc block
				if k:find("slab") == nil and k:find("stairs") == nil and k:find("wall") == nil then
					return k, v
				end
			end
		end
	end
	
	return "", 0
end

function T:getSaplingSlot(name)
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

function T:getPlaceChestDirection()
	local facing = self.facing
	local chestDirection = "forward"
	local turns = 0
	
	for i = 1, 4 do
		if turtle.detect() then
			self:turnRight(1)
			turns = turns + 1
		else
			break
		end
	end
	if turns == 4 then -- full circle
		turns = 0
		if turtle.detectDown() then -- no space below
			if turtle.detectUp() then
				if self:dig("up") then
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

function T:getSlotContains(slotNo)
	local data = {} --initialise empty table variable
	
	local slotCount = 0
	local slotContains = ""
	if turtle.getItemCount(slotNo) > 0 then
		data = turtle.getItemDetail(slotNo)
		slotCount = data.count
		slotContains = data.name
	end
	
	return slotContains, slotCount
end

function T:getStock(item)
	-- return total units and slot numbers of max and min amounts
	local slot, total, slotData = self:getItemSlot(item) --return .leastSlot, .leastModifier, total, slotData
	local rt = {}
	rt.total = total
	rt.mostSlot = slotData.mostSlot
	rt.leastSlot = slotData.leastSlot
	rt.mostCount = slotData.mostCount
	rt.leastCount = slotData.leastCount

	return rt --{rt.total, rt.mostSlot, rt.leastSlot, rt.mostCount, rt.leastCount}
end

function T:getSolidBlockCount()
	local retValue = 0
	--local solids = {'cobble', 'stone', 'dirt', 'granite', 'andesite', 'diorite', 'deepslate', 'glass', 'tuff'}
	local slotCount, slotContains
	for i = 1, 16 do
		slotContains, slotCount = self:getSlotContains(i)
		for _, v in ipairs(stone) do
			if slotContains:find(v) ~= nil then
				retValue = retValue + slotCount
				break
			end
		end
	end
	return retValue
end

function T:getTotalItemCount()
	local count = 0
	
	for i = 1, 16 do
		count = count + turtle.getItemCount(i)
	end
	return count
end

function T:getWater(direction)
	direction = direction or "forward"
	-- assign place methods according to direction
	local Place = turtle.place
	if direction == "up" then
		Place = turtle.placeUp
	elseif direction == "down" then
		Place = turtle.placeDown
	end
	local slot = self:getItemSlot("minecraft:bucket")
	if slot > 0 then
		turtle.select(slot)
		if Place() then
			turtle.select(1)
			return true
		end
	end
	turtle.select(1)
	return false
end

function T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	useTorch = useTorch or false -- used in m and M to place torches in mines
	if leaveExisting == nil then
		leaveExisting = false
	end
	torchInterval = torchInterval or 8
	if preferredBlock == nil or preferredBlock == "" then
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
	self:refuel(15)
	turtle.select(1)
	for cmd in self:values(commandList) do -- eg F12 or x1
		local move = string.sub(cmd, 1, 1)
		local modifier = tonumber(string.sub(cmd, 2))
		if move == "A" then --mine block above and/or fill void + fill both sides
			turtle.select(1)
			--[[check block behind
			T.turnRight(self, 2)
			T.digValuable(self, "forward")
			T.fillVoid(self, "forward")
			T.turnRight(self, 2)]]
			for i = 1, modifier + 1 do --eg A16 run loop 17 x
				self:digValuable("up")
				self:fillVoid("up")
				self:turnLeft(1)
				self:digValuable("forward")
				self:fillVoid("forward")
				self:turnRight(2)
				self:digValuable("forward")
				self:fillVoid("forward")
				self:turnLeft(1)
				--T.dig(self, "down") -- create player coridoor
				if i <= modifier then -- A16 = move forward 16x
					self:forward(1)
				end
			end
			--check block at end
			self:digValuable("forward")
			self:fillVoid("forward")
		elseif move == "B" then
			self:back(modifier)
		elseif move == "c" then
			if turtle.detectDown() then
				--check if vegetation and remove
				if self:isSeaweed("down") then
					turtle.digDown()
				end
			end
			if not turtle.detectDown() then
				if not self:place("minecraft:cobblestone", "down") then
					self:place("minecraft:dirt", "down")
				end
			end
		elseif move == "C" then
			-- fillVoid(self, direction, tblPreferredBlock, leaveExisting)
			local fill = false
			if leaveExisting then -- leave alone if non-gravity
				if self:detect(direction[modifier + 1]) then -- solid block ahead, not air, water or lava
					if self:digValuable(direction[modifier + 1]) then
						fill = true
					elseif self:digGravityBlock(direction[modifier + 1]) then -- sand or gravel
						fill = true
					end
				else	-- air, water or lava ahead
					fill = true
				end
			else
				fill = true
			end
			if fill then
				self:fillVoid(direction[modifier + 1], preferredBlock, false)
			end
		elseif move == "d" then -- down and place while not detect
			if modifier == 1 then
				self:fillVoid("forward", preferredBlock)
			end
			while not turtle.detectDown() do
				self:down(1)
				if modifier == 1 then
					self:fillVoid("forward", preferredBlock)
				end
			end
			if modifier == 1 then
				self:fillVoid("forward", preferredBlock)
			end
		elseif move == "D" then
			self:down(modifier)
		elseif move == "e" then -- ladder above / in front / below
			self:place("minecraft:ladder", direction[modifier + 1], false)
		elseif move == "E" then --mine block below + fill both sides
			turtle.select(1)
			--check block behind
			self:turnRight(2)
			self:digValuable("forward")
			self:fillVoid("forward")
			self:turnRight(2)
			for i = 1, modifier + 1 do --eg A16 run loop 17 x
				self:turnLeft(1)
				self:digValuable("forward")
				self:fillVoid("forward")
				self:turnRight(2)
				self:digValuable("forward")
				self:fillVoid("forward")
				self:turnLeft(1)
				self:dig("down") -- create player coridoor
				if i <= modifier then -- A16 = move forward 16x
					self:forward(1)
				end
			end
			--check block at end
			self:digValuable("forward")
			self:fillVoid("forward")
		elseif move == "F" then
			self:forward(modifier)
		elseif move == "H" then
			self:place("minecraft:chest", direction[modifier + 1], leaveExisting)
		elseif move == "L" then
			self:turnLeft(modifier)
		elseif move == "m" then --mine block below and/or fill void
			--T:go("m8", false, 0, false, brick)
			for i = 1, modifier + 1 do --eg m8 run loop 9 x
				turtle.select(1)
				local isValuable, blockType = self:isValuable("down")
				if isValuable or blockType == "minecraft:gravel" or not leaveExisting then
					turtle.digDown() -- dig if gravel
				elseif blockType == "minecraft:lava" then
					self:place("minecraft:bucket", "down")
				end
				self:dig("up") -- create player coridoor
				if not turtle.detectDown() then
					self:fillVoid("down", preferredBlock, leaveExisting)
				end
				if i <= modifier then -- n8 = move forward 8x. check for initial use in mine to avoid torch in wrong place
					if useTorch then
						if  (i == intervalList[1] and modifier >= 16) or
							i == intervalList[2] or
							i == intervalList[3] or
							i == intervalList[4] or
							i == intervalList[5] then
							self:up(1)
							self:place("minecraft:torch", "down", false)
							self:forward(1)
							self:down(1)
						else
							self:forward(1)
						end
					else
						self:forward(1)
					end
				end
			end
		elseif move == "M" then --mine block above and/or fill void
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = self:isValuable("up")
				if isValuable then
					self:dig("up")
				elseif blockType == "minecraft:lava" then
					self:place("minecraft:bucket", "up")
				end
				if not turtle.detectUp()then
					self:fillVoid("up", preferredBlock)
				end
				if i <= modifier then -- will not move forward if modifier = 0
					if useTorch then
						if  i == intervalList[1] or
							i == intervalList[2] or
							i == intervalList[3] or
							i == intervalList[4] or
							i == intervalList[5] then
							self:place("minecraft:torch", "down", false)
						end
					end
					self:forward(1)
				end
			end
		elseif move == "n" then --mine block below and/or fill void + check left side
			for i = 1, modifier + 1 do --eg m8 run loop 9 x
				turtle.select(1)
				local isValuable, blockType = self:isValuable("down")
				if isValuable or blockType == "minecraft:gravel" or not leaveExisting then
					turtle.digDown() -- dig if valuable or gravel
				else --check for lava
					if blockType == "minecraft:lava" then
						self:place("minecraft:bucket", "down")
					end
				end
				self:dig("up") -- create player coridoor
				if not turtle.detectDown() then
					self:fillVoid("down", preferredBlock)
				end
				self:turnLeft(1)
				local isValuable, blockType = self:isValuable("forward")
				if isValuable or not leaveExisting then
					turtle.dig() -- dig if valuable
				end
				if not turtle.detect() then
					self:fillVoid("forward", preferredBlock, leaveExisting)
				end
				self:turnRight(1)	
				if i <= modifier then -- m8 = move forward 8x
					if useTorch then
						if  i == intervalList[1] or
							i == intervalList[2] or
							i == intervalList[3] or
							i == intervalList[4] or
							i == intervalList[5] then
							self:up(1)
							self:place("minecraft:torch", "down", false)
							self:forward(1)
							self:down(1)
						else
							self:forward(1)
						end
					else
						self:forward(1)
					end
				end
			end
		elseif move == "N" then --mine block above and/or fill void + mine block below if valuable
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = self:isValuable("up")
				if isValuable then
					self:dig("up")
				elseif blockType == "minecraft:lava" then
					self:place("minecraft:bucket", "up")
				end
				if not turtle.detectUp() then
					self:fillVoid("up", preferredBlock)
				end
				turtle.select(1)
				isValuable, blockType = self:isValuable("down")
				if isValuable then
					self:dig("down")
					self:fillVoid("down", preferredBlock)
				else
					if self:getBlockType("down") == "minecraft:lava" then
						self:place("minecraft:bucket", "down")
					end
				end
				if i <= modifier then
					self:forward(1)
				end
			end
		elseif move == "P" then
			self:place("minecraft:hopper", direction[modifier + 1], leaveExisting)
		elseif move == "q" then --mine block and fill voids on left side left side
			for i = 1, modifier + 1 do
				turtle.select(1)
				self:turnLeft(1)
				if self:isValuable("forward") then
					turtle.dig() -- dig if valuable
				end
				if not turtle.detect() then
					self:fillVoid("forward", preferredBlock)
				end
				self:turnRight(1)	
				if i <= modifier then
					self:forward(1)
				end
			end
		elseif move == "Q" then --mine block above and/or fill void + mine block below if valuable + left side
			for i = 1, modifier + 1 do
				turtle.select(1)
				if self:isValuable("up") then
					self:dig("up")
				else --check for lava
					if self:getBlockType("up") == "minecraft:lava" then
						self:place("minecraft:bucket", "up")
					end
				end
				if not turtle.detectUp() then
					self:fillVoid("up", preferredBlock)
				end
				self:turnLeft(1)
				if self:isValuable("forward") then
					turtle.dig() -- dig if valuable
				end
				if not turtle.detect() then
					self:fillVoid("forward", preferredBlock)
				end
				self:turnRight(1)	
				if self:isValuable("down") then
					turtle.digDown()
				end
				if i <= modifier then
					self:forward(1)
				end
			end
		elseif move == "r" then
			self:place("minecraft:dirt", direction[modifier + 1], leaveExisting)
		elseif move == "R" then
			self:turnRight(modifier)
		elseif move == "s" then
			if modifier == 0 then
				while turtle.suckUp() do end
			elseif modifier == 1 then
				while turtle.suck() do end
			elseif modifier == 2 then
				while turtle.suckDown() do end
			end
		elseif move == "S" then
			self:place("sapling", direction[modifier + 1], leaveExisting)
		elseif move == "t" then
			-- 0 = placeUp does not work with os 1.8
			-- 1 = turn round, placeForward
			-- 2 = placeDown
			-- 3 = turnLeft, placeUp
			-- 4 = turnround, placeUp
			-- 5 = place down without block
			if modifier == 0 then -- os < 1.8
				self:place("minecraft:torch", "up", false)
			elseif modifier == 1 then --place behind
				self:turnLeft(2)
				self:place("minecraft:torch", "forward", false)
				self:turnLeft(2)
			elseif modifier == 2 then -- place below for 2
				if not self:place("minecraft:cobblestone", "down") then
					self:place("minecraft:dirt", "down")
				end
				self:up(1)
				self:place("minecraft:torch", "down", false)
				self:forward(1)
				self:down(1)
			elseif modifier == 3 then --turnLeft, placeUp (on ground to wall)
				self:turnLeft(1)
				self:place("minecraft:torch", "up", false)
				self:turnRight(1)
			elseif modifier == 4 then --turnLeft, placeUp (on ground to wall)
				self:turnLeft(2)
				self:place("minecraft:torch", "up", false)
				self:turnLeft(2)
			elseif modifier == 5 then --cobble first, then torch
				self:place("minecraft:torch", "down", false)
			end
		elseif move == "T" then
			self:place("minecraft:torch", direction[modifier + 1], leaveExisting)
		elseif move == "u" then -- move up and place forward/down
			repeat
				if modifier == 1 then
					self:fillVoid("forward", preferredBlock, leaveExisting)
				end
				self:up(1)
				if modifier == 1 then
					self:fillVoid("forward", preferredBlock, leaveExisting)
				end
				self:fillVoid("down", preferredBlock, leaveExisting)
			until not turtle.inspectUp()
			if modifier == 1 then
				self:fillVoid("forward", preferredBlock, leaveExisting)
			end
		elseif move == "U" then
			self:up(modifier)
		elseif move == "x" then
			if modifier == 0 then
				self:dig("up")
			elseif modifier == 1 then
				self:dig("forward")
			elseif modifier == 2 then
				while turtle.detectDown() do
					turtle.digDown()
				end
			end
		elseif move == "V" then --QuickMine
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = self:isValuable("down")
				if isValuable then
					self:dig("down")
				elseif blockType == "minecraft:lava" then
					self:place("minecraft:bucket", "down")
				end
				isValuable, blockType = self:isValuable("up")
				if isValuable then
					self:dig("up")
				elseif blockType == "minecraft:lava" then
					self:place("minecraft:bucket", "up")
				end
				if not turtle.detectUp()then
					self:fillVoid("up", preferredBlock)
				end
				if not turtle.detectDown()then
					self:fillVoid("down", preferredBlock)
				end
				if i <= modifier then -- will not move forward if modifier = 0
					self:forward(1)
				end
			end
		elseif move == "W" then --QuickCoridoor
			for i = 1, modifier + 1 do
				turtle.select(1)
				local isValuable, blockType = self:isValuable("up")
				if isValuable then
					self:dig("up")
				elseif blockType == "minecraft:lava" then
					self:place("minecraft:bucket", "up")
				end
				if not turtle.detectUp()then
					self:fillVoid("up", preferredBlock)
				end
				self:isWaterOrLava("down") -- automatically removes lava
				self:dig("down")
				if i <= modifier then -- will not move forward if modifier = 0
					self:forward(1)
				end
			end
		elseif move == "X" then --mine block below and/or fill void, then check sides (X = trench)
			for i = 1, modifier + 1 do --eg X8 run loop 9 x
				turtle.select(1)
				local isValuable, blockType = self:isValuable("down")
				if isValuable or blockType == "minecraft:gravel" or blockType == "minecraft:sand" or blockType:find("grass") ~= nil then
					turtle.digDown() -- dig if gravel
				else --check for lava
					if blockType == "minecraft:lava" then
						self:place("minecraft:bucket", "down")
					end
				end
				self:dig("up") -- create player coridoor
				if not turtle.detectDown() then
					self:fillVoid("down")
				end
				self:turnRight(1)
				if not turtle.detect() then
					self:fillVoid("forward")
				end
				self:turnLeft(2)
				if not turtle.detect() then
					self:fillVoid("forward")
				end
				self:turnRight(1)
				if i <= modifier then -- X8 = move forward 8x
					self:forward(1)
				end
			end
		elseif move == "Z" then -- mine to bedrock
			for i = 1, modifier + 1 do	
				turtle.select(1)
				local goUp = 0
				while self:down(1) do
					goUp = goUp + 1
				end
				for j = goUp, 1, -1 do
					for k = 1, 4 do
						self:turnRight(1)
						if self:isValuable("forward") then
							self:place("minecraft:cobblestone", "forward")
						end
					end
					self:up(1)
					self:place("minecraft:cobblestone", "down")
					turtle.select(1)
				end
				if i <= modifier then 
					self:forward(2)
				end
			end
		elseif move == "+" then
			local height = 0
			while turtle.detectUp() do
				self:up(1)
				height = height + 1
			end
			self:down(height)
		elseif move == "-" then
			while not turtle.inspectDown() do
				self:down(1)
			end
		elseif move == "*" then
			local goUp = 0
			while not turtle.inspectDown() do
				self:down(1)
				goUp = goUp + 1
			end
			if goUp > 0 then
				for i = 1, goUp do
					self:up(1)
					if not self:place("minecraft:cobblestone", "down") then
						self:place("minecraft:dirt", "down")
					end
				end
				goUp = 0
			else
				turtle.digDown()
				if not self:place("minecraft:cobblestone", "down") then
					self:place("minecraft:dirt", "down")
				end
			end
		elseif move == "^" then --place stair
			if not self:place("stairs", direction[modifier + 1], false) then -- ending false forces block replacement
				print("could not place stairs "..direction[modifier + 1])
				self:place("minecraft:cobblestone", direction[modifier + 1], false)
			end
		elseif move == "@" then -- any item in inventory
			self:place("", direction[modifier + 1], leaveExisting)
		end
	end
	turtle.select(slot)
end

function T:harvestTree(extend, craftChest, direction)
	extend = extend or false
	craftChest = craftChest or false
	direction = direction or "forward"
	local goHeight = 0
	local onLeft = true		-- default position in double tree
	if direction == "forward" then
		turtle.dig()       	-- dig base of tree
		self:forward(1) -- go under tree with 1 log. Will refuel if needed
	end
	-- check if on r or l of double width tree
	self:turnLeft(1)
	local blockType = self:getBlockType("forward")
	if blockType:find("log") ~= nil then
		extend = true
		onLeft = false 				-- placed on right side of 2 block tree
	end
	self:turnRight(2)	-- check if double tree
	blockType = self:getBlockType("forward")
	if blockType:find("log") ~= nil then
		extend = true
		onLeft = true 				-- placed on left side of 2 block tree
	end
	self:turnLeft(1)	-- return to correct position
	if craftChest then
		self:dig("up")
		self:up(1)
		self:dig("up")
		while not self:detect("down") do
			self:down(1)
		end
		self:craft("planks", 8)
		self:craft("chest", 1)
		while self:detect("up") do
			self:up(1)
			goHeight = goHeight + 1
		end
	end
	-- Loop to climb up tree and harvest trunk and surrounding leaves
	while self:dig("up") do -- continue loop while block detected above
		self:up(1)  -- Move up
		goHeight = goHeight + 1
		-- Inner loop to check for leaves/ break double tree logs
		for i = 1, 4 do
			blockType = self:getBlockType("forward")
			if blockType:find("log") ~= nil or blockType:find("leaves") ~= nil then
				self:dig("forward") --Dig leaves / logs in double tree. Leave bee nests
			end
			self:turnRight(1)
		end
	end
	-- At top of the tree. New loop to return to ground
	if extend then
		if onLeft then
			self:go("F1R1F1R2")
		else
			self:go("F1L1F1R2")
		end
		while turtle.detectUp() do
			self:up(1)
			goHeight = goHeight + 1
		end
	end
	for i = 1, goHeight do
		if extend then
			for j = 1, 4 do
				self:dig("forward")
				self:turnRight(1)
			end
		end
		self:down(1)
	end
	-- check for logs below in case felling started above ground
	while self:getBlockType("down"):find("log") ~= nil do
		self:down(1)
	end
	if extend then
		if onLeft then
			self:go("F1L1F1R2")
		else
			self:go("F1R1F1R2")
		end
	end
	return extend	-- true if double tree
end

function T:harvestWholeTree(direction)	
	--RECURSIVE FUNCTION - BEWARE!
	local blockType, height

	if direction == "up" then
		self:refuel(15)
		if self:isLog("up") then
			self:up(1)
			if self:isLog("up") then
				self:harvestWholeTree("up")
			end
		end
		self:down(1)
		for i = 1, 4 do
			-- check all round
			if self:isLog("forward") then
				self:harvestWholeTree("forward")
			else
				blockType = self:getBlockType("forward")
				if blockType ~= "" then
					if blockType:find("leaves") ~= nil then
						self:forward(1)
						self:harvestWholeTree("forward")
						self:back(1)
					end
				end
			end
			self:turnRight(1)
		end
	elseif direction == "forward" then
		if self:isLog("forward") then
			self:refuel(15)
			
			self:forward(1)
			if turtle.detectUp() then
				turtle.digUp()
			end
			if self:isLog("forward") then
				self:harvestWholeTree("forward")
			end
			--check left side
			self:turnLeft(1)
			if self:isLog("forward") then
				self:harvestWholeTree("forward")
			end
			-- check right side
			self:turnRight(2)
			if self:isLog("forward") then
				self:harvestWholeTree("forward")
			end
			self:turnLeft(1)
			self:back(1)
		end
	end
end

function T:isEmpty()
	local isEmpty = true
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			isEmpty = false
			break
		end
	end
	return isEmpty
end

function T:isLog(direction) 
	local success = false
	local blockType, modifier
	
	local Detect = turtle.detect
	if direction == 'up' then
		Detect = turtle.detectUp
	elseif direction == 'down' then
		Detect = turtle.detectDown
	end
	
	if Detect() then
		blockType = self:getBlockType(direction)
		if blockType:find('log') ~= nil then
			success = true
		end
	end
	
	return success
end

function T:isValuable(direction) 
	local success = false
	local ignoreList = "minecraft:dirt,minecraft:grass,minecraft:stone,minecraft:gravel,minecraft:chest,"..
					 "minecraft:cobblestone,minecraft:sand,minecraft:torch,minecraft:bedrock,minecraft:ladder"..
					 "minecraft:netherrack,minecraft:blackstone,minecraft:basalt"..
					 "minecraft:granite,minecraft:diorite,minecraft:andesite"..
					 "minecraft:deepslate,minecraft:cobbled_deepslate,minecraft:tuff,minecraft:obsidian,minecraft:end_stone"

					 
	local Detect = turtle.detect
	
	if direction == "up" then
		Detect = turtle.detectUp
	elseif direction == "down" then
		Detect = turtle.detectDown
	end
	
	local blockType = self:getBlockType(direction)
	
	if blockType ~= "" then --block found
		success = true
		if ignoreList:find(blockType) ~= nil then
			success = false
		end
		if blockType:find("lava") ~= nil or blockType:find("water") ~= nil then
			success = false
		end
	end
	if success then
		-- check if diamond. or netherite if so ensure space in inventory
		if blockType:find("diamond") ~= nil or blockType:find("debris") ~= nil then
			self:dumpRefuse(direction)
		end
	end
	return success, blockType
end

function T:isSeaweed(direction)
	--[[ look for seaweed in specified direction ]]
	local Detect = turtle.detect
	local blockName
	if direction == "up" then
		Detect = turtle.detectUp
	elseif direction == "down" then
		Detect = turtle.detectDown
	end
	if Detect() then
		blockName = self:getBlockType(direction)
	end
	if self:isVegetation(blockName) then
		return true
	end
	return false
end

function T:isGravityBlock(direction)
	--[[ look for sand, gravel, concrete powder ]]
	local blockName = self:getBlockType(direction)
	if blockName:find("sand") ~= nil or blockName:find("gravel") ~= nil then
		return true
	end
	return false
end

function T:isEmpty()
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			return false
		end
	end
	return true
end

function T:isVegetation(blockName)
	blockName = blockName or ""
	for _, v in pairs(flowers) do
		if blockName == v then
			return true
		end
	end
	
	return false
end

function T:isWater(direction)
	direction = direction or "forward"
	local isWater = false
	local isSource = false
	local isIce = false
	local level = nil
	local isAir = false
	
	local blockType, data = self:getBlockType(direction)		
	if blockType == "" then
		return false, false, false, nil, true
	end
	if blockType:find("water") ~= nil or blockType == "minecraft:bubble_column" or blockType:find("ice") ~= nil then -- allows for bubble_column
		isWater = true
		if blockType == "minecraft:bubble_column" then
			isSource = true
		end
		if blockType:find("ice") ~= nil then
			isSource = true
			isIce = true
		end
		level = data.state.level
		if level ~= nil then
			if level == 0 then
				isSource = true
			end
		end
	end
	
	-- isWater 	= source, ice, flowing water or bubble column
	-- isSource = source or ice
	-- isIce 	= ice
	-- level 	= nil or flowing water value
	-- air 		= NOT water, source, ice
	return isWater, isSource, isIce, level, isAir --true, true, false, 0, false = source true, false, false, 1 if next to source
end
 
function T:isWaterOrLava(direction)
	direction = direction or "forward"
	local blockType = ""
	if not self:detect(direction) then --air, water or lava
		blockType = self:getBlockType(direction)
		if blockType:find("lava") ~= nil then 
			self:place("minecraft:bucket", direction, false) -- auto refuel
		end
	end
	return blockType  -- "" or 'minecraft:xxxx"
end

function T:menu(title, list)
	local retValue = 0
	response = true
	while response do
		response = false
		self:clear()
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

function T:place(blockType, direction, leaveExisting, signText, doNotAttack)
	-- originally place(blockType, damage, direction, leaveExisting, signText): "log", -1, "forward", true, "Hello"
	if blockType == "" then --use any
		blockType = "stone"
	end
	if tonumber(direction) ~= nil then
		-- legacy call -> shift parameters "log", -1(direction), "forward"(leaveExisting), true(signText), "Hello" -> "log", "forward", true, "Hello"
		leaveExisting = signText
		direction = leaveExisting
	else
		-- correct params
		direction = direction or "forward"
	end
	
	if leaveExisting == nil then
		leaveExisting = true
	end
	signText = signText or ""
	doNotAttack = doNotAttack or false
	
	local success = false
	local doContinue = true
	local dig = true
	-- assign place methods according to direction
	local Place = turtle.place
	if direction == "up" then
		Place = turtle.placeUp
	elseif direction == "down" then
		Place = turtle.placeDown
	end
	local slot = self:getItemSlot(blockType)
	if blockType == "minecraft:bucket" then -- empty bucket for lava or water
		if slot > 0 then
			turtle.select(slot)
			if Place() then -- lava or water collected
				if self:getSlotContains(slot) == "minecraft:lava_bucket" then
					self:refuel(0)
				end
				turtle.select(1)
				return true, slot
			end
		end
	else
		local existingBlock = self:getBlockType(direction)
		if leaveExisting then -- do not remove existing block unless sand gravel water or lava
			if self:detect(direction) then -- not water or lava
				if existingBlock:find("sand") ~= nil or existingBlock:find("gravel") ~= nil then --leave anything except sand/gravel	
					doContinue = true
				end
			else
				doContinue = true
			end	
		end
		if existingBlock:find("cobble") ~= nil and blockType:find("cobble") ~= nil then -- already cobble or cobbled deepslate
			doContinue = false-- no need to replace 1 cobble with another
		end
		if doContinue then -- air / water or lava in next block or leaveExisting = false
			self:dig(direction)
			if slot > 0 then -- item to place found
				turtle.select(slot)
				if doNotAttack then
					 Place(signText)
				else
					local attempts = 0
					while not Place(signText) do
						if self:attack() then
							print("Attacking "..blockType.." ? chest or minecart below")
							sleep(1)
							--T.saveToLog("Error placing "..blockType.." ? chest or minecart below")
						end
						attempts = attempts + 1
						if attempts > 1 then
							turtle.select(1)
							return false, slot
						end
					end
				end
				success = true
			end
		end
	end
	turtle.select(1)
	return success, slot
end

function T:placeWater(direction)
	direction = direction or "forward"
	-- assign place methods according to direction
	local Place = turtle.place
	if direction == "up" then
		Place = turtle.placeUp
	elseif direction == "down" then
		Place = turtle.placeDown
	end
	local slot = self:getItemSlot("minecraft:water_bucket")
	if slot > 0 then
		turtle.select(slot)
		if Place() then
			turtle.select(1)
			return true
		end
	end
	
	turtle.select(1)
	return false
end

function T:refuel(minLevel, toLimitOnly)	
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
				item, count = self:getSlotContains(i)
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
					item, count = self:getSlotContains(i)
					if item:find("planks") ~= nil then
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
					item, count = self:getSlotContains(i)
					if string.find(item, "log") ~= nil then --logs onboard
						print("Refuelling with log slot "..tostring(i)..", crafting planks")
						if self:craft("planks", 4) then
							success = true
						else
							print("refuel() error crafting planks")
						end
						if success then
							local planksSlot, count = self:getItemSlot("planks")
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
				local result = self:checkInventoryForItem({"minecraft:lava_bucket", "coal", "planks"}, {1, 10, 32}, false) -- false allows user to press enter
				if result == nil then
					return false
				end
			end
		end
		turtle.select(slot)
		
		return refuelOK
	end
end

function T:selectPlaceItem(item)
	self.placeSlot = self:getItemSlot(item)
	if self.placeSlot > 0 then
		self.placeItem = item
		return true
	end
	return false
end

function T:setEquipment()
	-- if contains a crafting table, puts it on the right. Any other tool on the left
	self:clear()
	print("Setting up equipment...")
	local emptySlotR = self:getFirstEmptySlot() -- first empty slot
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
	local pickaxeSlot, total = self:getItemSlot("minecraft:diamond_pickaxe")
	local swordSlot, total = self:getItemSlot("minecraft:diamond_sword")
	local hoeSlot, total = self:getItemSlot("minecraft:diamond_hoe")
	local craftTableSlot, total = self:getItemSlot("minecraft:crafting_table")
	if emptySlotR > 0 then -- empty slot found
		turtle.select(emptySlotR)
		if turtle.equipRight() then -- remove tool on the right
			eqRight, count = self:getSlotContains(emptySlotR) -- eqRight contains name of tool from right side
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
			emptySlotL = self:getFirstEmptySlot() -- get next empty slot
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
				eqLeft, count = self:getSlotContains(emptySlotL) -- eqLeft contains name of tool from left side
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
	
function T:sortInventory(useChest)
	if useChest == nil then useChest = true end
	local lib = {}

	function lib.checkForStorage(self)
		local blockType = self:getBlockType("forward")
		if blockType:find("barrel") ~= nil or blockType:find("chest") ~= nil then
			return "forward"
		end
		blockType = self:getBlockType("up")
		if blockType:find("barrel") ~= nil or blockType:find("chest") ~= nil then
			return "up"
		end
		blockType = self:getBlockType("down")
		if blockType:find("barrel") ~= nil or blockType:find("chest") ~= nil then
			return "down"
		end
		return ""
	end
	
	function lib.chestSort(self, chestDirection)
		for i = 1, 16 do	-- fill chest with everything
			self:drop(chestDirection, i)
		end
		local success, msg
		repeat
			success, msg = self:suck(chestDirection)
		until not success or message ~= nil
		--while self:suck(chestDirection) do end -- remove everything
	end
	
	local chestSlot = 0
	if useChest then
		chestSlot = self:getItemSlot("minecraft:chest") --get the slot number containing a chest
		if chestSlot == 0 then
			chestSlot = self:getItemSlot("minecraft:barrel") --get the slot number containing a barrel
		end
	end
	local blockType
	local facing = self.facing
	local chestPlaced = false
	local chestDirection, turns = "", 0
	if chestSlot > 0 then -- chest found
		local chestDirection, turns = self:getPlaceChestDirection()	-- find empty block to place it.
		for i = 1, 10 do	-- attempt to place chest 10x
			if self:place("minecraft:chest", chestDirection) then
				chestPlaced = true
				break
			elseif self:place("minecraft:barrel", chestDirection) then
				chestPlaced = true
				break
			else
				self:attack() -- will force wait for mob
			end
		end
		if chestPlaced then
			lib.chestSort(self, chestDirection)
			if chestDirection == "forward" then
				turtle.dig()
			elseif chestDirection == "up" then
				turtle.digUp()
			else
				turtle.digDown()
			end
		end
		if turns > 0 then	--return to original position
			self:turnLeft(turns)
		end
	else
		if useChest then -- false eg in mining, where storage chest may be full, and essential items not retrieved
			chestDirection = lib.checkForStorage(self)
			if chestDirection ~= "" then
				chestPlaced = true
				lib.chestSort(self, chestDirection)
				self:dig(chestDirection, false) -- collect chest (false = do not bypass chest)
			end
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

function T:split(textToSplit, sSeparator)
	return textToSplit:split(sSeparator)
end

function T:suck(direction, slot, quantity)
	direction = direction or "forward"
	slot = slot or 1
	--[[success, msg = turtle.suck()
		success = true / false
		msg = "No space for items" / nil]]
	
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
	turtle.select(1)
	return success, msg
end

function T:trimItemName(item)
	itemName = item
	colonPos = item:find(":")
	if colonPos ~= nil then
		itemName = item:sub(colonPos + 1)
	end
	
	return itemName
end

function T:writeCoords(filename)
	-- create/append e.g 'SpawnerCoords.txt'
	local fileHandle = fs.open(filename, "a")
	fileHandle.writeLine("x="..self.x)
	fileHandle.writeLine("y="..self.y)
	fileHandle.writeLine("z="..self.z)
	fileHandle.writeLine("f="..self.facing)
	fileHandle.close()
	self:saveToLog(filename.." file created", true)
	self:saveToLog("x = "..self:getX()..", y = "..self:getY()..", z = "..self:getZ()..", f = "..self:getFacing(), false)
end

return T
