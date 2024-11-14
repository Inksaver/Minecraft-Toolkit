version = 20240926.1230
--[[
https://pastebin.com/fCKDc9Vi
pastebin get fCKDc9Vi data.lua
]]
local usage = [[usage:
data    block name forward or data 1
data u  block name up      or data 0
data d  block name down    or data 2
data s# item detail slot#  or data s #
]]
args = {...}

local direction = "forward"
--local blockType = ""
--local blockModifier = nil
local success = false
local data = {} --initialise empty table variable
local inspect = turtle.inspect

local function clear()
	term.clear()
	term.setCursorPos(1,1)
end

local function continue(clearAfter)
	write("Enter to continue...")
	read()
	if clearAfter then clear() end
end

local function checkLines(lines)
	if lines > 10 then
		write("Enter to continue")
		read()
		lines = 0
		clear()
		return 0
	end
	return lines + 1
end

local function trim(text)
	--[[ trim leading and trailing spaces ]]
	return (text:gsub("^%s*(.-)%s*$", "%1"))
end

local function getData(inspect)
	success, data = inspect()
	if success then -- block found
		-- data.name 				-- eg "minecraft:log"
		-- data.metadata 			-- no longer used
		-- data.state.level 		-- in water 0 to 8 0=source
		-- data.state.shape 		-- eg straight
		-- data.state.waterlogged	-- bool
		-- data.state.half 			-- eg "bottom"
		-- data.state.facing		-- eg "south"
		-- data.state.drag			-- bool eg bubble_column
		clear()
		local lines = 0
		local count = 0
		local isSource = false
		
		print("Block "..direction.."="..data.name)
		for k,v in pairs(data) do
			print(count..":"..k)
			count = count + 1
		end
		continue(false)
		lines = checkLines(lines)
		
		if data.name:find("water") ~= nil then -- allows for bubble_column
			if data.state.level ~= nil then
				if data.state.level == 0 then
					isSource = true
				end
			end
			term.write("data.state.level = "..data.state.level)
			if isSource then
				term.write(" (source)\n")
			else
				term.write(" (flowing)\n")
			end
		end
		if data.state ~= nil then
			for k,v in pairs(data.state) do
				print("data.state."..k.." = "..tostring(v))
				lines = checkLines(lines)
			end
			continue(true)
		end
		if data.metadata ~= nil then
			-- deprecated. legacy inclusion
			for k,v in pairs(data.metadata) do
				print("data.metadata."..k.." = "..v)
				lines = checkLines(lines)
			end
			continue(true)
		end
		if data.tags ~= nil then
			for k,v in pairs(data.tags) do
				if k:find("minecraft:") ~= nil then
					k = k:sub(11)
				end
				print("tags."..k.."="..tostring(v))
				lines = checkLines(lines)
			end
		end
	else
		print("Unable to inspect block "..direction)
	end
end

local function getItemDetail(text)
	-- eg bow: data.nbt = "552887824c43124013fd24f6edcde0fb"
	-- should be s1 to s16
	-- could be s 1 to s 16
	-- could be >16 or < 1
	local command = trim(text)
	local slot = command:sub(2)
	slot = trim(slot)
	print("Slot '"..slot.."'")
	slot = tonumber(slot)
	if slot ~= nil then
		local data = turtle.getItemDetail(slot)
		if data == nil then
			print("Slot "..slot.." is empty")
		else
			for k,v in pairs(data) do
				print(k..": "..v)
			end
		end
	else
		print("Unable to parse '"..text.."'")
	end
end


if args[1] ~= nil then
	--[[
	data s1  args[1] = s1
	data s 1 args[1] = s args[2] = 1
	]]
	if args[1]:lower() == "h" then
		term.clear()
		term.setCursorPos(1,1)
		print(usage)
		print("Fuel Level: "..turtle.getFuelLevel())
	elseif args[1]:lower() == "u" or args[1] == "0" then
		direction = "up"
		getData(turtle.inspectUp)
	elseif args[1]:lower() == "d" or args[1] == "2" then
		direction = "down"
		getData(turtle.inspectDown)
	elseif args[1]:lower():find("s") ~= nil then -- check slot no
		if args[2] == nil then
			getItemDetail(args[1])
		else
			getItemDetail(args[1]..args[2])
		end
	else
		getData(inspect)
	end
end
