version = 20230308.1930
--[[
	pastebin get kFZsXu99 lavaRefuel.lua
	Last edited: see version YYYYMMDD.HHMM
	Will auto-download clsTurtle.lua
	Used to refuel a turtle on a lava lake or drain lava
	Use: 'lavaRefuel' in turtle terminal
]]

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

function getLavaStrip()
	local block, blockType = T:isWaterOrLava("down") -- will automatically fill bucket with lava and refuel
	local start = true
	local length = 0
	local lavaPresent = false
	-- while lava below, just started or moved forward < 3
	while block == "minecraft:lava" or block == "minecraft:flowing_lava" or start or length < 3 do --will automatically fill bucket with lava
		start = false
		
		if T:forward(1) then
			length = length + 1
		end
		block, blockType = T:isWaterOrLava("down")
		
		print("Block below: "..tostring(block))
		if block == "minecraft:lava" or block == "minecraft:flowing_lava" then
			lavaPresent = true
		end
	end
	T:go("L2F"..length + 1)
	block, blockType = T:isWaterOrLava("down")
	while block == "minecraft:lava" or block == "minecraft:flowing_lava" do
		T:forward(1)
		block, blockType = T:isWaterOrLava("down")
	end
	turtle.back()
	T:go("L2")
	return lavaPresent
end

function main()
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
	local doContinue = true
	if not checkLibs("lib", "clsTurtle") then
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
	sleep(2)
	if doContinue then
		clear()
		print("Current fuel: "..turtle.getFuelLevel().." / "..turtle.getFuelLimit())
		T = require("lib.clsTurtle"):new()
		local lavaSlot = T:getItemSlot("minecraft:lava_bucket", -1) 
		if lavaSlot > 0 then
			turtle.select(lavaSlot)
			T:refuel(0) -- 0=force refuel
		end
		T:checkInventoryForItem({"minecraft:bucket", "minecraft:lava_bucket"}, {1,1}, true)
		T:refuel(0) -- 0=force refuel
		local width = 0
		local lavaPresent = getLavaStrip()
		if side ~= 'C' then -- not a single strip
			while lavaPresent do
				width = width + 1
				if side == 'R' then -- do strip on the right
					T:go("R1F1L1")
				else
					T:go("L1F1R1")
				end
				lavaPresent = getLavaStrip()
				if turtle.getFuelLevel() >= turtle.getFuelLimit() then
					lavaPresent = false
					print("Max fuel "..turtle.getFuelLimit() .. " achieved")
				end
			end
			if width <= 0 then
				width = 1
			end
			
			if side == 'R' then
				T:go("L1F"..width.."R1")
			else
				T:go("R1F"..width.."L1")
			end
		end
	else
		print("Add missing files and restart")
	end
end

main()