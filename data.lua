version = 20230430.1000
--[[
https://pastebin.com/fCKDc9Vi
pastebin get fCKDc9Vi data.lua
]]
local usage = [[usage:
data   (getBlockType forward) or data 1
data u (getBlockType up)      or data 0
data d (getBlockType down)    or data 2
]]
args = {...}

local direction = "forward"
--local blockType = ""
--local blockModifier = nil
local success = false
local data = {} --initialise empty table variable
local inspect = turtle.inspect

if args[1] ~= nil then
	if args[1]:lower() == "h" then
		term.clear()
		term.setCursorPos(1,1)
		print(usage)
		print("Fuel Level: "..turtle.getFuelLevel())
		error()
	elseif args[1]:lower() == "u" or args[1] == "0" then
		direction = "up"
		inspect = turtle.inspectUp
	elseif args[1]:lower() == "d" or args[1] == "2" then
		direction = "down"
		inspect = turtle.inspectDown
	end
end
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
	term.clear()
	term.setCursorPos(1,1)
	local lines = 0
	local isSource = false
	print("Block "..direction.."="..data.name)
	lines = lines + 1
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
			if k ~= "level" then
				print("data.state."..k.." = "..tostring(v))
				lines = lines + 1
			end
		end
	end
	if data.metadata ~= nil then
		for k,v in pairs(data.metadata) do
			print("data.metadata."..k.." = "..v)
		end
	end
	if data.tags ~= nil then
		for k,v in pairs(data.tags) do
			if k:find("minecraft:") ~= nil then
				k = k:sub(11)
			end
			print("tags."..k.."="..tostring(v))
			lines = lines + 1
			if lines > 10 then
				print("Enter to continue")
				read()
				lines = 0
			end
		end
	end
else
	print("Unable to inspect block "..direction)
end