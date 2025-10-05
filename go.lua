version = 20251004.2000
--[[
	Will auto-download clsTurtle.lua
	Used to move turtle in multiple directions
	Use: go in command prompt
	keys:
	q = quit
	e = slot
	1 - 0 select slot
	w = forward
	a = turnLeft
	d = turnRight
	s = back
	some versions of MC or CC use different key constants:
	1.12.2 keys.one=2, keys.two=3...  keys.zero=11
	1.16.2 keys.one=49 keys.two=50..  keys.zero=48
]]

args = {...} -- eg go r1f5u2
local Turtle
local kv = {}
kv[keys.zero] 	= "0"
kv[keys.one] 	= "1"
kv[keys.two] 	= "2"
kv[keys.three] 	= "3"
kv[keys.four] 	= "4"
kv[keys.five] 	= "5"
kv[keys.six] 	= "6"
kv[keys.seven] 	= "7"
kv[keys.eight] 	= "8"
kv[keys.nine] 	= "9"

function checkArgs()
	local path = ""
	if args[1] ~= nil then
		path = args[1]
	end
	return path
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

function clear(setCP)
	term.clear()
	term.setCursorPos(1, 1)
	if setCP then
		term.write("directions: f u d b r l")
		term.setCursorPos(1, 2)
		term.write("or: s(lot) p(lace) x(dig) t(unnel)")
		term.setCursorPos(1, 3)
	end
end

function getCommand()
	local cmd = ""
	local minNum = 0
	local maxNum = 9
	local col, row = term.getCursorPos()
	if keys.one == 49 then  --newer versions
		minNum = 48
		maxNum = 57
	end
	term.write("cmd?_")
	while true do
		local event, key = os.pullEvent("key")
		if key == keys.q then -- quit
			cmd = ""
			break
		elseif key == keys.s then -- user wants to select slot no
			cmd = "s"
			term.setCursorPos(1, row)
			term.write("slot no? "..cmd.."_")
		elseif key == keys.t then -- user wants to tunnel
			cmd = "t"
			term.setCursorPos(1, row)
			term.write("length? "..cmd.."_")
		elseif key == keys.p or key == keys.x then -- user wants to place or excavate
			cmd = keys.getName(key)
			term.setCursorPos(1, row)
			term.write("direction u=0 f=1 d=2? "..cmd.."_")
		elseif key == keys.f or key == keys.b or key == keys.u or key == keys.d or key == keys.l or key == keys.r then
			cmd = keys.getName(key) -- eg f
			term.setCursorPos(1, row)
			term.write("no? "..cmd.."_")
		elseif key >= minNum and key <= maxNum then -- 1 to 0 chosen = 49 to 58
			--check if cmd is empty
			if string.len(cmd) > 0 then -- not empty so build command
				local c = string.sub(cmd, 1, 1)
				local num = kv[key]
				if c == "s" then -- select slot
					if cmd == "s" then
						cmd = "s"..num
						term.setCursorPos(1, row)
						term.write("0 to 6 or enter? "..cmd.."_")
					else
						if key + offset - 1 <= 6 then -- allow 0 to 6 only
							cmd = cmd..num
							break
						end
					end
				elseif c == "p" or c == "x" then
					if key == keys.zero then
						cmd = c.."0"
						break
					elseif key == keys.one or key == keys.two then
						cmd = c..num
						break
					end
				elseif c == "r" or c == "l" then
					cmd = cmd..num
					break
				elseif  c == "f" or c == "b" or c == "u" or c == "d" or c == "r" or c == "l" or c == "t" then
					cmd = cmd..num
					term.setCursorPos(1, row)
					term.write("0-9 or Enter? "..cmd.."_")
				end
			end
		elseif key == keys.enter then -- command finished
			break
		end
	end
	clear()
	return cmd
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

function tunnel(length)
	-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	local preferredBlock = T:getMostItem("", false)
	for l = 1, length do
		if l < length then
			T:go("x0C2F1", false, 0, true, preferredBlock)
		else
			T:go("x0C2", false, 0, true, preferredBlock)
		end
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
	print("Current fuel: "..turtle.getFuelLevel().." / "..turtle.getFuelLimit())
	local action,  modifier
	local cmd = checkArgs() -- empty string or cmd eg go r1f5u2
	local direction = {"up", "forward", "down"}
	if cmd ~= "" then
		if cmd:sub(1,1):lower() == "t" then
			-- tunnel # length
			cmd = cmd:gsub(" ", "") -- remove spaces from path
			local length = tonumber(cmd:sub(2))
			tunnel(length)
		else
			T:go(cmd)
		end
	else
		sleep(2)
		clear(true)
		while true do
			cmd = string.upper(getCommand())
			action = string.sub(cmd, 1, 1)
			modifier = string.sub(cmd, 2)
			if cmd == "" then
				break
			else
				if action == "S" then --select slot
					turtle.select(tonumber(modifier))
				elseif action == "X" then --dig
					T:dig(direction[modifier + 1])
				elseif action == "P" then --place
					--place current selected slot contents
					--T:place(blockType, damageNo, direction, leaveExisting)
					local slotContains, slotCount, slotDamage = T:getSlotContains(turtle.getSelectedSlot)
					
					print("Place "..slotContains.." count: "..slotCount.." damage: "..tostring(slotDamage).." Enter")
					read()
					T:place(slotContains, slotDamage, direction[modifier + 1], false)
				elseif action == "T" then --tunnel
					tunnel(tonumber(modifier))
				else
					T:go(cmd)
				end
			end
		end
	end
end

main()
