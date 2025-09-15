version = 20250915.1500
--[[
	Last edited: see version YYYYMMDD.HHMM
	Will auto-download clsTurtle.lua
	Used to refuel a turtle on a lava lake or drain lava
	Use: 'lavaRefuel' in turtle terminal
]]
local Turtle
-- Turtle class (T), menu class (menu) and other libraries made Global

function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

function checkLibs(libDir, filename)
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

function getFileFromGithub(url, pathAndFile)
	print("Missing "..pathAndFile)
	print("Attempting to obtain from Github...")

	local response, message = http.get(url..pathAndFile)
	if response == nil then
		print("failed to install "..pathAndFile.." from Github: "..message)
		return
	else
		local data = response.readAll()
		response.close()
		local h = fs.open(pathAndFile, "w")
		if h == nil then
			error("Could not open "..pathAndFile.." for saving")
		end
		-- Save new file
		h.write(data)
		h.close()
		print(pathAndFile.." installed from Github")
	end
end

function getLavaStrip(y)
	local block = T:isWaterOrLava("down") -- will automatically fill bucket with lava and refuel
	local length = 0
	local lavaPresent = false
	local full = false
	-- while lava below, just started or moved forward < 3
	while (block == "minecraft:lava" or block == "minecraft:flowing_lava" or length < 3) and not full do --will automatically fill bucket with lava
		if T:forward(1) then
			length = length + 1
			y = y + 1
		end
		block = T:isWaterOrLava("down")
		
		print("Block below: "..tostring(block))
		if block == "minecraft:lava" or block == "minecraft:flowing_lava" then
			lavaPresent = true
		end
		if turtle.getFuelLevel() >= turtle.getFuelLimit() then
			full = true
			lavaPresent = false
		end
	end
	T:go("L2F"..length + 1)
	y = y - length - 1
	block = T:isWaterOrLava("down")
	while block == "minecraft:lava" or block == "minecraft:flowing_lava" do
		T:forward(1)
		y = y - 1
		block = T:isWaterOrLava("down")
	end
	turtle.back()
	y = y + 1
	T:go("L2")
	return lavaPresent, y
end
	
function goHome(x, y)
	if y > 0 then
		utils.goBack(y)
	elseif y < 0 then
		T:forward(math.abs(y))
	end
	if x > 0 then
		T:go("L1F"..x.."R1")
	elseif x < 0 then
		T:go("R1F"..math.abs(x).."L1")
	end
end

function main()
	local url = "https://raw.githubusercontent.com/Inksaver/Computercraft-GUI/main/"
	if not checkLibs("lib", "clsTurtle") then
		-- use Github get to download clsTurtle to libs folder
		getFileFromGithub(url, "lib/clsTurtle.lua")
	end
	if not checkLibs("lib", "Class.lua") then
		-- use Github get to download Class to libs folder
		getFileFromGithub(url, "lib/Class.lua")
	end
	
	Turtle = require("lib.clsTurtle")
	T = Turtle(false)
	
	local side = ''
	while side == '' do
		clear()
		print("Place me in front of lava")
		print("Which side has more lava? (L C R)")
		print("Choose C for a single strip")
		side = read()
		if side == 'l' or side =='L' then
			side = 'L'
		elseif side == 'r' or side =='R' then
			side = 'R'
		else
			side = 'C'
		end
	end
		
	clear()
	print("Current fuel: "..turtle.getFuelLevel().." / "..turtle.getFuelLimit())
	
	local lavaSlot = T:getItemSlot("minecraft:lava_bucket") 
	if lavaSlot > 0 then
		turtle.select(lavaSlot)
		T:refuel(0) -- 0=force refuel
	end
	T:checkInventoryForItem({"minecraft:bucket", "minecraft:lava_bucket"}, {1,1}, true)
	T:refuel(0) -- 0=force refuel
	local x, y, width = 0, 0, 0
	local lavaPresent, y = getLavaStrip(y)
	if side ~= 'C' then -- not a single strip
		while lavaPresent do
			width = width + 1
			if side == 'R' then -- do strip on the right
				T:go("R1F1L1")
				x = x + 1
			else
				T:go("L1F1R1")
				x = x - 1
			end
			lavaPresent, y  = getLavaStrip(y)
			if turtle.getFuelLevel() >= turtle.getFuelLimit() then
				lavaPresent = false
				print("Max fuel "..turtle.getFuelLimit() .. " achieved")
			end
		end
		if width <= 0 then
			width = 1
		end
		goHome(x, y)
	end
end

main()
